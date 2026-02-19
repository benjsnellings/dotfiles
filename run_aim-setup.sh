#!/bin/bash
# run_aim-setup.sh — Runs on every `chezmoi apply`
# Installs/updates aim skills, agents, and MCP servers, registers the
# smangings plugin marketplace, then ensures ~/.claude.json has the
# correct mcpServers configuration.

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

if ! command -v claude &>/dev/null; then
    echo "[aim-setup] claude not found on PATH, skipping marketplace plugin setup"
    HAS_CLAUDE=false
else
    HAS_CLAUDE=true
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
    aim mcp install builder-mcp spec-studio-mcp workplace-chat-mcp agentspaces-mcp || {
        echo "[aim-setup] WARNING: aim mcp install failed (continuing)"
    }
fi

# ── Claude plugin marketplace (smangings) ───────────────────────────

MARKETPLACE_DIR="$HOME/.claude/personal_marketplaces/smangings"

if $HAS_CLAUDE && [ -d "$MARKETPLACE_DIR" ]; then
    MARKETPLACE_LIST=$(claude plugin marketplace list 2>/dev/null || true)
    if echo "$MARKETPLACE_LIST" | grep -q "smangings"; then
        echo "[aim-setup] Updating smangings marketplace..."
        claude plugin marketplace update smangings || {
            echo "[aim-setup] WARNING: marketplace update failed (continuing)"
        }
    else
        echo "[aim-setup] Adding smangings marketplace from $MARKETPLACE_DIR..."
        claude plugin marketplace add "$MARKETPLACE_DIR" || {
            echo "[aim-setup] WARNING: marketplace add failed (continuing)"
        }
    fi

    PLUGIN_LIST=$(claude plugin list 2>/dev/null || true)
    if ! echo "$PLUGIN_LIST" | grep -q "smangings@smangings"; then
        echo "[aim-setup] Installing smangings plugin..."
        claude plugin install smangings@smangings || {
            echo "[aim-setup] WARNING: smangings install failed (continuing)"
        }
    fi
else
    if ! $HAS_CLAUDE; then
        echo "[aim-setup] claude CLI not available, skipping marketplace registration"
    elif [ ! -d "$MARKETPLACE_DIR" ]; then
        echo "[aim-setup] $MARKETPLACE_DIR not found, skipping marketplace registration"
    fi
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
      },
      "workplace-chat-mcp": {
        "type": "stdio",
        "command": "workplace-chat-mcp",
        "args": []
      },
      "agentspaces-mcp": {
        "type": "stdio",
        "command": "agentspaces-mcp",
        "args": []
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
