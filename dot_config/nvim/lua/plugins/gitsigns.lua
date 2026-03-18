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
      map("]h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, "Next hunk")

      map("[h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Prev hunk")

      -- ── Staging ─────────────────────────────────────────────────────────
      map("<leader>gs", gs.stage_hunk, "Stage hunk")
      map("<leader>gr", gs.reset_hunk, "Reset hunk")
      map("<leader>gS", gs.stage_buffer, "Stage buffer")
      map("<leader>gR", gs.reset_buffer, "Reset buffer")
      map("<leader>gu", gs.undo_stage_hunk, "Undo stage hunk")

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
      map("<leader>gb", function()
        gs.blame_line({ full = true })
      end, "Blame line")
      map("<leader>gB", gs.toggle_current_line_blame, "Toggle line blame")
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
