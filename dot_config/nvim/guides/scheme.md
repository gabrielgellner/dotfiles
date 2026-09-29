# Scheme and Racket

Three plugins, for SICP work in `~/dev/sicp`: **conjure** evaluates against a
REPL, **nvim-paredit** edits s-expressions structurally, and **vim-racket**
supplies filetype detection.

The important thing to know up front is that the two halves cover different
files. **conjure works in both `.rkt` and `.scm`; paredit works in `.scm`
only.** That is a limit of paredit rather than a choice here, and the section
at the bottom has the measurements.

`<localleader>` is `\`, so every conjure key below starts with a backslash.

## Evaluating — conjure

| Key    | Evaluates                          |
| ------ | ---------------------------------- |
| `\ee`  | the current form                   |
| `\er`  | the root form                      |
| `\ew`  | the word under the cursor          |
| `\eb`  | the buffer                         |
| `\ef`  | the file                           |
| `\E`   | a motion (`\E` in visual: the selection) |
| `\e!`  | the form, and **replace it** with the result |
| `\em`  | the marked form                    |
| `\ep`  | the previous evaluation again      |

`\ece`, `\ecr` and `\ecw` are the same as `\ee`, `\er` and `\ew` but write the
result into the buffer as a comment — useful for working through an exercise
and leaving the answers in place.

| Key    | Does                          |
| ------ | ----------------------------- |
| `\cs`  | start the REPL                |
| `\cS`  | stop it                       |
| `\ei`  | interrupt the evaluation      |
| `\gd`  | definition under the cursor   |
| `K`    | documentation under the cursor |

### The log

Results land in a log buffer rather than the message area.

| Key    | Does                              |
| ------ | --------------------------------- |
| `\lg`  | toggle the log                    |
| `\lv`  | open it in a vertical split       |
| `\ls`  | horizontal split                  |
| `\lt`  | a new tab                         |
| `\ll`  | jump to the latest part           |
| `\lq`  | close every visible log window    |
| `\lr`  | soft reset · `\lR` hard reset     |

### `.scm` goes through racket too

`vim.g["conjure#filetype#scheme"]` points at the **racket** stdio client, which
is what `.rkt` already uses by default. It used to point at
`conjure.client.guile.socket`, which wants a guile REPL on a socket — and guile
is installed on neither machine, so evaluating in a `.scm` buffer logged "No
REPL running" and nothing else. A second line configured the guile *stdio*
client that the first had already routed around, so it could not have helped
either.

One wrinkle, and it is cosmetic. On starting the REPL, conjure asks racket to
load the current file, and racket rejects a `.scm` with no `#lang` line —
"expected a `module` declaration". The log carries that once and nothing else
breaks; evaluating form by form works from there. Add `#lang racket` at the top
if you want the load to succeed too.

## Structural editing — paredit, `.scm` only

| Key           | Does                      |
| ------------- | ------------------------- |
| `>)` `<)`     | slurp / barf forwards     |
| `<(` `>(`     | slurp / barf backwards    |
| `>e` `<e`     | drag element right / left |
| `>f` `<f`     | drag form right / left    |
| `>p` `<p`     | drag element pairs        |
| `\o` `\O`     | raise form / element      |
| `\@`          | splice — unwrap the form  |

Twenty-four mappings in total, all buffer-local.

**None of them exists in a `.rkt` buffer**, and that is worth knowing before
you reach for one and wonder why nothing happened. paredit 1.0 dispatches on a
per-language **treesitter query**, and it ships queries for `clojure`,
`commonlisp`, `fennel`, `janet_simple` and `scheme` — there is no racket one.

Three ways round it were measured, and none works:

- Adding `racket` to paredit's own `filetypes` binds all 24 keys in a `.rkt`
  buffer and every one of them is **inert** — worse than unbound, by this
  config's own rule about not advertising what cannot work.
- `vim.treesitter.language.register("scheme", "racket")` — the trick `.scrawl`
  uses for markdown — makes the parser report `scheme` and still does not make
  slurp fire, and it costs `#lang` its keyword highlight.
- `add_language_extension` is gone, removed in paredit 1.0.0 in favour of the
  query design.

The comparison that pins it, run through the API rather than a keystroke so
nothing depends on key routing: identical `(foo (bar) baz)` with the cursor in
the inner form gives `(foo (bar baz))` under `ft=scheme` and is unchanged under
`ft=racket`.

**So write `.scm` when structural editing matters.** conjure sends it to the
same racket REPL either way, so nothing is lost by doing that.

## The toolchain

`racket` is what both clients actually run — v9.3 here, from Homebrew. Note it
is **not installed by `bootstrap.sh`**, so a fresh machine gets the plugins and
no REPL behind them; `\cs` would fail there until `brew install racket`.

`vim-racket` is only filetype detection and a syntax fallback; the highlighting
comes from treesitter, which has parsers for both `racket` and `scheme`.

## See also

- [Treesitter](treesitter.md) — the parsers behind both filetypes
- [Navigation](navigation.md) — `%` and matchup, which work on parens
  everywhere, paredit or not
