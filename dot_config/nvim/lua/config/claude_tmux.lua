-- claudecode.nvim's terminal, as a tmux window instead of a float.
--
-- config/claude_kitty.lua, for tmux: under tmux (the work VM in xterm, and any
-- tmux started by hand) Claude gets its own window in the project's session,
-- beside nvim and the console. That is what puts its output in tmux's history,
-- which `prefix + [` opens in nvim (bin/tmux-scrollback, guides/scrollback.md).
-- plugins/claudecode.lua hands this table to the plugin as `terminal.provider`
-- inside tmux; an nvim outside both tmux and kitty keeps the float.
--
-- The window is found each time by a window option, `@dev_role claude`, in
-- this nvim's session — the tmux spelling of kitty's `--var dev_role=claude`.
-- Not by its name, which `prefix + ,` can change, and nothing is cached, so a
-- Claude quit or killed by hand is simply not found next time.
--
-- The IDE connection is unchanged: the plugin passes `env_table`
-- (CLAUDE_CODE_SSE_PORT, ENABLE_IDE_INTEGRATION), which goes onto the window
-- with -e, so the new Claude connects to this nvim's server as the float's
-- did. The status-bar hooks need nothing: claude-tmux-state keys on $TMUX_PANE,
-- which a window of its own has like any other.

local M = {}

---@param args string[]
---@return boolean ok, string stdout
local function tmux(args)
  local cmd = { "tmux" }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, { text = true }):wait()
  return res.code == 0, vim.trim(res.stdout or "")
end

---This nvim's session, as an id (`$3`): exact as a target whatever the name
---holds, where a name would need `=` and a trailing colon (see bin/dev).
---Resolved through our own pane, since display-message without -t answers for
---whichever client is attached.
---@return string|nil
local function session()
  local ok, out = tmux({ "display-message", "-p", "-t", vim.env.TMUX_PANE or "", "#{session_id}" })
  return (ok and out ~= "") and out or nil
end

---This session's Claude window: its id and whether it is the one on screen.
---@return string|nil id, boolean active
local function claude_window()
  local sess = session()
  if not sess then
    return nil, false
  end
  local ok, out = tmux({ "list-windows", "-t", sess .. ":", "-F", "#{window_id} #{window_active} #{@dev_role}" })
  if not ok then
    return nil, false
  end
  for line in out:gmatch("[^\n]+") do
    local id, active, role = line:match("^(%S+) (%d) (.*)$")
    if role == "claude" then
      return id, active == "1"
    end
  end
  return nil, false
end

---@param id string
local function focus(id)
  tmux({ "select-window", "-t", id })
end

---Start Claude in a new window of this session.
---
---The command runs under tmux's default-shell with -c, so a non-interactive
---zsh: dot_zshenv is what gives it the PATH a console has. `cmd_string` is the
---plugin's `claude ...`, word-split by that shell as the plugin's own
---providers do.
---@param cmd_string string
---@param env_table table<string, string>
---@param keep_focus boolean
local function launch(cmd_string, env_table, keep_focus)
  local sess = session()
  if not sess then
    vim.notify("Claude: could not resolve this tmux session", vim.log.levels.ERROR)
    return
  end
  local args = { "new-window", "-t", sess .. ":", "-n", "claude", "-c", vim.fn.getcwd(), "-P", "-F", "#{window_id}" }
  if keep_focus then
    table.insert(args, "-d")
  end
  for k, v in pairs(env_table or {}) do
    vim.list_extend(args, { "-e", ("%s=%s"):format(k, v) })
  end
  table.insert(args, cmd_string)
  local ok, id = tmux(args)
  if not ok or id == "" then
    vim.notify("Claude: tmux new-window failed", vim.log.levels.ERROR)
    return
  end
  tmux({ "set-option", "-w", "-t", id, "@dev_role", "claude" })
end

function M.setup(_) end

function M.is_available()
  return true
end

-- Set while ensure_visible goes through the plugin's open().
local keep_focus = false

---Go to this session's Claude, starting one if there is none.
function M.open(cmd_string, env_table)
  local id = claude_window()
  if id then
    if not keep_focus then
      focus(id)
    end
  else
    launch(cmd_string, env_table, keep_focus)
  end
end

---Is a Claude running in this session?
---@return boolean
function M.running()
  return claude_window() ~= nil
end

function M.close()
  local id = claude_window()
  if id then
    tmux({ "kill-window", "-t", id })
  end
end

-- Called from nvim, so nvim is on screen whenever these run: "toggle" can only
-- mean "go to Claude". Going back is tmux's job — `C-/` in Claude's window,
-- bound in dot_tmux.conf — since a key pressed there never reaches nvim.
M.simple_toggle = M.open
M.focus_toggle = M.open

---Start Claude without moving focus, for a send made before one is running.
function M.ensure_visible()
  if not claude_window() then
    -- The plugin builds the command and env only inside its own entry points,
    -- so go through one; open() then sees no window and launches.
    keep_focus = true
    pcall(require("claudecode.terminal").open)
    keep_focus = false
  end
end

-- No nvim buffer: Claude's screen belongs to tmux.
function M.get_active_bufnr()
  return nil
end

-- Diff review happens in nvim, but Claude proposes the edit while you are
-- watching Claude's window, so the diff would open out of sight. Go to nvim's
-- window when one opens, and back to Claude once it is accepted or rejected —
-- the round trip the float made without anyone moving. Only when Claude's
-- window was the one on screen: a diff arriving while you are already in nvim
-- moves nothing, and resolving it leaves you there.
local returned_from
function M.follow_diffs()
  local group = vim.api.nvim_create_augroup("claude_tmux_diffs", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "ClaudeCodeDiffOpened",
    callback = function()
      local id, active = claude_window()
      returned_from = active and id or nil
      if returned_from and vim.env.TMUX_PANE then
        focus(vim.env.TMUX_PANE)
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "ClaudeCodeDiffClosed",
    callback = function()
      if returned_from then
        focus(returned_from)
        returned_from = nil
      end
    end,
  })
end

return M
