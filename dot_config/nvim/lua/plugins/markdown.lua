return {
  -- ── In-buffer markdown rendering ──────────────────────────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    -- quarto too: a .qmd is markdown to render-markdown (it reads the
    -- markdown parser the filetype is registered to), but it only attaches to
    -- the filetypes in `file_types`, which defaults to markdown alone.
    ft = { "markdown", "quarto" },
    opts = {
      file_types = { "markdown", "quarto" },
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
        ft = { "markdown", "quarto" },
        desc = "Toggle render",
      },
    },
  },

  -- ── Browser preview (no npm/build deps) ──────────────────────────────────
  {
    -- Both repos were renamed in their 2.0.0 (markdown-preview.nvim ->
    -- mdkite.nvim, live-server.nvim -> kitehost.nvim). The former names keep
    -- working through 2.x behind a once-a-session deprecation warning and go
    -- in 3.0.0, so the spec, module and commands here use the new ones.
    -- kitehost would install without the dependencies line (mdkite's own
    -- lazy.lua names it); it stays so the server is visible in this file.
    "selimacerbas/mdkite.nvim",
    dependencies = { "selimacerbas/kitehost.nvim" },
    ft = { "markdown" },
    config = function()
      -- Both of these are the plugin's own defaults, restated because they are
      -- the two behaviours the keymaps below assume: one shared browser tab
      -- across buffers, and <leader>mp meaning "show me this in a browser"
      -- rather than "start a server I then have to open myself".
      --
      -- `port` is *not* set. Its default, 0, means 8421 under takeover and an
      -- OS-assigned port under multi. Before 2.0.0 takeover returned 8421
      -- without consulting config.port at all, which is why `port = 0` was
      -- once dropped from here as saying nothing; mdkite now honours a
      -- non-zero port in either mode, so set one only to move off 8421.
      --
      -- debounce_ms is not set either; 300 was the default it was already
      -- getting.
      require("mdkite").setup({
        instance_mode = "takeover",
        open_browser = true,
      })
    end,
    keys = {
      { "<leader>mp", "<cmd>MdKite start<CR>", ft = "markdown", desc = "Preview start" },
      { "<leader>mP", "<cmd>MdKite stop<CR>", ft = "markdown", desc = "Preview stop" },
      -- Refresh sits on mf, not mR. <leader>mr is render-markdown's toggle — a
      -- different plugin doing a different thing — so mr/mR looked like a pair
      -- and wasn't. mf keeps refresh beside the preview commands it belongs to
      -- without borrowing a letter that is already spoken for.
      { "<leader>mf", "<cmd>MdKite refresh<CR>", ft = "markdown", desc = "Preview refresh" },
    },
  },
}
