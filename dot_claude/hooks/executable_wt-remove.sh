#!/usr/bin/env bash
# WorktreeRemove hook — workspace-aware worktree cleanup, paired with
# wt-create.sh. Fires when Claude Code tears down a worktree it created.
#
# Contract (code.claude.com/docs/en/hooks#worktreeremove):
#   stdin  : JSON carrying the worktree's absolute path. The exact field name is
#            undocumented, so we probe the likely keys (worktree_path / path /
#            worktree.path) defensively.
#   output : ignored. This hook CANNOT block removal and does not receive the
#            user's keep/discard choice — it is best-effort side-effect only.
#   exit   : logged in debug mode only; always exit 0 so a cleanup hiccup never
#            surfaces as a session error.
#
# Discriminator is the path shape, not the cwd (by removal time the session has
# usually left the worktree):
#   * <...>/worktrees/<name> with a packageInfo marker -> brazil-worktree remove
#   * <...>/.claude/worktrees/<name>                    -> git worktree remove --force

set -uo pipefail  # no -e: this hook must never hard-fail the session

export PATH="$HOME/.toolbox/bin:$PATH"

INPUT=$(cat)
DIR=$(printf '%s' "$INPUT" \
  | jq -r '.worktree_path // .path // .worktree.path // .worktree_base_path // empty')

if [ -z "$DIR" ]; then
  echo "wt-remove: no worktree path in hook input; nothing to do" >&2
  exit 0
fi

NAME=$(basename "$DIR")

# --- Brazil worktree (has a packageInfo marker, lives under /worktrees/) ---
if [ -f "$DIR/packageInfo" ] && command -v brazil-worktree >/dev/null 2>&1; then
  # brazil-worktree resolves the parent workspace from cwd; step just outside
  # the worktree (its grandparent is the workspace root) before removing.
  WS_ROOT=$(cd "$DIR/../.." 2>/dev/null && pwd || true)
  echo "wt-remove: removing Brazil worktree '$NAME'" >&2
  ( [ -n "$WS_ROOT" ] && cd "$WS_ROOT"
    printf '{"version":"v1","operation":"remove","arguments":{"name":"%s"}}' "$NAME" \
      | brazil-worktree >/dev/null 2>&1 ) || \
    echo "wt-remove: brazil-worktree remove reported failure (continuing)" >&2
  exit 0
fi

# --- Git worktree fallback -------------------------------------------------
if [ -d "$DIR" ] && git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "wt-remove: removing git worktree at $DIR" >&2
  git -C "$DIR" worktree remove --force "$DIR" >/dev/null 2>&1 \
    || git worktree remove --force "$DIR" >/dev/null 2>&1 \
    || echo "wt-remove: git worktree remove failed (continuing)" >&2
  exit 0
fi

echo "wt-remove: '$DIR' is neither a Brazil nor git worktree; nothing to do" >&2
exit 0
