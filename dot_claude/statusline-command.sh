#!/usr/bin/env bash
input=$(cat)

# Git branch (skip optional locks to avoid conflicts)
git_branch=$(git -C "$(echo "$input" | jq -r '.workspace.current_dir')" --no-optional-locks branch --show-current 2>/dev/null)

# Context window tokens used percentage
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Model
model=$(echo "$input" | jq -r '.model.display_name // empty')

# Reasoning effort (only present when model supports it)
effort=$(echo "$input" | jq -r '.effort.level // empty')

# Rate limits
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Build output parts
parts=()

[ -n "$model" ] && parts+=("model:$model")
[ -n "$effort" ] && parts+=("effort:$effort")
[ -n "$git_branch" ] && parts+=("branch:$git_branch")
[ -n "$five_h" ] && parts+=("5h:$(printf '%.0f' "$five_h")%")
[ -n "$seven_d" ] && parts+=("7d:$(printf '%.0f' "$seven_d")%")
[ -n "$used_pct" ] && parts+=("ctx:$(printf '%.0f' "$used_pct")%")

printf '%s' "$(IFS=' | '; echo "${parts[*]}")"
