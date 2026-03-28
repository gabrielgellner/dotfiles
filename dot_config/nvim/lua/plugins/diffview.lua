return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Git: Diff view (working tree)" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Git: File history" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Git: Repo history" },
  },
  opts = {
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
      },
      file_panel = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
      },
      file_history_panel = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
      },
    },
  },
}
