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
- `.tmpl` suffix = Go template (us {{ .chezmoi.os }}, etc.)

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

## Key Files and Their Roles

| File                               | Destination               | Purpose                                                      |
| ---------------------------------- | ------------------------- | ------------------------------------------------------------ |
| `dot_zshrc`                        | `~/.zshrc`                | Zsh config: completions, fzf, zoxide, starship, aliases      |
| `dot_tmux.conf`                    | `~/.tmux.conf`            | Tmux: Ctrl-A prefix, vi keys, catppuccin theme               |
| `bin/executable_dev`               | `~/bin/dev`               | fzf-based tmux session/project switcher                      |
| `bin/executable_new-session`       | `~/bin/new-session`       | Creates tmux sessions with nvim + console windows            |
| `dot_config/private_starship.toml` | `~/.config/starship.toml` | Starship prompt: vi mode indicators, custom uv_python module |
| `dot_config/nvim/`                 | `~/.config/nvim/`         | Neovim config (lazy.nvim, Lua)                               |

## Neovim Configuration Architecture

Lazy.nvim-based setup with modules under `dot_config/nvim/lua/`:

- `config/` — options, keymaps, autocmds (loaded unconditionally)
- `plugins/` — one file per plugin or plugin group, lazy-loaded

Plugin categories: LSP + completion, DAP debugging, treesitter, formatting/linting, UI (noice, snacks, mini), navigation (flash, spider, oil), git (gitsigns), Rust-specific.

## Toolchain

The config assumes these tools are installed: `fzf`, `fd`, `eza`, `bat`, `zoxide`, `starship`, `tmux`, `nvim`, `uv` (Python).

## Starship Custom Module

`dot_config/private_starship.toml` defines a custom `uv_python` module that shows the Python version from `pyproject.toml` when in a uv project. The vi mode uses `❯`/`❮` symbols with color coding (green=normal, red=error, yellow=visual, purple=replace).
