-- Replaces diffview.nvim, whose last commit was June 2024 — nothing in the two
-- years since. codediff computes diffs with a C port of VSCode's diff engine and
-- renders them with extmarks, so it never edits buffer text.
--
-- The layout is "inline": one window, deletions shown as virtual lines above the
-- additions. That is the unified view GitLab renders a merge request in, which
-- is the shape this config reviews branches in. `t` inside any diff view toggles
-- to side-by-side for the occasional change that reads better that way.

-- Resolve the branch a feature branch should be compared against. origin/HEAD is
-- the remote's own answer to "what is the default branch"; it is only written by
-- `git clone` and `git remote set-head`, so fall back to whichever of main and
-- master exists. Hardcoding `main` (which is what the diffview mapping did) fails
-- outright in a master/develop/trunk repo.
---@return string?
local function default_base()
  local head = vim.system({ "git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD" }, { text = true }):wait()
  if head.code == 0 then
    local name = vim.trim(head.stdout or ""):gsub("^origin/", "")
    if name ~= "" then
      return name
    end
  end
  for _, name in ipairs({ "main", "master" }) do
    if vim.system({ "git", "rev-parse", "--verify", "--quiet", name }):wait().code == 0 then
      return name
    end
  end
end

---Run `CodeDiff <fmt with the base substituted>`, or explain why it can't.
---@param fmt string
local function with_base(fmt)
  return function()
    local base = default_base()
    if not base then
      vim.notify(
        "codediff: no default branch found.\n"
          .. "Set one with `git remote set-head origin -a`,\n"
          .. "or run :CodeDiff <base>...HEAD directly.",
        vim.log.levels.WARN
      )
      return
    end
    vim.cmd("CodeDiff " .. fmt:format(base))
  end
end

---The branch this one pushes to, or nil when it has none.
---
---`@{upstream}` rather than a hardcoded origin/<branch>: it follows whatever
---the branch is actually tracking, which is what "will this be in the push"
---depends on. Resolves to origin/main here and origin/session-74-prep in
---pf2e-prep, without either being named.
---@return string|nil
local function upstream()
  local res = vim.system({ "git", "rev-parse", "--abbrev-ref", "@{upstream}" }, { text = true }):wait()
  if res.code ~= 0 then
    return nil -- "fatal: no upstream configured for branch ..."
  end
  local name = vim.trim(res.stdout or "")
  return name ~= "" and name or nil
end

---Run `CodeDiff <fmt with the upstream substituted>`, or explain why it can't.
---@param fmt string
local function with_upstream(fmt)
  return function()
    local up = upstream()
    if not up then
      vim.notify(
        "codediff: this branch has no upstream, so there is nothing to compare a push against.\n"
          .. "Push it once with `git push -u origin HEAD`, or use <leader>gm to review against the base.",
        vim.log.levels.WARN
      )
      return
    end
    vim.cmd("CodeDiff " .. fmt:format(up))
  end
end

---Scope a review to the current file, optionally against a revision.
---
---The pathspec has to be expanded here. codediff expands `%` in *path*
---arguments (which is why `CodeDiff history %` works) but hands the operands
---after `--` to git verbatim, so `CodeDiff -- %` asks git for a file literally
---named "%", matches nothing, and reports "No changes to show" — a wrong answer
---that looks like a right one.
---@param rev string?
local function this_file(rev)
  return function()
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
      vim.notify("codediff: this buffer has no file to review", vim.log.levels.WARN)
      return
    end
    vim.cmd(("CodeDiff %s-- %s"):format(rev and (rev .. " ") or "", vim.fn.fnameescape(file)))
  end
end

---Does `buf` carry a buffer-local normal-mode mapping for `lhs`?
---
---maparg() only ever answers for the current buffer, so it cannot be used to
---test a buffer we are merely iterating over.
---@param buf integer
---@param lhs string
local function has_map(buf, lhs)
  for _, km in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
    if km.lhs == lhs then
      return true
    end
  end
  return false
end

---Jump from a diff pane to the same line in the real file, anchored on the
---line's *text* rather than its number.
---
---codediff's own `gf` copies the cursor position verbatim
---(nvim_win_set_cursor with the diff pane's line), which is correct exactly
---when the file on disk still matches the side being reviewed. For
---`<leader>gm` — base...HEAD, on the branch you have checked out — that
---normally holds, and in inline layout the diff pane's line numbers *are* the
---new file's, because deletions are virtual lines and take up no numbering.
---
---It stops holding the moment the working tree is dirty, and it fails
---silently. Measured on a 60-line file with three hunks: with five lines
---added at the top, `gf` from a line reading "TARGET MARKER" landed on
---"line 045 original" five lines short, with no warning.
---
---So: let codediff navigate (it knows how to resolve the path and pick the
---tab), then check where we landed. If the text does not match, look for it
---nearby and say so; if it is not in the file at all, say that too rather
---than leave the cursor somewhere arbitrary.
local function open_anchored()
  local want = vim.api.nvim_get_current_line()
  local from = vim.api.nvim_win_get_cursor(0)[1]

  -- gF is codediff's open_in_prev_tab, moved off gf in opts below.
  --
  -- "mx", not "nx". The x executes the keys before this function continues,
  -- which is what lets the landing be checked below — but n means *noremap*,
  -- and with it the gF went through as vim's builtin gF rather than
  -- codediff's mapping, leaving the cursor in the diff pane. m remaps.
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gF", true, false, true), "mx", false)

  -- Nothing to anchor to. A blank or near-blank line matches everywhere, so
  -- checking it would produce noise, not safety.
  if vim.trim(want) == "" then
    return
  end

  local landed = vim.api.nvim_get_current_line()
  if landed == want then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local best
  for i, line in ipairs(lines) do
    if line == want then
      -- Nearest to where codediff put us, so a line that legitimately repeats
      -- resolves to the copy the diff was showing rather than the first one.
      if not best or math.abs(i - from) < math.abs(best - from) then
        best = i
      end
    end
  end

  if not best then
    vim.notify(
      ("codediff: this line is not in the working copy.\nShowing line %d, which may be unrelated."):format(from),
      vim.log.levels.WARN
    )
    return
  end

  vim.api.nvim_win_set_cursor(0, { best, 0 })
  vim.cmd("normal! zz")
  vim.notify(("codediff: line moved %d -> %d in the working copy"):format(from, best), vim.log.levels.INFO)
end

---The diff pane's position in the file's hunks, as `hunk 3/5`, or "" anywhere
---else. Rendered by mini.statusline — see the append in plugins/mini.lua.
---
---Kept as a global because that is what a statusline `%{}` can call: the
---expression is evaluated as vimscript, where `v:lua.Fn()` resolves a global
---but `v:lua.require'x'.fn()` does not parse.
---
---codediff is `cmd`-lazy, so on most buffers it is not loaded at all. Asking
---package.loaded directly rather than require()ing is the point: a require
---here would load the whole plugin on the first redraw of any buffer, which is
---the opposite of lazy.
function _G.CodeDiffHunkStatus()
  local lifecycle = package.loaded["codediff.ui.lifecycle"]
  if not lifecycle then
    return ""
  end

  local session = lifecycle.get_session(vim.api.nvim_get_current_tabpage())
  if not session or not session.stored_diff_result then
    return ""
  end

  -- Only the diff panes. The explorer and the history list live in the same
  -- tabpage and would otherwise inherit a count that says nothing about them.
  local buf = vim.api.nvim_get_current_buf()
  if buf ~= session.modified_bufnr and buf ~= session.original_bufnr then
    return ""
  end

  local changes = session.stored_diff_result.changes or {}
  if #changes == 0 then
    return " no hunks "
  end

  -- Which line numbers a hunk is recorded under depends on the side being
  -- shown. In inline layout there is only one pane and deletions are virtual
  -- lines, so its numbering is the modified file's throughout — the same
  -- choice codediff's own ]c makes in view/navigation.lua.
  local use_original = buf == session.original_bufnr and session.layout ~= "inline"
  local line = vim.api.nvim_win_get_cursor(0)[1]

  -- The hunk the cursor is in, or the last one it is past. 0 until the first
  -- hunk, which is honest: `jump_to_first_change` normally means we open at 1,
  -- but scrolling back above it should not claim to be in hunk 1.
  local current = 0
  for i, hunk in ipairs(changes) do
    local side = use_original and hunk.original or hunk.modified
    if line >= side.start_line then
      current = i
    else
      break
    end
  end

  return (" hunk %d/%d "):format(current, #changes)
end

return {
  "esmuellert/codediff.nvim",
  cmd = "CodeDiff",
  opts = {
    -- Solved against the actual foregrounds, after two attempts that were not.
    --
    -- The measurement that matters: WCAG contrast between a diff background and
    -- the dimmest thing drawn on it. In a Python diff here that is #949cbc, the
    -- comment colour, and it is also the most common — comments outnumbered
    -- every other foreground on diff lines by three to one. Normal code gives
    -- it 4.53x. catppuccin's own DiffAdd gives it 3.07x, so a diff line was
    -- already the least readable thing on screen before anything was changed.
    --
    -- Both earlier attempts made that worse, because green carries 0.7152 of
    -- the luminance formula against blue's 0.0722. Picking a green by its HSL
    -- lightness therefore picks a much brighter colour than the same number
    -- suggests: #405f2b reads as "lightness 27%", darker than base's 23%, and
    -- is nearly three times its luminance — 2.68x for comments. The attempt
    -- before that, #5f7361, managed 1.88x.
    --
    -- So these are chosen the other way round: fix the luminance, then spend
    -- everything else on chroma. Each line colour sits at the luminance where
    -- comment contrast is 4.5x — the same as normal code, so no diff line is
    -- ever harder to read than the file around it — and takes as much
    -- saturation as that allows, about 45% against catppuccin's 9%. They are
    -- frappe's own hues throughout (green 96°, red 359°).
    --
    -- char_insert/char_delete are set rather than derived. Left nil, codediff
    -- multiplies the line colour's channels by 1.4, which buys prominence with
    -- contrast: the derived pair came out at 3.27x. These instead take a small
    -- brightness step (to 4.2x, still at normal code's level) and a large
    -- saturation step, to 75%, so a changed word stands out by being more
    -- vivid rather than by being washed paler.
    --
    -- The red pair then went one step lighter than the green, to 4.2x and
    -- 3.9x, because at matched luminance a dark saturated red reads as muddier
    -- than the green does — it was blurring against mauve, which is what
    -- `def` and every other keyword is drawn in. That is a chroma clash rather
    -- than a contrast one (mauve had 5.59x on the darker red, well clear of
    -- the floor), so the fix is the red being lighter and more obviously red,
    -- not more separated in luminance.
    --
    -- To tune, hold the contrast and move the saturation; changing lightness
    -- directly is the trap this comment exists to record. At 4.5x the ladder
    -- is #253b16 / #213c0f / #1d3c09 for 45 / 60 / 75% saturation.
    highlights = {
      line_insert = "#253b16",
      char_insert = "#204209",
      line_delete = "#632627",
      char_delete = "#7e1214",
    },
    diff = {
      layout = "inline",
      jump_to_first_change = true,
      gutter_signs = true, -- gitsigns' signs aren't shown in codediff's buffers
    },
    explorer = {
      position = "left",
      width = 40,
      -- Land in the diff, not the file list: the list is how you move between
      -- files, but the diff is what you came to read.
      initial_focus = "diff",
    },
    history = { position = "bottom" },
    -- gf is rebound below to open_anchored(), which calls this one and then
    -- checks the landing. Kept reachable as gF: when the working tree is
    -- clean the two agree, and gF is the way to say "go to line N" and mean it.
    keymaps = { view = { open_in_prev_tab = "gF" } },
  },
  init = function()
    -- Dispatched at press time rather than bound when a diff opens.
    --
    -- The obvious hooks both lose a race. codediff claims its view keymaps
    -- buffer-locally on the session's panes, but its User CodeDiffOpen event
    -- fires from the *placeholder* view, before the git read returns — during
    -- that callback gF is absent from every window in the tabpage and present
    -- immediately after. BufEnter has the same problem from the other side:
    -- you enter the pane once, before the mappings exist, and never again.
    --
    -- Asking the question when the key is pressed has no ordering to get
    -- wrong. gF is codediff's open_in_prev_tab (moved off gf in opts above),
    -- so a buffer-local gF is a reliable marker for "this is a diff pane" —
    -- better than buftype or filetype, which the explorer and history share.
    -- Everywhere else this falls through to vim's own gf.
    vim.keymap.set("n", "gf", function()
      if has_map(0, "gF") then
        return open_anchored()
      end
      -- normal! so this cannot recurse into the mapping. The count matters:
      -- vim's gf takes one as a line number to land on.
      vim.cmd("normal! " .. (vim.v.count > 0 and vim.v.count or "") .. "gf")
    end, { desc = "Go to file (anchored on line text inside a codediff pane)" })
  end,

  keys = {
    { "<leader>gv", "<cmd>CodeDiff<cr>", desc = "Git: Review working tree" },
    -- The same working-tree review, narrowed to the current file. Unlike the
    -- gitsigns diffthis this replaces, staged and unstaged changes stay in
    -- separate groups rather than merged into one diff.
    { "<leader>gd", this_file(), desc = "Git: Review this file" },
    -- Same view, one commit further back. `CodeDiff file HEAD~` also works but
    -- opens its own tab with no explorer — a different shape from every other
    -- key here.
    { "<leader>gD", this_file("HEAD~"), desc = "Git: Review this file vs HEAD~" },
    -- The merge-request key. `...` is git's merge-base syntax, so this shows
    -- what the branch adds, not everything that has landed on the base since it
    -- was cut.
    { "<leader>gm", with_base("%s...HEAD"), desc = "Git: Review branch vs base (MR)" },
    -- The same range, commit by commit, for when the squashed diff is too big to
    -- read in one go. `..` here, not `...`: this is a commit list, not a diff.
    { "<leader>gM", with_base("history %s..HEAD"), desc = "Git: Branch commits" },
    -- The same two shapes again, against the upstream rather than the base:
    -- "what am I about to push", which <leader>gm cannot answer while you are
    -- *on* the default branch — there `base...HEAD` is empty by definition.
    { "<leader>gu", with_upstream("%s...HEAD"), desc = "Git: Review unpushed work" },
    { "<leader>gU", with_upstream("history %s..HEAD"), desc = "Git: Unpushed commits" },
    -- `%` is the current file. codediff tells a revision from a path by testing
    -- whether the argument is readable, so no range is needed.
    { "<leader>gh", "<cmd>CodeDiff history %<cr>", desc = "Git: File history" },
    { "<leader>gH", "<cmd>CodeDiff history<cr>", desc = "Git: Repo history" },
  },
}
