-- Personal guides — hand-written markdown reference cards, opened from a picker.
--
-- These are the third tier of notes in this config, and the only read-mostly
-- one:
--   * scratch (`<leader>n…`, config/scratch.lua) — today's working log
--   * zk      (`<leader>z…`, plugins/zk.lua)     — the linked second brain
--   * guides  (here)                             — reference you reread
--
-- They live in the nvim config directory rather than with the other notes on
-- purpose: a guide here documents *this config's* keymaps, so it should travel
-- with the config, be versioned alongside the keymap it describes, and go stale
-- in the same commit that changes one.
--
-- The other way to do this in vim is native `:help` — a vimdoc .txt under
-- ~/.config/nvim/doc/ plus `:helptags ALL` gives you `:h <tag>` and shows up in
-- `<leader>fh` for free. That's more integrated, but vimdoc's tag/column syntax
-- is fussy to write and it renders as plain text. Markdown wins here because
-- render-markdown.nvim already makes it look right and it stays editable.

local M = {}

local DIR = vim.fn.stdpath("config") .. "/guides"

-- A guide's display name is its first `# Heading`, so the picker lists prose
-- titles rather than filenames. Bounded read: the title is at the top of the
-- file or the file doesn't have one.
---@param path string
---@return string?
local function title_of(path)
  local fh = io.open(path, "r")
  if not fh then
    return nil
  end
  local title
  for _ = 1, 20 do
    local line = fh:read("l")
    if not line then
      break
    end
    title = line:match("^#%s+(.+)$")
    if title then
      break
    end
  end
  fh:close()
  return title
end

---@return snacks.picker.finder.Item[]
local function items()
  local out = {}
  if not vim.uv.fs_stat(DIR) then
    return out
  end
  for name, kind in vim.fs.dir(DIR) do
    if kind == "file" and name:match("%.md$") then
      local path = DIR .. "/" .. name
      table.insert(out, { file = path, text = title_of(path) or (name:gsub("%.md$", "")) })
    end
  end
  table.sort(out, function(a, b)
    return a.text < b.text
  end)
  return out
end

--- Follow a `[text](other.md)` link, or a bare `other.md`, to another guide.
---
--- Plain `gf` cannot do this: the float's 'path' is `.,,` and resolves against
--- the *cwd*, not the guides directory, so a relative link between guides never
--- opens. Resolving by basename here also means the link text can stay short.
---@param win snacks.win
local function follow(win)
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")

  -- Prefer the link the cursor is actually inside, matching on the whole
  -- `[text](dest)` span rather than just the parenthesised half — the cursor is
  -- normally on the words, not the filename. A see-also line carries several
  -- links, and taking the first would ignore which one was pointed at.
  local target
  local from = 1
  while true do
    local a, b, dest = line:find("%[[^%]]*%]%((%S-%.md)%)", from)
    if not a then
      break
    end
    if col >= a and col <= b then
      target = dest
      break
    end
    target = target or dest -- first link on the line, if the cursor is on none
    from = b + 1
  end
  target = target or vim.fn.expand("<cfile>")
  if type(target) ~= "string" or not target:match("%.md$") then
    vim.notify("guides: no guide link on this line", vim.log.levels.WARN)
    return
  end
  local path = DIR .. "/" .. vim.fs.basename(target)
  if not vim.uv.fs_stat(path) then
    vim.notify("guides: no such guide: " .. vim.fs.basename(target), vim.log.levels.WARN)
    return
  end
  win:close()
  M.open(path)
end

--- Open one guide in a float, styled for reading rather than editing.
---@param path string
function M.open(path)
  Snacks.win({
    file = path,
    width = 0.7,
    height = 0.85,
    border = "rounded",
    title = " " .. (title_of(path) or vim.fn.fnamemodify(path, ":t")) .. " ",
    title_pos = "center",
    wo = {
      winhighlight = "NormalFloat:Normal",
      wrap = true,
      linebreak = true,
      number = false,
      relativenumber = false,
      signcolumn = "no",
      spell = false,
      conceallevel = 2, -- let render-markdown conceal the syntax
    },
    keys = {
      q = "close",
      -- `gf` because these *are* file references; it just needs help resolving
      -- them. <CR> is already the checkbox toggle in markdown buffers.
      gf = follow,
    },
  })
end

--- Pick a guide.
---
--- Always the picker, even for a single guide. Short-circuiting to open the one
--- guide directly saves a keystroke now and costs a surprise later: <leader>?
--- would quietly change from "open the navigation guide" to "choose a guide" on
--- the day a second file lands. The preview pane also makes the list worth
--- reading in its own right.
function M.pick()
  local list = items()
  if #list == 0 then
    vim.notify("guides: nothing in " .. DIR, vim.log.levels.WARN)
    return
  end
  Snacks.picker({
    title = "Guides",
    finder = items,
    format = "text",
    preview = "file",
    confirm = function(picker, item)
      picker:close()
      if item then
        M.open(item.file)
      end
    end,
  })
end

return M
