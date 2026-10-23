-- GitHub issues, pull requests and notifications as nvim buffers.
--
-- Octo is a front end to `gh`: every request is a `gh api graphql` call, so it
-- needs nothing of its own for auth. `gh auth status` answering is the whole
-- setup, and the token's scopes are what limit it — `repo`, `read:org` and
-- `workflow` cover issues, PRs, reviews and runs. Projects v2 would need
-- `read:project` on top, which is why the card commands are not keyed here.
--
-- plenary is a hard dependency, not an optional one: octo runs every `gh` call
-- through plenary.job, and `:checkhealth octo` fails without it. That sits
-- awkwardly beside the notes in todo.lua and trouble.lua about plenary being
-- end of life — there is no octo without it, so this is the cost of the
-- plugin rather than an oversight. yazi.lua already pulls it in.
--
-- Keys live under <leader>o. Everything octo binds *inside* its own buffers is
-- buffer-local under <localleader> (`\`), and the guide (octo.md) has the
-- ones worth learning.
return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
  opts = {
    -- The default is telescope, which is not installed here; snacks is what
    -- every other picker in this config is.
    picker = "snacks",
    -- Bare `:Octo` opens a picker over every action instead of an error, which
    -- is the discoverable way into the long tail no key is spent on.
    enable_builtin = true,
    picker_config = {
      mappings = {
        -- Upstream binds merge to <C-r> in the PR picker, in insert mode too,
        -- and runs `gh pr merge` on the highlighted row with no confirmation.
        -- In a snacks prompt <C-r> also starts the register keys — <C-r><C-w>,
        -- <C-r>% — so a slow second keystroke merges a PR. A <Plug> lhs is
        -- unreachable from the keyboard, which is the only way to take it off:
        -- octo binds whatever lhs this names. Merge from the PR buffer with
        -- `\pm`, with the PR on screen.
        merge_pr = { lhs = "<Plug>(octo-picker-merge-pr)", desc = "merge pull request" },
      },
    },
    mappings = {
      pull_request = {
        -- Upstream puts approve on <leader>qa, buffer-locally — the one octo
        -- key outside <localleader>, and it lands in this config's quit group,
        -- a typo away from <leader>qq. Approving belongs beside the other PR
        -- verbs (po checkout, pm merge, pd diff).
        approve_pr = { lhs = "<localleader>pa", desc = "approve PR" },
      },
    },
  },
  keys = {
    -- Lowercase is this repo, capital is all of GitHub — the scope rule from
    -- keymaps.md. The capitals go through search, which is cross-repo by
    -- nature; `@me` is resolved by GitHub, not here.
    { "<leader>oi", "<cmd>Octo issue list<CR>", desc = "Issues (repo)" },
    { "<leader>oI", "<cmd>Octo search is:issue is:open involves:@me<CR>", desc = "Issues involving me (GitHub)" },
    { "<leader>op", "<cmd>Octo pr list<CR>", desc = "Pull requests (repo)" },
    { "<leader>oP", "<cmd>Octo search is:pr is:open involves:@me<CR>", desc = "PRs involving me (GitHub)" },
    { "<leader>on", "<cmd>Octo notification list<CR>", desc = "Notifications" },
    { "<leader>oc", "<cmd>Octo issue create<CR>", desc = "Create issue" },
    -- Start or resume a review of the PR for the checked-out branch. Octo's own
    -- `\ve` does the same from inside a PR buffer.
    { "<leader>or", "<cmd>Octo review<CR>", desc = "Review this branch's PR" },
    { "<leader>ob", "<cmd>Octo repo browser<CR>", desc = "Repo in browser" },
    { "<leader>oo", "<cmd>Octo<CR>", desc = "All Octo actions" },
  },
}
