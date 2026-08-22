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

-- ── <C-/>: toggle the float ─────────────────────────────────────────────────
--
-- One key, one job, from inside Claude or from any buffer. No timing involved:
-- the tap acts immediately, so there's no timeoutlen stall and no double-press
-- to get right.
--
-- Getting to normal mode inside the terminal is a separate key, <C-\><C-n> —
-- Neovim's built-in, which no terminal program consumes. Normal mode is for
-- scrolling and yanking Claude's output; `i` goes back to typing at it.

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

    -- Self-heal the one state that breaks the toggle: focused *and* hidden.
    --
    -- Any focus round-trip through a focusable window that ends back on the
    -- Claude float leaves the WinLeave hide already applied — cursor in the
    -- terminal, window not drawn, so you type into something you can't see. To
    -- the plugin that window isn't visible, so <leader>ac takes simple_toggle's
    -- *show* branch and focuses Claude instead of toggling away from it.
    --
    -- Being the current window is the definition of wanting to see it, so
    -- un-hide on entry and the state can't persist.
    vim.api.nvim_create_autocmd("WinEnter", {
      group = augroup,
      desc = "Un-hide the Claude float if focus lands in it while hidden",
      callback = function()
        local win = vim.api.nvim_get_current_win()
        if claude_win() ~= win then
          return
        end
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative ~= "" and cfg.hide then
          pcall(vim.api.nvim_win_set_config, win, { hide = false })
        end
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

          -- ...which leaves <C-\><C-n> as the way out of terminal mode. That's
          -- fine: it's a built-in, and it's the only key here that has to be
          -- something Claude's TUI won't eat.
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
            function()
              vim.cmd("ClaudeCode")
            end,
            mode = { "t", "n" },
            desc = "Toggle Claude",
          },
          claude_toggle_legacy = {
            "<C-_>",
            function()
              vim.cmd("ClaudeCode")
            end,
            mode = { "t", "n" },
            desc = "Toggle Claude",
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
    -- The same toggle from anywhere in the editor. Buffer-local keys win over
    -- global ones, so inside Claude the snacks_win_opts pair takes these over —
    -- they do the same thing either way.
    { "<C-/>", "<cmd>ClaudeCode<cr>", mode = "n", desc = "Toggle Claude" },
    { "<C-_>", "<cmd>ClaudeCode<cr>", mode = "n", desc = "Toggle Claude" },
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
