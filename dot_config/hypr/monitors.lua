-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all
--
-- Tracked by chezmoi, on the Omarchy machine only. The first two settings and
-- the catch-all monitor line are Omarchy's own, as it wrote this file.

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- The BenQ EX3501R. `preferred` picked 3440x1440@59.97, but the panel does
-- 99.98 at the same resolution — listed by `hyprctl monitors all`. Matched by
-- description rather than by port, so moving the cable does not lose it.
hl.monitor({ output = "desc:BNQ BenQ EX3501R K4L00561019", mode = "3440x1440@99.98", position = "auto", scale = 1 })
