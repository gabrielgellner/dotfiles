-- claudecode.nvim's terminal, as a kitty tab instead of a float.
--
-- Under kitty (the laptop, where kitty is the multiplexer) Claude gets its own
-- tab in the project's session, beside nvim and the consoles. That is what makes
-- its output ordinary kitty scrollback, which `ctrl+a>[` opens in nvim (see
-- guides/scrollback.md). plugins/claudecode.lua hands this table to the plugin
-- as `terminal.provider` only under kitty; tmux machines keep the float.
--
-- The plugin's own "external" provider is not enough. It cannot find a running
-- Claude again, so its toggle *stops the job* — for a launcher that has already
-- exited, a no-op, and then the next toggle starts a second Claude. Here the
-- tab is found each time by its user var, `dev_role=claude`, in this session
-- (`session:.`), the same way just.lua finds consoles. Nothing is cached, so a
-- Claude quit or killed by hand is simply not found next time.
--
-- The IDE connection is unchanged: the plugin passes `env_table`
-- (CLAUDE_CODE_SSE_PORT, ENABLE_IDE_INTEGRATION), which goes onto the tab with
-- --env, so the new Claude connects to this nvim's server as the float's did —
-- diffs, <leader>as and <leader>ab all go through that socket, not the window.

local M = {}

---@param args string[]
---@return boolean ok, string stdout
local function kitten(args)
  local cmd = { "kitten", "@" }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, { text = true }):wait()
  return res.code == 0, vim.trim(res.stdout or "")
end

---This session's Claude window id, or nil.
---@return integer|nil
local function claude_window()
  local ok, out = kitten({ "ls", "--match", "session:. and var:dev_role=claude" })
  if not ok then
    return nil
  end
  local decoded, data = pcall(vim.json.decode, out)
  if not decoded then
    return nil
  end
  for _, os_window in ipairs(data) do
    for _, tab in ipairs(os_window.tabs) do
      for _, w in ipairs(tab.windows) do
        return w.id
      end
    end
  end
end

---@param id integer|string
local function focus(id)
  kitten({ "focus-window", "--match", "id:" .. id })
end

---Start Claude in a new tab of this session.
---
-----copy-env takes this nvim's environment, which came from the login shell,
---so Claude's tools see the same PATH as a Claude started from a console, and
---DEV_SESSION comes along for the status-bar hook. `cmd_string` is the plugin's
---`claude ...`, word-split by the shell as the plugin's own providers do.
---@param cmd_string string
---@param env_table table<string, string>
---@param keep_focus boolean
local function launch(cmd_string, env_table, keep_focus)
  local args = {
    "launch",
    "--type=tab",
    "--copy-env",
    "--cwd=" .. vim.fn.getcwd(),
    "--tab-title=claude",
    "--var=dev_role=claude",
    "--add-to-session=.",
  }
  if keep_focus then
    table.insert(args, "--keep-focus")
  end
  for k, v in pairs(env_table or {}) do
    table.insert(args, ("--env=%s=%s"):format(k, v))
  end
  vim.list_extend(args, { vim.o.shell, "-c", cmd_string })
  local ok, out = kitten(args)
  if not ok then
    vim.notify("Claude: kitten @ launch failed: " .. out, vim.log.levels.ERROR)
  end
end

function M.setup(_) end

function M.is_available()
  return true
end

-- Set while ensure_visible goes through the plugin's open().
local keep_focus = false

---Focus this session's Claude, starting one if there is none.
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
    kitten({ "close-window", "--match", "id:" .. id })
  end
end

-- Called from nvim, so nvim has focus whenever these run: "toggle" can only
-- mean "go to Claude". Going back is kitty's job — `ctrl+/` in the Claude tab,
-- from kitty/mux.conf — since a key pressed there never reaches nvim.
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

-- No nvim buffer: Claude's screen belongs to kitty.
function M.get_active_bufnr()
  return nil
end

-- Diff review happens in nvim, but Claude proposes the edit while you are
-- watching Claude's tab, so the diff would open out of sight. Go to nvim's
-- window when one opens, and back to Claude once it is accepted or rejected —
-- the round trip the float made without anyone moving.
local returned_from
function M.follow_diffs()
  local group = vim.api.nvim_create_augroup("claude_kitty_diffs", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "ClaudeCodeDiffOpened",
    callback = function()
      returned_from = claude_window()
      if vim.env.KITTY_WINDOW_ID then
        focus(vim.env.KITTY_WINDOW_ID)
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
