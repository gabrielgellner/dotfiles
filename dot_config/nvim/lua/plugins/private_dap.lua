-- ============================================================================
-- plugins/dap.lua
-- ============================================================================

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = { "mfussenegger/nvim-dap-python" },
    keys = {
      { "<leader>db",  function() require("dap").toggle_breakpoint() end,            desc = "Toggle breakpoint" },
      { "<leader>dB",  function()
          require("dap").set_breakpoint(vim.fn.input("Condition: "))
        end,                                                                          desc = "Conditional breakpoint" },
      { "<leader>dc",  function() require("dap").continue() end,                     desc = "Continue" },
      { "<leader>dn",  function() require("dap").step_over() end,                    desc = "Step over" },
      { "<leader>di",  function() require("dap").step_into() end,                    desc = "Step into" },
      { "<leader>do",  function() require("dap").step_out() end,                     desc = "Step out" },
      { "<leader>dq",  function() require("dap").terminate() end,                    desc = "Terminate" },
      { "<leader>dr",  function() require("dap").repl.toggle() end,                  desc = "Toggle REPL" },
      -- python specific: debug test method / class under cursor
      { "<leader>dtm", function() require("dap-python").test_method() end,           desc = "Debug test method" },
      { "<leader>dtc", function() require("dap-python").test_class() end,            desc = "Debug test class" },
    },
    config = function()
      local dap_python = require("dap-python")

      -- use the nvim-tools venv python which has debugpy installed:
      --   uv tool install debugpy  (or pip install debugpy in ~/.venvs/nvim-tools)
      local python_path = vim.fn.expand("~/.local/bin/python")

      -- fallback: prefer project venv if it exists
      local project_venv = vim.fn.getcwd() .. "/.venv/bin/python"
      if vim.fn.filereadable(project_venv) == 1 then
        python_path = project_venv
      end

      dap_python.setup(python_path)

      -- ── Signs ─────────────────────────────────────────────────────────
      vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DiagnosticInfo", linehl = "CursorLine" })
    end,
  },
  {
    "mfussenegger/nvim-dap-python",
    lazy = true,
  },
}
