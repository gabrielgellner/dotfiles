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
    version = "v0.*",
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
    },
  },

  -- ── LuaSnip ───────────────────────────────────────────────────────────────
  {
    "L3MON4D3/LuaSnip",
    lazy = true,
    version = "v2.*",
    build = "make install_jsregexp",
  },
}
