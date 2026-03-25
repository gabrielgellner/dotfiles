# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io).

## What's configured

| Tool         | Config                             | Purpose                                                                |
| ------------ | ---------------------------------- | ---------------------------------------------------------------------- |
| **zsh**      | `dot_zshrc`                        | Shell: completions, fzf, zoxide, vi mode, aliases                      |
| **starship** | `dot_config/private_starship.toml` | Prompt: vi mode indicators, custom uv/Python module                    |
| **tmux**     | `dot_tmux.conf`                    | Terminal multiplexer: Ctrl-A prefix, vi keys, catppuccin theme         |
| **neovim**   | `dot_config/nvim/`                 | Editor: lazy.nvim, LSP (basedpyright + ruff + lua_ls), DAP, treesitter |
| **scripts**  | `bin/`                             | `dev` — fzf tmux session switcher; `new-session` — session layout      |

## New machine setup

### 1. Install chezmoi and apply dotfiles

```bash
brew install chezmoi
chezmoi init git@gitlab.com:gabrielgellner/dotfiles.git
chezmoi apply
```

### 2. Install all required tools

```bash
cd ~/.local/share/chezmoi
./bootstrap.sh
```

This installs brew packages, uv Python tools (basedpyright, ruff, debugpy), rustup, and tpm. Safe to re-run.

### 3. Finish tmux plugin install

Start tmux, then press `Ctrl-A + I` to install plugins via tpm.

### 4. Generate chezmoi completions (once)

```bash
chezmoi completion zsh > "$(brew --prefix)/share/zsh/site-functions/_chezmoi"
```

## Working on the dotfiles

Edit files directly in the chezmoi source directory (`~/.local/share/chezmoi`), then apply:

```bash
just diff     # preview what will change in ~
just apply    # apply changes to home directory
just update   # pull from remote + apply
```

The chezmoi file naming conventions:

- `dot_*` → `~/.*`
- `executable_*` → file gets execute bit on apply
- `private_*` → file gets `chmod 600` on apply
- `dot_config/` → `~/.config/`

## Releases and changelog

This project uses [git-cliff](https://git-cliff.org) to maintain `CHANGELOG.md` from [conventional commits](https://www.conventionalcommits.org).

```bash
just changelog-preview    # see what's unreleased
just release v1.2.3       # update changelog, tag, and push
```
