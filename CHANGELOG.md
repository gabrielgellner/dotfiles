# Changelog

All notable changes to this dotfiles repository are documented here.
## [Unreleased]

### Bug Fixes

- Add missing accept to completions.

- Make tmux use proper titles instead of hostname.


### Chores

- Clean up some cruft in the nvim config.

- Clean up nvim to remove lazyvim merged mistakes, and some permissions.

- Initial dotfiles


### Features

- Add bootstrap script for tool installation — Idempotent script that installs all tools assumed by the dotfiles:
brew packages (shell, prompt, file tools, editor, formatters, linters,
lazygit), uv tools (basedpyright, ruff, debugpy), rustup with
rust-analyzer, and tpm. Safe to re-run, skips already-installed tools.

- Improve zsh and starship config — - Remove redundant INC_APPEND_HISTORY (implied by SHARE_HISTORY)
- Add HIST_IGNORE_SPACE to keep secrets out of history
- Raise KEYTIMEOUT from 1 to 10 for more comfortable vi mode
- Add FZF_DEFAULT_OPTS with height/layout/border defaults
- Replace redundant ZLE vi mode hooks with zsh-syntax-highlighting source
- Scope uv_python starship module to uv.lock projects only
- Replace slow `uv run python --version` fallback with rg pyproject.toml parse
- Remove dead commented-out starship block
- Fix vimcmd replace symbols from bare `purple` to catppuccin mauve (#cba6f7)

- Have dev script be fullscreen with better layout and preview.

- Get rid of the sesh dependency for dev script.

- Fixup starship prompt to be more efficient.

- Cleanup zshrc, fix autocompletion to actually work.

- Add completion shortcuts to zsh for history.

- Add sesh for tmux management

- Cleanup zshrc

- Get vi mode in zshrc/starship and fix binding in tmux



