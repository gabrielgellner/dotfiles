# Navigation

Moving around code you're _reading_, not editing. The organising idea: **the
viewport and the cursor are separate things**, and most "scrolling feels clunky"
is really "I moved the cursor when I only wanted to move the window", or "I
scrolled to something that was already on screen".

## Viewport only — cursor stays put

The cursor holds its buffer line; it only gets dragged once `scrolloff` (8 here)
runs out.

| Key               | Does                                             |
| ----------------- | ------------------------------------------------ |
| `<C-e>` / `<C-y>` | scroll window down / up, 3 lines a press         |
| `zt` `zz` `zb`    | cursor's line to top / middle / bottom of window |
| `z<CR>` `z.` `z-` | same, but also jump to first non-blank           |

`<C-e>`/`<C-y>` are the answer to "scroll without moving the cursor". Vim has no
way to fully decouple the two — the cursor must stay on screen — so a generous
`scrolloff` is what buys the runway.

## Cursor only — within what's already on screen

| Key              | Does                                                   |
| ---------------- | ------------------------------------------------------ |
| `H` `M` `L`      | cursor to top / middle / bottom of the _window_        |
| `s{char}{char}`  | flash: jump to any visible match by label              |
| `S`              | flash treesitter: label every enclosing node, pick one |
| `f` `t` `F` `T`  | flash-enhanced — labels appear on multiple matches     |
| `w` `e` `b` `ge` | spider — stops at subWord boundaries                   |

**`<C-e>`/`<C-y>` then `H`/`M`/`L` is the core two-step**: bring the text into
view, then place the cursor. That's the pair that replaces mashing `<C-d>`.

And before scrolling at all: if the target is visible, `s` gets there in three
keystrokes regardless of distance. Scrolling is for things _off_ screen.

## Both — the big jumps

| Key                | Does                                                    |
| ------------------ | ------------------------------------------------------- |
| `<C-d>` / `<C-u>`  | half page, recentred — cursor stays mid-screen          |
| `<C-f>` / `<C-b>`  | full page                                               |
| `{` / `}`          | previous / next blank line — cheap paragraph-sized hops |
| `12j` `12k`        | counted moves are _real_ lines, matching the gutter     |
| `n` / `N`          | next / previous match, recentred                        |
| `gg` / `G` / `42G` | top / bottom / line 42                                  |

## By structure, not by distance

This is the one that actually replaces scrolling. Don't count lines — name what
you want to land on.

| Key          | Does                                                           |
| ------------ | -------------------------------------------------------------- |
| `]f` `[f`    | next / previous function start (`]F` `[F` for the end)         |
| `]k` `[k`    | next / previous class (`]K` `[K` for the end)                  |
| `]a` `[a`    | next / previous argument                                       |
| `]?` `[?`    | next / previous conditional                                    |
| `]r` `[r`    | next / previous loop                                           |
| `[i` / `]i`  | top / bottom of the current indent scope                       |
| `ii` / `ai`  | select the indent scope, without / with its borders            |
| `%`          | matching bracket / keyword pair (matchup: `if`↔`end`, tags, …) |
| `<leader>fs` | symbol picker — the fastest way into a big file                |

A sticky header pins the enclosing function/class signatures to the top of the
window as you scroll, so you always know what you're inside. `<leader>uc`
toggles it.

### Folds

Folds are on but start fully open (`foldlevel` 99), so they never surprise you.
Use them as a reading tool: collapse a file to its shape, then open what
matters.

| Key            | Does                                                     |
| -------------- | -------------------------------------------------------- |
| `zM` / `zR`    | fold everything / unfold everything                      |
| `zm` / `zr`    | fold / unfold one level at a time                        |
| `za` `zo` `zc` | toggle / open / close the fold under the cursor          |
| `zv`           | open just enough to see the cursor line                  |
| `zj` / `zk`    | move to the start of the next / end of the previous fold |

`zM` then `zr` a couple of times gives you a signatures-only view of a file.
`zM` then `zv` gives you "just the function I'm in, everything else collapsed".

## Growing a selection

Two ways to select by structure, and they answer different questions.

**Name it** — mini.ai and the treesitter textobjects. `vaf` a function, `ci"`
inside quotes, `daa` an argument. Precise, but you have to know the thing has a
name.

**Grow into it** — start anywhere and take the next bigger node. No name needed,
which is what makes it work on things that have none: a table entry, a match
arm, one link of a chained call.

| Key               | Does                                   |
| ----------------- | -------------------------------------- |
| `<M-o>`           | grow to the parent node                |
| `<M-i>`           | shrink back to the child               |
| `<M-n>` / `<M-p>` | next / previous sibling                |
| `]n` / `[n`       | next / previous sibling (Neovim's own) |
| `]N` / `[N`       | same, but growing the selection        |

All take a count, so `3<M-o>` grows three levels at once.

Worked example, cursor on `client` in `if client:supports_method(...) then`:

```
viw      client
<M-o>    client:supports_method
<M-o>    client:supports_method("textDocument/foldingRange")
<M-o>    the whole if block, across three lines
<M-i>    back to the call
```

Reach for growing when reading unfamiliar code — you rarely know what the node
is called, and it is faster than guessing which textobject fits. Reach for
naming when you already know: `daf` beats four `<M-o>` presses.

These live on Alt because Neovim puts them on `an`/`in`, which mini.ai owns. See
[Keymap conventions](keymaps.md) for why moving them was the right call.

## Many cursors, Helix style

`multicursor.nvim`, on `<leader>v`. This is a different idea from the two above,
and worth trying on its own terms rather than as "vim with more cursors".

The Helix loop is: **select a region, split it into many cursors, act on all of
them, collapse.** The split is the part vim has no equivalent for — you are not
placing cursors one at a time, you are cutting one selection into pieces by a
pattern and getting a cursor per piece.

| Key                       | Does                                        |
| ------------------------- | ------------------------------------------- |
| `<leader>vs` _(visual)_   | split the selection by a regex              |
| `<leader>vr` _(visual)_   | put a cursor on each regex match inside it  |
| `<leader>vl` _(visual)_   | one cursor per line of the selection        |
| `<leader>vI` `<leader>vA` | insert / append at every line's start / end |
| `<leader>vj` `<leader>vk` | add a cursor on the line below / above      |
| `<leader>vv`              | a cursor at every match of the word in file |
| `<leader>vn` `<leader>vN` | add a cursor at the next / previous match   |
| `<leader>vt` `<leader>vT` | rotate the contents between cursors         |
| `<leader>va`              | align the cursor columns                    |
| `<leader>vu`              | restore the cursor set you just collapsed   |

While more than one cursor exists, six more keys apply — and only then, so they
mean their usual thing the rest of the time:

| Key            | Does                                          |
| -------------- | --------------------------------------------- |
| `<Esc>`        | collapse back to one                          |
| `<Tab>`        | make the next cursor main                     |
| `<S-Tab>`      | the previous one                              |
| `<leader>vx`   | drop the cursor you are on                    |
| `<C-a>` `<C-x>` | increment / decrement, **as a sequence**     |

### Worked examples

Renaming a local where LSP rename does not reach:

```
foo bar foo baz foo     <leader>vv  ciwQUX<Esc>   ->  QUX bar QUX baz QUX
```

Numbering a list. `<C-a>` gives each cursor a larger step than the one before,
so identical numbers come out as a sequence:

```
item 0                  Vjj  <leader>vl  f0  <C-a>       item 1
item 0                                                   item 2
item 0                                                   item 3
```

Swapping two arguments — the one that has no vim equivalent worth typing:

```
f(first, second)        vi(  <leader>vs  , <CR>  <leader>vt
                        ->  f(second, first)
```

A suffix on every line of a block:

```
alpha                   <leader>vj  <leader>vj  A!<Esc>   alpha!
beta                                                      beta!
gamma                                                     gamma!
```

### Coming from Helix

| Helix           | Here                      |
| --------------- | ------------------------- |
| `s`             | `<leader>vr`              |
| `S`             | `<leader>vs`              |
| `Alt-s`         | `<leader>vl`              |
| `C` / `Alt-C`   | `<leader>vj` `<leader>vk` |
| `&`             | `<leader>va`              |
| `Alt-)` `Alt-(` | `<leader>vt` `<leader>vT` |
| `)` `(`         | `<Tab>` `<S-Tab>`         |
| `,`             | `<Esc>`                   |
| `Alt-,`         | `<leader>vx`              |
| `Ctrl-a`        | `<C-a>`, same key         |
| `%`             | `ggVG`, vim's own         |
| `_`             | no equivalent             |

### Why not `s` and `S`, and why not `<leader>m`

Helix puts select-in-selection on `s` and split on `S`. Both are flash here (see
[what the plugins took](#what-the-plugins-took)), and flash is the better trade
for a vim-shaped config — it is used constantly, these a few times a day.

`<leader>m` would have read better for "multi", but `m` is markdown's, and
markdown's mappings are **buffer-local**: `<leader>mr` and `<leader>mx` would
have meant render-toggle and checkbox-toggle inside a markdown buffer and
multicursor everywhere else, with nothing to say which you were getting. `v` is
where vim already keeps selecting, and *selection* is Helix's own word for these.

`<leader>vn`/`vN` break the house rule that a capital means a wider scope: here
it means the other direction, following `n`/`N`. That is the vim convention for
search, which is what these are.

## What the plugins took

Several single keys mean something other than stock vim here. Each is a
deliberate trade, and each has a replacement worth knowing before you reach for
the original by reflex.

| Key              | Stock vim                 | Here                   | Use instead |
| ---------------- | ------------------------- | ---------------------- | ----------- |
| `s`              | substitute character      | flash jump             | `cl`        |
| `S`              | substitute line           | flash treesitter       | `cc`        |
| visual `S` / `R` | change the selected lines | flash                  | `c`         |
| `w` `e` `b`      | word motions              | spider (subword-aware) | `W` `E` `B` |

The spider one is the easiest to trip over, because it applies **after an
operator too**: `dw` on `getUserName` deletes only `get`. `dW` is the vanilla
behaviour, and `daw` still takes the whole word.

There is a second edge to it, and this one is silent: on the **last word of a
line**, `dw` and `de` do nothing at all. Spider's motion has nowhere to go, so
the operator gets an empty range and no error. Nothing to do with subwords —
`alpha beta` with the cursor on `beta` behaves the same way.

```
alpha beta   dw    ->  "alpha beta"   no-op, no message
alpha beta   dW    ->  "alpha "       the space stays
alpha beta   D     ->  "alpha "       same
alpha beta   daw   ->  "alpha"        aw eats the space too
```

Two that are _not_ taken, despite looking like they should be: `r` still
replaces a character and `R` still enters Replace mode — flash only claims those
in operator-pending and visual, where they weren't vim commands to begin with.

Pasting over a selection: `P` leaves your register alone, `p` takes the replaced
text into it, which is how you swap two pieces of text — yank the first, select
the second, `p`, then select where the first was and `p` again.

## Getting back where you were

The single biggest reading upgrade: jump freely, because returning is one key.

| Key               | Does                                                |
| ----------------- | --------------------------------------------------- |
| `<C-o>` / `<C-i>` | back / forward through the jumplist (crosses files) |
| `[j` / `]j`       | the same list as a bracket motion, with counts      |
| `''`              | back to the line you were on before the last jump   |
| `` `` ``          | back to the exact position                          |
| `` `. ``          | the position of the last edit                       |
| `g;` / `g,`       | walk backward / forward through the changelist      |
| `<C-^>`           | toggle to the alternate (previously edited) buffer  |

## Across files

| Key                                    | Does                                                |
| -------------------------------------- | --------------------------------------------------- |
| `[b` `]b`                              | previous / next buffer (`[B` `]B` for first / last) |
| `[o` `]o`                              | previous / next recently-opened file                |
| `gd`                                   | LSP definition                                      |
| `grr` `gri` `grt`                      | LSP references / implementations / type definitions |
| `grn` `gra` `grx`                      | rename / code action / run codelens                 |
| `gO`                                   | document symbols (same as `<leader>fs`)             |
| `<leader>ff` `<leader>fb` `<leader>fr` | find file / buffer / recent                         |
| `<leader>fg` `<leader>fw`              | live grep / grep word under cursor                  |
| `<leader>fl`                           | fuzzy-find a line in this buffer                    |
| `<leader>fm` `<leader>fj`              | marks / jumps as a list, not stepped                |
| `<leader>f;`                           | reopen the last picker                              |
| `<leader>fS`                           | workspace symbols                                   |

## Between windows

| Key                             | Does                                 |
| ------------------------------- | ------------------------------------ |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | move to the split left/down/up/right |

Splits live under `<leader>w`: `<leader>w-` horizontal, `<leader>w|` vertical,
`<leader>wd` to close. They are prose rather than another table row because the
vertical one is a pipe, and a pipe inside a table cell has to be written `\|`,
backslash and all, in the rendered view.

These were vim-tmux-navigator's for a while, which carried the same movement on
into a neighbouring tmux pane when nvim ran out of splits. There has never been
a second tmux pane to reach — work is divided into tmux *windows*, `prefix` and
`1`/`2`/`3` — so the plugin is gone and these are plain `wincmd` now.

`<C-h>` means something else inside an oil buffer: see [Files](files.md).

## The rest of the bracket family

Everything `[`/`]` is bound to, in one place:

| Suffix          | Motion                               | From             |
| --------------- | ------------------------------------ | ---------------- |
| `f` `F` `c` `C` | function, class (caps = end)         | treesitter       |
| `a` `r` `?`     | argument, loop (repeat), conditional | treesitter       |
| `i`             | top / bottom of indent scope         | mini.indentscope |
| `b` `B`         | buffer                               | mini.bracketed   |
| `j` `l` `o`     | jumplist, location list, oldfile     | mini.bracketed   |
| `u` `w` `y`     | undo state, window, yank ring        | mini.bracketed   |
| `x`             | conflict marker                      | mini.bracketed   |
| `h`             | git hunk                             | gitsigns         |
| `d` `e`         | diagnostic, error                    | LSP              |
| `t`             | todo comment                         | todo-comments    |
| `q` `Q`         | quickfix entry / first-last          | mini.bracketed   |

`[y` / `]y` is the sleeper: after pasting, it cycles the paste through older and
newer yanks in place.

## Recipes

**Skim an unfamiliar file.** `zM` to collapse to signatures → `zj`/`zk` to walk
them → `zv` on the interesting one. Or skip folds: `<leader>fs` and read the
symbol list.

**Read a long function without losing the top.** Park the cursor and `<C-e>` /
`<C-y>`. The sticky header keeps the signature visible; `''` returns you to
where the cursor still is.

**Follow a call and come back.** `gd` → read → `<C-o>`. Chain it as deep as you
like; `<C-o>` unwinds one level per press.

**Compare two places in one file.** `ma` on the first, jump away, `` `a `` to
return. Or split with `<leader>w-` and scroll the two independently.

**Get to something you can see.** `s` + two characters. Never scroll to it.

**Get to something you can't see.** Name it: `/pattern`, `]f`, `<leader>fs`, or
`<leader>fw`. Scrolling is the last resort, not the first.

---

Why these keys are where they are, and what a capital means:
[Keymap conventions](keymaps.md). Press `gf` on a link to follow it.
