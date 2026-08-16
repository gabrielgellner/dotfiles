-- ── Markdown outline picker ──────────────────────────────────────────────────
--
-- Why this exists: <leader>fs is Snacks.picker.lsp_symbols(), which needs an
-- LSP that answers textDocument/documentSymbol. In markdown buffers nothing
-- does — zk's LSP registers completion, links, definition, references, hover,
-- code actions and diagnostics, but no documentSymbol handler. Snacks' own
-- treesitter picker is no help either: it drives off `locals` queries and
-- markdown ships none.
--
-- So build the outline straight from the markdown parse tree. Headings become
-- picker items, indented by level, fuzzy-filterable on the heading text alone.
-- Because it reads the syntax tree rather than the raw lines, `#` inside fenced
-- code blocks is correctly ignored, and setext headings (=== / ---) are picked
-- up alongside the atx ones.

local M = {}

local QUERY = [[
  (atx_heading) @heading
  (setext_heading) @heading
]]

---Level of a heading node, from its marker/underline child.
---@param node TSNode
---@return integer
local function heading_level(node)
  for child in node:iter_children() do
    local level = child:type():match("^atx_h(%d)_marker$") or child:type():match("^setext_h(%d)_underline$")
    if level then
      return tonumber(level)
    end
  end
  return 1
end

---Collect headings in document order.
---@param buf integer
---@return table[]|nil items, string? err
function M.headings(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
  if not ok or not parser then
    return nil, "no markdown treesitter parser for this buffer"
  end
  parser:parse(true)

  local ok_query, query = pcall(vim.treesitter.query.parse, "markdown", QUERY)
  if not ok_query then
    return nil, "could not parse the heading query"
  end

  local items = {}
  for _, tree in ipairs(parser:trees()) do
    for _, node in query:iter_captures(tree:root(), buf) do
      local srow, scol, erow, ecol = node:range()
      -- Take the node's own text, not the raw buffer line: for a heading
      -- nested in a blockquote the `> ` prefix belongs to the enclosing
      -- block_quote node, so this drops it for free. Title is the first line;
      -- strip the atx markers (leading, and the optional closing run).
      local raw = vim.treesitter.get_node_text(node, buf) or ""
      local text = (raw:match("^[^\n]*") or ""):gsub("^%s*#+%s*", ""):gsub("%s*#+%s*$", ""):gsub("%s+$", "")
      if text ~= "" then
        items[#items + 1] = {
          text = text,
          name = text,
          level = heading_level(node),
          buf = buf,
          pos = { srow + 1, scol },
          end_pos = { erow + 1, ecol },
        }
      end
    end
  end

  table.sort(items, function(a, b)
    return a.pos[1] < b.pos[1]
  end)

  return items
end

---Format one item: indent by level, then a dimmed `##` marker, then the title.
---Only `item.text` is matched against, so the indent never affects filtering.
local function format(item)
  local level = item.level or 1
  return {
    { string.rep("  ", level - 1), "SnacksPickerDir" },
    { string.rep("#", level) .. " ", "@markup.heading." .. level .. ".markdown" },
    { item.text, "SnacksPickerLabel" },
  }
end

---Open the outline picker for the current buffer.
function M.pick()
  local buf = vim.api.nvim_get_current_buf()
  local items, err = M.headings(buf)
  if not items then
    vim.notify("Markdown outline: " .. err, vim.log.levels.WARN)
    return
  end
  if #items == 0 then
    vim.notify("Markdown outline: no headings in this buffer", vim.log.levels.INFO)
    return
  end

  Snacks.picker.pick({
    source = "markdown_outline",
    title = "Markdown Outline",
    items = items,
    format = format,
    -- Empty prompt keeps document order (matcher.sort_empty is false by
    -- default); once you type, best match wins with document order as the
    -- tiebreaker. Same idiom snacks' own sources use.
    sort = { fields = { "score:desc", "idx" } },
  })
end

---<leader>fs entry point: outline in markdown, LSP symbols everywhere else.
function M.symbols()
  if vim.bo.filetype:match("markdown") then
    M.pick()
  else
    Snacks.picker.lsp_symbols()
  end
end

return M
