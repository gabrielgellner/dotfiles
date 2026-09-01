local function augroup(name)
  return vim.api.nvim_create_augroup("nvim_" .. name, { clear = true })
end

-- ── Jinja templates ───────────────────────────────────────────────────────────
-- Neovim detects `.jinja` and nothing else, so `.j2` and `.jinja2` opened with
-- no filetype at all: no highlighting, no formatter. plugins/formatting.lua has
-- had djlint wired to `jinja`, `jinja2` and `htmldjango` all along, and only the
-- first of those three was a filetype anything could produce.
--
-- `*.html.j2` is the htmldjango case — a full HTML document with template tags,
-- which djlint wants to know about, since it indents the HTML around them.
vim.filetype.add({
  extension = {
    j2 = "jinja",
    jinja2 = "jinja",
  },
  pattern = {
    [".*%.html%.j2"] = "htmldjango",
  },
})

-- --- Detect filetype even if unset ----------------------------------------------
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = augroup("filetype_detect"),
  callback = function()
    if vim.bo.filetype == "" then
      vim.cmd("filetype detect")
    end
  end,
})

-- ── Run Lua from the buffer it lives in ───────────────────────────────────────
-- Snacks.debug.run() executes the buffer, or just the visual selection, with
-- print output inlined beside the code and errors raised as diagnostics. That is
-- what makes plugins/snacks.lua's <leader>nl pad a REPL, and the same thing is
-- worth having in real config files — try a function where it lives instead of
-- copying it into the pad.
--
-- Bound per-buffer rather than globally because it only means anything for Lua:
-- a global <leader>cx would appear in the code popup in every filetype and
-- error on each of them. Snacks is loaded eagerly (lazy = false), so the global
-- is safe to reference here.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("lua_run"),
  pattern = "lua",
  callback = function(ev)
    vim.keymap.set({ "n", "x" }, "<leader>cx", function()
      Snacks.debug.run()
    end, { buffer = ev.buf, desc = "Run Lua (buffer or selection)" })
  end,
})

-- ── Highlight on yank ─────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    -- vim.hl, not vim.highlight: renamed in Neovim 0.11 and listed in
    -- :help deprecated.txt. The old name is still an alias — same function
    -- object — so this was working, and would have kept working until the
    -- release that drops it.
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- ── Restore cursor position ───────────────────────────────────────────────────
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("restore_cursor"),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ── Close certain filetypes with q ────────────────────────────────────────────
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "startuptime",
    "checkhealth",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})

-- --- Setup common indent rules -------------------------------------------------
local lang_indent = {
  lua = 2,
  javascript = 2,
  typescript = 2,
  json = 2,
  yaml = 2,
  python = 4,
  rust = 4,
}

vim.api.nvim_create_autocmd("FileType", {
  -- Grouped like everything else here. Without it, re-sourcing this file stacks
  -- another copy rather than replacing the old one — every other autocmd in the
  -- file goes through augroup(), which clears first.
  group = augroup("lang_indent"),
  pattern = vim.tbl_keys(lang_indent),
  callback = function()
    local indent = lang_indent[vim.bo.filetype]
    vim.opt_local.shiftwidth = indent
    vim.opt_local.tabstop = indent
  end,
})

-- ── Markdown: no soft wrap (tables scroll), gq reflow to 120, prettier owns ──
-- ── hard-wrap on save. <leader>uw toggles soft wrap back on when wanted.    ──
--
-- 120 matches prettier: both this project's .prettierrc and the print-width
-- fallback in plugins/formatting.lua. One number everywhere, so a manual `gq`
-- and a format-on-save agree instead of fighting.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("markdown_wrap"),
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = false
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.textwidth = 120
    vim.opt_local.formatoptions:remove("t")
    vim.opt_local.formatoptions:append("qjn")
    vim.opt_local.colorcolumn = ""

    -- Exception: campaign/rules/** is auto-generated from Foundry JSON and is
    -- listed in .prettierignore, so nothing ever reflows it — some stat-block
    -- lines run past 400 chars. Hard-wrap can't help there, so soft-wrap these
    -- buffers instead and let them be readable. <leader>uw still toggles.
    if vim.api.nvim_buf_get_name(0):find("/campaign/rules/", 1, true) then
      vim.opt_local.wrap = true
    end

    -- Rules lookup from bare prose, e.g. "dimension door" in a generated stat
    -- block -> spells/translocate.md. Buffer-local and set here rather than in
    -- zk.lua's LspAttach, because the generated rules/ files this is most
    -- useful in aren't served by that LSP.
    --   <leader>zr  picker, seeded with every span under the cursor that
    --               resolves (Flame Strike *and* Strike), fuzzy over all rules
    --   <leader>zR  jump straight to the longest match, no prompt
    -- Under the zettelkasten group, not markdown: <leader>mr is already
    -- RenderMarkdown toggle, and a buffer-local map would silently shadow it.
    -- (<leader>mR was the other half of this argument when preview refresh
    -- lived there; it is on <leader>mf now, and mR is unclaimed.)
    local rules = require("config.rules_lookup")
    vim.keymap.set("n", "<leader>zr", rules.pick, { buffer = true, desc = "Rules: pick (under cursor + fuzzy all)" })
    vim.keymap.set("n", "<leader>zR", rules.goto_rule, { buffer = true, desc = "Rules: jump to name under cursor" })
    vim.keymap.set("x", "<leader>zr", rules.goto_rule_visual, { buffer = true, desc = "Rules: go to selection" })

    -- Task list checkboxes. See config/markdown_checkbox.lua for the toggle
    -- semantics; the keys are chosen as follows.
    --
    -- <CR> is the primary one, and buffer-local so quickfix, Trouble and the
    -- pickers keep theirs. Ticking a box is the highest-frequency action in a
    -- notes buffer, and a <leader> prefix would make it the most expensive one;
    -- <CR> is unbound as an lhs anywhere in this config, and its normal-mode
    -- default (down a line, first non-blank) is j/+ territory and worth nothing
    -- in prose.
    --
    -- <leader>mx is the same function under the `markdown` which-key group, so
    -- it's discoverable next to mr/mp/mP/mf once <CR> has been forgotten. `x`
    -- as in the x of [x].
    local checkbox = require("config.markdown_checkbox")
    vim.keymap.set({ "n", "x" }, "<CR>", checkbox.toggle, { buffer = true, desc = "Toggle checkbox" })
    vim.keymap.set({ "n", "x" }, "<leader>mx", checkbox.toggle, { buffer = true, desc = "Toggle checkbox" })
    vim.keymap.set("n", "]x", function()
      checkbox.next_unchecked(false)
    end, { buffer = true, desc = "Next unchecked box" })
    vim.keymap.set("n", "[x", function()
      checkbox.next_unchecked(true)
    end, { buffer = true, desc = "Prev unchecked box" })
  end,
})

-- ── Notice files edited outside Neovim ───────────────────────────────
-- 'autoread' is already on — it is a Neovim default, unlike Vim — but it only
-- acts at the moments Neovim happens to stat the file, which is essentially
-- never while you sit in a buffer. The missing half is a `:checktime` to
-- provoke the check; without it a file rewritten underneath you (chezmoi apply,
-- a formatter, an agent editing the repo) leaves a stale buffer.
--
-- The visible symptom is not the text — it is gitsigns. Signs are computed
-- against the *buffer*, so a stale buffer diffed against a moved HEAD marks
-- lines as removed that are present on disk.
--
-- FocusGained covers alt-tabbing back. CursorHold covers staying put inside
-- Neovim, which FocusGained never fires for; at updatetime=250 that is a stat
-- a quarter-second after you stop typing, not a poll.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    -- E11 in the command-line window, and a checktime is meaningless for a
    -- buffer with no file behind it (terminals, pickers, the dashboard).
    if vim.fn.getcmdwintype() ~= "" or vim.bo.buftype ~= "" then
      return
    end
    vim.cmd("checktime")
  end,
})

-- Say so when it happens. A buffer changing under the cursor with no message is
-- worse than a stale one: an undo now crosses a reload boundary.
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = augroup("checktime_notify"),
  callback = function()
    vim.notify("Reloaded from disk (changed outside Neovim)", vim.log.levels.INFO)
  end,
})

-- ── Auto-resize splits on window resize ──────────────────────────────────────
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- ── plv: formats Neovim must not read ────────────────────────────────────────
-- BufReadCmd replaces the read entirely, which is the point: a parquet that
-- reaches a buffer is one a stray `:w` corrupts (measured — see config/plv.lua).
-- Registered for the extensions in plv.BINARY, and it protects the file whether
-- or not plv is installed to show it.
vim.api.nvim_create_autocmd("BufReadCmd", {
  group = vim.api.nvim_create_augroup("plv_binary_formats", { clear = true }),
  pattern = { "*.parquet", "*.ducklake" },
  callback = function(ev)
    require("config.plv").open_binary(ev.buf, ev.file)
  end,
})
