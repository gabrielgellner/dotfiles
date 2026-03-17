return {
  "stevearc/oil.nvim",
  lazy = false, -- load immediately so you can open dirs from the shell
  opts = {
    -- use oil as the default file explorer (replaces netrw)
    default_file_explorer         = true,
    delete_to_trash               = true,
    skip_confirm_for_simple_edits = true,
    view_options                  = {
      show_hidden = true, -- show dotfiles
    },
    float                         = {
      padding    = 2,
      max_width  = 90,
      max_height = 40,
      border     = "rounded",
    },
  },
  keys = {
    { "-",         "<cmd>Oil<CR>",         desc = "Open parent directory" },
    { "<leader>-", "<cmd>Oil --float<CR>", desc = "Open parent directory (float)" },
  },
}
