return {
  -- ── In-buffer markdown rendering ──────────────────────────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown" },
    opts = {
      heading = { enabled = true },
      code = { enabled = true, sign = false },
      dash = { enabled = true },
      bullet = { enabled = true },
      checkbox = { enabled = true },
      link = {
        enabled = true,
        -- Typed rules references: [Display](type:slug) render as an icon + the
        -- display name, with the (type:slug) concealed. zk ignores them (the
        -- `type:` scheme makes them external links, not note links). Icons are
        -- Nerd Font glyphs written as \u{...} so they survive editing; swap the
        -- codepoint for any that render as tofu.
        custom = {
          spell = { pattern = "^spell:", icon = "\u{f0d0} ", highlight = "Special" }, -- magic wand
          condition = { pattern = "^condition:", icon = "\u{f21e} ", highlight = "DiagnosticWarn" }, -- heartbeat
          feat = { pattern = "^feat:", icon = "\u{f005} ", highlight = "Constant" }, -- star
          action = { pattern = "^action:", icon = "\u{f0e7} ", highlight = "Function" }, -- bolt
          creature = { pattern = "^creature:", icon = "\u{f1b0} ", highlight = "Type" }, -- paw
        },
      },
    },
    keys = {
      {
        "<leader>mr",
        "<cmd>RenderMarkdown toggle<CR>",
        ft = "markdown",
        desc = "Toggle render",
      },
    },
  },

  -- ── Browser preview (no npm/build deps) ──────────────────────────────────
  {
    "selimacerbas/markdown-preview.nvim",
    dependencies = { "selimacerbas/live-server.nvim" },
    ft = { "markdown" },
    config = function()
      require("markdown_preview").setup({
        instance_mode = "takeover",
        port = 0,
        open_browser = true,
        debounce_ms = 300,
      })
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreview<CR>", ft = "markdown", desc = "Preview start" },
      { "<leader>mP", "<cmd>MarkdownPreviewStop<CR>", ft = "markdown", desc = "Preview stop" },
      { "<leader>mR", "<cmd>MarkdownPreviewRefresh<CR>", ft = "markdown", desc = "Preview refresh" },
    },
  },
}
