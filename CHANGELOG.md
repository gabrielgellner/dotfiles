# Changelog

All notable changes to this dotfiles repository are documented here.
## [Unreleased]

### Bug Fixes

- Date releases in local time, not UTC


## [v1.1.0] — 2026-08-27

### Features

- Toggle the guides picker between titles and contents


### Bug Fixes

- Move zk's filetypes to the key zk-nvim reads

- Rust-analyzer has no cargo.allFeatures key

- Bind gsn ourselves — mini.surround stopped mapping it

- Undo prettier's reformatting of the guides

- Re-request LSP folds when the first answer comes back empty


### Refactoring

- Drop two restated defaults in matchup and conjure

- Drop two todo-comments keys, annotate oil's default

- Drop three catppuccin integrations that were never doing work


### Documentation

- Record what the second config-key sweep found

- Name the prettier bug correctly — two backticks, not one

- Never run prettier on the guides

- Cross-link the guides both ways

- List all eleven guides in the index

- Point the guide index at the contents search

- List the textobjects, and note that vaf skips decorators

- Say plainly that .chezmoiremove is temporary


## [v1.0.0] — 2026-08-27

### Features

- Keep the waiting count permanent, and order the states by glyph height

- Advertise <CR> follow-link on the guide float footer

- Show the q hint on the guide float, as the scratch float does

- Make codediff hunks legible, and say how many there are

- Debug Rust through codelldb, which gives the program back its stdout

- Rank active sessions first when searching, and steady the status bar

- Three Claude states, and a status bar that always says something

- Hide the preview by default, and keep utility sessions out of the list

- Show which tmux sessions have Claude working or idle

- Cmus in a popup on prefix + m, themed to match frappe

- Review unpushed work with <leader>gu, the way gm reviews a branch

- Let rules lookup reach creature abilities

- Give every picker a copy key, and document the pickers

- Stat the file when idle, so a buffer edited underneath you reloads

- Friendly-snippets, and <C-k>/<C-j> to drive a snippet

- The three Helix operations the first pass left out

- Helix-style multiple cursors on <leader>v

- Report what the i3 config needs, on the machine that uses it

- Pin the flavor by tracking package.toml

- Track the modifier remaps, macOS only

- Add bash-language-server, and put three scripts within its reach

- Let <leader>as reference the file from a codediff pane

- Scope mkv2mp4 and ffmpeg to macOS

- Give rustaceanvim a debug adapter it can find

- Track .zshenv, and make its PATH portable

- Track the global ignore file

- Complete only recipes for just, dropping files and dirs

- Route TAB completion through fzf-tab

- Replace fzf's C-r with atuin

- Order live sessions by recency, not alphabetically

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

- Hide the Claude float when a chain of floats leaves focus elsewhere

- Keep the multicursor colour across a colorscheme change, and drop six no-op highlights

- Name the matchup motions in normal mode too

- Drop grug-far's headerMaxWidth, which is not one of its options

- Drop a markdown-preview option that never applied, and two stale comments

- Drop the dead jinja2 formatter key, and stop using a legacy conform alias

- Drop the fzf preview, which had taken ctrl-p from the list

- Drop <leader>xt, which never worked

- Make ]d mean diagnostics, and focus every trouble list

- Lighten the codediff delete colours a step

- Choose the codediff hunk colours by contrast, not by eye

- Make the codediff hunk colours saturated, not just lighter

- Make Rust debugging actually launch, and drop a setting that never existed

- Make prefix + m toggle the cmus popup instead of stacking one

- Wrap scratch notes at 100, the width the float can actually show

- Make af/ac select functions and classes, as both files claimed

- Evaluate .scm through racket, the interpreter that is installed

- Drop catppuccin's nvim_cmp integration, which was never a real key

- Start treesitter on the first buffer of a session too

- Build LSP capabilities from blink, not from uninstalled nvim-cmp

- Bind zk's anchor-aware gd on new notes, not only existing ones

- Reparse spell_aliases.toml when it changes, and per notebook

- Stop the non-tmux just float closing before you can read it

- Fold accents in the markdown outline, sharing rules_lookup's table

- Make <leader>np promote a scratch, as its docs already claimed

- Anchor codediff's gf on the line's text, not its number

- Drop the dashboard key that could only ever report failure

- Stop ]d/[d claiming an operator-pending mode they do not have

- Make four plugins' own commands exist before their keys are pressed

- Stop reporting every ruff finding twice

- Keep the compiled spell file out of the source tree

- Vim.hl.on_yank, the name that is not deprecated

- Group the two autocmds that were registering duplicates

- Guard the last two unchecked external commands

- Stop the lint trigger from eating trouble's location list

- Drop a modifier remap kitty was rejecting anyway

- Put ~/bin on the non-interactive path too

- Switch sessions instead of detaching when one is destroyed

- Give the jinja filetypes something that produces them

- Keep the guides out of format-on-save, and drop the pragma

- Make shellcheck actually run on shell scripts

- Silence the duplicate-global warnings the dotfiles layout causes

- Keep the treesitter motions out of buffers that cannot use them

- Stop which-key advertising the old class motions

- Do not at-mention a buffer that has no file

- Both Option keys as Alt, not just the left one

- Make Option send Alt, or every <M-...> mapping is dead

- Guard treesitter textobject motions on a parser existing

- Put brew on PATH after installing it

- The font install aborted the whole run on Linux

- Make the debug-adapter lookups portable and non-throwing

- Install ffmpeg, which bin/mkv2mp4 requires

- Point debugpy at an interpreter that exists

- Prefer LLVM's lldb-dap, Apple's cannot launch

- Install the regex treesitter parser noice asks for

- Put ~/.cargo/bin on PATH

- Verify what it installs, not a third of it

- Only narrow just's completion at the first argument

- Complete just with one describe call, killing the duplicates

- Filter just's completion by value, not by rendered line

- Stop starship's vi-mode widget wrapping itself

- The promotion query needs --include-duplicates

- Expand the pathspec for <leader>gd/gD

- Restore ctrl-x kill in the session picker

- Subject-only entries, and order the groups

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

- Move the cmus popup from prefix m to prefix C-p

- Drop claude-window, keeping only the in-editor integration

- Drop the dashboard's Find Text, which <leader>fg already covers

- Remove tpm — neither of its plugins was needed

- Write the catppuccin theme out instead of fetching it

- Rewrite dev in bash, targeting the version macOS ships

- Share one file resolver between the Claude context maps

- One key for "next change" — ]c everywhere, class to ]k

- Move <leader>gd/gD from gitsigns to codediff

- Stop tracking tpm's plugin directory

- Vendor the one theme file instead of the whole repo

- Drop the uv_python fallback that could report a floor

- Drop two redundant options, one fork, and the silent guards

- Always show the guides picker, even for one guide

- Hand the quickfix motions to mini.bracketed too

- Move LSP navigation into Neovim's gr* namespace


### Documentation

- Record what the audit learned, and rewrite the README

- Add a guide for the cmus popup and its keys

- Flash's char mode does not add jump labels

- Record that plenary is end of life, not merely quiet

- Record the cmus rc in CLAUDE.md, and why it needs no re-add

- Give the :%s table in replace.md a header like every other one

- A guide for the four ways to replace, and when each is wrong

- The snacks module labelled "LSP progress indicator" is statuscolumn

- Tie the keymap audit counts to a protocol that reproduces them

- D]c does not work, and now neither the guide nor the code says it does

- Correct two cmdline completion claims that testing disproved

- Note that a snippet is rarely the preselected item

- A completion guide, and make the snippet keys inert outside a snippet

- Record spider's silent no-op on the last word of a line

- Write down window movement, and drop a claim that stopped being true

- Record the tab motions codediff makes you want

- Distinguish moving from extending a treesitter selection

- Warn that ]h works in one codediff view and not the other

- Record that only just's first argument is narrowed

- Note that .luarc.json overrides the lua_ls globals list

- Cover dot_claude and kitty, drop the deleted script

- Name the language servers nvim actually enables

- Describe the rendering that is actually configured

- Bring CLAUDE.md back in line with the repo

- Record why the changelog has a gap

- Write down the keymap conventions the audit settled on

- Add git and surround guides


### Styling

- Match folke's stylua config exactly

- Run stylua over oil.lua, the last unformatted file

- Run stylua over zk.lua

- Format the guides through prettier, at 80 columns


### Chores

- Delete the unused vendored theme

- Delete the vestigial dot_gitconfig-work

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


## [v0.2.0] — 2026-03-24

### Features

- Add ctrl-x to kill tmux session and colored pane preview


### Bug Fixes

- Use correct neogen annotation convention name for google docstrings


## [v0.1.1] — 2026-03-24

### Bug Fixes

- Switch dev and new-session scripts to zsh


## [v0.1.0] — 2026-03-24

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

- Add MIT license

- Clean up some cruft in the nvim config.

- Clean up nvim to remove lazyvim merged mistakes, and some permissions.

- Initial dotfiles



