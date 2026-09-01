# Music (gmuse in a tmux popup)

`prefix + Ctrl-P` opens gmuse in a floating popup from **any** tmux session, and
the same key inside the popup closes it. The point is not having to remember
which session the music is in — there is no "music window" to navigate back to.

The player keeps running when the popup closes. Closing the popup detaches a
client; it does not stop playback or quit gmuse.

## Getting in and out

| Key               | Does                                            |
| ----------------- | ----------------------------------------------- |
| `prefix + Ctrl-P` | open the popup — from any session               |
| `prefix + Ctrl-P` | inside the popup: close it, music keeps playing |
| `q`               | quit gmuse itself — the session goes with it    |

`prefix` is `Ctrl-A`. It sits beside `prefix + Ctrl-J`, which opens the `dev`
session picker — both overlays, reached the same way.

> **Why not `prefix + Ctrl-M`.** `Ctrl-M` _is_ Enter — both send `0x0D`, the way
> `Ctrl-I` is Tab and `Ctrl-[` is Esc — and `prefix + Enter` is already the
> `dev` picker. `Ctrl-J` escapes this only because it is a different byte,
> `0x0A`.

## One player, one session

`new-session -A` attaches the `music` session if it is there and creates it
only if it is not, so pressing the key twice never gives you two players
fighting over the audio device. gmuse holds no lock of its own, so this binding
is the whole of that guarantee — a `gmuse` started by hand in an ordinary
window is a second instance, and both will write
`~/.local/state/gmuse/session.toml` and the audit log.

The session is called `music`, not `gmuse`, because `dev` names sessions after
project directories and `~/dev/gmuse` is one of them. `-s gmuse` made this key
attach the player's *source* session instead of starting the player.

It is hidden from the `dev` picker (`UTILITY_SESSIONS` in `bin/executable_dev`)
so a stray `ctrl-x` there cannot kill the music. To end it deliberately: `q` in
the popup, or `tmux kill-session -t music` from anywhere.

## The keys

Not listed here, on purpose. gmuse's **view 7** is its own keymap guide, and it
is _generated from the live binding table_ rather than written — a `:bind` at
runtime shows up in it, so there is no second copy of the keymap to fall out of
step. `7gt` gets there (views are nvim tab style: a count and `gt`), and the
other six entries in that view are prose guides on moving around, the library
tree, playlists, finding things, saved rules and format strings.

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
it keeps its state in `$XDG_STATE_HOME/gmuse` and its library index in
`$XDG_CACHE_HOME/gmuse`, both untracked — so unlike `settings.json` or
`karabiner.json` there is no `re-add` dance before an apply.

`gmuse` on PATH is a symlink: `~/.local/bin/gmuse` points into
`~/dev/gmuse/target/release/gmuse`, which is the artifact `just ui` already
builds. So a rebuild is the install, with no `cargo install` step. Two
consequences worth knowing:

- The running player keeps the old inode and plays on through a rebuild. The
  new build is what the **next** launch gets, so `q` and reopen is how you pick
  up a change.
- `cargo clean` makes gmuse _absent_ rather than broken — a dangling symlink
  fails `command -v` — and the popup then opens and closes again with nothing
  in it. `cargo build --release` puts it back.

That symlink is machine-local and deliberately untracked: `~/dev/gmuse` exists
on the laptop and not on the Linux box, where a tracked link would only dangle.
