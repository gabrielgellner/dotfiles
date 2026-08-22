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

-- Step in and out of terminal mode with one key.
--
-- Normal mode is for scrolling and yanking Claude's output; terminal mode is
-- for typing at it. auto_insert is off, so nothing puts you back at the prompt
-- on its own — this is the way back.
local function toggle_mode()
  if vim.api.nvim_get_mode().mode == "t" then
    vim.cmd.stopinsert()
  else
    vim.cmd.startinsert()
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
    vim.api.nvim_create_autocmd("WinLeave", {
      group = augroup,
      desc = "Hide the Claude float when focus leaves it",
      callback = function()
        local leaving = vim.api.nvim_get_current_win()
        if claude_win() ~= leaving then
          return
        end
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(leaving) and vim.api.nvim_get_current_win() ~= leaving then
            pcall(vim.api.nvim_win_set_config, leaving, { hide = true })
          end
        end)
      end,
    })
  end,

  opts = {
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
          -- leave insert mode with the built-in <C-\><C-n>, which no terminal
          -- program consumes.
          term_normal = false,

          -- ...which leaves <C-\><C-n> as the only way out of terminal mode,
          -- and that chord is slow for something pressed this often. <C-/> is
          -- one keystroke and Claude's input line doesn't use it.
          --
          -- Bound twice on purpose. Without tmux's `extended-keys on` (see
          -- dot_tmux.conf, currently commented out) Ctrl-/ reaches Neovim as
          -- 0x1f, i.e. <C-_>; with the kitty protocol in play it arrives as a
          -- real <C-/>. Neovim keeps those two distinct, so bind both and the
          -- key works either way.
          claude_mode = {
            "<C-/>",
            toggle_mode,
            mode = { "t", "n" },
            desc = "Toggle Claude terminal/normal mode",
          },
          claude_mode_legacy = {
            "<C-_>",
            toggle_mode,
            mode = { "t", "n" },
            desc = "Toggle Claude terminal/normal mode",
          },

          -- Resize without leaving terminal mode. <C-\> is Neovim's terminal
          -- escape prefix, so Claude's TUI never sees it — unlike <C-w>, which
          -- its input line uses for delete-word.
          claude_width = {
            "<C-\\>z",
            function()
              toggle_width()
            end,
            mode = "t",
            desc = "Toggle Claude width",
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
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>az", toggle_width, desc = "Toggle Claude width (full/side)" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume session" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue last session" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
    -- Context
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
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
