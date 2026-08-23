return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Git: Diff view (working tree)" },
    {
      -- The base is resolved per repository rather than hardcoded. This used to
      -- be `DiffviewOpen main...HEAD`, which is the one mapping in this config
      -- that assumed something about the repo rather than about the editor: a
      -- checkout whose default branch is master, develop or trunk got
      -- "fatal: ambiguous argument 'main'".
      --
      -- origin/HEAD is the remote's own answer to "what is the default branch",
      -- but it is only written by `git clone` and `git remote set-head`, so a
      -- repo that never had it falls back to whichever of main/master exists.
      "<leader>gm",
      function()
        local function resolve()
          local head = vim
            .system({ "git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD" }, { text = true })
            :wait()
          if head.code == 0 then
            local name = vim.trim(head.stdout or ""):gsub("^origin/", "")
            if name ~= "" then
              return name
            end
          end
          for _, name in ipairs({ "main", "master" }) do
            local ok = vim.system({ "git", "rev-parse", "--verify", "--quiet", name }):wait()
            if ok.code == 0 then
              return name
            end
          end
        end

        local base = resolve()
        if not base then
          -- Reachable in a repo whose default is something else entirely
          -- (develop, trunk) and which has no origin/HEAD to say so. Both ways
          -- out are worth naming, since neither is obvious at the time.
          vim.notify(
            "diffview: no default branch found.\n"
              .. "Set one with `git remote set-head origin -a`,\n"
              .. "or diff explicitly: :DiffviewOpen <base>...HEAD",
            vim.log.levels.WARN
          )
          return
        end
        vim.cmd("DiffviewOpen " .. base .. "...HEAD")
      end,
      desc = "Git: Branch diff vs default",
    },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Git: File history" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Git: Repo history" },
  },
  config = function()
    local actions = require("diffview.actions")
    require("diffview").setup({
      view = {
        default = { layout = "diff2_vertical" },
        merge_tool = { layout = "diff3_vertical" },
      },
      hooks = {
        diff_buf_read = function()
          vim.opt_local.wrap = false
          vim.opt_local.list = false
          vim.opt_local.colorcolumn = ""
        end,
      },
      keymaps = {
        view = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "<leader>e", actions.toggle_files, { desc = "Toggle file panel" } },
        },
        file_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "<leader>e", actions.toggle_files, { desc = "Toggle file panel" } },
        },
        file_history_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "<leader>e", actions.toggle_files, { desc = "Toggle file panel" } },
        },
      },
    })
  end,
}
