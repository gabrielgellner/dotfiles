# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A [chezmoi](https://chezmoi.io) dotfiles repository managing shell, editor, and terminal multiplexer configuration for a single-user developer environment.

## Chezmoi Naming Conventions

- `dot_*` → `~/.*` (e.g., `dot_zshrc` → `~/.zshrc`)
- `executable_*` → files with execute bit set (scripts in `bin/`)
- `private_*` → prefix means chmod 600 on apply (e.g., `dot_config/private_starship.toml`)
- `dot_config/` → `~/.config/`
- Run `chezmoi diff` to preview changes
- `.tmpl` suffix = Go template (use `{{ .chezmoi.os }}`, etc.)
- `.chezmoiignore` and `.chezmoi.toml.tmpl` are **always** evaluated as templates — `.chezmoiignore` needs no `.tmpl` suffix

## Applying Changes

```bash
chezmoi apply          # apply all changes to home directory
chezmoi diff           # preview changes before applying
chezmoi apply -v       # verbose output
```

To test changes without applying:

```bash
chezmoi diff --no-pager
```

Common tasks are wrapped in the `justfile` — `just diff`, `just apply`, `just update`,
`just changelog`, `just next-version`, `just release`. Run `just` for the list.
`just release` refuses to run on a dirty tree or an existing tag; the changelog
recipe carries a note about commits git-cliff silently drops.

## Per-Machine Configuration

The same repo serves a macOS laptop and a Linux machine. Two mechanisms:

- **`.chezmoiignore`** is a template, so a path can be skipped per machine.
  `.config/i3` and `.config/i3status` apply on Linux only, and
  `bin/mkv2mp4` and `.config/karabiner` on macOS only. Paths there are
  *target* names (`.config/i3`), not source names (`dot_config/i3`).
- **`.chezmoi.toml.tmpl`** defines a `role`, asked once per machine by
  `chezmoi init` and stored in the generated (untracked)
  `~/.config/chezmoi/chezmoi.toml`. For distinctions `.chezmoi.os` cannot
  express. Guard uses of it: `{{ if eq (.role | default "personal") "work" }}`.

Machine-local secrets stay out of the repo entirely — `dot_gitconfig` includes
`~/.gitconfig.local`, which is not tracked. The global ignore file
(`dot_config/git/ignore`) *is* tracked, since its rules should hold on both
machines; git finds it at the XDG default, with `core.excludesfile` unset.

## Key Files and Their Roles

| File                               | Destination               | Purpose                                                       |
| ---------------------------------- | ------------------------- | ------------------------------------------------------------- |
| `dot_zshenv`                       | `~/.zshenv`               | PATH for non-interactive zsh; read before `.zshrc`            |
| `dot_zshrc`                        | `~/.zshrc`                | Zsh config: completions, fzf, zoxide, starship, aliases       |
| `dot_tmux.conf`                    | `~/.tmux.conf`            | Tmux: Ctrl-A prefix, vi keys, catppuccin frappe               |
| `bin/executable_dev`               | `~/bin/dev`               | fzf-based tmux session/project switcher                       |
| `bin/executable_new-session`       | `~/bin/new-session`       | Creates tmux sessions with nvim + console windows             |
| `bin/executable_claude-window`     | `~/bin/claude-window`     | Jump to or create a `claude` window (tmux prefix + C)         |
| `bin/executable_mkv2mp4`           | `~/bin/mkv2mp4`           | Video remux helper                                            |
| `dot_config/private_starship.toml` | `~/.config/starship.toml` | Starship prompt: vi mode indicators, custom uv_python module  |
| `dot_config/private_karabiner/`    | `~/.config/karabiner/`    | macOS modifier remaps — see the caveat below                  |
| `dot_config/nvim/`                 | `~/.config/nvim/`         | Neovim config (lazy.nvim, Lua)                                |
| `dot_config/kitty/kitty.conf`      | `~/.config/kitty/kitty.conf` | Kitty: 8 active settings; the rest is commented reference  |
| `dot_claude/settings.json`         | `~/.claude/settings.json` | Claude Code settings — see the caveat below                   |
| `dot_claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | Statusline renderer invoked by that settings file     |
| `bootstrap.sh`                     | —                         | Installs the toolchain on a fresh machine; not applied        |

`~/.claude/settings.json` has two writers. Claude Code rewrites it whenever a
setting changes from inside the tool — model, theme, effort level, enabled
plugins — while chezmoi holds its own copy. Whichever wrote last wins, so a
change made in the tool is reverted by the next `chezmoi apply`. Capture such a
change with `chezmoi re-add ~/.claude/settings.json` before applying.

`~/.config/karabiner/karabiner.json` has the same shape of problem: Karabiner
rewrites it whenever a setting changes in its GUI, so re-add before applying
after touching the app. It holds three simple modifications — `caps_lock` and
`right_command` both to control, `right_option` to command — which is what
makes control and command each reachable from either hand. It is tracked
because nothing else here can express it: `dot_config/kitty/kitty.conf` tried
the same remap and kitty rejected it as an unknown key.

Colour themes are pinned, not fetched. `dot_config/kitty/` carries one vendored
catppuccin theme file with its upstream commit in the header. tmux's catppuccin
comes from tpm and is not tracked at all — `~/.tmux/plugins` is ignored
outright, since chezmoi managing it would revert every tpm update.

yazi sits between the two. `dot_config/yazi/package.toml` **is** tracked: it
names the flavor and the commit it is pinned to, so `ya pkg install` reproduces
the tree, which is the relationship `lazy-lock.json` has with lazy.nvim. The
fetched content under `.config/yazi/flavors` is ignored. To move the pin,
`ya pkg upgrade` and then `chezmoi re-add ~/.config/yazi/package.toml`, the same
two steps as `:Lazy update` followed by committing the lockfile.

## Neovim Configuration Architecture

Lazy.nvim-based setup with modules under `dot_config/nvim/lua/`:

- `config/` — loaded unconditionally. Beyond `options`, `keymaps` and `autocmds`
  this holds standalone features: `files` (oil ↔ explorer handoff), `folds`
  (LSP/treesitter fold dispatch), `guides` (the `<leader>?` picker), `just`
  (run recipes into a tmux console window), `scratch`, `markdown_checkbox`,
  `markdown_outline`, `rules_lookup`.
- `plugins/` — one file per plugin or plugin group, lazy-loaded.
- `guides/` — hand-written markdown reference cards, opened with `<leader>?`.
  Covers navigation, git, files, surround, the command line, and the keymap
  conventions themselves. `gf` or `<CR>` follows a link between them.

Plugin categories: LSP + completion (blink.cmp), DAP debugging, treesitter,
formatting/linting, UI (noice, snacks, mini), navigation (flash, spider, oil),
git (gitsigns, codediff), tmux integration (vim-tmux-navigator), Rust, Haskell,
Scheme (conjure, paredit).

## Keymap Conventions

`dot_config/nvim/guides/keymaps.md` records the rules this config follows and
the faults each one prevents — read it before adding a mapping. In short: a
capital means a *wider* scope and never an unrelated action; a doubled key is
the ordinary case; buffer-local mappings silently beat global ones, which is the
most common way a keymap appears to do nothing; and `mode = "x"`, never `"v"`,
because `"v"` includes select mode.

## Toolchain

Installed by `bootstrap.sh`, which skips anything already present. Core:
`tmux`, `nvim`, `fzf`, `fd`, `ripgrep` (`rg`), `eza`, `bat`, `yazi`, `zoxide`,
`atuin`, `starship`, `direnv`, `lazygit`, `zk`, `just`, `git-cliff`,
`tree-sitter`, `uv` (Python).

Language servers: `lua-language-server`, `pyrefly`, `ruff`, `just-lsp`.
`basedpyright` is installed but deliberately *not* enabled in nvim — it is the
CI/`just` checker, while pyrefly does the editor work.

## Starship Custom Module

`dot_config/private_starship.toml` defines a custom `uv_python` module that
shows the contents of `.python-version` when both it and `uv.lock` are present.
It reads the file rather than running `.venv/bin/python` because this evaluates
on every prompt; the tradeoff is noted in the config. The vi mode uses `❯`/`❮`
symbols with color coding (green=normal, red=error, yellow=visual, purple=replace).
