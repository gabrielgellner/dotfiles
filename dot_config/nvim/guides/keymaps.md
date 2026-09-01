# Keymap conventions

The rules this config settled on, and why. Read this before adding a mapping —
most of these were learned by finding something already broken.

## Case means scope

**A capital is the wider version of the lowercase key.** Never a different
action, never an on/off partner.

```
gs / gS   stage hunk / stage buffer        fs / fS   document / workspace symbols
gr / gR   reset hunk / reset buffer        ff / fF   smart / all files
gd / gD   diff this  / diff this ~         xx / xX   buffer / project diagnostics
gh / gH   file history / repo history      sw / sW   this file / whole project
gl / gL   blame line / toggle inline       cc / cC   nearest / enclosing class
[q / [Q   step / first-last                [l / [L   step / first-last
```

**If two actions aren't related by scope, don't pair them by case.** There's
nothing to reason from, so the reader has to memorise which is which. Give them
separate letters instead:

| Was                           | Became          | Why case was wrong  |
| ----------------------------- | --------------- | ------------------- |
| `cb` / `cB` decode / encode   | `cbe` / `cbd`   | carried _direction_ |
| `mr` / `mR` render / refresh  | refresh → `mf`  | different plugins   |
| `ac` / `aC` toggle / continue | continue → `al` | unrelated actions   |

When a genuine scope pair is backwards, **swap it**. When it was never a pair,
**move the odd one out** — and move the _rarer_ half, so the common action keeps
the cheaper keystroke.

## A doubled key is the ordinary case

`gcc`, `dd`, `yy`. So `<leader>cc` is "annotate whatever is nearest" and the
class-specific variant is `cC`, not the other way round.

## Leaf-and-prefix: only a trap when the timeout does something wrong

`timeoutlen` is 300ms. A key that is both a complete action and a prefix makes
every longer sequence a race.

But it only matters if losing the race does something **wrong**:

- `gr` was references _and_ the prefix for `grn`/`gra`/`gri`. A slow third
  keystroke opened a picker instead of running a code action. **Fixed** — `gr`
  is now a pure prefix.
- `<leader>w` was `:write` _and_ the prefix for `<leader>wd`. **Fixed** — splits
  and close moved under it, save went back to `:w`.
- `gc` is an operator, so timing out leaves it pending and `c` then gives the
  linewise variant — the same result. **Harmless.**
- mini.surround's `gsd`/`gsf`/… prefix `…n`/`…l`. Losing the race prompts for a
  surrounding identifier and finds nothing. **Harmless.**

The question is never "is this key both", it's "what happens when the clock
wins".

## Buffer-local always beats global

This was the single most common fault found, and it is always silent.

It had killed Trouble's diagnostic integration (`lsp.lua` bound `]d`
buffer-locally over `trouble.lua`'s global), neogen's docstring key
(`<leader>cf` under LSP format), the Snacks branches picker (`<leader>gb` under
gitsigns blame), and `:lnext`/`:lprevious` (`[l` under a treesitter motion) —
each in exactly the buffers where you'd want the shadowed half.

**When a key seems to do nothing, or the wrong thing, check both scopes first:**

```vim
:verbose nmap <leader>cf
```

## Don't advertise what can't work

If a key can only error, hide it rather than list it:

- `zf` `zd` `zD` `zE` raise E350/E351/E352 under `foldmethod=expr`, which is
  always. Hidden from which-key.
- `<leader>cx` runs the buffer as Lua. Bound per-buffer on `FileType lua` rather
  than globally, so it isn't offered in filetypes where it would fail.

## `mode = "x"`, never `"v"`

`"v"` is visual **and select**. In select mode a printable key replaces the
selection — and select mode is where LuaSnip leaves you inside a placeholder.

With `mode = "v"`, typing `<` in a placeholder dedented instead of typing a `<`,
and every `<leader>` mapping turned a space into the start of a command sequence
that ate the next keystroke. Use `"x"` unless you specifically mean select mode.

## which-key

**Group entries need an explicit mode list.** which-key defaults a spec entry to
normal mode (`mapping.mode or { "n" }`), so a group named only there goes back
to "+N keymaps" the moment you have a selection. `mode` is an inheriting field,
so nesting the groups under one entry covers them all.

**Naming a group costs nothing.** which-key prunes a group node with no keymaps
beneath it, so plugin groups can be declared unconditionally and appear only
where that plugin loaded — that's how conjure's `\e`/`\l`/… are handled.

**Desc-only entries are _not_ pruned.** Claiming `]b` in visual mode would
invent a row for a mapping that only exists in normal mode. Only groups get the
blanket treatment.

## When two designs legitimately want the same keys

Usually a collision means one side is wrong. Once it didn't.

Neovim puts incremental selection on `an`/`in` — grow to the parent node, shrink
to the child. mini.ai also maps `an`/`in`, as "around/inside the **next**
textobject": `n` and `l` are its next/last modifiers, and that axis runs through
every textobject it defines. Both uses are load-bearing.

The resolution was to **move the operation, not break either grammar**. `a` and
`i` mean "find a region around the cursor"; grow and shrink act on the selection
you already have, which is a different kind of operation that never really
belonged in the textobject namespace. They now sit on Helix's own keys, `<M-o>`
and `<M-i>`.

The lesson generalises: when a key is contested, ask whether one of the two is
in the wrong namespace to begin with. Moving it beats picking a winner.

## Fighting upstream is a standing commitment

`gr` used to be references, which collided with Neovim's own `gr*` LSP
namespace. Deleting Neovim's defaults would have worked until the next release —
`grx` appeared in 0.12. Adopting the namespace and overriding individual keys
with nicer pickers has no maintenance tail.

Same shape: Neovim's `ftplugin/lua.lua` sets `foldexpr` window-locally, which
beats any global. A global option is not automatically authoritative.

## Auditing

An audit only sees the buffer and mode it runs in. Three separate rounds found
things earlier passes had called clean:

- `<leader>z` has 5 mappings in a Lua buffer and 14 in markdown — the extra 9
  are buffer-local, from the 12 lazy keys across `plugins/zk.lua`,
  `plugins/markdown.lua` and `plugins/snacks.lua` that carry `ft = "markdown"`.
- A scheme buffer holds 163 buffer-local mappings against a Lua buffer's 80.
- blink's 9 insert keymaps are applied **buffer-locally**, and only once you
  have entered insert mode in that buffer. Count before doing so and you get
  zero, which is what makes them easy to miss entirely.

Those figures assume a protocol, and change without it. Pin all of it: a fresh
Neovim, one Lua file opened *outside* a git repo so gitsigns never attaches,
`lua_ls` attached, insert mode visited once. That buffer counts 68 before the
insert-mode visit and 80 after — insert goes 0 to 10 and select 0 to 2, while
normal, visual and operator-pending do not move at all:

```
cold: n=35 x=17 o=16 i=0 s=0
warm: n=35 x=17 o=16 i=10 s=2
```

Nine of those ten insert maps are blink's; the tenth is which-key's `<C-r>`
registers trigger. which-key is most of the normal-mode count too — 12 of the
35 are its triggers, and subtracting them gives the 23 an earlier pass here
recorded, back when it did not install buffer-local ones. Counting the triggers
is the right default: they are what a keystroke actually hits.

Attachment moves these more than anything else does. The same file *inside* a
git repo counts 46 in normal mode rather than 35, the extra 11 being gitsigns'.
Counting a buffer opened *after* several others gives higher numbers again,
because their plugins have loaded by then.

So quote the protocol with the number, or re-derive:

```lua
:lua local n = 0 for _, m in ipairs({"n","x","o","i","s"}) do
  n = n + #vim.api.nvim_buf_get_keymap(0, m) end print(n)
```

So: run the checks in more than one filetype, with an LSP client and gitsigns
actually attached, and look at buffer-local maps as well as global ones.

The four questions worth asking of any namespace:

1. Is any key both a complete action and a prefix — and does losing the race do
   something wrong?
2. Is any key defined both globally and buffer-locally?
3. Do two keys share a description, or does one key's case partner mean
   something unrelated?
4. Does anything advertised actually work?

---

All eleven guides — `gf` or `<CR>` on a link follows it. The first five are the
ones these rules shaped; the rest document tools that came with their own keys.

- [Navigation](navigation.md) — moving through code you are reading: the
  viewport, structural motions, folds, selections, windows
- [Files](files.md) — two browsers good at opposite things, oil and the snacks
  explorer, and the handoff between them
- [Git](git.md) — gitsigns hunk by hunk while you work, codediff for reading a
  whole change
- [Surround](surround.md) — `mini.surround` on the `gs` prefix, in three verbs
- [Command line](cmdline.md) — the `:` prompt as a small editor: completion,
  insert-from-elsewhere, and the command-line window
- [Pickers](pickers.md) — the key frame every `snacks.picker` shares, and how to
  get text back out of one
- [Search and replace](replace.md) — four tools, sorted by how far the change
  reaches
- [Completion](completion.md) — `blink.cmp` and LuaSnip, and why the popup is
  never asked for
- [Shell history and completion](shell-history.md) — atuin's SQLite history and
  zsh, outside nvim
- [Floats](floats.md) — plv, lazygit and Claude in a window over your work, and
  the one key that takes it back from them
- [Music](music.md) — gmuse in a tmux popup, reachable from any session
- Keymap conventions — this one

`<leader>?` opens the picker over all of them, and `<C-g>` there switches it
from matching titles to grepping their contents — which is how you find the
rule rather than the guide. See [pickers.md](pickers.md).
