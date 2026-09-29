# Tmux

**The prefix is `C-a`**, not `C-b`. Everything below is written `prefix + x`.

The shape of this setup is one idea: **a session per project, windows inside
it, and never panes.** Every window holds a single pane, `prefix + 1/2/3` moves
between them, and the pane-splitting keys go unused. Knowing that explains most
of what follows — including why there is no plugin manager.

## Getting between sessions

| Key              | Does                                  |
| ---------------- | ------------------------------------- |
| `prefix + C-j`   | the `dev` picker, in a popup          |
| `prefix + Enter` | the same picker                       |
| `prefix + C-p`   | the music popup — see [Music](music.md) |
| `prefix + 1`…`9` | window by index                       |
| `prefix + r`     | reload `~/.tmux.conf`                 |

`dev` is the switcher and it does two jobs at once: it lists **live sessions**
first, most-recently-attached first, then the **projects** in `~/dev` that have
no session yet. Picking a live one switches to it; picking a project builds a
session for it and goes there.

That ordering is the alt-tab one, deliberately. Alphabetical was stable but made
swapping between two sessions a reading exercise — the one you just came from
sat wherever its name fell. Now it is the top entry, so the common case is one
keypress.

The current session is pushed to the **end** of its group rather than hidden.
It sorts newest by definition, so leaving it in place would park the one session
you cannot switch to exactly where the cursor starts.

| In the picker | Does                             |
| ------------- | -------------------------------- |
| `Enter`       | switch to it, or build it        |
| `ctrl-x`      | kill the highlighted session     |

`ctrl-x` can reach the session you are *in*, which is why that one is listed at
all. Killing it does not drop you to the shell: `detach-on-destroy off` switches
the client to the most recently active remaining session instead, which is what
was meant every time.

## What a project session looks like

`new-session <name> <dir>` builds it, and `dev` calls it for you:

```
1 nvim      # nvim, already running
2 console   # a build
3 console   # something else
```

Two consoles rather than one because a build and a test run want different
windows. They also hold output that outlives nvim: the `<leader>j…` recipes
(`jj` pick, `jt` test, `jb` build) `send-keys` into window 2 exactly as if you
had typed it there, falling through to window 3 when 2 is busy. That is why
`history-limit` is 50000 rather than tmux's default 2000 — one verbose test run
can exceed the default and scroll away the output that was deliberately routed
there.

Running `new-session` again on a session that already exists **goes to it**
rather than laying it out a second time. That is the obvious mistake to make,
and the early version renamed the live window, typed `nvim` into it and appended
two more consoles.

## Copying

| Key                  | Does                                 |
| -------------------- | ------------------------------------ |
| `prefix + [`         | enter copy mode                      |
| `v`                  | begin selection (vi keys)            |
| `y` or `Enter`       | copy to the **system** clipboard     |
| drag with the mouse  | copies on release                    |
| `prefix + P`         | paste from the system clipboard      |

`mode-keys vi`, so movement in copy mode is `hjkl`, `/` searches, `gg`/`G`
jump. The clipboard command is chosen once at load — `pbcopy` on macOS,
`xclip` on Linux — so `y` means the same thing on both machines.

Note `prefix + P` is paste and `prefix + p` is not: lowercase is tmux's own
previous-window.

## The status bar

Left is the session name. Right is three things, and **two of them print
nothing when there is nothing to say**, so the bar is unchanged from before
they existed unless something is happening:

```
 ♪ title · artist   ⣿ 3 ⣤ 0 ⣀ 0   Tue 29 Sep 14:58
 └─ gmuse ──────┘   └─ Claude ─┘   └─ clock ──────┘
```

`♪` is playing and `⏸` is paused; nothing at all when the engine has no track.

The braille glyphs are Claude's state across **every** session, so a run
finishing somewhere else is visible without switching to it:

| Glyph | Means                          | Colour |
| ----- | ------------------------------ | ------ |
| `⣿`   | working                        | yellow |
| `⣤`   | waiting on you                 | pink   |
| `⣀`   | idle, finished                 | green  |

The order is by glyph height rather than importance, so the row reads as a
falling bar. `dev` shows the same three states per session as `[a]`, `[q]` and
`[i]` before the session name — the picker and the bar must not disagree about
one session, so they split the states the same way.

**These are latches, not samples.** Nothing polls: hooks in
`~/.claude/settings.json` write one file per session, and `status-interval 5`
only re-renders what is already on disk. A missed edge is therefore permanent
rather than late, which is the whole of the bug this feature carried for its
first month — see the Claude section of CLAUDE.md.

The music field asks the gmuse **engine** over its socket, not the TUI, so it
answers whether or not a popup is on screen.

## No plugins, and no plugin manager

`.tmux/plugins` is in `.chezmoiignore` as a guard. tpm carried exactly two
plugins and both are gone:

- **catppuccin** — 3.4MB and 131 files of shell to produce a dozen `set -g`
  lines. What it actually left on the server was read back with `tmux show -g`
  and pasted into the config, with the palette references resolved to literal
  hex. Nothing is computed at load now.
- **vim-tmux-navigator** — forwarded `<C-hjkl>` between tmux panes and nvim
  windows. Never used, because there are no panes to navigate between. nvim
  binds `<C-hjkl>` to plain `wincmd` itself, which is the half that was in use.

## Things that bit, and are worth not rediscovering

**`C-m` is Enter.** Same byte, the way `C-i` is Tab and `C-[` is Esc. So the
music popup is on `C-p`, not the obvious `C-m` — binding `C-m` and `Enter` to
different commands and pressing `C-m` fired the `Enter` one.

**A bare session name can hit the wrong session.** tmux resolves a target by
exact match, then *prefix*, then fnmatch, so `has-session -t pinax` answers true
when only `pinax-ai` exists. Every target in `dev` and `new-session` is written
`=name` to force exact matching. The kill binding is where this matters: without
it, `ctrl-x` on `pinax` would silently kill `pinax-ai`.

**A utility session must not be named after a project.** The music session is
`music`, not `gmuse`, because `~/dev/gmuse` is a project and `dev` names
sessions after directories — so `-s gmuse` attached the *editing* session and
hid the real one from the picker. Any utility session added here has the same
trap: check the name against `ls ~/dev` first.

**A popup inherits `$TMUX`.** tmux refuses a nested attach, so the music popup
clears it for the one command (`TMUX= tmux new-session -A -s music`). Without
that the attach silently does not take.

## See also

- [Music](music.md) — the gmuse popup this shares its shape with
- [Floats](floats.md) — the nvim-side equivalent of a popup over your work
