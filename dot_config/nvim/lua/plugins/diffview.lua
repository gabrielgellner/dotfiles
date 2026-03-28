return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Git: Diff view (working tree)" },
    { "<leader>gm", "<cmd>DiffviewOpen main...HEAD<cr>", desc = "Git: Branch diff vs main" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Git: File history" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Git: Repo history" },
  },
  config = function()
    local actions = require("diffview.actions")
    require("diffview").setup({
      view = {
        default = { layout = "diff2_vertical" },
        merge_tool = { layout = "diff3_vertical" },
      },
      hooks = {
        diff_buf_read = function(_bufnr)
          vim.opt_local.wrap = false
          vim.opt_local.list = false
          vim.opt_local.colorcolumn = ""
        end,
      },
      keymaps = {
        view = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "<leader>e", actions.toggle_files, { desc = "Toggle file panel" } },
        },
        file_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "<leader>e", actions.toggle_files, { desc = "Toggle file panel" } },
        },
        file_history_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "<leader>e", actions.toggle_files, { desc = "Toggle file panel" } },
        },
      },
    })
  end,
}
