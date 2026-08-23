-- 'foldexpr' for every buffer: the language server's folds where a server can
-- provide them, treesitter's everywhere else.
--
-- Set globally from config/options.lua rather than per-window on LspAttach,
-- which is what `:h vim.lsp.foldexpr` suggests. 'foldexpr' is window-local, and
-- the per-window form leaves exactly the holes the treesitter setup had before
-- it was made global: the first buffer of a session never got it, and every new
-- split fell back to the global default. Dispatching inside one global
-- expression keeps folds identical in every window showing a buffer.
--
-- LSP folds are worth having where they exist because the server folds by what
-- the code means — imports as a block, a docstring, a region marker — rather
-- than by syntax tree shape.

local M = {}

-- Cached per buffer. 'foldexpr' is evaluated once per line on every fold
-- recalculation, so this cannot do real work: vim.lsp.get_clients() at that
-- rate would be felt on any sizeable file.
local supports = {}

---@param buf integer
---@return boolean
local function detect(buf)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    if client:supports_method("textDocument/foldingRange") then
      return true
    end
  end
  return false
end

--- The global 'foldexpr'.
---@return string|integer
function M.expr()
  local buf = vim.api.nvim_get_current_buf()
  local use_lsp = supports[buf]
  if use_lsp == nil then
    use_lsp = detect(buf)
    supports[buf] = use_lsp
  end
  -- vim.lsp.foldexpr enables the folding_range capability on first call and
  -- returns "0" until the server answers, so early calls simply report no fold
  -- rather than erroring.
  if use_lsp then
    return vim.lsp.foldexpr(vim.v.lnum)
  end
  return vim.treesitter.foldexpr(vim.v.lnum)
end

local group = vim.api.nvim_create_augroup("nvim_folds", { clear = true })

-- A server attaching or detaching changes the answer, so drop the cached one
-- and recompute. zx is safe here precisely because 'foldlevel' is 99: it
-- re-applies that level, which means everything ends up open, which is where it
-- already was.
vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
  group = group,
  callback = function(ev)
    supports[ev.buf] = nil
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) then
        return
      end
      for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
        vim.api.nvim_win_call(win, function()
          vim.cmd("silent! normal! zx")
        end)
      end
    end)
  end,
})

-- Neovim ships ftplugins that set 'foldexpr' window-locally, and a window-local
-- value beats the global one — so the global alone is not actually authoritative.
-- ftplugin/lua.lua does it unconditionally, which silently pinned every Lua
-- buffer to plain treesitter folds; Lua is also the one filetype here whose
-- server advertises foldingRange, so the override defeated exactly the case this
-- module exists for. (ftplugin/markdown.vim does it too, but only when
-- g:markdown_folding is set, which it isn't.)
--
-- FileType runs after the ftplugin has loaded, so re-assert there. Matching on
-- the exact string those ftplugins write keeps this narrow: a plugin that sets
-- its own 'foldexpr' for its own buffers — codediff's compact mode, say — is
-- left alone. Splits need no handling; they don't fire FileType and inherit the
-- global, which is already ours.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function()
    if vim.wo[0][0].foldexpr == "v:lua.vim.treesitter.foldexpr()" then
      vim.wo[0][0].foldexpr = "v:lua.require'config.folds'.expr()"
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
  group = group,
  callback = function(ev)
    supports[ev.buf] = nil
  end,
})

return M
