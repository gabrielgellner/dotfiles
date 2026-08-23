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

    -- ── mini.bracketed — consistent [ / ] motions ──────────────────────────
    -- Most of the alphabet mini.bracketed wants is already spoken for here, and
    -- the existing maps are buffer-local (LspAttach / FileType / on_attach), so
    -- they'd silently shadow mini's globals in exactly the buffers you'd use
    -- them in. Disable those suffixes rather than leave half-dead bindings:
    --
    --   c f i l    treesitter textobject moves   plugins/treesitter.lua
    --   t          todo comments                 plugins/todo.lua
    --   d          diagnostics                   plugins/lsp.lua, trouble.lua
    --   q          quickfix                      config/keymaps.lua
    --   h          git hunks                     plugins/gitsigns.lua (not a
    --              mini suffix, listed so the map of the space is complete)
    --
    -- What's left is the half that has no equivalent yet: b buffer, j jumplist,
    -- o oldfile, u undo states, w window, x conflict marker, y yank ring.
    require("mini.bracketed").setup({
      comment = { suffix = "" },
      diagnostic = { suffix = "" },
      file = { suffix = "" },
      indent = { suffix = "" },
      location = { suffix = "" },
      quickfix = { suffix = "" },
      treesitter = { suffix = "" },
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
