-- haskell-tools.nvim - LSP + Haskell-specific features (HLS, GHCi REPL, hoogle)
-- Same author as rustaceanvim. Do NOT configure `hls` in lsp.lua: this plugin
-- owns the language server client and manual setup causes conflicts.
-- Keymaps live in after/ftplugin/haskell.lua (buffer-local).
return {
  "mrcjkb/haskell-tools.nvim",
  version = "^10", -- requires neovim >= 0.12
  lazy = false, -- filetype plugin: must register the ftplugin before any haskell buffer opens
}
