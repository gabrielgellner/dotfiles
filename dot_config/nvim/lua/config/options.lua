local opt = vim.opt

-- ── UI ────────────────────────────────────────────────────────────────────────
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes" -- always show, prevents layout shifts
opt.cursorline = true
-- Deliberately small. A big 'scrolloff' *costs* <C-e>/<C-y> runway rather than
-- buying it: the cursor is dragged once it comes within scrolloff lines of the
-- edge, so every line of padding is a line the viewport can no longer move
-- past it. Measured from a centred cursor in a 28-line text area, 3<C-e> a
-- press: scrolloff=2 gives 3 presses before the cursor moves, scrolloff=8
-- gives 1. 8 also ate enough of the screen that the usable area felt wrong.
opt.scrolloff = 2
opt.sidescrolloff = 2
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
-- The expression dispatches per buffer: a language server's folds where one can
-- provide them, treesitter's otherwise, and "0" — no folds — for a filetype with
-- neither. See config/folds.lua, which is required here rather than lazily from
-- the expression so its LspAttach invalidation is registered at startup.
require("config.folds")
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.require'config.folds'.expr()"
opt.foldenable = true
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldtext = "" -- empty picks nvim's built-in, which keeps treesitter colours
opt.fillchars:append({ fold = " ", foldopen = "▾", foldclose = "▸", foldsep = " " })

-- ── Spelling ──────────────────────────────────────────────────────────────────
-- 'spellfile' has to be set explicitly for zg/zw to write somewhere tracked.
-- Left empty, Neovim makes up a path from the first writable 'runtimepath'
-- directory ending in spell/ — which is stdpath("data") .. "/site/spell", not
-- the config directory. Words added there are outside chezmoi entirely and
-- never reach another machine.
--
-- The file itself lives in the chezmoi source, so the word list is versioned.
-- Neovim compiles a .spl sidecar beside it, which is a build artifact and stays
-- untracked. 'spell' itself is left off globally and switched on per-window
-- (config/scratch.lua, config/guides.lua) where prose is expected.
opt.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"

-- ── Misc ──────────────────────────────────────────────────────────────────────
opt.clipboard = "unnamedplus" -- sync with system clipboard
opt.mouse = "a"
opt.fileencoding = "utf-8"
opt.conceallevel = 0
