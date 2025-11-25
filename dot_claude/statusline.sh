#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract relevant information
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')

# Abbreviate home directory with ~
cwd_display="${cwd/#$HOME/~}"

# Get time in 24-hour format
time_now=$(date '+%H:%M:%S')

# Get git branch if in a git repository (skip optional locks for performance)
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    git_info=" • $(printf '\033[36m')$branch$(printf '\033[0m')"
else
    git_info=""
fi

# Build status line with color codes
# Format: directory • git-branch • model • time
printf "$(printf '\033[34m')%s$(printf '\033[0m')%s • $(printf '\033[35m')%s$(printf '\033[0m') • $(printf '\033[33m')%s$(printf '\033[0m')" \
    "$cwd_display" \
    "$git_info" \
    "$model" \
    "$time_now"
