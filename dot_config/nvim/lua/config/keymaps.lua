local map = vim.keymap.set

-- ── Leader ────────────────────────────────────────────────────────────────────
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- ── Better defaults ───────────────────────────────────────────────────────────
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "n", "nzzzv", { desc = "Next match (centred)" })
map("n", "N", "Nzzzv", { desc = "Prev match (centred)" })

-- Bare j/k step by display line so soft-wrapped markdown moves by what you see,
-- but a *counted* j/k has to move real lines: 'relativenumber' counts real
-- lines, so 12j must go where the gutter says 12. Unconditional gj/gk breaks
-- that in any wrapped buffer (<leader>uw), landing you short by however many
-- screen lines the wrapping added.
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down" })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up" })

-- ── Viewport ──────────────────────────────────────────────────────────────────
-- Half-page jumps recentre, so the cursor stays pinned mid-screen and the text
-- slides past it rather than the cursor drifting to a screen edge.
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centred)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centred)" })

-- Move the *window* while the cursor stays put on its buffer line — it only
-- gets dragged once 'scrolloff' runs out, which is why that's set to 8. This is
-- as close as vim gets to scrolling without moving the cursor (:h scroll).
-- Three lines a press; one is too slow to be worth the keystroke. The natural
-- follow-up is H/M/L, which place the cursor on the top/middle/bottom of
-- whatever you just scrolled into view.
map({ "n", "x" }, "<C-e>", "3<C-e>", { desc = "Scroll view down" })
map({ "n", "x" }, "<C-y>", "3<C-y>", { desc = "Scroll view up" })

-- ── Windows ───────────────────────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<leader>-", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>|", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>wd", "<C-w>c", { desc = "Close window" })
-- `<leader>w` is deliberately left as a bare prefix for this group. It used to
-- also be mapped to `:write`, which made it a complete action *and* a prefix:
-- with 'timeoutlen' at 300ms, `<leader>wd` only closed a window if the `d`
-- landed in time, and otherwise saved the file. which-key showed the group name
-- "window" for it either way, so the popup described a key that wrote a file.
-- `:w<CR>` is one keystroke more and costs no namespace.

-- ── Terminal ──────────────────────────────────────────────────────────────────
-- One key out of terminal mode instead of <C-\><C-n>. <C-\> is 0x1c, so it
-- survives every terminal intact — no <C-_>-style fallback needed the way <C-/>
-- needs one.
--
-- This takes over the whole <C-\> prefix in terminal mode (:h terminal-input),
-- which costs three things: <C-\><C-o> (one normal-mode command, then straight
-- back to terminal mode), the <C-\>{key} literal passthrough, and any plugin
-- key hung off the prefix. Nothing may reuse <C-\> as a prefix in terminal mode
-- afterwards — a second binding would put a 'timeoutlen' wait on every press.
map("t", "<C-\\>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- The passthrough above was the only way to send a literal <C-\> — the terminal
-- quit character, i.e. SIGQUIT — to the job. That's how you get a Go goroutine
-- dump or a Java thread dump, and how you kill something that's swallowing
-- <C-c>, so keep a way to send the raw byte.
map("t", "<C-q>", function()
  vim.api.nvim_chan_send(vim.b.terminal_job_id, "\28")
end, { desc = "Send SIGQUIT to terminal job" })

-- ── Buffers ───────────────────────────────────────────────────────────────────
-- Buffer cycling lives on [b / ]b (mini.bracketed, plugins/mini.lua) rather than
-- <S-h>/<S-l>. Those shadow H and L, which are worth more here: with <C-e>/<C-y>
-- moving the viewport under a parked cursor, H/M/L are how you then place the
-- cursor on what you scrolled into view. mini's version also takes a count and
-- wraps, and adds [B/]B for first/last buffer.
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
-- Nothing is bound here any more; both halves live elsewhere and this note is
-- what stops them being re-added:
--
--   ]q / [q     mini.bracketed (plugins/mini.lua). Takes a count, wraps, and
--               adds [Q/]Q for first/last — none of which the plain
--               :cnext/:cprev mappings that used to live here could do.
--   <leader>xq  plugins/trouble.lua, `Trouble qflist toggle`. It loads after
--               this file, so a :copen mapping here was only ever overwritten.

-- ── Guides ────────────────────────────────────────────────────────────────────
-- Personal reference cards (guides/*.md). See config/guides.lua.
map("n", "<leader>?", function()
  require("config.guides").pick()
end, { desc = "Open a guide" })

-- ── Misc ──────────────────────────────────────────────────────────────────────
map("n", "<leader>qq", "<cmd>qall<CR>", { desc = "Quit all" })
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

-- ── Just ──────────────────────────────────────────────────────────────────────
-- Recipes run in the tmux console window (see config/just.lua), not in nvim.
-- Focus stays here; <leader>jw is the "watch it" variant that follows the run.
local just = function(fn, ...)
  local args = { ... }
  return function()
    require("config.just")[fn](unpack(args))
  end
end

map("n", "<leader>jj", just("pick"), { desc = "Run recipe (pick)" })
map("n", "<leader>jw", just("pick", { focus = true }), { desc = "Run recipe (pick, watch)" })
map("n", "<leader>jd", just("run_default"), { desc = "Run default recipe" })
map("n", "<leader>jr", just("rerun"), { desc = "Re-run last recipe" })
map("n", "<leader>jt", just("run_named", "test"), { desc = "Run `test`" })
map("n", "<leader>jb", just("run_named", "build"), { desc = "Run `build`" })
map("n", "<leader>jc", just("run_named", "check"), { desc = "Run `check`" })
