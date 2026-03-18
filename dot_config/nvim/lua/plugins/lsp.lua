return {
  "neovim/nvim-lspconfig", -- still needed for server definitions/defaults
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- ── Capabilities (with nvim-cmp) ──────────────────────────────────────
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok then
      capabilities = cmp_lsp.default_capabilities(capabilities)
    end

    -- ── Diagnostics ───────────────────────────────────────────────────────
    vim.diagnostic.config({
      virtual_text = { prefix = "●" },
      update_in_insert = false,
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "󰅚 ",
          [vim.diagnostic.severity.WARN] = "󰀪 ",
          [vim.diagnostic.severity.HINT] = "󰌶 ",
          [vim.diagnostic.severity.INFO] = "󰋽 ",
        },
      },
      float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = true,
      },
    })

    -- ── LspAttach — keymaps set once per buffer ───────────────────────────
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("nvim_lsp_attach", { clear = true }),
      callback = function(event)
        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        map("K", vim.lsp.buf.hover, "Hover docs")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
        map("<leader>cf", function()
          require("conform").format({ async = true, lsp_fallback = true })
        end, "Format buffer")
        map("[d", function()
          vim.diagnostic.jump({ count = -1 })
        end, "Prev diagnostic")
        map("]d", function()
          vim.diagnostic.jump({ count = 1 })
        end, "Next diagnostic")
        map("[e", function()
          vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
        end, "Prev error")
        map("]e", function()
          vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
        end, "Next error")
        map("<leader>e", vim.diagnostic.open_float, "Show diagnostic")
      end,
    })

    -- ── basedpyright ──────────────────────────────────────────────────────
    vim.lsp.config("basedpyright", {
      capabilities = capabilities,
      cmd = { "basedpyright-langserver", "--stdio" },
      filetypes = { "python" },
      root_markers = { "pyproject.toml", "setup.py", ".git" },
      before_init = function(_, config)
        local venv = vim.fn.getcwd() .. "/.venv"
        if vim.fn.isdirectory(venv) == 1 then
          config.settings = config.settings or {}
          config.settings.python = { pythonPath = venv .. "/bin/python" }
        end
      end,
      settings = {
        basedpyright = {
          analysis = {
            typeCheckingMode = "standard",
            autoImportCompletions = true,
            venvPath = ".",
            venv = ".venv",
            diagnosticSeverityOverrides = {
              reportUnknownMemberType = "none",
              reportUnknownArgumentType = "none",
            },
          },
        },
      },
    })
    vim.lsp.enable("basedpyright")

    -- ── ruff ──────────────────────────────────────────────────────────────
    vim.lsp.config("ruff", {
      capabilities = capabilities,
      cmd = { "ruff", "server" },
      filetypes = { "python" },
      root_markers = { "pyproject.toml", "ruff.toml", ".git" },
      on_attach = function(client)
        -- basedpyright owns hover; ruff handles diagnostics + formatting only
        client.server_capabilities.hoverProvider = false
      end,
    })
    vim.lsp.enable("ruff")

    -- ── lua_ls (for editing this config) ─────────────────────────────────
    vim.lsp.config("lua_ls", {
      capabilities = capabilities,
      cmd = { "lua-language-server" },
      filetypes = { "lua" },
      root_markers = { ".luarc.json", ".git" },
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          workspace = {
            checkThirdParty = false,
            library = vim.api.nvim_get_runtime_file("", true),
          },
          diagnostics = { globals = { "vim", "Snacks" } },
          telemetry = { enable = false },
        },
      },
    })
    vim.lsp.enable("lua_ls")
  end,
}
