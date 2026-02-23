
# Auto-spawn tmux session for Claude Code
# claude() {
#   if [[ -z "$TMUX" ]]; then
#     tmux new-session -s "claude-$$" \; send-keys "command claude $*" Enter
#   else
#     command claude "$@"
#   fi
# }
