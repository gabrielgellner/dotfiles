-- zk-nvim - Zettelkasten / second-brain notes on top of the `zk` CLI.
-- Requires the `zk` binary (installed via homebrew) and a notebook directory
-- initialised with `zk init` (a dir containing a `.zk/` marker).
--
-- Multiple notebooks: the notebook root is resolved per Neovim session (see the
-- `opts` function). Editing a note picks the notebook that *contains* it, so a
-- project like ~/dev/pf2e-prep can be its own independent notebook. When no
-- notebook is in scope, commands fall back to $ZK_NOTEBOOK_DIR (the second
-- brain). NOTE: zk-nvim caches one LSP client per session, so keep one notebook
-- per session — which matches the per-project tmux sessions from `dev`.
--
-- zk ships its own language server (`zk lsp`); this config auto-attaches it to
-- markdown buffers inside a notebook, giving link/tag completion via blink.cmp.

-- Walk up from `start` looking for a `.zk/` directory (a notebook root).
local function notebook_root(start)
  local marker = vim.fs.find(".zk", { upward = true, type = "directory", path = start })[1]
  return marker and vim.fs.dirname(marker) or nil
end

-- Incrementally reindex the notebook that contains `bufpath` (async, silent).
-- zk keeps its own index and doesn't notice notes added outside this session
-- (git pull, scripts, another tool) until it reindexes — so links to them read
-- as dead and pickers don't list them. No-op for markdown outside any notebook.
local function reindex(bufpath)
  local root = notebook_root(bufpath and bufpath ~= "" and vim.fs.dirname(bufpath) or nil)
    or notebook_root(vim.uv.cwd())
  -- executable() first: this runs from an autocmd, and vim.system's list form
  -- raises ENOENT for a missing binary rather than returning a code, so on a
  -- machine without zk every note opened would report an error instead of
  -- quietly skipping the index.
  if root and vim.fn.executable("zk") == 1 then
    vim.system({ "zk", "index" }, { cwd = root })
  end
end

-- Normal go-to-definition (matches the global `gd` — snacks picker if present).
local function lsp_def()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.picker then
    snacks.picker.lsp_definitions()
  else
    vim.lsp.buf.definition()
  end
end

-- Typed rules-reference links: [Display](type:slug) -> rules/<dir>/<slug>.md.
local RULES_DIRS = {
  spell = "spells",
  condition = "conditions",
  action = "actions",
  feat = "feats",
  creature = "creatures",
  item = "items",
}

-- Lazily read spell_aliases.toml (legacy slug -> remaster slug) from the repo
-- root (the parent of the notebook), so a link written with a pre-remaster
-- spell name still resolves. Cached after first read.
local spell_aliases
local function load_spell_aliases(root)
  if spell_aliases then
    return spell_aliases
  end
  spell_aliases = {}
  local f = root and io.open(vim.fs.dirname(root) .. "/spell_aliases.toml", "r")
  if f then
    for l in f:lines() do
      local legacy, remaster = l:match('^%s*"([^"]+)"%s*=%s*"([^"]+)"')
      if legacy then
        spell_aliases[legacy] = remaster
      end
    end
    f:close()
  end
  return spell_aliases
end

-- Read a YAML frontmatter scalar `key:` from a buffer's opening lines.
local function frontmatter_field(bufnr, key)
  local head = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)
  if head[1] ~= "---" then
    return nil
  end
  for i = 2, #head do
    if head[i] == "---" then
      return nil
    end
    local v = head[i]:match("^" .. key .. ":%s*(.+)$")
    if v then
      return (v:gsub("%s+$", ""))
    end
  end
  return nil
end

-- Follow a [H21](room://H21) link: jump to that room's key in this note's level
-- chapter (the buffer's `chapter:` frontmatter), landing on the `## H21 …` heading.
local function follow_room(anchor, root)
  local chapter = frontmatter_field(0, "chapter")
  if not chapter or not root then
    vim.notify("room link: no `chapter:` in this note's frontmatter", vim.log.levels.WARN)
    return
  end
  local path = root .. "/" .. chapter .. ".md"
  if vim.fn.filereadable(path) == 0 then
    vim.notify("room link: chapter not found — " .. chapter, vim.log.levels.WARN)
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.fn.cursor(1, 1)
  vim.fn.search([[\c^#\+\s\+]] .. vim.fn.escape(anchor, [[\.*$^~[]/]]), "cw")
  vim.cmd("normal! zz")
end

-- If a [Display](type://slug) typed rules link is under the cursor, open the
-- matching rules/<dir>/<slug>.md and return true; otherwise return false so the
-- caller falls back to wikilink/LSP handling. The `//` makes zk treat the link
-- as an external URL, so its dead-link diagnostic leaves it alone (a bare
-- `type:slug` reads as an internal note ref and gets flagged "not found").
local function follow_typed_link(line, col, root)
  local init = 1
  while true do
    local s, e, dest = line:find("%[.-%]%((.-)%)", init)
    if not s then
      return false
    end
    if col >= s and col <= e then
      local typ, slug = dest:match("^(%a+):/?/?(.+)$")
      if typ == "room" then
        follow_room(slug, root)
        return true
      end
      local dir = typ and RULES_DIRS[typ]
      if not dir or not root then
        return false
      end
      local path = root .. "/rules/" .. dir .. "/" .. slug .. ".md"
      if vim.fn.filereadable(path) == 0 and typ == "spell" then
        local alias = load_spell_aliases(root)[slug]
        if alias then
          path = root .. "/rules/spells/" .. alias .. ".md"
        end
      elseif vim.fn.filereadable(path) == 0 and typ == "item" then
        -- custom shop items aren't in the rules DB; look under campaign/items/.
        local hit = vim.fn.globpath(root .. "/items", "**/" .. slug .. ".md", false, true)[1]
        if hit then
          path = hit
        end
      end
      if vim.fn.filereadable(path) == 1 then
        vim.cmd.edit(vim.fn.fnameescape(path))
        vim.fn.cursor(1, 1)
      else
        vim.notify("No rules file for " .. dest, vim.log.levels.WARN)
      end
      return true
    end
    init = e + 1
  end
end

-- Follow the link under the cursor. First a typed rules link [Display](type:slug);
-- then a [[wikilink]], honoring a `#heading` anchor. zk's LSP opens a note but never
-- moves to the header (zk-nvim#193), so for anchored links we resolve the file
-- ourselves and search for the heading. Bare links fall through to the LSP.
local function follow_link()
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col(".")
  local root = notebook_root(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
  if follow_typed_link(line, col, root) then
    return
  end

  local target, init = nil, 1
  while true do -- find the [[...]] span under the cursor
    local s, e, inner = line:find("%[%[(.-)%]%]", init)
    if not s then
      break
    end
    if col >= s and col <= e then
      target = inner
      break
    end
    init = e + 1
  end
  if not target then
    return lsp_def()
  end
  target = target:gsub("|.*$", "") -- strip |display alias
  local file, anchor = target:match("^(.-)#(.+)$")
  if not anchor then
    return lsp_def()
  end -- no anchor: let the LSP resolve it
  local path
  if file == "" then
    path = vim.api.nvim_buf_get_name(0) -- [[#heading]] — same file
  elseif file:find("/") then
    path = root and (root .. "/" .. file .. ".md") -- path-qualified target
  elseif root then
    path = vim.fn.globpath(root, "**/" .. file .. ".md", false, true)[1] -- bare filename
  end
  if not path or vim.fn.filereadable(path) == 0 then
    return lsp_def()
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.fn.cursor(1, 1)
  vim.fn.search([[\c^#\+\s\+]] .. vim.fn.escape(anchor, [[\.*$^~[]/]]), "cw")
  vim.cmd("normal! zz")
end

-- Turn a visual selection into a wikilink to an existing note, keeping the
-- selected text as the display alias: `Sceptre of Sorrows` -> `[[sceptre-of-sorrows|Sceptre of Sorrows]]`.
-- Reads the `'<`/`'>` marks (so invoke via `:<C-u>ZkLinkSelection`, which leaves
-- visual mode first), filters zk by the selection, then replaces it in place.
-- The link target is the bare filename stem — the same thing `[[` completion
-- resolves by name; path-qualify by hand for a stem collision (see CLAUDE.md).
local function link_selection()
  local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
  local srow, scol, erow, ecol = s[2], s[3], e[2], e[3]
  if srow == 0 then
    return
  end
  -- clamp the inclusive end column to the line (handles `$`/v:maxcol selections)
  local last = vim.api.nvim_buf_get_lines(0, erow - 1, erow, false)[1] or ""
  ecol = math.min(ecol, #last)
  local ok, chunks = pcall(vim.api.nvim_buf_get_text, 0, srow - 1, scol - 1, erow - 1, ecol, {})
  if not ok then
    return
  end
  local sel = vim.trim(table.concat(chunks, " "):gsub("[%[%]|]", ""))
  if sel == "" then
    return
  end

  require("zk.api").list(nil, { select = { "title", "path" }, match = { sel } }, function(a, b)
    local notes = (type(a) == "table" and a) or (type(b) == "table" and b) or {}
    if vim.tbl_isempty(notes) then
      return vim.notify("zk: no notes match '" .. sel .. "'", vim.log.levels.WARN)
    end
    vim.ui.select(notes, {
      prompt = "Link “" .. sel .. "” → ",
      format_item = function(n)
        return n.title and (n.title .. "  ·  " .. n.path) or n.path
      end,
    }, function(choice)
      if not choice then
        return
      end
      local stem = vim.fn.fnamemodify(choice.path, ":t:r")
      local link = (stem == sel) and ("[[" .. stem .. "]]") or ("[[" .. stem .. "|" .. sel .. "]]")
      vim.api.nvim_buf_set_text(0, srow - 1, scol - 1, erow - 1, ecol, { link })
    end)
  end)
end

return {
  "zk-org/zk-nvim",
  main = "zk",
  ft = "markdown",
  cmd = { "ZkNotes", "ZkNew", "ZkTags", "ZkNewFromTitleSelection", "ZkNewFromContentSelection" },
  -- Keep zk's index fresh: reindex the notebook whenever a markdown note is
  -- opened, so notes created outside this session (git pull, scripts) are picked
  -- up and their links resolve. Runs from startup (not lazy) since it only
  -- shells out to `zk`, and is a no-op outside a notebook.
  init = function()
    vim.api.nvim_create_autocmd("BufReadPost", {
      -- Grouped so a reload replaces this rather than adding another copy.
      group = vim.api.nvim_create_augroup("zk_notebook", { clear = true }),
      pattern = "*.md",
      callback = function(args)
        local name = vim.api.nvim_buf_get_name(args.buf)
        if name == "" or not notebook_root(vim.fs.dirname(name)) then
          return
        end
        reindex(name)
        -- anchor-aware follow: gd jumps to a [[note#heading]] section (zk-nvim#193).
        vim.keymap.set("n", "gd", follow_link, { buffer = args.buf, desc = "zk: follow link (jump to #heading)" })
      end,
      desc = "zk: reindex + anchor-aware gd in notebook notes",
    })
    -- Backs the visual <leader>zl mapping (see keys). A user command so the
    -- `:<C-u>` invocation leaves visual mode before the `'<`/`'>` marks are read.
    vim.api.nvim_create_user_command("ZkLinkSelection", function()
      link_selection()
    end, { range = true, desc = "zk: link visual selection to a note (alias-preserving)" })
  end,
  opts = function()
    -- Resolve the notebook for this session, most-specific first:
    --   1. the notebook containing the file being opened (lazy loads on `ft`,
    --      so buffer 0 is that file);
    --   2. the notebook containing the cwd (project sessions start cd'd in);
    --   3. $ZK_NOTEBOOK_DIR — the default second brain (~/notes).
    local buf = vim.api.nvim_buf_get_name(0)
    local root = notebook_root(buf ~= "" and vim.fs.dirname(buf) or nil)
      or notebook_root(vim.uv.cwd())
      or vim.env.ZK_NOTEBOOK_DIR
      or vim.fn.expand("~/notes")

    return {
      -- Reuse the snacks picker already used everywhere else in this config.
      picker = "snacks_picker",
      lsp = {
        config = {
          cmd = { "zk", "lsp" },
          name = "zk",
          -- Pin the server to the resolved notebook so commands work even when
          -- run from a non-notebook cwd (otherwise `vim.lsp.start` roots at cwd
          -- and zk fails with "no notebook found").
          root_dir = root,
        },
        auto_attach = {
          -- Only attaches to markdown buffers that live inside a notebook, so
          -- editing unrelated markdown (README, dotfiles) never starts the LSP.
          enabled = true,
          filetypes = { "markdown" },
        },
      },
    }
  end,
  keys = {
    -- ── Global (work from any buffer) ─────────────────────────────────────
    {
      "<leader>zn",
      function()
        require("zk").new({ title = vim.fn.input("Title: ") })
      end,
      desc = "New note",
    },
    {
      "<leader>zo",
      function()
        require("zk").edit({ sort = { "modified" } }, { title = "Notes" })
      end,
      desc = "Open notes",
    },
    {
      "<leader>zf",
      function()
        require("zk").edit({ sort = { "modified" }, match = { vim.fn.input("Search: ") } }, { title = "Search notes" })
      end,
      desc = "Find notes (full-text)",
    },
    {
      "<leader>zt",
      "<cmd>ZkTags<CR>",
      desc = "Browse tags",
    },
    {
      "<leader>zi",
      function()
        reindex(vim.api.nvim_buf_get_name(0))
        vim.notify("zk: reindexing notebook", vim.log.levels.INFO)
      end,
      desc = "Reindex notebook",
    },
    -- ── Buffer-local note actions ─────────────────────────────────────────
    {
      "<leader>zb",
      function()
        require("zk").edit({ linkTo = { vim.api.nvim_buf_get_name(0) } }, { title = "Backlinks" })
      end,
      ft = "markdown",
      desc = "Backlinks to this note",
    },
    {
      "<leader>zl",
      function()
        require("zk").edit({ linkedBy = { vim.api.nvim_buf_get_name(0) } }, { title = "Links from note" })
      end,
      ft = "markdown",
      desc = "Notes this note links to",
    },
    {
      -- The other half of linking. Visual <leader>zl links text that is already
      -- written; this inserts a link to an existing note where the cursor is,
      -- picking the target from a list — which is the action you actually reach
      -- for while writing prose.
      --
      -- `k` rather than another `l`: <leader>zl already carries two link
      -- meanings across normal and visual mode, and a third would need a mode
      -- that is already taken.
      "<leader>zk",
      "<cmd>ZkInsertLink<CR>",
      ft = "markdown",
      desc = "Insert link to a note",
    },
    -- ── Create from a visual selection ────────────────────────────────────
    {
      "<leader>zn",
      ":'<,'>ZkNewFromTitleSelection<CR>",
      mode = "x",
      ft = "markdown",
      desc = "New note (selection as title)",
    },
    {
      "<leader>zc",
      ":'<,'>ZkNewFromContentSelection<CR>",
      mode = "x",
      ft = "markdown",
      desc = "New note (selection as content)",
    },
    -- ── Link a visual selection to an existing note ───────────────────────
    {
      "<leader>zl",
      ":<C-u>ZkLinkSelection<CR>",
      mode = "x",
      ft = "markdown",
      desc = "Link selection to a note (alias)",
    },
  },
}
