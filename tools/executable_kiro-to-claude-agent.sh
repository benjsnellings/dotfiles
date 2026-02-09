#!/usr/bin/env bash
set -euo pipefail

# kiro-to-claude-agent.sh — Convert Kiro agent definitions to Claude Code agent format
#
# Usage:
#   kiro-to-claude-agent.sh [OPTIONS] <input-file-or-directory>
#
# Options:
#   -o, --output DIR    Output directory (default: ~/.claude/agents/)
#   -n, --dry-run       Print to stdout instead of writing files
#   -h, --help          Show this help message

readonly VERSION="1.0.0"
readonly DEFAULT_OUTPUT_DIR="$HOME/.claude/agents"

# ─── Colors ───────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    readonly C_RESET='\033[0m'
    readonly C_BOLD='\033[1m'
    readonly C_GREEN='\033[32m'
    readonly C_YELLOW='\033[33m'
    readonly C_RED='\033[31m'
    readonly C_CYAN='\033[36m'
    readonly C_DIM='\033[2m'
else
    readonly C_RESET='' C_BOLD='' C_GREEN='' C_YELLOW='' C_RED='' C_CYAN='' C_DIM=''
fi

# ─── Logging ──────────────────────────────────────────────────────────────────
info()    { echo -e "${C_CYAN}ℹ${C_RESET} $*" >&2; }
warn()    { echo -e "${C_YELLOW}⚠${C_RESET} $*" >&2; }
error()   { echo -e "${C_RED}✖${C_RESET} $*" >&2; }
success() { echo -e "${C_GREEN}✔${C_RESET} $*" >&2; }

# ─── Counters ─────────────────────────────────────────────────────────────────
CONVERTED=0
SKIPPED=0
WARNINGS=0
SKILLS_COPIED=0
TMPOUT=$(mktemp)
trap 'rm -f "$TMPOUT"' EXIT

readonly AIM_SKILLS_DIR="$HOME/.aim/skills"

# ─── Result Variables (avoid subshells for counter tracking) ──────────────────
_MAPPED_TOOL=""
_MAPPED_MODEL=""
_MAPPED_TOOLS=""

# ─── Tool Name Mapping ────────────────────────────────────────────────────────
# Sets _MAPPED_TOOL to the result
map_tool_name() {
    local tool="$1"
    case "$tool" in
        read|fs_read)           _MAPPED_TOOL="Read" ;;
        write|fs_write)         _MAPPED_TOOL="Write,Edit" ;;
        shell|execute_bash)     _MAPPED_TOOL="Bash" ;;
        web|web_fetch)          _MAPPED_TOOL="WebFetch" ;;
        grep)                   _MAPPED_TOOL="Grep" ;;
        glob)                   _MAPPED_TOOL="Glob" ;;
        '@builtin')             _MAPPED_TOOL="Read,Write,Edit,Glob,Grep,Bash,WebFetch,NotebookEdit" ;;
        '@'*'/'*|'@'*)
            # MCP server reference — drop with warning
            warn "  Dropped tool '${tool}' (MCP tools inherited globally in Claude Code)"
            ((WARNINGS++)) || true
            _MAPPED_TOOL=""
            ;;
        '*')
            # Wildcard — signal to omit tools field entirely
            _MAPPED_TOOL="__WILDCARD__"
            ;;
        *)
            warn "  Unknown tool '${tool}' — passed through as-is"
            ((WARNINGS++)) || true
            _MAPPED_TOOL="$tool"
            ;;
    esac
}

# ─── Model Name Mapping ──────────────────────────────────────────────────────
# Sets _MAPPED_MODEL to the result
map_model_name() {
    local model="$1"
    case "$model" in
        null|"")                          _MAPPED_MODEL="" ;;
        claude-sonnet-4*|claude-sonnet-3*) _MAPPED_MODEL="sonnet" ;;
        claude-opus-4*|claude-opus-3*)     _MAPPED_MODEL="opus" ;;
        claude-haiku-3*|claude-haiku-*)    _MAPPED_MODEL="haiku" ;;
        *)
            warn "  Unknown model '${model}' — mapped to empty (inherit)"
            ((WARNINGS++)) || true
            _MAPPED_MODEL=""
            ;;
    esac
}

# ─── Map Tools Array ─────────────────────────────────────────────────────────
# Input: JSON array string like '["@builtin","@builder-mcp"]'
# Sets _MAPPED_TOOLS to comma-separated Claude Code tool names, or __WILDCARD__
map_tools_array() {
    local tools_json="$1"
    local has_wildcard=false
    local mapped_tools=()

    # Parse JSON array into lines
    local tools
    tools=$(echo "$tools_json" | jq -r '.[]? // empty' 2>/dev/null) || { _MAPPED_TOOLS=""; return; }

    while IFS= read -r tool; do
        [[ -z "$tool" ]] && continue
        map_tool_name "$tool"
        if [[ "$_MAPPED_TOOL" == "__WILDCARD__" ]]; then
            has_wildcard=true
        elif [[ -n "$_MAPPED_TOOL" ]]; then
            # Split comma-separated results into individual items
            IFS=',' read -ra parts <<< "$_MAPPED_TOOL"
            for part in "${parts[@]}"; do
                mapped_tools+=("$part")
            done
        fi
    done <<< "$tools"

    if $has_wildcard; then
        _MAPPED_TOOLS="__WILDCARD__"
        return
    fi

    # Deduplicate and join
    if [[ ${#mapped_tools[@]} -gt 0 ]]; then
        _MAPPED_TOOLS=$(printf '%s\n' "${mapped_tools[@]}" | sort -u | paste -sd',' - | sed 's/,/, /g')
    else
        _MAPPED_TOOLS=""
    fi
}

# ─── Extract Skills from mcpServers Args ──────────────────────────────────────
# Parses --skill-name-filter values from mcpServers.*.args arrays
# Sets _EXTRACTED_SKILLS to comma-separated skill names (empty if none)
extract_skills() {
    local input_file="$1"
    _EXTRACTED_SKILLS=""

    # Find all --skill-name-filter values across all mcpServer args
    local filter_values
    filter_values=$(jq -r '
        [.mcpServers // {} | to_entries[].value.args // [] |
         . as $args | range(length) |
         select($args[.] == "--skill-name-filter") |
         $args[. + 1] // empty
        ] | .[]
    ' "$input_file" 2>/dev/null) || return

    local all_skills=()
    while IFS= read -r filter; do
        [[ -z "$filter" ]] && continue
        if [[ "$filter" == "*" ]]; then
            info "  Skills: wildcard (*) — all skills available"
            # Wildcard: don't restrict, omit skills field
            _EXTRACTED_SKILLS="__WILDCARD__"
            return
        fi
        # Split comma-separated skill names
        IFS=',' read -ra skill_names <<< "$filter"
        for sname in "${skill_names[@]}"; do
            [[ -n "$sname" ]] && all_skills+=("$sname")
        done
    done <<< "$filter_values"

    if [[ ${#all_skills[@]} -gt 0 ]]; then
        # Deduplicate
        _EXTRACTED_SKILLS=$(printf '%s\n' "${all_skills[@]}" | sort -u | paste -sd',' - | sed 's/,/, /g')
        info "  Skills → ${_EXTRACTED_SKILLS}"
    fi
}

# ─── Convert Resources to @file References ───────────────────────────────────
# Input: JSON array of file:// URIs
# Sets _RESOURCE_REFS to newline-separated @path lines
convert_resources() {
    local resources_json="$1"
    _RESOURCE_REFS=""

    local resources
    resources=$(echo "$resources_json" | jq -r '.[]? // empty' 2>/dev/null) || return

    while IFS= read -r uri; do
        [[ -z "$uri" ]] && continue

        local path=""
        case "$uri" in
            file:///*)
                # Absolute path: file:///Users/... → /Users/...
                path="${uri#file://}"
                ;;
            file://~*)
                # Home-relative: file://~/.kiro/... → ~/.kiro/...
                path="${uri#file://}"
                ;;
            file://*)
                # Relative path: file://README.md → README.md
                path="${uri#file://}"
                ;;
            *)
                warn "  Skipped non-file resource: ${uri}"
                ((WARNINGS++)) || true
                continue
                ;;
        esac

        if [[ -n "$path" ]]; then
            # Auto-fix missing .md extension: if path doesn't exist but path.md does
            local expanded_path="$path"
            # Expand ~ for existence check
            local check_path="${path/#\~/$HOME}"
            if [[ "$path" != *'*'* && "$path" != *'?'* ]]; then
                # Not a glob — check existence
                if [[ ! -e "$check_path" && -e "${check_path}.md" ]]; then
                    expanded_path="${path}.md"
                    info "  Resource: auto-fixed missing .md extension"
                fi
            fi

            if [[ -n "$_RESOURCE_REFS" ]]; then
                _RESOURCE_REFS+=$'\n'
            fi
            _RESOURCE_REFS+="@${expanded_path}"
            info "  Resource → @${expanded_path}"
        fi
    done <<< "$resources"
}

# ─── Copy and Translate Skills ────────────────────────────────────────────────
# Finds a skill in ~/.aim/skills/, translates SKILL.md frontmatter,
# and copies the full skill directory to the output skills directory.
copy_skills() {
    local skills_csv="$1"
    local skills_output_dir="$2"
    local dry_run="$3"

    [[ -z "$skills_csv" || "$skills_csv" == "__WILDCARD__" ]] && return

    IFS=',' read -ra skill_list <<< "$skills_csv"
    for skill in "${skill_list[@]}"; do
        skill=$(echo "$skill" | xargs)  # trim whitespace
        [[ -z "$skill" ]] && continue

        # Find skill in AIM directory (search all subdirectories)
        local src_dir=""
        src_dir=$(find "$AIM_SKILLS_DIR" -maxdepth 2 -type d -name "$skill" 2>/dev/null | head -1)

        if [[ -z "$src_dir" || ! -f "$src_dir/SKILL.md" ]]; then
            warn "  Skill '${skill}' not found in ${AIM_SKILLS_DIR}"
            ((WARNINGS++)) || true
            continue
        fi

        local dest_dir="${skills_output_dir}/${skill}"

        if [[ "$dry_run" == "true" ]]; then
            info "  Would copy skill: ${skill} → ${dest_dir}/"
            # Show what the translated SKILL.md would look like
            translate_skill_md "$src_dir/SKILL.md"
            return
        fi

        # Create destination and copy supporting files
        mkdir -p "$dest_dir"
        # Copy everything except SKILL.md first
        find "$src_dir" -mindepth 1 -not -name "SKILL.md" -print0 2>/dev/null | while IFS= read -r -d '' item; do
            local rel="${item#$src_dir/}"
            if [[ -d "$item" ]]; then
                mkdir -p "$dest_dir/$rel"
            else
                cp "$item" "$dest_dir/$rel"
            fi
        done

        # Translate and write SKILL.md
        translate_skill_md "$src_dir/SKILL.md" > "$dest_dir/SKILL.md"
        success "  Skill copied: ${skill} → ${dest_dir}/"
        ((SKILLS_COPIED++)) || true
    done
}

# Translates a Kiro SKILL.md by stripping unsupported frontmatter fields
# (version, tags) and preserving everything else.
translate_skill_md() {
    local src_file="$1"
    local in_frontmatter=false
    local frontmatter_done=false
    local delimiter_count=0
    local skip_tags_block=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "---" ]]; then
            ((delimiter_count++))
            if [[ $delimiter_count -eq 1 ]]; then
                in_frontmatter=true
                echo "$line"
                continue
            elif [[ $delimiter_count -eq 2 ]]; then
                in_frontmatter=false
                frontmatter_done=true
                skip_tags_block=false
                echo "$line"
                continue
            fi
        fi

        if $in_frontmatter; then
            # Skip version field
            if [[ "$line" =~ ^version: ]]; then
                continue
            fi
            # Skip tags field and its multi-line value
            if [[ "$line" =~ ^tags: ]]; then
                skip_tags_block=true
                continue
            fi
            # If inside a tags block, skip indented lines or array notation
            if $skip_tags_block; then
                if [[ "$line" =~ ^[[:space:]] || "$line" == "["* || "$line" == "]"* ]]; then
                    continue
                else
                    skip_tags_block=false
                fi
            fi
        fi

        echo "$line"
    done < "$src_file"
}

# ─── Generate Claude Code Agent Markdown ──────────────────────────────────────
generate_output() {
    local name="$1"
    local description="$2"
    local model="$3"
    local tools_csv="$4"
    local body="$5"
    local skills="$6"

    # Start YAML frontmatter
    echo "---"

    # Name
    if [[ -n "$name" ]]; then
        echo "name: ${name}"
    fi

    # Description — use folded scalar for multi-line or long descriptions
    if [[ -n "$description" ]]; then
        if [[ ${#description} -gt 80 ]] || [[ "$description" == *$'\n'* ]]; then
            echo "description: >"
            # Wrap at ~78 chars, indent with 2 spaces
            echo "$description" | fold -s -w 78 | sed 's/^/  /'
        else
            echo "description: \"${description}\""
        fi
    fi

    # Tools — omit if wildcard
    if [[ -n "$tools_csv" && "$tools_csv" != "__WILDCARD__" ]]; then
        echo "tools: ${tools_csv}"
    fi

    # Model — omit if empty (inherit)
    if [[ -n "$model" ]]; then
        echo "model: ${model}"
    fi

    # Skills — omit if wildcard or empty
    if [[ -n "$skills" && "$skills" != "__WILDCARD__" ]]; then
        echo "skills:"
        IFS=',' read -ra skill_list <<< "$skills"
        for skill in "${skill_list[@]}"; do
            # Trim whitespace
            skill=$(echo "$skill" | xargs)
            echo "  - ${skill}"
        done
    fi

    echo "---"

    # Body
    if [[ -n "$body" ]]; then
        echo ""
        echo "$body"
    fi
}

# ─── Convert JSON Agent ──────────────────────────────────────────────────────
convert_json() {
    local input_file="$1"
    local filename
    filename=$(basename "$input_file")

    info "Converting JSON: ${C_BOLD}${filename}${C_RESET}"

    # Extract fields with jq
    local name description model tools_json prompt
    name=$(jq -r '.name // empty' "$input_file")
    description=$(jq -r '.description // empty' "$input_file")
    model=$(jq -r '.model // empty' "$input_file")
    tools_json=$(jq -c '.tools // []' "$input_file")
    prompt=$(jq -r '.prompt // empty' "$input_file")

    # Check for dropped fields and warn
    local has_resources has_hooks has_allowed has_mcp has_aliases has_settings has_legacy has_welcome has_include_mcp has_include_powers
    has_resources=$(jq 'has("resources")' "$input_file")
    has_hooks=$(jq 'has("hooks")' "$input_file")
    has_allowed=$(jq 'has("allowedTools")' "$input_file")
    has_mcp=$(jq 'has("mcpServers")' "$input_file")
    has_aliases=$(jq 'has("toolAliases")' "$input_file")
    has_settings=$(jq 'has("toolsSettings")' "$input_file")
    has_legacy=$(jq 'has("useLegacyMcpJson")' "$input_file")
    has_welcome=$(jq 'has("welcomeMessage")' "$input_file")

    # Convert resources to @file references (handled below, not dropped)

    [[ "$has_hooks" == "true" ]] && { warn "  Dropped 'hooks' — different format in Claude Code (see settings.json)"; ((WARNINGS++)) || true; }
    [[ "$has_allowed" == "true" ]] && { warn "  Dropped 'allowedTools' — no equivalent in Claude Code"; ((WARNINGS++)) || true; }
    [[ "$has_mcp" == "true" ]] && { warn "  Dropped 'mcpServers' — must be configured separately in Claude Code"; ((WARNINGS++)) || true; }
    [[ "$has_aliases" == "true" ]] && { warn "  Dropped 'toolAliases' — no equivalent in Claude Code"; ((WARNINGS++)) || true; }
    [[ "$has_settings" == "true" ]] && { warn "  Dropped 'toolsSettings' — no equivalent in Claude Code"; ((WARNINGS++)) || true; }
    [[ "$has_legacy" == "true" ]] && { warn "  Dropped 'useLegacyMcpJson' — Kiro-only field"; ((WARNINGS++)) || true; }
    [[ "$has_welcome" == "true" ]] && { warn "  Dropped 'welcomeMessage' — no equivalent in Claude Code"; ((WARNINGS++)) || true; }

    # Map model
    if [[ -n "$model" ]]; then
        map_model_name "$model"
    else
        _MAPPED_MODEL=""
    fi

    # Map tools
    map_tools_array "$tools_json"

    # Extract skills from mcpServers args
    extract_skills "$input_file"

    # Convert resources to @file references and append to body
    _RESOURCE_REFS=""
    if [[ "$has_resources" == "true" ]]; then
        local resources_json
        resources_json=$(jq -c '.resources // []' "$input_file")
        convert_resources "$resources_json"
    fi

    local body="$prompt"
    if [[ -n "$_RESOURCE_REFS" ]]; then
        if [[ -n "$body" ]]; then
            body+=$'\n\n'
        fi
        body+="$_RESOURCE_REFS"
    fi

    # Generate output to temp file
    generate_output "$name" "$description" "$_MAPPED_MODEL" "$_MAPPED_TOOLS" "$body" "$_EXTRACTED_SKILLS" > "$TMPOUT"
}

# ─── Convert Markdown Agent ──────────────────────────────────────────────────
convert_markdown() {
    local input_file="$1"
    local filename
    filename=$(basename "$input_file")

    info "Converting Markdown: ${C_BOLD}${filename}${C_RESET}"

    # Extract frontmatter and body
    local in_frontmatter=false
    local frontmatter_done=false
    local frontmatter=""
    local body=""
    local delimiter_count=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "---" ]]; then
            ((delimiter_count++))
            if [[ $delimiter_count -eq 1 ]]; then
                in_frontmatter=true
                continue
            elif [[ $delimiter_count -eq 2 ]]; then
                in_frontmatter=false
                frontmatter_done=true
                continue
            fi
        fi

        if $in_frontmatter; then
            frontmatter+="${line}"$'\n'
        elif $frontmatter_done; then
            body+="${line}"$'\n'
        fi
    done < "$input_file"

    # Parse frontmatter fields (simple YAML parsing)
    local name description model tools_raw
    name=$(echo "$frontmatter" | grep -E '^name:' | sed 's/^name:[[:space:]]*//' | tr -d '"' || true)
    description=$(echo "$frontmatter" | grep -E '^description:' | sed 's/^description:[[:space:]]*//' | tr -d '"' || true)
    model=$(echo "$frontmatter" | grep -E '^model:' | sed 's/^model:[[:space:]]*//' | tr -d '"' || true)
    tools_raw=$(echo "$frontmatter" | grep -E '^tools:' | sed 's/^tools:[[:space:]]*//' || true)

    # Check for dropped fields
    local has_include_mcp has_include_powers
    has_include_mcp=$(echo "$frontmatter" | grep -c '^includeMcpJson:' || true)
    has_include_powers=$(echo "$frontmatter" | grep -c '^includePowers:' || true)

    [[ "$has_include_mcp" -gt 0 ]] && { warn "  Dropped 'includeMcpJson' — Kiro-only field"; ((WARNINGS++)) || true; }
    [[ "$has_include_powers" -gt 0 ]] && { warn "  Dropped 'includePowers' — Kiro-only field"; ((WARNINGS++)) || true; }

    # Map model
    if [[ -n "$model" ]]; then
        map_model_name "$model"
    else
        _MAPPED_MODEL=""
    fi

    # Map tools — parse the YAML array format ["tool1", "tool2"]
    _MAPPED_TOOLS=""
    if [[ -n "$tools_raw" ]]; then
        # Convert YAML-style array to JSON array for consistent handling
        local tools_json
        tools_json=$(echo "$tools_raw" | sed 's/\[/[/; s/\]/]/' | jq -c '.' 2>/dev/null || echo '[]')
        map_tools_array "$tools_json"
    fi

    # Strip leading blank lines from body
    body=$(echo "$body" | sed '/./,$!d')

    generate_output "$name" "$description" "$_MAPPED_MODEL" "$_MAPPED_TOOLS" "$body" "" > "$TMPOUT"
}

# ─── Should Skip File ────────────────────────────────────────────────────────
should_skip() {
    local file="$1"
    local basename
    basename=$(basename "$file")

    # Skip backup files
    if [[ "$basename" == *.bak ]]; then
        info "Skipping backup: ${basename}"
        ((SKIPPED++)) || true
        return 0
    fi

    # Skip example files
    if [[ "$basename" == *.example ]]; then
        info "Skipping example: ${basename}"
        ((SKIPPED++)) || true
        return 0
    fi

    return 1
}

# ─── Process a Single File ────────────────────────────────────────────────────
process_file() {
    local input_file="$1"
    local output_dir="$2"
    local dry_run="$3"

    if should_skip "$input_file"; then
        return 0
    fi

    local agent_name=""

    case "$input_file" in
        *.json)
            convert_json "$input_file"
            agent_name=$(jq -r '.name // empty' "$input_file")
            ;;
        *.md)
            convert_markdown "$input_file"
            # Extract name from frontmatter
            agent_name=$(sed -n '/^---$/,/^---$/{ /^name:/{ s/^name:[[:space:]]*//; s/"//g; p; } }' "$input_file")
            ;;
        *)
            warn "Skipping unsupported file type: $(basename "$input_file")"
            ((SKIPPED++)) || true
            return 0
            ;;
    esac

    # Fallback name from filename
    if [[ -z "$agent_name" ]]; then
        agent_name=$(basename "$input_file" | sed 's/\.[^.]*$//')
    fi

    local output_file="${output_dir}/${agent_name}.md"

    if [[ "$dry_run" == "true" ]]; then
        echo -e "${C_DIM}── ${agent_name}.md ──${C_RESET}" >&2
        cat "$TMPOUT"
        echo "" >&2
    else
        mkdir -p "$output_dir"
        cp "$TMPOUT" "$output_file"
        success "Wrote: ${output_file}"
    fi

    # Copy referenced skills from AIM to output skills directory
    if [[ -n "$_EXTRACTED_SKILLS" ]]; then
        # Derive skills dir as sibling of agents dir (e.g. ~/.claude/skills/)
        local skills_dir
        skills_dir="$(dirname "$output_dir")/skills"
        copy_skills "$_EXTRACTED_SKILLS" "$skills_dir" "$dry_run"
    fi

    ((CONVERTED++)) || true
}

# ─── Usage ────────────────────────────────────────────────────────────────────
usage() {
    cat <<'EOF'
Usage: kiro-to-claude-agent.sh [OPTIONS] <input-file-or-directory>

Convert Kiro agent definitions (.json or .md) to Claude Code agent format.

Options:
  -o, --output DIR    Output directory (default: ~/.claude/agents/)
  -n, --dry-run       Print to stdout instead of writing files
  -h, --help          Show this help message
  -v, --version       Show version

Examples:
  # Convert a single JSON agent
  kiro-to-claude-agent.sh ~/.kiro/agents/my-agent.json

  # Convert all agents in a directory
  kiro-to-claude-agent.sh ~/.kiro/agents/

  # Dry-run preview
  kiro-to-claude-agent.sh --dry-run ~/.kiro/agents/my-agent.json

  # Output to custom directory
  kiro-to-claude-agent.sh -o .claude/agents/ ~/.kiro/agents/
EOF
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    local output_dir="$DEFAULT_OUTPUT_DIR"
    local dry_run="false"
    local input_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            -n|--dry-run)
                dry_run="true"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -v|--version)
                echo "kiro-to-claude-agent.sh v${VERSION}"
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                input_path="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$input_path" ]]; then
        error "No input file or directory specified"
        usage
        exit 1
    fi

    # Check dependencies
    if ! command -v jq &>/dev/null; then
        error "Required dependency 'jq' not found. Install with: brew install jq"
        exit 1
    fi

    # Process input
    if [[ -d "$input_path" ]]; then
        info "Processing directory: ${C_BOLD}${input_path}${C_RESET}"
        echo "" >&2
        local found=0
        for file in "$input_path"/*.json "$input_path"/*.md; do
            [[ -f "$file" ]] || continue
            process_file "$file" "$output_dir" "$dry_run"
            ((found++)) || true
            echo "" >&2
        done
        if [[ $found -eq 0 ]]; then
            error "No .json or .md files found in ${input_path}"
            exit 1
        fi
    elif [[ -f "$input_path" ]]; then
        process_file "$input_path" "$output_dir" "$dry_run"
    else
        error "Input not found: ${input_path}"
        exit 1
    fi

    # Summary
    echo "" >&2
    echo -e "${C_BOLD}── Summary ──${C_RESET}" >&2
    echo -e "  Agents:    ${C_GREEN}${CONVERTED}${C_RESET}" >&2
    echo -e "  Skills:    ${C_GREEN}${SKILLS_COPIED}${C_RESET}" >&2
    echo -e "  Skipped:   ${C_DIM}${SKIPPED}${C_RESET}" >&2
    echo -e "  Warnings:  ${C_YELLOW}${WARNINGS}${C_RESET}" >&2
}

main "$@"
