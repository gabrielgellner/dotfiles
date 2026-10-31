-- Quarto (.qmd): markdown with executable code chunks.
--
-- quarto-nvim adds the commands (:QuartoPreview) and the chunk runner; otter
-- is what makes the chunks real code. It mirrors each language's chunks into a
-- hidden buffer of that filetype, starts that language's server on it (pyrefly,
-- jetls, …, from plugins/lsp.lua — nothing is configured twice), and forwards
-- requests from the .qmd to it. Completion reaches blink through the ordinary
-- LSP source, since otter presents itself as a language server.
--
-- Every other default is the wanted one, so only python's runner is set: LSP
-- for every language found in the document (`languages = nil`), diagnostics on
-- save, and slime as the runner. Read from lua/quarto/config.lua.
return {
  {
    "quarto-dev/quarto-nvim",
    ft = "quarto",
    dependencies = {
      "jmbuhr/otter.nvim",
      "nvim-treesitter/nvim-treesitter",
      "jpalardy/vim-slime",
    },
    opts = {
      codeRunner = {
        ft_runners = {
          -- python's REPL takes a multi-line paste as one block and then wants
          -- a blank line to run it; slime sends a single Enter after the
          -- paste, which left a cell sitting at `...` until a second Enter.
          -- julia's REPL runs on the one Enter, so this is python's alone.
          python = function(cell)
            vim.fn["slime#send"](require("quarto.tools").concat(cell.text) .. "\n")
          end,
        },
      },
    },
    keys = {
      -- Under <localleader>e for the same reason conjure's are: "eval".
      -- which-key already declares the group (plugins/whichkeys.lua).
      { "<localleader>ee", function() require("quarto.runner").run_cell() end, ft = "quarto", desc = "Run cell" },
      { "<localleader>ea", function() require("quarto.runner").run_above() end, ft = "quarto", desc = "Run cell and above" },
      { "<localleader>eb", function() require("quarto.runner").run_all() end, ft = "quarto", desc = "Run all cells" },
      { "<localleader>el", function() require("quarto.runner").run_line() end, ft = "quarto", desc = "Run line" },
      { "<localleader>E", function() require("quarto.runner").run_range() end, mode = "x", ft = "quarto", desc = "Run selection" },
      { "<leader>mp", "<cmd>QuartoPreview<CR>", ft = "quarto", desc = "Preview start" },
      { "<leader>mP", "<cmd>QuartoClosePreview<CR>", ft = "quarto", desc = "Preview stop" },
    },
  },

  -- The runner's transport. Chunks go to window 2 of this tmux session, the
  -- console bin/new-session opens and config/just.lua also targets. Start the
  -- REPL there yourself (`python`, `julia`): slime types into whatever the
  -- pane is running, so into a bare shell a Python chunk is run as zsh.
  {
    "jpalardy/vim-slime",
    lazy = true,
    init = function()
      vim.g.slime_target = "tmux"
      -- Multi-line chunks arrive as one paste, so the REPL does not run them a
      -- line at a time (python's REPL would end an indented block early).
      vim.g.slime_bracketed_paste = 1
      vim.g.slime_dont_ask_default = 1
      -- $TMUX is "<socket path>,<pid>,<session>"; slime passes an absolute
      -- socket_name as `tmux -S`. `:2` carries no session, so tmux resolves it
      -- against the session $TMUX names — the one this nvim is running in.
      vim.g.slime_default_config = {
        socket_name = vim.split(vim.env.TMUX or "default", ",")[1],
        target_pane = ":2",
      }
    end,
  },
}
