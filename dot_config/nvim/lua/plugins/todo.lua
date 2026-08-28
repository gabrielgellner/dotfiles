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
  -- Only the snacks integration is wired up here, and that is deliberate.
  -- todo-comments' other entry points — the trouble source, :TodoQuickFix,
  -- :TodoLocList, the telescope extension — all route through its
  -- Search.search, which requires plenary and, when plenary is absent, returns
  -- without ever calling its callback. So they report nothing rather than
  -- failing. plenary is not installed here and deliberately will not be — it
  -- is end of life, archived-pending, and stopped taking even critical fixes
  -- on 2026-06-30. Those entry points are therefore permanently dead unless
  -- todo-comments migrates off it upstream.
  --
  -- lua/todo-comments/snacks.lua is the path that does not need it, and is
  -- what <leader>ft uses. See the note in plugins/trouble.lua.
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
