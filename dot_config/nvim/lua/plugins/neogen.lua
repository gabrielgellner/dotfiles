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
    -- cc is the doubled key, so by vim's own convention — gcc, dd, yy — it has
    -- to be the ordinary case, not a special one. It used to be the class
    -- variant while the general "annotate whatever is nearest" sat on cn, which
    -- read backwards. Swapped: cc annotates the nearest node, and cC widens to
    -- the enclosing class, which keeps the capital meaning a wider scope the way
    -- it does everywhere else here.
    --
    -- No `type = "func"` variant. It lived on <leader>cf, which lsp.lua binds
    -- buffer-locally to "Format buffer" — and a buffer-local mapping always
    -- shadows a global one, so it was unreachable in exactly the buffers where
    -- you would write a docstring. The default type "any" covers it anyway: it
    -- annotates the enclosing function whenever the cursor is inside one, and
    -- only picks the class when nothing nearer qualifies.
    {
      "<leader>cc",
      function()
        require("neogen").generate()
      end,
      desc = "Generate docstring",
    },
    {
      "<leader>cC",
      function()
        require("neogen").generate({ type = "class" })
      end,
      desc = "Generate class docstring",
    },
  },
}
