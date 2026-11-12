-- Run just recipes from nvim, into the tmux console window (or kitty's, when
-- kitty is the multiplexer; see in_kitty below).
--
-- Why this exists: just-lsp (plugins/lsp.lua) is analysis only — completion,
-- definitions, rename, diagnostics. LSP has no notion of "execute a task", so
-- running a recipe is ours to build.
--
-- Where output goes: bin/new-session opens every project as `1=nvim,
-- 2=console` (windows, each with one pane — `base-index 1`), so a recipe is
-- sent to the first window named `console` with `send-keys`, exactly as if it
-- had been typed there by hand. That keeps the output where it's always been:
-- still on screen after nvim is closed, scrollable with the usual tmux keys,
-- and part of the shell history. Focus stays in nvim —
-- `M.pick({ focus = true })` is the opt-in for watching a long run.
--
-- Two things make the send safe rather than a blind keystroke dump:
--   * the window must exist — consoles are looked up by name each time, so
--     one that has been closed is simply not a candidate;
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

-- The name bin/new-session and new_console below give a console window.
-- Consoles are found by it rather than by index: Claude's window sits among
-- them (config/claude_tmux.lua), and an index would count it.
local CONSOLE_NAME = "console"

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

---kitty as the multiplexer (mux.conf). Same rule as ~/bin/dev-mux, minus its
---DEV_MUX override, which only matters when choosing what to launch.
---@return boolean
local function in_kitty()
  return (vim.env.TMUX or "") == "" and (vim.env.KITTY_WINDOW_ID or "") ~= "" and (vim.env.KITTY_LISTEN_ON or "") ~= ""
end

---Run a `kitten @` remote-control command.
---@param args string[]
---@return boolean ok, string stdout
local function kitten(args)
  local cmd = { "kitten", "@" }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, { text = true }):wait()
  return res.code == 0, vim.trim(res.stdout or "")
end

---kitty's console windows in this session, in tab order: the windows
---new-session tagged `dev_role=console`. `session:.` is the active session,
---which is this nvim's whenever a key here is what ran the recipe.
---@return { id: integer, at_prompt: boolean }[]
local function kitty_consoles()
  local ok, out = kitten({ "ls", "--match", "session:. and var:dev_role=console" })
  if not ok then
    return {}
  end
  local decoded, data = pcall(vim.json.decode, out)
  if not decoded then
    return {}
  end
  local found = {}
  for _, os_window in ipairs(data) do
    for _, tab in ipairs(os_window.tabs) do
      for _, w in ipairs(tab.windows) do
        found[#found + 1] = { id = w.id, at_prompt = w.at_prompt == true }
      end
    end
  end
  return found
end

---Where a recipe goes under kitty: the first console at a shell prompt, else a
---new console tab. `at_prompt` comes from kitty's shell integration, and is
---what `pane_current_command` is for tmux: false while anything is running.
---@return integer|nil window_id
local function kitty_console()
  for _, w in ipairs(kitty_consoles()) do
    if w.at_prompt then
      return w.id
    end
  end
  -- --keep-focus so focus stays in nvim; --add-to-session . puts it in the
  -- session of the window that asked, which is this nvim's.
  local ok, out = kitten({
    "launch",
    "--type=tab",
    "--keep-focus",
    "--cwd=" .. context_dir(),
    "--tab-title=console",
    "--var=dev_role=console",
    "--env=DEV_SESSION=" .. (vim.env.DEV_SESSION or ""),
    "--add-to-session=.",
  })
  return ok and tonumber(out) or nil
end

---First console window sitting at a prompt.
---@param sess string
---@return string|nil target
local function idle_console(sess)
  local listed, out = tmux({ "list-windows", "-t", sess .. ":", "-F", "#{window_index} #{window_name}" })
  if not listed then
    return nil
  end
  for line in out:gmatch("[^\n]+") do
    local idx, name = line:match("^(%d+) (.*)$")
    if name == CONSOLE_NAME then
      local target = ("%s:%s"):format(sess, idx)
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
    CONSOLE_NAME,
    "-c",
    cwd,
    "-P",
    "-F",
    "#{session_name}:#{window_index}",
  })
  return (ok and out ~= "") and out or nil
end


---Every public recipe in the justfile above the current buffer.
---Module recipes are not included — `--dump` nests them under `modules`, and
---they need a `mod::recipe` path this doesn't build yet.
---@return table[]|nil items, string? err
function M.recipes()
  local dir = context_dir()
  -- vim.system's list form raises ENOENT when the binary is missing, rather
  -- than returning a non-zero code — so without this the error path below,
  -- which exists precisely to say what went wrong, was skipped and the picker
  -- threw instead.
  if vim.fn.executable("just") ~= 1 then
    return nil, "just is not installed"
  end
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

  if in_kitty() then
    local id = kitty_console()
    if not id then
      vim.notify("just: could not find or open a console window", vim.log.levels.ERROR)
      return
    end
    -- \x15 is C-u, as below.
    local ok = kitten({ "send-text", "--match", "id:" .. id, "\x15" .. cmdline .. "\r" })
    if not ok then
      vim.notify("just: send-text to kitty window " .. id .. " failed", vim.log.levels.ERROR)
      return
    end
    if opts.focus then
      kitten({ "focus-window", "--match", "id:" .. id })
    else
      vim.notify(("%s → console (kitty window %d)"):format(cmdline, id))
    end
    return
  end

  local sess = session()
  if not sess then
    -- Outside tmux and kitty there's no console window to own the output, so it goes in a
    -- float instead.
    --
    -- `interactive = false`, and it matters. In snacks that flag is a shortcut
    -- for start_insert, auto_insert *and* auto_close together, all defaulting
    -- to its value — so asking for an interactive terminal asked for one that
    -- closes the moment the process exits. A recipe that finishes quickly
    -- flickered and left nothing behind: `just marker`, echoing a string that
    -- appears nowhere in the justfile, never put that string on screen at all.
    -- Only a recipe with a `sleep` in it looked like it worked.
    --
    -- Off, the float stays in normal mode with the output in it, scrollable and
    -- dismissable with q — which is what the tmux path gives you, and the point
    -- of running a task at all.
    Snacks.terminal(cmdline, { win = { position = "float" }, interactive = false })
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
