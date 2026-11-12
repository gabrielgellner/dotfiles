-- The keys of the tmux scrollback view: the buffer bin/tmux-scrollback opens
-- on `prefix + [`, holding one pane's history. guides/scrollback.md is the
-- user's side of it.
--
-- It is an ordinary read-only buffer in a throwaway nvim, so every motion,
-- search and text object already works and a plain `y` already reaches the
-- clipboard (`clipboard=unnamedplus`). What is added here is only the ways
-- out, named after kitty-scrollback.nvim's so the two machines agree:
--
--   q                   quit
--   <leader>y           (visual) copy and quit
--   <leader>y{motion}   copy what the motion covers, and quit; <leader>yy a line
--   <CR>                (visual) paste the selection into the pane, and quit
--
-- <CR> rather than kitty-scrollback's <S-CR>: without extended-keys tmux hands
-- nvim the same byte for both, so there is no Shift-Enter to bind.

local M = {}

local pane

---Quit this nvim, which closes the popup it is running in.
local function quit()
  vim.cmd("qall!")
end

---The text between two marks, as the lines a yank of it would hold.
---@param mode string "char" | "line" | "block" | a visual mode
---@return string[]
local function region(mode, from, to)
  local type = ({ line = "V", V = "V", block = "\22", ["\22"] = "\22" })[mode] or "v"
  return vim.fn.getregion(vim.fn.getpos(from), vim.fn.getpos(to), { type = type })
end

---Copy to the clipboard and leave.
---@param lines string[]
---@param linewise boolean
local function copy_and_quit(lines, linewise)
  vim.fn.setreg("+", lines, linewise and "V" or "v")
  -- The clipboard tool is a child of this nvim: give the provider its turn
  -- before the process that started it goes away.
  vim.schedule(quit)
end

function M.copy_operator(mode)
  copy_and_quit(region(mode, "'[", "']"), mode == "line")
end

---Paste text into the pane this was opened over, bracketed so a shell or
---Claude takes it as a paste, and without a final newline so nothing runs.
---@param lines string[]
local function paste_and_quit(lines)
  local text = table.concat(lines, "\n")
  vim.system({ "tmux", "load-buffer", "-b", "scrollback", "-" }, { stdin = text }):wait()
  vim.system({ "tmux", "paste-buffer", "-d", "-p", "-b", "scrollback", "-t", pane }):wait()
  quit()
end

---@param target string the tmux pane the buffer was captured from
function M.attach(target)
  pane = target
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.wo.wrap = true
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  -- The end is where the thing you want usually is.
  vim.cmd("normal! G")

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, nowait = true, desc = desc })
  end

  map("n", "q", quit, "Quit the scrollback")
  map("x", "<leader>y", function()
    local mode = vim.fn.mode()
    copy_and_quit(region(mode, "v", "."), mode == "V")
  end, "Copy and quit")
  vim.keymap.set("n", "<leader>y", function()
    vim.o.operatorfunc = "v:lua.require'config.scrollback'.copy_operator"
    return "g@"
  end, { buffer = buf, expr = true, desc = "Copy {motion} and quit" })
  vim.keymap.set("n", "<leader>yy", function()
    vim.o.operatorfunc = "v:lua.require'config.scrollback'.copy_operator"
    return "g@_"
  end, { buffer = buf, expr = true, desc = "Copy the line and quit" })
  map("x", "<CR>", function()
    paste_and_quit(region(vim.fn.mode(), "v", "."))
  end, "Paste the selection into the pane and quit")
end

return M
