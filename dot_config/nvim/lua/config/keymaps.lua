local map = vim.keymap.set

-- ── Leader ────────────────────────────────────────────────────────────────────
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- ── Better defaults ───────────────────────────────────────────────────────────
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "j", "gj", { desc = "Visual line down" })
map("n", "k", "gk", { desc = "Visual line up" })
map("n", "n", "nzzzv", { desc = "Next match (centred)" })
map("n", "N", "Nzzzv", { desc = "Prev match (centred)" })
map("n", "<C-d>", "<C-d>", { desc = "Scroll down" })
map("n", "<C-u>", "<C-u>", { desc = "Scroll up" })

-- ── Windows ───────────────────────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<leader>-", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>|", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>wd", "<C-w>c", { desc = "Close window" })

-- ── Buffers ───────────────────────────────────────────────────────────────────
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
-- <leader>bd is bound by mini.bufremove in plugins/mini.lua (keeps window layout)
vim.keymap.set("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
      vim.cmd("bd " .. buf)
    end
  end
end, { desc = "Close other buffers" })

-- ── Move lines ────────────────────────────────────────────────────────────────
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- ── Indenting in visual mode (keep selection) ─────────────────────────────────
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- ── Quickfix ──────────────────────────────────────────────────────────────────
map("n", "<leader>xq", "<cmd>copen<CR>", { desc = "Quickfix list" })
map("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix" })
map("n", "[q", "<cmd>cprev<CR>", { desc = "Prev quickfix" })

-- ── Misc ──────────────────────────────────────────────────────────────────────
map("n", "<leader>qq", "<cmd>qall<CR>", { desc = "Quit all" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save" })
-- paste without losing register
map("v", "p", '"_dP', { desc = "Paste without yank" })

-- toggle soft wrap for the current buffer (markdown defaults to off so wide
-- tables scroll instead of folding onto the next screen line)
map("n", "<leader>uw", function()
  vim.opt_local.wrap = not vim.wo.wrap
  vim.notify("wrap " .. (vim.wo.wrap and "on" or "off"))
end, { desc = "Toggle wrap" })

-- ── Base64 ────────────────────────────────────────────────────────────────────
map("v", "<leader>cB", function()
  vim.cmd('noautocmd normal! "zy')
  local text = vim.fn.getreg("z")
  vim.fn.setreg("z", vim.base64.encode(text))
  vim.cmd('noautocmd normal! gv"zp')
end, { desc = "Base64 encode" })

map("v", "<leader>cb", function()
  vim.cmd('noautocmd normal! "zy')
  local text = vim.fn.getreg("z")
  local ok, result = pcall(vim.base64.decode, text)
  if not ok then
    vim.notify("base64: invalid input", vim.log.levels.ERROR)
    return
  end
  vim.fn.setreg("z", result)
  vim.cmd('noautocmd normal! gv"zp')
end, { desc = "Base64 decode" })

-- ── Ruff QF ───────────────────────────────────────────────────────────────────
vim.keymap.set("n", "<leader>xR", function()
  local results = vim.fn.systemlist("ruff check " .. vim.fn.getcwd() .. " --output-format=concise 2>/dev/null")
  -- parse into quickfix format
  local qflist = {}
  for _, line in ipairs(results) do
    local file, row, col, msg = line:match("^(.+):(%d+):(%d+): (.+)$")
    if file then
      table.insert(qflist, {
        filename = file,
        lnum = tonumber(row),
        col = tonumber(col),
        text = msg,
      })
    end
  end
  vim.fn.setqflist(qflist)
  if #qflist > 0 then
    require("trouble").open("qflist") -- show in trouble
  else
    vim.notify("ruff: no issues found", vim.log.levels.INFO)
  end
end, { desc = "Ruff check project" })
