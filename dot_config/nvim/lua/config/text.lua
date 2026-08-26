-- ── Text folding for picker haystacks ────────────────────────────────────────
--
-- Snacks' matcher does ignorecase but no accent folding, so a picker entry
-- whose name carries a diacritic can only be reached by typing the diacritic —
-- which is the difficulty, not the solution. Both pickers that show names out
-- of the notebook need the same trick, so it lives here rather than in either
-- of them: config/rules_lookup.lua (spell and creature names) and
-- config/markdown_outline.lua (headings, four of which are accented in the
-- campaign corpus: "Déjà Vu", "Ixamè's Eye", "Kimanéz Luminescent Toadstool",
-- "Niyaháat").

local M = {}

---Accent-folded copy, for matching only: "Déjà Vu" -> "Deja Vu". Snacks' matcher
---does ignorecase but no folding, so without this the picker cannot be reached
---by typing "deja" — and typing the accent is the whole difficulty.
---
---Both cases are listed because Lua has no UTF-8-aware upper/lower: s:lower()
---works a byte at a time and leaves "É" alone, so one half cannot be derived
---from the other. Callers can pass text straight from a heading
---(goto_rule_visual), so the uppercase half is not hypothetical.
---
---Only the characters this corpus plausibly contains are mapped; the pattern
---matches whole UTF-8 sequences, so an unmapped one passes through untouched.
-- A grid reads as a character table; one pair per line does not.
-- stylua: ignore
local FOLD = {
  ["à"] = "a", ["á"] = "a", ["â"] = "a", ["ä"] = "a", ["ã"] = "a", ["å"] = "a",
  ["è"] = "e", ["é"] = "e", ["ê"] = "e", ["ë"] = "e",
  ["ì"] = "i", ["í"] = "i", ["î"] = "i", ["ï"] = "i",
  ["ò"] = "o", ["ó"] = "o", ["ô"] = "o", ["ö"] = "o", ["õ"] = "o",
  ["ù"] = "u", ["ú"] = "u", ["û"] = "u", ["ü"] = "u",
  ["ñ"] = "n", ["ç"] = "c", ["ý"] = "y",
  ["À"] = "A", ["Á"] = "A", ["Â"] = "A", ["Ä"] = "A", ["Ã"] = "A", ["Å"] = "A",
  ["È"] = "E", ["É"] = "E", ["Ê"] = "E", ["Ë"] = "E",
  ["Ì"] = "I", ["Í"] = "I", ["Î"] = "I", ["Ï"] = "I",
  ["Ò"] = "O", ["Ó"] = "O", ["Ô"] = "O", ["Ö"] = "O", ["Õ"] = "O",
  ["Ù"] = "U", ["Ú"] = "U", ["Û"] = "U", ["Ü"] = "U",
  ["Ñ"] = "N", ["Ç"] = "C", ["Ý"] = "Y",
}
---@param s string
---@return string
function M.fold(s)
  local folded = s:gsub("[\194-\244][\128-\191]*", function(c)
    return FOLD[c] or c
  end)
  return folded
end

---Picker items carry `label` (shown) and `text` (matched). They differ only for
---accented names, where the folded copy rides along in the haystack so both
---"déjà" and "deja" find the entry. Everywhere else they are the same string.
---@param label string
---@return string
function M.haystack(label)
  local folded = M.fold(label)
  return folded ~= label and (label .. " " .. folded) or label
end

return M
