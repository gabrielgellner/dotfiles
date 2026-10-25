-- Change the default Omarchy look'n'feel.
--
-- Tracked by chezmoi, on the Omarchy machine only; Omarchy wrote it with
-- every line commented out. `omarchy refresh hyprland` resets it.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
--
-- A lone tiled window is held to 4:3 and centred, rather than stretched over
-- the BenQ's 3440 px; a second window and normal tiling takes over again.
-- Measured on applying: kitty went from 3416x1390 to 1854x1390 at x=793,
-- dead centre — a little over half the screen. Omarchy's own commented
-- example here was { 1, 1 }; 16:10 would be 2224 px wide for more columns,
-- 1:1 is 1390 for fewer. Hyprland reloads this file on save.
hl.config({
  layout = {
    single_window_aspect_ratio = { 4, 3 },
  },
})

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })
