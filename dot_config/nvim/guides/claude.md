# Claude Code

Claude shows up in three places here, and they answer different questions:

| Where              | Answers                                  |
| ------------------ | ---------------------------------------- |
| a float in nvim    | "talk to it about this code"             |
| the tmux status bar | "is it done **over there**"              |
| its own statusline | "what model, what branch, how much left" |

The float's mechanics — how it hides, how `Esc` is handed over, and `<C-x>` for
scrollback — are on [Floats](floats.md). The bar glyphs are on
[Tmux](tmux.md). This card is the keys and the machinery that connects them.

## Keys

| Key            | Does                             |
| -------------- | -------------------------------- |
| `<C-/>`        | toggle the float (`<C-_>` too)   |
| `<leader>ac`   | the same toggle                  |
| `<leader>af`   | focus it                         |
| `<leader>az`   | toggle width, full ↔ side        |
| `<leader>ab`   | add the current buffer           |
| `<leader>as`   | send the selection (visual)      |
| `<leader>ar`   | resume a session                 |
| `<leader>al`   | continue the last session        |
| `<leader>am`   | select model                     |
| `<leader>aa`   | accept the proposed diff         |
| `<leader>ax`   | reject it                        |
| `<leader>a?`   | server status                    |

`<C-/>` and `<C-_>` are bound to the same thing because terminals disagree
about which byte `Ctrl-/` sends.

`<leader>aa` / `<leader>ax` are the pair worth learning: Claude's edits arrive
as a diff you accept or reject, rather than being written under you.

## The state feedback loop

This is the part that is not obvious, and it is why a run finishing in another
tmux session is visible without switching to it.

```
Claude fires a hook
  -> ~/bin/claude-tmux-state <state>
     -> one file per tmux session under $XDG_STATE_HOME/claude-tmux
        -> ~/bin/claude-tmux-status  counts them into ⣿ ⣤ ⣀
        -> dev                       shows [a] [q] [i] per session
```

Six hooks are wired in `~/.claude/settings.json`:

| Hook               | Writes    |
| ------------------ | --------- |
| `UserPromptSubmit` | `working` |
| `PreToolUse`       | `working` |
| `PostToolUse`      | `working` |
| `Stop`             | `idle`    |
| `Notification`     | `waiting` |
| `SessionEnd`       | `clear`   |

**It is a latch, not a sample — nothing polls.** `status-interval 5` re-renders
a file that only hooks write, so a *missed edge is permanent rather than late*.
That was the bug this carried for its first month: `working` was written by
`UserPromptSubmit` alone, so once a permission prompt was answered nothing
re-armed it and the bar read "wants you" for the rest of the turn. Caught with a
session showing `waiting` from the previous evening while its pane read
`✳ Combobulating… (34m 20s)`.

**Three writers of `working`, two of them tool events**, and that is the fix:
the tool events re-arm the latch mid-turn. They fire on every tool call, so the
script is on a hot path — one `tmux display-message` and one small write. The
write is deliberately unconditional rather than skipped when the file already
says `working`, because the mtime is then the last tool call: a heartbeat, and
the thing that made the original bug findable.

Long autonomous stretches need that. Re-invocation by background-task output
fires no `UserPromptSubmit` at all, and one session here went fifteen hours on
four prompts.

### Two things that look like bugs

**`PostToolUse` does not fire when a tool errors** — measured on a `git status`
that exited 128. `PreToolUse` is the only per-tool event to rely on.

**`SessionEnd` fires on a clean exit only.** A Claude killed under a surviving
tmux session would leave `working` on disk for ever. So liveness is treated as a
*process* question rather than a session one: the status script walks `ppid`
from every process named exactly `claude` up to a `pane_pid`. The walk has to go
several levels — claudecode.nvim's instance sits under `nvim --embed` under the
pane's `nvim`.

### Why `grep` and not `jq`

`Notification` carries a kind, and the kind is load-bearing: `idle_prompt` means
"finished, and you have not come back", which is what green already says, so
pink `⣤` is left for the kinds genuinely blocked on you. It is read with `grep`
rather than `jq` because jq is a dependency of nothing else here, is absent from
`bootstrap.sh`, and merely happens to sit in `/usr/bin` on macOS.

## Its own statusline

`~/.claude/statusline-command.sh`, named from `settings.json`. It reads one JSON
blob on stdin and prints one line: model, git branch, effort level, context
window used, and both rate-limit windows. Fields that are absent are simply
omitted, so a short payload prints a short line.

One jq call, not one per field — this redraws constantly, and an earlier version
forked jq six times per refresh. The fields are joined with an ASCII unit
separator rather than tabs, because `read` collapses runs of whitespace and
empty fields would shift every later value.

## The file with two writers

**`~/.claude/settings.json` is rewritten by Claude Code itself** whenever a
setting changes from inside the tool — model, theme, effort level, enabled
plugins. chezmoi holds its own copy, so whichever wrote last wins and a change
made in the tool is reverted by the next `chezmoi apply`.

```
chezmoi re-add ~/.claude/settings.json     # before applying
```

Same shape as karabiner and btop — see CLAUDE.md for the full list.

Editing that file from a script makes you a **third** writer, so keep the
serialiser faithful: Python's `json.dump` defaults to `ensure_ascii=True`, which
turns the em dashes in `autoMode.environment` into `\uXXXX` escapes. The file
still parses and still means the same thing, but every one of those lines then
shows up in `chezmoi diff` and in the next diff Claude Code's own writer
produces.

## Scrollback in the float

`CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` is set in `dot_zshenv`, and it is what
makes `<C-x>` then `<C-u>` able to scroll Claude's output at all. In the
alternate screen nothing scrolls off, so nvim's `scrollback` has nothing to
record. The mouse wheel keeps working either way, which is what makes the fault
confusing rather than obvious.

## See also

- [Floats](floats.md) — the window it lives in, and `<C-x>`
- [Tmux](tmux.md) — where `⣿ ⣤ ⣀` is rendered
- [Shell](shell.md) — `dot_zshenv`, where the alt-screen variable is set
