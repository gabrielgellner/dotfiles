return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  lazy = false,
  opts = {
    flavour = "frappe",
    -- Only what differs needs to be here. `auto_integrations` defaults to true
    -- (catppuccin/init.lua:58) and at setup unions the integrations table with
    -- one built from every plugin lazy reports installed, so snacks,
    -- treesitter_context, blink_cmp, gitsigns, flash, which_key, lsp_trouble,
    -- grug_far, render_markdown and dap all arrive enabled without being named.
    -- `snacks = true` and `treesitter_context = true` sat here restating two.
    --
    -- `treesitter = true` was not even that: catppuccin has no treesitter
    -- integration. Its groups/treesitter.lua is a *syntax* module, loaded
    -- unconditionally alongside syntax and semantic_tokens (lib/mapper.lua:29),
    -- and the key resolves to nil. Only nvim-treesitter-*context* maps to an
    -- integration (utils/integration_mappings.lua:46).
    --
    -- `nvim_cmp = true` was wrong twice over: catppuccin spells that one `cmp`,
    -- so the key was never read, and nvim-cmp is not installed — blink.cmp is
    -- the engine. Same leftover assumption that had plugins/lsp.lua asking
    -- cmp_nvim_lsp for capabilities.
    --
    -- Dropping all four changes nothing: nvim_get_hl(0, {}) is identical
    -- before and after, all 1089 groups.
    integrations = {
      mini = { enabled = true, indentscope_color = "lavender" },
      native_lsp = {
        enabled = true,
        virtual_text = {
          errors = { "italic" },
          hints = { "italic" },
          warnings = { "italic" },
          information = { "italic" },
        },
        underlines = {
          errors = { "underline" },
          hints = { "underline" },
          warnings = { "underline" },
          information = { "underline" },
        },
      },
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
