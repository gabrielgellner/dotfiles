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
    -- Also owns four keys: `ii`/`ai` select the indent scope, and `[i`/`]i` jump
    -- to its top/bottom — the useful pair when reading nested code.
    --
    -- `[i`/`]i` used to be dead: the treesitter @conditional move claimed them
    -- buffer-locally (plugins/treesitter.lua), so indentscope's globals lost in
    -- every buffer with a filetype. Conditional moved to `[?`/`]?`, since `i`
    -- reads as "indent" here — `ii`/`ai` already mean exactly that — while `i`
    -- for "if" was the arbitrary claim. mini.bracketed's own `indent` suffix
    -- stays disabled for the same reason; this is the `i` motion.
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
    --   c f r      treesitter textobject moves   plugins/treesitter.lua
    --   i          indent scope top/bottom       mini.indentscope, above
    --   t          todo comments                 plugins/todo.lua
    --   d          diagnostics                   plugins/lsp.lua, trouble.lua
    --   q          quickfix                      config/keymaps.lua
    --   h          git hunks                     plugins/gitsigns.lua (not a
    --              mini suffix, listed so the map of the space is complete)
    --
    -- `location` is enabled: [l/]l are Neovim's own :lprevious/:lnext, and mini
    -- adds counts and wrapping plus [L/]L for first/last. The treesitter @loop
    -- move used to sit on `l` and shadowed them buffer-locally; it has moved to
    -- [r/]r so the location list can have the letter that means it — the same
    -- trade already made for [i/]i and indent scope.
    --
    -- What's left is the half that has no equivalent yet: b buffer, j jumplist,
    -- l location list, o oldfile, u undo states, w window, x conflict marker,
    -- y yank ring.
    require("mini.bracketed").setup({
      comment = { suffix = "" },
      diagnostic = { suffix = "" },
      file = { suffix = "" },
      indent = { suffix = "" },
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
