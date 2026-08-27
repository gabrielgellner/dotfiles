return {
  -- ── In-buffer markdown rendering ──────────────────────────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown" },
    opts = {
      heading = { enabled = true },
      code = { enabled = true, sign = false },
      dash = { enabled = true },
      bullet = { enabled = true },
      checkbox = { enabled = true },
      link = {
        enabled = true,
        -- Typed rules references: [Display](type:slug) render as an icon + the
        -- display name, with the (type:slug) concealed. zk ignores them (the
        -- `type:` scheme makes them external links, not note links). Icons are
        -- Nerd Font glyphs written as \u{...} so they survive editing; swap the
        -- codepoint for any that render as tofu.
        custom = {
          spell = { pattern = "^spell:", icon = "\u{f0d0} ", highlight = "Special" }, -- magic wand
          condition = { pattern = "^condition:", icon = "\u{f21e} ", highlight = "DiagnosticWarn" }, -- heartbeat
          feat = { pattern = "^feat:", icon = "\u{f005} ", highlight = "Constant" }, -- star
          action = { pattern = "^action:", icon = "\u{f0e7} ", highlight = "Function" }, -- bolt
          creature = { pattern = "^creature:", icon = "\u{f1b0} ", highlight = "Type" }, -- paw
          room = { pattern = "^room:", icon = "\u{f041} ", highlight = "Identifier" }, -- map marker
          item = { pattern = "^item:", icon = "\u{f02b} ", highlight = "WarningMsg" }, -- tag
        },
      },
    },
    keys = {
      {
        "<leader>mr",
        "<cmd>RenderMarkdown toggle<CR>",
        ft = "markdown",
        desc = "Toggle render",
      },
    },
  },

  -- ── Browser preview (no npm/build deps) ──────────────────────────────────
  {
    "selimacerbas/markdown-preview.nvim",
    dependencies = { "selimacerbas/live-server.nvim" },
    ft = { "markdown" },
    config = function()
      -- Both of these are the plugin's own defaults, restated because they are
      -- the two behaviours the keymaps below assume: one shared browser tab
      -- across buffers, and <leader>mp meaning "show me this in a browser"
      -- rather than "start a server I then have to open myself".
      --
      -- `port` is *not* set. It looked like it was auto-assigning one, but
      -- takeover mode never consults it — init.lua returns a hardcoded 8421
      -- before reading config.port, so `port = 0` said nothing true. (Measured:
      -- the running server listens on 8421, plus a separate websocket port.)
      -- It would start mattering under instance_mode = "multi", which is the
      -- per-instance mode this config deliberately does not use.
      --
      -- debounce_ms is not set either; 300 was the default it was already
      -- getting.
      require("markdown_preview").setup({
        instance_mode = "takeover",
        open_browser = true,
      })
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreview<CR>", ft = "markdown", desc = "Preview start" },
      { "<leader>mP", "<cmd>MarkdownPreviewStop<CR>", ft = "markdown", desc = "Preview stop" },
      -- Refresh sits on mf, not mR. <leader>mr is render-markdown's toggle — a
      -- different plugin doing a different thing — so mr/mR looked like a pair
      -- and wasn't. mf keeps refresh beside the preview commands it belongs to
      -- without borrowing a letter that is already spoken for.
      { "<leader>mf", "<cmd>MarkdownPreviewRefresh<CR>", ft = "markdown", desc = "Preview refresh" },
    },
  },
}
