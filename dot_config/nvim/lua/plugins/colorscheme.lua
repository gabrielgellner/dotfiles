return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  lazy = false,
  opts = {
    flavour = "frappe",
    integrations = {
      mini = { enabled = true, indentscope_color = "lavender" },
      snacks = true,
      -- No `nvim_cmp` key here: catppuccin spells that integration `cmp`, so
      -- the name was never one it reads, and nvim-cmp is not installed anyway —
      -- blink.cmp is the engine and its `blink_cmp` integration is on by
      -- itself. Verified against require("catppuccin").options.integrations at
      -- runtime rather than the README. Same leftover assumption that had
      -- plugins/lsp.lua asking cmp_nvim_lsp for its capabilities.
      treesitter = true,
      treesitter_context = true,
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
