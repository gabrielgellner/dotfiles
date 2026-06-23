-- Buffer-local Haskell keymaps (haskell-tools.nvim).
-- Sourced after the plugin initializes, once per haskell buffer.
-- General LSP maps (K, <leader>ca, <leader>cr, <leader>cf, diagnostics) come
-- from the global LspAttach handler in lua/plugins/lsp.lua and apply here too.
local ht = require("haskell-tools")
local bufnr = vim.api.nvim_get_current_buf()

-- Indentation: 2-space, spaces-not-tabs (Haskell layout is whitespace-sensitive).
-- This only affects manual typing comfort; ormolu via format-on-save is the
-- source of truth for final layout.
vim.bo[bufnr].expandtab = true
vim.bo[bufnr].shiftwidth = 2
vim.bo[bufnr].tabstop = 2
vim.bo[bufnr].softtabstop = 2

local map = function(keys, func, desc)
  vim.keymap.set("n", keys, func, { buffer = bufnr, silent = true, desc = "Haskell: " .. desc })
end

-- HLS code lens (e.g. "add type signature", evaluate doctest)
map("<leader>cl", vim.lsp.codelens.run, "Run code lens")

-- Hoogle search the type signature under the cursor
map("<leader>hs", ht.hoogle.hoogle_signature, "Hoogle signature search")

-- Evaluate all code snippets (eval comments) in the buffer
map("<leader>he", ht.lsp.buf_eval_all, "Eval all snippets")

-- GHCi REPL (auto-detects cabal repl / stack ghci / ghci)
map("<leader>rr", ht.repl.toggle, "Toggle REPL (project)")
map("<leader>rf", function()
  ht.repl.toggle(vim.api.nvim_buf_get_name(0))
end, "Toggle REPL (current file)")
map("<leader>rq", ht.repl.quit, "Quit REPL")
