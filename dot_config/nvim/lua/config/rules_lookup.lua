-- ── Jump to a rules file from a bare name under the cursor ───────────────────
--
-- zk.lua already resolves *typed links* — [Flame Strike](spell://flame-strike)
-- — including the legacy→remaster alias hop. But generated stat blocks under
-- campaign/rules/creatures/ contain no links at all: Urevian's spell list is
-- plain prose ("dimension door (at will), private sanctum (at will)"). Those
-- files also sit outside the parts of the notebook the zk LSP serves, so `gd`
-- has nothing to work with there.
--
-- This maps the *text* under the cursor to a rules file, doing the same alias
-- resolution: "Dimension Door" -> dimension-door -> (alias) -> translocate.md.
--
-- Multi-word names are the whole difficulty. Rather than guess a word count,
-- try every span of 1..4 words containing the cursor, longest first, and take
-- the first that resolves to a real file. "Private Sanctum" beats "Sanctum";
-- "Wall of Force" beats "Force".

local M = {}

local text = require("config.text")

-- Searched in order, and the order is precedence: resolve() returns the first
-- hit, so a slug living in two directories resolves to the earlier one. Spells
-- lead because that is the common case in stat blocks.
--
-- The three trailing entries were added later and go last deliberately: gm-core
-- shares influence, light, research and treat-wounds with actions and spells,
-- and putting it after them keeps those resolving where they always did.
-- hazards and player-core collide with nothing.
--
-- abilities goes last for the same reason, and was missing entirely until the
-- audit went looking: 55 files, and their names are exactly what this module
-- exists to catch — "aquatic ambush" appears as bare prose in four creature
-- stat blocks, "All-Around Vision" inside Belcorra's Effect line. Six of the 55
-- slugs already live in an earlier directory (change-shape, reactive-strike and
-- retributive-strike in actions; darkvision, telepathy and tremorsense in
-- spells), so trailing placement leaves every one of those resolving where it
-- did and reaches the other 49.
--
-- Not everything under campaign/rules/ is here. feats (5408) and items (5466)
-- dwarf the rest, and pulling them in would quadruple the corpus this globs and
-- bury the picker in feats. The cost is that they cannot be reached at all —
-- including a few item files with accents in their names. skills/ is empty, so
-- listing it would buy nothing.
local LOOKUP_ORDER =
  { "spells", "conditions", "actions", "creatures", "hazards", "gm-core", "player-core", "abilities" }
local MAX_WORDS = 4

---Repo root = the directory holding spell_aliases.toml, found upward from buf.
---@return string|nil
local function repo_root(bufnr)
  local from = vim.api.nvim_buf_get_name(bufnr or 0)
  if from == "" then
    from = vim.uv.cwd() or ""
  end
  local hit = vim.fs.find("spell_aliases.toml", { upward = true, path = vim.fs.dirname(from) })[1]
  return hit and vim.fs.dirname(hit) or nil
end

---Cache stamp for a path: its mtime, or "-" if it does not exist. Comparing
---these is what lets the caches below survive a long nvim session without going
---stale — this notebook is edited in the same session that reads it, so
---"parsed once per root, forever" meant a new rules file stayed invisible until
---a restart.
---@param path string
---@return string
local function stamp(path)
  local st = vim.uv.fs_stat(path)
  return st and (st.mtime.sec .. "." .. st.mtime.nsec) or "-"
end

local alias_cache = {}
---Legacy slug -> remaster slug. Same file zk.lua reads; reparsed when it changes.
local function aliases(root)
  local now = stamp(root .. "/spell_aliases.toml")
  local hit = alias_cache[root]
  if hit and hit.stamp == now then
    return hit.map
  end
  local map = {}
  local f = io.open(root .. "/spell_aliases.toml", "r")
  if f then
    for line in f:lines() do
      local legacy, remaster = line:match('^%s*"([^"]+)"%s*=%s*"([^"]+)"')
      if legacy then
        map[legacy] = remaster
      end
    end
    f:close()
  end
  alias_cache[root] = { stamp = now, map = map }
  return map
end

---"Private Sanctum!" -> "private-sanctum". Apostrophes vanish rather than
---becoming separators, so "Mariner's Curse" -> "mariners-curse".
---
---The punctuation class spares bytes 128-255 so UTF-8 survives: %w is ASCII
---only, so "[^%w]+" treated every byte of an accented character as punctuation
---and "Déjà Vu" came out "d-j-vu", which matches no file. Filenames keep their
---accents (déjà-vu.md), so the slug has to as well.
---
---vim.fn.tolower rather than s:lower() for the same reason: Lua lowercases a
---byte at a time, which under some locales rewrites the lead byte of a UTF-8
---sequence and leaves an invalid one behind — "DÉJÀ VU" came out with a broken
---byte where the À had been. vim.fn.tolower knows about characters.
---
---The apostrophe class is bytewise too — it holds ' plus the three bytes of
---U+2019 individually rather than the character — but that is harmless here:
---any byte it could strip from another character is one the class below would
---replace anyway.
---@param s string
---@return string
function M.slugify(s)
  local lowered = vim.fn.tolower(s)
  return (lowered:gsub("['\u{2019}]", ""):gsub("[^%w\128-\255]+", "-"):gsub("^%-+", ""):gsub("%-+$", ""))
end

---Resolve a display name to a rules file path, applying the spell alias map.
---@return string|nil path, string? kind
function M.resolve(name, root)
  local slug = M.slugify(name)
  if slug == "" then
    return nil
  end
  for _, dir in ipairs(LOOKUP_ORDER) do
    local path = ("%s/campaign/rules/%s/%s.md"):format(root, dir, slug)
    if vim.fn.filereadable(path) == 1 then
      return path, dir
    end
    if dir == "spells" then
      local alias = aliases(root)[slug]
      if alias then
        path = ("%s/campaign/rules/spells/%s.md"):format(root, alias)
        if vim.fn.filereadable(path) == 1 then
          return path, "spells (via alias)"
        end
      end
    end
  end
  return nil
end

---Words on `line` as {text, s, e} with 1-based inclusive byte columns.
local function words(line)
  local out, init = {}, 1
  while true do
    local s, e = line:find("[%w'\u{2019}]+", init)
    if not s then
      return out
    end
    out[#out + 1] = { text = line:sub(s, e), s = s, e = e }
    init = e + 1
  end
end

---Candidate names under the cursor, longest span first.
---@return string[]
function M.candidates(line, col)
  local ws = words(line)
  local cur
  for i, w in ipairs(ws) do
    if col >= w.s and col <= w.e then
      cur = i
      break
    end
  end
  if not cur then
    return {}
  end

  local spans = {}
  for len = MAX_WORDS, 1, -1 do
    -- every window of `len` words that contains the cursor word
    for start = math.max(1, cur - len + 1), math.min(cur, #ws - len + 1) do
      local finish = start + len - 1
      if finish <= #ws then
        spans[#spans + 1] = line:sub(ws[start].s, ws[finish].e)
      end
    end
  end
  return spans
end

---"wall-of-force" -> "Wall of Force". Small words stay lowercase so the list
---reads like the book rather than a Title Cased slug dump.
local MINOR = { of = true, the = true, a = true, an = true, to = true, ["and"] = true, in_ = true }
local function titleize(slug)
  local out = {}
  for word in slug:gmatch("[^%-]+") do
    out[#out + 1] = (#out > 0 and MINOR[word]) and word or (word:sub(1, 1):upper() .. word:sub(2))
  end
  return table.concat(out, " ")
end

---Stamp covering every input to corpus(): each searched directory, plus the
---alias file whose entries it folds in. A directory's mtime moves when a file
---is added, removed or renamed, which is precisely what corpus() reads — it
---takes names, never contents, so an edit that leaves the filename alone
---correctly does not invalidate anything.
---@param root string
---@return string
local function corpus_stamp(root)
  local parts = { stamp(root .. "/spell_aliases.toml") }
  for _, dir in ipairs(LOOKUP_ORDER) do
    parts[#parts + 1] = stamp(("%s/campaign/rules/%s"):format(root, dir))
  end
  return table.concat(parts, "|")
end

---Every rules file, as picker items. ~2.6k files, globbed once and then only
---again when one of the directories changes: eight fs_stat calls per pick.
local corpus_cache = {}
local function corpus(root)
  local now = corpus_stamp(root)
  local hit = corpus_cache[root]
  if hit and hit.stamp == now then
    return hit.items
  end
  local items = {}
  for _, dir in ipairs(LOOKUP_ORDER) do
    local base = ("%s/campaign/rules/%s"):format(root, dir)
    for _, path in ipairs(vim.fn.globpath(base, "*.md", false, true)) do
      local slug = vim.fn.fnamemodify(path, ":t:r")
      local label = titleize(slug)
      items[#items + 1] =
        { text = text.haystack(label), label = label, file = path, kind = dir:gsub("s$", ""), slug = slug }
    end
  end
  -- Legacy names as their own entries, so searching "Dimension Door" finds the
  -- remaster file even though no such filename exists.
  for legacy, remaster in pairs(aliases(root)) do
    local path = ("%s/campaign/rules/spells/%s.md"):format(root, remaster)
    if vim.fn.filereadable(path) == 1 then
      items[#items + 1] = {
        text = text.haystack(titleize(legacy)),
        label = titleize(legacy),
        file = path,
        kind = "spell (legacy)",
        slug = legacy,
      }
    end
  end
  table.sort(items, function(a, b)
    return a.label < b.label
  end)
  corpus_cache[root] = { stamp = now, items = items }
  return items
end

---Fuzzy picker over all rules files, seeded with every span under the cursor
---that actually resolves — so with the cursor in "wall of force" you get both
---"Wall of Force" and "Force" and pick, instead of the longest span winning
---silently. Typing searches the whole corpus.
function M.pick()
  local root = repo_root(0)
  if not root then
    vim.notify("rules lookup: no spell_aliases.toml above this file", vim.log.levels.WARN)
    return
  end

  local under = {}
  local seen = {}
  for _, name in ipairs(M.candidates(vim.api.nvim_get_current_line(), vim.fn.col("."))) do
    local path, kind = M.resolve(name, root)
    if path and not seen[path] then
      seen[path] = true
      under[#under + 1] =
        { text = text.haystack(name), label = name, file = path, kind = kind:gsub("s$", ""), cursor = true }
    end
  end

  local items = {}
  vim.list_extend(items, under)
  for _, item in ipairs(corpus(root)) do
    if not seen[item.file] then
      items[#items + 1] = item
    end
  end

  Snacks.picker.pick({
    source = "rules_lookup",
    title = #under > 0 and ("Rules — under cursor: " .. under[1].label) or "Rules",
    items = items,
    format = function(item)
      local ret = {
        { item.cursor and "● " or "  ", "SnacksPickerSelected" },
        { item.label, "SnacksPickerLabel" },
        { " ", "Normal" },
      }
      ret[#ret + 1] = { item.kind, "SnacksPickerComment" }
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd.edit(vim.fn.fnameescape(item.file))
        vim.fn.cursor(1, 1)
      end
    end,
    -- Empty prompt keeps the cursor matches on top; typing scores across all.
    sort = { fields = { "score:desc", "idx" } },
  })
end

---Jump to the rules file for the name under the cursor.
function M.goto_rule()
  local root = repo_root(0)
  if not root then
    vim.notify("rules lookup: no spell_aliases.toml above this file", vim.log.levels.WARN)
    return
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local tried = M.candidates(line, col)
  if #tried == 0 then
    vim.notify("rules lookup: no word under the cursor", vim.log.levels.WARN)
    return
  end

  for _, name in ipairs(tried) do
    local path, kind = M.resolve(name, root)
    if path then
      vim.cmd.edit(vim.fn.fnameescape(path))
      vim.fn.cursor(1, 1)
      vim.notify(("%s → %s"):format(name, kind))
      return
    end
  end
  vim.notify("rules lookup: nothing found for '" .. tried[1] .. "'", vim.log.levels.WARN)
end

---Same, for an explicit visual selection (handles names longer than MAX_WORDS).
function M.goto_rule_visual()
  local root = repo_root(0)
  if not root then
    return
  end
  local a, b = vim.fn.getpos("v"), vim.fn.getpos(".")
  if a[2] ~= b[2] then
    vim.notify("rules lookup: select within one line", vim.log.levels.WARN)
    return
  end
  local s, e = math.min(a[3], b[3]), math.max(a[3], b[3])
  local name = vim.api.nvim_get_current_line():sub(s, e)
  local path, kind = M.resolve(name, root)
  if path then
    vim.cmd.edit(vim.fn.fnameescape(path))
    vim.fn.cursor(1, 1)
    vim.notify(("%s → %s"):format(name, kind))
  else
    vim.notify("rules lookup: nothing found for '" .. name .. "'", vim.log.levels.WARN)
  end
end

return M
