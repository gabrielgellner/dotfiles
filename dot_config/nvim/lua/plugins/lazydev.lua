-- lazydev.nvim — teaches lua_ls about the plugins this config actually loads.
--
-- Why: lua_ls only knows the Neovim runtime (see .luarc.json). It has no idea
-- what `snacks.scratch.Config` is, so every `---@type snacks.*` annotation is an
-- undefined-doc-name warning and plugin APIs get no completion. Adding every
-- plugin's lua/ dir to workspace.library would fix that and make startup crawl —
-- lazydev instead pushes library paths to the server on demand, as the buffer
-- turns out to need them.
--
-- Ordinary `require("foo")` calls are resolved automatically. The `words` entries
-- below cover what lazydev can't infer: globals and bare type annotations, which
-- name a plugin without ever requiring it (config/scratch.lua uses the `Snacks`
-- global and annotates `---@type snacks.scratch.Config`).

return {
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    library = {
      -- vim.uv's types live in the luv meta package, not the nvim runtime.
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      -- `words` are Lua patterns, so `snacks.*` type names match too.
      { path = "snacks.nvim", words = { "Snacks", "snacks%." } },
    },
  },
}
