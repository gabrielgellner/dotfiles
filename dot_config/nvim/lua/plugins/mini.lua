return {
  "echasnovski/mini.nvim",
  version = false,
  event = "VeryLazy",
  config = function()
    -- ── mini.ai — extended text objects ────────────────────────────────────
    -- Owns `a` and `i` in operator-pending and visual mode, then reads one more
    -- character as the textobject id. Builtins cover a (argument), t (tag),
    -- q (quote), b (bracket) and the pairs.
    --
    -- `f` and `c` are overridden with treesitter specs, because the builtins do
    -- not mean what this config has always said they mean. mini.ai's stock `f`
    -- is a function *call*, so `vaf` on `def _slugify(name: str) -> str:`
    -- selected the call-shaped part of that one line rather than the function.
    -- And there is no stock `c` at all — `vac` on `class Edge:` selected the
    -- single line under the cursor, silently.
    --
    -- plugins/treesitter.lua declared exactly these two, plus parameter, under
    -- `select.keymaps`. That block never bound anything: on the textobjects
    -- `main` branch it is the old master-branch schema, the same way `matchup`
    -- was in nvim-treesitter's own opts (a9ce4de). The keys looked alive only
    -- because mini.ai owns the `a`/`i` prefix and answered with its builtins.
    --
    -- `a` (argument) is left as mini.ai's builtin. It already works, and it
    -- works by pattern rather than by query — so it keeps working in filetypes
    -- that have no treesitter parser, which a @parameter spec would not.
    local ai = require("mini.ai")

    --- A treesitter textobject that stays quiet where there is no parser.
    ---
    --- gen_spec.treesitter() on its own raises: pressing `vaf` in a conf buffer
    --- produced `E5108: (mini.ai) Can not get parser for buffer 1 and language
    --- "conf"` with a traceback. Parserless filetypes are ordinary — conf,
    --- text, gitcommit — and an error there is worse than the builtin `f` this
    --- replaces, which merely found nothing.
    ---@param captures table
    local function ts_spec(captures)
      local spec = ai.gen_spec.treesitter(captures)
      return function(ai_type, id, opts)
        if not vim.treesitter.get_parser(0, nil, { error = false }) then
          return nil
        end
        local ok, res = pcall(spec, ai_type, id, opts)
        return ok and res or nil
      end
    end

    ai.setup({
      n_lines = 500,
      custom_textobjects = {
        f = ts_spec({ a = "@function.outer", i = "@function.inner" }),
        c = ts_spec({ a = "@class.outer", i = "@class.inner" }),
      },
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
    --   h          git hunks                     plugins/gitsigns.lua (not a
    --              mini suffix, listed so the map of the space is complete)
    --
    -- `location` and `quickfix` are both enabled, so the two lists behave the
    -- same way: [l/]l and [q/]q take a count and wrap, and [L/]L and [Q/]Q jump
    -- to first/last — none of which plain :lnext/:cnext gave. Leaving one to
    -- mini and hand-rolling the other is what made them diverge before.
    --
    -- The treesitter @loop move used to sit on `l` and shadowed :lprevious /
    -- :lnext buffer-locally; it moved to [r/]r so the location list could have
    -- the letter that means it — the same trade already made for [i/]i and
    -- indent scope.
    --
    -- What's left is the half that has no equivalent yet: b buffer, j jumplist,
    -- l location list, o oldfile, q quickfix, u undo states, w window,
    -- x conflict marker, y yank ring.
    require("mini.bracketed").setup({
      comment = { suffix = "" },
      diagnostic = { suffix = "" },
      file = { suffix = "" },
      indent = { suffix = "" },
      treesitter = { suffix = "" },
    })

    -- ── mini.statusline ────────────────────────────────────────────────────
    require("mini.statusline").setup({
      use_icons = true,
    })

    -- Appended rather than configured through content.active, because it has
    -- to survive mini's own default for every other buffer: the function
    -- returns "" unless the current window is a codediff diff pane, so this
    -- costs one table lookup per redraw everywhere else.
    --
    -- mini sets vim.o.statusline in the setup above, so this has to run after
    -- it. CodeDiffHunkStatus is defined at the top level of
    -- plugins/codediff.lua, which lazy evaluates while collecting specs at
    -- startup, so the global is there whether or not codediff itself loads.
    vim.o.statusline = vim.o.statusline .. "%{v:lua.CodeDiffHunkStatus()}"

    -- ── mini.bufremove — smarter buffer deletion ───────────────────────────
    -- keeps window layout intact when closing a buffer
    require("mini.bufremove").setup()
    vim.keymap.set("n", "<leader>bd", function()
      require("mini.bufremove").delete(0, false)
    end, { desc = "Delete buffer" })
  end,
}
