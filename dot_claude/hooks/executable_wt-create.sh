#!/usr/bin/env bash
# WorktreeCreate hook — workspace-aware worktree creation.
#
# Claude Code fires WorktreeCreate (from `--worktree` / EnterWorktree) when a
# hook is configured, and this REPLACES the built-in git worktree logic in every
# repo. We branch on context:
#
#   * Inside a Brazil workspace  -> delegate to `brazil-worktree` (JSON-pipe),
#     which builds a real isolated Brazil workspace (own packageInfo/build/env)
#     at <workspace>/worktrees/<name>. Fixes the write-lock/build contention that
#     plain git worktrees can't (shared build/ dirs). See
#     w.amazon.com/bin/view/BrazilCLI/Worktrees.
#   * Anywhere else (ordinary git repo) -> reproduce the documented Claude Code
#     default: a git worktree on branch `worktree-<name>` under
#     .claude/worktrees/<name>, based on origin/HEAD (falling back to HEAD).
#     This is lossy vs. the built-in (no .worktreeinclude copy, no transcript
#     relocation), the accepted trade-off for a single global hook.
#
# Contract (code.claude.com/docs/en/hooks#worktreecreate):
#   stdin  : JSON with `.name` (+ session_id/cwd/hook_event_name)
#   stdout : the created worktree's absolute path as the LAST line; everything
#            else MUST go to stderr or it corrupts path detection
#   exit   : non-zero aborts creation (this hook is blocking)

set -euo pipefail

# Hooks may run with a minimal PATH; toolbox bin holds brazil / brazil-worktree.
export PATH="$HOME/.toolbox/bin:$PATH"

INPUT=$(cat)
NAME=$(printf '%s' "$INPUT" | jq -r '.name // .worktree_name // empty')
HOOK_CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')

if [ -z "$NAME" ]; then
  echo "wt-create: no worktree name in hook input" >&2
  exit 1
fi

# Run detection/creation from the session's cwd when provided.
[ -n "$HOOK_CWD" ] && [ -d "$HOOK_CWD" ] && cd "$HOOK_CWD"

# --- Brazil workspace path ------------------------------------------------
if command -v brazil-worktree >/dev/null 2>&1 && brazil workspace show >/dev/null 2>&1; then
  echo "wt-create: Brazil workspace detected, creating worktree '$NAME'" >&2
  RESULT=$(printf '{"version":"v1","operation":"create","arguments":{"name":"%s"}}' "$NAME" \
    | brazil-worktree 2>/dev/null) || {
      echo "wt-create: brazil-worktree create failed" >&2
      exit 1
    }
  ERR=$(printf '%s' "$RESULT" | jq -r '.error // empty')
  DIR=$(printf '%s' "$RESULT" | jq -r '.path // empty')
  if [ -n "$ERR" ] || [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
    echo "wt-create: brazil-worktree returned no usable path (${ERR:-no error field})" >&2
    exit 1
  fi
  echo "$DIR"
  exit 0
fi

# --- Git fallback (mirror Claude Code's documented default) ---------------
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ROOT=$(git rev-parse --show-toplevel)
  DIR="$ROOT/.claude/worktrees/$NAME"
  BRANCH="worktree-$NAME"

  # Base on origin/HEAD (a "fresh" tree matching the remote); fall back to local
  # HEAD when no remote default is resolvable — same order the built-in uses.
  if BASE_REF=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null); then
    BASE="$BASE_REF"
  else
    BASE="HEAD"
  fi

  echo "wt-create: git worktree '$BRANCH' from '$BASE' at $DIR" >&2
  git worktree add -b "$BRANCH" "$DIR" "$BASE" >&2 || {
    echo "wt-create: git worktree add failed" >&2
    exit 1
  }
  echo "$DIR"
  exit 0
fi

echo "wt-create: not a Brazil workspace and not a git repo; cannot create worktree" >&2
exit 1
