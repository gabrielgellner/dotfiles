return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {
    modes = {
      search = {
        -- The one real setting here: flash's default is false. With it on,
        -- typing `/result` puts a jump label beside every match as you type, so
        -- a search can end in a label press instead of n/n/n. <C-s> below turns
        -- the labels off again mid-search without leaving it.
        enabled = true,
      },
      char = {
        -- Already flash's default; stated because it changes what f/t/F/T do
        -- and that is worth seeing in this file rather than inferring.
        --
        -- It does *not* add jump labels — `char.jump_labels` is false by
        -- default and is not set here, so f/t behave as they always did except
        -- that the motion key repeats itself, clever-f style. Measured on a
        -- line with `r` at columns 9, 20 and 29: `fr` lands on 9, `frf` on 20,
        -- `frff` on 29, and `frfF` back to 9. `;` and `,` are flash's too.
        enabled = true,
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
