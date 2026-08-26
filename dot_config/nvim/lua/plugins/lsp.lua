return {
  "neovim/nvim-lspconfig", -- still needed for server definitions/defaults
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- ── Capabilities ──────────────────────────────────────────────────────
    -- This asked cmp_nvim_lsp, which is not installed and will not be: the
    -- completion engine here is blink.cmp. The pcall meant the dead branch was
    -- silent, so every server was started with plain
    -- make_client_capabilities().
    --
    -- Mostly that cost nothing, because Neovim's own defaults have caught up —
    -- snippetSupport, insertReplaceSupport, contextSupport and itemDefaults are
    -- all advertised without help. The measurable gap was resolveSupport:
    -- clients offered { additionalTextEdits, command, documentation } where
    -- blink asks for `detail` and `data` as well, which is what lets a server
    -- defer a completion item's type signature to the resolve request instead
    -- of sending it with every candidate.
    --
    -- blink is lazy = false and already loaded by the time lspconfig configures
    -- (this loads on BufReadPre), so requiring it here forces nothing early.
    -- (nil, true), not (capabilities). The first argument *overrides* blink's
    -- table and is applied last, so handing it Neovim's defaults puts the
    -- three-property resolveSupport back on top of blink's five and undoes the
    -- whole point. `true` asks blink to start from those defaults itself.
    local ok, blink = pcall(require, "blink.cmp")
    local capabilities = ok and blink.get_lsp_capabilities(nil, true) or vim.lsp.protocol.make_client_capabilities()

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
        local map = function(keys, func, desc, mode)
          vim.keymap.set(mode or "n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        map("K", vim.lsp.buf.hover, "Hover docs")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
        map("<leader>cf", function()
          require("conform").format({ async = true, lsp_fallback = true })
        end, "Format buffer")
        -- No [d/]d here. plugins/trouble.lua binds those globally to a version
        -- that steps the Trouble list when it is open and falls back to this
        -- exact vim.diagnostic.jump call when it is not. Defining them here made
        -- them buffer-local, which always beats a global mapping — so the
        -- Trouble half never ran in any buffer with a client attached, which is
        -- every buffer that has diagnostics to jump between.
        --
        -- [e/]e stay: nothing else defines an errors-only motion.
        local diag_jump = function(count, severity)
          return function()
            vim.diagnostic.jump({ count = count, severity = severity })
          end
        end
        local ERROR = vim.diagnostic.severity.ERROR
        map("[e", diag_jump(-1, ERROR), "Prev error", { "n", "x", "o" })
        map("]e", diag_jump(1, ERROR), "Next error", { "n", "x", "o" })
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

    -- ── bashls ────────────────────────────────────────────────────────────
    -- bash-language-server (brew install bash-language-server): completion,
    -- goto-definition for functions and sourced files, rename, and hover that
    -- pulls the flag descriptions out of explainshell.
    --
    -- It shells out to shellcheck for diagnostics itself, and offers the
    -- fixes as code actions, which nvim-lint cannot do — so shellcheck was
    -- removed from plugins/lint.lua when this went in. Running both reports
    -- every finding twice.
    --
    -- `sh` only, never `zsh`: Neovim gives every shell script filetype `sh`
    -- regardless of dialect, and this server would parse zsh as bash and
    -- invent errors. The zsh scripts in bin/ have no server.
    vim.lsp.config("bashls", {
      capabilities = capabilities,
      cmd = { "bash-language-server", "start" },
      filetypes = { "sh" },
      root_markers = { ".git" },
    })
    vim.lsp.enable("bashls")

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
          -- Duplicated in .luarc.json at the root of the dotfiles repo, and
          -- that copy wins wherever it exists — lua_ls prefers a workspace
          -- .luarc.json over anything the client sends, which is verifiable by
          -- adding a name to one file and not the other. This list is therefore
          -- the fallback, for lua buffers outside such a workspace. Add a global
          -- to both or it resolves in one place and not the other.
          diagnostics = { globals = { "vim", "Snacks" } },
          telemetry = { enable = false },
        },
      },
    })
    vim.lsp.enable("lua_ls")
  end,
}
