-- ============================================================================
-- init.lua
-- Entry point. To switch to airgapped mode, change IS_AIRGAPPED to true
-- and set GITLAB_BASE to your internal mirror URL.
-- ============================================================================
-- PATH fixup first
-- vim.env.PATH = table.concat({
--   vim.fn.expand("~/.local/bin"),
--   vim.fn.expand("~/miniconda3/envs/system/bin"),
--   vim.env.PATH,
-- }, ":")

-- ── Environment ───────────────────────────────────────────────────────────────
local IS_AIRGAPPED = false
local GITLAB_BASE  = "https://gitlab.k8s.cloud.statacan.ca/neovim-repo/neovim-packages"
-- ── Bootstrap lazy.nvim ───────────────────────────────────────────────────────
local lazypath     = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local source = IS_AIRGAPPED
      and (GITLAB_BASE .. "/lazy.nvim")
      or "https://github.com/folke/lazy.nvim"

  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    source, "--branch=stable", lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- ── Core config (before plugins) ─────────────────────────────────────────────
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- ── Plugin setup ─────────────────────────────────────────────────────────────
-- Expose env flags so plugin files can read them if needed
_G.NvimEnv = {
  is_airgapped = IS_AIRGAPPED,
  gitlab_base  = GITLAB_BASE,
}

require("lazy").setup("plugins", {
  git = {
    -- In airgapped mode this rewrites all github.com URLs to your mirror.
    -- lazy builds URLs as: url_format % "owner/repo"
    -- so we embed the full base and drop the owner segment via the mirror
    -- naming convention (repos named without owner prefix).
    url_format = IS_AIRGAPPED
        and (GITLAB_BASE .. "/%s.git")
        or "https://github.com/%s.git",
  },
  install = {
    colorscheme = { "catppuccin" },
  },
  ui = {
    border = "rounded",
  },
  -- disable automatic update checks (always off is fine for airgapped,
  -- set to true locally if you want lazy to notify you of updates)
  checker = {
    enabled = not IS_AIRGAPPED,
    notify  = false,
  },
  change_detection = {
    enabled = not IS_AIRGAPPED,
    notify  = false,
  },
  performance = {
    rtp = {
      -- strip out unused default runtime plugins
      disabled_plugins = {
        "gzip", "matchit", "matchparen",
        "netrwPlugin", "tarPlugin", "tohtml",
        "tutor", "zipPlugin",
      },
    },
  },
})
