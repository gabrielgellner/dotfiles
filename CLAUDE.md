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
| `bin/executable_mkv2mp4`           | `~/bin/mkv2mp4`           | Video remux helper                                            |
| `bin/executable_claude-tmux-state` | `~/bin/claude-tmux-state` | Records working/idle per tmux session, from Claude's hooks    |
| `bin/executable_claude-tmux-status`| `~/bin/claude-tmux-status`| Summarises those states for tmux's status-right               |
| `dot_config/private_starship.toml` | `~/.config/starship.toml` | Starship prompt: vi mode indicators, custom uv_python module  |
| `dot_config/private_karabiner/`    | `~/.config/karabiner/`    | macOS modifier remaps — see the caveat below                  |
| `dot_config/nvim/`                 | `~/.config/nvim/`         | Neovim config (lazy.nvim, Lua)                                |
| `dot_config/kitty/kitty.conf`      | `~/.config/kitty/kitty.conf` | Kitty: 6 settings + a theme include; rest is commented     |
| `dot_config/private_cmus/rc`       | `~/.config/cmus/rc`       | cmus: frappe colours — the one file cmus never rewrites       |
| `dot_claude/settings.json`         | `~/.claude/settings.json` | Claude Code settings — see the caveat below                   |
| `dot_claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | Statusline renderer invoked by that settings file     |
| `bin/executable_codelldb`          | `~/bin/codelldb`          | CodeLLDB adapter wrapper — see the caveat below               |
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

`~/.config/cmus/` is the same problem solved the other way round. cmus rewrites
`autosave` on exit — and saves *colours* into it, so a `.theme` file applies
once and is then carried by autosave, where a later edit to the theme does
nothing. But cmus also reads `rc` immediately afterwards and documents that it
never writes to it, so the colours live there and are re-applied every start
with no `re-add` dance. `.chezmoiignore` excludes everything else in that
directory: autosave, the cache, the library index and a unix socket. The
`private_` prefix is not decoration either — the socket is why the directory is
0700, and chezmoi would otherwise widen it to 0755.

`~/bin/codelldb` is a wrapper, not a symlink, and that is load-bearing.
CodeLLDB finds `liblldb` relative to its own argv[0], so a link in `~/bin` sends
it looking for `~/lldb/lib/liblldb.dylib` and it aborts; the wrapper passes
`--liblldb` explicitly. The adapter itself is not tracked — `bootstrap.sh`
unpacks a pinned release into `~/.local/opt/codelldb`, since upstream ships a VS
Code `.vsix` and Homebrew has no formula. It exists because the alternative,
`lldb-dap`, hangs on rustaceanvim's `runInTerminal` handshake; the long comment
in `dot_config/nvim/lua/plugins/rust.lua` has the detail.

Colour themes are pinned, not fetched. `dot_config/kitty/` carries one vendored
catppuccin theme file with its upstream commit in the header, and `dot_tmux.conf`
carries tmux's frappe colours inline — that was a tpm plugin, 3.4MB of shell to
produce a dozen `set -g` lines, so the resolved output was read off the server
and pasted in. There is no tmux plugin manager any more: tpm's only other plugin
was vim-tmux-navigator, and its tmux half went unused because work here is
divided into windows (`prefix + 1/2/3`), never panes. `.tmux/plugins` stays in
`.chezmoiignore` as a guard.

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
  Eleven of them, indexed at the end of `keymaps.md`; `gf` or `<CR>` follows a
  link between them, and `<C-g>` in the picker switches from matching titles to
  grepping their contents.

**Never run prettier on `dot_config/nvim/guides/`.** They are hand-formatted.
`plugins/formatting.lua` skips them on save — prettier corrupts a code span
whose content is *two* backticks, rewriting `` `` `` to `` ` `` plus a stray
pair. The row it eats is the jumplist `` `` `` in navigation.md, and the only
guard is a `<!-- prettier-ignore -->` comment that render-markdown refuses to
conceal. (A span holding *one* backtick — files.md's `:cd` row, surround.md's
quote row — survives; measured both ways.) It
also rewrites `*emphasis*` to `_emphasis_` and re-pads tables. All three have
happened. `prettier --check` failing on a guide is the expected state, not a
defect to fix: some table rows are deliberately not aligned.

Plugin categories: LSP + completion (blink.cmp), DAP debugging, treesitter,
formatting/linting, UI (noice, snacks, mini), navigation (flash, spider, oil),
git (gitsigns, codediff), Rust, Haskell, Scheme (conjure, paredit).

## Keymap Conventions

`dot_config/nvim/guides/keymaps.md` records the rules this config follows and
the faults each one prevents — read it before adding a mapping. In short: a
capital means a *wider* scope and never an unrelated action; a doubled key is
the ordinary case; buffer-local mappings silently beat global ones, which is the
most common way a keymap appears to do nothing; and `mode = "x"`, never `"v"`,
because `"v"` includes select mode.

## Verifying a change here

The comments in this repo state what was *measured*, not what was expected. An
audit through 2026-08 exercised every file in `lua/plugins/` and every module in
`lua/config/` by driving them rather than reading them. Keep that bar: a claim
in a comment should be something someone ran.

The method is a detached tmux session — `tmux new-session -d`, drive it with
`tmux send-keys`, read it back with `tmux capture-pane`. Two rules earned the
hard way:

- **Measure state, not side effects.** `require("dap").session()`,
  `mc.numCursors()`, `vim.fn.maparg()`, `nvim_win_get_config()` answer directly.
  Inferring from "did the buffer change" produced three false bug reports in one
  sitting: an insert that landed on the same column for every cursor, a
  keystroke that never arrived, and a continue that silently did nothing.
- **Suspect the probe before the config.** Every one of those was the harness.
  A window-picking loop landed in a snacks notification window; a `list-keys`
  check loaded the user's own config and reported it as a tmux default.

Interactive overlays *are* drivable, contrary to an earlier note in this repo:
flash's jump labels, which-key popups and codediff's panes all render into the
terminal grid, so `capture-pane` reads the label out and it can be sent straight
back. The exception is `vim.fn.input()` under noice — invisible to
`capture-pane` but still receiving keys, so a blank capture there is not
evidence of a broken prompt.

## Faults this config has had

Each of these has bitten more than once. Worth checking for when touching
anything here:

- **Configured but never run.** An option the plugin does not read, or no longer
  reads: `headerMaxWidth` (grug-far has no such option), `port = 0` (takeover
  mode returns a hardcoded 8421 before consulting it), `jinja2` (never a
  filetype anything produces), nvim-treesitter's dropped module schema. Nothing
  warns — the key just sits in the merged table.
- **Restated defaults.** Six of multicursor's seven highlight lines set what the
  plugin had already set. Keep one only where it records a decision worth
  seeing, and say so.
- **Stale comments.** Keymaps move and their explanations do not follow:
  `<leader>mR` for a refresh that is now `<leader>mf`, `<C-\>` for an escape
  that is now `<C-x>`.
- **One-shot highlight overrides.** `nvim_set_hl` in a plugin's `config()` does
  not survive `:colorscheme` — that clears every group, after which the plugin's
  own `default = true` fills it back in. Overriding a plugin highlight needs a
  ColorScheme autocmd of its own.
- **Legacy aliases.** `lsp_fallback`, `checkOnSave` as a table: honoured today,
  silently, with nothing to say they are the old spelling.
- **Terminal key collisions.** `C-m` is Enter, `C-i` is Tab, `C-[` is Esc — the
  same byte, not a binding. `C-j` survives only because it is a different one.

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
