-- ============================================================================
-- config/options.lua
-- ============================================================================

local opt          = vim.opt

-- ── UI ────────────────────────────────────────────────────────────────────────
opt.number         = true
opt.relativenumber = true
opt.signcolumn     = "yes" -- always show, prevents layout shifts
opt.cursorline     = true
opt.scrolloff      = 2
opt.sidescrolloff  = 2
opt.wrap           = false
opt.termguicolors  = true
opt.showmode       = false -- lualine / mini.statusline handles this
opt.cmdheight      = 1
opt.pumheight      = 10    -- max completion menu items
opt.splitright     = true
opt.splitbelow     = true

-- ── Editing ───────────────────────────────────────────────────────────────────
opt.expandtab      = true
opt.tabstop        = 4
opt.shiftwidth     = 4
opt.softtabstop    = 4
opt.smartindent    = true
opt.breakindent    = true

-- ── Search ────────────────────────────────────────────────────────────────────
opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = true
opt.incsearch      = true

-- ── Files ─────────────────────────────────────────────────────────────────────
opt.undofile       = true -- persistent undo
opt.swapfile       = false
opt.backup         = false
opt.updatetime     = 250 -- faster CursorHold (used by LSP)
opt.timeoutlen     = 300

-- ── Completion ────────────────────────────────────────────────────────────────
opt.completeopt    = { "menu", "menuone", "noselect" }

-- ── Folding (treesitter-powered) ──────────────────────────────────────────────
opt.foldmethod     = "expr"
opt.foldexpr       = "nvim_treesitter#foldexpr()"
opt.foldenable     = false -- open all folds by default

-- ── Misc ──────────────────────────────────────────────────────────────────────
opt.clipboard      = "unnamedplus" -- sync with system clipboard
opt.mouse          = "a"
opt.fileencoding   = "utf-8"
opt.conceallevel   = 0
