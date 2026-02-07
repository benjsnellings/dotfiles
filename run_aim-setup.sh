#!/bin/bash
# run_aim-setup.sh — Runs on every `chezmoi apply`
# Installs/updates aim skills, agents, and MCP servers, then ensures
# ~/.claude.json has the correct mcpServers configuration.

set -euo pipefail

# ── Guard clauses ────────────────────────────────────────────────────

if ! command -v aim &>/dev/null; then
    echo "[aim-setup] aim not found on PATH, skipping aim installs"
    HAS_AIM=false
else
    HAS_AIM=true
fi

if ! command -v jq &>/dev/null; then
    echo "[aim-setup] jq not found on PATH, skipping ~/.claude.json update"
    HAS_JQ=false
else
    HAS_JQ=true
fi

# ── aim skills ───────────────────────────────────────────────────────

if $HAS_AIM; then
    echo "[aim-setup] Installing/updating skills..."
    aim skills install AmazonBuilderCoreAISkillSet AmazonBuilderGenAIPowerUsersQContext StoreGenSpecStudioSkills || {
        echo "[aim-setup] WARNING: aim skills install failed (continuing)"
    }

    echo "[aim-setup] Installing/updating agents..."
    aim agents install AmazonBuilderCoreAIAgents BTDocsAIToolkit StoreGenSpecStudioSkills || {
        echo "[aim-setup] WARNING: aim agents install failed (continuing)"
    }

    echo "[aim-setup] Installing MCP servers from registry..."
    aim mcp install builder-mcp spec-studio-mcp || {
        echo "[aim-setup] WARNING: aim mcp install failed (continuing)"
    }
fi

# ── ~/.claude.json mcpServers ────────────────────────────────────────

if $HAS_JQ; then
    CLAUDE_JSON="$HOME/.claude.json"

    # Desired mcpServers entries — merged into existing config
    DESIRED_SERVERS='
    {
      "builder-mcp": {
        "type": "stdio",
        "command": "builder-mcp",
        "args": [
          "--include-tools",
          "ReadInternalWebsites, InternalSearch, InternalCodeSearch, BrazilBuildAnalyzerTool, GetSoftwareRecommendation, SearchSoftwareRecommendations, Taskei*, Quip*"
        ],
        "env": {}
      },
      "spec-studio-mcp": {
        "type": "stdio",
        "command": "mcp-spec-studio-server"
      }
    }'

    if [ ! -f "$CLAUDE_JSON" ]; then
        echo "[aim-setup] $CLAUDE_JSON not found, creating with mcpServers"
        echo "{\"mcpServers\": $DESIRED_SERVERS}" | jq '.' > "$CLAUDE_JSON"
    else
        # Merge desired servers into existing mcpServers (recursive merge
        # preserves any other keys/servers already in the file)
        UPDATED=$(jq --argjson desired "$DESIRED_SERVERS" '
            .mcpServers = ((.mcpServers // {}) * $desired)
        ' "$CLAUDE_JSON")

        # Only write if something actually changed
        CURRENT=$(cat "$CLAUDE_JSON")
        if [ "$UPDATED" = "$CURRENT" ]; then
            echo "[aim-setup] ~/.claude.json mcpServers already up to date"
        else
            TMPFILE=$(mktemp "${CLAUDE_JSON}.XXXXXX")
            echo "$UPDATED" > "$TMPFILE"
            mv "$TMPFILE" "$CLAUDE_JSON"
            echo "[aim-setup] ~/.claude.json mcpServers updated"
        fi
    fi
fi

echo "[aim-setup] Done"
exit 0
