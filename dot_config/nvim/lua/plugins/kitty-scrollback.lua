-- A kitty window's scrollback, opened in nvim: motions, / search and yank to
-- the clipboard over Claude's output or a build log. kitty starts it (the
-- `ctrl+a>[` map in kitty/mux.conf runs this plugin's kitten), so nothing here
-- has a key; it loads on the event that kitten fires.
return {
  "mikesmithgh/kitty-scrollback.nvim",
  lazy = true,
  cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth", "KittyScrollbackGenerateCommandLineEditing" },
  event = { "User KittyScrollbackLaunch" },
  config = function()
    require("kitty-scrollback").setup()
  end,
}
