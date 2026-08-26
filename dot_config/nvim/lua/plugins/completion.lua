-- ============================================================================
-- plugins/completion.lua
-- blink.cmp with vim-style keybinds:
--   - popup appears automatically as you type
--   - buffer is NEVER modified until explicit <C-y>
--   - <C-n>/<C-p> to navigate, <C-y> to confirm, <C-e> to dismiss
-- ============================================================================

return {
  {
    "saghen/blink.cmp",
    version = "1.*", -- 1.x ships prebuilt fuzzy-matcher binaries; no cargo needed
    dependencies = { "L3MON4D3/LuaSnip" },
    opts = {
      -- ── Keymaps ───────────────────────────────────────────────────────────
      keymap = {
        preset = "none", -- start from scratch, no defaults
        ["<C-space>"] = { "show", "fallback" }, -- manual trigger
        ["<C-y>"] = { "accept", "fallback" }, -- confirm item
        ["<C-e>"] = { "hide", "fallback" }, -- dismiss popup
        ["<C-n>"] = { "select_next", "show" }, -- next item / open
        ["<C-p>"] = { "select_prev", "show" }, -- prev item
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        ["<Tab>"] = { "snippet_forward", "fallback" }, -- jump snippet node
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },

      -- ── Snippets ──────────────────────────────────────────────────────────
      snippets = {
        expand = function(snippet)
          require("luasnip").lsp_expand(snippet)
        end,
        active = function(filter)
          if filter and filter.direction then
            return require("luasnip").jumpable(filter.direction)
          end
          return require("luasnip").in_snippet()
        end,
        jump = function(direction)
          require("luasnip").jump(direction)
        end,
      },

      -- ── Sources ───────────────────────────────────────────────────────────
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },

      -- ── Completion behaviour ──────────────────────────────────────────────
      completion = {
        trigger = {
          -- show popup automatically as you type
          show_on_keyword = true,
          show_on_trigger_character = true,
        },
        list = {
          selection = {
            preselect = true,
            auto_insert = false, -- typing NEVER modifies buffer from popup
          },
        },
        accept = {
          auto_brackets = { enabled = true }, -- auto close brackets on accept
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = {
            border = "rounded",
          },
        },
        menu = {
          border = "rounded",
          draw = {
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind", gap = 1 },
              { "source_name" },
            },
          },
        },
      },

      -- ── Appearance ────────────────────────────────────────────────────────
      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
      },

      -- ── Signature help ────────────────────────────────────────────────────
      signature = {
        enabled = true,
        window = { border = "rounded" },
      },

      -- ── Command line ──────────────────────────────────────────────────────
      -- blink enables cmdline completion by default, but only auto-shows the
      -- menu in the command-line *window* (`q:`). Show it while typing `:` too,
      -- which is the VSCode-palette-ish behaviour: start typing and the matches
      -- appear.
      --
      -- Not for `/` and `?`. Those are incremental — the point is watching the
      -- match move as you type — and a popup over the buffer hides the thing you
      -- are aiming at. Ghost text still works there, and <C-space> pulls the
      -- menu up on demand.
      cmdline = {
        completion = {
          menu = {
            auto_show = function(ctx)
              return ctx.mode == "cmdwin" or vim.fn.getcmdtype() == ":"
            end,
          },
        },
        keymap = {
          preset = "cmdline",
          -- The `cmdline` preset gives Left/Right to the menu whenever it is
          -- open. That was tolerable when the menu only appeared on demand;
          -- with auto_show it is open most of the time, and arrow keys are how
          -- you move the cursor in a command you are editing. Hand them back —
          -- <Tab>, <C-n>/<C-p> already select.
          ["<Left>"] = { "fallback" },
          ["<Right>"] = { "fallback" },
        },
      },
    },
  },

  -- ── LuaSnip ───────────────────────────────────────────────────────────────
  {
    "L3MON4D3/LuaSnip",
    lazy = true,
    version = "v2.*",
    build = "make install_jsregexp",
    -- friendly-snippets is the collection; LuaSnip is only the engine. Without
    -- it `snippets` sat in blink's source list returning nothing at all — zero
    -- available for lua and for python — because nothing ever loaded any.
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      local ls = require("luasnip")
      -- The snippets ship in VSCode's json format, which is what this loader
      -- reads. Called here rather than at startup: LuaSnip is lazy and pulled
      -- in by blink, so this runs the first time completion is needed.
      require("luasnip.loaders.from_vscode").lazy_load()

      -- <C-k>/<C-j> drive a snippet directly, LuaSnip's own convention.
      -- <Tab>/<S-Tab> above do the jumping too, through blink; the difference
      -- is that expand_or_jump also *expands* a trigger word that was typed
      -- without going through the completion menu — `fori<C-k>` in a lua
      -- buffer, no popup involved.
      --
      -- <C-k> is vim's digraph key in insert mode — <C-k>a: for an a-umlaut.
      -- Rather than lose it, the mapping hands it back when there is no
      -- snippet to expand or jump in, which is almost always. `n` on feedkeys
      -- so the fed key is not remapped straight back into this function.
      vim.keymap.set({ "i", "s" }, "<C-k>", function()
        if ls.expand_or_jumpable() then
          ls.expand_or_jump()
        else
          vim.api.nvim_feedkeys(vim.keycode("<C-k>"), "n", false)
        end
      end, { silent = true, desc = "Expand snippet or jump forward" })

      vim.keymap.set({ "i", "s" }, "<C-j>", function()
        if ls.jumpable(-1) then
          ls.jump(-1)
        end
      end, { silent = true, desc = "Jump to the previous placeholder" })
    end,
  },
}
