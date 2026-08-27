-- rustaceanvim - LSP + rust-specific features
return {
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    lazy = false,
    config = function()
      -- rustaceanvim looks for mason's codelldb, then `codelldb`, then
      -- `lldb-dap`/`lldb-vscode` on PATH. It never looks for plain `lldb`, which
      -- is why /usr/bin/lldb being present does not satisfy it — that is the
      -- interactive debugger, not the DAP adapter.
      --
      -- macOS ships lldb-dap inside the Command Line Tools, which are not on
      -- PATH; `xcrun -f` is the supported way to locate them. Homebrew's llvm
      -- has one too, but it is keg-only on purpose — putting that bin directory
      -- on PATH shadows the system clang — so it is reached by full path rather
      -- than by exporting anything.
      -- Homebrew's llvm is tried before the Command Line Tools copy, and the
      -- order matters. rustaceanvim sets runInTerminal = true, and Apple's
      -- lldb-dap fails that handshake on macOS 26:
      --
      --   launch failed: Failed to attach to the target process. Timed out
      --   trying to get messages from the runInTerminal launcher
      --
      -- nvim-dap does spawn the terminal and reports a pid back; Apple's
      -- adapter then times out reading its own comm-file. LLVM 22's lldb-dap
      -- launches the same target, hits breakpoints and runs to exit 0. The CLT
      -- path stays as a fallback because it is present on any Mac with Xcode
      -- tools, and a debugger that may fail to launch beats none at all.
      local function lldb_dap()
        -- HOMEBREW_PREFIX rather than a literal: brew lives at /opt/homebrew on
        -- Apple silicon and /home/linuxbrew/.linuxbrew on the Linux machine, and
        -- dot_zshrc exports it from `brew shellenv` before nvim ever starts.
        local prefix = vim.env.HOMEBREW_PREFIX
        if prefix then
          local brewed = prefix .. "/opt/llvm/bin/lldb-dap"
          if vim.fn.executable(brewed) == 1 then
            return brewed
          end
        end
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

      vim.g.rustaceanvim = {
        -- Left to rustaceanvim's own detection when nothing is found: it returns
        -- false there, which disables dap rather than erroring.
        dap = (function()
          local cmd = lldb_dap()
          if not cmd then
            return nil
          end
          return {
            adapter = { type = "executable", command = cmd, name = "lldb" },
            -- runInTerminal = false is what makes Apple's lldb-dap work.
            --
            -- rustaceanvim hardcodes runInTerminal = true for any adapter with
            -- type = "executable" (config/internal.lua: `if type == 'lldb'`),
            -- and Apple's adapter fails that handshake on macOS 26.5.2:
            --
            --   Error on launch: Failed to attach to the target process.
            --   Timed out trying to get messages from the runInTerminal launcher
            --
            -- Reproduced on this machine, then fixed by overriding the whole
            -- `configuration` — which rustaceanvim exposes for exactly this.
            -- After: the session attaches, stops on the breakpoint, `a` reads
            -- back `(int) $0 = 2`, and step-over advances.
            --
            -- The cost is that the program gets no terminal, so its stdout is
            -- not shown anywhere — `println!` output vanishes. A debugger that
            -- stops where you asked beats one that never launches, and a
            -- program whose output you want can be run with `cargo run`.
            configuration = {
              name = "Rust debug client",
              type = "lldb",
              request = "launch",
              stopOnEntry = false,
              runInTerminal = false,
            },
          }
        end)(),
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
              inlayHints = {
                bindingModeHints = { enable = true },
                chainingHints = { enable = true },
                closureReturnTypeHints = { enable = "always" },
                typeHints = { enable = true },
              },
              cargo = {
                allFeatures = true,
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
