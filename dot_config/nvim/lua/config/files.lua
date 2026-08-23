-- The two file browsers and the handoff between them.
--
-- They are good at opposite things, which is why both are here:
--
--   * snacks explorer — a tree you navigate. Folds open and shut, so you can
--     see several levels at once and find something without knowing its path.
--   * oil — one directory as an editable buffer. Renaming a run of files,
--     deleting several, creating a tree: it is normal editing, so `cw`, visual
--     block, `:%s/` and undo all work on the filesystem.
--
-- The workflow is find in the explorer, edit in oil. `O` in the explorer opens
-- oil on whatever directory the cursor is in; `<leader>fe` inside an oil buffer
-- goes back the other way, rooted where oil was rather than at the cwd.

local M = {}

--- Open the snacks explorer, optionally rooted somewhere other than the cwd.
---@param opts? table
function M.explorer(opts)
  return Snacks.picker.explorer(vim.tbl_deep_extend("force", {
    auto_close = true,
    layout = {
      layout = { position = "float", width = 0.4, height = 0.8 },
    },
  }, opts or {}))
end

--- From an oil buffer, open the explorer on the directory oil is showing.
function M.explorer_from_oil()
  local oil = require("oil")
  local dir = oil.get_current_dir()
  if not dir then
    -- Non-file adapters (ssh://, trash://) have no local directory to hand over.
    vim.notify("oil: no local directory here", vim.log.levels.WARN)
    return
  end
  oil.close()
  M.explorer({ cwd = dir })
end

--- From the explorer, open oil on the item's directory — the item itself when
--- it is one, otherwise its parent.
---@param picker snacks.Picker
---@param item snacks.picker.Item?
function M.oil_from_explorer(picker, item)
  -- Guard on the path rather than on `item`. An item carrying no path is as
  -- useless here as no item at all, and the `and`/`or` below is only safe once
  -- the path is known truthy: `item.dir and item.file` falls through to the
  -- `or` branch whenever item.file is nil — even with item.dir true, which is
  -- the opposite of what it reads like.
  --
  -- That failure is silent rather than loud. vim.fs.dirname(nil) returns nil,
  -- fnameescape stringifies nil to "v:null", and oil is handed a path by that
  -- name. Nothing raises; you just end up somewhere absurd.
  local path = item and item.file
  if not path then
    return
  end
  picker:close()
  vim.cmd("Oil " .. vim.fn.fnameescape(item.dir and path or vim.fs.dirname(path)))
end

return M
