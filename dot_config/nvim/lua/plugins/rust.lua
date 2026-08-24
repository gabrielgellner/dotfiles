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
      local function lldb_dap()
        if vim.fn.executable("lldb-dap") == 1 then
          return "lldb-dap"
        end
        local found = vim.fn.system({ "xcrun", "-f", "lldb-dap" })
        if vim.v.shell_error == 0 and vim.trim(found) ~= "" then
          return vim.trim(found)
        end
        local brewed = "/opt/homebrew/opt/llvm/bin/lldb-dap"
        if vim.fn.executable(brewed) == 1 then
          return brewed
        end
      end

      vim.g.rustaceanvim = {
        -- Left to rustaceanvim's own detection when nothing is found: it returns
        -- false there, which disables dap rather than erroring.
        dap = (function()
          local cmd = lldb_dap()
          return cmd and { adapter = { type = "executable", command = cmd, name = "lldb" } } or nil
        end)(),
        server = {
          settings = {
            ["rust-analyzer"] = {
              checkOnSave = {
                command = "clippy", -- use clippy instead of cargo check
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
              preferredMRO = "markdown",
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
