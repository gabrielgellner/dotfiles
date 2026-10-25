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

**The remote is GitHub since 2026-09-23.** `origin` is
github.com/gabrielgellner/dotfiles, public; the GitLab project it moved off is
still there, kept as the remote `gitlab` and no longer pushed to. `just release`
ends in `git push --follow-tags` with no remote named, so it follows `main`'s
upstream and lands on GitHub without a change to the recipe.

A published release is final, and that survived the move. Two GitHub rulesets
carry it: `protect-main` (deletion, non_fast_forward) on `refs/heads/main`, and
`protect-version-tags` (deletion, update, non_fast_forward) on `refs/tags/v*`.
`GET /repos/.../rules/branches/main` lists both of the branch rules as applying,
which is how they were checked — the rejection itself is *not* measured here,
unlike the GitLab original, where a delete push came back "You can only delete
protected tags using the web interface" with the tag left intact. So a release
that ships something wrong is still fixed by cutting the next version, not by
moving the tag. v1.1.0 was retagged once, under GitLab and before any protection
existed, because its changelog was dated in UTC; doing that again means
disabling the ruleset in Settings → Rules first, on purpose.

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

Notes are not in this repo, and that is a **safety** boundary rather than a
tidiness one: `origin` is public. There are three tiers, and none of their
content is tracked here.

- `~/scratch` — the scratch notebooks behind `<leader>.` (project) and
  `<leader>ng` (the global journal). `.chezmoiignore` carries `scratch/*` with
  a single `!scratch/.prettierrc` exception, so `chezmoi add ~/scratch/...`
  cannot pull a note in by accident. Untracked by git as well, deliberately:
  its `.meta` sidecars record an absolute `cwd`
  (`/Users/gabrielgellner/dev/...`), which would not resolve on the Linux
  machine anyway.
- `~/notes` — the zk notebook, `$ZK_NOTEBOOK_DIR` in `dot_zshrc`. Since
  2026-09-29 it is **its own private repository**,
  github.com/gabrielgellner/notes, created private and verified so. Only
  `.zk/notebook.db` is gitignored there: a SQLite index `zk index` rebuilds,
  which `plugins/zk.lua` runs on every note opened. `.zk/config.toml` and
  `.zk/templates/` are tracked, because without them a clone is a pile of
  markdown rather than the same notebook.
- Per-project notebooks (a directory with its own `.zk/`) belong to whatever
  repo they sit in.

That notes repo **cannot** have the `protect-main` ruleset this one has, and
the reason is the plan rather than an oversight: rulesets and classic branch
protection are both 403 on a **private** repo on the free plan — "Upgrade to
GitHub Pro or make this repository public" (measured, both endpoints). The
protection here works because this repo is public. `~/notes` carries a tracked
`.githooks/pre-push` instead, refusing non-fast-forward pushes and deletions of
main, with `just hooks` to arm a clone and `just sync` warning when it is not.
It stops the mistake rather than the intent: `--no-verify` goes straight past
it, and a fresh clone is unguarded until `just hooks` runs.

`journal/.gitkeep` in that repo is load-bearing. git does not track an empty
directory and **zk does not create a missing one** — `zk new` into an absent
path fails with "directory not found", measured — so the `daily` alias would
fail on a fresh clone without it. A `.gitkeep` rather than a README because
anything ending `.md` inside a notebook is a note, and zk would index it.

Machine-local secrets stay out of the repo entirely — `dot_gitconfig` includes
`~/.gitconfig.local`, which is not tracked. The global ignore file
(`dot_config/git/ignore`) *is* tracked, since its rules should hold on both
machines; git finds it at the XDG default, with `core.excludesfile` unset.

The Linux machine runs its desktop over RDP, which is why `.xsession`,
`.config/i3` and `.config/i3status` are tracked and Linux-only — `.xsession` is
what xrdp reads to start i3. That constraint reaches further than it looks:
anything i3-, font- or terminal-size-shaped on that machine is answering to the
remote display rather than to taste, which is why `dot_config/kitty/font.conf.tmpl`
exists at all. `.config/fontconfig` is tracked but *not* Linux-only; it turned
out to be present on macOS too.

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
| `dot_config/kitty/kitty.conf`      | `~/.config/kitty/kitty.conf` | Kitty: 5 settings, a theme include, and a font-size include; rest is commented |
| `dot_config/kitty/font.conf.tmpl`  | `~/.config/kitty/font.conf` | Font size per machine — see the caveat below                  |
| `dot_config/xterm/XTerm`           | `~/.config/xterm/XTerm`   | The Linux machine's terminal; Linux only — see below          |
| `dot_config/yazi/`                 | `~/.config/yazi/`         | yazi: pins, theme, vim counts, marks, keymap audit — see below |
| `executable_dot_xsession`          | `~/.xsession`             | Starts i3 under xrdp; Linux only                              |
| `dot_config/gmuse/config.toml`     | `~/.config/gmuse/config.toml` | gmuse music player config — see the caveat below           |
| `dot_config/btop/`                 | `~/.config/btop/`         | btop resource monitor — see the caveat below                  |
| `dot_config/mermaid/puppeteer.json` | `~/.config/mermaid/puppeteer.json` | Browser mmdc renders mermaid with — see the caveat below |
| `dot_config/himalaya/`             | `~/.config/himalaya/`     | himalaya, scripted mail access for the shell and Claude — see Mail below |
| `dot_config/neomutt/`              | `~/.config/neomutt/`      | NeoMutt, the mail client; macOS only — same section            |
| `dot_config/isyncrc.tmpl`          | `~/.config/isyncrc`       | mbsync: mirrors Proton into the maildir NeoMutt reads — same section |
| `dot_config/notmuch/default/config.tmpl` | `~/.config/notmuch/default/config` | notmuch: search index over that maildir — same section |
| `bin/executable_mail-sync`         | `~/bin/mail-sync`         | one sync, run by that agent; notifies when Bridge is down — same section |
| `bin/executable_mail-backup`       | `~/bin/mail-backup`       | encrypted restic backup of the maildir to the NAS — same section |
| `bin/executable_mail-attachments`  | `~/bin/mail-attachments`  | copies attachments worth keeping to the NAS, by hand — same section |
| `bin/executable_mail-unlabel`      | `~/bin/mail-unlabel`      | NeoMutt's `-`: takes one label off a message — same section |
| `bin/executable_mail-image`, `bin/executable_mail-open` | `~/bin/…` | NeoMutt attachments: inline in kitty, or in their macOS app — same section |
| `bin/executable_mail-attach-pick` | `~/bin/mail-attach-pick` | NeoMutt compose's `a`: attach files picked in yazi — same section |
| `bin/executable_mail-contacts`     | `~/bin/mail-contacts`     | NeoMutt's address lookup (Ctrl-Y), from notmuch — same section |
| `private_Library/private_LaunchAgents/local.mbsync-proton.plist.tmpl` | `~/Library/LaunchAgents/…` | launchd agent running mbsync every 2m — same section |
| `dot_claude/settings.json`         | `~/.claude/settings.json` | Claude Code settings — see the caveat below                   |
| `dot_claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | Statusline renderer invoked by that settings file     |
| `bin/executable_codelldb`          | `~/bin/codelldb`          | CodeLLDB adapter wrapper — see the caveat below               |
| `bootstrap.sh`                     | —                         | Installs the toolchain on a fresh machine; not applied        |

`~/.claude/settings.json` has two writers. Claude Code rewrites it whenever a
setting changes from inside the tool — model, theme, effort level, enabled
plugins — while chezmoi holds its own copy. Whichever wrote last wins, so a
change made in the tool is reverted by the next `chezmoi apply`. Capture such a
change with `chezmoi re-add ~/.claude/settings.json` before applying.

`~/.config/kitty/font.conf` is a three-line file for one setting, and the split
is forced rather than chosen. `kitty.conf` here is kitty's full annotated
reference config, and it folds on triple braces — the same two characters Go's
template parser treats as the start of an action. So the file cannot be a
`.tmpl`: `chezmoi execute-template` rejects it with `unexpected "{" in command`.
Measured, and then measured again when the new file's own comment quoted the
markers literally and broke the same way.

The setting has to differ per machine because the *unit* does. kitty sizes text
in points; a point is 1/72 inch to CoreText and 1/96 inch to the Linux machine's
Xvnc (`-dpi 96`), so the same number renders a third larger over RDP. The laptop
keeps 14.0 and the VM uses 12.0; parity would be 10.5. The grid each size
produces at 1920x1080 is tabulated in the file, measured by reading `stty size`
out of a full-screen kitty on a throwaway `Xvnc :99` — which also showed that
13.5 is a no-op, quantising to the same cell as 14.0.

**The Linux machine runs xterm, not kitty**, and that is a measured speed
decision. With no GPU, kitty's OpenGL runs on llvmpipe and redraws its whole
window every frame, and xorgxrdp then has to scan all of it: a spinner changing
one cell ten times a second damaged the full 1920x1054 window each time —
238.8 Mpx in 10s, kitty at 64% of a core — where xterm damaged 2.4 Mpx in 10x17
rects at 0.4%. Measured with the X DAMAGE extension on a throwaway
`Xvnc :99 -depth 24 -dpi 96`; urxvt reached 22 Mpx, and st and xfce4-terminal
both repaint the full window as kitty does. What it costs is kitty graphics
(snacks.image, yazi previews) and FiraCode's ligatures. Nerd Font glyphs,
Frappé, italics and truecolour all render — the last only because
`.tmux.conf` marks `xterm-256color` as RGB.

Its resources are `dot_config/xterm/XTerm`, found through
`XUSERFILESEARCHPATH`, which i3's `$term` sets — there rather than in
`.xsession`, so an i3 restart is enough to pick it up. Not `.Xresources` and xrdb:
the VM has an untracked `~/.Xdefaults` (xscreensaver settings), and X only reads
that file while no `RESOURCE_MANAGER` property is set, so loading anything with
xrdb would silently drop it.

`~/.config/karabiner/karabiner.json` has settings.json's shape of problem: Karabiner
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
needed 0700 for its socket, and the engine's socket is not here — it lives in
`$XDG_RUNTIME_DIR/gmuse/` (`$TMPDIR/gmuse/` on macOS), in a directory gmuse
chmods 0700 itself.

The hazard is the other direction: **the schema changes under the tracked
copy**, and nothing warns, because the file is only ever read. `[catalogs.*]`
and `active_catalogs` became views (`view`, `library`) and the tracked copy went
stale — at which point `chezmoi apply` would have quietly pushed the obsolete
shape back over a working config. gmuse keeps the dead keys *only* to report
them (`src/config.rs:78`), which is what makes this recoverable rather than
silent. So after upgrading gmuse, diff before applying, the same as for the
files with two writers above — the reason differs, the workflow does not.

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
- A rebuild does not disturb anything running. Old inodes play on; the new build
  is what the *next* launch gets — and since the split there are two launches.
  `q` and reopen picks up a new **view**; a change to the audio path needs
  `gmuse ctl engine.shutdown` first, because the engine is a daemon and the
  popup closing does not end it.

**gmuse is a client/server pair now, and this section twice said otherwise.**
Playback lives in a `gmuse engine` daemon, listening on
`$XDG_RUNTIME_DIR/gmuse/engine.sock` (`$TMPDIR/gmuse/` on macOS, where there is
no `XDG_RUNTIME_DIR`). Bare `gmuse` is a **view**: no audio device, no player
lock, it starts an engine if none answers and attaches. So quitting the TUI
leaves the music playing, and two views run side by side quite happily —
measured, two at once with the player lock unheld by either.

Which makes the instance lock this section used to describe the wrong lock to
care about. `src/lock.rs` still exists and still guards a `--no-attach` player,
but the default path never takes it. "Not twice" is now `engine.lock`, beside
the socket, and it is about the daemon: one engine per user, and a second exits
rather than opening a second device. Same reasoning as before — an OS lock
rather than a pid file, because the kernel drops it however the process ends.

The popup binding is back to answering one question rather than sharing two.
`new-session -A` says "and here it is"; nothing about it constrains how many
views exist, and it no longer needs to. `session.toml` is likewise the engine's
concern rather than a race between popups. Ratings and plays were never at risk:
`events-*.log` is append-only, one short line at a time, which is the same
design that lets two machines share a library. The audit log is opt-in
(`--log` / `GMUSE_LOG`, `audit.rs` defaults it disabled).

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

`disks_filter = "/ /media/triples /System/Volumes/Data"` names mountpoints for
*both* machines at once, and is deliberately *not* a template: `chezmoi re-add`
refuses to overwrite templates, which would break the workflow above for the
sake of one line. The union is safe because the match is by **equality**, not
prefix — btop tests each mountpoint for membership in the list — so an entry
naming a path the machine does not have is inert rather than wrong. That is what
lets one line serve both: `/System/Volumes/Data` matches nothing on Linux and
`/media/triples` matches nothing on macOS. (A prefix match would make `/` alone
select everything, which it plainly does not.)

On macOS the filter earns its place — `use_fstab` and `only_physical` are both
useless there, because `VM`, `Preboot`, `Update`, `xarts` and `iSCPreboot` are
genuine APFS volumes on the one device and btop lists all five (measured with
`use_fstab` both ways). On Linux `use_fstab = true` makes *fstab* the candidate
list, which on the Azure machine is `/`, `/boot/efi`, `/media/triples` and
`/mnt` — nothing outside those four can be filtered back in. It has no separate
`/home`, so the old "show only `/`" value was not wrong here, just blind to the
5TB CIFS share. `/boot/efi` (104 MiB) and `/mnt` (the ephemeral Azure resource
disk) are left out on purpose; add either by name to get it back. Measured by
running `btop -c` on a throwaway copy listing all four, which drew root, efi,
triples and mnt as four separate meters.

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

yazi sits between the two, and now does both at once.
`dot_config/yazi/package.toml` **is** tracked: it names the flavor and
`KKV9/compress` and the commits they are pinned to, so `ya pkg install`
reproduces those trees, which is the relationship
`lazy-lock.json` has with lazy.nvim. `theme.toml` is tracked alongside it and is
what actually *selects* that flavor — the pin does nothing on its own. The
fetched content under `.config/yazi/flavors` and `.config/yazi/plugins` is
ignored. To move a pin, `ya pkg upgrade` and then
`chezmoi re-add ~/.config/yazi/package.toml`, the same two steps as
`:Lazy update` followed by committing the lockfile. Beware that `ya pkg upgrade`
takes *everything* it manages: run to check something unrelated, it moved the
flavor from `20b47bf` to `1183892` on its own.

`relative-motions` is the exception, and the one place here where a dependency
is **vendored rather than pinned**. It gives yazi vim counts — `3j`, `12k`,
`10gg`, and `d`/`v`/`y`/`x` after a count — with `init.lua` holding its options
and `keymap.toml` binding the digits. Upstream
(`dedukun/relative-motions.yazi`) is dead: `a603d9e`, 2025-07-09, is its HEAD
and nothing has landed since, so a pin buys nothing. Meanwhile yazi 26 **removed
`ya.mgr_emit`**, which the plugin is built on — nil, not deprecated-but-working,
and a plugin calling it dies with no notification and nothing under
`YAZI_LOG=debug`. So the copy under
`dot_config/yazi/plugins/relative-motions.yazi/` is tracked, MIT LICENSE beside
it, carrying two patches; its header has the measurements and how to re-diff
against upstream. The first is mechanical (`ya.mgr_emit(` -> `ya.emit(`, 26
sites). The second drops the **tab commands** from the plugin's candidate list:
a count hands the keyboard to the plugin, so yazi's own binding never sees the
key, and upstream claimed `t L H w W < > ~` — each colliding with what its key
does bare. `2w` was `tab_close` by index while bare `w` is the task manager, so
a stale count closed a tab with no prompt and no message (measured, three tabs
to two). `{count}gt` is kept and is now the only counted tab command; it
survives the cut because its `t` is read from DIRECTION_KEYS after a `g`.

Two things that shape any future plugin work here. **A `ya pkg` entry and a
tracked copy are alternatives, not partners** — dropping the `[[plugin.deps]]`
block is what stops `ya pkg upgrade` reaching the vendored tree, and it was
checked by running one and finding the checksum unmoved. And **chezmoi ignores
hierarchically**: a negation on the leaf alone fails with "parent directory not
in source state", so `.chezmoiignore` names the directory and its parent too.
With those three lines `chezmoi add` takes relative-motions and still refuses
compress.yazi — measured both ways.

The other lesson is about where a fix can live. **`init.lua` and plugins are
separate Lua environments**: a global assigned in `init.lua` reads back as `nil`
inside a plugin, measured with a probe. So a shim in config cannot repair a
plugin's use of a removed API — patching the plugin's own source is the only
route, which is what forced the vendoring rather than a one-liner.

`keymap.toml` binds compress to `c a` — yazi's `c` is the copy-something prefix
(c, C, d, D, f, n, all "copy the path or the name", read off the which-key
popup rather than assumed), so `a` was free under it. The digits relative-motions
takes were free in the same way: measured against a stock config on 26.9.1, all
ten leave the pane unchanged and none is a silent prefix, so nothing of yazi's
own is displaced. compress prompts for the output name and takes the format from
the extension you type. Measured on 26.9.1: `sub.zip` from a hovered directory,
`both.7z` and `all.tar.zst` from a two-file selection, each verified by listing
the archive afterwards. Every key in that file is under `prepend_keymap`, which
merges — a bare `keys = [...]` replaces yazi's whole default set for that
section, which is the usual way a keymap file silently loses navigation.

`keymap.toml` is a **template** now, and `gt` is why. yazi's "go to trash bin"
resolves to `trash:///@//` and fails there with "Operation not permitted" — macOS
TCC, not yazi, since a terminal without Full Disk Access cannot read `~/.Trash`
at all and plain `ls ~/.Trash` gives the same error. That is also the answer to
why `d` looks broken: `d` **trashes and works** (measured under `$HOME` and
under `/private/tmp`, no error either time, and the confirm takes `y` and
`<Enter>` alike) — what is missing is any way to see the result. On macOS `gt`
is handed to Finder instead, which holds the entitlement the terminal does not,
so the trash is visible without granting the terminal anything. Linux keeps
yazi's own `gt`, where the trash is an ordinary readable directory.

`d`/`D` is left as yazi ships it: trash on the unshifted key, permanent delete
on the capital. It is the one case pair here that survives keymaps.md's rule,
and the ordering is already right — the reflexive key is the recoverable one.

The rest of that audit went the other way. `y`/`Y` was copy/cancel and `x`/`X`
cut/cancel — the "on/off partner" the rule names, twice over, with two keys
bound to one action — and `j`/`J`, `k`/`K` moved the cursor and scrolled the
*preview pane*, a different pane rather than a wider scope. Cancel-yank is on
`u` now, preview scrolling on `<C-e>`/`<C-y>`, and whoosh's bookmarks on vim's
`m`/`'` with management under `b`, which pushed linemode from `m` to `i`.

Taking a preset *away* is the part with a trap. `prepend_keymap` only adds, so a
default needs `noop`, a virtual action yazi added for exactly this (CHANGELOG
#1882). The trap is that an **unknown command is silently ignored too** — a
bogus string in `run` errors neither at startup nor on press — so a key going
quiet is not evidence that `noop` did it. Both halves were measured: with `Y` on
noop a yank survives the keypress and still pastes, and with `u` it does not.

Extraction needed no configuration at all: `Enter` on an archive already
extracts it, and it does not clobber — a second extract of `sub.zip` beside an
existing `sub/` produced `sub_1/`. Both halves go through `7zz`, which nothing
declares: `brew deps yazi` is empty, so `bootstrap.sh` installs `sevenzip`
explicitly and the verification pass checks for the binary.

`~/.config/mermaid/puppeteer.json` is there so that `mmdc` can find a browser at
all. snacks.image renders a ```mermaid fence inline in markdown, in kitty, by
converting it to a PNG with mermaid-cli first — and mermaid-cli draws by driving
a headless Chrome through puppeteer, which pins the copy it wants to the exact
version it was built against. The brew bottle ships no browser, so a bare `mmdc`
exits 1 with "Could not find chrome-headless-shell (ver. 152.0.7977.54)".

`{"channel": "chrome"}` is the answer to that, and it is chosen over the obvious
`npx puppeteer browsers install`: puppeteer then resolves the *installed* Google
Chrome by its well-known path, which is stable across Chrome's own updates,
needs no ~150MB download beside the three chromiums already in
`~/.cache/puppeteer`, and re-pins nothing when mermaid-cli is upgraded. It is
also the portable spelling — the same key works on Linux, where an
`executablePath` would have forced a template. Measured: 1.7s for a four-node
flowchart, against a hard failure without it.

`plugins/snacks.lua` passes it with `-p`, guarded on the file existing, because
`-p` naming a missing file is itself a hard error in mmdc. Only mmdc ever reads
that file and nothing writes it, so this is the gmuse case rather than the btop
one: no `chezmoi re-add` in the workflow. snacks needs `image` *named* in its
opts — it is one of the `needs_setup` modules, where an `enabled` flag alone is
not enough — and needs nothing from kitty or tmux, because it runs
`tmux set -p allow-passthrough all` on the pane itself.

The other two lines in that block are both about size. `doc.max_height = 20`
is a sharpness fix as much as a fitting one: snacks sizes an image as
`px / dpi * 96 * scale`, mmdc writes 72dpi, and the `-s {scale}` snacks passed
mmdc had *already* rendered at that scale — so the default 40 rows asked kitty
to stretch a 587x790 chart over the whole window. 20 rows puts that chart at
34x20 cells, within a cell of its own pixels. Capping the height is enough
because `fit` keeps the aspect ratio, and the clamp that bites is always the
vertical one. `convert.notify = true` is there because the alternative to a
message is nothing at all: a failed convert leaves no image and no clue.

What makes any of it render in a session `dev` built is `SNACKS_KITTY=1`, set
in `dot_zshenv` — see the comment there. Without it snacks never learns it is
in kitty, because `new-session` starts nvim in a detached session and tmux
answers no terminal query from a pane nobody is watching.

## Mail

Proton Mail, read in **NeoMutt** and scripted with **himalaya**, both through
**Proton Mail Bridge** on localhost (IMAP 1143, SMTP 1025). Proton speaks no
IMAP itself; Bridge decrypts locally and serves it, and needs a paid plan.
Laptop only for now, set up 2026-10-24. How everything reaches Bridge —
plain-text loopback, Bridge's own password, the `proton-bridge` keychain entry
— is written up once, at the top of `dot_config/isyncrc.tmpl`.

NeoMutt does not read Bridge directly. **mbsync** (isync, `~/.config/isyncrc`)
mirrors it into `~/.local/share/mail/proton`, and NeoMutt reads that maildir,
re-reading the open folder every 30s. mbsync runs from a launchd agent every
2m, client open or not
(`private_Library/private_LaunchAgents/local.mbsync-proton.plist.tmpl`,
loaded by `run_onchange_after_load-mbsync-agent.sh.tmpl` whenever the plist
changes; errors only, to `~/Library/Logs/mbsync-proton.log`). The agent runs
`~/bin/mail-sync`, which also raises a macOS notification when Bridge stops
answering on 1143, again when it is back, and when a sync fails three runs in a
row for another reason — on changes only, from two state files in
`$XDG_STATE_HOME/mail-sync`. That exists because Bridge quit cleanly one
evening (2026-10-24, nothing in its log saying why) and the first sign was a
send failing the next day. Each path was run: a dead port (`MAIL_SYNC_PORT`,
scratch `MAIL_SYNC_STATE`) notified once over two runs, the real port then
notified the recovery and synced rc 0, and a stubbed failing mbsync notified
on the third failure only. To sync now,
`launchctl kickstart gui/$(id -u)/local.mbsync-proton` rather than running
mbsync by hand: two mbsyncs at once collide — forced side by side, one of each
pair failed with "channel ... is locked" — and launchd runs one instance at a
time (a kickstart during a run left the run count at +1, rc 0). himalaya goes
straight to Bridge, so Claude's changes are live on Proton and reach the
maildir on the next sync. The first sync was 2271 messages, 915M, 14s; an
incremental one with nothing new, 0.17s.

A local maildir rather than IMAP because Bridge's IMAP has no SORT extension,
and a client that sorts server-side cannot sort it at all: aerc's `:sort`
answered "Sorting is not available for this backend", and the inbox sat in
Bridge's sync order.

**The Gmail archive** (2026-10-24) is a Google Takeout export converted to a
maildir at `~/.local/share/mail/gmail-archive/` — 35,808 messages, 2009 to
today, 7.8G; local only and read-only, nothing syncs it. Spam and Trash (1,116)
were dropped, message bytes copied unchanged, file dates set to the mail's
date, read/starred carried as flags. Gmail's labels became notmuch tags under
their own names, plus `gmail` on every message (`tag:gmail tag:"Product
Serial"`); Unread/Starred/Opened were not made tags, since they are flags.
Tagging used notmuch's message identity, and 34 messages exist in both
sources, so with `synchronize_flags` a tag change on one of those renames the
Proton copy too — checked after tagging: no Proton file gained or lost a
flag. The original export was deleted once the archive was converted and
backed up; Gmail still has everything. Gmail's filters and blocked list are
on the NAS in `records/gmail-settings/`.

**The maildir is backed up to the NAS, encrypted** (2026-10-24):
`~/bin/mail-backup` runs restic daily at 03:30 from launchd over all of
`~/.local/share/mail` (Proton and the Gmail archive; 8.4 GiB as 6.4G on the NAS)
(`local.mail-backup`; a run missed asleep happens on wake), to
`sftp:asnas:/volume1/Backups/mail-restic` — SFTP rather than the Finder SMB
mount, which may not be mounted at 03:30. SSH to asnas works with an empty
environment (`env -i`), i.e. without an agent, which is what launchd gives it.
Keeps 7 daily, 8 weekly, 24 monthly. The password is the keychain item
`restic-mail`, generated and never printed, and **must also live in Bitwarden**:
a repository only the laptop can open does not survive the laptop. Measured on
the first run (24s, through the agent): 701 MiB of mail became 513M on the NAS,
`restic check` clean, a restored folder byte-identical, and no file in the
repository containing the string `Subject:`. notmuch's index is not backed
up; `notmuch new` rebuilds it in seconds.

**`~/bin/mail-attachments`** copies the attachments worth keeping onto the
NAS, run by hand (never scheduled): camera photos to
`Media/Photos/From email/<year>/`, ebooks to `Media/Books/`, documents to
`records/documents/<category>/`, other large images, audio and leftovers to
`records/images|audio-video|files/`. Dry run unless `--write`; it skips any
content already under those folders, so a rerun only adds what is new
(measured: from empty it wrote 315 files, a second run 0, and against the real
NAS after the first export, 0). A photo is a JPEG with camera EXIF over
100 KB — what separates pictures from the logos and pixels in HTML mail. The
sender→category map is `~/.config/mail-attachments/categories.json`, **not
tracked** because the domains name doctors and family; a reference copy is on
the NAS in `records/`. Without it documents fall back to "From people" /
"Other". It needs both NAS shares mounted, and says so if they are not.
`--mail ~/.local/share/mail/gmail-archive` points it at the Gmail archive and
`--only photo` (or `ebook`, `document`, …) limits the kinds: that pass added
728 photos from 2009-2024, 799 in all. HEIC is a photo by name as well as by
content type, and a `.HEIC` that is really a JPEG — 7 of the archive's 8,
iPhones converting on send — is saved as `.jpg`. The archive's documents went
in at 2,881 (3,085 in all): the category map grew a "Research & Academia"
entry matched by parent domain and by suffix (`.edu`, `.ac.uk`, …), a
`labels` map read from `X-Gmail-Labels` (Contracts), and `self_addresses`
for "Sent by me"; a label wins over "Sent by me".

Two run-time lessons, both now in the script. **Output is not the job**: a
`--write` piped into `head -1` died of BrokenPipeError part-way through, so
printing now stops on a closed pipe while writing carries on. **Don't re-read
the NAS to dedupe**: hashing every destination file over SMB (Media/Books, the
photos) dominated each run, so the hashes live in
`~/.local/state/mail-attachments/saved.sha256`, appended as files are written;
`--rescan` rebuilds it (292s once). A Proton dry run went from minutes to 8s;
a Gmail one is 105s, now almost all of it parsing 7.8G of mail.

**The maildir is decrypted mail on disk**, which is why it waited for
FileVault (`fdesetup status` said Off when this started). Spotlight had
indexed none of it a few minutes after the first sync — no text content, zero
`mdfind` hits — which is the point of the hidden path; not re-checked since.
`All Mail` and `Starred` are excluded from sync (duplicates of everything, and
of the F flag).

**Proton's model, and what the local copy does with it.** On Proton a message
lives in exactly one folder (Inbox, Archive, Sent, Trash) and carries any
number of labels — one message, Gmail-style, not copies. Archive is the
container for everything filed, the counterpart of Gmail's "All Mail minus the
Inbox". IMAP has no labels, so Bridge presents each as a folder under
`Labels/`, and the maildir holds one file per label: a message with three
labels is three files locally, kept consistent by the sync.

**What a maildir operation becomes on Proton** was measured on throwaway
messages before Expunge was switched on, and neomuttrc is built around it:

| on the maildir | on Proton after `mbsync` |
| --- | --- |
| move between folders (Archive, Trash) | a move, single copy |
| copy into `Labels/x` | label added, message stays put |
| delete inside `Labels/x` | that label removed |
| move a label copy to Trash (`d` in `Labels/x`) | the message trashed, single copy |
| delete in Inbox or Archive | **in no folder at all** — only All Mail shows it |

So in NeoMutt `$trash` is set in every folder: `d` is a move to Trash
everywhere, label folders included. Labels have their own keys — `+` opens the
copy prompt at `+Labels/`, and `-` pipes the message to `~/bin/mail-unlabel`,
which finds its copies under `Labels/` by Message-ID, asks which label to
remove and deletes that one copy. (`d` inside a label folder used to *remove
the label*, through a folder-hook unsetting `$trash`; one key meaning two
things was the problem.) Measured on a throwaway Proton message in the Inbox
and labelled Cooking: `d` + `$` inside Cooking left it in Trash only — out of
the Inbox and the label, All Mail unchanged — and the next sync dropped the
local Inbox copy. Archive (`a`, a save to `+Archive`) left no copy in Trash. Deletes and moves are marked first and carried out on `$`,
a folder change or quit. A message orphaned the last way is recovered by
copying it out of All Mail (`himalaya message copy --from "All Mail" --to
Trash <id>` did it). `Remove None` keeps a vanished local folder from being
propagated as a deletion; a mass delete of *files* would still sync — as
orphaning in Inbox, and as a permanent delete in Trash (see below).

**Emptying Trash in Proton races the sync.** Emptied while deletes made in
NeoMutt were still on their way up, the two crossed: Proton dropped messages
mbsync was mid-way through filing in Trash, and mbsync was left with 17 local
Trash files it kept trying to upload ("far side refuses to store message N
from near side", and once Bridge's "failed to unlabel messages: Message does
not exist"). Nothing was lost — every one was gone from Proton, deleted as
intended — but left alone mbsync might have re-uploaded them. Recovered by
unloading the agent (`launchctl bootout gui/$(id -u)/local.mbsync-proton`),
moving the stale local files aside, and `launchctl bootstrap` again; afterwards
every folder's count matched Proton. So: `$` in NeoMutt, let a sync pass (2m),
then empty Trash.

**Deleting inside Trash is a permanent delete**, so Trash can be emptied from
NeoMutt: `c +Trash`, `D ~A`, `$`. Measured on two throwaway messages added to
an otherwise empty Trash: `d` on one and `D ~A` on the other each unlinked the
local file (NeoMutt does not trash from Trash), and after a sync each was gone
from Proton's All Mail as well, which dropped by one each time. All Mail lags:
for up to a minute the deleted message still showed there, looking exactly
like an orphan, before it went.

**Labels, measured during the 2026-10-24 clean-up:**

- Copying files into a local `Labels/<x>` folder and syncing labels the
  existing message — 530 copies at once left All Mail unchanged (+1, a new
  arrival), and every label's count on Proton matched what was copied.
- `himalaya imap create "Labels/<x>"` makes a label, `&` in the name included
  (it came back as `Labels/Finance & Tax`, not modified-UTF-7 noise). It fails
  if the label exists.
- `himalaya imap delete "Labels/<x>"` removes **only the label**, despite
  himalaya's own "every message it holds go for good": a throwaway message
  labelled into a throwaway label was still in Trash and All Mail afterwards.
- Proton then has the folder and the local copy does not, which `Remove None`
  reports as an error on every sync. `mbsync --remove-near proton` cleans up
  once — but refuses a local box that is not empty, so a label that held mail
  has to be removed by hand (after checking its messages exist in a real
  folder), then `--remove-near` run again to drop the sync state.
- **Labels do not nest.** A `/` in a label name is a character, not a level:
  the Gmail import's `[Imap]/Drafts` came through Bridge as one flat label,
  `Labels/[Imap]\/Drafts`. A sub-topic is a second label beside the first —
  `SDMX` (44 messages, found with a notmuch query over every folder) sits
  beside `Work & Research`, and the filter applies both.
- New mail is labelled by a Sieve filter in Proton ("Auto-label by sender"),
  generated from the same sender lists. It is not tracked here — its domain
  lists name doctors and family — and its reference copy is on the NAS
  (`/Volumes/Backups/records/`).

**NeoMutt, measured on throwaway maildirs:**

- **It refreshes the open folder**: a message dropped into the open Inbox
  appeared on its own within the 30s `mail_check`/`timeout`. `timeout`
  defaults to 600, which would make that ten minutes.
- **Colours are terminal numbers, not hex.** `#rrggbb` needs a direct-colour
  TERM (xterm-direct); under tmux every hex line failed with "color not
  supported by term". So ANSI colour numbers instead: 0-15 are exact Frappé via
  kitty, and only mauve (183) and overlay1 (103) come from the 256 cube.
- **Rows are numbered (`%C`) and typing a number jumps there** — no binding
  needed: the first digit opens "Jump to message:", Enter goes. Measured on a
  20-message maildir (5, 12, 20, 1). There is no relative numbering.
- **Threads open collapsed** (`folder-hook . 'push <collapse-all>'`), the row
  showing the hidden count (`%M`) and drawn bold blue when the thread holds
  anything unread (`~v~(~U)`). Folder hopping is the index's `J`/`K` alone.
- **`Ctrl-J`/`Ctrl-K` are `J`/`K`** in both index and pager. `Ctrl-J` is the
  line-feed byte, which NeoMutt names `<Enter>` and bound to open the thread;
  the Enter key sends `<Return>`, a separate binding, so taking `\Cj` left
  Enter working (measured: Enter opened the thread, `Ctrl-J` changed folder).
  `Ctrl-K` was `extract-keys` (PGP).
- **Reading a thread stays inside it** (2026-10-25). Stock, `Enter` expanded
  the thread for good and `J` ran on past its end into the next row. Now
  `Enter` is `<limit-current-thread><display-message>` and the pager's `q`/`i`
  are `<exit><limit>all<enter><collapse-all>`. Three things were measured to
  get there, on a scratch maildir of a 3-thread, a single and a 2-thread:
  - `collapse-all` is a **toggle of a folder-wide flag**, not "collapse": run
    after a thread had been opened it expanded everything. But `<limit>all`
    re-expands every thread anyway, so after it the toggle always collapses —
    four opens in a row came back folded, cursor on the thread just read.
  - **`next-entry` with nowhere to go leaves the pager** — silently, into the
    still-limited index. `d` and `a` do the same on the thread's last
    message. So those pager keys end in a reopen.
  - **The pager has no `display-message`.** Left over at the end of a macro it
    reported "Key is not bound" and *swallowed the next key pressed* — a `d`
    after `J` deleted nothing. The reopen is `display-toggle-weed` twice: a
    no-op in the pager, "open with headers as usual" in the index.
  Testing `d`/`a` needs `folder` *and* `trash` overridden: `trash = "+Trash"`
  is expanded when the config loads, so resetting `folder` afterwards still
  left it pointing at the real Proton Trash.
- **`q` in the index asks before quitting** (`quit = ask-no`): the prompt's
  default is to stay, so a reflexive `q` then Enter does nothing. It covers
  `x` (exit without saving) too, and the pager's `q` still just goes back —
  all four measured in a throwaway session.
- **Attachments are viewed through mailcap**, which before covered only HTML,
  so an image showed as raw bytes. `image/*` now runs `~/bin/mail-image`
  (needsterminal): `kitten icat` draws it inline, through tmux by switching on
  passthrough for its own pane as snacks.nvim does, and the script waits for
  Enter itself and clears the image — icat's `--hold` prompt did not answer to
  Enter in a test session. `application/pdf` runs `~/bin/mail-open`, and `o`
  in the attachment list pipes any attachment to it; it copies the file out of
  NeoMutt's temp file first (deleted the moment the command returns, while
  `open` returns at once) and names piped data with `file --extension`. Tested
  in a detached session up to the pixels: kitty's placeholder cells appeared,
  one Enter came back, the PDF landed in `~/.cache/mail-open`. Seeing the image
  needs a real kitty window. `wait_key = no`, or leaving an image took two
  keys; the cost is that `!` and `|` output no longer waits.
- **Speed, measured on a full scratch copy of the maildir** (2026-10-25), from
  keypress to screen: startup 0.23s, opening Archive (880 messages) 0.08s,
  folder switches and `+` about 0.01s. A sync (`$` after `a` or `d`) was 1.09s
  — all of it `sleep_time`, a one-second pause after "Mailbox synced"; at 0 it
  is 0.04s. Lag felt earlier came on top of that from heavy disk and network
  jobs running alongside (the Gmail conversion, indexing, backups, NAS writes).
  When timing, read the *total* in `Msgs:29/36` — with threads collapsed the
  first number is visible rows, and it does not move when one message goes.
- **Address completion is `Ctrl-T`** (`query_command` = `~/bin/mail-contacts`),
  over everything notmuch indexes: recipients of mail you sent (Proton Sent
  plus Gmail's Sent tag, so no address of yours is written into the script)
  ranked by count ×10, then senders, minus no-reply and list addresses. Listing
  recipients takes notmuch ~3s, so the 2,163 addresses are cached in
  `~/.cache/mail-contacts.json` for a day; a lookup is 0.03s. `alias_sort =
  unsorted` keeps that ranking — the default sorted by name and put the
  address written to 1,155 times sixth of seven. `Tab` stays alias completion,
  since it is folder completion too.
- **`Ctrl-Y` completes too, and needed the tty fixed first.** It mirrors
  blink.cmp — `Ctrl-N`/`Ctrl-P`/`Ctrl-Y`/`Ctrl-E` in the query list, all four
  unbound there by default (read off `:bind query` and `:bind generic`). But
  bound alone it did nothing, at the prompt or in the list: macOS's tty has
  `dsusp = ^Y` (`stty -a` in a tmux pane), and NeoMutt keeps the tty's signal
  characters, so the key never arrived. `dot_zshrc` runs `stty dsusp undef` on
  macOS; with that, `amy` `Ctrl-Y` `Ctrl-N` `Ctrl-Y` put the second match in
  To:. nvim was never affected — it puts the tty in raw mode.
- **The saved searches are notmuch named queries** (`[query]` in its config,
  `notmuch://?query=query:starred`). Written into the URL, their slashes
  (`path:proton/**`) indented the rows: `sidebar_folder_indent` counts every
  `/` in a mailbox's path, so the three-slash search sat 6 spaces in and the
  two-slash one 4. Named, both line up with Inbox and give the same counts.
- **`gx` lists a message's links** through urlscan (brew; in `bootstrap.sh`),
  piped the raw message so it reads every MIME part: on a test message it
  found the plain part's link once (`--dedupe`) and both HTML hrefs, the long
  one with `&amp;` decoded. The list shortens long links on screen, but
  the whole link is what gets opened — checked by swapping the browser for
  `--run-safe 'tee …' --pipe`. Opening goes through Python's `webbrowser`,
  which is the macOS opener when `$BROWSER` is unset.
  Its stock palette was unreadable here: the selected row is bright white on
  blue (`97;44`), which kitty's Frappé draws as light text on light blue.
  `dot_config/urlscan/config.json` replaces it with ANSI names matching
  NeoMutt — the selection on `black` (surface1), as NeoMutt's indicator, read
  back from `capture-pane -e` as `40`. The file replaces *all* the built-in
  palettes, so `p` has only this one to cycle to.
- **`,` files a message: label and archive in one key** (`,r` Receipts …,
  generated per label by a template `range`). Measured on a scratch tree laid
  out like the real one, then once on Proton with a self-sent message, which
  ended in Archive with the label and nowhere else (All Mail 1). Four things
  shaped it:
  - **Archive only from the Inbox.** folder-hooks give every folder the
    label-only macro, then `/proton/INBOX$` replaces it; in Archive `,r` added
    the label and left one copy.
  - **Batches need `auto_tag`**, set and unset inside the macro: `;` reaches only
    a macro's first function. With it, two tagged messages were both labelled
    and archived and the one under the cursor was left alone.
  - **Space in a prompt is `mailbox-cycle`**, so a macro typing "Finance & Tax"
    copied nowhere — and the archive half still ran, filing without the label.
    Spaces are typed `<quote-char> `.
  - **A driving harness can eat the keys**: an error such as "You are on the
    last message" (a `t` on the last row) flushed the `,f` sent after it.
- **`a` in the compose screen attaches through yazi** (`~/bin/mail-attach-pick`):
  yazi's `--chooser-file`, turned into a `push "<attach-file>…<enter>…"` line
  that the macro sources, since NeoMutt takes no files from outside. Two
  traps, both hit: yazi writes the list **with no final newline**, and a bare
  `while read` drops that line — so every single-file pick attached nothing;
  and a space in the path must go in as `<quote-char> ` (Space is
  mailbox-cycle in that prompt too). Measured in a compose screen opened with
  `editor=true abort_unmodified=no`: a spaced path attached whole, two files
  marked with Space both attached, `q` in yazi attached nothing.
- **`gg` cost mutt's `g`** (group-reply), since binding it makes `g` a prefix;
  reply-all is `gr`.
- **HTML is rendered by lynx, not w3m** (`dot_config/neomutt/executable_html-filter`,
  called from `mailcap`). Much HTML mail is laid out in nested tables, and w3m
  boxes every table that declares a border: 247 of 959 HTML-only messages came
  out boxed, the worst with ~560 box-drawing characters. lynx flattened the six
  worst to 0-2 at about the same length; pandoc's plain output was worse than
  w3m. w3m cannot be told not to — `display_borders` only *adds* borders. The
  script also drops lines of zero-width preheader padding. It is a script
  rather than a mailcap one-liner because mailcap gives `%` and `\` meanings
  the perl filter needs.
- `sidebar_delim_chars` is `/` alone: the default `/.` cut the label
  `gmail.com 04-11-2024 08:21` down to `com 04-11-2024 08:21`.
- The label list is built at startup by a shell command over `Labels/`, quoted
  and escaped (spaces, `&`, a backslash). On a maildir with no `Labels/` it
  fails with "mailboxes: too few arguments" — harmless on the real one, which
  always has it, but it is why a bare throwaway maildir greets you with an
  error.
- Sending is configured (Bridge SMTP, `ssl_force_tls` off for the loopback)
  but has not been tried.

**Threads stop at the folder edge** in a folder view, because they are built
from In-Reply-To/References among the messages in that folder. A reply to your
own reply names a parent in Sent, so it has no match in Inbox; NeoMutt joins it
by subject instead (the `*` in `└*>` marks such a guessed link).

**notmuch** (2026-10-24) indexes all the mail under `~/.local/share/mail` —
the Proton maildir in `proton/` and the Gmail archive in `gmail-archive/` — so
searches and threads cross folders: in a search, that same thread came back
4/4 with your reply from Sent in place, linked by headers. One index, not one
per source, because NeoMutt opens a single notmuch database; folder names
carry the prefix as a result (`folder:proton/INBOX`). The index is
`~/.local/share/notmuch/mail`, apart from the mail so mbsync never sees it;
37,722 files became 37,003 messages in 75s. The launchd agent runs
`notmuch new` after each sync and keeps mbsync's exit status. In NeoMutt, `\`
searches both, and the sidebar's two saved searches (named queries in its
config) are Proton only (`path:proton/**`), since the archive keeps receiving Gmail's forwarded
copies.

- **`nm_default_url` names the database**, not the maildir: pointed at the
  maildir, a search opened "(no mailbox)".
- **`d` in a search result moved the file to Trash**, as in a folder — no
  deleted tag, no T flag — so results need no special guarding.
- **Never tag `deleted`.** `synchronize_flags` maps it to the T flag, and with
  mbsync's Expunge Both that is a permanent delete on Proton. Unread, flagged
  and replied do mirror usefully: a message marked unread on Proton showed as
  `tag:unread` after one agent run.
- `new.tags` is empty and `exclude_tags` too: `unread` comes from the missing
  S flag on its own (measured on a throwaway index — an unseen file and one in
  `new/` both got it, a seen one did not), and Trash/Spam are folders here.

**aerc was tried first and removed** (2026-10-24), after a day side by side
with NeoMutt on the same maildir. What decided it, all measured on 0.22.0: it
does not refresh the open maildir folder (the sidebar count moves, the list
does not); `:archive flat` leaves an empty `Archive` directory in its working
directory; a user `binds.conf` replaces the defaults wholesale; it reads
`~/Library/Preferences/aerc` on macOS whatever its man page says; and a user
`aerc.conf` drops the shipped filters. Its project is younger and more
broadly maintained (51 authors in a year to NeoMutt's 31) but much less active
(220 commits to 1,125). NeoMutt's caveat is the reverse: ~90% of its commits
are one maintainer's.

The address is `proton_email` in the untracked chezmoi data, asked by
`.chezmoi.toml.tmpl`, and the NeoMutt, himalaya and mbsync configs are
templates reading it. That is for switching mail on per machine, not for
privacy — the same address is already public as `dot_gitconfig`'s email and
the author of most commits. `.chezmoiignore` skips the mail configs on Linux
or wherever `proton_email` is empty. Bridge's own sign-in is the one step
nothing here can do.

**himalaya**, measured while building it:

- **2.x is a different program from 1.x**: `imap.server` and `imap.sasl.*`
  replaced `backend.*`, and the verbs were renamed. Its README's Proton block
  is the reference. Even one account needs `default = true`, and over IMAP only
  INBOX gets a role, hence the `mailbox.alias.*` lines.
- **`message read` does not mark a message seen** unless given `--seen`, so
  reading is genuinely read-only.
- **Bridge files sent mail in Sent itself.** A test sent to self with
  `--no-save` showed up once in Sent, once in Inbox, and once in All Mail. So
  nothing here saves its own copy — no NeoMutt `$record`, no himalaya
  `message.send.save-copy` — or every sent message would be doubled.
- **What sends mail is wider than `message send`**: `compose`, `reply` and
  `forward` take `--send`, and since 2.0 so does `message add`. `imap` and
  `smtp` are raw passthroughs that can do anything, expunge included. The
  permission rules in `dot_claude/settings.json` gate all of them.

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
- **`working` has three writers**, two of them tool events, which is what
  re-arms the latch mid-turn. (This said four and three; counted from
  `dot_claude/settings.json`, it is `UserPromptSubmit`, `PreToolUse` and
  `PostToolUse` — the tracked and live copies agree.) They fire on every tool call, so the script is on
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
  this holds standalone features: `files` (the explorer ↔ oil ↔ yazi handoffs),
  `float` (maximize a snacks float, which snacks.win itself cannot), `folds`
  (LSP/treesitter fold dispatch), `guides` (the `<leader>?` picker), `just`
  (run recipes into a tmux console window), `plv` (the table viewer handoff),
  `scratch`, `markdown_checkbox`, `markdown_outline`, `rules_lookup`.
- `plugins/` — one file per plugin or plugin group, lazy-loaded.
- `guides/` — hand-written markdown reference cards, opened with `<leader>?`.
  Twenty-five of them, indexed at the end of `keymaps.md`; `gf` or `<CR>` follows a
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
git (gitsigns, codediff), GitHub (octo), Rust, Scheme (conjure, paredit).

**`:Lazy restore` does not rebuild treesitter parsers; run `:TSUpdate` after
it.** The lockfile pins nvim-treesitter, and its queries move with it because
they are not copies: every `site/queries/<lang>` is a *symlink* into the
plugin's own `runtime/queries/<lang>`, so a query cannot go stale independently
of the pin (checked — all eighteen resolve inside the current checkout; the
symlinks' own mtimes vary and mean nothing). The compiled parsers are the
asymmetry, and the only thing the check below has to cover: they are real files
in `~/.local/share/nvim/site/parser/`, outside the plugin, and only
`build = ":TSUpdate"` rebuilds them — which lazy runs on `:Lazy update` on the
machine doing the updating, not on the machine that later pulls the lockfile.
Measured 2026-09-18: the plugin was restored here on 2026-09-11 and six parsers
(`diff`, `json`, `luadoc`, `markdown`, `markdown_inline`, `racket`) stayed at
their July revisions. The symptom was markdown-specific and only in files with
a ```` ```diff ```` fence: the new `diff/highlights.scm` names a
`change` node the old grammar lacks, so every redraw logged
`Invalid node type "change"` to `~/.local/state/nvim/nvim.log`, from
treesitter-context. Nothing reached the screen, and `:messages` was empty. The
check is to compare `site/parser-info/*.revision` against the `revision` each
language has in the plugin's `parsers.lua`, and to compare them as *strings*:
not every pin is a SHA. Ten of them are version tags, and `python`'s `v0.25.0`
is the one that lands here, so a check asserting 40 hex characters calls it
stale every time. `:checkhealth nvim-treesitter` does *not* do this comparison
(its `health.lua` never reads a revision), and `:TSUpdate` is idempotent, so
run it rather than wonder.

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
- **Target throwaway sessions exactly: `-t '=name:'`.** A bare `-t nv`, sent
  from inside a tmux session, was resolved as a prefix of the window `nvim` in
  the *current* session before any session name was tried — and test keystrokes
  went into the user's own nvim (2026-10-24). Confirm with
  `tmux display-message -p -t '=name:' '#S'` before sending anything.
- **A killed session can leave its program running.** `tmux kill-session`
  hangs up the pane, and aerc ignored the hangup: 42 test instances outlived
  their sessions by most of a day, invisible, before anyone noticed. Quit the
  program inside first, or `pgrep` for it after teardown and kill what is left.
  NeoMutt did exit; it is a per-program thing, so check rather than assume.
- **Check colours from the escapes, not the look.** `capture-pane -e` keeps
  the SGR sequences, so `^[[38;5;183m` on a row is mauve and `^[[1m` is bold —
  a check on the attribute itself rather than a screenshot.
- **Suspect the probe before the config.** Every one of those was the harness.
  A window-picking loop landed in a snacks notification window; a `list-keys`
  check loaded the user's own config and reported it as a tmux default.

Interactive overlays *are* drivable, contrary to an earlier note in this repo:
flash's jump labels, which-key popups and codediff's panes all render into the
terminal grid, so `capture-pane` reads the label out and it can be sent straight
back. The exception is `vim.fn.input()` under noice — invisible to
`capture-pane` but still receiving keys, so a blank capture there is not
evidence of a broken prompt.

**`v:errmsg` after opening a markdown buffer reads `E31: No such mapping`, and
that is expected.** lazy.nvim deletes a filetype-scoped key before setting it
(`lazy/core/handler/keys.lua`, `_del`), inside a `pcall` — but a caught Vim
error still lands in `v:errmsg`. The first markdown buffer has nothing to
delete, so zk's `<leader>zb` and `<leader>zl` (normal and visual) each fail
the delete and are then mapped correctly, buffer-locally (measured
2026-10-17: traced through `nvim_buf_del_keymap`, then read back with
`maparg`). With no file open `v:errmsg` stays empty. Nothing reaches the
screen or `:messages`. So a startup probe should baseline `v:errmsg` before
opening the buffer, or discount this one message, rather than read it as a
regression; it has been mistaken for one once.

**Images are testable detached only because `dot_zshenv` forces the answer.**
snacks detects kitty by writing `\033[>q` through tmux passthrough and waiting
for the reply, and tmux drops passthrough output from a pane nobody is looking
at — so without `SNACKS_KITTY=1`, a detached session or a background window
reports `name = "tmux"` with `supported` unset and places nothing, and it does
not recover, because `doc._attach` latches `b:snacks_image_attached` *before* it
tests support. With the override the geometry is computed normally wherever the
pane lives, so read the result from the extmark rather than the screen:
`nvim_buf_get_extmarks` on the `snacks.image` namespace returns `virt_lines`
full of kitty placeholder characters, which `capture-pane` does not show. Only
the pixels need a window you are actually looking at.

That was three false negatives before it was understood — each one a probe that
raced the tmux client rather than a config that did not work.

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
`tmux`, `nvim`, `fzf`, `fd`, `ripgrep` (`rg`), `eza`, `bat`, `yazi`, `broot`,
`btop`, `zoxide`, `atuin`, `starship`, `direnv`, `lazygit`,
`zk`, `just`, `git-cliff`, `tree-sitter`, `uv` (Python), `racket` (the REPL
behind both conjure clients — added 2026-09-29, having been installed by hand
here while absent from this list; `ensure_command racket minimal-racket`, not
`brew_install`, because the **cask** `racket` is the full distribution and the
**formula** is `minimal-racket` answering to the old name, so asking for the
formula would have put a second, smaller racket beside the full one).
`mermaid-cli` (`mmdc`) is there for the markdown diagrams above; it pulls in
`node`, and leans on a Google Chrome that nothing here installs.

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
