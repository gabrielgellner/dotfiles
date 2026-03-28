return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  opts = {
    formatters_by_ft = {
      python = { "ruff_format", "ruff_organize_imports" },
      lua = { "stylua" },
      markdown = { "prettier" },
      json = { "biome" },
      jsonc = { "biome" },
      yaml = { "yamlfmt" },
      toml = { "taplo" },
      css = { "biome" },
      html = { "prettier" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      jinja = { "djlint" },
      jinja2 = { "djlint" },
      htmldjango = { "djlint" },
      javascript = { "biome" },
      typescript = { "biome" },
      javascriptreact = { "biome" },
      typescriptreact = { "biome" },
      rust = { "rustfmt" },
    },
    format_on_save = function(bufnr)
      local timeout = vim.bo[bufnr].filetype == "markdown" and 3000 or 500
      return { timeout_ms = timeout, lsp_fallback = true }
    end,
  },
}
