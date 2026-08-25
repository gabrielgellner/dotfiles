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

    -- manual trigger
    vim.keymap.set("n", "<leader>xl", function()
      lint.try_lint()
      vim.notify("Linting " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
    end, { desc = "Lint current file" })
  end,
}
