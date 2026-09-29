# LSP

Language servers, diagnostics, formatting and linting. The completion popup
those servers feed is its own card — see [Completion](completion.md) for
blink.cmp and snippets.

No `mason`, no `lspconfig` setup calls. Servers are installed by
`bootstrap.sh` and enabled with Neovim's own `vim.lsp.enable`; lspconfig is
still a dependency, but only for the server definitions it ships.

## Going places

| Key   | Does                  |
| ----- | --------------------- |
| `gd`  | definitions           |
| `grr` | references            |
| `gri` | implementations       |
| `gO`  | document symbols      |
| `K`   | hover docs            |

**Those live in Neovim's own `gr*` namespace, deliberately.** `gr` used to be
references here and collided with it. Deleting Neovim's defaults would have
worked until the next release — `grx` appeared in 0.12 — so the namespace was
adopted instead and individual keys overridden with nicer pickers. Fighting
upstream is a standing commitment; adopting it has no maintenance tail. See
[Keymap conventions](keymaps.md).

The four above open a [picker](pickers.md) rather than jumping blind, which is
what makes them worth overriding at all.

## Acting on code

| Key          | Does                    |
| ------------ | ----------------------- |
| `<leader>ca` | code action             |
| `<leader>cr` | rename symbol           |
| `<leader>cf` | format buffer           |
| `<leader>lr` | restart the LSP         |
| `grn` `gra`  | Neovim's own rename / action |

`grn` and `gra` are upstream's and still work — `gra` in visual mode too. The
`<leader>c…` pair is the same thing under the "code" prefix, which is where the
rest of this config's code actions live.

## Diagnostics

| Key          | Does                        |
| ------------ | --------------------------- |
| `]e` `[e`    | next / previous **error**   |
| `<leader>e`  | show the diagnostic float   |

`]e`/`[e` skip warnings and hints and stop only at errors, which is what makes
them usable in a file that has a hundred style hints. They work in normal,
visual and operator-pending mode.

Errors show as `󰅚` in the sign column with `●` virtual text, sorted by
severity. `update_in_insert` is off, so nothing moves while you are typing.

**Inlay hints are on by default** — enabled per buffer on attach, so types and
parameter names appear without asking.

## Which server does what

| Filetype  | Server                  |
| --------- | ----------------------- |
| lua       | `lua-language-server`   |
| python    | `pyrefly` **and** `ruff` |
| bash, sh  | `bash-language-server`  |
| just      | `just-lsp`              |
| rust      | `rust-analyzer`, via rustaceanvim |

**Python runs two servers with the overlap cut by hand.** pyrefly does types and
hover; ruff does diagnostics and formatting, with `hoverProvider` switched off
on attach so the two do not both answer `K`. pyrefly also gets pointed at the
project's `.venv/bin/python` when there is one.

**`basedpyright` is installed but deliberately not enabled here.** It is the
CI and `just` checker; pyrefly does the editor work. Finding it in
`bootstrap.sh` and not in nvim is the intended state, not an oversight.

The same overlap is cut again on the linting side, twice. The linter table has
**one entry**, `yaml` — everything else gets its diagnostics from a language
server already, and adding it here reported each finding twice from the same
tool. ruff was literally duplicating itself, once as source "Ruff" from the
server and once as "ruff" from nvim-lint; `sh` did the same via
bash-language-server's own shellcheck. `yamllint` stays only because nothing
else covers yaml.

## Formatting and linting

Formatting is `conform.nvim`, on save. One formatter per filetype, chosen to be
the fast one: `ruff` for python, `stylua` for lua, `biome` for JS/TS/JSON/CSS,
`taplo` for toml, `yamlfmt`, `shfmt`, `rustfmt`, `prettier` for markdown and
html.

The save timeout is 3000ms for markdown and 500ms everywhere else — prettier on
a long document is genuinely slower than the rest.

**`nvim/guides/` is excluded from format-on-save**, by path. These cards are
hand-formatted, and prettier corrupts a code span whose content is two
backticks — it ate the jumplist row in navigation.md. It also rewrites
`*emphasis*` to `_emphasis_` and re-pads tables. `prettier --check` failing on a
guide is the expected state, not a defect.

Linting is `nvim-lint`, with the single `yaml` entry described above.

## See also

- [Completion](completion.md) — the popup these servers feed
- [Pickers](pickers.md) — the window `gd`, `grr`, `gri` and `gO` open into
- [Keymap conventions](keymaps.md) — why the `gr*` namespace was adopted rather
  than replaced
