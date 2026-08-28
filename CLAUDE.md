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

A published release is final. `main` is protected against force-push and, since
2026-08-27, `v*` is a protected tag pattern on GitLab — a delete push comes back
"You can only delete protected tags using the web interface" (measured, with the
tag left intact). So a release that ships something wrong is fixed by cutting
the next version, not by moving the tag. v1.1.0 was retagged once, before the
protection existed, because its changelog was dated in UTC; doing that again
means unprotecting in the project settings first, on purpose.

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
| `dot_config/eilmeldung/`           | `~/.config/eilmeldung/`   | eilmeldung RSS reader: frappe palette + the tracked feed list |
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

`dot_config/eilmeldung/feeds.opml` is the same idea again, for RSS
subscriptions. The live list is rows in the news-flash SQLite database, which
on macOS sits under `~/Library/Application Support/org.christo-auer.eilmeldung`
and is state, not config — so the OPML is the tracked copy and
`eilmeldung --import-opml ~/.config/eilmeldung/feeds.opml` seeds a new machine
from it. `--export-opml` goes the other way, but writes a single unformatted line
titled "NewsFlash OPML export" with the file's header comment gone — so it is
for *checking* what the database holds, not for regenerating the tracked file.
Two things bite when editing that file: XML forbids `--` inside a comment, so
the flags cannot be spelled out in the file's own header, and an OPML holding
one is *rejected* by the importer rather than ignored (measured — the import
failed with "invalid comment at 2:1" until the header was reworded).
To add a single feed to a database that is already seeded, import a *one-feed*
OPML rather than the whole file — naming an existing category in it puts the
feed in that category rather than creating a second one of the same name
(measured, adding lucumr.pocoo.org to `Tech`). Then hand-add the same entry
here and diff the two. Whether re-importing the whole file duplicates was not
tested, only avoided.

`config.toml` carries `[login_setup]` with `provider = "local_rss"` and
`login_type = "no_login"`, which is what keeps a fresh machine out of the
interactive first-run wizard.

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
quote row — survives; measured both ways.) It also rewrites `*emphasis*` to
`_emphasis_` and re-pads tables. All three have happened. `prettier --check` failing on a guide is the expected state, not a
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

A second sweep on 2026-08-27 checked every plugin file's configured keys against
the plugins' own defaults — all thirty, both the `opts` ones and the nine that
configure through `config = function()`. It found four dead keys, eight restated
defaults worth deleting, and two worth keeping because the files say why — all
listed under "Faults this config has had" below. `dap.lua`, `lsp.lua`,
`haskell.lua`, `multicursor.lua` and nvim-paredit came out clean.

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

eilmeldung is the awkward case for that method: a session accepts keys right
after launch and then goes deaf, three times out of four, with `send-keys`
reporting success and the pane still repainting. Driving it by keystroke is
therefore unreliable — but it does not need to be driven. Two of its own
features replace the harness:

- `startup_commands` in `config.toml` runs any command at launch, so a popup
  can be opened with no keystrokes at all. Two throwaway config dirs passed to
  `--config-dir`, differing in one line, gave a clean A/B of `shadows`: the
  same help float with 141 `░` glyphs and with none.
- its config parser **rejects unknown fields** — `shadowz = false` aborts at
  `src/config/mod.rs:440` and prints every accepted field name. That is the
  opposite of the nvim plugins below, where a misspelled key just sits in the
  merged table. A config that starts eilmeldung at all is a config with no
  typos in its key names, so `--config-dir <dir> --sync` is a cheap syntax
  check.

## Faults this config has had

Each of these has bitten more than once. Worth checking for when touching
anything here:

- **Configured but never run.** An option the plugin does not read, or no longer
  reads: `headerMaxWidth` (grug-far has no such option), `port = 0` (takeover
  mode returns a hardcoded 8421 before consulting it), `jinja2` (never a
  filetype anything produces), nvim-treesitter's dropped module schema,
  `nvim_cmp` and `treesitter` (catppuccin spells the first `cmp` and has no
  integration for the second), `sign_hl` (todo-comments knows `signs` and
  `sign_priority` and nothing between them), `cargo.allFeatures` (rust-analyzer
  renamed it `cargo.features`, which takes `"all"`), `auto_attach.filetypes`
  (zk-nvim reads `lsp.config.filetypes`). Nothing warns — the key just sits in
  the merged table.

  The worst of them was mini.surround's `update_n_lines = "gsn"`: dropped from
  the plugin's `mappings`, so `gsn` was unmapped while a guide advertised it.
  A dead key can take a documented keystroke down with it.
- **Restated defaults.** Six of multicursor's seven highlight lines set what the
  plugin had already set. So did catppuccin's `snacks`/`treesitter_context`
  (auto_integrations enables anything lazy reports installed), todo-comments'
  `signs`, matchup's `motion_enabled`, conjure's `doc_word`, rust-analyzer's
  `chainingHints`/`typeHints`, and zk's `cmd`/`name`/`auto_attach.enabled`.
  Keep one only where it records a decision worth seeing, and say so — flash's
  `char.enabled` and oil's `default_file_explorer` do, which is why they stayed.
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

To find the first two, compare against the plugin's *own* defaults, read from
the installed copy rather than its README — a `local defaults` table in its
`config.lua`, `MiniX.config` before `setup()` replaces it with the merged table,
gitsigns' `config.schema`, or `rust-analyzer --print-config-schema` straight from
the binary. Then measure: drop the key and diff the observable state.
`nvim_get_hl(0, {})`, `vim.fn.maparg()`, the extmarks in a buffer and the
inlay hints a server returns all answer directly, and an unchanged dump is the
proof that the line was doing nothing.

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
