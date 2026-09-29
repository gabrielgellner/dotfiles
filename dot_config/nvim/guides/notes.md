# Notes

Three tiers, and the whole design is that they are sorted by **friction**. A
thought costs one keystroke to capture, a little more to keep, and the move
between them is explicit rather than automatic.

| Tier        | Key          | Lives in   | For                                    |
| ----------- | ------------ | ---------- | -------------------------------------- |
| Project     | `<leader>.`  | `~/scratch` | this branch, this bug, this afternoon |
| Global      | `<leader>ng` | `~/scratch` | cross-project thinking, plans          |
| Second brain | `<leader>z…` | `~/notes`  | notes worth keeping, linked and indexed |

The reason to know all three is that the wrong tier is the one that loses
things. A thought typed into a project notebook is gone the moment you stop
working on that project; the same thought in zk is findable in a year.

## Scratch — the working log

| Key          | Does                                             |
| ------------ | ------------------------------------------------ |
| `<leader>.`  | project notes — the most-reached-for key         |
| `<leader>nn` | the same thing, in the notes group               |
| `<leader>ng` | the **global journal**, not keyed to any project |
| `<leader>ns` | pick from every scratch notebook                 |
| `<leader>np` | promote this buffer into zk                      |

`<leader>.` and `<leader>nn` are deliberately the same action. The dot is at the
top level because it is reached for more than anything else in the group.

**`<leader>ng` is the one that is easy to miss.** Project notes are keyed to the
directory you are in, which is exactly right for "why is this test flaky" and
exactly wrong for "what should I do about X". The journal passes
`filekey = { cwd = false }`, so it is the same notebook wherever you open it
from — the place for thinking that does not belong to any one project.

Both accumulate under `## YYYY-MM-DD` headings. Opening a notebook on a new day
appends today's heading and leaves the cursor at the bottom, so a notebook reads
as a journal rather than a soup of undated fragments. They auto-save when
hidden, so there is nothing to write and nothing to lose.

`vim.v.count1` picks between numbered notebooks: `2<leader>nn` is a second
project notebook, `3<leader>nn` a third. Worth knowing before you need it,
because there is no other way to get a second one.

`<leader>nl` is in this group but is **not** a notebook — it is a Lua pad, and
`<CR>` there runs the buffer, or just the selection, with output inlined and
errors raised as diagnostics. A REPL that happens to live next door.

## Promoting — the one-way door

`<leader>np` takes the buffer you are in, asks for a title, and creates a zk
note from it. That is the intended path from "half-formed" to "kept", and it is
manual on purpose: deciding a thought is worth keeping is the useful part.

It passes the notebook explicitly, because the scratch root is not inside a
notebook and zk cannot infer one from the buffer path.

## zk — the second brain

Normal mode:

| Key          | Does                             |
| ------------ | -------------------------------- |
| `<leader>zn` | new note                         |
| `<leader>zo` | open notes                       |
| `<leader>zf` | find notes, full-text            |
| `<leader>zt` | browse tags                      |
| `<leader>zb` | backlinks **to** this note       |
| `<leader>zl` | notes this note **links to**     |
| `<leader>zk` | insert a link to a note          |
| `<leader>zi` | reindex the notebook             |

With a selection:

| Key          | Does                                  |
| ------------ | ------------------------------------- |
| `<leader>zn` | new note, selection as the **title**   |
| `<leader>zc` | new note, selection as the **content** |
| `<leader>zl` | link the selection to a note          |

**`zk` inserts a link and `zl` lists outgoing ones**, which is the pair worth
getting straight — `zl` already carries two meanings across normal and visual
mode, so the insert went to a different letter rather than a third `l`.

Notes use `[[WikiLinks]]`, 4-character IDs as filenames, and `#hashtags`. Dead
links are an LSP **error** and an untitled note a hint, both surfaced as
diagnostics — so a broken link shows up while you are editing rather than when
you next go looking for it.

### Which notebook you are in

Resolution is per-session, in order:

1. the notebook containing the note you are editing
2. the notebook containing the working directory
3. `$ZK_NOTEBOOK_DIR` — the default second brain, `~/notes`

So a project with its own `.zk/` is an independent notebook, and everything
else falls back to the second brain. **Keep one notebook per Neovim session**:
zk-nvim caches a single LSP client per session, which is why this is fine with
the per-project tmux sessions `dev` makes, and not fine if you go wandering.

The index is zk's own, and it does not notice notes that arrived from outside
the session — a `git pull`, a script, another machine. `plugins/zk.lua`
reindexes whenever a note is opened, and `<leader>zi` forces it.

## Where all this lives, and what is synced

| Directory   | Tracked                      | Synced                          |
| ----------- | ---------------------------- | ------------------------------- |
| `~/scratch` | no                           | nowhere — this machine only     |
| `~/notes`   | its own **private** git repo | `just sync`                     |

**None of it is in the dotfiles repo, and that is a safety boundary rather than
a tidiness one: that repo is public.** `.chezmoiignore` carries `scratch/*` with
a single `!scratch/.prettierrc` exception, so `chezmoi add ~/scratch/...` cannot
sweep a note in by accident.

`~/scratch` is untracked by git as well, deliberately. Its `.meta` sidecars
record an absolute `cwd` (`/Users/gabrielgellner/dev/...`) which would not
resolve on the Linux machine, so a synced scratch would not find its project
notebooks there anyway. It is the tier you are allowed to lose.

`~/notes` is github.com/gabrielgellner/notes, private. Only `.zk/notebook.db` is
gitignored — a SQLite index `zk index` rebuilds. `.zk/config.toml` and
`.zk/templates/` **are** tracked, because without them a clone is a pile of
markdown rather than the same notebook.

### `just sync`

Run from `~/notes`, and it is the whole round trip:

```
just sync      # commit anything new, pull --rebase, push, reindex
just status    # what is here, and what is not yet anywhere else
just hooks     # point this clone at the tracked pre-push guard — once per clone
```

It commits before pulling, because the alternative needs a stash and a stash
that fails to pop mid-conflict is a worse place to be than a commit that needs
amending. It rebases rather than merges, so two machines writing notes produce a
linear history rather than a merge bubble per sync. And it reindexes afterwards,
so the pickers are right before nvim is even started.

If the same note changed on both machines the rebase stops and says so, with the
two ways out — `git rebase --continue` after fixing, or `git rebase --abort`.
Nothing is auto-resolved: merging two versions of a thought is not a thing a
script should guess at.

**There is no automation behind any of this.** Notes reach the other machine
when you run `just sync`, and not before.

[Just recipes](just.md) has the rest — what each step does in order, and what
to do when a conflict stops the rebase.

### Why main is guarded by a hook and not a rule

The dotfiles repo has a `protect-main` ruleset, so a force-push to it is
refused by GitHub itself. This repo cannot have one: **rulesets and classic
branch protection are both 403 on a private repo on the free plan** — "Upgrade
to GitHub Pro or make this repository public", and making a notebook public is
not a trade worth making. The dotfiles ruleset works precisely because that
repo is public.

`.githooks/pre-push` is the stand-in. It refuses a non-fast-forward push or a
deletion of main, and it is weaker than a rule in three specific ways, all of
which are written in the hook itself: it binds only a clone whose
`core.hooksPath` points at it, a fresh clone is unprotected until `just hooks`,
and `--no-verify` walks straight past it. It stops the mistake, not the intent.

`just sync` warns when the guard is inactive rather than refusing to run — a
sync that will not run is worse than an unguarded one, because the notes still
need to leave the machine.

## Getting a notebook onto another machine

```
git clone git@github.com:gabrielgellner/notes.git ~/notes
```

`ZK_NOTEBOOK_DIR` already points there from `dot_zshrc`, so nothing else needs
configuring. There is no index in a fresh clone; the first note you open builds
one, or `zk index` does it up front.

`journal/.gitkeep` in that repo is load-bearing, which is worth knowing before
you tidy it away: git does not track an empty directory, and **zk does not
create a missing one** — `zk new` into an absent path fails with "directory not
found". The `daily` alias writes to `journal/`, so without the keepfile it would
fail on a fresh clone.

## See also

- [Pickers](pickers.md) — the key frame `<leader>ns`, `<leader>zo` and
  `<leader>zf` all share
- [Keymap conventions](keymaps.md) — why `<leader>z` has 5 mappings in a Lua
  buffer and 14 in markdown
