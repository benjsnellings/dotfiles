#!/usr/bin/env bash
# Marks the current tmux pane's window with Claude Code's "waiting" state so the
# tmux status bar can color it. Invoked from Claude Code hooks:
#   Notification (permission_prompt / idle_prompt / elicitation_dialog) -> ask   (red)
#   Stop                                                                -> stop  (yellow)
#   UserPromptSubmit                                                    -> clear (you replied)
#   PostToolUse (*)                                                     -> clear (working:
#     answering a permission/question dialog is a tool result, NOT a prompt submit,
#     so UserPromptSubmit alone would leave the red marker stuck mid-turn)
#
# Mechanism: sets a pane-scoped user option (@claude_state) that
# window-status-format reads via #{?#{==:#{@claude_state},ask},...}. See ~/.tmux.conf.
#
# States overwrite unconditionally: a Stop after an answered dialog correctly
# downgrades ask->stop (turn is over; "your move" yellow is the honest state).
#
# No-ops safely when not in tmux (Claude launched outside it) or tmux is absent.

set -euo pipefail

state="${1:-clear}"

[ -n "${TMUX_PANE:-}" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

case "$state" in
  ask|stop)
    tmux set-option -p -t "$TMUX_PANE" @claude_state "$state" 2>/dev/null || true
    ;;
  clear)
    tmux set-option -pu -t "$TMUX_PANE" @claude_state 2>/dev/null || true
    ;;
esac

exit 0
