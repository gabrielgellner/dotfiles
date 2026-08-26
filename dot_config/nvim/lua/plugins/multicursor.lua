-- Helix-style multiple cursors.
--
-- The workflow this exists for is not "add a cursor here, and here, and here"
-- — that is what a mouse is for. It is: make one selection, *split* it into
-- many cursors by structure, act on all of them at once, collapse. Helix and
-- Kakoune put that on `s` and `S`; both are taken here (flash), so the whole
-- set lives under `<leader>v` — Helix calls these things *selections*, not
-- cursors, and `v` is where vim keeps selecting.
--
-- Not `<leader>m`: that is markdown's, and it is buffer-local, so `<leader>mr`
-- and `<leader>mx` would have resolved to "toggle render" and "toggle checkbox"
-- inside a markdown buffer and to multicursor everywhere else. Silently — a
-- buffer-local mapping beats a global one with no message, which guides/
-- keymaps.md calls the most common way a keymap appears to do nothing.
--
-- Everything is keyed rather than eager, so the plugin does not load until the
-- first `<leader>v` press.
return {
  "jake-stewart/multicursor.nvim",
  -- Pinned to the branch upstream's README installs, not main. main is the
  -- development branch and has broken the API before.
  branch = "1.0",
  keys = {
    { "<leader>vs", mode = { "x" }, desc = "Split selection by regex" },
    { "<leader>vr", mode = { "x" }, desc = "Cursor at each regex match" },
    { "<leader>vl", mode = { "x" }, desc = "One cursor per line" },
    { "<leader>vI", mode = { "x" }, desc = "Insert at start of each line" },
    { "<leader>vA", mode = { "x" }, desc = "Append at end of each line" },
    { "<leader>vj", mode = { "n", "x" }, desc = "Add cursor on the line below" },
    { "<leader>vk", mode = { "n", "x" }, desc = "Add cursor on the line above" },
    { "<leader>vt", mode = { "n", "x" }, desc = "Rotate cursor contents forward" },
    { "<leader>vT", mode = { "n", "x" }, desc = "Rotate cursor contents back" },
    { "<leader>vv", mode = { "n", "x" }, desc = "Cursor at every match in file" },
    { "<leader>vn", mode = { "n", "x" }, desc = "Add cursor at next match" },
    { "<leader>vN", mode = { "n", "x" }, desc = "Add cursor at prev match" },
    { "<leader>va", mode = { "n", "x" }, desc = "Align cursor columns" },
    { "<leader>vu", mode = { "n", "x" }, desc = "Restore the last cursor set" },
  },
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local function map(lhs, mode, fn, desc)
      vim.keymap.set(mode, lhs, fn, { desc = desc })
    end

    -- ── Making cursors ────────────────────────────────────────────────────
    -- The two that carry the idea. Both prompt for a pattern and act inside
    -- the visual selection: split cuts the selection *at* each match and
    -- leaves a cursor on each piece; match puts a cursor *on* each match.
    map("<leader>vs", { "x" }, mc.splitCursors, "Split selection by regex")
    map("<leader>vr", { "x" }, mc.matchCursors, "Cursor at each regex match")

    -- No pattern needed: one cursor per line of the selection, and the two
    -- that then put you in insert mode at every line's start or end.
    map("<leader>vl", { "x" }, mc.visualToCursors, "One cursor per line")
    map("<leader>vI", { "x" }, mc.insertVisual, "Insert at start of each line")
    map("<leader>vA", { "x" }, mc.appendVisual, "Append at end of each line")

    -- ── Cursors from the word under the cursor ────────────────────────────
    -- vv is the doubled-key ordinary case: every match in the file at once.
    -- mn/mN add them one at a time, so you can skip the ones you do not want.
    map("<leader>vv", { "n", "x" }, mc.matchAllAddCursors, "Cursor at every match in file")
    map("<leader>vn", { "n", "x" }, function()
      mc.matchAddCursor(1)
    end, "Add cursor at next match")
    map("<leader>vN", { "n", "x" }, function()
      mc.matchAddCursor(-1)
    end, "Add cursor at prev match")

    -- ── The column, and rotating between cursors ──────────────────────────
    -- Helix's C and alt-C: the plainest multi-cursor there is, and the one
    -- reached for most. j/k because that is down and up everywhere else here.
    map("<leader>vj", { "n", "x" }, function()
      mc.lineAddCursor(1)
    end, "Add cursor on the line below")
    map("<leader>vk", { "n", "x" }, function()
      mc.lineAddCursor(-1)
    end, "Add cursor on the line above")

    -- Helix's alt-( and alt-): rotate the *contents* between cursors, leaving
    -- the cursors where they are. Nothing in vim does this — swapping two
    -- function arguments is otherwise a yank, two deletes and two pastes.
    map("<leader>vt", { "n", "x" }, function()
      mc.transposeCursors(1)
    end, "Rotate cursor contents forward")
    map("<leader>vT", { "n", "x" }, function()
      mc.transposeCursors(-1)
    end, "Rotate cursor contents back")

    -- ── Housekeeping ──────────────────────────────────────────────────────
    map("<leader>va", { "n", "x" }, mc.alignCursors, "Align cursor columns")
    map("<leader>vu", { "n", "x" }, mc.restoreCursors, "Restore the last cursor set")

    -- ── Only while several cursors exist ──────────────────────────────────
    -- A layer, so these four keys mean their usual thing the rest of the time.
    -- <Esc> is the important one: it is the collapse step, and without a layer
    -- it would have to be a permanent mapping that swallowed escape.
    mc.addKeymapLayer(function(layer)
      layer({ "n", "x" }, "<Tab>", mc.nextCursor, { desc = "Next cursor" })
      layer({ "n", "x" }, "<S-Tab>", mc.prevCursor, { desc = "Prev cursor" })
      layer({ "n", "x" }, "<leader>vx", mc.deleteCursor, { desc = "Delete this cursor" })
      -- Helix's ctrl-a/ctrl-x, except each cursor gets a larger step than the
      -- one before it, so a column of identical numbers becomes a sequence.
      -- In the layer so that both keep vim's plain increment the rest of the
      -- time — which is the same key doing the same thing, just once.
      layer({ "n", "x" }, "<C-a>", mc.sequenceIncrement, { desc = "Increment as a sequence" })
      layer({ "n", "x" }, "<C-x>", mc.sequenceDecrement, { desc = "Decrement as a sequence" })
      layer("n", "<Esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end, { desc = "Collapse to one cursor" })
    end)

    -- Frappe, to match everything else. Cursor and visual are deliberately
    -- different shades: with one colour it is hard to tell a cursor from the
    -- selection it sits in when several overlap.
    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { link = "Cursor" })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn" })
    hl(0, "MultiCursorMatchPreview", { link = "Search" })
    hl(0, "MultiCursorDisabledCursor", { reverse = true })
    hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
    hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
  end,
}
