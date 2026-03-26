return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  opts = {
    formatters_by_ft = {
      python = { "ruff_format", "ruff_organize_imports" },
      lua = { "stylua" },
      -- add these:
      yaml = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      markdown = { "prettier" },
      toml = { "taplo" }, -- toml has its own formatter
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      rust = { "rustfmt" },
    },
    format_on_save = {
      timeout_ms = 2000,
      lsp_fallback = true,
    },
  },
}
