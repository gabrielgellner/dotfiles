return {
  "MagicDuck/grug-far.nvim",
  cmd = { "GrugFar", "GrugFarWithin" },
  -- No opts. The only one here was headerMaxWidth = 80, which grug-far has no
  -- such option for — the string appears nowhere in the plugin, and it does not
  -- validate unknown keys, so it sat in the merged table being read by nothing.
  --
  -- Nothing replaced it because setup() only calls setGlobalOptionsOverride,
  -- and getGlobalOptions falls back to `vim.g.grug_far or {}` when it was never
  -- called. An `opts = {}` would be the same as no opts at all, so this spec
  -- simply does not have one.
  keys = {
    -- A blank search/replace: no prefill, whole project. The three below narrow
    -- it. `transient` on all four means the buffer unlists and deletes itself
    -- when it goes out of use, rather than accumulating one per search.
    {
      "<leader>sr",
      function()
        require("grug-far").open({
          transient = true,
        })
      end,
      desc = "Search and replace",
    },
    -- The word under the cursor, this file only.
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
    -- The visual selection, whole project. `mode = "x"` and not "v", which
    -- would take select mode with it — see guides/keymaps.md.
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
