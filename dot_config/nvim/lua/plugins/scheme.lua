return {
  -- racket/scheme filetype detection + syntax fallback
  { "wlangstroth/vim-racket", ft = { "racket", "scheme" } },

  -- interactive REPL evaluation
  {
    "Olical/conjure",
    ft = { "racket", "scheme" },
    init = function()
      -- .scm goes through racket, the same client .rkt already uses by default.
      --
      -- This pointed at conjure.client.guile.socket, which wants a guile REPL
      -- listening on a socket — and guile is not installed on either machine.
      -- Evaluating a form in a .scm buffer logged "No REPL running" and nothing
      -- else. A second line set conjure#client#scheme#stdio#command to "guile",
      -- configuring the *stdio* client that the first line had already routed
      -- around, so it could never have taken effect either.
      --
      -- racket is installed, its stdio client defaults to `command = "racket"`,
      -- and the SICP work this is for lives in ~/dev/sicp as .rkt — where
      -- evaluation already worked. Sending .scm to the same place makes the two
      -- extensions behave alike rather than leaving one of them dead.
      --
      -- One wrinkle, and it is cosmetic: on starting the REPL conjure asks
      -- racket to load the current file, and racket rejects a .scm with no
      -- `#lang` line — "expected a `module` declaration". The log carries that
      -- once and nothing else breaks. Evaluating form by form, which is how
      -- conjure is used, works from there: the define returns "Empty result"
      -- and (add 1 2) returns 3. Add `#lang racket` to a .scm file if you want
      -- the load to succeed too.
      vim.g["conjure#filetype#scheme"] = "conjure.client.racket.stdio"
      -- No `conjure#mapping#doc_word`: "K" is conjure's default (config.fnl:190).
    end,
  },

  -- structural editing for s-expressions
  {
    "julienvincent/nvim-paredit",
    ft = { "racket", "scheme", "fennel", "clojure" },
    opts = {},
  },
}
