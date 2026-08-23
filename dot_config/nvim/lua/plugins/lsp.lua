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
        map("<leader>lr", function()
          -- Restart every server attached to this buffer (config-agnostic;
          -- works with vim.lsp.enable, no lspconfig commands needed).
          local names = {}
          for _, client in ipairs(vim.lsp.get_clients({ bufnr = event.buf })) do
            names[client.name] = true
          end
          for name in pairs(names) do
            vim.lsp.enable(name, false)
          end
          -- Re-enable after a beat so clients fully stop before relaunch.
          vim.defer_fn(function()
            for name in pairs(names) do
              vim.lsp.enable(name)
            end
            vim.notify("LSP restarted: " .. table.concat(vim.tbl_keys(names), ", "))
          end, 300)
        end, "Restart LSP")
      end,
    })

    -- ── pyrefly ───────────────────────────────────────────────────────────
    -- Fast LSP type checking for the editor. basedpyright is kept for
    -- CI / `just` checks where broader coverage matters. Pyrefly auto-detects
    -- `.venv`, but we pass the interpreter explicitly via initializationOptions.
    -- Note: pyrefly has no per-rule severity overrides like basedpyright's
    -- diagnosticSeverityOverrides; use a pyrefly.toml `[errors]` table per
    -- project if you need to silence specific checks.
    vim.lsp.config("pyrefly", {
      capabilities = capabilities,
      cmd = { "pyrefly", "lsp" },
      filetypes = { "python" },
      root_markers = { "pyrefly.toml", "pyproject.toml", "setup.py", ".git" },
      before_init = function(_, config)
        -- Resolve the interpreter from the LSP root (folder matched by
        -- root_markers), not nvim's cwd — otherwise opening a file from a
        -- session rooted elsewhere makes pyrefly miss .venv and fall back to
        -- system python (which lacks your uv-installed packages).
        local root = config.root_dir or vim.fn.getcwd()
        local venv = root .. "/.venv"
        if vim.fn.isdirectory(venv) == 1 then
          config.init_options = config.init_options or {}
          config.init_options.pythonPath = venv .. "/bin/python"
        end
      end,
      init_options = {
        pyrefly = {
          typeCheckingMode = "default",
        },
      },
    })
    vim.lsp.enable("pyrefly")

    -- ── ruff ──────────────────────────────────────────────────────────────
    vim.lsp.config("ruff", {
      capabilities = capabilities,
      cmd = { "ruff", "server" },
      filetypes = { "python" },
      root_markers = { "pyproject.toml", "ruff.toml", ".git" },
      on_attach = function(client)
        -- pyrefly owns hover; ruff handles diagnostics + formatting only
        client.server_capabilities.hoverProvider = false
      end,
    })
    vim.lsp.enable("ruff")

    -- ── just_lsp ──────────────────────────────────────────────────────────
    -- terror/just-lsp (brew install just-lsp): completion for builtin
    -- functions/constants, goto-definition and rename for recipes/variables,
    -- and parse diagnostics from tree-sitter-just. Formatting comes from
    -- `just --fmt` via conform (see plugins/formatting.lua), not the server.
    vim.lsp.config("just_lsp", {
      capabilities = capabilities,
      cmd = { "just-lsp" },
      filetypes = { "just" },
      root_markers = { "justfile", "Justfile", ".justfile", ".git" },
    })
    vim.lsp.enable("just_lsp")

    -- ── lua_ls (for editing this config) ─────────────────────────────────
    vim.lsp.config("lua_ls", {
      capabilities = capabilities,
      cmd = { "lua-language-server" },
      filetypes = { "lua" },
      root_markers = { ".luarc.json", ".git" },
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          -- No workspace.library here on purpose: lazydev owns that key and
          -- pushes plugin paths on demand (see plugins/lazydev.lua). Setting it
          -- statically would be the slow version of the same thing, and a
          -- second writer of the key is one more thing to keep in sync.
          workspace = { checkThirdParty = false },
          diagnostics = { globals = { "vim", "Snacks" } },
          telemetry = { enable = false },
        },
      },
    })
    vim.lsp.enable("lua_ls")
  end,
}
