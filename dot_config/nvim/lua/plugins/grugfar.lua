return {
  "MagicDuck/grug-far.nvim",
  cmd = { "GrugFar", "GrugFarWithin" },
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
      -- Lowercase is this file, capital is the whole project. The pair used to
      -- run the other way, which fought the convention a capital carries
      -- everywhere else here — and fought vim's own w/W, where the capital is
      -- the bigger thing.
      "<leader>sw",
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
    {
      "<leader>sW",
      function()
        require("grug-far").open({
          transient = true,
          prefills = { search = vim.fn.expand("<cword>") },
        })
      end,
      desc = "Search word under cursor (project)",
    },
    -- search visual selection
    {
      "<leader>sr",
      function()
        require("grug-far").with_visual_selection({
          transient = true,
        })
      end,
      mode = "x",
      desc = "Search and replace selection",
    },
  },
}
