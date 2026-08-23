# Navigation

Moving around code you're *reading*, not editing. The organising idea: **the
viewport and the cursor are separate things**, and most "scrolling feels clunky"
is really "I moved the cursor when I only wanted to move the window", or "I
scrolled to something that was already on screen".

## Viewport only — cursor stays put

The cursor holds its buffer line; it only gets dragged once `scrolloff` (8 here)
runs out.

| Key | Does |
| --- | --- |
| `<C-e>` / `<C-y>` | scroll window down / up, 3 lines a press |
| `zt` `zz` `zb` | put the cursor's line at top / middle / bottom of window |
| `z<CR>` `z.` `z-` | same, but also jump to first non-blank |

`<C-e>`/`<C-y>` are the answer to "scroll without moving the cursor". Vim has no
way to fully decouple the two — the cursor must stay on screen — so a generous
`scrolloff` is what buys the runway.

## Cursor only — within what's already on screen

| Key | Does |
| --- | --- |
| `H` `M` `L` | cursor to top / middle / bottom of the *window* |
| `s{char}{char}` | flash: jump to any visible match by label |
| `S` | flash treesitter: label every enclosing node, pick one |
| `f` `t` `F` `T` | flash-enhanced — labels appear on multiple matches |
| `w` `e` `b` `ge` | spider — stops at subWord boundaries, not just words |

**`<C-e>`/`<C-y>` then `H`/`M`/`L` is the core two-step**: bring the text into
view, then place the cursor. That's the pair that replaces mashing `<C-d>`.

And before scrolling at all: if the target is visible, `s` gets there in three
keystrokes regardless of distance. Scrolling is for things *off* screen.

## Both — the big jumps

| Key | Does |
| --- | --- |
| `<C-d>` / `<C-u>` | half page, recentred (`zz`) so the cursor stays mid-screen |
| `<C-f>` / `<C-b>` | full page |
| `{` / `}` | previous / next blank line — cheap paragraph-sized hops |
| `12j` `12k` | counted moves are *real* lines, matching the `relativenumber` gutter |
| `n` / `N` | next / previous match, recentred |
| `gg` / `G` / `42G` | top / bottom / line 42 |

## By structure, not by distance

This is the one that actually replaces scrolling. Don't count lines — name what
you want to land on.

| Key | Does |
| --- | --- |
| `]f` `[f` | next / previous function start (`]F` `[F` for the end) |
| `]c` `[c` | next / previous class (`]C` `[C` for the end) |
| `]a` `[a` | next / previous argument |
| `]?` `[?` | next / previous conditional |
| `]r` `[r` | next / previous loop |
| `[i` / `]i` | top / bottom of the current indent scope |
| `ii` / `ai` | select the indent scope, without / with its borders |
| `%` | matching bracket / keyword pair (matchup: `if`↔`end`, tags, …) |
| `<leader>fs` | symbol picker for the file — the fastest way into a big file |

A sticky header pins the enclosing function/class signatures to the top of the
window as you scroll, so you always know what you're inside. `<leader>uc`
toggles it.

### Folds

Folds are on but start fully open (`foldlevel` 99), so they never surprise you.
Use them as a reading tool: collapse a file to its shape, then open what matters.

| Key | Does |
| --- | --- |
| `zM` / `zR` | fold everything / unfold everything |
| `zm` / `zr` | fold / unfold one level at a time |
| `za` `zo` `zc` | toggle / open / close the fold under the cursor |
| `zv` | open just enough to see the cursor line |
| `zj` / `zk` | move to the start of the next / end of the previous fold |

`zM` then `zr` a couple of times gives you a signatures-only view of a file.
`zM` then `zv` gives you "just the function I'm in, everything else collapsed".

## Getting back where you were

The single biggest reading upgrade: jump freely, because returning is one key.

| Key | Does |
| --- | --- |
| `<C-o>` / `<C-i>` | back / forward through the jumplist (crosses files) |
| `[j` / `]j` | the same list as a bracket motion, with counts |
| `''` | back to the line you were on before the last jump |
| `` `` `` | back to the exact position |
| `` `. `` | the position of the last edit |
| `g;` / `g,` | walk backward / forward through the changelist |
| `<C-^>` | toggle to the alternate (previously edited) buffer |

## Across files

| Key | Does |
| --- | --- |
| `[b` `]b` | previous / next buffer (`[B` `]B` for first / last) |
| `[o` `]o` | previous / next recently-opened file |
| `gd` | LSP definition |
| `grr` `gri` `grt` | LSP references / implementations / type definitions |
| `grn` `gra` `grx` | rename / code action / run codelens |
| `gO` | document symbols (same as `<leader>fs`) |
| `<leader>ff` `<leader>fb` `<leader>fr` | find file / buffer / recent |
| `<leader>fg` `<leader>fw` | live grep / grep word under cursor |
| `<leader>fS` | workspace symbols |

## The rest of the bracket family

Everything `[`/`]` is bound to, in one place:

| Suffix | Motion | From |
| --- | --- | --- |
| `f` `F` `c` `C` `a` `r` `?` | function, class, argument, loop (repeat), conditional | treesitter |
| `i` | top / bottom of indent scope | mini.indentscope |
| `b` `B` | buffer | mini.bracketed |
| `j` `l` `o` `u` `w` `x` `y` | jumplist, location list, oldfile, undo state, window, conflict marker, yank ring | mini.bracketed |
| `h` | git hunk | gitsigns |
| `d` `e` | diagnostic, error | LSP |
| `t` | todo comment | todo-comments |
| `q` `Q` | quickfix entry / first-last | mini.bracketed |

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
return. Or split with `<leader>-` and scroll the two independently.

**Get to something you can see.** `s` + two characters. Never scroll to it.

**Get to something you can't see.** Name it: `/pattern`, `]f`, `<leader>fs`, or
`<leader>fw`. Scrolling is the last resort, not the first.
