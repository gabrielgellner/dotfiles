-- Scratch notebooks — snacks.nvim scratch buffers used as a running work log.
--
-- Two tiers of notes in this config:
--   * scratch (here) — the working log: thinking out loud, TODOs for the branch
--     you're on, questions raised while reviewing code, half-formed plans. Zero
--     friction: one key opens it, it auto-saves when hidden, and it's keyed to
--     the project you're in.
--   * zk (`<leader>z…`, see plugins/zk.lua) — the second brain: notes worth
--     keeping, linked and indexed. `M.promote()` moves a scratch into it.
--
-- Snacks stores scratch files under an opaque hashed name (with a `.meta`
-- sidecar holding the name/cwd/branch), so the on-disk directory isn't meant to
-- be browsed by hand — `<leader>ns` (the scratch picker) is the index. The root
-- is ~/scratch rather than nvim's data dir so the notes survive a plugin/data
-- wipe and can be committed if wanted.
--
-- Notes accumulate under `## YYYY-MM-DD` day headings: opening a notebook on a
-- new day appends today's heading and drops the cursor at the bottom, so a
-- notebook reads as a journal rather than a soup of undated fragments.

local M = {}

local DAY = "^## (%d%d%d%d%-%d%d%-%d%d)%s*$"

-- Seed an empty notebook with a title naming what it's for.
---@param buf integer
---@param title string
local function seed(buf, title)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #lines > 1 or (lines[1] or "") ~= "" then
    return
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "# " .. title, "" })
end

-- Append a `## <today>` heading unless the newest one already is today.
---@param buf integer
local function stamp_today(buf)
  local today = os.date("%Y-%m-%d")
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i = #lines, 1, -1 do
    local day = lines[i]:match(DAY)
    if day then
      if day == today then
        return
      end
      break -- newest heading is an older day: fall through and stamp
    end
  end
  local last = #lines
  while last > 0 and lines[last]:match("^%s*$") do
    last = last - 1 -- don't stack blank lines from the previous session
  end
  local add = last == 0 and { "## " .. today, "" } or { "", "## " .. today, "" }
  vim.api.nvim_buf_set_lines(buf, last, -1, false, add)
end

--- Open (or toggle closed) a scratch notebook.
--- `vim.v.count1` picks between numbered notebooks, e.g. `2<leader>nn`.
---@param opts? snacks.scratch.Config
function M.open(opts)
  opts = opts or {}
  local title = opts.name or Snacks.config.get("scratch", {}).name or "Scratch"
  if opts.filekey == nil or opts.filekey.cwd ~= false then
    title = title .. " — " .. vim.fn.fnamemodify(vim.uv.cwd() or "", ":t")
  end
  if vim.v.count1 > 1 then
    title = title .. " " .. vim.v.count1
  end

  local win = Snacks.scratch.open(opts)
  if not win then
    return -- the notebook was already visible; open() toggled it closed
  end
  seed(win.buf, title)
  stamp_today(win.buf)
  vim.api.nvim_win_call(win.win, function()
    vim.cmd("normal! G")
  end)
  return win
end

--- Promote the current buffer into a permanent zk note, then open it.
--- Use this when a scratch section outgrows the working log. The scratch is
--- left untouched — prune it by hand once the note exists.
---
--- For a *part* of a notebook, select it and use `<leader>zc`
--- (ZkNewFromContentSelection) instead.
function M.promote()
  local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  if vim.trim(content) == "" then
    return vim.notify("scratch: nothing to promote", vim.log.levels.WARN)
  end
  local title = vim.fn.input("Note title: ")
  if title == "" then
    return
  end
  -- Pass the notebook explicitly: the scratch root isn't inside a notebook, so
  -- zk can't infer one from the buffer path.
  local notebook = vim.env.ZK_NOTEBOOK_DIR or vim.fn.expand("~/notes")
  require("zk.api").new(notebook, { title = title, content = content, edit = true }, function(err)
    if err then
      vim.notify("zk: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

return M
