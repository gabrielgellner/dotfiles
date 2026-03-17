-- ============================================================================
-- plugins/snacks.lua
-- ============================================================================

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy     = false,
  opts     = {
    -- ── picker (telescope replacement) ──────────────────────────────────────
    picker       = {
      sources = {
        files = {
          hidden = true,   -- show dotfiles like .env .gitignore
          ignored = false, -- respect .gitignore by default
          args = {
            "--exclude", ".venv",
            "--exclude", "__pycache__",
            "--exclude", ".git",
            "--exclude", "node_modules",
            "--exclude", "*.pyc",
          },
        },
      },
      enabled = true,
      layout  = {
        preset = "default",
        layout = {
          width = 0.9,
          height = 0.9,
        }
      },
    },
    -- ── notifier ─────────────────────────────────────────────────────────────
    notifier     = {
      enabled = true,
      timeout = 3000,
    },
    -- ── dashboard ────────────────────────────────────────────────────────────
    dashboard    = {
      enabled = true,
      preset = {
        header = [[
  /\_/\    /\_/\
  ( o.o )--( o.o )
  > ^ <    > ^ <]],
      },
      sections = {
        { section = "header" },
        { section = "keys",         gap = 1,   padding = 1 },
        { section = "recent_files", limit = 5, padding = 1 },
        { section = "startup" },
      },
    },
    -- ── lazygit ──────────────────────────────────────────────────────────────
    lazygit      = { enabled = true },
    -- ── indent guides (using mini.indentscope instead) ────────────────────────
    indent       = { enabled = false },
    -- ── large file handling ───────────────────────────────────────────────────
    bigfile      = { enabled = true },
    -- ── smooth scrolling ─────────────────────────────────────────────────────
    scroll       = { enabled = true },
    -- ── LSP progress indicator ───────────────────────────────────────────────
    statuscolumn = { enabled = true },
  },
  keys     = {
    -- files
    { "<leader>ff", function() Snacks.picker.smart() end,   desc = "Find files" },
    { "<leader>fF", function() Snacks.picker.files() end,   desc = "Find files" },
    { "<leader>fr", function() Snacks.picker.recent() end,  desc = "Recent files" },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    {
      "<leader>fe",
      function()
        Snacks.picker.explorer({
          auto_close = true,
          layout = {
            layout = {
              position = "float",
              width = 0.4,
              height = 0.8,
            },
          },
        })
      end,
      desc = "File Explorer"
    },
    -- search
    { "<leader>fg", function() Snacks.picker.grep() end,                  desc = "Live grep" },
    { "<leader>fw", function() Snacks.picker.grep_word() end,             desc = "Grep word under cursor", mode = { "n", "v" } },
    -- lsp
    { "<leader>fs", function() Snacks.picker.lsp_symbols() end,           desc = "LSP symbols" },
    { "<leader>fS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP workspace symbols" },
    { "<leader>fd", function() Snacks.picker.diagnostics() end,           desc = "Diagnostics" },
    { "gr",         function() Snacks.picker.lsp_references() end,        desc = "LSP references" },
    { "gd",         function() Snacks.picker.lsp_definitions() end,       desc = "LSP definitions" },
    -- vim
    { "<leader>fh", function() Snacks.picker.help() end,                  desc = "Help tags" },
    { "<leader>fk", function() Snacks.picker.keymaps() end,               desc = "Keymaps" },
    { "<leader>fc", function() Snacks.picker.commands() end,              desc = "Commands" },
    { "<leader>f/", function() Snacks.picker.search_history() end,        desc = "Search history" },
    -- git
    { "<leader>gc", function() Snacks.picker.git_log() end,               desc = "Git log" },
    { "<leader>gb", function() Snacks.picker.git_branches() end,          desc = "Git branches" },
    { "<leader>gg", function() Snacks.lazygit() end,                      desc = "Lazygit" },
    -- notifications
    {
      "<leader>fn",
      function()
        Snacks.picker.notifications(
          {
            layout = {
              preset = "default",
              layout = {
                width  = 0.9,
                height = 0.9,
                box    = "vertical", -- stack list and preview vertically
                {
                  box    = "vertical",
                  border = "rounded",
                  title  = "{title} {live} {flags}",
                  { win = "input", height = 1,  border = "bottom" },
                  { win = "list",  height = 0.4 },
                },
                { win = "preview", border = "rounded", height = 0.6 },
              },
            },
          }
        )
      end,
      desc = "Notification history"
    },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss notifications" },
  },
}
