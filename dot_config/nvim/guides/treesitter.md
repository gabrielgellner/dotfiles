# Treesitter

The parser layer under four things you use constantly: **highlighting**,
**indent**, **folds** and **structural motions**. The motions and textobjects
themselves are on another card — see [Navigation](navigation.md) for `]f`,
`]k`, `ii`/`ai` and the fold keys. This one is the machinery, and what to do
when it misbehaves.

`branch = "main"`, which matters: the old `master` branch took a
`modules = { highlight = { enable = true } }` table that the new one ignores
**silently**. A config copied from a blog post configures nothing and says
nothing about it.

## What it drives

| Thing         | Where it is set                    |
| ------------- | ---------------------------------- |
| highlighting  | `vim.treesitter.start` per buffer  |
| indent        | `indentexpr` per buffer            |
| folds         | `config/options.lua`, **globally** |
| textobjects   | `nvim-treesitter-textobjects`      |
| sticky header | `treesitter-context`, `<leader>uc` toggles |

**Folds are set globally rather than per filetype, and that is a bug fix.**
They are window-local options, so setting them from a `FileType` autocmd missed
the first buffer of a session — which got `foldexpr` but kept
`foldmethod=manual`, so `zM` silently did nothing — and missed every new split
as well.

Highlighting has the same hole and cannot be solved the same way, because it is
per buffer rather than an option. So it catches up instead: the config loops
over already-loaded buffers at startup as well as listening for `FileType`.
Without that, the file Neovim was *started with* fell back to Vim's regex
syntax — close enough to right that nothing looked broken.

Checked on a freshly opened python file: `highlighter.active[buf]` is true on
buffer 1, the parser is `python`, and `def` reports the capture
`keyword.function`.

## Parsers

17 are installed, from an `ensure_installed` list covering the languages here —
python, lua, rust, bash, markdown, json, toml, yaml, just, scheme, racket and
the vim/diff/regex support ones. Missing ones are installed at startup with a
notification rather than silently.

```
:TSUpdate          rebuild the compiled parsers
:checkhealth vim.treesitter
```

### The one asymmetry worth understanding

**Queries cannot go stale, only parsers can.** The lockfile pins
nvim-treesitter, and the queries move with it because they are not copies:
every `site/queries/<lang>` is a *symlink* into the plugin's own
`runtime/queries/<lang>`, so a query resolves inside whatever checkout the pin
names. (The symlinks' own mtimes vary and mean nothing.)

The compiled parsers are different. They are **real files** in
`~/.local/share/nvim/site/parser/`, outside the plugin, and only
`build = ":TSUpdate"` rebuilds them — which lazy runs on `:Lazy update`, on the
machine doing the updating. **A machine that later pulls the lockfile gets new
queries against old parsers.**

That has happened: six parsers sat at their July revisions after a restore, and
the symptom was narrow enough to be baffling — markdown files, but only ones
containing a ` ```diff ` fence, because the newer `diff/highlights.scm` named a
node the old `diff` parser did not produce.

So after `:Lazy restore` or a pull that moves the lockfile, run `:TSUpdate`.
The pin alone does not carry the parsers.

## When highlighting looks wrong

In order of likelihood:

1. **Parser older than the queries** — the case above. `:TSUpdate`.
2. **No parser for that filetype** — the buffer falls back to regex syntax,
   which looks nearly right. `:checkhealth vim.treesitter` names what is
   missing.
3. **A query error** after an update, which does say so, loudly.

`:InspectTree` shows the parse tree for the current buffer and `:Inspect` names
the captures under the cursor — the latter is how you tell "treesitter is
wrong" from "the colourscheme has no rule for that capture".

## Indent

`indentexpr` is treesitter's. It and Vim's own engine agree where it counts —
typing `o` under `if a:` indents the same either way.

They diverge on **re-indenting python that is already flat**, where treesitter
can do nothing at all: the parse tree it would need is exactly what the missing
indentation destroyed. Vim's heuristic can guess; a parser cannot. That is not a
bug to report, it is the shape of the tool.

## See also

- [Navigation](navigation.md) — the motions, textobjects and folds this powers
- [LSP](lsp.md) — the other source of structure, and where the two differ
