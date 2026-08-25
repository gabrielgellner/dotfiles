return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      python = { "ruff" }, -- ruff as linter (separate from ruff LSP)
      yaml = { "yamllint" },
      -- No `sh` entry: bash-language-server runs shellcheck itself and turns
      -- its findings into code actions (see plugins/lsp.lua). Linting here as
      -- well reported everything twice.
      -- markdown = { "markdownlint" }, -- uncomment if you want this
    }

    -- run on open and save
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
      callback = function()
        lint.try_lint()
      end,
    })

    -- The BufReadPost that loads this plugin has already fired by the time
    -- the autocmd above exists, so the first file opened in a session was
    -- never linted until it was saved. Lint it here.
    lint.try_lint()

    -- Manual trigger. `<leader>xr` and not `<leader>xl`: xl is trouble's
    -- location list, and this line used to overwrite it. Not visibly — lazy
    -- installs trouble's key stub at startup and this config() runs later, on
    -- the BufReadPost that loads nvim-lint, so the mapping said "Location list"
    -- until the first file was opened and "Lint current file" ever after.
    --
    -- xr pairs with `<leader>xR` in config/keymaps.lua, which runs ruff over the
    -- whole project: same idea, wider scope, which is the rule guides/keymaps.md
    -- sets out for a capital.
    vim.keymap.set("n", "<leader>xr", function()
      lint.try_lint()
      vim.notify("Linting " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
    end, { desc = "Lint current file" })
  end,
}
