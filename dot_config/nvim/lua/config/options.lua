local opt = vim.opt

-- ── UI ────────────────────────────────────────────────────────────────────────
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes" -- always show, prevents layout shifts
opt.cursorline = true
-- Deliberately generous: 'scrolloff' is the runway <C-e>/<C-y> get to move the
-- viewport before the cursor is dragged along, so a small value makes
-- "scroll without moving the cursor" barely work at all. 8 also keeps a few
-- lines of context visible past the cursor when reading downward.
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.termguicolors = true
opt.showmode = false -- lualine / mini.statusline handles this
opt.cmdheight = 1
opt.pumheight = 10 -- max completion menu items
opt.splitright = true
opt.splitbelow = true

-- ── Editing ───────────────────────────────────────────────────────────────────
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.smartindent = true
opt.breakindent = true

-- ── Search ────────────────────────────────────────────────────────────────────
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- ── Files ─────────────────────────────────────────────────────────────────────
opt.undofile = true -- persistent undo
opt.swapfile = false
opt.backup = false
opt.updatetime = 250 -- faster CursorHold (used by LSP)
opt.timeoutlen = 300

-- ── Completion ────────────────────────────────────────────────────────────────
opt.completeopt = { "menu", "menuone", "noselect" }

-- ── Folding ('foldmethod'/'foldexpr' set per-buffer by treesitter.lua) ────────
-- Folds are on but start fully open. 'foldlevel' 99 is deeper than any real
-- nesting, so nothing is ever closed when you arrive at a file, while zM/zR/za
-- stay live as reading tools — zM collapses a buffer to its signatures.
--
-- 'foldenable' = false would have been the other way to get "never folded on
-- open", but it disables folding outright: zM has to switch it back on first,
-- and zc/za do nothing until it does.
-- Set globally rather than per-window from the FileType autocmd, which is how
-- this used to work. 'foldmethod' and 'foldexpr' are window-local, and that had
-- two holes: the very first file of a session got 'foldexpr' but kept
-- foldmethod=manual (so zM silently did nothing until you opened a second
-- file), and a new split started from the global default rather than
-- inheriting. As a global default both are simply always right.
--
-- vim.treesitter.foldexpr() returns "0" for a filetype with no parser, so
-- unparsed files just get no folds instead of an error.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = true
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldtext = "" -- empty picks nvim's built-in, which keeps treesitter colours
opt.fillchars:append({ fold = " ", foldopen = "▾", foldclose = "▸", foldsep = " " })

-- ── Misc ──────────────────────────────────────────────────────────────────────
opt.clipboard = "unnamedplus" -- sync with system clipboard
opt.mouse = "a"
opt.fileencoding = "utf-8"
opt.conceallevel = 0
