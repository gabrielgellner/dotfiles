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

| Was | Became | Why case was wrong |
| --- | --- | --- |
| `cb` / `cB` decode / encode | `cbe` / `cbd` | carried *direction* |
| `mr` / `mR` render / refresh | refresh → `mf` | different plugins |
| `ac` / `aC` toggle / continue | continue → `al` | unrelated actions |

When a genuine scope pair is backwards, **swap it**. When it was never a pair,
**move the odd one out** — and move the *rarer* half, so the common action keeps
the cheaper keystroke.

## A doubled key is the ordinary case

`gcc`, `dd`, `yy`. So `<leader>cc` is "annotate whatever is nearest" and the
class-specific variant is `cC`, not the other way round.

## Leaf-and-prefix: only a trap when the timeout does something wrong

`timeoutlen` is 300ms. A key that is both a complete action and a prefix makes
every longer sequence a race.

But it only matters if losing the race does something **wrong**:

- `gr` was references *and* the prefix for `grn`/`gra`/`gri`. A slow third
  keystroke opened a picker instead of running a code action. **Fixed** — `gr`
  is now a pure prefix.
- `<leader>w` was `:write` *and* the prefix for `<leader>wd`. **Fixed** — splits
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
buffer-locally over `trouble.lua`'s global), neogen's docstring key (`<leader>cf`
under LSP format), the Snacks branches picker (`<leader>gb` under gitsigns
blame), and `:lnext`/`:lprevious` (`[l` under a treesitter motion) — each in
exactly the buffers where you'd want the shadowed half.

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
normal mode (`mapping.mode or { "n" }`), so a group named only there goes back to
"+N keymaps" the moment you have a selection. `mode` is an inheriting field, so
nesting the groups under one entry covers them all.

**Naming a group costs nothing.** which-key prunes a group node with no keymaps
beneath it, so plugin groups can be declared unconditionally and appear only
where that plugin loaded — that's how conjure's `\e`/`\l`/… and haskell-tools'
`<leader>h`/`<leader>r` are handled.

**Desc-only entries are *not* pruned.** Claiming `]b` in visual mode would invent
a row for a mapping that only exists in normal mode. Only groups get the blanket
treatment.

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

- `<leader>z` has 5 mappings in a Lua buffer and 14 in markdown — 8 carry
  `ft = "markdown"`.
- A scheme buffer holds 122 mappings from conjure and paredit that exist
  nowhere else.
- blink's 9 insert keymaps are applied **buffer-locally on BufEnter**, so they
  never appear in the global table at all.

So: run the checks in more than one filetype, with an LSP client and gitsigns
actually attached, and look at buffer-local maps as well as global ones.

The four questions worth asking of any namespace:

1. Is any key both a complete action and a prefix — and does losing the race do
   something wrong?
2. Is any key defined both globally and buffer-locally?
3. Do two keys share a description, or does one key's case partner mean something
   unrelated?
4. Does anything advertised actually work?

---

The guides these rules shaped — `gf` on a link follows it:
[Navigation](navigation.md), [Files](files.md), [Git](git.md),
[Surround](surround.md), [Command line](cmdline.md).
