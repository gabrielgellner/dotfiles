#!/usr/bin/env bash
# Claude Code statusline. Reads one JSON blob on stdin, prints one line.
set -uo pipefail

input=$(cat)

# One jq call, not one per field. This redraws constantly, and the previous
# version forked jq six times per refresh.
#
# -r gives raw strings; @tsv would quote, so the fields are joined by hand with
# an ASCII unit separator. Not tabs: tab is whitespace, and `read` collapses
# runs of whitespace separators, so empty fields disappeared and the values
# shifted anyway. 0x1f is not whitespace, so each empty field survives as one.
#
# Each fallback is `// ""` and emphatically not `// empty`: empty removes
# the element from the array, so join() emits fewer fields and every later value
# lands in the wrong variable — a payload with no effort put the context figure
# into $model. "" keeps the position and reads back as an empty string, which is
# what the `-n` tests below expect.
IFS=$'\x1f' read -r dir model effort used_pct five_h seven_d < <(
    printf '%s' "$input" | jq -r '
        [ .workspace.current_dir            // "",
          .model.display_name               // "",
          .effort.level                     // "",
          .context_window.used_percentage   // "",
          .rate_limits.five_hour.used_percentage // "",
          .rate_limits.seven_day.used_percentage // ""
        ] | join("\u001f")'
)

# --no-optional-locks so a status read never contends with a running git command
git_branch=""
[ -n "$dir" ] && git_branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)

parts=()
[ -n "$model" ]      && parts+=("model:$model")
[ -n "$effort" ]     && parts+=("effort:$effort")
[ -n "$git_branch" ] && parts+=("branch:$git_branch")
[ -n "$five_h" ]     && parts+=("5h:$(printf '%.0f' "$five_h")%")
[ -n "$seven_d" ]    && parts+=("7d:$(printf '%.0f' "$seven_d")%")
[ -n "$used_pct" ]   && parts+=("ctx:$(printf '%.0f' "$used_pct")%")

# Joined explicitly. This used to be `IFS=' | '; echo "${parts[*]}"`, which does
# not do what it reads like: IFS is a set of separator *characters* and ${a[*]}
# joins with only the first of them, so the output was space-separated.
# ${parts[@]+...} because bash 3.2 — which is what /bin/bash still is on macOS —
# treats an empty array as unset under `set -u` and aborts here.
out=""
for p in ${parts[@]+"${parts[@]}"}; do
    [ -n "$out" ] && out+=" | "
    out+="$p"
done
printf '%s' "$out"
