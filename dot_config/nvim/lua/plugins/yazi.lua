-- yazi in a float, as the third file browser.
--
-- The other two and the handoff between them are in config/files.lua: the
-- snacks explorer is a tree you navigate, oil is one directory as an editable
-- buffer. yazi is a third shape rather than a duplicate of either — two panes
-- and a live preview, and it is the *same* yazi `y` opens in the shell, so the
-- keys carry over in both directions. guides/yazi.md is the card for them.
--
-- What it is for here is the multi-file selection. `<Space>` marks files and
-- the marks accumulate across directories, then `<c-x>`, `<c-v>` or `<c-t>`
-- open the whole marked set into splits or tabs in one go. The explorer opens
-- one thing at a time and oil only ever shows a single directory, so neither
-- reaches that.
--
-- `cmd` is declared so `:Yazi`, `:Yazi toggle` and `:Yazi logs` can be typed
-- without a key having loaded the plugin first. The explorer handoff in
-- config/files.lua does not go through it: `:Yazi` takes only the three
-- subcommands and rejects anything else with "command does not exist"
-- (yazi/commands.lua), so opening at a given directory is the Lua API,
-- `require("yazi").yazi(nil, dir)` — which is what `:Yazi cwd` itself calls.

return {
  "mikavilpas/yazi.nvim",
  version = "*",
  dependencies = { { "nvim-lua/plenary.nvim", lazy = true } },
  cmd = "Yazi",
  keys = {
    -- Under `<leader>f` with the other ways of finding a file, and a genuine
    -- scope pair in the sense guides/keymaps.md means: the same action, the
    -- lowercase one narrower. `fy` starts where the buffer you are in lives,
    -- `fY` starts at the project root.
    { "<leader>fy", "<cmd>Yazi<cr>", desc = "Yazi (this file)" },
    { "<leader>fY", "<cmd>Yazi cwd<cr>", desc = "Yazi (cwd)" },
  },
  opts = {
    -- A default, restated because it is the one option here that would break
    -- something else. `true` makes yazi open any directory argument, which is
    -- the job oil already claims through `default_file_explorer`
    -- (plugins/oil.lua) — two plugins racing for the same event, with `-` and
    -- `<leader>-` on the losing side. yazi is reached deliberately here, never
    -- by opening a directory.
    open_for_directories = false,

    -- `<c-s>` inside the float greps the directory yazi is in, and yazi.nvim
    -- routes that through **telescope** by default (yazi/config.lua:58). There
    -- is no telescope here and never has been, so the key could only error —
    -- which guides/keymaps.md says not to ship. yazi.nvim offers
    -- "snacks.picker" as an implementation, and snacks is what every other
    -- picker in this config already is, so the key lands in the same UI as
    -- `<leader>fg`.
    --
    -- `<c-g>` needs no such repair: it replaces through grug-far, which is
    -- already installed (plugins/grugfar.lua).
    integrations = {
      grep_in_directory = "snacks.picker",
      grep_in_selected_files = "snacks.picker",
    },
  },
}
