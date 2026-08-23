return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,

  -- Debug globals, available everywhere — including inside plugin code you're
  -- poking at, where adding a require() would be a nuisance. `print` is useless
  -- on tables; dd() pretty-prints with Lua highlighting and names the caller.
  --
  -- Safe to define before Snacks loads: the closures only look Snacks up when
  -- called. Pointing vim.print at dd means `:=expr` and `:lua =expr` get the
  -- pretty view too (at the cost of vim.print's return value, which nothing
  -- here relies on).
  init = function()
    _G.dd = function(...)
      Snacks.debug.inspect(...)
    end
    _G.bt = function()
      Snacks.debug.backtrace()
    end
    vim.print = _G.dd
  end,
  opts = {
    -- ── picker (telescope replacement) ──────────────────────────────────────
    picker = {
      sources = {
        -- Notification history. Everything about this source lives here rather
        -- than at the keymap so the layout and the extra actions travel
        -- together with the source.
        notifications = {
          layout = {
            preset = "default",
            layout = {
              width = 0.9,
              height = 0.9,
              box = "vertical", -- stack list and preview vertically
              {
                box = "vertical",
                border = "rounded",
                title = "{title} {live} {flags}",
                { win = "input", height = 1, border = "bottom" },
                { win = "list", height = 0.4 },
              },
              { win = "preview", border = "rounded", height = 0.6 },
            },
          },
          -- A picker item's `text` is the one-line list entry (level, title and
          -- message flattened together); the notification itself hangs off
          -- `item.item`. Both actions below read `.msg` from there, so what you
          -- get is the full multi-line message, not the truncated list line.
          actions = {
            yank_msg = function(picker, item)
              if not item then
                return
              end
              picker:close()
              local msg = item.item and item.item.msg or item.text
              vim.fn.setreg(vim.v.register, msg)
              vim.fn.setreg("+", msg)
            end,
            -- ClaudeCodeSend @-mentions a *file range*; it never ships raw text.
            -- So the message has to exist on disk before Claude can be pointed
            -- at it. Each send gets its own file: reusing one path would
            -- silently rewrite what an earlier mention still refers to.
            send_to_claude = function(picker, item)
              if not item then
                return
              end
              picker:close()
              local msg = item.item and item.item.msg or item.text
              local dir = vim.fn.stdpath("state") .. "/notifications"
              vim.fn.mkdir(dir, "p")
              local path = ("%s/%s.md"):format(dir, os.date("%Y%m%d-%H%M%S"))
              local lines = vim.split(msg, "\n", { plain = true })
              vim.fn.writefile(lines, path)
              -- 0-indexed, end-inclusive on Claude's side.
              require("claudecode").send_at_mention(path, 0, #lines - 1, "notification")
            end,
          },
          win = {
            input = {
              keys = {
                ["<c-y>"] = { "yank_msg", mode = { "i", "n" } },
                ["<c-o>"] = { "send_to_claude", mode = { "i", "n" } },
              },
            },
            list = {
              keys = {
                ["<c-y>"] = "yank_msg",
                ["<c-o>"] = "send_to_claude",
              },
            },
          },
        },
        files = {
          hidden = true, -- show dotfiles like .env .gitignore
          ignored = false, -- respect .gitignore by default
          args = {
            "--exclude",
            ".venv",
            "--exclude",
            "__pycache__",
            "--exclude",
            ".git",
            "--exclude",
            "node_modules",
            "--exclude",
            "*.pyc",
          },
        },
      },
      enabled = true,
      layout = {
        preset = "default",
        layout = {
          width = 0.9,
          height = 0.9,
        },
      },
    },
    -- ── scratch notebooks ────────────────────────────────────────────────────
    -- Persistent per-project working notes. See config/scratch.lua for the
    -- rationale and the day-heading/promote behaviour.
    scratch = {
      name = "Notes",
      ft = "markdown", -- always markdown, even when opened from a code buffer
      -- Outside nvim's data dir so notes survive a plugin wipe (and can be a
      -- git repo of their own).
      root = vim.fn.expand("~/scratch"),
      autowrite = true,
      filekey = {
        cwd = true, -- one notebook per project
        branch = false, -- ...but not per branch: a plan outlives the branch
        count = true, -- 2<leader>nn opens a second notebook for the project
      },
      win = {
        width = 0.7,
        height = 0.85,
        border = "rounded",
        wo = {
          winhighlight = "NormalFloat:Normal",
          wrap = true,
          linebreak = true,
          spell = true,
          conceallevel = 2, -- let render-markdown conceal link/heading syntax
        },
      },
    },
    -- ── notifier ─────────────────────────────────────────────────────────────
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    -- ── dashboard ────────────────────────────────────────────────────────────
    dashboard = {
      enabled = true,
      preset = {
        header = [[
  /\_/\    /\_/\
  ( o.o )--( o.o )
  > ^ <    > ^ <]],
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "recent_files", limit = 5, padding = 1 },
        { section = "startup" },
      },
    },
    -- ── lazygit ──────────────────────────────────────────────────────────────
    lazygit = { enabled = true },
    -- ── indent guides (using mini.indentscope instead) ────────────────────────
    indent = { enabled = false },
    -- ── large file handling ───────────────────────────────────────────────────
    bigfile = { enabled = true },
    -- ── smooth scrolling ─────────────────────────────────────────────────────
    -- Disabled: animated scroll fights this VM's redraw lag; prefer vim's
    -- instant jump.
    scroll = { enabled = false },
    -- ── LSP progress indicator ───────────────────────────────────────────────
    statuscolumn = { enabled = true },
  },
  keys = {
    -- files
    {
      "<leader>ff",
      function()
        Snacks.picker.smart()
      end,
      -- `smart` ranks open buffers and recent files above a plain file scan,
      -- so this is the one to reach for by default.
      desc = "Find files (smart)",
    },
    {
      "<leader>fF",
      function()
        Snacks.picker.files()
      end,
      desc = "Find files (all)",
    },
    {
      "<leader>fr",
      function()
        Snacks.picker.recent()
      end,
      desc = "Recent files",
    },
    {
      "<leader>fb",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Buffers",
    },
    {
      "<leader>fe",
      function()
        Snacks.picker.explorer({
          auto_close = true,
          layout = {
            layout = {
              position = "float",
              width = 0.4,
              height = 0.8,
            },
          },
        })
      end,
      desc = "File Explorer",
    },
    -- search
    {
      "<leader>fg",
      function()
        Snacks.picker.grep()
      end,
      desc = "Live grep",
    },
    {
      "<leader>fw",
      function()
        Snacks.picker.grep_word()
      end,
      desc = "Grep word under cursor",
      mode = { "n", "v" },
    },
    -- lsp
    {
      -- Dispatches on filetype: markdown has no documentSymbol provider (zk's
      -- LSP doesn't implement it), so fall back to a treesitter-built heading
      -- outline. See config/markdown_outline.lua.
      "<leader>fs",
      function()
        require("config.markdown_outline").symbols()
      end,
      desc = "Symbols (LSP / markdown outline)",
    },
    {
      "<leader>fS",
      function()
        Snacks.picker.lsp_workspace_symbols()
      end,
      desc = "LSP workspace symbols",
    },
    {
      "<leader>fd",
      function()
        Snacks.picker.diagnostics()
      end,
      desc = "Diagnostics",
    },
    -- LSP navigation sits inside Neovim's own `gr*` namespace (:h lsp-defaults)
    -- rather than beside it. `gr` used to be references, which made it both a
    -- complete action and the prefix for grn/gra/gri/grr/grt/grx: with
    -- 'timeoutlen' at 300ms, a third keystroke that arrived late silently
    -- opened a references picker instead. Deleting `gr` makes it a pure prefix
    -- and the ambiguity goes away.
    --
    -- Fighting the other way — keeping `gr` and deleting the defaults — is a
    -- standing commitment: grx (codelens) only appeared in 0.12, so the
    -- namespace grows with each release.
    --
    -- The three that have a nicer picker are overridden here; grn, gra and grx
    -- stay exactly as Neovim defines them.
    {
      "grr",
      function()
        Snacks.picker.lsp_references()
      end,
      desc = "LSP references",
    },
    {
      "gri",
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "LSP implementations",
    },
    {
      "grt",
      function()
        Snacks.picker.lsp_type_definitions()
      end,
      desc = "LSP type definitions",
    },
    {
      "gd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "LSP definitions",
    },
    {
      -- Same dispatch as <leader>fs, so both symbol keys behave alike —
      -- including the treesitter heading fallback for markdown.
      "gO",
      function()
        require("config.markdown_outline").symbols()
      end,
      desc = "Document symbols",
    },
    -- vim
    {
      "<leader>fh",
      function()
        Snacks.picker.help()
      end,
      desc = "Help tags",
    },
    {
      "<leader>fk",
      function()
        Snacks.picker.keymaps()
      end,
      desc = "Keymaps",
    },
    {
      "<leader>fc",
      function()
        Snacks.picker.commands()
      end,
      desc = "Commands",
    },
    {
      "<leader>f/",
      function()
        Snacks.picker.search_history()
      end,
      desc = "Search history",
    },
    {
      -- Pairs with f/ above: the two histories on the two keys that already
      -- mean "search" and "command" at a vim prompt.
      "<leader>f:",
      function()
        Snacks.picker.command_history()
      end,
      desc = "Command history",
    },
    {
      -- `;` is vim's repeat-last-motion, so it reads as "that picker again".
      -- Deliberately not <leader>fR: `fr` is recent files, and a capital that
      -- means an unrelated action rather than a wider one is the mistake this
      -- namespace was just cleaned of.
      "<leader>f;",
      function()
        Snacks.picker.resume()
      end,
      desc = "Resume last picker",
    },
    {
      -- Fuzzy-find within the current buffer — the picker equivalent of the
      -- structural motions in guides/navigation.md, for when you know the text
      -- but not where it is.
      "<leader>fl",
      function()
        Snacks.picker.lines()
      end,
      desc = "Buffer lines",
    },
    -- Pickers over the lists the [ / ] motions step through one at a time
    -- (plugins/mini.lua): see the whole list and jump, instead of walking it.
    {
      "<leader>fm",
      function()
        Snacks.picker.marks()
      end,
      desc = "Marks",
    },
    {
      "<leader>fj",
      function()
        Snacks.picker.jumps()
      end,
      desc = "Jumps",
    },
    {
      "<leader>fu",
      function()
        Snacks.picker.undo()
      end,
      desc = "Undo tree",
    },
    {
      -- `"` is how you name a register in vim, so it needs no other mnemonic.
      '<leader>f"',
      function()
        Snacks.picker.registers()
      end,
      desc = "Registers",
    },
    -- git
    {
      -- Changed files, i.e. `git status`. Not on <leader>gs or gS — gitsigns
      -- holds both for stage hunk and stage buffer.
      "<leader>gf",
      function()
        Snacks.picker.git_status()
      end,
      desc = "Changed files (status)",
    },
    {
      "<leader>gc",
      function()
        Snacks.picker.git_log()
      end,
      -- `c` is for commits; the picker is the log that lists them.
      desc = "Commits (log)",
    },
    {
      "<leader>gb",
      function()
        Snacks.picker.git_branches()
      end,
      desc = "Git branches",
    },
    {
      "<leader>gg",
      function()
        Snacks.lazygit()
      end,
      desc = "Lazygit",
    },
    -- scratch notebooks
    {
      -- Same action as <leader>nn, kept at the top level because it is the
      -- most-reached-for key in the group.
      "<leader>.",
      function()
        require("config.scratch").open()
      end,
      desc = "Project notes (quick)",
    },
    {
      "<leader>nn",
      function()
        require("config.scratch").open()
      end,
      desc = "Toggle project notes",
    },
    {
      "<leader>ng",
      function()
        -- Not keyed to cwd: the notebook for cross-project thinking and plans.
        require("config.scratch").open({ name = "Journal", filekey = { cwd = false } })
      end,
      desc = "Toggle global journal",
    },
    -- A Lua pad, deliberately not routed through config.scratch: that seeds
    -- markdown headings, which are syntax errors here.
    --
    -- The point of the lua filetype is Snacks' own `win_by_ft.lua` default,
    -- which binds <cr> in normal *and* visual mode to Snacks.debug.run: the
    -- buffer (or just the selection) runs with `print` output inlined beside
    -- the code and errors raised as diagnostics. Selection-running is what
    -- makes this a REPL rather than a :source keymap.
    --
    -- Not keyed to cwd — this is for learning the API, not per-project work.
    -- The `wo` overrides undo the markdown-oriented window options above.
    {
      "<leader>nl",
      function()
        Snacks.scratch.open({
          name = "Lua",
          ft = "lua",
          filekey = { cwd = false },
          win = { wo = { spell = false, wrap = false, conceallevel = 0 } },
        })
      end,
      desc = "Toggle Lua scratchpad",
    },
    -- The same runner is bound for real config files too, but per-buffer on
    -- FileType lua (config/autocmds.lua) rather than as a global key here:
    -- Snacks.debug.run executes the buffer as Lua, so a global <leader>cx would
    -- show up in the code popup of every filetype and error on all of them.
    {
      "<leader>ns",
      function()
        Snacks.scratch.select()
      end,
      desc = "Select notebook",
    },
    {
      "<leader>np",
      function()
        require("config.scratch").promote()
      end,
      desc = "Promote buffer to zk note",
    },
    -- notifications
    {
      "<leader>fn",
      function()
        Snacks.picker.notifications()
      end,
      desc = "Notification history",
    },
    {
      "<leader>un",
      function()
        Snacks.notifier.hide()
      end,
      desc = "Dismiss notifications",
    },
  },
}
