# Changelog

All notable changes to this dotfiles repository are documented here.
## [Unreleased]

### Features

- Search hazards, gm-core and player-core for rules lookups

- Frappe everywhere, and scrollback the console windows can use

- Make i3 Linux-only, and add a per-machine role

- Incremental selection on Helix's keys, keeping mini.ai whole

- Cross-link the guides, and make the links followable

- Name haskell-tools' leader prefixes

- Auto-show the cmdline completion menu, and document the prompt

- Use LSP folds where a server offers them, treesitter elsewhere

- Bind ZkInsertLink, the other half of linking

- Relative numbers in the explorer, and an oil handoff both ways

- Replace diffview with codediff, reviewing in a unified view

- Make case mean scope in <leader>c and <leader>f, add 8 pickers

- Separate viewport from cursor movement when reading

- Run just recipes in the tmux console window

- Add just-lsp and just --fmt support

- Add markdown task list checkboxes

- Make <C-\> a single-key terminal escape

- Add a Lua scratchpad and debug globals

- Make <C-/> toggle the Claude float from anywhere

- Send notifications to Claude from the picker

- Run Claude as a full-screen float

- Start sessions in auto permission mode

- Add lazydev.nvim for plugin type definitions

- Add prefix+C binding for a Claude window

- Add claudecode.nvim IDE integration under <leader>a

- Resolve pyrefly venv from LSP root + add <leader>lr restart

- Switch nvim python lsp from basedpyright to pyrefly

- Add mkv2mp4 remux script

- Auto-reindex notebook on note open + <leader>zi

- Add zk notebooks with per-session notebook resolution

- Set 2-space indent defaults for Haskell buffers

- Add Haskell support via haskell-tools.nvim

- Add Scheme/Racket support with REPL and structural editing

- Add claude code settings and statusline command

- Add markdown soft wrap with gq reflow to 80

- Add ~/.local/bin to PATH for uv tools

- Add gitconfig with per-remote identity, bump bootstrap with git

- Add i3, yazi, xfce4-terminal, and linux/xrdp setup

- Add tree-sitter-cli to bootstrap script

- Add ~/bin to PATH in zshrc

- Update bootstrap to install nerdfonts

- Add kitty to chezmoi

- Add markdown preview with render-markdown and markdown-preview.nvim

- Add base64 encode/decode keymaps to neovim

- Add bat with Catppuccin Mocha theme

- Set nvim as default editor and auto-regenerate just completions

- Add second console window to new-session script

- Improve diffview and tmux session switching

- Add diffview.nvim and fix just zsh completions

- Replace prettier with biome for JS/TS/JSON, add more formatters

- Add JS/TS/Rust formatters and increase prettier timeout


### Bug Fixes

- Dedupe fpath, as path already is

- Reparse rules caches when the files change

- Make rules lookup reach accented names

- Group the indent autocmd so re-sourcing stops stacking it

- Don't raise a stack trace toggling a checkbox in a read-only buffer

- Keep the doc line last, so `just --list` reads right

- Statusline separator, and guards on `just release`

- Install the tools the config actually needs

- Don't rebuild a session that already exists

- Target tmux sessions exactly, not by prefix

- Leave terminal mode with <C-x>, not the shell's quit character

- Stop vim-tmux-navigator binding C-\

- Make <CR> follow a guide link instead of raising an error

- Stop the guide tables overflowing the float

- Use "x" not "v" for visual maps, and name conjure's prefixes

- Drop the visual `p` remap, which vim's `P` already does

- Guard the explorer path before handing it to oil

- Make a capital mean a wider scope, and finish the tmux pair

- Move the splits under <leader>w, where the window keys are

- Resolve the diff base per repo instead of assuming main

- Put the common docstring on cc, scope cx to Lua buffers

- Stop advertising unusable fold keys, track the spell word list

- Drop the arglist's [a/]a globals as well

- Drop the arglist's [A/]A, which were all that still worked

- Unshadow [d/]d and [l/]l, make buffer motions operator-ready

- Give the duplicated keymap descriptions distinct labels

- Unshadow <leader>cf and <leader>gb, drop dead <leader>xq

- Stop <leader>w saving so it can be the window prefix

- Name the which-key groups that showed as "+N keymaps"

- Give [i/]i back to mini.indentscope

- Clear the remaining lua_ls diagnostics

- Let lazydev own lua_ls's workspace.library

- Make the Claude float toggle reliably

- Focus Claude after sending a selection

- Stop the Claude split jumping to its prompt on focus

- Make lua_ls resolve globals in the chezmoi source tree

- Keep the markdown heading level an integer

- Hard-wrap markdown prose on save, stop soft-wrapping tables

- Sync copy to both clipboard and primary selection

- Disable snacks smooth scrolling

- Pin eza --icons=auto in ls alias

- Drop i3status wireless module and exclude homebrew-taps from deploy

- Switch i3 terminal to kitty and disable tmux extended keys

- Add missing tool dependencies to bootstrap script

- Remove zz from C-d/C-u to fix conflict with snacks.scroll


### Refactoring

- Stop tracking tpm's plugin directory

- Vendor the one theme file instead of the whole repo

- Drop the uv_python fallback that could report a floor

- Drop two redundant options, one fork, and the silent guards

- Always show the guides picker, even for one guide

- Hand the quickfix motions to mini.bracketed too

- Move LSP navigation into Neovim's gr* namespace


### Documentation

- Name the language servers nvim actually enables

- Describe the rendering that is actually configured

- Bring CLAUDE.md back in line with the repo

- Record why the changelog has a gap

- Write down the keymap conventions the audit settled on

- Add git and surround guides


### Chores

- Delete the unused local homebrew tap

- Retire the hand-generated zsh completion workflow

- Drop the sesh and xfce4 config

- Track auto mode configuration

- Update plugin lockfile

- Disable git autoCommit and autoPush

- Bump lazy-lock

- Enable git autoCommit + autoPush

- Ignore work-specific gitconfig and remove per-remote includeIf

- Stash gellgab/local just 1.51.0 formula

- Track regenerate-completions in bin/ and sync claude settings

- Add .chezmoiignore to keep repo files out of home directory


## [v0.2.0] — 2026-03-25

### Features

- Add ctrl-x to kill tmux session and colored pane preview


### Bug Fixes

- Use correct neogen annotation convention name for google docstrings


### Chores

- V0.2.0


## [v0.1.1] — 2026-03-25

### Bug Fixes

- Switch dev and new-session scripts to zsh


### Chores

- V0.1.1


## [v0.1.0] — 2026-03-25

### Features

- Add README, CHANGELOG, justfile, and git-cliff config

- Add bootstrap script for tool installation

- Improve zsh and starship config

- Have dev script be fullscreen with better layout and preview.

- Get rid of the sesh dependency for dev script.

- Fixup starship prompt to be more efficient.

- Cleanup zshrc, fix autocompletion to actually work.

- Add completion shortcuts to zsh for history.

- Add sesh for tmux management

- Cleanup zshrc

- Get vi mode in zshrc/starship and fix binding in tmux


### Bug Fixes

- Auto-bump version in justfile using git-cliff

- Add missing accept to completions.

- Make tmux use proper titles instead of hostname.


### Chores

- V0.1.0

- Add MIT license

- Clean up some cruft in the nvim config.

- Clean up nvim to remove lazyvim merged mistakes, and some permissions.

- Initial dotfiles



