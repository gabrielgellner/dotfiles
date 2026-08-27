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
adds**, not everything that has landed on the base since the branch was cut.
That distinction is the whole point: `..` would show you other people's work
too.

The view opens **inline** — one window, deletions as virtual lines above the
additions — which is the unified layout GitLab shows a merge request in. Press
`t` for side-by-side when a change reads better that way.

| Inside the view           | Does                                        |
| ------------------------- | ------------------------------------------- |
| `]c` / `[c`               | next / previous hunk                        |
| `]f` / `[f`               | next / previous file                        |
| `t`                       | toggle inline ↔ side-by-side                |
| `gc`                      | toggle compact — collapse unchanged context |
| `<leader>e` / `<leader>b` | focus / toggle the file explorer            |
| `g?`                      | full keymap help                            |
| `q`                       | quit                                        |

> **These keys mean different things here.** Everywhere else `]f` is next
> function. Inside a codediff view it's next file. Same for `<leader>e`, which
> is normally the diagnostic float.

The statusline shows **`hunk 3/5`** while the cursor is in a diff pane, so how
much of the file is left to read is answerable without walking to the end. It
counts from the top of the file rather than from where you started, and reads
`0/5` above the first hunk. `]c` also echoes the same count as it moves — the
statusline is the version that stays put.

> **One key for "next change", everywhere.** `]c`/`[c` is vim's own diff motion
> (`:help ]c`), so it now means next/previous hunk in gitsigns, next/previous
> hunk in codediff, and next/previous change in plain vimdiff. gitsigns' `]h` is
> gone: it worked in the working-tree review and silently did nothing under
> `<leader>gm`, because gitsigns attaches to the first and not the second.

If the squashed diff is too big to read in one sitting, `<leader>gM` gives the
same range **commit by commit** instead, so you can follow the author's steps.

| Key          | Does                                                |
| ------------ | --------------------------------------------------- |
| `<leader>gm` | review branch vs base — the MR view                 |
| `<leader>gM` | the same range, commit by commit                    |
| `<leader>gu` | review **unpushed** work — what the next push sends |
| `<leader>gU` | the same range, commit by commit                    |
| `<leader>gv` | review the working tree — your own uncommitted work |
| `<leader>gh` | history of the current file                         |
| `<leader>gH` | history of the repo                                 |

## Before you push

`<leader>gm` answers "what does this branch add to its base". It cannot answer
"what am I about to push", and on the default branch it answers *nothing* —
there `base...HEAD` is empty by definition, so the key opens no diff at all.

`<leader>gu` is the same view against `@{upstream}` instead: the commits that
exist locally and not on the remote. `<leader>gU` walks them one at a time, the
way `<leader>gM` does for a branch.

`@{upstream}` rather than a hardcoded `origin/main`, so it follows whatever the
branch actually tracks — `origin/main` in the dotfiles repo, and
`origin/session-74-prep` in a feature branch, without either being named.

Two quiet answers are correct rather than broken:

- **"No changes to show"** — you are in sync with the remote, nothing to push.
- **a warning naming `git push -u origin HEAD`** — the branch has no upstream
  at all, so there is no "what will push" to compute. Use `<leader>gm` there.

## Working the code, not just reading it

The diff panes are **not real buffers**. Under `<leader>gm` both sides are
historical content, so the pane is `nofile`, unnamed, unmodifiable, and has no
LSP client attached. `gd`, `gr`, hover and rename all do nothing there. This is
not a misconfiguration — there is no file on disk for a server to answer about.

Three things work anyway, and between them they cover most of why you wanted
`gd`.

**`<leader>fw` — what else touches this.** Grep for the word under the cursor,
straight from the diff pane. It searches the working tree rather than asking a
language server, so the pane being virtual doesn't matter. For "what does this
change impact", the list of every use is usually more informative than the one
definition `gd` would have given you. `<C-y>` copies a result out — see
[pickers.md](pickers.md).

**`]c` then `yih` — copy a hunk.** `ih` is a hunk textobject, so `yih` yanks the
whole change under the cursor. Pair it with `]c` and you can walk the diff
lifting hunks into a message or a review comment.

**`gf` — leave for the real file.** This is the escape hatch to a buffer where
every LSP key works normally.

`gf` is **anchored on the line's text**, not its number. codediff's own version
copies the cursor position across verbatim, which is right only while the file
on disk still matches the side under review — and wrong silently when it
doesn't. With five lines added at the top of a file, a `gf` from a line reading
`TARGET MARKER` landed five lines short on unrelated code, with no warning.

So the mapping here lets codediff navigate, then checks where it landed:

```
same text          nothing to say, you are on the right line
text found nearby  cursor corrected, "line moved 51 -> 56 in the working copy"
text not found     warned: "this line is not in the working copy"
```

`gF` is codediff's original, kept for when you mean "go to line N" literally.
Everywhere outside a diff pane, `gf` is still vim's own go-to-file.

The round trip is `gf`, work in the real file, `g<Tab>` back to the review.

## Getting back to your file

codediff opens its review in a **new tab**, so the file you were editing is
still there, one tab over. The tabline at the top names them — `m.py` next to
`2 CodeDiff History [3]` — and it is clickable, but the keyboard is faster.

| Key         | Does                                           |
| ----------- | ---------------------------------------------- |
| `g<Tab>`    | the tab you were in last — the alt-tab of tabs |
| `gt` / `gT` | next / previous tab                            |
| `3gt`       | tab 3 directly                                 |
| `<C-w>T`    | move this window out into a tab of its own     |

`g<Tab>` is the one to learn. Reviewing is two tabs — your work and the review —
and it flips between them, so you never count or cycle. All four are Neovim
builtins; nothing here configures them.

Tabs can accumulate if you open several reviews, and `gt` cycling gets old past
about four. That is the point at which numbered jumps (`<leader>1`…`<leader>9`)
would be worth adding; they are not bound today.

## While you're working

gitsigns, in the buffer, no separate UI.

| Key          | Does                                                  |
| ------------ | ----------------------------------------------------- |
| `]c` / `[c`  | next / previous hunk — normal and visual, not operators |
| `ih`         | the hunk as a text object — `dih`, `vih`              |
| `<leader>gp` | preview the hunk in a popup                           |
| `<leader>gP` | preview it inline instead                             |
| `<leader>gs` | stage the hunk — in visual, just the selected lines   |
| `<leader>gS` | stage the whole buffer                                |
| `<leader>gr` | reset the hunk — in visual, just the selected lines   |
| `<leader>gR` | reset the whole buffer                                |

> **Not after an operator.** `v]c` extends a selection to the next hunk, but
> `d]c` deletes nothing at all, silently. gitsigns moves the cursor from a
> scheduled callback — immediately after `nav_hunk()` returns the cursor has not
> moved yet, and only a tick later does it land — so an operator has already
> resolved against no movement. Use `v]c` then `d`.

`<leader>gs` is also **unstage**: on a hunk that's already staged it takes it
back out. gitsigns removed the separate undo-stage action, and staged hunks get
their own sign so you can see which you're aiming at.

## Who wrote this, and when

| Key          | Does                                          |
| ------------ | --------------------------------------------- |
| `<leader>gl` | blame this line — popup, full commit message  |
| `<leader>gL` | toggle persistent inline blame for every line |
| `<leader>gB` | blame the whole file in a scrollbound split   |
| `<leader>gd` | diff this file against the index              |
| `<leader>gD` | diff it against `HEAD~`                       |

## Jumping to things

| Key          | Does                                     |
| ------------ | ---------------------------------------- |
| `<leader>gf` | changed files — `git status` as a picker |
| `<leader>gb` | branches                                 |
| `<leader>gc` | commits (log)                            |
| `<leader>gg` | lazygit, for anything not covered here   |

## Recipes

**Review a branch someone wants merged.** Check it out, then `<leader>gm`. Walk
files with `]f`, hunks with `]c`. Hit `gc` if the context is drowning the
changes. Anything you want to come back to, note in `<leader>.`. If the diff is
too large to hold in your head, `<leader>gM` instead and read it commit by
commit.

**Review your own work before committing.** `<leader>gv` shows the working tree
in the same view. From the explorer, `-` toggles a file staged, `S` stages
everything and `U` unstages it.

**Stage only part of a messy file.** In the buffer, `]c` to the hunk,
`<leader>gp` to check it, `<leader>gs` to stage it. For less than a whole hunk,
select the lines in visual mode first — `<leader>gs` then takes only those.

**Work out when a line broke.** `<leader>gl` for the commit that last touched
it. If that isn't the one, `<leader>gh` for the file's history and read
backwards.

**Undo a change you just made.** `<leader>gr` resets the hunk under the cursor.
`[u` / `]u` walk Neovim's own undo states, which is the finer-grained tool.

---

The rules behind these bindings: [Keymap conventions](keymaps.md).
