-- ── Markdown task list checkboxes ────────────────────────────────────────────
--
-- render-markdown.nvim draws `[ ]` / `[x]` as glyphs but is purely a decorator:
-- it has no commands and no mappings, so nothing in this config could actually
-- tick a box. zk is links-and-notes only, and todo-comments runs with
-- comments_only = true, so it ignores markdown prose by design. Hence this.
--
-- One entry point, `toggle()`, bound to <CR> and <leader>mx in both normal and
-- visual mode (see config/autocmds.lua). It is deliberately two behaviours in
-- one key, decided per invocation rather than per line:
--
--   * any line in range that isn't a checkbox yet -> make them all checkboxes.
--     Typing a list as plain `- foo` bullets and then running <CR> down the
--     column is faster than typing `[ ] ` seven times.
--   * everything already a checkbox -> flip. Mixed states check the lot;
--     all-checked unchecks. So a range never lands half-toggled, which is what
--     you want when ticking off a whole sub-list at once.
--
-- Nothing here reflows or reformats: a line keeps its own indent and marker, so
-- ordered lists, nested lists and prettier's output all survive a toggle.

local M = {}

-- A list line is an indent, a marker, and the rest. Both bullet flavours are
-- accepted because prettier rewrites `*` to `-` but hand-typed notes have both,
-- and ordered markers take either `.` or `)`.
local BULLET = "^(%s*)([-*+])%s+(.*)$"
local ORDERED = "^(%s*)(%d+[%.%)])%s+(.*)$"

-- ` ` is unchecked; any other character counts as done when deciding whether a
-- range is finished. Testing against " " rather than for "x" is what keeps
-- render-markdown's custom states (`[-]` cancelled, `[>]` deferred) from reading
-- as open items — a range containing one won't be force-ticked, and ]x won't
-- stop on it. Note the reset direction does normalise: unchecking a range whose
-- states are all non-space rewrites `[-]` and `[>]` to `[ ]` along with the
-- `[x]`s, since "clear this range" is the only sensible reading of that press.
local UNCHECKED = " "
local CHECKED = "x"

---Split a line into its list parts, or nil if it isn't a list item.
---@param line string
---@return table|nil
local function parse(line)
  local indent, marker, rest = line:match(BULLET)
  if not indent then
    indent, marker, rest = line:match(ORDERED)
  end
  if not indent then
    return nil
  end

  -- A checkbox is `[c]` followed by a space or nothing at all. The trailing
  -- check matters: without it `- [label](url) text` parses as a checkbox in
  -- state "l", and toggling would eat the link. A `(` after the `]` fails the
  -- separator test, so links fall through as ordinary text.
  local state, sep, text = rest:match("^%[([^%]])%](%s?)(.*)$")
  if state and (sep == " " or (sep == "" and text == "")) then
    return { indent = indent, marker = marker, state = state, text = text }
  end
  return { indent = indent, marker = marker, state = nil, text = rest }
end

---Render list parts back to a line.
local function render(p)
  local box = p.state and ("[" .. p.state .. "] ") or ""
  local body = box .. p.text
  return p.indent .. p.marker .. " " .. (body:gsub("%s+$", ""))
end

---Turn a line into an unchecked checkbox, whatever it started as.
---A bare prose line becomes a bullet too — `foo` -> `- [ ] foo` — so you can
---write a paragraph of items and convert the block in one visual-mode press.
local function to_checkbox(line)
  if line:match("^%s*$") then
    return line -- blank lines stay blank; a range toggle shouldn't litter them
  end
  local p = parse(line)
  if p then
    p.state = p.state or UNCHECKED
    return render(p)
  end
  local indent, text = line:match("^(%s*)(.*)$")
  return indent .. "- [" .. UNCHECKED .. "] " .. text
end

---The 0-indexed, end-exclusive line range this invocation applies to.
---Reads the visual selection directly via the `v` mark rather than `'<`/`'>`,
---so the mapping can stay a plain `x` map instead of routing through a
---`:<C-u>` user command to get the marks written.
---@return integer, integer
local function range()
  local mode = vim.api.nvim_get_mode().mode
  if mode:match("^[vV\22]") then
    local a = vim.fn.line("v")
    local b = vim.fn.line(".")
    if a > b then
      a, b = b, a
    end
    return a - 1, b
  end
  local l = vim.fn.line(".")
  return l - 1, l
end

---Toggle the checkbox(es) in the current line or visual selection.
function M.toggle()
  local first, last = range()
  local lines = vim.api.nvim_buf_get_lines(0, first, last, false)

  -- Decide once for the whole range, so a multi-line toggle is all-or-nothing.
  local has_plain, has_unchecked = false, false
  for _, line in ipairs(lines) do
    if not line:match("^%s*$") then
      local p = parse(line)
      if not p or not p.state then
        has_plain = true
      elseif p.state == UNCHECKED then
        has_unchecked = true
      end
    end
  end

  local out = {}
  for _, line in ipairs(lines) do
    if has_plain then
      table.insert(out, to_checkbox(line))
    else
      local p = parse(line)
      if p and p.state then
        p.state = has_unchecked and CHECKED or UNCHECKED
        table.insert(out, render(p))
      else
        table.insert(out, line) -- blank line inside the selection
      end
    end
  end

  vim.api.nvim_buf_set_lines(0, first, last, false, out)

  -- Leave visual mode: the selection's line range has just been rewritten, so
  -- keeping it highlighted only invites a second toggle on a stale idea of
  -- what's selected.
  if vim.api.nvim_get_mode().mode:match("^[vV\22]") then
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
  end
end

-- ]x / [x — jump between open items. What makes a long list navigable: you want
-- the next thing still to do, not the next line.
-- Long-bracket level 1: the pattern ends in `\]`, so a plain [[...]] would
-- close early on the `]]` that forms.
local OPEN = [==[\v^\s*([-*+]|\d+[.)])\s+\[ \]]==]

---@param backwards boolean
function M.next_unchecked(backwards)
  vim.fn.search(OPEN, backwards and "bw" or "w")
end

return M
