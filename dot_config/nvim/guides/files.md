# Files

Two browsers, good at opposite things.

- **snacks explorer** (`<leader>fe`) — a tree you *navigate*. Folds open and
  shut, so several levels are visible at once and you can find something without
  knowing its path.
- **oil** (`-`, or `<leader>-` floating) — one directory as an *editable buffer*.
  The lines are the filenames. Change them and `:w`.

The short version: **find in the explorer, change in oil.**

## The handoff

| Key | Does |
| --- | --- |
| `O` in the explorer | open oil on the directory under the cursor |
| `<leader>fe` in oil | explorer rooted where oil is, not the cwd |

So the loop is: `<leader>fe`, drill down through the tree to the directory you
want, `O`, do the editing, `<leader>fe` to carry on browsing from there.

## Explorer — finding

The list starts focused, so it's ordinary normal mode. Relative numbers are on
and `j`/`k` take a count, so **`12j` jumps 12 entries** — read the number off the
gutter rather than pressing `j` twelve times.

| Key | Does |
| --- | --- |
| `l` / `h` | open / close a directory |
| `<BS>` | go up a level |
| `.` | make the directory under the cursor the root |
| `<CR>` | open the file |
| `a` `d` `r` `c` `m` | add, delete, rename, copy, move — one at a time |
| `y` / `p` | yank / paste paths |
| `H` / `I` | toggle hidden / ignored files |
| `Z` | collapse everything |
| `]g` `[g` | next / previous file with git changes |
| `]d` `[d` | next / previous file with a diagnostic |
| `<leader>/` | grep inside the directory under the cursor |
| `O` | hand this directory to oil |

`a` `d` `r` are fine for a single file. For more than one, that's oil's job.

## Oil — changing

The buffer *is* the directory listing, so filesystem changes are ordinary text
edits, applied on `:w`:

| Edit | Effect |
| --- | --- |
| change a name | rename |
| `dd` a line | delete (to trash — `delete_to_trash` is on) |
| type a new line | create a file |
| new line ending in `/` | create a directory |
| `dd` here, `p` in another oil buffer | move the file between directories |
| `u` | undo — before `:w`, nothing has happened yet |

Everything vim does to text works here: `cw` on a name, `:%s/foo/bar/` across a
whole directory, visual block to change a column of names, `.` to repeat.

| Key | Does |
| --- | --- |
| `-` | go to the parent directory |
| `_` | go to the cwd |
| `<CR>` | open the file or descend |
| `<C-p>` | preview without leaving |
| `` ` `` | `:cd` here |
| `g.` | toggle hidden files |
| `g\` | toggle the trash view — where deletions go |
| `gs` | change sort order |
| `gx` | open with the system handler |
| `g?` | help |

> **Two keys mean something else in an oil buffer.** `gs` is change-sort, not the
> surround prefix. `<C-h>` opens the file in a horizontal split, rather than moving
> to the window or tmux pane on the left.

## Recipes

**Rename a run of files.** `-` into the directory, then treat the names as text:
visual block over a shared prefix and `c`, or `:%s/^old/new/`. `:w` to apply.
Nothing touches disk until then, so `u` is free.

**Delete several files.** Visual select the lines, `d`, `:w`. They go to trash,
and `g\` shows the trash view if you want one back.

**Create a nested tree.** In oil, type the lines you want — `src/`, `tests/`,
`README.md` — and `:w`. Directories ending in `/` are created as directories,
and intermediate ones are created for you.

**Move files between directories.** Open oil in the source, `dd` the lines you
want. Open oil in the destination (`-` up, then `<CR>` down, or `<leader>fe` and
navigate), `p`, `:w`.

**Find something, then work on it.** `<leader>fe`, navigate with `12j`-style
jumps and `l`/`h`, then either `<CR>` to open the file, or `O` if what you
actually wanted was to reorganise the directory it's in.

**Grep a subtree.** `<leader>fe`, put the cursor on the directory, `<leader>/`.

## Why not just one of them

The explorer can rename and delete (`r`, `d`), and oil can navigate (`-`, `<CR>`).
Either can do the other's job badly. The split worth keeping is that the explorer
shows you *many* directories at once and oil lets you *edit* one of them — so
reach for the explorer when you don't know where a thing is, and oil when you
know exactly what you want the directory to look like afterwards.

---

The rules behind these bindings: [Keymap conventions](keymaps.md).
