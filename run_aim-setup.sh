#!/bin/bash
# run_aim-setup.sh — Runs on every `chezmoi apply`
# Installs/updates aim skills, agents, and MCP servers, provisions the
# ClaudeAmazonMarketplace workspace and plugins, then ensures
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

if ! command -v brazil &>/dev/null; then
    echo "[aim-setup] brazil not found on PATH, skipping marketplace workspace"
    HAS_BRAZIL=false
else
    HAS_BRAZIL=true
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

# ── ClaudeAmazonMarketplace workspace + marketplace ────────────────

MARKETPLACE_WS="$HOME/tools/ClaudeAmazonMarketplace"
MARKETPLACE_PKG_DIR="$MARKETPLACE_WS/src/ClaudeAmazonMarketplace"
MARKETPLACE_AMZN_DIR="$MARKETPLACE_PKG_DIR/amzn"

if $HAS_BRAZIL; then
    if [ ! -d "$MARKETPLACE_WS/src" ]; then
        echo "[aim-setup] Creating ClaudeAmazonMarketplace workspace at $MARKETPLACE_WS..."
        brazil ws create --root "$MARKETPLACE_WS" --versionset SnellinAiPlayground/development || {
            echo "[aim-setup] WARNING: workspace create failed (continuing)"
        }
        if [ -d "$MARKETPLACE_WS" ]; then
            echo "[aim-setup] Pulling ClaudeAmazonMarketplace package..."
            (cd "$MARKETPLACE_WS" && brazil ws use -p ClaudeAmazonMarketplace) || {
                echo "[aim-setup] WARNING: brazil ws use failed (continuing)"
            }
        fi
    else
        echo "[aim-setup] Syncing ClaudeAmazonMarketplace workspace..."
        (cd "$MARKETPLACE_WS" && brazil ws sync) || {
            echo "[aim-setup] WARNING: brazil ws sync failed (continuing)"
        }
    fi
fi

if $HAS_CLAUDE && [ -d "$MARKETPLACE_AMZN_DIR" ]; then
    MARKETPLACE_LIST=$(claude plugin marketplace list 2>/dev/null || true)
    if echo "$MARKETPLACE_LIST" | grep -q "amzn"; then
        echo "[aim-setup] Updating amzn marketplace..."
        claude plugin marketplace update amzn || {
            echo "[aim-setup] WARNING: marketplace update failed (continuing)"
        }
    else
        echo "[aim-setup] Adding amzn marketplace from $MARKETPLACE_AMZN_DIR..."
        claude plugin marketplace add "$MARKETPLACE_AMZN_DIR" || {
            echo "[aim-setup] WARNING: marketplace add failed (continuing)"
        }
    fi

    PLUGIN_LIST=$(claude plugin list 2>/dev/null || true)
    if ! echo "$PLUGIN_LIST" | grep -q "amzn-commit@amzn"; then
        echo "[aim-setup] Installing amzn-commit plugin..."
        claude plugin install amzn-commit@amzn || {
            echo "[aim-setup] WARNING: amzn-commit install failed (continuing)"
        }
    fi

    if ! echo "$PLUGIN_LIST" | grep -q "amzn-cr@amzn"; then
        echo "[aim-setup] Installing amzn-cr plugin..."
        claude plugin install amzn-cr@amzn || {
            echo "[aim-setup] WARNING: amzn-cr install failed (continuing)"
        }
    fi
else
    if ! $HAS_CLAUDE; then
        echo "[aim-setup] claude CLI not available, skipping marketplace registration"
    elif [ ! -d "$MARKETPLACE_AMZN_DIR" ]; then
        echo "[aim-setup] $MARKETPLACE_AMZN_DIR not found, skipping marketplace registration"
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
