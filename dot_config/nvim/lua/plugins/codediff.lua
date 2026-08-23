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

return {
  "esmuellert/codediff.nvim",
  cmd = "CodeDiff",
  opts = {
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
  },
  keys = {
    { "<leader>gv", "<cmd>CodeDiff<cr>", desc = "Git: Review working tree" },
    -- The merge-request key. `...` is git's merge-base syntax, so this shows
    -- what the branch adds, not everything that has landed on the base since it
    -- was cut.
    { "<leader>gm", with_base("%s...HEAD"), desc = "Git: Review branch vs base (MR)" },
    -- The same range, commit by commit, for when the squashed diff is too big to
    -- read in one go. `..` here, not `...`: this is a commit list, not a diff.
    { "<leader>gM", with_base("history %s..HEAD"), desc = "Git: Branch commits" },
    -- `%` is the current file. codediff tells a revision from a path by testing
    -- whether the argument is readable, so no range is needed.
    { "<leader>gh", "<cmd>CodeDiff history %<cr>", desc = "Git: File history" },
    { "<leader>gH", "<cmd>CodeDiff history<cr>", desc = "Git: Repo history" },
  },
}
