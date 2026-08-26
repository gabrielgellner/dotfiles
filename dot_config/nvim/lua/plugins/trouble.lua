return {
  "folke/trouble.nvim",
  -- `cmd` as well as `keys`: without it lazy registers no stub and
  -- `:Trouble diagnostics toggle` — the interface the plugin's own README
  -- documents — answered "Not an editor command" until one of the keys below
  -- had been pressed at least once.
  cmd = "Trouble",
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
    -- Lowercase is this buffer, capital is the project — a capital widens the
    -- scope everywhere else here (stage hunk/buffer, file/repo history,
    -- document/workspace symbols), and this pair used to read the other way.
    -- The narrower one is also the one reached for more often, which is the
    -- right way round for the easier keystroke.
    { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (buffer)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (project)" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list" },
    { "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "Todo comments (trouble)" },
    -- these override ]d/[d to use trouble's jump when trouble is open.
    --
    -- n and x only. `o` was in this list and did nothing: both branches move
    -- the cursor by calling a function rather than returning a motion, so an
    -- operator resolves against no movement and `d]d` deletes nothing at all,
    -- silently. `v]d` does extend the selection — measured, lines 1-4 with the
    -- diagnostic on 4 — so visual is real and worth keeping. Same shape as the
    -- gitsigns hunk motions; see the note in plugins/gitsigns.lua.
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
      mode = { "n", "x" },
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
      mode = { "n", "x" },
    },
  },
}
