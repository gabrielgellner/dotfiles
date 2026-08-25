# Command line

The `:` prompt is a small editor, not just a text box. Three things make it one:
completion, a set of insert-from-elsewhere keys, and a real buffer you can
escape into when a command outgrows one line.

## Completion

The menu now appears as you type `:`, like a command palette. It does **not**
appear for `/` and `?` — those are incremental, and a popup over the buffer
would hide the match you're watching. Ghost text still shows there.

| Key               | Does                                            | From  |
| ----------------- | ----------------------------------------------- | ----- |
| `<Tab>`           | show the menu, or accept when only one match    | blink |
| `<S-Tab>`         | same, selecting from the bottom                 | blink |
| `<C-n>` / `<C-p>` | next / previous match                           | blink |
| `<C-y>`           | accept the selection                            | blink |
| `<C-e>`           | dismiss the menu                                | blink |
| `<C-space>`       | force the menu (this is how you get it for `/`) | blink |
| `<C-d>`           | list all matches without a menu                 | vim   |
| `<C-a>`           | insert _every_ match at once                    | vim   |
| `<C-l>`           | complete to the longest unambiguous prefix      | vim   |

Arrow keys move the cursor, not the selection — `<Left>`/`<Right>` are handed
back deliberately, since with the menu open most of the time you want them for
editing the command you're writing.

`<C-a>` is the surprising one: `:e src/<C-a>` puts every file in that directory
on the line at once, which is how you feed a list to `:argdo` or `:vimgrep`.

## Pulling text in

You rarely want to _type_ the thing you're operating on.

| Key          | Inserts                                             |
| ------------ | --------------------------------------------------- |
| `<C-r><C-w>` | the word under the cursor                           |
| `<C-r><C-a>` | the WORD under the cursor (through punctuation)     |
| `<C-r><C-f>` | the filename under the cursor                       |
| `<C-r>%`     | the current file's name                             |
| `<C-r>"`     | the unnamed register — what you last yanked         |
| `<C-r>0`     | the last _yank_ specifically, unaffected by deletes |
| `<C-r>+`     | the system clipboard                                |
| `<C-r>=`     | the result of an expression, e.g. `<C-r>=line('$')` |

So the substitute you actually want is rarely typed out: put the cursor on the
symbol, `:%s/<C-r><C-w>/newname/g`.

## Editing the line

| Key               | Does                                         |
| ----------------- | -------------------------------------------- |
| `<C-w>`           | delete the word before the cursor            |
| `<C-u>`           | delete to the start of the line              |
| `<C-b>` / `<C-e>` | start / end of line                          |
| `<C-f>`           | **open the command-line window** — see below |

## History

`<Up>` and `<Down>` filter by what you've already typed. Type `:CodeDiff` then
`<Up>` and you walk only through past commands starting with `CodeDiff`, rather
than everything. This is the fastest way back to a long command and is worth
preferring over reaching for the history window.

## The command-line window

`<C-f>` while typing, or `q:` from normal mode, opens your command history as a
**real buffer** — one command per line, `filetype=vim`, seven lines tall.

| Open                | Shows                                      |
| ------------------- | ------------------------------------------ |
| `q:`                | command history                            |
| `q/` and `q?`       | search history                             |
| `<C-f>` mid-command | the same, carrying what you'd typed so far |

Inside it, everything works: `cw`, `f/`, visual block, `.`, `u`, and `/` to
search your own history. `<CR>` runs the line under the cursor. `<C-c>` returns
to the ordinary prompt; `:q` or `ZZ` closes it.

The menu auto-shows here too, and since it's a real buffer with room, that's
comfortable rather than intrusive.

**The catch:** while it's open you can't leave it — moving to another window
gives `E11: Invalid in command-line window`. It's modal by design.

## Recipes

**Fix a long substitute you got wrong.** You're deep into
`:%s/\v(\w+)\s+(\w+)/\2 \1/g` and spot a mistake near the start. `<C-f>` — now
you're in a buffer where every motion works. Fix it, `<CR>`.

**Rename a symbol without typing it.** Cursor on the symbol,
`:%s/<C-r><C-w>/newName/gc`. The `c` flag asks per match, `y`/`n`/`a`/`q` to
answer.

**Reuse the last search.** Search with `/foo`, then `:%s//bar/g` — an empty
pattern means "whatever I just searched for", so you never type it twice.

**Operate on a visual selection.** Select, then `:` — vim inserts `'<,'>` for
you, so `:'<,'>s/foo/bar/g` applies only there.

**Run a normal-mode command over many lines.** `:%norm A;` appends a semicolon
to every line. Combine with a range or `:g` for the lines you mean.

**Act on every line matching a pattern.** `:g/TODO/d` deletes them all;
`:g/^func/norm O// ` inserts a comment above each. `:v/pattern/d` is the inverse
— delete everything that _doesn't_ match.

**Dig an old command back out.** `q:`, then `/` to search your history, edit the
line you find, `<CR>`.

**Feed a directory to a command.** `:args src/<C-a>` puts every file on the
line, ready for `:argdo`.

---

The rules behind these bindings: [Keymap conventions](keymaps.md).
