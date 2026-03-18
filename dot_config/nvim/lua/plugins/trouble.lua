return {
  "folke/trouble.nvim",
  opts = {
    modes = {
      diagnostics = {
        auto_open = false,
        auto_close = true, -- closes when no more items
        focus = true,
      },
    },
  },
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (project)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (buffer)" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list" },
    { "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "Todo comments" },
    -- these override ]d/[d to use trouble's jump when trouble is open
    {
      "]d",
      function()
        if require("trouble").is_open() then
          require("trouble").next({ skip_groups = true, jump = true })
        else
          vim.diagnostic.jump({ count = 1 })
        end
      end,
      desc = "Next diagnostic",
    },
    {
      "[d",
      function()
        if require("trouble").is_open() then
          require("trouble").prev({ skip_groups = true, jump = true })
        else
          vim.diagnostic.jump({ count = -1 })
        end
      end,
      desc = "Prev diagnostic",
    },
  },
}
