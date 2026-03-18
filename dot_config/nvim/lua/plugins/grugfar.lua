return {
  "MagicDuck/grug-far.nvim",
  opts = {
    headerMaxWidth = 80,
  },
  keys = {
    -- open with current word pre-filled
    {
      "<leader>sr",
      function()
        require("grug-far").open({
          transient = true,
        })
      end,
      desc = "Search and replace",
    },
    -- search word under cursor
    {
      "<leader>sw",
      function()
        require("grug-far").open({
          transient = true,
          prefills = { search = vim.fn.expand("<cword>") },
        })
      end,
      desc = "Search word under cursor",
    },
    -- search and replace in current file only
    {
      "<leader>sW",
      function()
        require("grug-far").open({
          transient = true,
          prefills = {
            search = vim.fn.expand("<cword>"),
            paths = vim.fn.expand("%"),
          },
        })
      end,
      desc = "Search word in current file",
    },
    -- search visual selection
    {
      "<leader>sr",
      function()
        require("grug-far").with_visual_selection({
          transient = true,
        })
      end,
      mode = "v",
      desc = "Search and replace selection",
    },
  },
}
