-- Sticky context header: pins the enclosing function/class/if signatures to the
-- top of the window so a long body never leaves you wondering what you're
-- inside of. VS Code calls this sticky scroll.
--
-- No keymaps for jumping to a context line: `[f` / `[k` (plugins/treesitter.lua)
-- already move to the enclosing function/class start, which is what the
-- plugin's suggested `[c` binding does — and `[c` is taken anyway, by gitsigns'
-- previous-hunk motion. (This used to say `[c` was one of the treesitter maps.
-- It never was: class is on `[k`, and `[c` reports "Git: Prev hunk".)
return {
  "nvim-treesitter/nvim-treesitter-context",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    -- "topline" tracks the top *visible* line, not the cursor. That's the one
    -- that matters here: <C-e>/<C-y> scroll with the cursor parked, so a
    -- cursor-following context would sit there showing stale headers for
    -- whatever is now off-screen.
    mode = "topline",
    max_lines = 3, -- deeper than this and the header eats the window
    min_window_height = 20, -- don't steal 3 of 10 lines in a split
    multiline_threshold = 1, -- collapse a wrapped signature to its first line
    separator = "─", -- underline it, so it reads as chrome and not as code
  },
  keys = {
    {
      "<leader>uc",
      function()
        require("treesitter-context").toggle()
      end,
      desc = "Toggle sticky context",
    },
  },
}
