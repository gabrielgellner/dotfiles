# Quarto and Typst

Two ways to write a document that is more than notes. **Quarto** (`.qmd`) is
markdown with code chunks that run, rendered through pandoc. **Typst** (`.typ`)
is a typesetting language, LaTeX's job with a compiler that answers in
milliseconds. Both preview on the same keys markdown does.

## Keys

| Key               | Quarto                        | Typst                        |
| ----------------- | ----------------------------- | ---------------------------- |
| `<leader>mp`      | `:QuartoPreview`              | `:TypstPreview`              |
| `<leader>mP`      | stop the preview              | stop the preview             |
| `<leader>mr`      | toggle rendered markdown      | —                            |
| `\ee`             | run the cell under the cursor | —                            |
| `\ea`             | run this cell and all above   | —                            |
| `\eb`             | run every cell                | —                            |
| `\el`             | run the line                  | —                            |
| `\E` (visual)     | run the selection             | —                            |

`\` is localleader, and `e` is the same "eval" group conjure uses in Scheme.

Format on save: typstyle for Typst. Quarto has none, since prettier's markdown
parser does not know chunk headers like `{python}`.

## Quarto

**Code chunks get their language's own LSP.** otter copies each language's
chunks into a hidden buffer of that filetype, so pyrefly, ruff and jetls start
on them as they would on a `.py` or `.jl`. Hover, go-to-definition, completion
and diagnostics all work inside a chunk. Diagnostics refresh on save.

**Cells run in tmux window 2**, the console `dev` opens with every project.
Start the REPL there first (`python`, `julia`); the runner types into whatever
the pane is running, so into a bare shell a Python cell is run by zsh. A cell is
sent as one paste, so an indented block followed directly by a dedented line
runs the way it would from a file.

The cursor has to be *inside* the chunk, not on the `` ```{python} `` fence
line. On the fence the runner reports "No code chunks found for the current
language".

`<leader>mp` runs `quarto preview` and opens the browser, re-rendering on save.
It needs the `quarto` CLI, which is a cask: `brew install --cask quarto`.

## Typst

tinymist is the language server: diagnostics, completion, hover with rendered
docs, and export commands such as `:LspTinymistExportPdf` (also Svg, Png,
Markdown, Text).

`<leader>mp` opens a live preview in the browser. It re-renders as you type,
without needing a save, and follows the cursor. A click in the preview jumps
the cursor to the matching source.

## See also

- [Markdown](markdown.md): rendering, checkboxes and the outline, which apply to
  `.qmd` too where the markdown parser does
- [LSP](lsp.md): the servers behind otter's chunks
- [Tmux](tmux.md): the windows the runner sends to
