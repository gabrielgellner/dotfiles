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
      link = { enabled = true },
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
