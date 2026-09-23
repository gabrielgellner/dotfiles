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
    -- The two disables are about this repo, not this code. lua_ls has the
    -- applied copy of the config on its library path, so editing the chezmoi
    -- source sees `_G.dd` assigned in two files and calls it a duplicate.
    -- Every file here exists twice; only these two assign a global, so this is
    -- the whole of the fallout. Editing ~/.config/nvim directly shows nothing.
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.dd = function(...)
      Snacks.debug.inspect(...)
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.bt = function()
      Snacks.debug.backtrace()
    end
    vim.print = _G.dd
  end,
  opts = {
    -- ── picker (telescope replacement) ──────────────────────────────────────
    picker = {
      -- ── Copy an item out of any picker ────────────────────────────────────
      -- snacks ships a generic `yank` action but binds it nowhere: only the
      -- explorer, the gh sources and the git diff picker get a copy key, so in
      -- <leader>fd, <leader>ff and most others there was no way to get text out
      -- of a picker short of retyping it.
      --
      -- `reg = "+"` rather than the action's default of vim.v.register. With
      -- clipboard=unnamedplus a plain yank already reaches the system
      -- clipboard, but setreg() on the unnamed register does not, and copying
      -- from a picker is nearly always on the way out of Neovim entirely.
      --
      -- The action does not close the picker, so several items can be taken in
      -- a row. It yanks `item.text` — the one-line list entry — which is what
      -- most sources put there; a source with something better to offer
      -- overrides the key, as `notifications` does below with the full message.
      actions = {
        yank_clip = function(picker, item)
          if not item then
            return
          end
          -- Not item.text. For several sources that field is the *search
          -- haystack*, not the display line: buffers builds it from
          -- buf/name/filetype/buftype, so yanking it gave `1 /long/path lua`,
          -- and diagnostics concatenates severity, code, file and source
          -- around the message. list:format() is what the list actually
          -- renders, so what lands in the clipboard is what was on screen.
          local ok, text = pcall(function()
            return (picker.list:format(item))
          end)
          local value = vim.trim((ok and type(text) == "string" and text ~= "") and text or (item.data or item.text))
          vim.fn.setreg("+", value)
          Snacks.notify(("Yanked to `+`:\n```\n%s\n```"):format(value), { title = "Snacks Picker" })
        end,
      },
      win = {
        -- <C-y> in both windows so it works whether or not you have left the
        -- prompt; `y` only in the list, where normal mode is real and the
        -- operator has nothing to act on anyway.
        input = { keys = { ["<c-y>"] = { "yank_clip", mode = { "i", "n" } } } },
        list = { keys = { ["<c-y>"] = "yank_clip", ["y"] = "yank_clip" } },
      },
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
        explorer = {
          -- The explorer starts focused on the list (upstream `focus = "list"`),
          -- so it is a normal-mode buffer, and its `j`/`k` are bound to
          -- list_down/list_up — which read vim.v.count1. `12j` therefore moves
          -- 12 entries already; relative numbers are only the missing half,
          -- turning that count from a guess into something you can read off.
          win = {
            list = {
              wo = {
                number = true,
                relativenumber = true,
                -- Snacks' own statuscolumn (opts.statuscolumn) would otherwise
                -- draw fold and git columns in here and eat the width.
                statuscolumn = "",
                signcolumn = "no",
              },
              -- All three hand the entry under the cursor to another tool.
              -- `O` is the capital of snacks' own `o` (open in the system app)
              -- and means "open it elsewhere"; `T` is for table; `Y` is for
              -- yazi. None is taken by snacks — checked against the picker
              -- list defaults and the explorer source's own key block in the
              -- installed copy.
              --
              -- Read these as a *family of capitals*, not as case pairs. That
              -- distinction matters for `Y`, because snacks binds `y` here to
              -- explorer_yank and guides/keymaps.md is emphatic that a capital
              -- should be the wider version of its lowercase and never a
              -- different action. `Y` is not "yank, but more" — it is the third
              -- hand-off, and the letter is the tool's initial exactly as `O`
              -- and `T` are. The rule is bent knowingly here rather than by
              -- accident; the alternative was a letter with no mnemonic at all.
              --
              -- `T` is not unmapped, though, and checking snacks alone was the
              -- wrong check: these are buffer-local and silently beat globals,
              -- which is this config's most common keymap fault. `maparg("T")`
              -- answers properly — it is flash's clever-f backwards till
              -- (char.lua, and plugins/flash.lua enables `char` on purpose).
              -- Shadowing it here is the one place that costs nothing: the
              -- list is read-only and moved through with j/k, so a horizontal
              -- till-motion has nothing to do. That is also why `T` is *not*
              -- bound in oil, where <leader>tt already reaches plv and the
              -- buffer is editable text in which dT/ and cT, are real edits.
              --
              -- `Y` shadows a global too, and a real one: nvim's own default
              -- maps `Y` to `y$` (measured with maparg). Same answer as `T`
              -- above — the list is read-only, so a yank-to-end-of-line has
              -- nothing to act on.
              keys = {
                ["O"] = "explorer_oil",
                ["T"] = "explorer_plv",
                ["Y"] = "explorer_yazi",
              },
            },
          },
          actions = {
            explorer_oil = function(picker, item)
              require("config.files").oil_from_explorer(picker, item)
            end,
            explorer_plv = function(picker, item)
              require("config.plv").open_from_explorer(picker, item)
            end,
            explorer_yazi = function(picker, item)
              require("config.files").yazi_from_explorer(picker, item)
            end,
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
        -- Snacks' own default list, less two entries.
        --
        -- `Restore Session` carried `section = "session"` instead of an action,
        -- which scans for a session manager and accepts mini.nvim as one — the
        -- monorepo is installed here for mini.bracketed and friends, so it
        -- matched. mini.sessions is never set up, so pressing `s` only ever
        -- produced "(mini.sessions) There are no detected sessions".
        --
        -- `Find Text` is dropped as redundant: <leader>fg reaches the same
        -- picker from anywhere, dashboard included.
        --
        -- Naming the keys here replaces the list wholesale; there is no merge,
        -- so the remaining six are repeated verbatim, icons included.
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "recent_files", limit = 5, padding = 1 },
        { section = "startup" },
      },
    },
    -- ── inline images (mermaid diagrams in markdown) ─────────────────────────
    -- Needs a key here at all: snacks.image is one of the modules marked
    -- `needs_setup`, so it stays off until opts mentions it, unlike notifier or
    -- bigfile which only need a flag flipped.
    --
    -- Nothing here is about kitty or tmux, because neither needs anything.
    -- snacks detects kitty through `tmux display-message -p #{client_termname}`
    -- rather than a TermResponse query (extended-keys would eat that), and it
    -- runs `tmux set -p allow-passthrough all` on the pane itself — pane-scoped,
    -- so `.tmux.conf` stays out of it and a pane that never shows an image never
    -- gets the option set.
    image = {
      enabled = true,
      doc = {
        -- A diagram that fills the window is not inline rendering, it is a
        -- slide. The default 40 rows *is* the whole window here, and it is
        -- also upscaled: snacks sizes an image by reading the PNG's dpi
        -- (mmdc writes 72) and computing `px / 72 * 96 * scale`, while the
        -- `-s {scale}` it passed mmdc already rendered at that scale — so a
        -- 587x790 chart is asked for at 98x57 cells when its own pixels are
        -- worth 33x19, and kitty stretches it to fit.
        --
        -- Capping the height is what corrects both at once, because `fit`
        -- keeps the aspect ratio: 20 rows puts this chart at 34x20, within a
        -- cell of its native resolution, and leaves half the window for the
        -- prose around it. max_width is left alone — the clamp that bites is
        -- always the vertical one, a chart being taller than it is wide.
        max_height = 20,
      },
      convert = {
        -- A failed convert is silent by default: no image, no message, and
        -- nothing in the buffer to say why. Every failure this has had so far
        -- was mmdc's, so let them speak.
        notify = true,
        -- snacks' own mermaid args plus `-p`. mermaid-cli renders through a
        -- headless Chrome that puppeteer pins by exact version, and the brew
        -- bottle ships no browser at all, so a bare `mmdc` dies with
        -- "Could not find chrome-headless-shell (ver. 152.0.7977.54)".
        -- `{"channel": "chrome"}` in the config file points puppeteer at the
        -- *installed* Google Chrome instead: no second browser to download,
        -- and nothing to re-pin the next time mermaid-cli is upgraded.
        -- (Measured: 1.7s for a four-node flowchart, against a hard failure
        -- without it.)
        --
        -- Guarded on the file existing, because `-p` naming a missing file is
        -- a hard error in mmdc — a machine without the config gets the plain
        -- args and whatever browser puppeteer can find on its own.
        mermaid = function()
          local theme = vim.o.background == "light" and "neutral" or "dark"
          local args = { "-i", "{src}", "-o", "{file}", "-b", "transparent", "-t", theme, "-s", "{scale}" }
          local puppeteer = vim.fn.expand("~/.config/mermaid/puppeteer.json")
          if vim.uv.fs_stat(puppeteer) then
            vim.list_extend(args, { "-p", puppeteer })
          end
          return args
        end,
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
    -- ── status column ────────────────────────────────────────────────────────
    -- snacks' own "pretty status column": number, fold column and signs drawn
    -- in one expression, which is what makes a fold marker and a gitsigns hunk
    -- share a cell instead of each claiming their own. It really is applied —
    -- 'statuscolumn' reads
    -- %!v:lua.require'snacks.statuscolumn'.get() in a normal buffer.
    --
    -- (This said "LSP progress indicator", which is a different thing
    -- entirely and not a snacks module at all — the notifier surfaces LSP
    -- progress here. The picker config above already described statuscolumn
    -- correctly, which is how the mislabel survived.)
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
        require("config.files").explorer()
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
      mode = { "n", "x" },
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
        -- Snacks.lazygit() forwards its opts to Snacks.terminal, so the win
        -- table is the terminal's and takes the same maximize key plv uses.
        -- Worth having here for the same reason: a diff is wider than 90% of
        -- the screen more often than it is narrower.
        Snacks.lazygit({
          win = { keys = { maximize = require("config.float").maximize_key() } },
        })
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
