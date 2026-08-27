# Search and replace

Four tools, and the useful question is always the same: **how far does the
change reach?** One buffer, or files you have not opened.

```
one buffer          :%s///g              type the replacement once
one buffer          <leader>v…           see every site, edit them together
across files        <leader>sr / sW      preview, then commit
across files        :cfdo                no preview, one command
a code symbol       <leader>cr           none of the above — use the LSP
```

## Start here: is it a symbol?

If you are renaming a function, variable, class or module, **`<leader>cr`** is
the answer and the rest of this guide is the wrong tool. LSP rename knows
scope: it will not touch a local of the same name in another function, and it
will not touch the word inside a string or a comment. Every option below is
text substitution and cannot tell those apart.

Use the text tools for what the LSP has no opinion about — prose, config
values, a term across notes, a string literal.

## One buffer, typed once — `:%s`

The details worth knowing are in [cmdline.md](cmdline.md); the short version:

| Command | Does |
| --- | --- |
| `:%s/old/new/g` | every match in the buffer |
| `:%s/<C-r><C-w>/new/g` | `<C-r><C-w>` pulls in the word under the cursor |
| `/old` then `:%s//new/g` | an empty pattern reuses the last search |
| `:%s/old/new/gc` | `c` asks per match — `y` `n` `a` `q` |
| `:'<,'>s/old/new/g` | visual selection only |

Good when you can describe the change as a pattern. Bad when you cannot —
which is what the next one is for.

## One buffer, seen — multicursor

The Helix-shaped alternative: put a cursor on every site, then edit them all at
once and *watch* it happen. No regex in the replacement, no guessing.

Getting cursors down:

| Key | Mode | Does |
| --- | --- | --- |
| `<leader>vv` | n, x | a cursor at every match of the word in the file |
| `<leader>vn` / `<leader>vN` | n, x | add a cursor at the next / previous match |
| `<leader>vr` | x | a cursor at each regex match inside the selection |
| `<leader>vs` | x | split the selection at each regex match |
| `<leader>vl` | x | one cursor per line of the selection |
| `<leader>vj` / `<leader>vk` | n, x | add a cursor a line down / up |

Then edit as normal — `ciw`, `A`, `x` — and every cursor does the same thing.
`<leader>vI` and `<leader>vA` start insert at the beginning or end of each
selected line without the round trip.

While cursors are down, four keys change meaning, and only while they are down:

| Key | Does |
| --- | --- |
| `<Tab>` / `<S-Tab>` | move between cursors |
| `<leader>vx` | drop the cursor under you |
| `<C-a>` / `<C-x>` | increment as a **sequence** — 1, 2, 3 rather than all the same |
| `<Esc>` | collapse back to one cursor |

`<leader>vu` brings the last set back if you collapsed too early, and
`<leader>va` aligns the cursor columns.

**`<leader>vt` / `<leader>vT` rotate the contents *between* cursors**, leaving
the cursors where they are — Helix's `alt-(` and `alt-)`. Vim has no equivalent:
swapping two function arguments is otherwise a yank, two deletes and two pastes.
Put a cursor on each argument, press `<leader>vt`, and they trade places.

The reason to reach for this over `:%s` is that you can see all the sites
before committing to anything, and the edit can be any normal-mode command
rather than a replacement string.

## Across files, with a preview — `<leader>sr`

grug-far. Opens a buffer listing every match; edit the replacement line and the
preview updates; commit when it looks right.

| Key | Scope |
| --- | --- |
| `<leader>sr` | search and replace, prompt empty |
| `<leader>sr` (visual) | seeded with the selection |
| `<leader>sw` | the word under the cursor, **this file** |
| `<leader>sW` | the word under the cursor, **the project** |

Lowercase is this file, capital is the project — the same relationship `w`/`W`
has in vim, and the one a capital carries everywhere else here.

This is the tool for a change you are not yet sure about, in files you have not
opened. That is the whole value: the preview.

## Across files, without one — `:cfdo`

The built-in path, using the quickfix list. No preview, no per-match control,
one command:

```
<leader>fg          grep the project
                    type the term
<C-q>               send the matches to the quickfix list
:cfdo %s/old/new/ge | noautocmd update
```

`e` on the substitute so a file with no match does not abort the run.

> **`noautocmd` is not optional here.** A plain `| update` triggers
> format-on-save on every file it touches. Replacing a term across three
> markdown files that way rewrote them from three lines to one — prettier
> reflowed the prose, because that is what saving a markdown file does in this
> config. The replacement itself was correct; everything around it moved. With
> `noautocmd update` the same run left all three files at three lines with both
> replacements in place.
>
> `.txt` and other filetypes with no formatter are unaffected either way, which
> is exactly what makes this easy to miss.

Undo is per file and you have to visit each one, so prefer `<leader>sr` when
the change is at all uncertain.

## Picking

- Renaming code? `<leader>cr`.
- One file, and you can write the pattern? `:%s`.
- One file, and you would rather see it? `<leader>v…`.
- Several files, and you want to look first? `<leader>sr` / `<leader>sW`.
- Several files, and you are certain? `:cfdo … | noautocmd update`.

## See also

- [cmdline.md](cmdline.md) — the `:` prompt, `<C-r><C-w>`, and the substitute flags
- [navigation.md](navigation.md) — the multicursor section in context
- [pickers.md](pickers.md) — `<C-q>` and the rest of the picker keys
