local function augroup(name)
  return vim.api.nvim_create_augroup("nvim_" .. name, { clear = true })
end

-- --- Detect filetype even if unset ----------------------------------------------
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = augroup("filetype_detect"),
  callback = function()
    if vim.bo.filetype == "" then
      vim.cmd("filetype detect")
    end
  end,
})

-- ── Highlight on yank ─────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
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
  pattern = vim.tbl_keys(lang_indent),
  callback = function()
    local indent = lang_indent[vim.bo.filetype]
    vim.opt_local.shiftwidth = indent
    vim.opt_local.tabstop = indent
  end,
})
-- ── Python specific ───────────────────────────────────────────────────────────
-- vim.api.nvim_create_autocmd("FileType", {
--   group    = augroup("python"),
--   pattern  = "python",
--   callback = function()
--     vim.opt_local.tabstop    = 4
--     vim.opt_local.shiftwidth = 4
--   end,
-- })

-- ── Markdown: soft wrap + gq reflow to 80, prettier owns hard-wrap on save ──
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("markdown_wrap"),
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.textwidth = 80
    vim.opt_local.formatoptions:remove("t")
    vim.opt_local.formatoptions:append("qjn")
    vim.opt_local.colorcolumn = ""
  end,
})

-- ── Auto-resize splits on window resize ──────────────────────────────────────
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})
