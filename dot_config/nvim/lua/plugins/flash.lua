return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {
    modes = {
      search = {
        enabled = true, -- flash labels appear during normal / search
      },
      char = {
        enabled = true, -- enhances f/t/F/T with labels on multi matches
      },
    },
  },
  keys = {
    {
      "s",
      function()
        require("flash").jump()
      end,
      mode = { "n", "x", "o" },
      desc = "Flash jump",
    },
    {
      "S",
      function()
        require("flash").treesitter()
      end,
      mode = { "n", "x", "o" },
      desc = "Flash treesitter",
    },
    {
      "r",
      function()
        require("flash").remote()
      end,
      mode = "o",
      desc = "Flash remote",
    },
    {
      "R",
      function()
        require("flash").treesitter_search()
      end,
      mode = { "o", "x" },
      desc = "Flash treesitter search",
    },
    {
      "<C-s>",
      function()
        require("flash").toggle()
      end,
      mode = "c",
      desc = "Flash toggle search",
    },
  },
}
