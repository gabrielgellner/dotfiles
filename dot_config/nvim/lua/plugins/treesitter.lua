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

      -- Everything below is per-buffer, so it needs applying to buffers that
      -- already exist as well as to the ones FileType will announce later.
      ---@param buf integer
      local function attach(buf)
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        -- highlighting
        pcall(vim.treesitter.start, buf)

        -- treesitter-powered indent.
        --
        -- The two indent engines agree where it counts: typing `o` under
        -- `if a:` indents to eight columns whether python#GetIndent or this
        -- expression is in charge. They diverge only when re-indenting python
        -- that is *already* flat, where treesitter can do nothing at all — the
        -- parse tree it would need is the thing the missing indentation
        -- destroys. Vim's heuristic indent can guess; a parser cannot.
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end

      -- The first buffer of a session, which is the one this used to miss.
      --
      -- config() runs on BufReadPost, and for the file Neovim was started with
      -- that is too late: its FileType has already fired, so the autocmd below
      -- never sees it. Measured before this loop existed — buffer 1 reported
      -- `highlighter.active[buf] = false` and no captures under the cursor on a
      -- `def`, while the very next buffer opened in the same session reported
      -- true and `keyword.function`. The first file you open every session was
      -- falling back to Vim's regex syntax, which is close enough to right that
      -- nothing looked broken.
      --
      -- The same hole is described a few lines down for folds, which were moved
      -- out to config/options.lua because of it. Highlighting cannot move
      -- there — it is per buffer, not an option — so it catches up instead.
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          attach(buf)
        end
      end

      -- wire up highlighting and indent per filetype
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvim_treesitter_ft", { clear = true }),
        callback = function(ev)
          attach(ev.buf)

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
    -- No `select` block. It declared af/if/ac/ic/aa/ia and bound none of them:
    -- on this branch `select.keymaps` is the old master-branch schema, the same
    -- way `matchup` was in nvim-treesitter's own opts. `move` below is read, so
    -- the halves genuinely differ.
    --
    -- It looked alive because mini.ai owns the `a`/`i` prefix and answered with
    -- its builtins — a function *call* for `f`, and nothing at all for `c`.
    -- plugins/mini.lua now gives mini.ai treesitter specs for both, so the keys
    -- mean what this block always claimed they meant, through the plugin that
    -- actually owns them. Parameter stays on mini.ai's pattern-based builtin,
    -- which works in filetypes with no parser.
    opts = {
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
