# Yazi

`y` opens it, and so does `yazi` — both are `yazi_lastdir` from `~/.zshrc`,
which is upstream's wrapper around `--cwd-file`. That wrapper is the whole
reason yazi is worth reaching for here rather than `cd`-ing by hand, so it is
what this card opens with.

`y` sits beside zoxide's `z` on purpose: `z` jumps when you know where you are
going, `y` browses when you do not.

## Leaving, and where the shell lands

| Key    | Yazi's own wording                        | What you get                        |
| ------ | ----------------------------------------- | ----------------------------------- |
| `q`    | Quit the process                          | shell follows you to where you were |
| `Q`    | Quit without outputting cwd-file          | shell stays where it started        |
| `<C-z>` | Suspend the process                      | back with `fg`, yazi where you left |
| `<C-c>` | Close the current tab, or quit if it's last | last tab quits like `q`           |

The middle column is quoted from `~`, because `Q`'s description names the
mechanism outright: yazi writes the directory you ended in to the file the
wrapper passed as `--cwd-file`, and `Q` is the one that declines to. Nothing
else distinguishes them.

So the loop is:

```
y              # browse from here
               # h j k l around, l into things
q              # shell is now *there*
git status     # ...do the terminal thing
y              # back in, at the new place
```

That is the drop-in/drop-out rhythm, and it is why `q` is the default exit
rather than a special one. Use `Q` when you went looking for something, found
it, and want your prompt left alone — reading someone else's tree, checking a
path, glancing at a sibling directory.

`<C-z>` is the third option and a different shape: yazi is still running, with
your selection and tabs intact, and `fg` returns to it. Better than `q` then
`y` when you are mid-selection and just need one command.

## Moving

| Key             | Does                                    |
| --------------- | --------------------------------------- |
| `h` `j` `k` `l` | parent / down / up / into               |
| `H` `L`         | back / forward through this tab's history |
| `gg` `G`        | top / bottom                            |
| `<C-u>` `<C-d>` | half page                               |
| `<C-b>` `<C-f>` | full page                               |
| `<C-e>` `<C-y>` | scroll the **preview** pane             |
| `.`             | toggle hidden files                     |
| `z`             | jump to a file/directory via **fzf**    |
| `Z`             | jump to a directory via **zoxide**      |
| `g<Space>`      | jump interactively                      |
| `gh` `gc` `gd`  | home / `~/.config` / `~/Downloads`      |

**`z` is fzf and `Z` is zoxide, which is the reverse of the shell outside.**
Out at the prompt `z` *is* zoxide; step into yazi and the same key is fzf. It
is the one binding here worth knowing before you need it, because both do
something plausible and neither errors.

**Counts work, and this card used to say they did not.** `3j`, `12k`, `10gg`
and `2h` all do what vim would do, from `relative-motions`, and the numbers down
the left of the listing are the hybrid nvim shows — absolute on the row you are
on, relative everywhere else. Read the number off the row you want and type it.

The old claim came with a reason attached — that `1`–`9` switch tabs — and the
reason was wrong too. On a stock 26.9.1, measured against an empty config, all
ten digits leave the pane unchanged and none of them is even a silent prefix.
They were simply unbound, which is what made them free to take. Tab switching is
`[` and `]` — see **Tabs** below.

`/` is still the better answer when you do not know how far down something is: a
listing is a column of names, and you always know what a file starts with.

Only `1`–`9` are bound. The plugin takes the keyboard after the first digit and
reads the rest itself, so `10j` works without `0` being a binding, and a bare
`0` stays free.

## Finding — four things, easily confused

| Key   | Does                                            | Scope                        |
| ----- | ----------------------------------------------- | ---------------------------- |
| `s`   | search files by name via `fd`                   | recursive, into a result set |
| `S`   | search files by content via `ripgrep`           | recursive, into a result set |
| `f`   | filter files                                    | narrows the listing in place |
| `/` `?` | find next / previous file                     | cursor moves within the dir  |

`/` is incremental and `n` / `N` step through matches afterwards. `f` is the
one to reach for by default: it narrows what is already in front of you rather
than building a virtual directory, so leaving it costs nothing and you never
lose your place.

Getting back out of `s` or `S` is where it bites. `<Esc>` cancels in priority
order — visual mode, then selection, then filter, then find, then search — so
if you selected something inside the results, the first press only clears the
selection and you need a second. `<C-s>` is bound by default to cancel the
search and nothing else, which is the unambiguous way out.

## Selecting, and moving files

| Key       | Does                             |
| --------- | -------------------------------- |
| `<Space>` | toggle selection, move down      |
| `v` `V`   | visual mode (set / unset)        |
| `<C-a>`   | select all in this directory     |
| `<C-r>`   | invert selection                 |
| `<Esc>`   | clear selection                  |

| Key       | Does                                              |
| --------- | ------------------------------------------------- |
| `y` `x`   | yank as copy / as cut                             |
| `p` `P`   | paste / paste overwriting                         |
| `u`       | cancel the pending yank                           |
| `-` `_`   | symlink the absolute / relative path of the yank  |
| `<C-->`   | hardlink the yank                                 |

**`u`, not `Y` or `X`.** Yazi ships cancel-yank on both capitals, which breaks
the rule in [keymap conventions](keymaps.md) twice over: a capital is meant to
be the *wider* version of its lowercase key, and `Y` against `y` is an on/off
partner instead — two keys, one action, neither of them a scope. Cancelling a
yank is undoing it, so it went to `u`, and `Y` and `X` are disabled rather than
left to mean something else.

Two rules make the difference between this being pleasant and being fiddly:

**`y` replaces the clipboard, it does not append.** Build the whole selection
first, then yank once. Yanking as you go throws away everything but the last.

**Selections accumulate across directories within a tab, and the clipboard is
global across tabs.** Mark two files here, walk into a sibling, mark three more
— the count in the status bar keeps climbing, and one `y` takes all five. Then
switch tabs and paste, because the clipboard crossed with you.

## Tabs

| Key     | Does                                        |
| ------- | ------------------------------------------- |
| `tt`    | create a tab in the current directory       |
| `tr`    | rename the current tab                      |
| `[` `]` | previous / next tab                         |
| `{` `}` | swap this tab with the previous / next      |
| `<C-c>` | close the tab, or quit if it is the last    |

**It is `tt`, not `t`** — `t` alone is a prefix, which is also why `tr` exists.

**There is no switch-by-index.** This card used to list `1`–`9` for it; yazi has
never bound them, and they are motion counts here now. A count does not combine
with the brackets either — `2]` moves nothing, the count is simply swallowed.

**A count does work on `H` and `L`, and changes what they mean.** Those keys are
directory history on their own, and tab movement with a number in front:

| Key         | Does                                      |
| ----------- | ----------------------------------------- |
| `H` `L`     | back / forward through this tab's history |
| `2H` `2L`   | jump two **tabs** left / right            |

Measured both ways: `2L` from the first of three tabs landed on the third, `2H`
took it back, while bare `L` stayed put and walked the history instead. It comes
from `relative-motions`, which claims the tab commands after a count.

**Which makes `2w` a trap worth knowing.** Bare `w` is the task manager; with a
count it is `tab_close` by index, so a stale count turns a glance at the tasks
into a closed tab — no prompt, no message. Measured: `2w` took three tabs to two
and said nothing.

Two tabs is the tool for shuffling files between distant directories: source in
one, destination in the other, mark and `y` in the first, `2` and `p` in the
second, `1` to come back with the cursor exactly where it was. Each tab keeps
its own directory, history and cursor.

## Trash, and the task manager

| Key | Does                              |
| --- | --------------------------------- |
| `d` | trash selected files (asks first) |
| `D` | permanently delete                |
| `gt` | open the Trash (Finder, on macOS) |
| `w` | show the task manager             |

Deletes, copies and moves all run as background tasks, and **the count in the
bottom-right is tasks still in flight** — not a file count. Inside `w`, `<Enter>`
inspects (which is where an error's actual text is), `x` cancels the highlighted
one, and `w` or `<Esc>` closes. There is no bulk clear: the list is in-memory
per process, so quitting yazi wipes it, which is the fastest fix for a screenful.

**`d` works. It is the *evidence* that is missing on macOS**, and that is worth
saying plainly because the key looks broken otherwise. `d` hands the file to the
system Trash and it does leave the listing — measured under `$HOME` and under
`/private/tmp`, no error either time, and the confirm takes `y` and `<Enter>`
alike. What you cannot do is look at the result: yazi's own `gt` went to the
`trash://` scheme and came back `Error: Operation not permitted (os error 1)`,
and `ls ~/.Trash` in the shell fails the same way. That is macOS TCC, not yazi —
the terminal has no Full Disk Access, so nothing launched from it can read the
Trash.

So `gt` is remapped here rather than left to fail. On macOS it runs
`open ~/.Trash` and Finder shows it, because Finder holds the entitlement the
terminal does not — the window comes up titled "Trash" while the same shell
still cannot list the directory. [keymap conventions](keymaps.md) says to hide a
key that can only error; handing it to something that works is better than
hiding it. On Linux the preset is kept, where the trash is an ordinary readable
directory.

Granting the terminal Full Disk Access would also fix it, and is not worth it:
the grant goes to the *terminal*, so every script, package postinstall and agent
run inside it inherits read access to Mail, Messages, browser data and Time
Machine — a wide, permanent capability traded for looking in the bin.

**`d` is trash and `D` is permanent, and they are deliberately not swapped.**
It is the one case pair yazi ships that survives the rule — "permanently" reads
as the wider version — and the ordering is already the right way round: the
reflexive, unshifted key is the recoverable one.

## Bookmarks, on vim's marks

| Key    | Does                                        |
| ------ | ------------------------------------------- |
| `m`    | mark **here** — prompts for a name, then a key |
| `'`    | jump to a mark                              |
| `bb`   | jump, picking from a list with **fzf**      |
| `bm`   | mark the **hovered** directory instead      |
| `bt`   | mark here, but only for this session        |
| `br`   | rename a mark                               |
| `bd` `bD` | delete one / delete all                  |

`m` and `'` are vim's `m{key}` and `'{key}`, which is the whole reason the keys
were chosen. The flow is one step longer than vim's: `m` asks for a name first
(prefilled with the directory's own) and then for the key, because a mark here
carries a label you will read back in the `bb` list.

`'` opens a menu rather than swallowing the next key blindly, and it carries
four things besides your marks: `<Space>` for fzf, `<Tab>` for this tab's
directory history, `<Backspace>` to go back one directory, and `-` for the git
root of wherever you are.

The management half sits under `b` to keep it away from the hot path. `bb` is
the doubled-key ordinary case, `bd`/`bD` is a genuine scope pair — and none of
it hangs off `d`, deliberately: `d` is a complete action, so making it a prefix
would put a timeout race on a key whose loser destroys files. See
[keymap conventions](keymaps.md).

**Marks are not a directory-only affair by accident.** `m` bookmarks the
current directory; whoosh's other form bookmarks whatever is *hovered* and warns
"Selected item is not a directory" on a file, which is why that one is on `bm`
and not on the key you reach for.

Marks live in `~/.local/state/yazi/bookmarks`, not under `~/.config`, so they
are machine-local state and never show up in `chezmoi diff`.

## Archives

| Key   | Does                          |
| ----- | ----------------------------- |
| `ca`  | archive the selection         |
| `<Enter>` | extract, on an archive    |

`c` is yazi's copy-something prefix, so `a` was free under it. It asks for the
output name and takes the format from the extension you type — `.zip`, `.7z`,
`.tar.zst` and so on — and it works on a hovered directory or on a multi-file
selection alike.

Extraction needed no binding at all: `<Enter>` on an archive already extracts,
and it does not clobber — extracting `sub.zip` beside an existing `sub/` gives
`sub_1/`. Both halves go through `7zz`, which nothing declares as a dependency;
`bootstrap.sh` installs `sevenzip` explicitly for it.

## What each row shows

| Key  | Row shows                  |
| ---- | -------------------------- |
| `is` | size                       |
| `ip` | permissions                |
| `im` | mtime                      |
| `ib` | btime                      |
| `io` | owner                      |
| `in` | nothing — back to plain    |

**This is yazi's `m` prefix, moved to `i`.** The mark key wanted `m`, and a
prefix that only changes what each row *displays* is worth less than vim's mark
key to anyone arriving from nvim. The actions are untouched; only the prefix
changed. Read `i` as the information a row carries.

## Copying paths

| Key  | Copies                     |
| ---- | -------------------------- |
| `cc` | file path                  |
| `cf` | filename                   |
| `cn` | filename without extension |
| `cd` | directory path             |
| `cC` `cD` | the URL forms of the two |

The reason to know these is the handoff: `cc` here, then paste into a command,
is usually faster than typing a path you are already looking at.

## From inside nvim

`yazi.nvim` opens the same yazi in a float, so everything above still applies —
these are the keys that get you in and the ones nvim adds while you are there.

| Key          | Opens yazi at                          |
| ------------ | -------------------------------------- |
| `<leader>fy` | the directory of the buffer you are in |
| `<leader>fY` | nvim's working directory               |
| `Y`          | in the snacks explorer, the entry under the cursor |

`fy` / `fY` are a scope pair in the sense keymaps.md means — same action, the
capital wider. `Y` in the explorer is the third of the hand-off capitals beside
`O` (oil) and `T` (plv); read them as a family rather than as the capitals of
`o`, `t` and `y`, because `y` there is yank.

This is a third browser, not a replacement for either of the other two, and the
split is in what each is shaped for. The explorer is a tree, so it answers
"where is that file". oil is one directory as an editable buffer, so it answers
"rename all of these". yazi is the one that marks files **across** directories
and then opens the whole set at once, which neither of the others can do:

```
<leader>fY     # start at the project root
<Space>...     # mark, walk somewhere else, mark more
<c-v>          # every marked file, into vertical splits
```

Opening a directory still gets oil, deliberately — `open_for_directories` is
left off so `-` and `<leader>-` keep meaning what they always did.

### Keys nvim adds inside the float

| Key       | Does                                            |
| --------- | ----------------------------------------------- |
| `<c-v>` `<c-x>` `<c-t>` | open the marked files in vsplits / splits / tabs |
| `<c-q>`   | send them to the quickfix list                  |
| `<c-o>`   | open, picking the target window                 |
| `<Tab>`   | cycle to buffers already open in nvim           |
| `<c-y>`   | copy the relative path of the marked files      |
| `<c-s>`   | grep the directory yazi is in                   |
| `<c-g>`   | search-and-replace over it, in grug-far         |
| `<c-\>`   | change nvim's working directory to it           |
| `<f1>`    | yazi.nvim's help, which is not yazi's `~`       |

Two of those are wired to tools rather than to yazi. `<c-g>` hands the
directory to grug-far, which is `<leader>sr`'s window — see
[Search and replace](replace.md). `<c-s>` is pointed at **snacks**: yazi.nvim
routes it through telescope by default, and there is no telescope here, so
without the redirect it would be a key that could only error. It now lands in
the same picker `<leader>fg` does — see [Pickers](pickers.md).

`q` closes the float and returns to nvim. There is no shell cwd to inherit
here, so the `q`/`Q` distinction above is a terminal-only concern; `<c-\>` is
the nvim equivalent, and it is explicit rather than automatic.

## Where the real list is

`~` opens yazi's own help, and it reflects your **live** bindings rather than
any documentation. It is filterable — type into it and the list narrows, which
is how every key on this card was checked. `<Esc>` leaves.

The task manager has its own help under the same key, listing a different
keymap; if `~` shows something unexpected, look at the title, which names the
layer (`mgr.help`, `tasks.help`).

**`~` is the list to trust, because this config is no longer stock.** That
sentence used to read the other way round — there was no `keymap.toml` and
everything on this card was a default. Four files are tracked now:

| File           | Holds                                                     |
| -------------- | --------------------------------------------------------- |
| `keymap.toml`  | everything on this card that is not a yazi default          |
| `init.lua`     | plugin setup — counts, marks, and where marks are stored    |
| `package.toml` | the pins `ya pkg install` reproduces: compress, the flavor  |
| `theme.toml`   | selects catppuccin frappe; the pin alone does not           |

`keymap.toml` is a **template**, because `gt` differs by machine — Finder on
macOS, yazi's own trash bin on Linux. It is the only file here that is one.

Two things about editing it. Every entry is under `prepend_keymap`, which
*merges*; a bare `keys = [...]` in the same section replaces yazi's whole
default set for it, which is the usual way a keymap file silently loses
navigation. And taking a default *away* needs `run = "noop"`, a virtual action
yazi has for exactly that — with the trap that an unknown command is silently
ignored too, so a key going quiet is not evidence your spelling was right.

`relative-motions` is **vendored** rather than pinned: upstream is dead and
yazi 26 removed the API it was built on, so the repo carries a patched copy
under `plugins/`. `ya pkg` does not manage it; `chezmoi apply` places it.

The config was also renamed at some point: `[mgr]`, not `[manager]`, and
`run =`, not `exec =`. Blog posts and dotfiles repos are still full of the old
spelling, and it fails without saying so.
