#!/bin/bash
# run_tmux-tpm-setup.sh — Runs on every `chezmoi apply`
# Bootstraps TPM (Tmux Plugin Manager) and installs the plugins declared
# in ~/.tmux.conf so a fresh machine gets resurrect/continuum/fzf-pane-switch/
# minimal-tmux-status without manual `prefix + I`.

set -euo pipefail

TPM_DIR="$HOME/.tmux/plugins/tpm"

# ── Guard clauses ────────────────────────────────────────────────────

if ! command -v git &>/dev/null; then
    echo "[tmux-tpm-setup] git not found on PATH, skipping"
    exit 0
fi

# ── Clone TPM if missing ─────────────────────────────────────────────

if [ -d "$TPM_DIR" ]; then
    echo "[tmux-tpm-setup] TPM already present at $TPM_DIR"
else
    echo "[tmux-tpm-setup] Cloning TPM into $TPM_DIR..."
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR" || {
        echo "[tmux-tpm-setup] WARNING: TPM clone failed (continuing)"
        exit 0
    }
fi

# ── Install plugins non-interactively ────────────────────────────────
# TPM's install_plugins parses ~/.tmux.conf @plugin lines but needs a tmux
# server that has sourced the config so TMUX_PLUGIN_MANAGER_PATH is set.
# Create a throwaway detached session, source the config into it, install,
# then kill only that session — never touching the user's own sessions.

if command -v tmux &>/dev/null && [ -x "$TPM_DIR/bin/install_plugins" ]; then
    echo "[tmux-tpm-setup] Installing/updating tmux plugins..."
    BOOT_SESSION="__tpm_bootstrap"
    tmux new-session -d -s "$BOOT_SESSION" 2>/dev/null || true
    tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true
    "$TPM_DIR/bin/install_plugins" || {
        echo "[tmux-tpm-setup] WARNING: plugin install failed (continuing)"
    }
    tmux kill-session -t "$BOOT_SESSION" 2>/dev/null || true
else
    echo "[tmux-tpm-setup] tmux or install_plugins unavailable, skipping plugin install"
fi

echo "[tmux-tpm-setup] Done"
exit 0
