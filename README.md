# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io), for a macOS laptop
and a Linux machine from one tree.

A terminal-first setup: tmux holds the sessions, neovim is the editor, and the
pieces know about each other — the session switcher, the music player and the
Claude status counts are all one prefix key away from wherever you are.

## What's configured

| Tool         | Config                             | Purpose                                                                   |
| ------------ | ---------------------------------- | ------------------------------------------------------------------------- |
| **zsh**      | `dot_zshrc`                        | completions, fzf-tab, zoxide, atuin, direnv, vi mode                      |
| **starship** | `dot_config/private_starship.toml` | prompt: vi mode indicators, custom `uv_python` module                     |
| **tmux**     | `dot_tmux.conf`                    | Ctrl-A prefix, vi keys, catppuccin frappe inline, popups                  |
| **neovim**   | `dot_config/nvim/`                 | lazy.nvim, LSP, DAP, treesitter — 30 plugin files, 12 local modules       |
| **cmus**     | `dot_config/private_cmus/rc`       | frappe colours, in the one file cmus never overwrites                     |
| **kitty**    | `dot_config/kitty/`                | six settings, plus a vendored catppuccin theme pinned to its upstream sha |
| **scripts**  | `bin/`                             | session switcher, session layout, Claude state, codelldb wrapper          |

## The bits worth knowing about

**Popups reachable from any session.** `prefix + Ctrl-J` opens an fzf session
switcher; `prefix + Ctrl-P` opens cmus in a float and closes it again, so there
is no "music window" to navigate back to. Both are overlays over whatever you
were doing.

**Claude activity in the status bar.** `⣿ 2 ⣤ 1 ⣀ 3` — how many Claude sessions
are working, waiting on you, and idle. Fed by Claude Code hooks writing state
files, counted per live tmux session. The session switcher marks the same states
inline, and sorts active sessions first when you type.

**Guides, in the editor.** `<leader>?` opens a picker of hand-written reference
cards — navigation, git, files, pickers, the command line, the keymap
conventions themselves, and the music setup. They live with the config so they
go stale in the same commit that changes the thing they describe, and they link
to each other.

**Notes in three tiers.** Scratch notebooks (`<leader>n`) for today's working
log, [zk](https://github.com/zk-org/zk) (`<leader>z`) for the linked second
brain, and the guides above for reference you reread.

**Review, not just diff.** codediff renders changes the way a merge request
does; `<leader>gm` reviews the branch against its base, `<leader>gv` the working
tree.

## New machine

```bash
brew install chezmoi
chezmoi init git@gitlab.com:gabrielgellner/dotfiles.git
chezmoi apply

cd ~/.local/share/chezmoi && ./bootstrap.sh
```

`bootstrap.sh` installs brew packages, uv Python tools, rustup components,
codelldb and the yazi flavors, skipping anything already present. It ends with a
verification pass that reports what is still missing — which exists because
tmux, zk, pyrefly and just-lsp had all drifted out of it while remaining hard
dependencies, invisibly, since a bootstrap runs once per machine.

## Working on them

Edit in the source directory (`~/.local/share/chezmoi`), then:

```bash
just diff     # preview what will change in ~
just apply    # apply to the home directory
just update   # pull from the remote, then apply
```

Naming conventions: `dot_*` → `~/.*`, `executable_*` gets the execute bit,
`private_*` gets `chmod 600`, `.tmpl` is a Go template. `.chezmoiignore` is a
template too, which is how one tree serves both machines.

Two tracked files have a second writer — `~/.claude/settings.json` and
`karabiner.json`. Both apps rewrite their own config, so a change made inside
one is reverted by the next `chezmoi apply` unless you `chezmoi re-add` it
first. cmus has the same hazard and dodges it instead: the file it rewrites is
untracked, and the colours live in `rc`, which it only ever reads. `CLAUDE.md`
has the reasoning for all three.

## Conventions

Commits are [conventional commits](https://www.conventionalcommits.org);
`CHANGELOG.md` is generated from them with [git-cliff](https://git-cliff.org).

```bash
just changelog-preview    # what is unreleased
just next-version         # what the next tag would be
just release              # tag it — refuses on a dirty tree or an existing tag
```

Comments in this repo record what was _measured_, not what was assumed. An audit
through 2026-08 exercised every plugin file and every local module by driving
them in a scratch tmux session rather than reading them, and the notes it left
behind — including the recurring ways config here has silently done nothing —
are in `CLAUDE.md`.
