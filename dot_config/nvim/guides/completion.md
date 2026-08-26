# Completion

`blink.cmp`, with `LuaSnip` behind it for snippets. Two rules shape the whole
setup:

- The popup appears **as you type**, without asking.
- It **never changes the buffer** until you say so. Moving through the list
  previews nothing into the line; `auto_insert` is off. The only key that
  commits is `<C-y>`.

That second one is why the keys are vim's rather than VSCode's: nothing here is
a race between you and the editor.

## Keys

| Key             | Does                                    |
| --------------- | --------------------------------------- |
| `<C-n>` `<C-p>` | next / previous item, opening the menu if it is closed |
| `<C-y>`         | accept the selected item                |
| `<C-e>`         | dismiss the menu                        |
| `<C-space>`     | open it on demand                       |
| `<C-b>` `<C-f>` | scroll the documentation window         |

`<Tab>` and `<S-Tab>` are **not** completion keys here. They jump between the
placeholders of a snippet you have already expanded, and fall through to a real
tab the rest of the time.

Accepting a function brings its brackets with it — `auto_brackets` is on — and
the signature window opens as you fill the arguments.

## Where the items come from

| Source     | Gives                                        |
| ---------- | -------------------------------------------- |
| `lsp`      | whatever the language server knows           |
| `path`     | filesystem paths, from the text under the cursor |
| `snippets` | friendly-snippets, per filetype              |
| `buffer`   | words already in the open buffer             |

The menu names the source on the right, so it is always clear which one an item
came from. Kind and icon sit in the middle column.

## Snippets

`friendly-snippets` supplies them — 24 for lua, 67 for python, 77 for rust, and
something for most languages you will open. They appear in the menu like
anything else, marked `Snippet`.

There are two ways in, and the difference is worth knowing:

```
pdb          the menu offers pdb, pudb, ipdb …    accept with <C-y>
fori<C-k>    expands straight away, no menu       the trigger is enough
```

| Key     | Does                                          |
| ------- | --------------------------------------------- |
| `<C-k>` | expand the trigger under the cursor, or jump to the next placeholder |
| `<C-j>` | jump to the previous placeholder              |
| `<Tab>` `<S-Tab>` | the same jumping, through blink     |

**Both `<C-k>` and `<C-j>` do nothing when no snippet is active.** That is
deliberate. In stock vim `<C-k>` begins a digraph — `<C-k>a:` gives `ä` — and
`<C-j>` inserts a line break. Neither is wanted here, and a press that lands
just after a snippet has ended would otherwise put something in the buffer that
is easy to miss and annoying to undo. They are suppressed rather than passed
through.

## On the command line

Typing `:` shows the menu as you go, which makes `:` behave a little like a
command palette. `/` and `?` deliberately do not: those are incremental, the
point is watching the match move, and a popup over the buffer hides the thing
you are aiming at. Ghost text still works there, and `<C-space>` pulls the menu
up when you want it.

`<Left>` and `<Right>` move the cursor rather than the selection, which is not
blink's default — with the menu open most of the time, arrow keys are how you
edit the command you are writing.

## See also

- [Command line](cmdline.md) — the rest of what `:` can do
- [Shell history](shell-history.md) — the zsh side, where `Tab` is fzf-tab
