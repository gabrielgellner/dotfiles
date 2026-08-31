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
-- gets dragged once it comes within 'scrolloff' lines of the edge, which is
-- part of why that's set low (2, see options.lua). This is as close as vim
-- gets to scrolling without moving the cursor (:h scroll).
-- Three lines a press; one is too slow to be worth the keystroke. The natural
-- follow-up is H/M/L, which place the cursor on the top/middle/bottom of
-- whatever you just scrolled into view.
map({ "n", "x" }, "<C-e>", "3<C-e>", { desc = "Scroll view down" })
map({ "n", "x" }, "<C-y>", "3<C-y>", { desc = "Scroll view up" })

-- ── Structural selection ──────────────────────────────────────────────────────
-- Neovim's incremental selection, on Helix's keys rather than its own.
--
-- Upstream puts grow and shrink on `an`/`in`, which mini.ai already owns — and
-- not by accident. `n` and `l` are mini.ai's next/last modifiers, so `an)` is
-- "around the next parens" and `il"` is "inside the last quotes". That axis runs
-- through every textobject it defines; there is no carving `n` out of it.
--
-- Moving the operation is the better trade anyway. `a`/`i` mean "find a region
-- around the cursor", while these grow and shrink the selection you already
-- have — a different kind of thing that never really belonged in the textobject
-- namespace. Helix calls them expand and shrink and puts them on <M-o>/<M-i>.
--
-- So mini.ai stays the way to *name* a region (vaf, ci", daa), and this is the
-- way to take the next bigger one *without* naming it: a table entry, a match
-- arm, one link of a chained call — anything with no textobject of its own.
--
-- [n/]n and [N/]N are Neovim's and were never shadowed. Note what they do,
-- though: `:help v_]N` is "Expands selection to [count]th next node" — they use
-- vim.treesitter.select's extend_next/extend_prev targets and *grow* the
-- selection over the sibling. <M-n>/<M-p> below pass plain next/prev, which
-- *moves* the selection onto the sibling instead. Different operations, so both
-- are worth having; they only looked redundant because they read the same in
-- which-key, the builtins being described as "Select next sibling node" too.
---@param target "parent"|"child"|"next"|"prev"
---@param lsp? integer direction for the no-parser fallback, if it has one
local function select_node(target, lsp)
  return function()
    if vim.treesitter.get_parser(nil, nil, { error = false }) then
      vim.treesitter.select(target, vim.v.count1)
    elseif lsp then
      -- What upstream falls back to: the server's idea of the enclosing range,
      -- so this still works in a filetype with no parser installed.
      vim.lsp.buf.selection_range(lsp * vim.v.count1)
    end
  end
end

map("x", "<M-o>", select_node("parent", 1), { desc = "Grow selection to parent node" })
map("x", "<M-i>", select_node("child", -1), { desc = "Shrink selection to child node" })
map("x", "<M-n>", select_node("next"), { desc = "Move selection to next sibling" })
map("x", "<M-p>", select_node("prev"), { desc = "Move selection to prev sibling" })

-- ── Windows ───────────────────────────────────────────────────────────────────
-- <C-hjkl> move between splits. These lived in plugins/tmux-navigator.lua for a
-- while, which carried the same movement on into a neighbouring tmux pane once
-- nvim ran out of windows. That handoff needs a tmux pane to hand off to, and
-- there has never been one — every window in every session holds a single pane,
-- because panes are not how this setup divides work; windows are, reached with
-- prefix + 1/2/3. So the plugin is gone and the keys are plain wincmd again.
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Splits sit under <leader>w with the rest of the window commands. <leader>-
-- used to be the horizontal one and did nothing: plugins/oil.lua binds the same
-- key to `Oil --float` and, being a lazy key registered later, won.
map("n", "<leader>w-", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>w|", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>wd", "<C-w>c", { desc = "Close window" })
-- `<leader>w` is deliberately left as a bare prefix for this group. It used to
-- also be mapped to `:write`, which made it a complete action *and* a prefix:
-- with 'timeoutlen' at 300ms, `<leader>wd` only closed a window if the `d`
-- landed in time, and otherwise saved the file. which-key showed the group name
-- "window" for it either way, so the popup described a key that wrote a file.
-- `:w<CR>` is one keystroke more and costs no namespace.

-- ── Terminal ──────────────────────────────────────────────────────────────────
-- One key out of terminal mode instead of <C-\><C-n>. This is the most-pressed
-- key in the Claude float — normal mode is how you scroll and yank its output —
-- so it has to be a single chord.
--
-- <C-x> rather than <C-\>, which is what this used to be. The hazard was not
-- inside nvim but outside it: a key pressed this often gets into the fingers,
-- and <C-\> in a plain shell is the terminal quit character, so a misfire in
-- the wrong pane sends SIGQUIT to whatever is running. <C-x> is the one
-- candidate that does *nothing* in this shell — zsh reports it as
-- `undefined-key` — and it is unbound in tmux's root and copy-mode tables too.
-- <C-g> was the runner-up (zsh binds it to list-expand, harmless), but a TUI is
-- likelier to want <C-g> for cancel than <C-x>.
--
-- 0x18 is a real control character, so it survives every terminal intact — no
-- <C-_>-style fallback needed the way <C-/> needs one.
--
-- The cost is that the job never receives <C-x>. In exchange, <C-\> is left
-- alone: the built-in <C-\><C-n> and <C-\><C-o> still work as a fallback, and
-- the <C-\>{key} literal passthrough is intact (:h terminal-input).
map("t", "<C-x>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- An explicit way to send the terminal quit character to the job — a Go
-- goroutine dump, a Java thread dump, or killing something that is swallowing
-- <C-c>. <C-\> can reach the job on its own again now, but this stays: it is
-- unambiguous, and it does not depend on remembering how nvim's <C-\> prefix
-- resolves.
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
map("x", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("x", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- ── Indenting in visual mode (keep selection) ─────────────────────────────────
-- "x", not "v", here and everywhere else in this config. "v" is visual *and*
-- select mode, and in select mode a printable key is meant to replace the
-- selection — so `mode = "v"` on `<` made typing `<` dedent instead of typing a
-- `<`, and the <leader> maps turned a space into the start of a command
-- sequence. Select mode is where LuaSnip leaves you inside a placeholder, which
-- is exactly where you are typing over the selection.
map("x", "<", "<gv", { desc = "Indent left" })
map("x", ">", ">gv", { desc = "Indent right" })

-- ── Quickfix ──────────────────────────────────────────────────────────────────
-- Nothing is bound here any more; both halves live elsewhere and this note is
-- what stops them being re-added:
--
--   ]q / [q     mini.bracketed (plugins/mini.lua). Takes a count, wraps, and
--               adds [Q/]Q for first/last — none of which the plain
--               :cnext/:cprev mappings that used to live here could do.
--   <leader>xq  plugins/trouble.lua, `Trouble qflist toggle`. It loads after
--               this file, so a :copen mapping here was only ever overwritten.

-- ── Argument list ─────────────────────────────────────────────────────────────
-- Neovim binds [a/]a to :previous/:next and [A/]A to :rewind/:last. The
-- treesitter @parameter move (plugins/treesitter.lua) claims [a/]a
-- buffer-locally, which shadows the globals only in buffers that have a
-- filetype — so the arglist ended up reachable in some buffers and not others,
-- with [A/]A working everywhere regardless. All four go, so `a` means
-- "argument" in the parameter sense consistently and nothing behaves
-- differently depending on which buffer you happen to be in.
--
-- The argument list itself is untouched and still driven by command — :args,
-- :argdo, :next, :previous. It just has no bracket keys here, and nothing in
-- this config uses it; :argdo's job belongs to grug-far (<leader>sr).
--
-- pcall because these only exist on Neovim versions that ship them, and
-- vim.keymap.del throws on a missing mapping.
for _, lhs in ipairs({ "[a", "]a", "[A", "]A" }) do
  pcall(vim.keymap.del, "n", lhs)
end

-- ── Guides ────────────────────────────────────────────────────────────────────
-- Personal reference cards (guides/*.md). See config/guides.lua.
map("n", "<leader>?", function()
  require("config.guides").pick()
end, { desc = "Open a guide" })

-- ── Misc ──────────────────────────────────────────────────────────────────────
map("n", "<leader>qq", "<cmd>qall<CR>", { desc = "Quit all" })
-- No `p` remap in visual mode. `"_dP` is the usual one, but vim's own `P`
-- already pastes over a selection without taking the replaced text into the
-- register — verified identical — so remapping `p` only spent native `p`, which
-- *does* take it, and is how you swap two pieces of text.

-- toggle soft wrap for the current buffer (markdown defaults to off so wide
-- tables scroll instead of folding onto the next screen line)
map("n", "<leader>uw", function()
  vim.opt_local.wrap = not vim.wo.wrap
  vim.notify("wrap " .. (vim.wo.wrap and "on" or "off"))
end, { desc = "Toggle wrap" })

-- ── Base64 ────────────────────────────────────────────────────────────────────
-- Under a <leader>cb group rather than cb/cB. Everywhere else here a capital
-- means a wider scope — stage hunk/buffer, file/repo history, document/workspace
-- symbols — so using case for direction instead left no way to guess which of
-- cb and cB encoded. e and d say it outright.
map("x", "<leader>cbe", function()
  vim.cmd('noautocmd normal! "zy')
  local text = vim.fn.getreg("z")
  vim.fn.setreg("z", vim.base64.encode(text))
  vim.cmd('noautocmd normal! gv"zp')
end, { desc = "Base64 encode" })

map("x", "<leader>cbd", function()
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
