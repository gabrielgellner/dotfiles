return {
  "lewis6991/gitsigns.nvim",
  event = "BufReadPre",
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "󰍵" },
      topdelete = { text = "󰍵" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    signs_staged = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "󰍵" },
      topdelete = { text = "󰍵" },
      changedelete = { text = "▎" },
    },
    on_attach = function(bufnr)
      local gs = require("gitsigns")
      local map = function(keys, func, desc, mode)
        vim.keymap.set(mode or "n", keys, func, { buffer = bufnr, desc = "Git: " .. desc })
      end

      -- ── Navigation ──────────────────────────────────────────────────────
      -- n/x/o, so a hunk works as an operator target: d]h, y[h, v]h. The
      -- `normal!` bang is what keeps the diff-mode branch working now that ]c
      -- is the treesitter class motion — it ignores mappings and reaches vim's
      -- native next-change.
      local MOTION = { "n", "x", "o" }

      map("]h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, "Next hunk", MOTION)

      map("[h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Prev hunk", MOTION)

      -- ── Staging ─────────────────────────────────────────────────────────
      map("<leader>gs", gs.stage_hunk, "Stage hunk")
      map("<leader>gr", gs.reset_hunk, "Reset hunk")
      map("<leader>gS", gs.stage_buffer, "Stage buffer")
      map("<leader>gR", gs.reset_buffer, "Reset buffer")
      -- No unstage mapping: gitsigns deprecated undo_stage_hunk, and the
      -- replacement is stage_hunk() itself — on a staged sign it unstages.
      -- signs_staged (above) is what makes those hunks visible to aim at, so
      -- <leader>gs is now both "stage" and "unstage" depending on the sign.

      -- visual mode stage/reset just the selected lines
      map("<leader>gs", function()
        gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Stage hunk", "v")
      map("<leader>gr", function()
        gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Reset hunk", "v")

      -- ── Preview / blame ─────────────────────────────────────────────────
      map("<leader>gp", gs.preview_hunk, "Preview hunk")
      map("<leader>gP", gs.preview_hunk_inline, "Preview hunk inline")
      -- Blame sits on gl/gL, not gb/gB. These are buffer-local and gitsigns
      -- attaches to every tracked file, so <leader>gb here shadowed the Snacks
      -- git_branches picker (plugins/snacks.lua) everywhere it mattered.
      map("<leader>gl", function()
        gs.blame_line({ full = true })
      end, "Blame line")
      map("<leader>gL", gs.toggle_current_line_blame, "Toggle line blame")
      -- Whole-file blame in a scrollbound split, as against gl's popup for one
      -- line. gB came free when blame moved off gb/gB so the branches picker
      -- could have gb.
      map("<leader>gB", gs.blame, "Blame file")
      map("<leader>gd", gs.diffthis, "Diff this")
      map("<leader>gD", function()
        gs.diffthis("~")
      end, "Diff this ~")

      -- ── Text object — ih selects the hunk ───────────────────────────────
      vim.keymap.set(
        { "o", "x" },
        "ih",
        ":<C-u>Gitsigns select_hunk<CR>",
        { buffer = bufnr, desc = "Git: select hunk" }
      )
    end,
  },
}
