#!/usr/bin/env zsh
# Tmux Session Manager Configuration
# This file is sourced by zsh to provide tmux-session functionality

# Main tmux-session function
tmux-session() {
    local SCRIPT_PATH="$HOME/.local/bin/tmux-session.sh"

    # Check if script exists
    if [[ ! -f "$SCRIPT_PATH" ]]; then
        echo "Error: tmux-session.sh not found at $SCRIPT_PATH"
        echo "Please run the installer again"
        return 1
    fi

    # Execute with all arguments
    "$SCRIPT_PATH" "$@"
}

# Tmux session aliases
alias ts='tmux-session'
alias tsd='tmux-session .'           # Start in current directory
alias tsp='tmux-session ~/projects'  # Start in projects folder
alias tsl='tmux list-sessions'       # List all sessions
alias tsk='tmux kill-session -t'     # Kill session by name
alias tsa='tmux attach -t'           # Attach to session by name

# Auto-completion for zsh
_tmux-session() {
    local -a sessions
    sessions=($(tmux list-sessions -F '#S' 2>/dev/null))
    _arguments \
        '1:directory:_directories' \
        '2:session name:(${sessions[@]})'
}
compdef _tmux-session tmux-session

# Quick project selector with fzf (if available)
if command -v fzf &> /dev/null; then
    tsproject() {
        local project_dir
        project_dir=$(find ~/projects ~/work ~/code -maxdepth 2 -type d 2>/dev/null | fzf)
        [[ -n "$project_dir" ]] && tmux-session "$project_dir"
    }
fi

# Export for availability in subshells
# export -f tmux-session 2>/dev/null || true
