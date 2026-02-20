#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract relevant information
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')

# Extract context window info
max_ctx=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Abbreviate home directory, then trim to last 3 path components
cwd_display="${cwd/#$HOME/~}"
parts=$(echo "$cwd_display" | tr '/' '\n' | wc -l)
if [ "$parts" -gt 3 ]; then
    cwd_display=$(echo "$cwd_display" | rev | cut -d'/' -f1-3 | rev)
fi

# Get time in 24-hour format
time_now=$(date '+%H:%M:%S')

# Color codes
BLUE='\033[34m'
CYAN='\033[36m'
MAGENTA='\033[35m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Get git branch if in a git repository (skip optional locks for performance)
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    git_info=" • ${CYAN}${branch}${RESET}"
else
    git_info=""
fi

# Build context window display
if [ -z "$used_pct" ] || [ "$used_pct" = "null" ]; then
    # Loading state - empty circles
    context_info="○○○○○○○○○○ loading..."
else
    pct=$(printf "%.0f" "$used_pct" 2>/dev/null || echo "$used_pct")
    [ "$pct" -gt 100 ] 2>/dev/null && pct=100

    # Calculate tokens in k
    used_k=$(( max_ctx * pct / 100 / 1000 ))
    max_k=$(( max_ctx / 1000 ))

    # Build circle bar (10 segments)
    bar=""
    filled=$(( pct / 10 ))

    # Blue by default, red when > 60%
    if [ "$pct" -gt 60 ]; then
        COLOR="$RED"
    else
        COLOR="$BLUE"
    fi

    for i in 0 1 2 3 4 5 6 7 8 9; do
        if [ "$i" -lt "$filled" ]; then
            bar="${bar}${COLOR}●${RESET}"
        else
            bar="${bar}○"
        fi
    done

    context_info="${bar} ${used_k}k/${max_k}k (${pct}%)"
fi

# Build status line with color codes
# Format: directory • git-branch • model • time | context-bar
printf '%b' "${BLUE}${cwd_display}${RESET}${git_info} • ${MAGENTA}${model}${RESET} • ${YELLOW}${time_now}${RESET} | ${context_info}"
