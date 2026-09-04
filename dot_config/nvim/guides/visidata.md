# VisiData (column layout)

`vd file.jsonl` is how a jsonl file gets read here — a sheet of rows and typed
columns instead of a wall of braces. Everything below is about making that
sheet _fit_, which is most of what you do to a new one.

Columns arrive at `options.default_width`, which is **20**, whatever the data
is. So the first thing almost any sheet needs is a resize.

## Width

| Key   | Longname            | Does                                                         |
| ----- | ------------------- | ------------------------------------------------------------ |
| `_`   | `resize-col-max`    | toggle current column between full width and the default     |
| `z_`  | `resize-col-input`  | prompt `set width=`, prefilled with the current width        |
| `z-`  | `resize-col-half`   | halve the current column                                     |
| `g_`  | `resize-cols-max`   | every visible column to full; if all are full already, reset |
| `gz_` | `resize-cols-input` | prompt once, apply that width to every visible column        |

`_` is the one worth muscle memory, and it is a **toggle**: full width, then
back to 20. Not "wider" — pressing it twice leaves the sheet where it started,
so it costs nothing to look. `g_` toggles the same way across the whole sheet,
which is the fastest way to see everything and then get the shape back.

`z_` prefills the prompt with the width the column has now, so it is a nudge
rather than a guess.

## Hiding

| Key  | Longname            | Does                                                        |
| ---- | ------------------- | ----------------------------------------------------------- |
| `-`  | `hide-col`          | hide the current column                                     |
| `g-` | `hide-uniform-cols` | hide every column that has one distinct value over all rows |
| `gv` | `unhide-cols`       | unhide everything hidden on this sheet                      |

Hiding **is** resizing: a hidden column is one with width `0`, which is why it
sits in the same family and why the Columns sheet below can hide by typing a
zero. `gv` brings one back at its _full_ width rather than at 20 — the width it
restores is `abs(width or 0) or getMaxWidth(rows)`.

`g-` is the one to reach for on machine-generated data, where half the columns
are the same constant on every row. It says what it hid, one status line per
column.

## Row height

The same idea one axis over, for the columns holding paragraphs:

| Key   | Longname              | Does                                           |
| ----- | --------------------- | ---------------------------------------------- |
| `v`   | `toggle-multiline`    | toggle rows between one line and `4`           |
| `zv`  | `resize-height-input` | prompt for a height, apply to all visible rows |
| `gzv` | `resize-height-max`   | grow to whatever the current row needs         |

## What the prefixes mean

The two tables have the same shape twice, which is worth reading as a rule
rather than as ten separate keys:

- **no prefix** — the current column
- **`g`** — all visible columns
- **`z`** — the second variant of the same idea (take a number, halve it)
- **`gz`** — that variant, across all visible columns

It is not nvim's `g`, but it is just as consistent: here `g` is the plural.

## Several at once — the Columns sheet

`C` opens the current sheet's columns **as rows**, one row per column, with
`width` as an editable integer field. Its own sidebar puts it plainly: _"Edit
values on this sheet to change the appearance of the source sheet."_

Two things this can do that the keys above cannot:

- `0` in the `width` field hides, any number unhides — typed, not toggled.
- Select rows with `s`, then `ge` (`setcol-input`) sets the field for **all of
  them** at once. Selecting two columns and typing `12` widened both, including
  one that had been hidden.

`height` is beside it, and so are `type`, `fmtstr` and `name` — the sheet is
the general answer to "change several columns' anything".

## Mouse

Press on a column separator, drag sideways, release. `go-mouse-1` records which
separator and the x on press; `check-drag` on release adds the delta to that
column's width (`mouse.py:drag_button1`).

It only fires when the press landed on a separator, and only on a column whose
width is already above zero — so a drag cannot un-hide anything.

## Where the real list is

`z Ctrl+H` lists every command available on the current sheet with its
keystrokes, generated from the live binding table. That is the authority; this
card is the dozen keys worth knowing before you get there. `g Ctrl+H` opens the
man page, and `Space` takes a longname directly, so `resize-cols-input` works
without the `gz_`.

The colours are this config's, not visidata's: `~/.visidatarc` registers a
Catppuccin Frappé theme and selects it. `theme-input` on the View menu switches
to one of the packaged themes and `theme-default` puts visidata's own back —
neither touches the file.
