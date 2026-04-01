#!/bin/bash
# Fix tmux pane styling after Claude Code team creation.
# Claude Code's TmuxBackend calls select-pane -P which sets per-pane
# window-style AND window-active-style to the same value, overriding
# the user's global active/inactive background distinction.
# This clears those overrides while preserving per-pane border colors.

[ -z "$TMUX" ] && exit 0

fix_panes() {
  for p in $(tmux list-panes -F '#{pane_id}' 2>/dev/null); do
    tmux set-option -up -t "$p" window-style 2>/dev/null
    tmux set-option -up -t "$p" window-active-style 2>/dev/null
  done
}

# Immediate cleanup
fix_panes

# Delayed cleanup for any late-created panes
(sleep 5 && fix_panes) & disown 2>/dev/null

exit 0
