-- Typst: tinymist is the language server (plugins/lsp.lua), typstyle the
-- formatter (plugins/formatting.lua), and this is the live preview.
--
-- typst-preview.nvim drives `tinymist preview` and opens the browser on it,
-- scrolling the page with the cursor. It talks to that server through
-- websocat (servers/factory.lua spawns it), and by default downloads its own
-- copy of both into nvim's data dir on first use. `dependencies_bin` points it
-- at brew's instead, so bootstrap.sh is the one place that decides versions —
-- and the preview renders with the same typst the LSP checks against.
return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  version = "1.*",
  opts = {
    dependencies_bin = { tinymist = "tinymist", websocat = "websocat" },
  },
  keys = {
    { "<leader>mp", "<cmd>TypstPreview<CR>", ft = "typst", desc = "Preview start" },
    { "<leader>mP", "<cmd>TypstPreviewStop<CR>", ft = "typst", desc = "Preview stop" },
  },
}
