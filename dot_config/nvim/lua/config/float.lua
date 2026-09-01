-- Maximize a snacks float, and put it back.
--
-- snacks ships a toggle_maximize for *pickers* (snacks.layout) and one for zen
-- mode, but `snacks.win` itself has none — so a terminal float, which is what
-- plv and lazygit are, cannot grow. This is that missing piece, and it is
-- built out of sizing snacks.win already does rather than out of
-- nvim_win_set_config directly:
--
--   * `width`/`height` of **0** means the whole parent. win.lua's `dim()`
--     returns `parent - border_offset` for 0, so a bordered float lands
--     exactly flush rather than two columns over.
--   * a value below 1 is a fraction of the parent — which is what the floats
--     here are configured with (plv is 0.9 x 0.9).
--   * `win:update()` re-runs `nvim_win_set_config` from `win.opts`.
--
-- So maximizing is "set both to 0 and update", and restoring is "put the old
-- numbers back". Nothing has to know what the original size *was* except this
-- module, which is why the sizes stay where they were configured.

local M = {}

-- Where the pre-maximize size is parked. On the win itself, because that is
-- the thing whose lifetime it shares — a closed float takes its saved size
-- with it, and a reopened one starts unmaximized. Namespaced with a prefix
-- because `snacks.win` is snacks' table and not ours to add plain fields to.
local SAVED = "_config_float_saved_size"

---Toggle `win` between its configured size and the full editor.
---@param win snacks.win
function M.toggle_maximize(win)
  -- A float whose process has exited can still have its key pressed, and
  -- win:update() on a dead window would throw rather than no-op.
  if not (win and win:valid()) then
    return
  end

  local saved = win[SAVED]
  if saved then
    win.opts.width, win.opts.height = saved.width, saved.height
    win[SAVED] = nil
  else
    win[SAVED] = { width = win.opts.width, height = win.opts.height }
    win.opts.width, win.opts.height = 0, 0
  end

  win:update()
end

---A `keys` entry for a snacks win, ready to drop into its `win.keys` table.
---
---`<a-m>` to match the picker, where snacks binds toggle_maximize to the same
---key — one keystroke means "make this bigger" whether the float is a picker,
---a table or lazygit.
---
---mode `t` as well as `n` is what makes it work at all: these are terminal
---floats and the job owns the keyboard, so a normal-mode-only mapping would
---never fire. The cost is the same one config/keymaps.lua accepts for `<C-x>`
---— the program inside never receives `<a-m>`.
---@param lhs? string
function M.maximize_key(lhs)
  return {
    lhs or "<a-m>",
    function(win)
      M.toggle_maximize(win)
    end,
    mode = { "n", "t" },
    desc = "Toggle maximize",
  }
end

return M
