return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 300,
    spec = {
      -- Groups carry an explicit mode list. which-key defaults every spec entry
      -- to normal mode only (which-key/mappings.lua: `mapping.mode or {"n"}`),
      -- so all of these went unnamed the moment there was a selection:
      -- <leader>c rendered as "+3 keymaps" in visual mode, and `gs` as
      -- "+3 keymaps" rather than "surround".
      --
      -- `mode` is an inheriting field, so one nested entry covers the lot.
      -- Naming a group in a mode where nothing lives under it is free —
      -- which-key deletes group nodes that end up with no keymaps beneath them
      -- (tree.lua `keep`/`fix`). That pruning is also why a group declared for
      -- keys that don't exist never shows up at all.
      --
      -- Only groups are nested here. The desc-only entries below have to stay
      -- normal-mode: they are *not* pruned when the keymap is missing (`keep`
      -- is true for any non-group mapping), so claiming e.g. `]b` in visual
      -- mode would invent a row for a mapping mini.bracketed only defines in
      -- normal mode.
      {
        mode = { "n", "x", "o" },

        -- ── Leader groups ─────────────────────────────────────────────────
        { "<leader>a", group = "ai/claude" },
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>cb", group = "base64" },
        { "<leader>d", group = "debug" },
        { "<leader>dt", group = "debug test" },
        { "<leader>f", group = "find/pick" },
        { "<leader>g", group = "git" },
        { "<leader>j", group = "just" },
        { "<leader>l", group = "lsp" },
        { "<leader>m", group = "markdown" },
        { "<leader>n", group = "notes (scratch)" },
        { "<leader>q", group = "quit" },
        { "<leader>s", group = "search/replace" },
        { "<leader>u", group = "ui" },
        { "<leader>w", group = "window" },
        { "<leader>x", group = "diagnostics/quickfix" },
        { "<leader>z", group = "zettelkasten" },

        -- ── Conjure, in lisp buffers ──────────────────────────────────────
        -- conjure hangs ~30 mappings off <localleader> in scheme, racket,
        -- fennel and clojure buffers, and names none of the prefixes — so the
        -- `\` popup listed `c`, `e`, `g` and `l` as "+N keymaps" and `\ec` as
        -- another. Declared unconditionally rather than per-filetype: a group
        -- with no keymaps under it is pruned (tree.lua keep/fix), so these
        -- appear only where conjure has actually loaded.
        { "<localleader>c", group = "repl" },
        { "<localleader>e", group = "eval" },
        { "<localleader>ec", group = "eval + comment" },
        { "<localleader>g", group = "goto" },
        { "<localleader>l", group = "log" },

        -- ── Navigation groups ─────────────────────────────────────────────
        { "[", group = "prev" },
        { "]", group = "next" },
        { "g", group = "goto" },
        { "gs", group = "surround" },
        { "gr", group = "lsp" },
      },

      -- Neovim's own gr* mappings (:h lsp-defaults). The three we override with
      -- pickers describe themselves from plugins/snacks.lua; these are the ones
      -- left native, which carry no desc of their own.
      { "grn", desc = "Rename symbol" },
      { "grx", desc = "Run codelens" },
      { "gra", desc = "Code action", mode = { "n", "x" } },

      { "<leader>?", desc = "Open a guide" },

      -- ── vim-matchup ─────────────────────────────────────────────────────
      -- These are <Plug> mappings with no description of their own, so
      -- which-key fell back to printing the raw `<Plug>(matchup-…)` rhs.
      { "[%", desc = "Prev unmatched open word", mode = { "o", "x" } },
      { "]%", desc = "Next unmatched close word", mode = { "o", "x" } },
      { "g%", desc = "Prev matching word", mode = { "o", "x" } },
      { "z%", desc = "Into nearest inner block", mode = { "n", "o", "x" } },
      -- Nothing to say about these two and nowhere useful to say it: hiding
      -- them also prunes the otherwise-unnamed <C-G> prefix in insert mode.
      { "<C-G>%", hidden = true, mode = "i" },
      { "<2-LeftMouse>", hidden = true },

      -- ── Folds that cannot work here ─────────────────────────────────────
      -- 'foldmethod' is "expr" everywhere (config/options.lua), which makes
      -- manual fold editing impossible: zf/zF raise E350, zd/zD raise E351 and
      -- zE raises E352, in every buffer, always. which-key's "modern" preset
      -- advertises all five, so the z popup was offering keys that only ever
      -- error. Hide them rather than list them — the alternative is giving up
      -- treesitter folds, which are worth far more than manual ones.
      --
      -- Everything else under z is unaffected: zM/zR/zm/zr collapse and expand,
      -- za/zc/zo/zv act on the fold under the cursor, zj/zk move between folds
      -- and zx recomputes them.
      { "zf", hidden = true },
      { "zF", hidden = true },
      { "zd", hidden = true },
      { "zD", hidden = true },
      { "zE", hidden = true },

      -- ── Undo ────────────────────────────────────────────────────────────
      -- mini.bracketed re-maps both to record undo state for [u/]u, and its
      -- wrappers carry no desc, so these showed as raw
      -- `u<Cmd>lua MiniBracketed.register_undo_state()<CR>`.
      { "u", desc = "Undo" },
      { "<C-R>", desc = "Redo" },

      -- ── Treesitter motions ──────────────────────────────────────────────
      { "]f", desc = "Next function" },
      { "[f", desc = "Prev function" },
      { "]F", desc = "End of next function" },
      { "[F", desc = "End of prev function" },
      { "]c", desc = "Next class" },
      { "[c", desc = "Prev class" },
      { "]C", desc = "End of next class" },
      { "[C", desc = "End of prev class" },
      { "]a", desc = "Next argument" },
      { "[a", desc = "Prev argument" },
      { "]?", desc = "Next conditional" },
      { "[?", desc = "Prev conditional" },
      { "]r", desc = "Next loop" },
      { "[r", desc = "Prev loop" },

      -- ── Git review (codediff) ───────────────────────────────────────────
      { "<leader>gv", desc = "Review working tree" },
      { "<leader>gm", desc = "Review branch vs base (MR)" },
      { "<leader>gM", desc = "Branch commits" },
      { "<leader>gh", desc = "File history" },
      { "<leader>gH", desc = "Repo history" },

      -- ── Git hunk motions ────────────────────────────────────────────────
      { "]h", desc = "Next hunk" },
      { "[h", desc = "Prev hunk" },

      -- ── Todo motions ────────────────────────────────────────────────────
      { "]t", desc = "Next todo" },
      { "[t", desc = "Prev todo" },

      -- ── Indent scope (mini.indentscope) ─────────────────────────────────
      { "]i", desc = "Bottom of indent scope" },
      { "[i", desc = "Top of indent scope" },

      -- ── mini.bracketed motions ──────────────────────────────────────────
      { "]b", desc = "Next buffer" },
      { "[b", desc = "Prev buffer" },
      { "]j", desc = "Next jumplist entry" },
      { "[j", desc = "Prev jumplist entry" },
      { "]l", desc = "Next location list entry" },
      { "[l", desc = "Prev location list entry" },
      { "]q", desc = "Next quickfix entry" },
      { "[q", desc = "Prev quickfix entry" },
      { "]o", desc = "Next oldfile" },
      { "[o", desc = "Prev oldfile" },
      { "]u", desc = "Next undo state" },
      { "[u", desc = "Prev undo state" },
      { "]w", desc = "Next window" },
      { "[w", desc = "Prev window" },
      { "]x", desc = "Next conflict marker" },
      { "[x", desc = "Prev conflict marker" },
      { "]y", desc = "Newer yank (replace paste)" },
      { "[y", desc = "Older yank (replace paste)" },

      -- ── Diagnostic motions ──────────────────────────────────────────────
      { "]d", desc = "Next diagnostic" },
      { "[d", desc = "Prev diagnostic" },
      { "]e", desc = "Next error" },
      { "[e", desc = "Prev error" },
    },
  },
}
