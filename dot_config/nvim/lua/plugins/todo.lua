return {
  "folke/todo-comments.nvim",
  event = "BufReadPost",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    -- No `signs` here: true is the default. No `sign_hl` either — it is not a
    -- key todo-comments reads. Its config knows `signs` and `sign_priority`
    -- and nothing between them; the sign highlight comes from the `TodoSign`
    -- group it builds per keyword. Setting it changed nothing: with
    -- `sign_hl = "DiagnosticSignWarn"` the extmarks still came back
    -- `sign_hl_group = TodoSignTODO`, and every Todo* highlight group was
    -- identical with the key and without it.
    keywords = {
      FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
      TODO = { icon = " ", color = "info" },
      HACK = { icon = " ", color = "warning" },
      WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
      PERF = { icon = "󰅒 ", color = "default", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
      NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
    },
    highlight = {
      before = "",
      keyword = "wide_bg",
      after = "fg",
      pattern = [[.*<(KEYWORDS)\s*:]],
      comments_only = true,
    },
  },
  -- Only the snacks integration is keyed here, and that is deliberate.
  -- todo-comments' other entry points — the trouble source, :TodoQuickFix,
  -- :TodoLocList, the telescope extension — all route through its
  -- Search.search, which needs plenary and, when plenary is absent, returns
  -- without ever calling its callback. So they report nothing rather than
  -- failing.
  --
  -- They work today only by accident. plenary was absent when this was
  -- written, and arrived as a dependency of yazi.lua (2026-09-07) and then
  -- octo.lua, neither of which is about todos. Measured 2026-10-23 on a file
  -- with two: :TodoQuickFix, :TodoLocList and `Trouble todo` each find both,
  -- and each finds none with `plenary.job` blocked in package.preload. plenary
  -- is end of life — critical fixes stopped on 2026-06-30 — so nothing here
  -- should lean on it.
  --
  -- lua/todo-comments/snacks.lua is the path that does not need it, and is
  -- what <leader>ft uses. See the note in plugins/trouble.lua.
  --
  -- To probe those commands headless, run them after VimEnter, not from -c:
  -- todo-comments defers setup to VimEnter (config.lua:90), and until then
  -- Search.search bails on Config.loaded, which looks exactly like the
  -- plenary failure.
  keys = {
    {
      "<leader>ft",
      function()
        Snacks.picker.todo_comments()
      end,
      -- No pre-filtered <leader>fT variant. It listed only TODO/FIX/FIXME, so
      -- the capital gave *fewer* results than the lowercase — backwards from
      -- <leader>fs/fS and ff/fF, where a capital widens. The picker filters
      -- interactively once open, so the second keymap earned little.
      desc = "Todo comments (picker)",
    },
    {
      "]t",
      function()
        require("todo-comments").jump_next()
      end,
      desc = "Next todo",
      mode = { "n", "x", "o" },
    },
    {
      "[t",
      function()
        require("todo-comments").jump_prev()
      end,
      desc = "Prev todo",
      mode = { "n", "x", "o" },
    },
  },
}
