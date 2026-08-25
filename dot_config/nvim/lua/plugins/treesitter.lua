return {
  -- ── Core treesitter ────────────────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile", "VeryLazy" },
    opts = {
      ensure_installed = {
        "python",
        "lua",
        "luadoc",
        "vim",
        "vimdoc",
        "toml",
        "yaml",
        "json",
        "markdown",
        "markdown_inline",
        "bash",
        "diff",
        -- noice highlights the cmdline through treesitter and asks for this one
        -- by name; without it `:checkhealth noice` reports cmdline highlighting
        -- for `regex` as possibly broken.
        "regex",
        "just",
        "rust",
        "scheme",
        "racket",
        "haskell",
      },
      matchup = {
        enable = true,
      },
    },
    config = function(_, opts)
      local TS = require("nvim-treesitter")

      -- setup core
      TS.setup(opts)

      -- install any missing parsers from ensure_installed
      local installed = TS.get_installed and TS.get_installed() or {}
      local installed_set = {}
      for _, lang in ipairs(installed) do
        installed_set[lang] = true
      end

      local missing = vim.tbl_filter(function(lang)
        return not installed_set[lang]
      end, opts.ensure_installed or {})

      if #missing > 0 then
        vim.notify("nvim-treesitter: installing missing parsers: " .. table.concat(missing, ", "), vim.log.levels.INFO)
        TS.install(missing)
      end

      -- wire up highlighting and indent per filetype
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvim_treesitter_ft", { clear = true }),
        callback = function(ev)
          -- highlighting
          pcall(vim.treesitter.start, ev.buf)

          -- treesitter-powered indent
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

          -- Folds are wired up globally in config/options.lua ('foldmethod',
          -- 'foldexpr', 'foldlevel'), not here. They're window-local options,
          -- and setting them from FileType missed the first buffer of a
          -- session (which got 'foldexpr' but kept foldmethod=manual, so zM
          -- silently did nothing) and every new split.
        end,
      })
    end,
  },

  -- ── Textobjects ────────────────────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    opts = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = { query = "@function.outer", desc = "outer function" },
          ["if"] = { query = "@function.inner", desc = "inner function" },
          ["ac"] = { query = "@class.outer", desc = "outer class" },
          ["ic"] = { query = "@class.inner", desc = "inner class" },
          ["aa"] = { query = "@parameter.outer", desc = "outer argument" },
          ["ia"] = { query = "@parameter.inner", desc = "inner argument" },
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          ["]f"] = "@function.outer",
          ["]k"] = "@class.outer",
          ["]a"] = "@parameter.inner",
          ["]?"] = "@conditional.outer",
          ["]r"] = "@loop.outer",
        },
        goto_next_end = {
          ["]F"] = "@function.outer",
          ["]K"] = "@class.outer",
        },
        goto_previous_start = {
          ["[f"] = "@function.outer",
          ["[k"] = "@class.outer",
          ["[a"] = "@parameter.inner",
          ["[?"] = "@conditional.outer",
          ["[r"] = "@loop.outer",
        },
        goto_previous_end = {
          ["[F"] = "@function.outer",
          ["[K"] = "@class.outer",
        },
      },
    },
    config = function(_, opts)
      local TS = require("nvim-treesitter-textobjects")
      if not TS.setup then
        vim.notify("nvim-treesitter-textobjects: please update the plugin", vim.log.levels.ERROR)
        return
      end
      TS.setup(opts)

      -- attach move keymaps per buffer on FileType
      local function attach(buf)
        -- Only where a parser exists. The guard inside each mapping already
        -- makes them no-ops elsewhere, but a no-op mapping is still a mapping:
        -- snacks' picker help (`?`) lists a buffer's keymaps verbatim, so all
        -- fourteen filled most of the popup for a prompt buffer that can never
        -- use them. Checked by parser rather than by buftype, so a codediff
        -- pane or a preview — nofile buffers holding real code — keeps them.
        if not vim.treesitter.get_parser(buf, nil, { error = false }) then
          return
        end

        local all_moves = {
          goto_next_start = opts.move.goto_next_start or {},
          goto_next_end = opts.move.goto_next_end or {},
          goto_previous_start = opts.move.goto_previous_start or {},
          goto_previous_end = opts.move.goto_previous_end or {},
        }

        for method, keymaps in pairs(all_moves) do
          for key, query in pairs(keymaps) do
            local desc = (key:sub(1, 1) == "[" and "Prev " or "Next ")
              .. query:gsub("@", ""):gsub("%..*", "")
              -- Capitalised suffix = the "end" variant. Match on %u rather than
              -- comparing against :upper(): a non-letter suffix like `?` is
              -- equal to its own uppercase and would be mislabelled an end motion.
              .. (key:sub(2, 2):match("%u") and " end" or " start")

            vim.keymap.set({ "n", "x", "o" }, key, function()
              -- A buffer with no parser throws rather than doing nothing: the
              -- plugin's scoring function indexes a range that was never
              -- produced and raises "E5108: attempt to perform arithmetic on
              -- local 'score' (a nil value)". Every one of these motions did it,
              -- in any filetype without a parser — plain text being the one you
              -- hit daily.
              --
              -- Only a missing parser is the problem. toml, json, markdown and
              -- sh all have parsers but no class query, and the plugin returns
              -- quietly there, so this guard is deliberately about the parser
              -- and not about whether the query exists.
              if not vim.treesitter.get_parser(buf, nil, { error = false }) then
                return
              end
              require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
            end, { buffer = buf, desc = desc, silent = true })
          end
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvim_treesitter_textobjects", { clear = true }),
        callback = function(ev)
          attach(ev.buf)
        end,
      })

      -- attach to already open buffers
      vim.tbl_map(attach, vim.api.nvim_list_bufs())
    end,
  },
}
