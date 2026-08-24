return {
  {
    "mfussenegger/nvim-dap",
    dependencies = { "mfussenegger/nvim-dap-python" },
    keys = {
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle breakpoint",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Condition: "))
        end,
        desc = "Conditional breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Continue",
      },
      {
        "<leader>dn",
        function()
          require("dap").step_over()
        end,
        desc = "Step over",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_out()
        end,
        desc = "Step out",
      },
      {
        "<leader>dq",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      -- python specific: debug test method / class under cursor
      {
        "<leader>dtm",
        function()
          require("dap-python").test_method()
        end,
        desc = "Debug test method",
      },
      {
        "<leader>dtc",
        function()
          require("dap-python").test_class()
        end,
        desc = "Debug test class",
      },
    },
    config = function()
      local dap_python = require("dap-python")

      -- The interpreter passed here runs the *adapter* (`-m debugpy.adapter`),
      -- so it is the one that needs debugpy importable. It is not the
      -- interpreter the program runs under — nvim-dap-python fills that in
      -- itself from VIRTUAL_ENV / CONDA_PREFIX per project, which is why there
      -- is no venv handling here.
      --
      -- Getting that backwards is how this came to be broken. It pointed at
      -- ~/.local/bin/python, which `uv tool install` never creates — uv
      -- symlinks a tool's entry points (debugpy, debugpy-adapter) and nothing
      -- else — and then preferred a project .venv, which does not carry debugpy
      -- either. Both branches were dead, in every project.
      local function adapter_python()
        -- Guarded rather than relying on v:shell_error: vim.fn.system() throws
        -- E475 when the command does not exist, so an unguarded call would
        -- raise here on a machine where uv is not yet installed — which is
        -- precisely the machine that has not been bootstrapped.
        if vim.fn.executable("uv") ~= 1 then
          return "python3"
        end
        local dir = vim.fn.system({ "uv", "tool", "dir" })
        if vim.v.shell_error == 0 then
          local p = vim.trim(dir) .. "/debugpy/bin/python"
          if vim.fn.executable(p) == 1 then
            return p
          end
        end
        return "python3"
      end

      dap_python.setup(adapter_python())

      -- ── Signs ─────────────────────────────────────────────────────────
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticInfo", linehl = "CursorLine" })
    end,
  },
  {
    "mfussenegger/nvim-dap-python",
    lazy = true,
  },
}
