return {
  "stevearc/oil.nvim",
  lazy = false, -- load immediately so you can open dirs from the shell
  opts = {
    -- use oil as the default file explorer (replaces netrw)
    default_file_explorer = true,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    view_options = {
      show_hidden = true, -- show dotfiles
    },
    float = {
      padding = 2,
      max_width = 90,
      max_height = 40,
      border = "rounded",
    },
    -- <leader>fe means "explorer here" everywhere; inside an oil buffer "here"
    -- is the directory oil is showing, not the cwd. Buffer-local, so it shadows
    -- the global mapping only where that reading applies. See config/files.lua.
    keymaps = {
      ["<leader>fe"] = {
        callback = function()
          require("config.files").explorer_from_oil()
        end,
        desc = "Explorer here",
        mode = "n",
      },
    },
  },
  keys = {
    { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
    { "<leader>-", "<cmd>Oil --float<CR>", desc = "Open parent directory (float)" },
  },
}
