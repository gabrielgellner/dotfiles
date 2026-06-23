return {
  -- racket/scheme filetype detection + syntax fallback
  { "wlangstroth/vim-racket", ft = { "racket", "scheme" } },

  -- interactive REPL evaluation
  {
    "Olical/conjure",
    ft = { "racket", "scheme" },
    init = function()
      vim.g["conjure#filetype#scheme"] = "conjure.client.guile.socket"
      vim.g["conjure#client#scheme#stdio#command"] = "guile"
      vim.g["conjure#mapping#doc_word"] = "K"
    end,
  },

  -- structural editing for s-expressions
  {
    "julienvincent/nvim-paredit",
    ft = { "racket", "scheme", "fennel", "clojure" },
    opts = {},
  },
}
