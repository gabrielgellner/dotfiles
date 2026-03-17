return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      python = { "ruff" }, -- ruff as linter (separate from ruff LSP)
      yaml   = { "yamllint" },
      bash   = { "shellcheck" },
      -- markdown = { "markdownlint" }, -- uncomment if you want this
    }

    -- run on open and save
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
      callback = function()
        lint.try_lint()
      end,
    })

    -- manual trigger
    vim.keymap.set("n", "<leader>xl", function()
      lint.try_lint()
      vim.notify("Linting " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
    end, { desc = "Lint current file" })
  end,
}
