# Music (gmuse in a tmux popup)

`prefix + Ctrl-P` opens gmuse in a floating popup from **any** tmux session, and
the same key inside the popup closes it. The point is not having to remember
which session the music is in — there is no "music window" to navigate back to.

**Playback outlives all of it.** gmuse is a client/server pair: an `engine`
daemon holds the audio device, and what the popup shows is a *view* that asks it
over a socket. Closing the popup detaches a tmux client, and quitting the view
leaves the music playing.

## Getting in and out

| Key               | Does                                            |
| ----------------- | ----------------------------------------------- |
| `prefix + Ctrl-P` | open the popup — from any session               |
| `prefix + Ctrl-P` | inside the popup: close it, music keeps playing |
| `q`               | quit the **view** — the music keeps playing     |

`q` quits without asking. While a `:` or `/` prompt is open it is text, not the
binding — gmuse has a test for exactly that.

**`q` no longer stops the music, and this card used to say it did.** It quits
the view; the engine is a daemon and carries on. gmuse's own help puts it
plainly — the TUI "leaves what is playing alone when it starts and when it
exits". To actually stop it:

```
gmuse ctl engine.shutdown
```

That is also what a change to the audio path needs before the next view will
pick up a new build.

`prefix` is `Ctrl-A`. It sits beside `prefix + Ctrl-J`, which opens the `dev`
session picker — both overlays, reached the same way.

> **Why not `prefix + Ctrl-M`.** `Ctrl-M` _is_ Enter — both send `0x0D`, the way
> `Ctrl-I` is Tab and `Ctrl-[` is Esc — and `prefix + Enter` is already the
> `dev` picker. `Ctrl-J` escapes this only because it is a different byte,
> `0x0A`.

## One engine, many views

**It is the engine that is single, not the view**, and this section used to
describe the wrong lock. Two views run side by side quite happily — neither
opens a device, neither takes a player lock — so a `gmuse` typed in an ordinary
window now attaches to the same engine instead of being refused.

What is "not twice" is the daemon. `engine.lock` sits beside the socket in
`$XDG_RUNTIME_DIR/gmuse/` — `$TMPDIR/gmuse/` on macOS, where there is no
`XDG_RUNTIME_DIR` — and a second engine exits rather than opening a second
device.

The old player lock still exists at `~/.local/state/gmuse/lock`, but only
`--no-attach` takes it, and the default path never does. Finding that file with
an old timestamp means nothing.

**The binding says where it is** — `new-session -A` attaches the `music` session
if it is there and creates it only if it is not, so the key takes you to the
running view rather than starting a second window of them. That is now the whole
of its job: it constrains the window, not the player.

The lock is an OS one rather than a pid file, which is why nothing has to be
cleaned up: the kernel drops it when the process ends _however_ it ends. A
crash, `kill -9`, the terminal going away — the next engine starts fine, and a
leftover file holding a dead pid is not a lock.

`--no-lock` starts anyway. `--no-attach` goes back to the old shape — a player
in this process, one device, playback that ends when the program does — and is
worth keeping only for measuring the audio path.

### What two views can and cannot collide over

Narrower than it looks, and narrower than it used to be: since the split the
views do not play anything, so most of this stopped being a question.

| state                              | two views                                 |
| ---------------------------------- | ----------------------------------------- |
| ratings and plays (`events-*.log`) | **safe** — appends never tear a line      |
| the library cache                  | safe — a whole-file write, regenerable    |
| `session.toml`                     | the **engine's**, not a race between views |
| the audio device                   | the engine's alone — a view opens none    |

Ratings were never at risk: an event is one short append, so two writers
interleave whole lines. The append-only design that lets two _machines_ share a
library makes two _processes_ safe too.

`session.toml` used to be the one you would notice — saved on quit, so whichever
instance you quit last decided what the next launch restored. That moved to the
engine with everything else about playback.

Not the audit log, though — that one is opt-in (`--log`, or `GMUSE_LOG`), and
the popup runs bare `gmuse`. "Disabled is the default: a player that writes to
disk during every session without being asked is a surprise," as `audit.rs`
puts it. `just listen` is the recipe that turns it on, and used to be the most
likely way you ended up with a second instance — now it is the most likely way
you meet the lock.

The session is called `music`, not `gmuse`, because `dev` names sessions after
project directories and `~/dev/gmuse` is one of them. `-s gmuse` made this key
attach the player's _source_ session instead of starting the player.

It is hidden from the `dev` picker (`UTILITY_SESSIONS` in `bin/executable_dev`)
so a stray `ctrl-x` there cannot kill the music. To end it deliberately: `q` in
the popup, or `tmux kill-session -t music` from anywhere.

## The keys

Not listed here, on purpose. gmuse's **view 7** is its guides, and the last of
the seven — **Index** — is a keymap _generated from the live binding table_
rather than written, so a `:bind` at runtime shows up in it and there is no
second copy to fall out of step. `7gt` gets there (views are nvim tab style: a
count and `gt`). The other six are prose: Moving around, The library tree,
Building playlists, Finding things, Rules that make lists, Writing the lines.

A copy of that table here would be a third copy, and the one guaranteed to be
wrong first.

The short version of what to expect: the keymap is **nvim's, not cmus's**.
Navigation is `j`/`k`, `gg`/`G`, `Ctrl-D`/`Ctrl-U`; folds are vim's whole `z`
vocabulary, where `zr`/`zm` expand to albums and collapse to artists; `{`/`}`
move artist to artist; `dd` removes a row. Transport lives behind `<leader>` —
`<leader>x` play, `<leader>c` pause, `<leader>z`/`<leader>b` previous and next
— which is why the letters look like cmus's but the reach does not.

## Config and the binary

`~/.config/gmuse/config.toml` is tracked by chezmoi. gmuse never writes to it —
`config.rs` is deserialize-only, with no `Serialize` anywhere and no write path
to that file at all. Its mutable state goes elsewhere: session, machine id and
the old player lock to `$XDG_STATE_HOME/gmuse`, the engine's socket and
`engine.lock` to `$XDG_RUNTIME_DIR/gmuse` (`$TMPDIR/gmuse` on macOS, which has
no `XDG_RUNTIME_DIR`), the library index to `$XDG_CACHE_HOME/gmuse`, and
ratings and play history to the library's own `data_dir` (`~/MusicLibrary/.gmuse`
here), so they travel with the music. All three are untracked, so unlike
`settings.json` or `karabiner.json` there is no `re-add` dance before an apply.

`gmuse` on PATH is a symlink: `~/.local/bin/gmuse` points into
`~/dev/gmuse/target/release/gmuse`, which is the artifact `just ui` already
builds. So a rebuild is the install, with no `cargo install` step. Two
consequences worth knowing:

- The running processes keep the old inode and play on through a rebuild. The
  new build is what the **next** launch gets — and since the split there are two
  launches to think about. `q` and reopen picks up a new **view**; a change to
  the audio path needs `gmuse ctl engine.shutdown` first, because the engine is
  a daemon and the popup closing does not end it.
- `cargo clean` makes gmuse _absent_ rather than broken — a dangling symlink
  fails `command -v` — and the popup then opens and closes again with nothing
  in it. `cargo build --release` puts it back.

That symlink is machine-local and deliberately untracked: `~/dev/gmuse` exists
on the laptop and not on the Linux box, where a tracked link would only dangle.
