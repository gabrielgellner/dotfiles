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
      --
      -- The price is that in visual and operator-pending the bracket motions
      -- fall back to whatever wording the plugin gave them — `d[` lists "Git:
      -- Prev hunk", "Conflict backward", "Jump backward". That is accurate if
      -- inconsistent, and the alternative is auditing per key which of them
      -- exist in which modes. The matchup entries below are listed per mode
      -- for exactly that reason: there the fallback was wrong, not just
      -- differently worded.
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
        -- codediff's own stage/unstage/discard keys, buffer-local to its diff
        -- buffers. The haskell group used to sit on this prefix and hid them;
        -- with it gone the popup showed `h` as "+3 keymaps" there (measured).
        -- Same pruning argument as the rest: it appears only where codediff has
        -- opened a buffer.
        { "<leader>h", group = "hunk" },
        { "<leader>j", group = "just" },
        { "<leader>l", group = "lsp" },
        { "<leader>m", group = "markdown" },
        { "<leader>n", group = "notes (scratch)" },
        { "<leader>v", group = "multicursor" },
        { "<leader>q", group = "quit" },
        { "<leader>s", group = "search/replace" },
        { "<leader>t", group = "table (plv)" },
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

      -- A desc here *overrides* the one the mapping already carries — measured:
      -- ]c shows "Next hunk / change" rather than gitsigns' own "Git: Next
      -- hunk", and ]e shows "Next error" rather than "LSP: Next error". That is
      -- what most of the entries below are for: normalising wording that reads
      -- as a plugin's internals ("Buffer forward", "Conflict forward") into
      -- what the key does. It also means a keymap that already has a good desc
      -- does not need an entry here.
      --
      -- Neovim's own gr* mappings (:h lsp-defaults). The three we override with
      -- pickers describe themselves from plugins/snacks.lua; these are the ones
      -- left native. They are not desc-less — their desc is the rhs itself, so
      -- the popup read "vim.lsp.buf.rename()" until these three lines.
      { "grn", desc = "Rename symbol" },
      { "grx", desc = "Run codelens" },
      { "gra", desc = "Code action", mode = { "n", "x" } },

      { "<leader>?", desc = "Open a guide" },

      -- ── vim-matchup ─────────────────────────────────────────────────────
      -- These are <Plug> mappings with no description of their own, so
      -- which-key fell back to printing the raw `<Plug>(matchup-…)` rhs.
      -- All three modes, not just o/x. matchup maps these in normal mode too,
      -- and there which-key fell back to its own presets.lua text: `]%` read
      -- "Next unmatched group", and `g%` read "Cycle backwards through
      -- results", which describes matchit's search cycling rather than
      -- anything matchup does. z% below already had the full list.
      { "[%", desc = "Prev unmatched open word", mode = { "n", "o", "x" } },
      { "]%", desc = "Next unmatched close word", mode = { "n", "o", "x" } },
      { "g%", desc = "Prev matching word", mode = { "n", "o", "x" } },
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

      -- ── Git review (codediff) ───────────────────────────────────────────
      { "<leader>gv", desc = "Review working tree" },
      { "<leader>gd", desc = "Review this file" },
      { "<leader>gD", desc = "Review this file vs HEAD~" },
      { "<leader>gm", desc = "Review branch vs base (MR)" },
      { "<leader>gM", desc = "Branch commits" },
      { "<leader>gh", desc = "File history" },
      { "<leader>gH", desc = "Repo history" },

      -- ── Git hunk motions ────────────────────────────────────────────────
      { "]c", desc = "Next hunk / change" },
      { "[c", desc = "Prev hunk / change" },

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
