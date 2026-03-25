# Changelog

All notable changes to this dotfiles repository are documented here.
## [v0.2.0] — 2026-03-25

### Bug Fixes

- Use correct neogen annotation convention name for google docstrings


### Features

- Add ctrl-x to kill tmux session and colored pane preview


## [v0.1.1] — 2026-03-25

### Bug Fixes

- Switch dev and new-session scripts to zsh — - Change shebang from bash to zsh for consistency with the user's shell
- Use zsh native typeset -A for EXTRA_PROJECTS associative array
- Add dotfiles (~/.local/share/chezmoi) as an extra project entry
- Inline EXTRA_PROJECTS lookup in preview() to avoid subshell scoping issues
- Rename local `status` to `git_status` to avoid zsh readonly variable conflict


### Chores

- V0.1.1


## [v0.1.0] — 2026-03-25

### Bug Fixes

- Auto-bump version in justfile using git-cliff — Use git-cliff --bumped-version to derive the next semver tag automatically.
Falls back to v0.1.0 on first release (no prior tags). Manual override
still available via: just release v1.2.3

- Add missing accept to completions.

- Make tmux use proper titles instead of hostname.


### Chores

- V0.1.0

- Add MIT license

- Clean up some cruft in the nvim config.

- Clean up nvim to remove lazyvim merged mistakes, and some permissions.

- Initial dotfiles


### Features

- Add README, CHANGELOG, justfile, and git-cliff config — - README covers what is configured, new machine setup, and dotfiles workflow
- cliff.toml configures git-cliff for conventional commit changelogs
- justfile provides chezmoi (diff/apply/update) and release (changelog/release) recipes
- bootstrap.sh now installs just and git-cliff

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



