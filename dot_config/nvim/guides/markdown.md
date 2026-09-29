# Markdown

Markdown gets more custom code here than any other filetype, and the reason is
the same each time: the obvious plugin turned out to be a **decorator** with no
behaviour behind it, or the generic key had nothing to answer it.

## Keys

| Key          | Does                                   |
| ------------ | -------------------------------------- |
| `<CR>`       | toggle the checkbox on this line       |
| `<leader>mx` | the same, and works on a selection     |
| `<leader>mr` | toggle rendering — show the raw text   |
| `<leader>mp` | start the browser preview              |
| `<leader>mP` | stop it                                |
| `<leader>mf` | refresh it                             |
| `<leader>fs` | outline picker — headings of this file |
| `gO`         | the same outline                       |

All of them are **buffer-local to markdown**, which is why `<leader>m` could be
claimed for it at all — the prefix is free everywhere else.

`<leader>mf` is refresh, not `<leader>mR`. That one moved and the comment
explaining it did not follow for a while; it is in this repo's own list of
faults.

## Checkboxes

`<CR>` is **two behaviours in one key**, decided per invocation rather than per
line:

| Range contains              | `<CR>` does            |
| --------------------------- | ---------------------- |
| any line not yet a checkbox | make them all checkboxes |
| all already checkboxes      | flip them              |
| a mix of checked/unchecked  | check the lot          |

Measured on a plain `- two` bullet: the first `<CR>` made it `- [ ] two`, the
second made it `- [x] two`.

That design is deliberate. Typing a list as plain `- foo` bullets and then
running `<CR>` down the column beats typing `[ ] ` seven times, and a range
never lands half-toggled when you are ticking off a whole sub-list.

Nothing reflows: a line keeps its own indent and marker, so ordered lists,
nested lists and prettier's output all survive a toggle.

**This exists because render-markdown has no behaviour.** It draws `[ ]` and
`[x]` as glyphs and stops there — no commands, no mappings — so nothing in the
config could actually tick a box. zk is links-and-notes only, and todo-comments
runs `comments_only = true` so it ignores prose by design.

## The outline

`<leader>fs` is normally `Snacks.picker.lsp_symbols()`, and in a markdown buffer
**nothing answers it**: zk's LSP registers completion, links, definition,
references, hover, code actions and diagnostics — but no `documentSymbol`
handler. Snacks' treesitter picker is no help either, since it drives off
`locals` queries and markdown ships none.

So the outline is built straight from the parse tree. Headings become picker
items indented by level, fuzzy-filterable on the heading text.

Reading the tree rather than the lines buys two things: a `#` inside a fenced
code block is correctly ignored, and setext headings (`===` / `---`) are picked
up alongside the `#` ones.

## Rendering, and turning it off

render-markdown draws headings, tables, code blocks and checkboxes in the
buffer. `<leader>mr` toggles it, which is the key to reach for when you need to
see the **actual characters** — editing a table's pipes, or checking what a
code span really contains.

Diagrams render inline: a ` ```mermaid ` fence becomes a PNG, in kitty, via
mermaid-cli. That needs a browser mermaid-cli can drive, which
`~/.config/mermaid/puppeteer.json` supplies by pointing puppeteer at the
installed Chrome — without it `mmdc` exits 1 looking for a chromium it never
downloaded.

Two things make it work in practice rather than in theory:

- **`SNACKS_KITTY=1`** in `dot_zshenv`. snacks detects kitty by writing an
  escape through tmux and waiting for a reply, and tmux drops that from a pane
  nobody is watching — which is exactly how `dev` builds every session. Without
  the override, images silently never place. See [Shell](shell.md).
- **A height cap.** snacks sizes an image from its pixels and mmdc writes 72dpi,
  so the default asked kitty to stretch a 587x790 chart over the whole window.

## `.scrawl`

A custom markdown variant from a side project gets its own filetype, so it can
be told apart, but is highlighted with **markdown's parser**:

```lua
vim.filetype.add({ extension = { scrawl = "scrawl" } })
vim.treesitter.language.register("markdown", "scrawl")
```

Registering the parser rather than setting `syntax = "markdown"` from a
`FileType` autocmd, and that is not a style choice — Neovim runs `syntax on`
*after* `init.lua`, so the built-in syntax autocmd is defined later, runs later,
and puts `syntax=scrawl` back. Measured. The parser is what highlights markdown
here anyway.

Verified: a `.scrawl` file reports `ft=scrawl`, parser `markdown`, and a
heading captures as `markup.heading.1`.

## Formatting

prettier, on save — except in `nvim/guides/`, which is excluded by path because
these cards are hand-formatted and prettier corrupts a code span whose content
is two backticks. The save timeout is 3000ms for markdown against 500ms
elsewhere, because prettier on a long document is genuinely slower. See
[LSP](lsp.md).

## See also

- [Notes](notes.md) — zk, and the markdown that is a notebook
- [LSP](lsp.md) — formatting, and why the guides are exempt
- [Treesitter](treesitter.md) — the parser doing the highlighting
