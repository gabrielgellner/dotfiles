# Surround

`mini.surround`, on the `gs` prefix. Three verbs cover nearly everything:

| Key                   | Does                                                |
| --------------------- | --------------------------------------------------- |
| `gsa{motion}{id}`     | **add** a surrounding around what the motion covers |
| `gsd{id}`             | **delete** the nearest `{id}` surrounding           |
| `gsr{old}{new}`       | **replace** one surrounding with another            |
| `gsf{id}` / `gsF{id}` | jump to the right / left edge of a surrounding      |
| `gsh{id}`             | briefly highlight one, to check your aim            |

`gsa` is an operator, so it takes any motion or text object: `gsaiw"`, `gsaip)`,
`gsa$)`. In visual mode the selection _is_ the target, so it's just `gsa{id}`.

## Identifiers

The `{id}` is one character naming the surrounding.

| `{id}`          | Adds                                            |
| --------------- | ----------------------------------------------- |
| `(` `[` `{` `<` | **with** inner spaces — `( foo )`               |
| `)` `]` `}` `>` | **without** — `(foo)`                           |
| `"` `'` `` ` `` | that quote                                      |
| `b`             | any bracket when matching; adds tight, like `)` |
| `q`             | any quote when matching; adds `"`               |
| `f`             | function call — prompts for the name            |
| `t`             | HTML/XML tag — prompts for the name             |
| `?`             | prompts for the left and right text separately  |
| anything else   | itself — `_` gives `_foo_`                      |

**The open/close distinction is the one worth memorising.** `(` and `)` match
the same thing but produce different output, so `gsr)(` adds inner spaces to a
tight pair and `gsr()` takes them away.

`b` and `q` are the "I don't care which" versions — `gsdq` removes whichever
quote style is there, which saves looking.

## Quoting a path — the `iw` trap

```
a/b/c   gsaiw"   ->  "a"/b/c        iw stops at the slash
a/b/c   gsaW"    ->  "a/b/c"        W takes the whole path
```

`iw` is a _word_, and `/`, `.`, `-` all end one. For anything path-shaped, a
filename, a URL, or a dotted attribute chain, reach for **`gsaW"`** — `W` runs
to the next whitespace. This is the single most common surround mistake.

Same for `gsdW`-style thinking when removing: `gsd"` finds the quotes wherever
they are, so deleting doesn't have the problem — only adding does.

## Recipes

| Want                         | Type                                     |
| ---------------------------- | ---------------------------------------- |
| quote a path or filename     | `gsaW"`                                  |
| quote a plain word           | `gsaiw"`                                 |
| quote the whole line         | `V` then `gsa"`                          |
| swap `"` for `'`             | `gsr"'`                                  |
| swap whichever quote for `'` | `gsrq'`                                  |
| drop the quotes              | `gsd"` or `gsdq`                         |
| wrap in a function call      | `gsaWf`, then type the name              |
| drop the enclosing call      | `gsdf` — `print(x)` becomes `x`          |
| tight parens to spaced       | `gsr)(`                                  |
| spaced parens to tight       | `gsr()`                                  |
| `"foo"` to `<div>foo</div>`  | `gsr"t`, then type `div`                 |
| custom delimiters            | `gsa{motion}?`, then type left and right |

## When there's more than one candidate

Suffix the verb with `n` for the **next** one or `l` for the **last**:

```
gsdn"   delete the next quotes, not the ones you're inside
gsrl)]  replace the previous parens with brackets
```

These are why `gsd` and `gsr` wait a moment before acting — they're prefixes of
`gsdn`/`gsdl` and `gsrn`/`gsrl`. Type the identifier promptly and there's no
pause. If one does fire early you get a prompt for an identifier, and `<Esc>`
backs out; nothing is changed until a match is found.

## Notes

- Searching is limited to 500 lines around the cursor (`n_lines`), so a
  surrounding that opens far above won't be found. `gsn` changes it for the
  session.
- `gsh{id}` is the cheap way to check what `gsd{id}` would hit before doing it.
- Counts on text objects behave oddly here — `gsa2iw)` does not wrap two words.
  Use visual mode when the target isn't a single clean motion.

---

The rules behind these bindings: [Keymap conventions](keymaps.md).
