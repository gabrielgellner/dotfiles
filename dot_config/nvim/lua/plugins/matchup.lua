return {
  "andymass/vim-matchup",
  event = "BufReadPost",
  init  = function()
    vim.g.matchup_matchparen_offscreen = { method = "popup" } -- show match in popup when offscreen
    vim.g.matchup_matchparen_deferred  = 1                    -- highlight deferred for performance
    vim.g.matchup_motion_enabled       = 1                    -- enable % jump motion
    vim.g.matchup_text_obj_enabled     = 0                    -- disable text objects (mini.ai handles these)
  end,
}
