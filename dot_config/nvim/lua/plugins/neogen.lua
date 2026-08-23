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
    -- No `type = "func"` variant. It lived on <leader>cf, which lsp.lua binds
    -- buffer-locally to "Format buffer" — and a buffer-local mapping always
    -- shadows a global one, so it was unreachable in exactly the buffers where
    -- you would write a docstring. <leader>cn covers the case anyway: the
    -- default type "any" annotates the nearest annotatable node, which is the
    -- enclosing function whenever you are inside one. <leader>cc stays, because
    -- "any" picks the method rather than the class when the cursor is in one.
    {
      "<leader>cn",
      function()
        require("neogen").generate()
      end,
      desc = "Generate docstring",
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
