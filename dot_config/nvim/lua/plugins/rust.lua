-- rustaceanvim - LSP + rust-specific features
return {
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    lazy = false,
    config = function()
      -- Two adapters can drive Rust debugging, and rustaceanvim prefers them
      -- in this order: mason's codelldb, `codelldb` on PATH, then
      -- `lldb-dap`/`lldb-vscode`. It never looks for plain `lldb` — that is the
      -- interactive debugger, not the DAP adapter, which is why
      -- /usr/bin/lldb being present does not satisfy it.
      --
      -- codelldb is the one to have, and bootstrap.sh installs it: the release
      -- is a VS Code .vsix (a zip), unpacked to ~/.local/opt/codelldb, with
      -- bin/executable_codelldb on PATH as a wrapper. The wrapper exists
      -- because codelldb finds liblldb relative to argv[0], so a bare symlink
      -- into ~/bin makes it look for ~/lldb/lib/liblldb.dylib and abort; the
      -- wrapper passes --liblldb explicitly.
      --
      -- Nothing below configures codelldb. rustaceanvim's own detection builds
      -- it as an adapter with type = "server", and the whole point of getting
      -- there is that the server path never touches runInTerminal.
      --
      -- runInTerminal is the trap. rustaceanvim hardcodes runInTerminal = true
      -- for an lldb adapter with type = "executable", and lldb-dap then fails
      -- that handshake:
      --
      --   Error on launch: Failed to attach to the target process.
      --   Timed out trying to get messages from the runInTerminal launcher
      --
      -- Reproduced on this machine (macOS 26.5.2, Apple's lldb-dap). It is not
      -- an Apple bug — nvim-dap #1437 is the same stall on Linux with LLVM 19 —
      -- so a newer lldb-dap is not the fix, and brewed llvm is not worth
      -- preferring over the Command Line Tools copy.
      --
      -- So: use codelldb when it is there, and when it is not, take lldb-dap
      -- but override `configuration` (which rustaceanvim exposes for exactly
      -- this) to turn runInTerminal off. Both were run against a real binary
      -- here: each attaches, stops on the breakpoint, reads locals back and
      -- steps. Under codelldb a `String` prints as "frappe" with its Rust type,
      -- and `println!` output lands in the [dap-terminal] buffer; the lldb-dap
      -- fallback gets the program no terminal at all, so that output goes
      -- nowhere. Restoring stdout is the reason codelldb is first.
      --
      -- Neither adapter can call a Rust function from the expression evaluator
      -- (`add(x, 10)` fails under both) — that is an LLDB limitation, not
      -- something this config chose.
      local function lldb_dap()
        if vim.fn.executable("lldb-dap") == 1 then
          return "lldb-dap"
        end
        -- Guarded, not just checked afterwards: vim.fn.system() with a list
        -- *throws* E475 when the command does not exist rather than setting
        -- v:shell_error, so calling xcrun unguarded would raise inside this
        -- config function on any machine without Xcode tools.
        if vim.fn.executable("xcrun") == 1 then
          local found = vim.fn.system({ "xcrun", "-f", "lldb-dap" })
          if vim.v.shell_error == 0 and vim.trim(found) ~= "" then
            return vim.trim(found)
          end
        end
      end

      -- nil, not false: an absent key leaves rustaceanvim's detection alone,
      -- which is what finds codelldb. `false` would disable dap outright.
      local function dap_fallback()
        if vim.fn.executable("codelldb") == 1 then
          return nil
        end
        local cmd = lldb_dap()
        if not cmd then
          return nil
        end
        return {
          adapter = { type = "executable", command = cmd, name = "lldb" },
          configuration = {
            name = "Rust debug client",
            type = "lldb",
            request = "launch",
            stopOnEntry = false,
            runInTerminal = false,
          },
        }
      end

      vim.g.rustaceanvim = {
        dap = dap_fallback(),
        server = {
          settings = {
            ["rust-analyzer"] = {
              -- checkOnSave is a *boolean* in this rust-analyzer ("Run the
              -- check command for diagnostics on save", default true); the
              -- command moved to check.command. The old nested shape is still
              -- honoured — clippy lints did appear with it — but it is writing
              -- a table where the schema says boolean, and legacy aliases are
              -- exactly the thing that stops being honoured one day.
              checkOnSave = true,
              check = {
                command = "clippy", -- clippy's lints, not just cargo check's
              },
              -- Only the two that differ from rust-analyzer's own defaults.
              -- `chainingHints` and `typeHints` were here set to `true`, which
              -- is what they already are — read off the installed binary with
              -- `rust-analyzer --print-config-schema`, not the docs.
              inlayHints = {
                bindingModeHints = { enable = true }, -- default false
                closureReturnTypeHints = { enable = "always" }, -- default "never"
              },
              -- `allFeatures = true` was here and is not a key this
              -- rust-analyzer has — it is absent from the config schema
              -- entirely. The spelling that passes --all-features to cargo is
              -- `features = "all"`, a string the schema documents as an
              -- alternative to the list form (default `[]`).
              cargo = {
                features = "all",
              },
            },
          },
        },
      }
    end,
  },
  -- crates.nvim - dependency version hints in Cargo.toml
  {
    "saecki/crates.nvim",
    event = "BufRead Cargo.toml",
    config = function()
      require("crates").setup()
    end,
  },
}
