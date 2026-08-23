-- Run just recipes from nvim, into the tmux console window.
--
-- Why this exists: just-lsp (plugins/lsp.lua) is analysis only — completion,
-- definitions, rename, diagnostics. LSP has no notion of "execute a task", so
-- running a recipe is ours to build.
--
-- Where output goes: bin/new-session opens every project as `1=nvim,
-- 2=console, 3=console` (windows, each with one pane — `base-index 1`), so a
-- recipe is sent to window 2 with `send-keys`, exactly as if it had been typed
-- there by hand. That keeps the output where it's always been: still on screen
-- after nvim is closed, scrollable with the usual tmux keys, and part of the
-- shell history. Focus stays in nvim — `M.pick({ focus = true })` is the
-- opt-in for watching a long run.
--
-- Two things make the send safe rather than a blind keystroke dump:
--   * the window must exist — `has-session -t sess:2` validates the *window*,
--     exiting 1 with "can't find window" when it's gone;
--   * its pane must be sitting at a shell prompt (`pane_current_command`), or
--     the keystrokes would be typed into whatever is running there — a pager, a
--     REPL, htop. A busy window is skipped for the next candidate, and if none
--     is free a new one is opened with `-d` (detached, so focus doesn't move).
--
-- The command sent is a plain `just <recipe>`, with no `cd` and no
-- `--justfile`: the console windows are opened with `-c "$DIR"` at the project
-- root and `dev` gives each project its own session, so the console's cwd and
-- the buffer's justfile are the same project by construction. Sending the bare
-- command is what makes the history line re-runnable by hand.

local M = {}

-- Console windows from bin/new-session, in preference order.
local CONSOLE_WINDOWS = { 2, 3 }

-- A pane running one of these is at a prompt and safe to type into.
local SHELLS = { zsh = true, bash = true, sh = true, fish = true }

---Run a tmux command.
---@param args string[]
---@return boolean ok, string stdout
local function tmux(args)
  local cmd = { "tmux" }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, { text = true }):wait()
  return res.code == 0, vim.trim(res.stdout or "")
end

---The session nvim is running in, or nil when we're not inside tmux.
---@return string|nil
local function session()
  if (vim.env.TMUX or "") == "" then
    return nil
  end
  -- Resolve via our own pane rather than the "current" client: with the session
  -- attached from two terminals, display-message without -t can answer for the
  -- other one.
  local args = { "display-message", "-p" }
  if (vim.env.TMUX_PANE or "") ~= "" then
    vim.list_extend(args, { "-t", vim.env.TMUX_PANE })
  end
  args[#args + 1] = "#{session_name}"
  local ok, out = tmux(args)
  return (ok and out ~= "") and out or nil
end

---First console window sitting at a prompt.
---@param sess string
---@return string|nil target
local function idle_console(sess)
  for _, idx in ipairs(CONSOLE_WINDOWS) do
    local target = ("%s:%d"):format(sess, idx)
    if tmux({ "has-session", "-t", target }) then
      local ok, cmd = tmux({ "display-message", "-p", "-t", target, "#{pane_current_command}" })
      if ok and SHELLS[cmd] then
        return target
      end
    end
  end
end

---Open a console window for this run. `-d` so focus stays in nvim.
---@param sess string
---@param cwd string
---@return string|nil target
local function new_console(sess, cwd)
  local ok, out = tmux({
    "new-window",
    "-d",
    "-t",
    sess,
    "-n",
    "console",
    "-c",
    cwd,
    "-P",
    "-F",
    "#{session_name}:#{window_index}",
  })
  return (ok and out ~= "") and out or nil
end

---Directory to resolve the justfile from: the buffer's own, so a recipe run
---from a file opened outside nvim's cwd still finds its project's justfile.
---@return string
local function context_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" and vim.bo.buftype == "" then
    return vim.fn.fnamemodify(name, ":p:h")
  end
  return vim.fn.getcwd()
end

---Every public recipe in the justfile above the current buffer.
---Module recipes are not included — `--dump` nests them under `modules`, and
---they need a `mod::recipe` path this doesn't build yet.
---@return table[]|nil items, string? err
function M.recipes()
  local dir = context_dir()
  local res = vim.system({ "just", "--dump", "--dump-format", "json" }, { cwd = dir, text = true }):wait()
  if res.code ~= 0 then
    local err = vim.trim(res.stderr or "")
    return nil, err ~= "" and err:gsub("^error: ", "") or "no justfile found"
  end

  -- luanil: `--dump` writes JSON null for an absent doc comment or parameter
  -- default, and the default decode turns those into vim.NIL — which is
  -- *truthy*, so `p.default == nil` would never fire and a required parameter
  -- would look like it had a default. Decode them as real nil instead.
  local ok, dump = pcall(vim.json.decode, res.stdout, { luanil = { object = true, array = true } })
  if not ok or type(dump) ~= "table" then
    return nil, "could not parse `just --dump` output"
  end

  local items = {}
  for name, recipe in pairs(dump.recipes or {}) do
    -- `private` covers both the `_leading-underscore` convention and the
    -- explicit [private] attribute, so one test hides both.
    if not recipe.private then
      items[#items + 1] = {
        text = name, -- the only field matched against
        name = name,
        doc = recipe.doc,
        params = recipe.parameters or {},
        is_default = name == dump.first,
        cwd = dir, -- where `just --show` has to run for the preview
      }
    end
  end
  table.sort(items, function(a, b)
    return a.name < b.name
  end)
  return items
end

---Preview the recipe's source. Snacks' default previewer wants `item.file`,
---and these items have none — without this it renders an "Item has no `file`"
---error and dumps the raw item. `just --show` gives the exact source including
---the doc comment, resolved through imports, so what you preview is what runs.
---Cached on the item: the previewer re-runs on every cursor move.
local function preview(ctx)
  local item = ctx.item
  if not item.source then
    local res = vim.system({ "just", "--show", item.name }, { cwd = item.cwd, text = true }):wait()
    item.source = res.code == 0 and vim.trim(res.stdout) or "# no source available"
  end
  ctx.preview:reset()
  ctx.preview:set_lines(vim.split(item.source, "\n"))
  ctx.preview:highlight({ ft = "just" })
end

---Format one recipe: name, then its parameters, then the doc comment.
local function format(item)
  local parts = { { item.name, "SnacksPickerLabel" } }
  for _, p in ipairs(item.params) do
    local sigil = (p.kind == "star" and "*") or (p.kind == "plus" and "+") or ""
    parts[#parts + 1] = { " " .. sigil .. p.name, "SnacksPickerComment" }
  end
  if item.doc and item.doc ~= "" then
    parts[#parts + 1] = { "  " .. item.doc, "SnacksPickerDir" }
  end
  return parts
end

---Prompt for a recipe's parameters, one input at a time.
---
---just takes arguments positionally, so a blank answer can't simply be dropped:
---skipping an early parameter would shift every later one into the wrong slot.
---Trailing blanks are trimmed (nothing follows them to shift), and a blank in
---the middle is backfilled with the parameter's default.
---@param params table[]
---@param done fun(args: string[])
local function prompt(params, done)
  local answers = {}

  local function ask(i)
    local p = params[i]
    if not p then
      -- Trim trailing blanks, then backfill any blank still holding a slot.
      while #answers > 0 and answers[#answers] == "" do
        answers[#answers] = nil
      end
      local args = {}
      for n, value in ipairs(answers) do
        if value == "" then
          local default = params[n].default
          if type(default) ~= "string" then
            vim.notify(
              ("just: `%s` has no simple default — supply a value or run it by hand"):format(params[n].name),
              vim.log.levels.WARN
            )
            return
          end
          value = default
        end
        local kind = params[n].kind
        if kind == "star" or kind == "plus" then
          -- Variadic parameters take a whole argument list, so split before
          -- escaping: one quoted blob would arrive as a single argument.
          for _, word in ipairs(vim.split(value, "%s+", { trimempty = true })) do
            args[#args + 1] = vim.fn.shellescape(word)
          end
        else
          -- A singular parameter is one argument no matter what's in it —
          -- splitting "my release" here would pass two positionals and just
          -- would reject the call.
          args[#args + 1] = vim.fn.shellescape(value)
        end
      end
      done(args)
      return
    end

    local hint = (type(p.default) == "string" and ("default: " .. p.default))
      or (p.kind == "star" and "optional, variadic")
      or (p.kind == "plus" and "required, variadic")
      or "required"
    vim.ui.input({ prompt = ("%s (%s): "):format(p.name, hint) }, function(input)
      if input == nil then
        return -- cancelled: abort the whole run
      end
      input = vim.trim(input)
      if input == "" and p.default == nil and p.kind ~= "star" then
        vim.notify(("just: `%s` is required"):format(p.name), vim.log.levels.WARN)
        return
      end
      answers[i] = input
      ask(i + 1)
    end)
  end

  ask(1)
end

---Send a fully-built command line to the console window.
---@param cmdline string
---@param opts? { focus?: boolean }
local function dispatch(cmdline, opts)
  opts = opts or {}
  M.last = cmdline

  local sess = session()
  if not sess then
    -- Outside tmux there's no console window to own the output.
    Snacks.terminal(cmdline, { win = { position = "float" }, interactive = true })
    return
  end

  local target = idle_console(sess) or new_console(sess, context_dir())
  if not target then
    vim.notify("just: could not find or open a console window", vim.log.levels.ERROR)
    return
  end

  -- C-u first: clear anything half-typed at the prompt, which would otherwise
  -- prefix the command.
  local ok = tmux({ "send-keys", "-t", target, "C-u", cmdline, "Enter" })
  if not ok then
    vim.notify("just: send-keys to " .. target .. " failed", vim.log.levels.ERROR)
    return
  end

  if opts.focus then
    tmux({ "select-window", "-t", target })
  else
    vim.notify(("%s → %s"):format(cmdline, target))
  end
end

---Run a recipe, prompting for parameters first.
---@param item table
---@param opts? { focus?: boolean }
function M.run(item, opts)
  local function go(args)
    local parts = { "just", item.name }
    vim.list_extend(parts, args)
    dispatch(table.concat(parts, " "), opts)
  end

  if #item.params > 0 then
    prompt(item.params, go)
  else
    go({})
  end
end

---Pick a recipe, then run it.
---@param opts? { focus?: boolean }
function M.pick(opts)
  local items, err = M.recipes()
  if not items then
    vim.notify("just: " .. err, vim.log.levels.WARN)
    return
  end
  if #items == 0 then
    vim.notify("just: no public recipes in this justfile", vim.log.levels.INFO)
    return
  end

  Snacks.picker.pick({
    source = "just_recipes",
    title = "Just Recipes",
    items = items,
    format = format,
    preview = preview,
    sort = { fields = { "score:desc", "idx" } },
    confirm = function(picker, item)
      picker:close()
      if item then
        M.run(item, opts)
      end
    end,
  })
end

---Run a recipe by name — the <leader>jt / <leader>jb style shortcuts.
---@param name string
---@param opts? { focus?: boolean }
function M.run_named(name, opts)
  local items, err = M.recipes()
  if not items then
    vim.notify("just: " .. err, vim.log.levels.WARN)
    return
  end
  for _, item in ipairs(items) do
    if item.name == name then
      M.run(item, opts)
      return
    end
  end
  vim.notify(("just: no `%s` recipe in this justfile"):format(name), vim.log.levels.WARN)
end

---Run the default recipe (bare `just`).
---@param opts? { focus?: boolean }
function M.run_default(opts)
  dispatch("just", opts)
end

---Re-send the last command this module dispatched.
---@param opts? { focus?: boolean }
function M.rerun(opts)
  if not M.last then
    vim.notify("just: nothing run yet", vim.log.levels.INFO)
    return
  end
  dispatch(M.last, opts)
end

return M
