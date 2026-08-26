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

--- Is `buf` one of snacks' scratch notebooks?
---
--- By path under the configured scratch root, read from the same place snacks
--- reads it when deciding where to write. snacks sets no marker variable on
--- the buffer, and the filename is an opaque hash, so the directory is the
--- only thing available to test.
---@param buf integer
local function is_scratch(buf)
  local root = Snacks.config.get("scratch", {}).root or (vim.fn.stdpath("data") .. "/scratch")
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return false
  end
  return vim.fs.normalize(name):find(vim.fs.normalize(root), 1, true) == 1
end

--- Drop the title `seed()` wrote, so the promoted note has one H1 and not two.
---
--- Only the leading `# …` and the blank lines under it. The `## <date>` day
--- headings stay: in a notebook spanning several days they are the structure
--- of what is being promoted, not scaffolding, and dropping just the first
--- would misdate everything under it.
---@param lines string[]
---@return string[]
local function strip_title(lines)
  local i = 1
  if (lines[1] or ""):match("^#%s+%S") then
    i = 2
    while (lines[i] or ""):match("^%s*$") do
      i = i + 1
    end
  end
  return vim.list_slice(lines, i)
end

--- Promote the current scratch notebook into a permanent zk note, then open it.
--- Use this when a scratch section outgrows the working log. The scratch is
--- left untouched — prune it by hand once the note exists.
---
--- Scratch buffers only. This used to promote whatever buffer was current,
--- with nothing in the prompt to say what it was about to copy, so `<leader>np`
--- pressed in a source file would offer to put the whole file in the notebook
--- as quietly as it would a five-line note.
---
--- For a *part* of a notebook, select it and use `<leader>zc`
--- (ZkNewFromContentSelection) instead.
function M.promote()
  if not is_scratch(0) then
    return vim.notify(
      "scratch: <leader>np promotes a scratch notebook, and this is not one.\n"
        .. "Open one with <leader>nn, or select part of this buffer and use <leader>zc.",
      vim.log.levels.WARN
    )
  end
  local lines = strip_title(vim.api.nvim_buf_get_lines(0, 0, -1, false))
  -- Emptiness has to mean "no prose", not "no characters". A notebook opened
  -- today and not yet written in still holds `## <date>` from stamp_today(),
  -- so a plain trim call sees content and lets you promote a heading with
  -- nothing under it — which is what it did until this was measured.
  local has_body = false
  for _, line in ipairs(lines) do
    if not line:match("^%s*$") and not line:match(DAY) then
      has_body = true
      break
    end
  end
  if not has_body then
    return vim.notify("scratch: nothing to promote — this notebook has no notes in it yet", vim.log.levels.WARN)
  end
  local content = table.concat(lines, "\n")
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
