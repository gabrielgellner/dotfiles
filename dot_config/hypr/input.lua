-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults ($OMARCHY_PATH/default/hypr/input.lua).
--
-- Tracked by chezmoi, on the Omarchy machine only. Omarchy created this file
-- with every line commented out and does not write it again — but
-- `omarchy refresh hyprland` resets it, so re-apply after one.

-- Caps Lock is Control, as Karabiner makes it on the laptop
-- (dot_config/private_karabiner): the one remap that matters for vi, tmux's
-- prefix and every C- binding in nvim.
--
-- Omarchy spends Caps Lock on Compose instead (`compose:caps`), and its
-- XCompose shortcuts depend on having one, so Compose moves to Right Alt
-- rather than disappearing. `shift:both_capslock_cancel` is Omarchy's own
-- way to reach Caps Lock itself, kept as it was.
--
-- kb_options is a single string, so this replaces Omarchy's value whole. If
-- the layout is ever non-Latin, Omarchy appends `grp:alts_toggle` to its own
-- copy, and that would need adding here as well.
hl.config({
  input = {
    kb_options = "ctrl:nocaps,compose:ralt,shift:both_capslock_cancel",
  },
})
