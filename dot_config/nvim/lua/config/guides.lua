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
---@param lnum? integer line to land on, for a hit from the content search
function M.open(path, lnum)
  local win = Snacks.win({
    file = path,
    -- Absolute, not a fraction: 0.7 of a narrow terminal was 54 — narrower than
    -- the content, so tables overflowed.
    --
    -- Prose in these files wraps at 80 (.prettierrc), but prettier pads table
    -- cells to the widest one and never wraps a table, so the real ceiling is
    -- set by the widest row — 96 in navigation.md. 100 clears that with room
    -- for the border. If a new table overflows, the number to check is
    --   awk '{ if (length($0)>m) m=length($0) } END { print m }' guides/*.md
    -- Snacks clamps this when the editor is smaller.
    width = 100,
    height = 0.9,
    border = "rounded",
    title = " " .. (title_of(path) or vim.fn.fnamemodify(path, ":t")) .. " ",
    title_pos = "center",
    -- The same border hint the scratch float carries, which gets it from
    -- Snacks.scratch setting footer_keys = true. A read-only float has no other
    -- way to say how to leave it, and nothing at all advertises that these
    -- guides link to each other.
    --
    -- Named rather than `true`, which would list every key here — and gf does
    -- the same job as <CR>, so listing both would say one thing twice. Snacks
    -- normalises both sides of this match (win.lua), so "<CR>" is the right
    -- spelling, and it sorts entries by lhs, so this reads
    -- ` <CR>  follow link   q  close `.
    footer_keys = { "q", "<CR>" },
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
      -- The desc is what the footer prints. A bare function value gets none —
      -- snacks builds the spec as { lhs, fn } and then falls back to the lhs
      -- itself (`key.desc or keymap`), which would render " <CR>  <CR> ". The
      -- table form carries one.
      --
      -- `gf` because these *are* file references; it just needs help resolving
      -- them.
      gf = { follow, desc = "follow link" },
      -- <CR> as well, because it is what a reader presses on a link. In a
      -- markdown buffer it is otherwise the checkbox toggle
      -- (config/autocmds.lua), which here throws "Buffer is not 'modifiable'"
      -- — the float is read-only and a reference document has no checkboxes,
      -- so the toggle can only ever fail. Better the key does the useful thing.
      ["<CR>"] = { follow, desc = "follow link" },
    },
  })

  -- A content-search hit knows the line, and landing on the match is the whole
  -- point of searching. zz because a hit at the bottom of a file otherwise
  -- opens with the match on the last row of the float.
  if lnum then
    pcall(vim.api.nvim_win_set_cursor, win.win, { lnum, 0 })
    vim.api.nvim_win_call(win.win, function()
      vim.cmd("normal! zz")
    end)
  end
end

--- Search the guides' *contents*, as opposed to their titles.
---
--- The picker lists titles, which is right for "open the git guide" and useless
--- for "which guide mentions `zx`" — the answer to that is in the prose, and
--- the titles are eleven words total. Rather than a second keymap for a second
--- picker, <c-g> swaps between them and carries the typed text across, so a
--- title search that finds nothing becomes a content search without retyping.
---
--- <c-g> is snacks' own key for toggle_live, which this replaces. In the title
--- picker that action only ever warns ("Live search is not supported") — a
--- static finder cannot go live — so nothing is lost there. In the content
--- picker it does work, but grep already starts live (sources.lua sets
--- `live = true` for it), so the direction being given up is the one that turns
--- live searching *off*.
---@param search? string seed for the live search
local function grep(search)
  Snacks.picker.grep({
    title = "Guides (contents)",
    dirs = { DIR },
    search = search,
    confirm = function(picker, item)
      picker:close()
      if item then
        M.open(item.file, item.pos and item.pos[1])
      end
    end,
    actions = {
      guides_titles = function(picker)
        local pattern = picker.input.filter.search
        picker:close()
        M.pick(pattern)
      end,
    },
    win = {
      input = { keys = { ["<c-g>"] = { "guides_titles", mode = { "i", "n" } } } },
      list = { keys = { ["<c-g>"] = "guides_titles" } },
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
---@param pattern? string seed for the title filter, carried over from <c-g>
function M.pick(pattern)
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
    pattern = pattern,
    confirm = function(picker, item)
      picker:close()
      if item then
        M.open(item.file)
      end
    end,
    actions = {
      guides_grep = function(picker)
        local typed = picker.input.filter.pattern
        picker:close()
        grep(typed ~= "" and typed or nil)
      end,
    },
    win = {
      input = { keys = { ["<c-g>"] = { "guides_grep", mode = { "i", "n" } } } },
      list = { keys = { ["<c-g>"] = "guides_grep" } },
    },
  })
end

return M
