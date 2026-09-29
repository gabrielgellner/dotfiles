# Shell

zsh, in vi mode, with a handful of tools replacing the coreutils defaults.
History and completion are their own card — see
[Shell history and completion](shell-history.md) for atuin, fzf-tab and ghost
text. This one is everything else.

## Two files, and which one runs

| File       | Read by                          | Holds                      |
| ---------- | -------------------------------- | -------------------------- |
| `.zshenv`  | **every** zsh, before `.zshrc`   | `PATH` and a few env vars  |
| `.zshrc`   | interactive shells only          | everything else            |

The split matters more than it looks. `.zshrc` returns immediately for a
non-interactive shell, so a script with `#!/usr/bin/env zsh`, a `zsh -c`, or
anything a tool spawns sees **only** `.zshenv`. That is why `PATH` is set in
both: `~/.local/bin`, `~/.cargo/bin`, `~/bin`, in that order.

`~/bin` was once missing from the `.zshenv` copy, and everything still worked —
because tmux is started from an interactive shell and hands its environment to
the popup. The fault only surfaces where that chain does not begin
interactively, at which point `dev` cannot find `new-session`.

## Vi mode

`bindkey -v`, with `KEYTIMEOUT=10` so `Esc` is not followed by a pause.

| Key    | Mode   | Does                            |
| ------ | ------ | ------------------------------- |
| `^P` `^N` | insert | history search backward / forward |
| `^Y`   | insert | accept the ghost suggestion     |
| `k`    | normal | up a line                       |
| `/`    | normal | search history                  |

**`k` and `/` are given back deliberately.** atuin binds both in normal mode —
`k` to its search UI unconditionally, `/` likewise — which leaves vi normal mode
unable to move up a line or start a search. That is broken vi rather than a
different history tool, and `^R` and `Up` already reach atuin from insert mode,
where the feature actually lives. Delete those two `bindkey -M vicmd` lines to
get atuin's stock behaviour back.

The prompt shows which mode you are in, from
`dot_config/private_starship.toml`:

| Symbol | Means                  |
| ------ | ---------------------- |
| `❯` green | insert, last command ok |
| `❯` red   | insert, last command failed |
| `❮` green | normal                 |
| `❮` yellow | visual                |
| `❮` mauve | replace                |

So the arrow points *into* the line when you can type into it and back out of it
when you cannot. The prompt also carries a custom `uv_python` module showing
`.python-version` when both it and `uv.lock` are present — it reads the file
rather than running `.venv/bin/python`, because this evaluates on every prompt.

## Getting around

| Command | Does                                          |
| ------- | --------------------------------------------- |
| `z <bit of a path>` | jump there (zoxide, by frecency)  |
| `zi`    | pick interactively                            |
| `y`     | browse in yazi, and **the shell follows**     |
| `br`    | broot                                         |

**`z` and `y` are the same verb split two ways**: `z` jumps when you know where
you are going, `y` browses when you do not.

`y` is `yazi` with the shell following it out — `q` writes the directory you
ended in and the wrapper `cd`s there, while `Q` quits without writing so the
shell stays put. That distinction is the whole reason to use the wrapper; see
[Yazi](yazi.md).

Note it is **not** `ya`, which is yazi's own package manager. And `broot`'s `br`
is the same trick one tool over: a subshell cannot change your directory, so
broot writes the command it wants run to a file and the function evals it.

## Aliases and environment

```
ls   eza --group-directories-first --icons=auto
ll   eza -lh --git
la   eza -lha
```

`ll` carries git status per file, which is the reason it is the one worth
typing. `EDITOR` and `VISUAL` are both `nvim`; `ZK_NOTEBOOK_DIR` is `~/notes`,
which is what lets `zk` commands run from anywhere — see [Notes](notes.md).

`direnv` is hooked, so a directory with an `.envrc` loads its environment on
entry and unloads it on leave.

`stty -ixon`, so `^S` does not freeze the terminal. It is flow control from
serial terminals and there is nothing here that wants it.

## Load order is the whole design

Most of `.zshrc` is not settings, it is a **sequence**, and several steps only
work where they are. Moving one breaks something quietly:

1. **brew shellenv**, then `fpath`
2. **compinit** — with a 24-hour cache
3. **fzf**, which binds `^I` and `^R`
4. **fzf-tab**, which must be the *last* thing to bind `^I` and must load before
   anything that wraps widgets
5. **zsh-autosuggestions**, which wraps widgets and sets the strategy
6. **starship**, guarded to once per process
7. **zoxide**, then `bindkey -v`
8. **atuin**, which must come after fzf (to take `^R`), after autosuggestions
   (it *prepends* to the strategy, so sourced first it drops the history
   fallback), and after `bindkey -v` (so it binds into the keymaps in use)
9. **zsh-syntax-highlighting**, last

That is why fzf-tab is wedged between two neighbours that both constrain it, and
why atuin sits so far down. Neither position is arbitrary and neither fails
loudly if moved.

## Things that bit

**`source ~/.zshrc` three times in one shell used to break `Esc`.** Starship's
init wraps any existing `zle-keymap-select` widget to redraw on a mode change.
Sourced a third time, that wrapping eats itself and every `Esc` reports
`maximum nested function level reached`. The init is guarded to once per
*process* — deliberately not exported, since a nested shell is a new process and
must initialise starship itself.

**`command yazi` inside the wrapper is load-bearing.** It bypasses both the
alias and the function, so the recursion terminates. Without it the safety
becomes order-dependent: with the alias written below the function it happens to
work, and moving the alias above kills it with the same nested-function error.
Measured both ways.

**Plugins are sourced unguarded, on purpose.** The guarded form failed
*silently* — a missing plugin meant no autosuggestions and no explanation. The
tool evals already fail loudly, so this matches them.

**`fpath` gets deduped before it is assigned.** Two things add brew's
site-functions, and `brew shellenv` *exports* `FPATH`, so a shell started from
another inherits the entry and both writers add it again. Every tmux pane is
such a shell. compinit walks every copy.

## See also

- [Shell history and completion](shell-history.md) — atuin, fzf-tab, ghost text
- [Tmux](tmux.md) — the sessions these shells run inside
- [Yazi](yazi.md) — what `y` opens, and the `q`/`Q` choice
