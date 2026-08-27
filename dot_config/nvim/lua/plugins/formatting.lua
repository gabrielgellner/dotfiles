return {
  "stevearc/conform.nvim",
  -- :ConformInfo is the command you reach for when formatting misbehaves,
  -- which is exactly when the plugin may not have loaded yet.
  cmd = "ConformInfo",
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
      -- `sh` covers bash and dash too: Neovim gives every shell script that
      -- filetype and keeps the dialect in `b:is_bash`. A `bash` entry here
      -- matched nothing, the same way plugins/lint.lua's did.
      sh = { "shfmt" },
      -- One `jinja`, not two. Neovim detects only `.jinja`; config/autocmds.lua
      -- maps `.j2` and `.jinja2` onto that same filetype, so all three extensions
      -- arrive here as `jinja` and the filetype `jinja2` is never produced by
      -- anything. That entry matched nothing, the same way `bash` did above and
      -- in plugins/lint.lua.
      --
      -- The autocmds.lua note already recorded that only the first of
      -- jinja/jinja2/htmldjango was reachable; it added the mapping and left
      -- the dead key here. This removes it. htmldjango stays — autocmds.lua's
      -- pattern gives it to `*.html.j2`, which djlint does want to know about.
      jinja = { "djlint" },
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
      -- The guides are formatted by hand. They were run through prettier once,
      -- so they are consistent, but prettier cannot be left in charge of them:
      -- it corrupts a code span whose content is a single backtick — `` `` ``,
      -- the mark in navigation.md — and the only way to protect that row is a
      -- <!-- prettier-ignore --> comment, which render-markdown does *not*
      -- conceal. It sits in the middle of the page every time you read it.
      --
      -- Matched on path rather than by .prettierignore, which prettier resolves
      -- from the working directory: that holds when the repo is the cwd and
      -- silently stops when a guide is opened from anywhere else.
      if vim.api.nvim_buf_get_name(bufnr):match("/nvim/guides/[^/]+%.md$") then
        return
      end
      local timeout = vim.bo[bufnr].filetype == "markdown" and 3000 or 500
      -- lsp_format = "fallback", not lsp_fallback = true. conform still
      -- honours the old key — init.lua maps it "for backwards compatibility"
      -- and says nothing — but it is a legacy alias, and this config has
      -- already been bitten once by leaning on one of those.
      return { timeout_ms = timeout, lsp_format = "fallback" }
    end,
  },
}
