# Debugging

`nvim-dap`, and **no dap-ui**. There is no panel layout, no variable pane and no
virtual text — the REPL on `<leader>dr` is the interface, and the sign column
tells you where you are.

Two languages are wired up: python through `nvim-dap-python`, and rust through
rustaceanvim, which drives the adapter itself.

## Keys

| Key           | Does                         |
| ------------- | ---------------------------- |
| `<leader>db`  | toggle breakpoint            |
| `<leader>dB`  | conditional breakpoint       |
| `<leader>dc`  | continue / start             |
| `<leader>dn`  | step over (**n**ext)         |
| `<leader>di`  | step into                    |
| `<leader>do`  | step out                     |
| `<leader>dq`  | terminate                    |
| `<leader>dr`  | toggle the REPL              |
| `<leader>dtm` | debug the test **m**ethod    |
| `<leader>dtc` | debug the test **c**lass     |

`dn` for step-over rather than the more obvious `ds`: step over is the one you
press repeatedly, and it is the **n**ext line. `dc` both starts a session and
continues a stopped one, which is dap's own behaviour rather than two keys.

`<leader>dtm` and `<leader>dtc` are python-only — they come from
nvim-dap-python and run the test under the cursor.

## What you see

| Sign | Means                       |
| ---- | --------------------------- |
| `●`  | breakpoint                  |
| `◆`  | conditional breakpoint      |
| `▶`  | stopped here (line highlighted) |

Everything else is the REPL. `<leader>dr` opens it; it takes expressions in the
current frame, and dap's own commands (`.scopes`, `.frames`, `.help`) list what
else it can do.

## Python

The interpreter `nvim-dap-python` is given runs the **adapter**
(`-m debugpy.adapter`), and is *not* the interpreter your program runs under —
that one nvim-dap-python works out per project from `VIRTUAL_ENV`. So there is
no venv handling in the config, and none is wanted.

**Getting that backwards is how this was broken.** It pointed at
`~/.local/bin/python`, which `uv tool install` never creates — uv symlinks a
tool's entry points and nothing else — and then preferred a project `.venv`,
which does not carry debugpy either. Both branches were dead, in every project.
It now asks `uv tool dir` for debugpy's own interpreter and falls back to
`python3`.

So debugpy belongs to **uv**, not to your project venv:

```
uv tool list          # debugpy should be here
uv tool install debugpy
```

## Rust

rustaceanvim finds and configures the adapter; there is no dap configuration for
rust in this repo at all. What it needs is `codelldb`, and two things about that
are worth knowing because both have bitten.

**`~/bin/codelldb` is a wrapper, not a symlink.** CodeLLDB locates `liblldb`
relative to its own `argv[0]`, so a symlink in `~/bin` sends it looking for
`~/lldb/lib/liblldb.dylib` and it aborts. The wrapper passes `--liblldb`
explicitly. The adapter itself is not tracked — `bootstrap.sh` unpacks a pinned
release into `~/.local/opt/codelldb`, because upstream ships a VS Code `.vsix`
and there is no Homebrew formula.

**The obvious alternative does not work.** rustaceanvim prefers `lldb-dap` when
it is present, and `lldb-dap` hangs on rustaceanvim's `runInTerminal`
handshake — reproduced here on macOS, and nvim-dap #1437 is the same stall on
Linux, so a newer `lldb-dap` is not the fix. codelldb registers as a `server`
adapter, which never goes near that path. The long comment in
`plugins/rust.lua` has the detail.

Neither adapter can call a Rust function from the expression evaluator, which
is a limitation of the adapters rather than of this setup — print debugging
still has its place.

## See also

- [LSP](lsp.md) — the rest of what a language server gives you
- [Floats](floats.md) — the window the REPL shares its shape with
