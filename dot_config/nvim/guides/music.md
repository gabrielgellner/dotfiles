# Music (cmus in a tmux popup)

`prefix + Ctrl-P` opens cmus in a floating popup from **any** tmux session, and
the same key inside the popup closes it. The point is not having to remember
which session the music is in — there is no "music window" to navigate back to.

The player keeps running when the popup closes. Closing the popup detaches a
client; it does not stop playback or quit cmus.

## Getting in and out

| Key               | Does                                            |
| ----------------- | ----------------------------------------------- |
| `prefix + Ctrl-P` | open the popup — from any session               |
| `prefix + Ctrl-P` | inside the popup: close it, music keeps playing |
| `q`               | quit cmus itself (asks first)                   |

`prefix` is `Ctrl-A`. It sits beside `prefix + Ctrl-J`, which opens the `dev`
session picker — both overlays, reached the same way.

> **Why not `prefix + Ctrl-M`.** `Ctrl-M` _is_ Enter — both send `0x0D`, the way
> `Ctrl-I` is Tab and `Ctrl-[` is Esc — and `prefix + Enter` is already the
> `dev` picker. `Ctrl-J` escapes this only because it is a different byte,
> `0x0A`.

## Playback

The five that matter are one row on the keyboard: `z x c v b`.

| Key       | Does                           |
| --------- | ------------------------------ |
| `x`       | play                           |
| `c`       | pause / unpause                |
| `v`       | stop                           |
| `z` / `b` | previous / next track          |
| `Z` / `B` | previous / next **album**      |
| `.` / `,` | seek forward / back one minute |
| `l` / `h` | seek forward / back 5 seconds  |

## Volume

| Key       | Does              |
| --------- | ----------------- |
| `+` / `-` | ±10%              |
| `]` / `}` | right channel ±1% |
| `[` / `{` | left channel ±1%  |

## Moving around

cmus is two panes side by side in the library view: artists on the left, tracks
on the right.

| Key                 | Does                                         |
| ------------------- | -------------------------------------------- |
| `Tab`               | **switch between the artist and track pane** |
| `j` / `k`           | down / up                                    |
| `g` / `G`           | top / bottom                                 |
| `Ctrl-D` / `Ctrl-U` | half page down / up                          |
| `Enter`             | play the selected track                      |
| `/` then `n`/`N`    | search, next / previous match                |

`Tab` is the one to learn first — without it the left pane is all you can reach,
which makes the library look broken rather than half-focused.

## Views

| Key | View                               |
| --- | ---------------------------------- |
| `1` | library, as a tree by artist       |
| `2` | library, as a flat sorted list     |
| `3` | playlists                          |
| `4` | play queue                         |
| `5` | file browser — add music from disk |
| `6` | filters                            |
| `7` | settings                           |

## Queue and playlists

| Key | Does                                   |
| --- | -------------------------------------- |
| `e` | add selection to the **queue**         |
| `E` | add to the front of the queue          |
| `a` | add selection to the **library**       |
| `y` | add selection to a **playlist**        |
| `D` | remove selection from the current view |

## Modes

These four are the ones worth knowing, because they change what "next track"
means. The status line's right-hand side shows which are on.

| Key | Toggles                                            |
| --- | -------------------------------------------------- |
| `r` | repeat                                             |
| `s` | shuffle                                            |
| `C` | continue — keep playing after the current track    |
| `m` | aaa mode — confine playback to one artist or album |

## Config

Colours live in `~/.config/cmus/rc`, tracked by chezmoi, catppuccin frappe to
match everything else. That file is the one cmus never writes to — it saves its
own state, colours included, into `autosave` on exit, so a theme put anywhere
else is overwritten the first time you quit. `rc` is read _after_ `autosave`,
which is why the colours here survive. Nothing else in that directory is
tracked.

None of the keys above are rebound: they are all cmus defaults, so `man cmus` is
the full reference and this is only the part worth memorising.
