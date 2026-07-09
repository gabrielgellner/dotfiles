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
return {
  "zk-org/zk-nvim",
  main = "zk",
  ft = "markdown",
  cmd = { "ZkNotes", "ZkNew", "ZkTags", "ZkNewFromTitleSelection", "ZkNewFromContentSelection" },
  opts = function()
    -- Walk up from `start` looking for a `.zk/` directory (a notebook root).
    local function notebook_root(start)
      local marker = vim.fs.find(".zk", { upward = true, type = "directory", path = start })[1]
      return marker and vim.fs.dirname(marker) or nil
    end

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
