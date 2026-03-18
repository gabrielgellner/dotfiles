return {
  "echasnovski/mini.nvim",
  version = false,
  event = "VeryLazy",
  config = function()
    -- ── mini.ai — extended text objects ────────────────────────────────────
    -- adds i/a for: f (function), c (class), a (argument), t (tag) etc.
    require("mini.ai").setup({
      n_lines = 500,
    })

    -- ── mini.surround ──────────────────────────────────────────────────────
    -- gs prefix to avoid clashing with snacks/default mappings
    require("mini.surround").setup({
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
      },
    })

    -- ── mini.pairs — autopairs ─────────────────────────────────────────────
    require("mini.pairs").setup({
      modes = { insert = true, command = false, terminal = false },
    })

    -- ── mini.indentscope — animated indent guides ──────────────────────────
    require("mini.indentscope").setup({
      symbol = "│",
      options = { try_as_border = true },
      draw = {
        delay = 50,
        animation = require("mini.indentscope").gen_animation.none(),
      },
    })

    -- ── mini.statusline ────────────────────────────────────────────────────
    require("mini.statusline").setup({
      use_icons = true,
    })

    -- ── mini.bufremove — smarter buffer deletion ───────────────────────────
    -- keeps window layout intact when closing a buffer
    require("mini.bufremove").setup()
    vim.keymap.set("n", "<leader>bd", function()
      require("mini.bufremove").delete(0, false)
    end, { desc = "Delete buffer" })
  end,
}
