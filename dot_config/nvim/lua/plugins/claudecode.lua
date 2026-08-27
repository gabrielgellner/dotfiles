-- claudecode.nvim — Claude Code IDE integration, in the same spirit as the
-- official VS Code/JetBrains extensions but pure Lua.
--
-- What it actually is: a WebSocket MCP server hosted *by Neovim*. On startup it
-- picks a port and writes ~/.claude/ide/<port>.lock describing this editor and
-- its workspace. Any `claude` CLI started afterwards in the same project finds
-- that lock file and connects — so the editor gains selection context, @-mention
-- sends, and in-editor diff review for proposed edits.
--
-- ── The workflow this is shaped around ──────────────────────────────────────
--
-- Claude is a full-screen float, not a split. Toggle it on with <leader>ac, work
-- in it, then toggle it away (or just move focus — see the WinLeave autocmd) and
-- the editor is back exactly as it was. The Claude session keeps running the
-- whole time: hiding a float is nvim_win_set_config{hide=true}, which leaves the
-- window, its grid and the pty untouched.
--
-- That last part is why a float rather than a maximised split. Snacks hides a
-- *split* by closing the window and re-creating it on show, and that destroy /
-- recreate cycle walks Claude's prompt up a row each time (the provider carries
-- a whole workaround block for it). A float never dies, so the bug can't occur.
--
-- Splits appear in exactly one place: reviewing a proposed edit. diff_opts sends
-- those to their own tab with the terminal suppressed, so the diff gets the full
-- screen and the float isn't sitting on top of the thing being reviewed.

local augroup = vim.api.nvim_create_augroup("claudecode_ui", { clear = true })

-- The window showing the in-editor Claude terminal, if one is on this tabpage.
local function claude_win()
  local ok, terminal = pcall(require, "claudecode.terminal")
  if not ok then
    return nil
  end
  local buf = terminal.get_active_terminal_bufnr()
  if not buf then
    return nil
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

-- Toggle the float between full screen and a right-hand column.
--
-- Full screen is the default and what you want most of the time; the narrow form
-- is for glancing at Claude while a file stays readable underneath. Both are the
-- same window resized in place, so the session and scrollback are untouched.
--
-- Note this is per-appearance: hiding and re-showing rebuilds the float from the
-- configured opts, so it comes back full screen.
local function toggle_width()
  local win = claude_win()
  if not win then
    vim.notify("Claude isn't open", vim.log.levels.WARN)
    return
  end
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative == "" then
    vim.notify("Claude isn't floating", vim.log.levels.WARN)
    return
  end

  -- `lines` counts the whole UI; the command line and status line aren't ours.
  local height = vim.o.lines - vim.o.cmdheight - 1
  local narrow = math.floor(vim.o.columns * 0.4)
  local going_narrow = cfg.width > narrow

  vim.api.nvim_win_set_config(win, {
    relative = "editor",
    row = 0,
    col = going_narrow and (vim.o.columns - narrow) or 0,
    width = going_narrow and narrow or vim.o.columns,
    height = height,
  })
end

-- Toggle the float, safely.
--
-- Two separate things go wrong, and they compound, so both are handled here.
--
-- 1. Terminal mode. The plugin hides the float with nvim_win_set_config{hide =
--    true} and then steps out of it, because Neovim doesn't auto-leave a
--    config-hidden window. From *terminal* mode that step doesn't stick: the
--    window command runs while mode() is still "t", and when the mapping
--    returns, terminal mode is re-entered and takes the focus back. Same reason
--    the canonical terminal mapping is `tnoremap <C-w>h <C-\><C-n><C-w>h` and
--    never `:wincmd h<CR>` — you have to leave terminal mode *before* the window
--    command, not during it. Hence stopinsert, then the toggle on the next tick
--    once the mode change has landed. From normal mode both are no-ops, which is
--    why one function serves the "t" and "n" mappings alike.
--
-- 2. `wincmd p` isn't a reliable escape even from normal mode. It is a no-op
--    whenever there is no previous window to go to, and Neovim has two everyday
--    ways of arriving at that:
--
--      * the window you came from was closed while you were in Claude, so
--        winnr("#") is 0;
--      * a transient float — a picker, which-key, a notification — opened on top
--        of Claude and closed again, which leaves the previous window pointing
--        at the Claude float *itself*.
--
--    The second is the common one, and it's why this only bites sometimes: it
--    depends entirely on what you happened to do just before pressing the key.
--    Note the WinLeave autocmd below deliberately doesn't hide Claude when focus
--    lands on another float, which is what lets pickers set that state up.
--
-- Either way the float ends up hidden but still focused: the screen changes, so
-- it looks like the toggle worked, while keystrokes go to a window that is no
-- longer drawn. The WinEnter self-heal can't catch it, because focus never
-- *entered* anywhere — it never left. So verify afterwards and, if we're still
-- sitting in the hidden float, pick a window by hand.

-- Somewhere to land: prefer an ordinary window, since that's what was underneath
-- the float, but any window at all beats staying in one that isn't drawn.
local function escape_to_any_win(from)
  local fallback
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= from then
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative == "" and not cfg.hide then
        vim.api.nvim_set_current_win(win)
        return
      end
      fallback = fallback or win
    end
  end
  if fallback then
    vim.api.nvim_set_current_win(fallback)
  end
end

local function toggle_float()
  vim.cmd("stopinsert")
  vim.schedule(function()
    vim.cmd("ClaudeCode")
    local win = claude_win()
    if not (win and vim.api.nvim_get_current_win() == win) then
      return
    end
    if vim.api.nvim_win_get_config(win).hide then
      escape_to_any_win(win)
    end
  end)
end

-- ── <C-/>: toggle the float ─────────────────────────────────────────────────
--
-- One key, one job, from inside Claude or from any buffer. No timing involved:
-- the tap acts immediately, so there's no timeoutlen stall and no double-press
-- to get right.
--
-- Getting to normal mode inside the terminal is a separate key, <C-x> — bound
-- in config/keymaps.lua to the built-in <C-\><C-n>. Normal mode is for
-- scrolling and yanking Claude's output; `i` goes back to typing at it. (It was
-- <C-\> once; keymaps.lua has the reason it moved, which is about what a
-- misfire does in a plain shell rather than anything inside nvim.)

-- The file a buffer is "about", which is not always its name. A codediff
-- review pane under <leader>gm is buftype=nofile with an empty name, yet it
-- concerns a real file and the session knows which: get_paths returns
-- { absolute, relative } for the pane. Used by both context mappings below, so
-- neither has to care which kind of buffer it is looking at.
---@return string|nil
local function buffer_file()
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" then
    return name
  end
  local ok, acc = pcall(require, "codediff.ui.lifecycle.accessors")
  local paths = ok and select(2, pcall(acc.get_paths, vim.api.nvim_get_current_tabpage())) or nil
  local target = type(paths) == "table" and paths.absolute or nil
  if target and target ~= "" then
    return target
  end
end

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },

  -- The server has to be listening before a `claude` in another tmux window can
  -- discover it, and lazy-loading on <leader>a would mean it isn't. Load on
  -- VeryLazy so the lock file exists as soon as the editor settles.
  event = "VeryLazy",

  init = function()
    -- A full-screen float is opaque, so focus moving out of it without the
    -- window going away would leave you typing into a buffer you can't see.
    -- Hide it instead. This is the same hide the plugin's own toggle performs,
    -- so <leader>ac brings it straight back — cc_show's first branch un-hides a
    -- config-hidden float rather than building a new one.
    --
    -- Deferred because WinLeave fires before focus lands: re-check that we
    -- really did end up somewhere else, so transient focus changes don't cause
    -- the float to flicker away underneath you.
    --
    -- Landing on another *float* doesn't count. Pickers, which-key and the like
    -- draw on top of Claude and hand focus straight back when they close; hiding
    -- underneath them is both pointless and the source of the bug the WinEnter
    -- autocmd below guards against.
    vim.api.nvim_create_autocmd("WinLeave", {
      group = augroup,
      desc = "Hide the Claude float when focus leaves it",
      callback = function()
        local leaving = vim.api.nvim_get_current_win()
        if claude_win() ~= leaving then
          return
        end
        vim.schedule(function()
          if not (vim.api.nvim_win_is_valid(leaving) and vim.api.nvim_get_current_win() ~= leaving) then
            return
          end
          if vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative ~= "" then
            return -- landed on a float; Claude stays live underneath it
          end
          pcall(vim.api.nvim_win_set_config, leaving, { hide = true })
        end)
      end,
    })

    -- Keep the float's visibility in step with where focus actually is. Two
    -- rules, one callback, because they are the two halves of the same
    -- invariant: the Claude float is drawn if and only if it has focus.
    --
    -- 1. Focused *and* hidden. Any focus round-trip through a focusable window
    --    that ends back on the Claude float leaves the WinLeave hide already
    --    applied — cursor in the terminal, window not drawn, so you type into
    --    something you can't see. To the plugin that window isn't visible, so
    --    <leader>ac takes simple_toggle's *show* branch and focuses Claude
    --    instead of toggling away from it. Being the current window is the
    --    definition of wanting to see it, so un-hide on entry.
    --
    -- 2. Visible *and* unfocused, which is the same fault the other way round
    --    and the more dangerous one. WinLeave deliberately does not hide when
    --    focus lands on a float, because a picker normally hands it straight
    --    back — but a chain of floats need not end where it started. Measured:
    --    from inside Claude, `<leader>?` then picking a guide then `q` leaves
    --    focus in the ordinary window *underneath* a still-drawn full-screen
    --    float. Claude is never left a second time, so no WinLeave fires and
    --    nothing rechecks. Typing then edits the file behind the float: `iZZZ`
    --    turned a buffer reading "hello" into "ZZZhello", invisibly.
    --
    --    Landing on another float is still exempt, for the same reason as in
    --    WinLeave — that one may yet hand focus back.
    vim.api.nvim_create_autocmd("WinEnter", {
      group = augroup,
      desc = "Draw the Claude float if and only if it has focus",
      callback = function()
        local claude = claude_win()
        if not claude then
          return
        end
        local win = vim.api.nvim_get_current_win()
        local cfg = vim.api.nvim_win_get_config(win)

        if win == claude then
          if cfg.relative ~= "" and cfg.hide then
            pcall(vim.api.nvim_win_set_config, win, { hide = false })
          end
          return
        end

        if cfg.relative ~= "" then
          return -- still on a float, which may hand focus back to Claude
        end
        local ccfg = vim.api.nvim_win_get_config(claude)
        if ccfg.relative ~= "" and not ccfg.hide then
          pcall(vim.api.nvim_win_set_config, claude, { hide = true })
        end
      end,
    })
  end,

  opts = {
    -- Follow the selection over to Claude. Without this, a send calls
    -- terminal.ensure_visible() rather than terminal.open(): it un-hides the
    -- float but leaves the cursor in the source buffer — which, at full screen,
    -- is now completely behind the float. The frame is up with no cursor in it
    -- and keystrokes go to a window you can't see. (The two <C-/> presses that
    -- fixed it were hide-then-show-with-focus, not a redraw.)
    focus_after_send = true,

    -- `claude` is on PATH (/opt/homebrew/bin/claude), so terminal_cmd stays nil.
    -- auto_start = true is what writes the lock file; leaving it on is what
    -- makes the tmux-side CLI able to find this editor at all.
    terminal = {
      provider = "snacks",
      -- Don't startinsert on focus. Otherwise re-entering the terminal snaps
      -- Claude to its prompt, so a scroll position never survives a trip out to
      -- a buffer and back. Costs an `i` before typing a prompt.
      auto_insert = false,
      snacks_win_opts = {
        position = "float",
        -- Snacks reads 0 as "full parent size" (a fraction < 1 would scale, and
        -- 1 would mean one single cell). No border and no backdrop: at full
        -- screen a border only eats two columns, and a backdrop would stay
        -- behind as a dimmed overlay when the float above it is hidden.
        width = 0,
        height = 0,
        border = "none",
        backdrop = false,
        keys = {
          -- Snacks' terminal style binds <Esc><Esc> to stopinsert, but only
          -- swallows the second press if it lands within 200ms; slower than
          -- that and both escapes reach Claude, which reads them as its own
          -- double-Esc and opens rewind. Esc has no substitute on Claude's side
          -- (single = interrupt, double = rewind), so hand it over entirely and
          -- leave insert mode with <C-\>, which no terminal program consumes.
          term_normal = false,

          -- ...which leaves <C-x> as the way out of terminal mode, from
          -- config/keymaps.lua. That's fine: it wraps the built-in
          -- <C-\><C-n>, and it is the one key here that has to be something
          -- Claude's TUI won't eat.
          --
          -- <C-/> is the float toggle instead — one keystroke to send Claude
          -- away from inside it, matching the same key in any other buffer.
          -- Claude's input line doesn't use it.
          --
          -- Note the rhs is a function, not "<cmd>ClaudeCode<cr>": Snacks reads a
          -- string rhs in win.keys as an *action name* (win.lua M:action), looks
          -- it up in opts.actions or as a method on the window, and when neither
          -- exists returns it from a non-expr function — so the key silently does
          -- nothing. A function rhs is called directly.
          --
          -- Bound twice on purpose. Without tmux's `extended-keys on` (see
          -- dot_tmux.conf, currently commented out) Ctrl-/ reaches Neovim as
          -- 0x1f, i.e. <C-_>; with the kitty protocol in play it arrives as a
          -- real <C-/>. Neovim keeps those two distinct, so bind both and the
          -- key works either way.
          claude_toggle = {
            "<C-/>",
            toggle_float,
            mode = { "t", "n" },
            desc = "Toggle Claude",
          },
          claude_toggle_legacy = {
            "<C-_>",
            toggle_float,
            mode = { "t", "n" },
            desc = "Toggle Claude",
          },
        },
      },
    },
    diff_opts = {
      layout = "vertical",
      -- Reviewing an edit is the one job that genuinely wants two windows side
      -- by side, so give it its own tab and leave Claude out of it: the diff
      -- gets the full screen, and the float isn't covering what you're reading.
      open_in_new_tab = true,
      hide_terminal_in_new_tab = true,
      -- Land in the diff to review it, rather than being left in the terminal.
      keep_terminal_focus = false,
      -- The diff lifecycle otherwise tries to resize the terminal to a split
      -- width, which means nothing to a float and nothing at all once
      -- hide_terminal_in_new_tab keeps it out of the diff tab.
      auto_resize_terminal = false,
    },
  },

  keys = {
    { "<leader>ac", toggle_float, desc = "Toggle Claude" },
    -- The same toggle from anywhere in the editor. Buffer-local keys win over
    -- global ones, so inside Claude the snacks_win_opts pair takes these over —
    -- they do the same thing either way.
    { "<C-/>", toggle_float, mode = "n", desc = "Toggle Claude" },
    { "<C-_>", toggle_float, mode = "n", desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>az", toggle_width, desc = "Toggle Claude width (full/side)" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume session" },
    -- `al` rather than `aC`: continuing the last session has nothing to do with
    -- toggling the window on <leader>ac, and a capital that means an unrelated
    -- action rather than a wider one is the one case convention this config
    -- tries to keep. `l` as in last; it sits beside ar, which picks a session.
    { "<leader>al", "<cmd>ClaudeCode --continue<cr>", desc = "Continue last session" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
    -- Context
    {
      "<leader>ab",
      function()
        -- `ClaudeCodeAdd %` expands to nothing in a buffer with no name, and
        -- the plugin logs "No file path provided" — accurate, but it fires in
        -- a codediff pane where there *is* a file to add.
        local target = buffer_file()
        if not target then
          vim.notify("Claude: this buffer has no file to reference", vim.log.levels.WARN)
          return
        end
        vim.cmd("ClaudeCodeAdd " .. vim.fn.fnameescape(target))
      end,
      desc = "Add current buffer",
    },
    {
      "<leader>as",
      function()
        -- A buffer with no file cannot be at-mentioned, and the plugin does not
        -- stop itself: its sanity check compares the tracked selection's
        -- filePath against the buffer name, which for a scratch or no-name
        -- buffer are both "" and so compare equal. It then formats that empty
        -- string and throws, surfacing as
        --
        --   Failed to send at-mention: format_path_for_at_mention:
        --   file_path must be a non-empty string
        --
        -- Say so plainly instead. Yanking and pasting into the float is the way
        -- to send text with no file behind it.
        if vim.api.nvim_buf_get_name(0) ~= "" then
          vim.cmd("ClaudeCodeSend")
          return
        end

        local target = buffer_file()
        if not target then
          vim.notify("Claude: this buffer has no file to reference", vim.log.levels.WARN)
          return
        end

        local first, last = vim.fn.line("v"), vim.fn.line(".")
        if first > last then
          first, last = last, first
        end

        -- Send line numbers only when they still describe the file on disk.
        -- The inline layout draws deletions as virtual lines, so buffer line N
        -- is file line N — but the pane may be showing a revision rather than
        -- the working tree, and then the numbers would point at the wrong
        -- place. Comparing the selected lines is cheap and settles it; when
        -- they disagree the file is referenced without a range, which is vague
        -- rather than wrong.
        local shown = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
        local on_disk = vim.fn.readfile(target, "", last)
        local same = true
        for i, line in ipairs(shown) do
          if on_disk[first + i - 1] ~= line then
            same = false
            break
          end
        end

        local cmd = "ClaudeCodeAdd " .. vim.fn.fnameescape(target)
        if same then
          cmd = ("%s %d %d"):format(cmd, first, last)
        end
        vim.cmd(cmd)
      end,
      mode = "x",
      desc = "Send selection",
    },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      ft = { "oil", "snacks_picker_list", "netrw" },
      desc = "Add file under cursor",
    },
    -- Diff review
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ax", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Reject diff" },
    -- Server
    { "<leader>a?", "<cmd>ClaudeCodeStatus<cr>", desc = "Server status" },
  },
}
