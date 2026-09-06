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
| `bin/executable_claude-tmux-state` | `~/bin/claude-tmux-state` | Records Claude's state per tmux session — see its section below |
| `bin/executable_claude-tmux-status`| `~/bin/claude-tmux-status`| Summarises those states for the status bar — same section      |
| `bin/executable_gmuse-tmux-status` | `~/bin/gmuse-tmux-status` | Asks the running gmuse what is playing, for the same bar       |
| `dot_config/private_starship.toml` | `~/.config/starship.toml` | Starship prompt: vi mode indicators, custom uv_python module  |
| `dot_config/private_karabiner/`    | `~/.config/karabiner/`    | macOS modifier remaps — see the caveat below                  |
| `dot_config/nvim/`                 | `~/.config/nvim/`         | Neovim config (lazy.nvim, Lua)                                |
| `dot_config/kitty/kitty.conf`      | `~/.config/kitty/kitty.conf` | Kitty: 6 settings + a theme include; rest is commented     |
| `dot_config/gmuse/config.toml`     | `~/.config/gmuse/config.toml` | gmuse music player config — see the caveat below           |
| `dot_config/btop/`                 | `~/.config/btop/`         | btop resource monitor — see the caveat below                  |
| `dot_visidatarc`                   | `~/.visidatarc`           | VisiData — a Catppuccin Frappé theme; see the caveat below    |
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

`~/.config/gmuse/config.toml` is the *easy* case, and worth naming as the
contrast to the three above. gmuse never writes it — `src/config.rs` reads it
and nothing there writes it back — because its mutable state goes to
`$XDG_STATE_HOME/gmuse` (`session.toml`, `last-data-dir`, `machine-id`,
`session.log`) and its library index to `$XDG_CACHE_HOME/gmuse`. Both are
outside `~/.config`, so the tracked directory holds exactly one file and
`.chezmoiignore` needs no entry for it at all. No `private_` either: cmus
needed 0700 for its socket, and there is no socket here.

The **binary** is the part with a caveat. `gmuse` on PATH is a symlink,
`~/.local/bin/gmuse` -> `~/dev/gmuse/target/release/gmuse`, and it is
deliberately **not** tracked: `~/dev/gmuse` exists on the laptop and not on the
Linux machine, where a tracked `symlink_` entry would only dangle. It is
machine-local in the same way `~/.gitconfig.local` is. Recreate it with a plain
`ln -sfn`; there is no `cargo install` step, because `target/release/gmuse` is
already what `just ui` builds in that tree (its justfile notes debug builds are
too slow for glitch-free audio, so release is the only sensible target anyway).

Three consequences, all measured:

- A symlink is safe here in the way it is *not* for `~/bin/codelldb`. gmuse has
  no `current_exe` or argv[0] use anywhere in `src/` — every path comes from an
  XDG environment variable — so it resolves the same through a link. Checked by
  running `gmuse --version` through one.
- `cargo clean` makes gmuse **absent, not broken**: a dangling symlink fails
  `command -v` (rc 1), `test -x`, and execution ("command not found"). That is
  the good failure, but the popup binding has no fallback, so it opens and
  closes again with nothing in it. `cargo build --release` puts it back.
- A rebuild does not disturb the running player. The tmux session holds the old
  inode and plays on; the new build is what the *next* launch gets. So `q` in
  the popup and reopen is the way to pick up a change.

gmuse **holds an instance lock** now, and this section used to say it did not.
`src/lock.rs` takes an OS lock (`File::try_lock`) on
`$XDG_STATE_HOME/gmuse/lock` at `main.rs:70` — deliberately *before* the audio
device is opened, so a refused second instance never touches the speakers — and
a second one exits naming the pid that holds it. `--no-lock` (`cli.rs:111`)
starts anyway.

An OS lock rather than a pid file is the part worth keeping: the kernel drops
it however the process ends, so `kill -9` and a crashed popup leave nothing to
clean up, and a stale file holding a dead pid is not a lock. The pid is stored
only so the refusal can name something.

So the popup binding no longer carries that weight alone. The two answer
different questions: the lock says "not twice", `new-session -A` says "and here
it is". What the lock does *not* undo is `session.toml` — saved on quit unless
`--no-resume` is passed (it opts out of restoring and saving together), so
before the lock the instance quit last decided what the next launch restored.
Ratings and plays were never at risk: `events-*.log` is append-only, one short
line at a time, which is the same design that lets two machines share a library.
The audit log is opt-in (`--log` / `GMUSE_LOG`, `audit.rs` defaults it
disabled) and the popup runs bare `gmuse`, so it was never contended either —
an earlier version of this section wrongly listed it.

The player's tmux session is named **`music`, not `gmuse`**, and that is a
measured fix rather than a preference. `bin/executable_dev` names sessions
after directories in `~/dev`, and `~/dev/gmuse` is one of them, so `-s gmuse`
collided with the project's own editing session two ways at once: the popup
attached to *that* — verified in a nested tmux, the popup came up showing
`gmuse 1 nvim 2 console 3 console 4 zsh` and no player — and
`UTILITY_SESSIONS="gmuse"` hid the source session from the picker and took its
ctrl-x with it. Any utility session added here has the same trap: name it for
its role, and check the name against `ls ~/dev` first.

`~/.config/btop/btop.conf` is the karabiner problem a third time, with an extra
edge. btop rewrites the whole file on quit whenever `save_config_on_exit` is
true, so `chezmoi re-add ~/.config/btop/btop.conf` before applying after any
change made in its own options menu (`F2`). The rewrite is faithful — quitting
btop and diffing showed every hand-edited value preserved — so the tracked copy
is btop's own canonical output and `chezmoi diff` stays quiet. The edge is
`shown_boxes`: cycling view presets with `p` *mutates* it, and the mutated value
is what gets saved. Quitting on a preset that hides the net box wrote
`shown_boxes = "cpu proc"` into the file (measured, twice). So quit from
preset 0 before re-adding, or fix the line up by hand.

`disks_filter = "/ /System/Volumes/Data"` in that file is macOS-shaped and is
deliberately *not* a template: `chezmoi re-add` refuses to overwrite templates,
which would break the workflow above for the sake of one line. On macOS the
filter earns its place — `use_fstab` and `only_physical` are both useless there,
because `VM`, `Preboot`, `Update`, `xarts` and `iSCPreboot` are genuine APFS
volumes on the one device and btop lists all five (measured with `use_fstab`
both ways). On Linux the line means "show only `/`", which is wrong if that
machine has a separate `/home`; widen it there.

The graph settings in it are the point of the file. `mem_graphs = false` turns
the memory box from braille traces into labelled `■■■` meters, `show_io_stat`
drops the `IO%` row under each disk, `proc_cpu_graphs` drops the per-process
sparkline column, and `cpu_single_graph` collapses the CPU box's mirrored pair
into one. The CPU box's main graph and the whole net box cannot be turned into
meters — `btop --default-config` (1.4.7) has no option for it, so the only knobs
there are the graph symbol and hiding the box, which is what the second and
third presets do.

Driving btop to check any of this is easy:
`-c <file>` and `--themes-dir <dir>` take throwaway copies, so an A/B is two
`tmux new-session -d` calls and a `capture-pane` diff, and `ctrl+r` reloads the
config from disk without restarting.

`~/.visidatarc` is the only file here that is *code* rather than settings:
visidata `exec`s it as Python at startup (`settings.py:loadConfigFile`). It is
tracked at that path and not under `.config` on purpose. VisiData does look for
an XDG config first — `user_config_dir('visidata')/config.py`, used only if it
exists — but that comes from its vendored appdirs, which answers
`~/.config/visidata` on Linux and `~/Library/Preferences/visidata` on macOS
(measured by calling it). `~/.visidatarc` is the fallback on both, so one
tracked file serves both machines where a `config.py` would need a template and
a second target path.

Only one writer, unlike karabiner and btop above: nothing in visidata rewrites
this file behind your back. The single write path is `setPersistentOptions`,
which *appends* `options.x=...` lines and only after a y/n prompt naming the
file — it exists for API keys, not for theming. So `chezmoi re-add` is not part
of the workflow here.

What it holds is a Catppuccin Frappé theme, registered in `vd.themes` and
selected with `options.theme` rather than written as loose
`options.color_x = ...` assignments. VisiData 3.4 has a theme registry
(`theme.py`) and going through it buys two things bare assignments do not:
`theme-input` in the View menu switches between this and the four packaged
themes at runtime, and `theme-default` puts everything back, because
`set_theme()` unsets every `color_`/`disp_`/`note_` option before applying a
dict.

The colours are terminal colour *numbers*, and that is a hard limit, not a
preference: `color.py:_get_colornum` resolves a colour name to `int(name)` or a
curses `COLOR_` constant and nothing else, so hex is not expressible. Two
things follow, and they are what the file is built on.

ANSI 0-15 are *already* Frappé, because kitty paints them from
`dot_config/kitty/catppuccin-frappe.conf`. `red` is exactly `#e78284`, `black`
is surface1, `8` is surface2, `white` is subtext1, `15` is subtext0 — naming
those is exact, and it follows the terminal if the flavour ever changes. The
same goes for leaving a colour unset: the terminal's background *is* base and
its foreground *is* text, so `color_default = ''` beats any approximation of
`#303446`. Only the colours with no ANSI slot — peach, mauve, maroon, and a
dark base to write *on* an accent — are xterm-256 approximations, and each is
written as `'<256> <ansi-fallback>'`, the fallback form visidata documents in
`help_color`.

Setting an option visidata does not know is not an error — `options.set` warns
`setting unknown option` and carries on — so the theme dict is restricted to
keys that exist at startup. That rules out the `color_git_*` options (defined
only when `apps/vgit` is imported) and the `color_diff*` ones
(`experimental/diff_sheet`). Checked by loading the config headless and
asserting `vd.statusHistory` came back empty.

Driving visidata is the same detached-tmux method as everything else here, with
one addition worth knowing: `capture-pane -e` keeps the SGR escapes, so the
check is on the actual attributes rather than on how a screenshot looks —
`^[[38;5;216m` on a selected row is peach, `^[[100m` under the cursor cell is
surface2. `VD_CONFIG=<file>` points a throwaway run at an untracked copy.

`~/bin/codelldb` is a wrapper, not a symlink, and that is load-bearing.
CodeLLDB finds `liblldb` relative to its own argv[0], so a link in `~/bin` sends
it looking for `~/lldb/lib/liblldb.dylib` and it aborts; the wrapper passes
`--liblldb` explicitly. The adapter itself is not tracked — `bootstrap.sh`
unpacks a pinned release into `~/.local/opt/codelldb`, since upstream ships a VS
Code `.vsix` and Homebrew has no formula. It exists because the alternative,
`lldb-dap`, hangs on rustaceanvim's `runInTerminal` handshake; the long comment
in `dot_config/nvim/lua/plugins/rust.lua` has the detail.

Colour themes are pinned, not fetched. `dot_config/kitty/` carries one vendored
catppuccin theme file with its upstream commit in the header,
`dot_config/btop/themes/` carries one the same way (btop 1.4.7 ships 41 themes
of its own and none of them is catppuccin), and `dot_tmux.conf`
carries tmux's frappe colours inline — that was a tpm plugin, 3.4MB of shell to
produce a dozen `set -g` lines, so the resolved output was read off the server
and pasted in. There is no tmux plugin manager any more: tpm's only other plugin
was vim-tmux-navigator, and its tmux half went unused because work here is
divided into windows (`prefix + 1/2/3`), never panes. `.tmux/plugins` stays in
`.chezmoiignore` as a guard.

yazi sits between the two. `dot_config/yazi/package.toml` **is** tracked: it
names the flavor and the commit it is pinned to, so `ya pkg install` reproduces
the tree, which is the relationship `lazy-lock.json` has with lazy.nvim.
`theme.toml` is tracked alongside it and is what actually *selects* that flavor
— the pin does nothing on its own. The fetched content under
`.config/yazi/flavors` is ignored. To move the pin,
`ya pkg upgrade` and then `chezmoi re-add ~/.config/yazi/package.toml`, the same
two steps as `:Lazy update` followed by committing the lockfile.

## Claude's State in the Status Bar

Hooks in `~/.claude/settings.json` drive `~/bin/claude-tmux-state`, which writes
one file per tmux session under `$XDG_STATE_HOME/claude-tmux`;
`~/bin/claude-tmux-status` counts those into the `⣿ ⣤ ⣀` slots in
`status-right`, and `dev` shows the same three as `[a]` / `[q]` / `[i]`.

Editing that settings file from a script makes you a third writer alongside the
two named above, so keep the serialiser faithful: Python's `json.dump` defaults
to `ensure_ascii=True`, which turns the em dashes in `autoMode.environment` into
`\uXXXX` escapes. The file still parses and still means the same thing, but
every one of those lines shows up in `chezmoi diff` and in the next diff Claude
Code's own writer produces.

What the hooks write is a **latch, not a sample** — nothing polls.
`status-interval 5` re-renders a file that only hooks write, so a missed edge is
permanent rather than late. That is the whole of the bug this feature carried
for its first month: `working` was written by `UserPromptSubmit` alone, so once
a permission prompt was answered nothing re-armed it and the bar read "wants
you" for the rest of the turn.
Caught live on 2026-09-05 — `sdmxlib` held `waiting permission_prompt` from the
previous evening while its pane showed `✳ Combobulating… (34m 20s)`.

Four things follow, all re-measured on Claude Code v2.1.236 by wiring every
candidate event to a logger in a throwaway detached session:

- **The event set is not the schema, and it is bigger than this repo used to
  claim.** `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`,
  `Notification`, `Stop`, `SubagentStop` and `SessionEnd` fire. `StopFailure`,
  `PermissionRequest`, `PermissionDenied`, `Elicitation` and `PreCompact` stay
  silent. `PostToolUse` does **not** fire when a tool errors — measured on a
  `git status` that exited 128 — so `PreToolUse` is the only per-tool event to
  rely on.
- **`working` has four writers**, three of them tool events, which is what
  re-arms the latch mid-turn. They fire on every tool call, so the script is on
  a hot path: one `tmux display-message` and one small write. The write is
  deliberately unconditional rather than skipped when the file already says
  `working`, because the mtime is then the last tool call — a heartbeat, and
  the thing that made the original bug findable. Long autonomous stretches need
  this: re-invocation by background-task output fires no `UserPromptSubmit` at
  all, and one session went fifteen hours on four prompts.
- **`Notification` carries more than `idle_prompt`.** `permission_prompt` fires
  too, about 6s after the dialog opens, and answering inside that window
  produces no notification at all. The kind decides a colour rather than being
  recorded for interest: `idle_prompt` means "finished, and you have not come
  back", which is what green already says, so pink `⣤` and `dev`'s `[q]` are
  left to the kinds genuinely blocked on you. `dev` splits them the same way on
  purpose — the bar and the picker must not disagree about one session. Because
  the kind is load-bearing it is read with `grep`, not `jq`: jq is a dependency
  of nothing else here, is absent from `bootstrap.sh`, and merely happens to sit
  in `/usr/bin` on macOS.
- **Liveness is a process question, not a session question.** `SessionEnd` fires
  on a clean exit only, so a Claude killed under a surviving tmux session left
  `working` on disk for ever, and `tmux has-session` could not see it. The
  status script walks `ppid` from every process named exactly `claude` up to a
  `pane_pid` instead — cheaper than the per-file `has-session` it replaced, and
  it answers both staleness cases at once. The walk must go several levels:
  claudecode.nvim's instance sits under `nvim --embed` under the pane's `nvim`.

Driving this is the usual detached-tmux method, with one wrinkle: the first
`send-keys` after launch is swallowed by Claude's startup screen, so send the
prompt twice. Sample the state file rather than the bar — content plus mtime, a
few times a second — and the transitions read out directly.

## Neovim Configuration Architecture

Lazy.nvim-based setup with modules under `dot_config/nvim/lua/`:

- `config/` — loaded unconditionally. Beyond `options`, `keymaps` and `autocmds`
  this holds standalone features: `files` (oil ↔ explorer handoff), `float`
  (maximize a snacks float, which snacks.win itself cannot), `folds`
  (LSP/treesitter fold dispatch), `guides` (the `<leader>?` picker), `just`
  (run recipes into a tmux console window), `plv` (the table viewer handoff),
  `scratch`, `markdown_checkbox`, `markdown_outline`, `rules_lookup`.
- `plugins/` — one file per plugin or plugin group, lazy-loaded.
- `guides/` — hand-written markdown reference cards, opened with `<leader>?`.
  Fourteen of them, indexed at the end of `keymaps.md`; `gf` or `<CR>` follows a
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
git (gitsigns, codediff), Rust, Scheme (conjure, paredit).

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
`multicursor.lua` and nvim-paredit came out clean.

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

Installed by `bootstrap.sh`, which skips anything already present and installs
only the gaps — run it on a half-provisioned machine to fill it in. An install
that *fails* is the error it reports: the run continues, and ends non-zero
naming what failed, rather than aborting at the first one and leaving the rest
uninstalled. Core:
`tmux`, `nvim`, `fzf`, `fd`, `ripgrep` (`rg`), `eza`, `bat`, `yazi`, `btop`,
`visidata` (`vd`), `zoxide`, `atuin`, `starship`, `direnv`, `lazygit`, `zk`,
`just`, `git-cliff`, `tree-sitter`, `uv` (Python).

Language servers: `lua-language-server`, `bash-language-server`, `pyrefly`,
`ruff`, `just-lsp` — the five `plugins/lsp.lua` enables. bash-language-server
shells out to `shellcheck` and serves its findings as code actions, which is
why `plugins/lint.lua` has no `sh` entry.
`basedpyright` is installed but deliberately *not* enabled in nvim — it is the
CI/`just` checker, while pyrefly does the editor work.

## Starship Custom Module

`dot_config/private_starship.toml` defines a custom `uv_python` module that
shows the contents of `.python-version` when both it and `uv.lock` are present.
It reads the file rather than running `.venv/bin/python` because this evaluates
on every prompt; the tradeoff is noted in the config. The vi mode uses `❯`/`❮`
symbols with color coding (green=normal, red=error, yellow=visual, purple=replace).
