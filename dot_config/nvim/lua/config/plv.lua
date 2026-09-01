-- plv - a table viewer for csv/tsv/txt/parquet, opened in a float.
--
-- plv is a personal binary (`cargo install`, not a package), so two things are
-- true of it that are not true of the other tools here: it may be absent on a
-- machine, and it may be *broken* on the machine where it is being worked on.
-- Both are handled rather than assumed away — see `available()` and the
-- TermClose watcher in `open()`.
--
-- Its CLI is the whole surface: `plv [FILE]`, no flags (0.4.1).
--
-- ── Which files go where ─────────────────────────────────────────────────────
-- The two halves of the handoff are decided by what Neovim can honestly offer,
-- not by what plv can open:
--
--   csv, tsv, tab, txt   Neovim is genuinely useful — editing, `:g`, grep,
--                        LSP-less but writable. It stays the default, and plv
--                        is a keystroke away (<leader>tt) when you want to
--                        *read* the table rather than edit the text.
--
--   parquet, ducklake    Neovim cannot show these at all, and is not merely
--                        useless: opening sample.parquet and pressing `:w`
--                        grew it from 1076 to 1077 bytes — a trailing newline
--                        Neovim adds because 'binary' is off — after which
--                        pyarrow reported "Could not open Parquet input
--                        source". Measured, and the reason these are
--                        intercepted before Neovim ever reads the bytes.
--
-- So: text formats hand off on request, binary formats hand off on open, and
-- the binary ones are protected from Neovim whether or not plv is there.

local M = {}

-- Extensions plv accepts, from its own --help. Kept as a set rather than a
-- pattern so the two tables below can disagree: everything here is viewable,
-- only BINARY is unsafe to let Neovim read.
local VIEWABLE = {
  csv = true,
  tsv = true,
  tab = true,
  txt = true,
  parquet = true,
  ducklake = true,
}

-- Formats Neovim damages rather than merely fails to render. See the header.
local BINARY = {
  parquet = true,
  ducklake = true,
}

local function ext(path)
  return vim.fn.fnamemodify(path, ":e"):lower()
end

---Is plv on PATH right now?
---
---Deliberately not cached. Every other executable check in this config could
---be, but plv is the one binary here that gets rebuilt while Neovim is open —
---a `cargo install` mid-session should take effect without a restart, and a
---broken build that removes it should stop this claiming otherwise. One PATH
---search per keystroke is not a cost worth optimising against that.
function M.available()
  return vim.fn.executable("plv") == 1
end

---Report plv's absence once, in the same shape everywhere.
local function notify_missing(context)
  vim.notify(
    ("plv is not on PATH%s\ncargo install plv, or check ~/.cargo/bin is on PATH"):format(
      context and (" — " .. context) or ""
    ),
    vim.log.levels.WARN
  )
end

---Open `path` in plv, in a float.
---
---Returns true when plv was launched, false when it was not — the parquet
---autocmd uses that to decide what to leave in the placeholder buffer.
function M.open(path)
  if not path or path == "" then
    vim.notify("plv: no file to open", vim.log.levels.WARN)
    return false
  end

  path = vim.fn.fnamemodify(path, ":p")
  if vim.fn.filereadable(path) ~= 1 then
    vim.notify(("plv: not readable — %s"):format(path), vim.log.levels.WARN)
    return false
  end

  if not M.available() then
    notify_missing(("cannot open %s"):format(vim.fn.fnamemodify(path, ":t")))
    return false
  end

  -- interactive defaults are what is wanted here, and are the opposite of what
  -- config/just.lua needs: plv is a TUI you quit with `q`, so start_insert,
  -- auto_insert and auto_close together mean it opens focused and the float
  -- disappears when you leave it. just.lua turns them off because a *task's*
  -- output has to survive the process exiting; a viewer's does not.
  local term = Snacks.terminal({ "plv", path }, {
    win = {
      position = "float",
      width = 0.9,
      height = 0.9,
      -- `border` is load-bearing for the title, not decoration. A snacks
      -- terminal float defaults to a square border that renders no title at
      -- all — measured, the same title string shows with "rounded" and is
      -- silently dropped without it. The title is what says which file you are
      -- looking at, which matters once two of these are open.
      border = "rounded",
      title = (" plv — %s "):format(vim.fn.fnamemodify(path, ":t")),
      title_pos = "center",
    },
  })

  -- A broken plv needs no handling here, which is worth writing down because
  -- the obvious thing is to add a TermClose watcher and that would fire a
  -- second, duplicate notification. snacks' own auto_close already checks
  -- vim.v.event.status: non-zero and it notifies the code *and skips the
  -- close*, so the float stays up with stderr in it. Measured with a stub plv
  -- that prints to stderr and exits 3 — the float stayed open reading
  -- "boom: bad build" and "[Process exited 3]", which is the whole diagnosis
  -- without leaving Neovim. A clean quit closes it as usual.
  return term ~= nil
end

---The file this keystroke means: the entry under the cursor in an oil buffer,
---otherwise the file in the current buffer.
---
---oil is included because browsing a directory of data files is exactly when
---you want a viewer, and oil is where that browsing happens (see config/files.lua).
local function current_path()
  if vim.bo.filetype == "oil" then
    local ok, oil = pcall(require, "oil")
    if ok then
      local entry = oil.get_cursor_entry()
      local dir = oil.get_current_dir()
      if entry and dir and entry.type == "file" then
        return dir .. entry.name
      end
      return nil
    end
  end

  local name = vim.api.nvim_buf_get_name(0)
  return name ~= "" and name or nil
end

---<leader>tt: view the current file in plv.
function M.open_current()
  local path = current_path()
  if not path then
    vim.notify("plv: this buffer has no file", vim.log.levels.WARN)
    return
  end

  -- A soft warning rather than a refusal. plv reads by extension, so this is
  -- the check it would make itself, but being wrong about the list should not
  -- stop you opening something — a .data that is really a CSV is your call.
  if not VIEWABLE[ext(path)] then
    vim.notify(
      ("plv: %s is not a format it opens (csv, tsv, tab, txt, parquet, ducklake) — trying anyway"):format(
        vim.fn.fnamemodify(path, ":t")
      ),
      vim.log.levels.INFO
    )
  end

  M.open(path)
end

---Called from the BufReadCmd autocmd in config/autocmds.lua.
---
---BufReadCmd rather than BufReadPost: it *replaces* the read, so the bytes
---never reach a buffer and the corruption described in the header cannot
---happen. The buffer is left as a one-line placeholder saying where the file
---went, and is made unwritable three ways over: nomodifiable, readonly, and
---buftype=nofile. Measured on sample.parquet — `:w` reports "E21: Cannot make
---changes, 'modifiable' is off" (nomodifiable is checked first, so E21 rather
---than nofile's E382), the file's md5 is unchanged and pyarrow still reads it.
function M.open_binary(buf, file)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  local name = vim.fn.fnamemodify(file, ":t")
  local line
  if M.open(file) then
    line = ("%s — opened in plv (a %s is not text; Neovim would corrupt it on :w)"):format(name, ext(file))
  else
    -- No plv, so there is nothing to show. Saying so beats an empty buffer,
    -- and the placeholder still protects the file, which is the half of this
    -- that does not depend on plv existing at all.
    line = ("%s — not opened. plv is not on PATH, and nothing else here can read a %s."):format(name, ext(file))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { line })
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
end

M.BINARY = BINARY

return M
