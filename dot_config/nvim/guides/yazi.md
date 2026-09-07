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
| `.`             | toggle hidden files                     |
| `z`             | jump to a file/directory via **fzf**    |
| `Z`             | jump to a directory via **zoxide**      |
| `g<Space>`      | jump interactively                      |
| `gh` `gc` `gd`  | home / `~/.config` / `~/Downloads`      |

**`z` is fzf and `Z` is zoxide, which is the reverse of the shell outside.**
Out at the prompt `z` *is* zoxide; step into yazi and the same key is fzf. It
is the one binding here worth knowing before you need it, because both do
something plausible and neither errors.

There is no count prefix — `11j` does not move eleven rows, because `1`–`9`
switch tabs. `/` is the answer instead: a listing is a column of names, and you
always know what a file starts with even when you do not know it is eleven down.

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
| `Y` `X`   | cancel the pending yank                           |
| `-` `_`   | symlink the absolute / relative path of the yank  |
| `<C-->`   | hardlink the yank                                 |

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
| `1`–`9` | switch by index                             |
| `[` `]` | previous / next tab                         |
| `{` `}` | swap this tab with the previous / next      |
| `<C-c>` | close the tab, or quit if it is the last    |

**It is `tt`, not `t`** — `t` alone is a prefix, which is also why `tr` exists.

Two tabs is the tool for shuffling files between distant directories: source in
one, destination in the other, mark and `y` in the first, `2` and `p` in the
second, `1` to come back with the cursor exactly where it was. Each tab keeps
its own directory, history and cursor.

## Trash, and the task manager

| Key | Does                              |
| --- | --------------------------------- |
| `d` | trash selected files (asks first) |
| `D` | permanently delete                |
| `gt` | go to the trash bin              |
| `w` | show the task manager             |

Deletes, copies and moves all run as background tasks, and **the count in the
bottom-right is tasks still in flight** — not a file count. Inside `w`, `<Enter>`
inspects (which is where an error's actual text is), `x` cancels the highlighted
one, and `w` or `<Esc>` closes. There is no bulk clear: the list is in-memory
per process, so quitting yazi wipes it, which is the fastest fix for a screenful.

**On macOS the trash is write-only from here, measured.** `d` hands the file to
the system Trash and it does vanish from the listing — but `gt` opens the
`trash://` scheme and comes back `Error: Operation not permitted (os error 1)`,
and `ls ~/.Trash` in the shell fails the same way. That is macOS TCC, not yazi:
the terminal has no Full Disk Access, so nothing launched from it can read the
Trash. Finder can — `osascript -e 'tell application "Finder" to count items in
trash'` answered while `ls` was refused. So `d` is safe to use and `gt` is not
the way back; the Finder is.

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

There is no `keymap.toml` here — everything above is yazi's default. Only
`package.toml` and `theme.toml` are tracked, pinning the catppuccin frappe
flavor; `ya pkg install` reproduces it. If a keymap ever gets added, note that
the config was renamed: `[mgr]`, not `[manager]`, and `run =`, not `exec =`.
Blog posts and dotfiles repos are still full of the old spelling, and it fails
without saying so.
