-- The Neovim half of vim-tmux-navigator. The tmux half was already installed
-- (dot_tmux.conf declares the plugin, and it lives under dot_tmux/plugins), but
-- without this one the pair only worked in one direction: tmux forwarded
-- <C-hjkl> to the pane when it saw nvim running, nvim moved between its own
-- windows, and at the outermost window the key did nothing instead of crossing
-- into the neighbouring tmux pane.
--
-- This replaces the four <C-w>h/j/k/l mappings that used to live in
-- config/keymaps.lua. Same keys, same behaviour inside nvim; the difference is
-- only at the edge.
return {
  "christoomey/vim-tmux-navigator",
  -- The plugin's own mappings are declined so the keys are declared here, where
  -- they are visible beside the rest of the window commands.
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
  },
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Window/pane left" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Window/pane down" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Window/pane up" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Window/pane right" },
  },
}
