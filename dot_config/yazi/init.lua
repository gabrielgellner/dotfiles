-- Plugin setup. yazi runs this once at startup. package.toml beside it pins the
-- *fetched* trees — compress and the flavor — and .chezmoiignore keeps those
-- untracked, the split theme.toml describes for the flavor.

-- The plugin under plugins/relative-motions.yazi is vendored, not fetched; its
-- own header carries the reason and the one patch it needed. Worth knowing here
-- because the obvious alternative does not exist: init.lua and plugins are
-- *separate* Lua environments, so a shim set here is invisible to a plugin. A
-- probe measured it — a global assigned in this file reads back as nil inside a
-- plugin — which is why the fix had to go into the plugin's own source.

-- Vim-style counts: `3j`, `12k`, `10gg`, and `d`/`v`/`y`/`x` after a count.
-- The digits are bound in keymap.toml; everything after the first one is read
-- by the plugin itself, which is why `0` needs no binding and `10j` still works.
--
-- show_numbers = "relative_absolute" is the hybrid nvim already uses here
-- (options.lua sets both `number` and `relativenumber`), so a count means the
-- same thing in both: read it off the row you want, type it, go.
--
-- show_motion puts the pending count in the status bar — vim's `showcmd`, and
-- the only feedback that a count is half-typed.
--
-- enter_mode is left at "cache", which is yazi's own behaviour: entering a
-- directory returns to where you last were in it. The plugin's other modes
-- ("first", "cache_or_first") jump to the first subdirectory instead, which is
-- a change to ordinary navigation rather than to motions.
require("relative-motions"):setup({
	show_numbers = "relative_absolute",
	show_motion = true,
	enter_mode = "cache",
})

-- whoosh: bookmarks, with the vim marks model on `m` and `'` (keymap.toml has
-- the bindings and what they displaced).
--
-- `bookmarks_path` is the one option set here, and it is set because the
-- default is wrong for a tracked config: whoosh would write
-- `~/.config/yazi/bookmarks` — mutable state, rewritten on every bookmark, in
-- the directory chezmoi manages. That is the trap the gmuse section of
-- CLAUDE.md describes from the other side; gmuse gets this right by keeping its
-- state in $XDG_STATE_HOME, so whoosh is pointed there too. ~/.local/state/yazi
-- already exists — yazi puts its own log there — so nothing needs creating.
--
-- Everything else is left at its default on purpose. `jump_notify`,
-- `history_size = 10`, and the four path-truncation pairs are all fine as
-- shipped, and restating a default is the fault this repo keeps finding in
-- lua/plugins — a line that looks like a decision and is not one.
require("whoosh"):setup({
	bookmarks_path = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state"))
		.. "/yazi/bookmarks",
})
