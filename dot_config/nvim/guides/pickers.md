# Pickers

Every list in this config is a `snacks.picker`: files, grep, diagnostics,
symbols, notifications, git. They share one set of keys, so learning the frame
once covers all of them.

Two windows, sometimes three. The **input** is where you land and where you
type. The **list** is the results. Most sources also show a **preview**.

## Getting text out

This is the part that is easy to miss: the pickers are not read-only. `<C-y>`
copies the current item to the system clipboard, from either window, in insert
or normal mode.

| Key      | Where                | Does                                    |
| -------- | -------------------- | --------------------------------------- |
| `<C-y>`  | input or list        | copy the current item to `+`            |
| `y`      | list only            | the same, when your hands are already there |

What lands in the clipboard is **the line as rendered**, not the internal item
text. That distinction matters: for several sources the internal `text` field is
a search haystack rather than a display string, and copying it gives you noise
like `1 /Users/you/very/long/path.lua lua`. So:

```
files          lua/config/keymaps.lua:1
grep           lua/config/autocmds.lua:187:4  -- 'autoread' is already on …
diagnostics    a probe diagnostic message   lua/config/keymaps.lua:3
```

Each of those is already in the shape you would paste into a message or a
commit. The picker stays open afterwards, so several items can be taken in a
row.

`+` explicitly, not the unnamed register. `clipboard=unnamedplus` makes an
ordinary yank reach the system clipboard, but that linkage does not apply to a
register written from Lua, and copying out of a picker is nearly always on the
way out of Neovim.

## Notifications, which do more

`<leader>fn` is the notification history, and it is the picker most likely to
hold something you want to send elsewhere — a stack trace, an LSP error, the
output of a failed format.

| Key     | Does                                                     |
| ------- | -------------------------------------------------------- |
| `<C-y>` | copy the **whole** message, not the truncated list line   |
| `<C-o>` | write the message to a file and `@`-mention it to Claude  |

Both override the generic key above, because a notification has something
better to offer than its one-line summary: the list collapses a multi-line
message onto one row, and `.msg` still holds all of it.

`<C-o>` exists because `ClaudeCodeSend` @-mentions a *file range* and never
ships raw text, so the message has to exist on disk before Claude can be
pointed at it. Each send gets its own timestamped file under `stdpath("state")`.

## Moving around

| Key         | Does                                              |
| ----------- | ------------------------------------------------- |
| `?`         | show every key this picker has — the real answer to "what can I do here" |
| `/`         | toggle focus between input and list               |
| `<Tab>`     | select the current item and move on (multi-select) |
| `<C-a>`     | select everything                                  |
| `<C-n>` `<C-p>` | next / previous without leaving insert        |

`?` is worth pressing once per source you use. Its list is long because it
includes every key the picker inherits, not just the interesting ones — but
anything source-specific shows up there and nowhere else.

Multi-select drives `<C-q>` (send to quickfix), not the copy keys: `<C-y>` and
`y` take the item under the cursor and ignore the selection.

## See also

- [completion.md](completion.md) — `<C-y>` also accepts a completion; same
  finger, different window
- [files.md](files.md) — the file pickers and the oil handoff
- [git.md](git.md) — the git sources, and `<leader>fw` as the way to chase a
  symbol out of a codediff review
