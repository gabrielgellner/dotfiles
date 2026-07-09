return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 300,
    spec = {
      -- ── Groups ─────────────────────────────────────────────────────────
      { "<leader>f", group = "find/pick" },
      { "<leader>c", group = "code" },
      { "<leader>d", group = "debug" },
      { "<leader>dt", group = "debug test" },
      { "<leader>g", group = "git" },
      { "<leader>b", group = "buffer" },
      { "<leader>s", group = "search/replace" },
      { "<leader>t", group = "test" },
      { "<leader>m", group = "markdown" },
      { "<leader>u", group = "ui" },
      { "<leader>w", group = "window" },
      { "<leader>x", group = "diagnostics/quickfix" },
      { "<leader>z", group = "zettelkasten" },

      -- ── Navigation groups ───────────────────────────────────────────────
      { "[", group = "prev" },
      { "]", group = "next" },
      { "g", group = "goto" },
      { "gs", group = "surround" },

      -- ── Treesitter motions ──────────────────────────────────────────────
      { "]f", desc = "Next function" },
      { "[f", desc = "Prev function" },
      { "]F", desc = "End of next function" },
      { "[F", desc = "End of prev function" },
      { "]c", desc = "Next class" },
      { "[c", desc = "Prev class" },
      { "]C", desc = "End of next class" },
      { "[C", desc = "End of prev class" },
      { "]a", desc = "Next argument" },
      { "[a", desc = "Prev argument" },
      { "]i", desc = "Next conditional" },
      { "[i", desc = "Prev conditional" },
      { "]l", desc = "Next loop" },
      { "[l", desc = "Prev loop" },

      -- ── Git diffview ────────────────────────────────────────────────────
      { "<leader>gv", desc = "Diff view (working tree)" },
      { "<leader>gh", desc = "File history" },
      { "<leader>gH", desc = "Repo history" },

      -- ── Git hunk motions ────────────────────────────────────────────────
      { "]h", desc = "Next hunk" },
      { "[h", desc = "Prev hunk" },

      -- ── Todo motions ────────────────────────────────────────────────────
      { "]t", desc = "Next todo" },
      { "[t", desc = "Prev todo" },

      -- ── Diagnostic motions ──────────────────────────────────────────────
      { "]d", desc = "Next diagnostic" },
      { "[d", desc = "Prev diagnostic" },
      { "]e", desc = "Next error" },
      { "[e", desc = "Prev error" },
    },
  },
}
