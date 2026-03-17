return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  opts = {
    formatters_by_ft = {
      python   = { "ruff_format", "ruff_organize_imports" },
      lua      = { "stylua" },
      -- add these:
      yaml     = { "prettier" },
      json     = { "prettier" },
      jsonc    = { "prettier" },
      markdown = { "prettier" },
      toml     = { "taplo" }, -- toml has its own formatter
    },
    format_on_save = {
      timeout_ms   = 500,
      lsp_fallback = true,
    },
  },
}
