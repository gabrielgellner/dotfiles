# Scrollback in nvim

On the laptop, kitty's copy mode is **nvim itself**. `prefix + [` takes
whatever a kitty window has printed — Claude's answer, a test run, a log — and
opens it in an nvim overlay over that window, with your whole config: motions,
`/`, flash, text objects, the clipboard. That is the job tmux's vi copy mode
did, with the real editor in place of an imitation of one. The plugin is
kitty-scrollback.nvim; `prefix` is `Ctrl-A`, as on [Tmux](tmux.md).

It works in *any* kitty window, including one running a TUI. Claude's output
reaches kitty's scrollback only because `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1`
is set in `dot_zshenv` — the same reason `<C-x>` can scroll it in the float
(see [Claude Code](claude.md)).

## Getting in and out

| Key          | Does                                                  |
| ------------ | ----------------------------------------------------- |
| `prefix + [` | the whole scrollback, cursor at the bottom            |
| `prefix + g` | only the **last command's** output                    |
| `q`          | quit, back to the window as it was — in the paste window, closes only that |
| `<C-c>`      | quit everything, from any mode, paste window or not   |

Neither pastes anything; only `:w`, `<S-CR>` and `<C-CR>` do. A yank is still
on the clipboard after you quit.

`prefix + g` uses kitty's shell integration to know where the last command's
output starts and ends, so it is the one for "copy that error" in a console
tab. It means a *shell* command — the boundaries come from the shell's
prompt marks — so in Claude's window use `prefix + [`.

The cursor starts at the end, which is where the thing you want usually is —
so search **backwards**: `?error` rather than `/error`, and `n` keeps going up.

## The two ways out with text

Everything below starts with a selection or a yank, and ends one of two ways:

| From             | Key           | Does                                          |
| ---------------- | ------------- | --------------------------------------------- |
| visual           | `<leader>y`   | copy to the clipboard **and close**           |
| visual           | `<S-CR>`      | paste the selection into the window, and close |
| normal           | `<leader>yy`  | copy the line, and close                      |
| normal           | `<leader>y{motion}` | copy what the motion covers, and close  |
| normal           | `yy`, `y{motion}` | copy, and open the **paste window**       |

**`<leader>y` is "I'm done":** the overlay closes the moment the clipboard has
it, and you are back where you were with the text ready for `p` in nvim or
`Cmd-V` anywhere. It is the one to reach for nine times out of ten.

**`<S-CR>` sends it back** into the window you opened this over, as if typed —
but *not run*. Into a shell that leaves the lines at the prompt; into Claude it
is a draft you can still edit before pressing Enter.

### Plain `y` is different, on purpose

A plain `y` copies to the clipboard as usual (`clipboard=unnamedplus`), but
does **not** close: it opens a small **paste window** at the bottom holding what
you yanked, with its keys in a footer. Each further `y` appends to it. That is a
scratch buffer for *building* something out of pieces of the scrollback — edit
it like any buffer, then send it:

| In the paste window | Does                                     |
| ------------------- | ---------------------------------------- |
| `:w` or `<S-CR>`    | paste it into the window, not run        |
| `<C-CR>`            | paste it **and press Enter**             |
| `g?`                | hide or show the footer                  |
| `q`                 | close the paste window, keep scrolling   |
| `<C-c>`             | close it and the overlay, pasting nothing |

`<C-CR>` *runs* what it sends (by the plugin's own table; not tried here).
`:w` and `<S-CR>` were tried and never do, which makes them the safe habit.

## Recipes

**Copy Claude's code block into your editor.** In Claude's window:
`prefix + [`, `?def ` (or whatever starts it), `V`, move to the end of the
block — `}` jumps a paragraph — `<leader>y`. Back in nvim, `p`.

**Copy an error from a build.** In the console: `prefix + g`, `?error`, `V`,
`j` to taste, `<leader>y`.

**Write a long prompt in nvim.** In Claude's window: `prefix + [`, `yy` on any
line to open the paste window (or yank the bit of Claude's answer you want to
quote), then write the prompt there, `:w`. It lands in Claude's input box
unsent; read it over, Enter.

**Re-run part of an old command.** In a shell: `prefix + [`, `?git`, select
the command, `<S-CR>`, edit at the prompt.

## Things that bite

- **`y` and `<leader>y` are not the same key with and without a prefix.** One
  stays open with a paste window, the other closes. If the overlay did not go
  away, you pressed the first.
- **Over nvim it is one screen.** nvim draws on the terminal's alternate
  screen, which keeps no history, so `prefix + [` on an nvim window — a Claude
  *float* included — shows only what is visible (measured: 41 lines of a
  42-row window). Use it on Claude's own tab, where a 120-line answer was all
  there; inside nvim, `<C-x>` and scrolling the terminal buffer is the way.
- **It is a snapshot.** What is shown is the scrollback at the moment you
  pressed `prefix + [`; output arriving afterwards is not added. Quit and
  reopen to see it.
- **The colours are kept, the program is not.** It is a plain buffer with the
  escape codes rendered, so Claude's keys mean nothing here — `q` quits this
  nvim, not Claude.
- **A mouse selection still copies on its own** (`copy_on_select`), without
  any of this. For one word, the mouse is quicker.

## How it is wired

kitty, not nvim, starts it: `mux.conf` maps the keys to the plugin's kitten,
named by its path inside lazy's checkout, and the kitten opens a fresh `nvim`
as an overlay and fires `User KittyScrollbackLaunch`, the event
`lua/plugins/kitty-scrollback.lua` loads on. So it costs your normal nvim
nothing — and if lazy's copy of the plugin goes, the key goes with it until
`:Lazy restore` puts it back.

## Under tmux

Where tmux is the multiplexer the key is the same and the idea is the same,
but it is a small script rather than the plugin: `prefix + [` runs
`~/bin/tmux-scrollback`, which captures the pane's history and opens it in
nvim in a popup over the pane. The keys are a subset, set in
`lua/config/scrollback.lua`:

| From   | Key                 | Does                                        |
| ------ | ------------------- | ------------------------------------------- |
| visual | `<leader>y`         | copy to the clipboard **and close**         |
| normal | `<leader>yy`        | copy the line, and close                    |
| normal | `<leader>y{motion}` | copy what the motion covers, and close      |
| visual | `<CR>`              | paste the selection into the pane, not run, and close |
| normal | `y…`                | copy, stay open                             |
| normal | `q`                 | quit                                        |

What differs from kitty:

- **No colour.** It is the plain text, and that is the trade for long lines
  coming back whole: a line the terminal wrapped is one line here (a
  407-character line yanked as 407), where keeping the colours would have
  put a newline at every wrap.
- **No `prefix + g`.** tmux 3.2a keeps no record of where a command's output
  starts. `?❯` finds the previous prompt.
- **No paste window.** A plain `y` just yanks; `<CR>` on a selection is the
  one way to send text back, and it is `<CR>` because tmux gives nvim the
  same byte for `<S-CR>`.
- **A border.** tmux 3.2a cannot draw a popup without one, so the text is one
  cell in from where it was.

tmux's own copy mode is still there on the mouse wheel and `prefix + PageUp`.

## See also

- [Tmux](tmux.md) — the other `prefix` keys under kitty
- [Claude Code](claude.md) — why Claude's output is in the scrollback at all
- [Floats](floats.md) — `<C-x>`, the same idea inside an nvim float
