# Git

Two layers, used at different moments:

- **gitsigns** — in the file you're editing, hunk by hunk, while you work.
- **codediff** — a dedicated review UI for reading a whole change at once.

Both are keyed under `<leader>g`. gitsigns' keys are buffer-local and only exist
in tracked files; codediff's are global.

## Reviewing a branch before you merge it

This is the merge-request flow. `<leader>gm` is the key.

```
<leader>gm     the branch's changes against its base
```

It resolves the base from `origin/HEAD` (falling back to main, then master), and
diffs with `base...HEAD` — git's merge-base syntax, so you see **what the branch
adds**, not everything that has landed on the base since the branch was cut. That
distinction is the whole point: `..` would show you other people's work too.

The view opens **inline** — one window, deletions as virtual lines above the
additions — which is the unified layout GitLab shows a merge request in. Press
`t` for side-by-side when a change reads better that way.

| Inside the view | Does |
| --- | --- |
| `]c` / `[c` | next / previous hunk |
| `]f` / `[f` | next / previous file |
| `t` | toggle inline ↔ side-by-side |
| `gc` | toggle compact — collapse unchanged context |
| `<leader>e` / `<leader>b` | focus / toggle the file explorer |
| `g?` | full keymap help |
| `q` | quit |

> **These keys mean different things here.** Everywhere else `]c` is next class
> and `]f` is next function. Inside a codediff view they're hunk and file. Same
> for `<leader>e`, which is normally the diagnostic float.

> **`]h` is not the key here, even though it sometimes works.** gitsigns attaches
> to the working-tree view (`<leader>gv`, `<leader>gd`) because those buffers map
> to tracked files, so `]h` happens to move there. It does not attach to
> `<leader>gm` or `<leader>gM`, where the buffer is a revision snapshot — `]h` is
> silently dead in exactly the review you reach for most. `]c` works in all of
> them.

If the squashed diff is too big to read in one sitting, `<leader>gM` gives the
same range **commit by commit** instead, so you can follow the author's steps.

| Key | Does |
| --- | --- |
| `<leader>gm` | review branch vs base — the MR view |
| `<leader>gM` | the same range, commit by commit |
| `<leader>gv` | review the working tree — your own uncommitted work |
| `<leader>gh` | history of the current file |
| `<leader>gH` | history of the repo |

## While you're working

gitsigns, in the buffer, no separate UI.

| Key | Does |
| --- | --- |
| `]h` / `[h` | next / previous hunk; works after an operator (`d]h`) |
| `ih` | the hunk as a text object — `dih`, `vih` |
| `<leader>gp` | preview the hunk in a popup |
| `<leader>gP` | preview it inline instead |
| `<leader>gs` | stage the hunk — in visual, just the selected lines |
| `<leader>gS` | stage the whole buffer |
| `<leader>gr` | reset the hunk — in visual, just the selected lines |
| `<leader>gR` | reset the whole buffer |

`<leader>gs` is also **unstage**: on a hunk that's already staged it takes it back
out. gitsigns removed the separate undo-stage action, and staged hunks get their
own sign so you can see which you're aiming at.

## Who wrote this, and when

| Key | Does |
| --- | --- |
| `<leader>gl` | blame this line — popup, full commit message |
| `<leader>gL` | toggle persistent inline blame for every line |
| `<leader>gB` | blame the whole file in a scrollbound split |
| `<leader>gd` | diff this file against the index |
| `<leader>gD` | diff it against `HEAD~` |

## Jumping to things

| Key | Does |
| --- | --- |
| `<leader>gf` | changed files — `git status` as a picker |
| `<leader>gb` | branches |
| `<leader>gc` | commits (log) |
| `<leader>gg` | lazygit, for anything not covered here |

## Recipes

**Review a branch someone wants merged.** Check it out, then `<leader>gm`. Walk
files with `]f`, hunks with `]c`. Hit `gc` if the context is drowning the
changes. Anything you want to come back to, note in `<leader>.`. If the diff is
too large to hold in your head, `<leader>gM` instead and read it commit by
commit.

**Review your own work before committing.** `<leader>gv` shows the working tree
in the same view. From the explorer, `-` toggles a file staged, `S` stages
everything and `U` unstages it.

**Stage only part of a messy file.** In the buffer, `]h` to the hunk, `<leader>gp`
to check it, `<leader>gs` to stage it. For less than a whole hunk, select the
lines in visual mode first — `<leader>gs` then takes only those.

**Work out when a line broke.** `<leader>gl` for the commit that last touched it.
If that isn't the one, `<leader>gh` for the file's history and read backwards.

**Undo a change you just made.** `<leader>gr` resets the hunk under the cursor.
`[u` / `]u` walk Neovim's own undo states, which is the finer-grained tool.

---

The rules behind these bindings: [Keymap conventions](keymaps.md).
