-- claudecode.nvim — Claude Code IDE integration, in the same spirit as the
-- official VS Code/JetBrains extensions but pure Lua.
--
-- What it actually is: a WebSocket MCP server hosted *by Neovim*. On startup it
-- picks a port and writes ~/.claude/ide/<port>.lock describing this editor and
-- its workspace. Any `claude` CLI started afterwards in the same project finds
-- that lock file and connects — so the editor gains selection context, @-mention
-- sends, and in-editor diff review for proposed edits.
--
-- Two ways to run Claude against it, both supported here:
--
--   1. In-editor: <leader>ac opens Claude in a snacks terminal split. Quick
--      questions without leaving nvim.
--   2. In tmux: run `claude` in another window of the same session (prefix+C,
--      see dot_tmux.conf). It auto-connects to this nvim's server — `/ide` in
--      the CLI picks the editor by hand if it doesn't. This is the full-terminal
--      Claude, with image paste and the whole UI.
--
-- Both connect to the same server, so <leader>as (send selection) reaches
-- whichever session is live. The ClaudeCodeSendComplete hook below follows the
-- send to the tmux window when Claude isn't running inside the editor.

local augroup = vim.api.nvim_create_augroup("claudecode_tmux", { clear = true })

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

-- Toggle the Claude split between its configured width and full width.
--
-- `<C-w>|` maximises, but there is no built-in way back: `<C-w>=` equalises
-- every window rather than restoring the 35% split. So stash the pre-zoom width
-- on the window and restore that.
local function toggle_zoom()
  local win = claude_win()
  if not win then
    vim.notify("Claude terminal isn't open", vim.log.levels.WARN)
    return
  end
  vim.api.nvim_win_call(win, function()
    local unzoomed = vim.w.claude_unzoomed_width
    if unzoomed then
      vim.api.nvim_win_set_width(0, unzoomed)
      vim.w.claude_unzoomed_width = nil
    else
      vim.w.claude_unzoomed_width = vim.api.nvim_win_get_width(0)
      -- Over-wide is clamped to whatever the other windows can spare, which is
      -- what `wincmd |` does; done via the API to avoid `|` needing escaping.
      vim.api.nvim_win_set_width(0, vim.o.columns)
    end
  end)
end

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },

  -- The server has to be listening before a `claude` in another tmux window can
  -- discover it, and lazy-loading on <leader>a would mean it isn't. Load on
  -- VeryLazy so the lock file exists as soon as the editor settles.
  event = "VeryLazy",

  init = function()
    -- After sending a selection, follow it to wherever Claude actually is.
    -- Skipped when an in-editor terminal is running (the send is already
    -- visible), and a no-op outside tmux or when no `claude` window exists —
    -- tmux's error goes to the captured stderr, not the message area.
    vim.api.nvim_create_autocmd("User", {
      pattern = "ClaudeCodeSendComplete",
      group = augroup,
      desc = "Focus the tmux claude window after sending a selection",
      callback = function()
        if not vim.env.TMUX then
          return
        end
        local ok, terminal = pcall(require, "claudecode.terminal")
        if ok and terminal.get_active_terminal_bufnr() then
          return -- Claude is in the editor; stay put
        end
        vim.system({ "tmux", "select-window", "-t", "claude" })
      end,
    })
  end,

  opts = {
    -- `claude` is on PATH (/opt/homebrew/bin/claude), so terminal_cmd stays nil.
    -- auto_start = true is what writes the lock file; leaving it on is what
    -- makes the tmux-side CLI able to find this editor at all.
    terminal = {
      provider = "snacks",
      split_side = "right",
      -- A split rather than a float on purpose: proposed edits open as a diff in
      -- the editor, and a split lets the diff and the conversation sit side by
      -- side. A float would cover the thing being reviewed.
      split_width_percentage = 0.35,
      snacks_win_opts = {
        keys = {
          -- Snacks' terminal style binds <Esc><Esc> to stopinsert, but only
          -- swallows the second press if it lands within 200ms; slower than
          -- that and both escapes reach Claude, which reads them as its own
          -- double-Esc and opens rewind. Esc has no substitute on Claude's side
          -- (single = interrupt, double = rewind), so hand it over entirely and
          -- leave insert mode with the built-in <C-\><C-n>, which no terminal
          -- program consumes.
          term_normal = false,

          -- Zoom without leaving terminal mode. <C-\> is Neovim's terminal
          -- escape prefix, so Claude's TUI never sees it — unlike <C-w>, which
          -- its input line uses for delete-word.
          claude_zoom = {
            "<C-\\>z",
            function()
              toggle_zoom()
            end,
            mode = "t",
            desc = "Zoom toggle",
          },
        },
      },
    },
    diff_opts = {
      layout = "vertical",
      -- Land in the diff to review it, rather than being left in the terminal.
      keep_terminal_focus = false,
    },
  },

  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude (in editor)" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>az", toggle_zoom, desc = "Zoom Claude split (toggle)" },
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
