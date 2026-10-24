# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io), for a macOS laptop
and a Linux machine from one tree.

A terminal-first setup: tmux holds the sessions, neovim is the editor, NeoMutt
reads the mail, and the pieces know about each other — the session switcher,
the music player and the Claude status counts are all one prefix key away from
wherever you are, and the reference cards for all of it open inside the editor.

## What's configured

| Area         | Tool                    | Config                                | Purpose                                                       |
| ------------ | ----------------------- | ------------------------------------- | ------------------------------------------------------------- |
| **Shell**    | zsh                     | `dot_zshrc`, `dot_zshenv`             | completions, fzf-tab, zoxide, atuin, direnv, vi mode          |
|              | starship                | `dot_config/private_starship.toml`    | prompt: vi mode indicators, a custom `uv_python` module       |
| **Terminal** | tmux                    | `dot_tmux.conf`                       | Ctrl-A prefix, vi keys, Catppuccin Frappé inline, popups      |
|              | kitty                   | `dot_config/kitty/`                   | five settings, a pinned theme, font size per machine          |
| **Editor**   | neovim                  | `dot_config/nvim/`                    | lazy.nvim, LSP, DAP, treesitter — 31 plugin files, 14 modules |
| **Mail**     | NeoMutt                 | `dot_config/neomutt/`                 | the client, over a local copy of Proton Mail                  |
|              | mbsync, notmuch         | `dot_config/isyncrc.tmpl`, `notmuch/` | the sync and the search index                                 |
|              | himalaya                | `dot_config/himalaya/`                | scripted mail access, for the shell and for Claude            |
| **Files**    | yazi                    | `dot_config/yazi/`                    | file manager: pinned plugins, vim counts, a keymap audit      |
| **System**   | btop, bat, git          | `dot_config/{btop,bat,git}/`          | monitor, pager, global git ignore                             |
|              | karabiner               | `dot_config/private_karabiner/`       | macOS modifier remaps                                         |
| **Music**    | gmuse                   | `dot_config/gmuse/config.toml`        | the music player, in a tmux popup                             |
| **Claude**   | Claude Code             | `dot_claude/`                         | settings, permission rules, hooks, the status line            |
| **Linux**    | xterm, i3, i3status     | `dot_config/{xterm,i3,i3status}/`     | the desktop the Linux machine serves over RDP                 |
| **Scripts**  | 10 tools                | `bin/`                                | session switcher and layout, Claude state, mail tools, …      |

## The bits worth knowing about

**Popups reachable from any session.** `prefix + Ctrl-J` opens an fzf session
switcher; `prefix + Ctrl-P` opens gmuse in a float and closes it again, so there
is no "music window" to navigate back to. Both are overlays over whatever you
were doing.

**Claude activity in the status bar.** `⣿ 2 ⣤ 1 ⣀ 3` — how many Claude sessions
are working, waiting on you, and idle. Fed by Claude Code hooks writing state
files, counted per live Claude process. The session switcher marks the same
states inline, and sorts active sessions first when you type.

**Mail in the terminal, without a mail server.** Proton Mail Bridge serves IMAP
on localhost; mbsync mirrors it into a local maildir every two minutes from a
launchd agent; NeoMutt reads that, sorted and threaded, and notmuch searches
every folder at once — a Gmail archive back to 2009 included — so a thread
includes your own replies. Proton's labels get
their own keys (`+` adds one, `-` takes one off), and the keys that archive,
delete and label were each checked against what Proton actually does with them
— a plain delete in the wrong folder there leaves a message in no folder at
all. himalaya gives
Claude live access to the same account, behind permission rules that always ask
before anything is sent or deleted. The maildir is backed up nightly to a NAS
with restic, encrypted before it leaves the laptop. The address and every
secret stay out of the repo: the address is per-machine chezmoi data, the
passwords live in the macOS keychain.

**Guides, in the editor.** `<leader>?` opens a picker over 25 hand-written
reference cards — navigation, git, files, pickers, LSP, debugging, tmux, mail,
the keymap conventions themselves, and more. They live with the config so they
go stale in the same commit that changes the thing they describe, and they link
to each other.

**Notes in three tiers.** Scratch notebooks (`<leader>n`) for today's working
log, [zk](https://github.com/zk-org/zk) (`<leader>z`) for the linked second
brain — kept in its own private repository, since this one is public — and the
guides above for reference you reread.

**Review, not just diff.** codediff renders changes the way a merge request
does; `<leader>gm` reviews the branch against its base, `<leader>gv` the working
tree. octo.nvim brings GitHub issues and PRs into the editor.

**One tree, two machines.** `.chezmoiignore` is a template, so the i3 desktop
and xterm apply on Linux only and the mail stack, karabiner and the media tools
on macOS only. The Linux machine is driven over RDP, which is why it runs xterm
rather than kitty: with no GPU, kitty redrew its whole window for a one-cell
change, measured at a hundred times the damage.

## New machine

```bash
brew install chezmoi
chezmoi init https://github.com/gabrielgellner/dotfiles.git
chezmoi apply

cd ~/.local/share/chezmoi && ./bootstrap.sh
```

`bootstrap.sh` installs brew packages, uv Python tools, rustup components,
codelldb and the yazi flavor and plugins, skipping anything already present, and on macOS
the mail stack. It ends with a verification pass that reports what is still
missing — which exists because tools had drifted out of it while remaining hard
dependencies, invisibly, since a bootstrap runs once per machine. A failed
install is reported at the end rather than stopping the run.

Two steps no script can do: signing in to Proton Mail Bridge, and putting its
password in the keychain. `chezmoi init` asks for the mail address once per
machine; leaving it empty leaves mail switched off there.

## Working on them

Edit in the source directory (`~/.local/share/chezmoi`), then:

```bash
just diff     # preview what will change in ~
just apply    # apply to the home directory
just update   # pull from the remote, then apply
```

Naming conventions: `dot_*` → `~/.*`, `executable_*` gets the execute bit,
`private_*` gets `chmod 600`, `.tmpl` is a Go template. `run_onchange_*`
scripts reload the launchd agents when their definitions change.

Some tracked files have a second writer — `~/.claude/settings.json`,
`karabiner.json` and `btop.conf` are all rewritten by their own apps, so a
change made inside one is reverted by the next `chezmoi apply` unless you
`chezmoi re-add` it first. gmuse avoids the hazard by construction: it never
writes its own config, keeping state in `$XDG_STATE_HOME` instead. `CLAUDE.md`
has the reasoning for all of them.

## Conventions

Commits are [conventional commits](https://www.conventionalcommits.org);
`CHANGELOG.md` is generated from them with [git-cliff](https://git-cliff.org).

```bash
just changelog-preview    # what is unreleased
just next-version         # what the next tag would be
just release              # tag it — refuses on a dirty tree or an existing tag
```

`main` and the release tags are protected on GitHub: a published release is
final, and a mistake is fixed by cutting the next one.

Comments in this repo record what was _measured_, not what was assumed — config
here is checked by driving it in a scratch tmux session rather than by reading
it. The notes that leaves behind, including the recurring ways config has
silently done nothing, are in `CLAUDE.md`.
