return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  opts = {
    formatters_by_ft = {
      python = { "ruff_format", "ruff_organize_imports" },
      lua = { "stylua" },
      markdown = { "prettier_markdown" },
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
      just = { "just" },
    },
    -- Prettier's default proseWrap is "preserve", so markdown saves left long
    -- lines untouched. Hard-wrap prose at 120 instead; tables are never wrapped
    -- by prettier, they just get aligned.
    --
    -- These are *defaults*, not overrides: --config-precedence file-override
    -- lets a project's .prettierrc win (prettier's default is cli-override,
    -- which silently reflowed 120-col projects to 80). Projects with no config
    -- still get always/120.
    --
    -- 120 is deliberate and matches `textwidth` for markdown in
    -- config/autocmds.lua, so `gq` and format-on-save produce the same wrap
    -- everywhere — including projects that ship no .prettierrc.
    formatters = {
      prettier_markdown = {
        command = "prettier",
        args = {
          "--stdin-filepath",
          "$FILENAME",
          "--parser",
          "markdown",
          "--prose-wrap",
          "always",
          "--print-width",
          "120",
          "--config-precedence",
          "file-override",
        },
        stdin = true,
      },
    },
    format_on_save = function(bufnr)
      local timeout = vim.bo[bufnr].filetype == "markdown" and 3000 or 500
      return { timeout_ms = timeout, lsp_fallback = true }
    end,
  },
}
