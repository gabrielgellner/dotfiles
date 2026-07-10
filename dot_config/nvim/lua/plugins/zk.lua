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
  if root then
    vim.system({ "zk", "index" }, { cwd = root })
  end
end

-- Normal go-to-definition (matches the global `gd` — snacks picker if present).
local function lsp_def()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.picker then snacks.picker.lsp_definitions() else vim.lsp.buf.definition() end
end

-- Follow the [[wikilink]] under the cursor, honoring a `#heading` anchor. zk's LSP
-- opens the note but never moves to the header (zk-nvim#193), so for anchored links
-- we resolve the file ourselves and search for the heading. Bare links (no anchor)
-- fall through to the normal LSP definition, which handles zk's own resolution.
local function follow_link()
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col(".")
  local target, init = nil, 1
  while true do -- find the [[...]] span under the cursor
    local s, e, inner = line:find("%[%[(.-)%]%]", init)
    if not s then break end
    if col >= s and col <= e then target = inner break end
    init = e + 1
  end
  if not target then return lsp_def() end
  target = target:gsub("|.*$", "") -- strip |display alias
  local file, anchor = target:match("^(.-)#(.+)$")
  if not anchor then return lsp_def() end -- no anchor: let the LSP resolve it

  local root = notebook_root(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
  local path
  if file == "" then
    path = vim.api.nvim_buf_get_name(0) -- [[#heading]] — same file
  elseif file:find("/") then
    path = root and (root .. "/" .. file .. ".md") -- path-qualified target
  elseif root then
    path = vim.fn.globpath(root, "**/" .. file .. ".md", false, true)[1] -- bare filename
  end
  if not path or vim.fn.filereadable(path) == 0 then return lsp_def() end
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.fn.cursor(1, 1)
  vim.fn.search([[\c^#\+\s\+]] .. vim.fn.escape(anchor, [[\.*$^~[]/]]), "cw")
  vim.cmd("normal! zz")
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
      pattern = "*.md",
      callback = function(args)
        local name = vim.api.nvim_buf_get_name(args.buf)
        if name == "" or not notebook_root(vim.fs.dirname(name)) then return end
        reindex(name)
        -- anchor-aware follow: gd jumps to a [[note#heading]] section (zk-nvim#193).
        vim.keymap.set("n", "gd", follow_link,
          { buffer = args.buf, desc = "zk: follow link (jump to #heading)" })
      end,
      desc = "zk: reindex + anchor-aware gd in notebook notes",
    })
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
        require("zk").edit(
          { linkTo = { vim.api.nvim_buf_get_name(0) } },
          { title = "Backlinks" }
        )
      end,
      ft = "markdown",
      desc = "Backlinks to this note",
    },
    {
      "<leader>zl",
      function()
        require("zk").edit(
          { linkedBy = { vim.api.nvim_buf_get_name(0) } },
          { title = "Links from note" }
        )
      end,
      ft = "markdown",
      desc = "Notes this note links to",
    },
    -- ── Create from a visual selection ────────────────────────────────────
    {
      "<leader>zn",
      ":'<,'>ZkNewFromTitleSelection<CR>",
      mode = "v",
      ft = "markdown",
      desc = "New note (selection as title)",
    },
    {
      "<leader>zc",
      ":'<,'>ZkNewFromContentSelection<CR>",
      mode = "v",
      ft = "markdown",
      desc = "New note (selection as content)",
    },
  },
}
