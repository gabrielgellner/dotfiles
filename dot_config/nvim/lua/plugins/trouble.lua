return {
  "folke/trouble.nvim",
  -- `cmd` as well as `keys`: without it lazy registers no stub and
  -- `:Trouble diagnostics toggle` — the interface the plugin's own README
  -- documents — answered "Not an editor command" until one of the keys below
  -- had been pressed at least once.
  cmd = "Trouble",
  -- Global rather than under modes.diagnostics, which is where these were.
  -- Scoped there, only <leader>xx and <leader>xX focused the list: xq, xl and
  -- xt opened it and left the cursor in the file, so three of the five keys in
  -- this family needed a window motion afterwards and two did not. All five
  -- toggle a list of places to jump to, so they should behave the same way.
  --
  -- auto_open is not restated here. It was, as false, which is already the
  -- default — and trouble only honours a per-mode auto_open at all because it
  -- rejects the global one, so setting it false bought nothing. Both settings
  -- below are non-defaults, and were checked by running: clearing the last
  -- diagnostic closes the window, and the cursor lands in ft=trouble.
  opts = {
    auto_close = true, -- close when the list runs out of items
    focus = true, -- put the cursor in the list, not beside it
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
    -- these override ]d/[d to use trouble's jump when trouble is *showing
    -- diagnostics*.
    --
    -- The mode argument is load-bearing on both calls. trouble's is_open() and
    -- next() both default to "the last open view, whatever mode it is in", so
    -- without it `]d` navigated whichever list happened to be on screen:
    -- measured with <leader>xq open and diagnostics on lines 5/12/20, `]d`
    -- from line 1 landed on line 2 — the first *quickfix* entry — and reported
    -- nothing unusual. Naming the mode makes it fall through to
    -- vim.diagnostic.jump instead, which is what `]d` says it does.
    --
    -- Both <leader>xx and <leader>xX open mode "diagnostics" (they differ only
    -- by filter), so this covers the buffer and project lists alike.
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
        if require("trouble").is_open("diagnostics") then
          require("trouble").next({ mode = "diagnostics", skip_groups = true, jump = true })
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
        if require("trouble").is_open("diagnostics") then
          require("trouble").prev({ mode = "diagnostics", skip_groups = true, jump = true })
        else
          vim.diagnostic.jump({ count = -1 })
        end
      end,
      desc = "Prev diagnostic",
      mode = { "n", "x" },
    },
  },
}
