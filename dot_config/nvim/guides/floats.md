# Another program in a window

Four things here are not Neovim and not the shell, but a whole other program
running in a window over the top of your work: **plv** for tables, **lazygit**,
**Claude**, and **gmuse** for music. They are worth one guide rather than four
because the awkwardness is the same in every case — the program inside is a TUI
that wants the entire keyboard, so every key you need for the *window* has to
be taken away from the program in it.

Three of the four are Neovim floats. gmuse is not, and that difference is the
first thing to know.

## Getting in

| Key            | Opens                                            |
| -------------- | ------------------------------------------------ |
| `<leader>tt`   | plv on the current file (`T` in the explorer)    |
| `<leader>gg`   | lazygit                                          |
| `<C-/>`        | Claude — the same key toggles it away again      |
| `prefix + C-p` | gmuse, from any tmux session                     |

`prefix` is `Ctrl-A`, and that last row is the odd one out: gmuse is a **tmux
popup**, not a Neovim float. It is not inside any editor, so none of the Neovim
keys below reach it — see [Music](music.md). It is listed here because from the
keyboard it feels like the same thing, and knowing it is not saves you pressing
`<C-x>` at it.

## Taking control of a float

The program owns the keyboard, so Neovim gets one key back:

| Key     | Does                                                |
| ------- | --------------------------------------------------- |
| `<C-x>` | leave terminal mode — now it is an ordinary buffer  |
| `<C-q>` | send the quit character to the program itself       |

`<C-x>` is the important one, and it is the answer to "how do I scroll this",
"how do I yank out of it" and "why is my keymap not working". After it you are
in normal mode on the float's buffer: motions, `y`, search and every buffer-local
mapping work as usual. `i` goes back in.

`<C-x>` was picked because it does *nothing* in zsh — `undefined-key` — and is
unbound in tmux, so pressing it in the wrong pane is harmless. The cost is that
the program inside never receives it. See `config/keymaps.lua`.

## Making one bigger

| Key     | Does                                        |
| ------- | ------------------------------------------- |
| `<M-m>` | fill the screen, and back — plv and lazygit |

Same key the pickers use for maximize, so one keystroke means "make this
bigger" everywhere. plv opens at 90% of the editor, which is a column short for
a wide table; a lazygit diff is wider than that more often than not.

> **If `<M-m>` does nothing, press `<C-x>` first.** Measured on this machine:
> the mapping is bound in both normal and terminal mode on the float's buffer,
> and it fires in normal mode — but the terminal-mode half does not match the
> key as kitty's keyboard protocol delivers it. `<C-x>` then `<M-m>` always
> works, and is a fair habit anyway: it is the same "take control first" that
> everything else in this guide needs.
>
> The tell is what `<C-v>` shows in insert mode. `<M-m>` there means the
> kitty protocol is in play; `^[m` means the legacy escape-prefixed form. Neovim
> keeps those two distinct, which is why `claudecode.lua` binds `<C-/>` *and*
> `<C-_>` for one key. Turning on `extended-keys` in `dot_tmux.conf` — commented
> out there today — is the change that would settle it globally, and it would
> change encodings for everything else at the same time.

Alt is **left** option only. Right option is Karabiner's command key, so it
never reaches the terminal as alt at all (`dot_config/kitty/kitty.conf`).

## Getting out

Each program quits its own way, and the window follows:

| Program | Leave it                                        |
| ------- | ----------------------------------------------- |
| plv     | `q` — float closes                              |
| lazygit | `q` — float closes                              |
| Claude  | `<C-/>` sends it away; the session keeps running |
| gmuse   | `prefix + C-p` hides it, `q` quits the player    |

plv and lazygit close on a clean exit because snacks' `auto_close` checks the
exit status. A **non-zero** exit deliberately leaves the float open with the
error still in it — which is the whole diagnosis without leaving Neovim, and
matters most for plv, the one binary here that gets rebuilt while Neovim is
open.

Claude is the exception: `Esc` is handed over to it entirely rather than being
used to leave insert mode, because single-Esc is interrupt and double-Esc is
rewind and neither has a substitute on its side. That is why `<C-x>` exists as
the way out, and why `term_normal = false` is set for that float.
