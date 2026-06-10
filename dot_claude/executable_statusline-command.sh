#!/bin/sh
# Claude Code statusLine — mirrors Powerlevel10k lean prompt style
# Order: dir  git  aws  tf  model  ctx%  rate%

input=$(cat)

# --- directory (adaptive truncation like Powerlevel10k) ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
home="$HOME"
# Replace $HOME prefix with ~
short_dir="${cwd/#$home/~}"

# Adaptive path shortening: keep first + last segment, shorten middle ones to
# their first letter — then collapse further with … if still too wide.
# Budget: terminal width minus ~30 chars for other prompt segments.
term_cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
path_budget=$(( term_cols - 30 ))
[ "$path_budget" -lt 10 ] && path_budget=10

shorten_path() {
  local p="$1" budget="$2"
  # If it already fits, use it as-is
  if [ "${#p}" -le "$budget" ]; then
    echo "$p"
    return
  fi

  # Split on /
  local IFS='/'
  # shellcheck disable=SC2206
  local parts=( $p )
  local n="${#parts[@]}"

  if [ "$n" -le 2 ]; then
    # Can't shorten further; just truncate with ellipsis
    echo "${p:0:$((budget-1))}…"
    return
  fi

  # Build array: keep first part and last part intact,
  # shorten all middle parts to their first character.
  local result=()
  local i=0
  for part in "${parts[@]}"; do
    if [ "$i" -eq 0 ] || [ "$i" -eq $(( n - 1 )) ]; then
      result+=( "$part" )
    else
      # First char of the segment (handles ~ and normal names)
      result+=( "${part:0:1}" )
    fi
    i=$(( i + 1 ))
  done

  local joined
  joined=$(IFS='/'; echo "${result[*]}")

  # If still too long, replace middle with a single …
  if [ "${#joined}" -gt "$budget" ]; then
    local first="${parts[0]}"
    local last="${parts[$(( n - 1 ))]}"
    joined="$first/…/$last"
    # Last resort: hard-truncate
    if [ "${#joined}" -gt "$budget" ]; then
      joined="${joined:0:$((budget-1))}…"
    fi
  fi

  echo "$joined"
}

short_dir=$(shorten_path "$short_dir" "$path_budget")

# --- git branch & dirty marker ---
git_info=""
if git -C "$cwd" rev-parse --git-dir --no-flags -q >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    # Check for uncommitted changes (skip optional locks)
    if git -C "$cwd" diff --no-ext-diff --quiet 2>/dev/null && git -C "$cwd" diff --no-ext-diff --cached --quiet 2>/dev/null; then
      dirty=""
    else
      dirty="*"
    fi
    git_info=" $branch$dirty"
  fi
fi

# --- model (strip any parenthesised suffix, e.g. "(1M context)") ---
model=$(echo "$input" | jq -r '.model.display_name // ""' | sed 's/ *([^)]*)//')

# --- context usage ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_info=""
if [ -n "$used_pct" ]; then
  ctx_info=" ctx:$(printf '%.0f' "$used_pct")%"
fi

# --- rate limits ---
five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rate_info=""
if [ -n "$five_hour" ]; then
  rate_info=" 5h:$(printf '%.0f' "$five_hour")%"
fi

# --- AWS profile ---
aws_profile="${AWS_PROFILE:-}"
aws_info=""
if [ -n "$aws_profile" ]; then
  aws_info=" \033[33maws:$aws_profile\033[0m"
fi

# --- Terraform workspace ---
tf_info=""
if [ -f "$cwd/.terraform/environment" ]; then
  tf_ws=$(cat "$cwd/.terraform/environment" 2>/dev/null)
  if [ -n "$tf_ws" ] && [ "$tf_ws" != "default" ]; then
    tf_info=" \033[38;5;141mtf:$tf_ws\033[0m"
  elif [ "$tf_ws" = "default" ]; then
    tf_info=" \033[38;5;141mtf:default\033[0m"
  fi
fi

printf '\033[34m%s\033[0m\033[32m%s\033[0m%b%b  \033[35m%s\033[0m\033[90m%s%s\033[0m' \
  "$short_dir" "$git_info" "$aws_info" "$tf_info" "$model" "$ctx_info" "$rate_info"
