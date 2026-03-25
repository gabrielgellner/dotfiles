return {
  "danymat/neogen",
  dependencies = "nvim-treesitter/nvim-treesitter",
  opts = {
    snippet_engine = "luasnip",
    languages = {
      python = {
        template = {
          annotation_convention = "google_docstrings", -- google_docstrings, numpydoc, reST
        },
      },
    },
  },
  keys = {
    {
      "<leader>cn",
      function()
        require("neogen").generate()
      end,
      desc = "Generate docstring",
    },
    {
      "<leader>cf",
      function()
        require("neogen").generate({ type = "func" })
      end,
      desc = "Generate func docstring",
    },
    {
      "<leader>cc",
      function()
        require("neogen").generate({ type = "class" })
      end,
      desc = "Generate class docstring",
    },
  },
}
