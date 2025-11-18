#!/bin/bash

# tmux-session.sh - Smart tmux session manager with directory-based naming
# Author: Generated via AI assistance
# Version: 1.0.0

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration defaults
DEFAULT_LAYOUT="even-vertical"
CONFIG_DIR="${TMUX_SESSION_CONFIG_DIR:-$HOME/.config/tmux-sessions}"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: tmux-session [OPTIONS] [DIRECTORY] [SESSION_NAME]

Smart tmux session manager that creates sessions with directory-based naming.

ARGUMENTS:
    DIRECTORY      Directory to use for the session (default: current directory)
    SESSION_NAME   Custom name for the session (default: directory name)

OPTIONS:
    -h, --help     Show this help message
    -f, --force    Force recreate session if it exists
    -c, --config   Path to configuration file
    -l, --layout   Layout preset (even-vertical, even-horizontal, main-vertical, tiled)
    -n, --no-split Don't create the split
    -d, --detach   Create session but don't attach
    -v, --version  Show version information

EXAMPLES:
    tmux-session                    # Create session in current dir
    tmux-session ~/projects/myapp   # Create session for specific dir
    tmux-session . production       # Custom name for current dir
    tmux-session -c dev.yml         # Use configuration file

SMART NAMING:
    The script automatically determines session names from:
    1. Custom name (if provided as second argument)
    2. .tmux-session-name file in the directory
    3. package.json name field (for Node.js projects)
    4. Git repository name (if in a git repo)
    5. Directory name (default fallback)

EOF
}

# Function to sanitize session names for tmux compatibility
sanitize_session_name() {
    local name="$1"
    # Replace dots, colons, and spaces with underscores
    # Remove brackets and other special characters
    echo "$name" | tr '.: ' '___' | tr -d '[]{}()' | sed 's/[^a-zA-Z0-9_-]/_/g'
}

# Function to get smart session name
get_session_name() {
    local dir="$1"
    local custom_name="$2"
    local session_name=""

    # Priority 1: Custom name provided
    if [[ -n "$custom_name" ]]; then
        session_name="$custom_name"
    # Priority 2: .tmux-session-name file
    elif [[ -f "$dir/.tmux-session-name" ]]; then
        session_name=$(head -n1 "$dir/.tmux-session-name" 2>/dev/null)
    # Priority 3: package.json for Node projects
    elif [[ -f "$dir/package.json" ]]; then
        session_name=$(grep '"name"' "$dir/package.json" 2>/dev/null | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    # Priority 4: Git repository name
    elif [[ -d "$dir/.git" ]] || git -C "$dir" rev-parse --git-dir > /dev/null 2>&1; then
        session_name=$(basename "$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)")
    fi

    # Default: directory name
    if [[ -z "$session_name" ]]; then
        session_name=$(basename "$dir")
    fi

    # Sanitize the name
    sanitize_session_name "$session_name"
}

# Function to check if tmux is installed
check_dependencies() {
    if ! command -v tmux &> /dev/null; then
        print_message "$RED" "Error: tmux is not installed. Please install tmux first."
        exit 1
    fi
}

# Function to create a new tmux session
create_session() {
    local session_name="$1"
    local work_dir="$2"
    local layout="$3"
    local no_split="$4"

    print_message "$GREEN" "Creating new tmux session: $session_name"
    print_message "$BLUE" "Working directory: $work_dir"

    # Create new detached session
    tmux new-session -d -s "$session_name" -c "$work_dir"

    # Get the first window index (could be 0 or 1 depending on base-index setting)
    local first_window=$(tmux list-windows -t "$session_name" -F '#{window_index}' | head -n1)

    # Create split unless disabled (horizontal split, but layout arranges panes)
    if [[ "$no_split" != "true" ]]; then
        tmux split-window -h -t "$session_name:$first_window" -c "$work_dir"

        # Apply layout
        if [[ -n "$layout" ]]; then
            tmux select-layout -t "$session_name:$first_window" "$layout"
        else
            tmux select-layout -t "$session_name:$first_window" "$DEFAULT_LAYOUT"
        fi
    fi

    # Set pane borders to be more visible
    tmux set-option -t "$session_name" pane-border-style fg=colour240
    tmux set-option -t "$session_name" pane-active-border-style fg=colour117

    print_message "$GREEN" "✓ Session '$session_name' created successfully"
}

# Function to attach to session
attach_session() {
    local session_name="$1"

    if [[ -n "$TMUX" ]]; then
        # If already in tmux, switch to the session
        tmux switch-client -t "$session_name"
    else
        # If not in tmux, attach to the session
        tmux attach-session -t "$session_name"
    fi
}

# Function to parse YAML config (simple parser for our use case)
parse_yaml_config() {
    local config_file="$1"
    local content

    # Read file, remove comments and empty lines
    content=$(grep -v '^[[:space:]]*#' "$config_file" | grep -v '^[[:space:]]*$')

    echo "$content"
}

# Function to create window with panes from config
create_window_from_config() {
    local session_name="$1"
    local window_name="$2"
    local window_index="$3"
    local work_dir="$4"
    shift 4
    local panes=("$@")

    if [[ $window_index -eq 0 ]]; then
        # Rename the first window
        tmux rename-window -t "$session_name:0" "$window_name"
    else
        # Create new window
        tmux new-window -t "$session_name:$window_index" -n "$window_name" -c "$work_dir"
    fi

    # Create panes and run commands
    local pane_index=0
    for pane_cmd in "${panes[@]}"; do
        if [[ $pane_index -eq 0 ]]; then
            # First pane already exists
            if [[ -n "$pane_cmd" ]]; then
                tmux send-keys -t "$session_name:$window_index.0" "$pane_cmd" C-m
            fi
        else
            # Split for additional panes
            tmux split-window -t "$session_name:$window_index" -c "$work_dir"
            if [[ -n "$pane_cmd" ]]; then
                tmux send-keys -t "$session_name:$window_index.$pane_index" "$pane_cmd" C-m
            fi
        fi
        ((pane_index++))
    done

    # Apply tiled layout if more than 2 panes
    if [[ ${#panes[@]} -gt 2 ]]; then
        tmux select-layout -t "$session_name:$window_index" tiled
    elif [[ ${#panes[@]} -eq 2 ]]; then
        tmux select-layout -t "$session_name:$window_index" even-vertical
    fi
}

# Function to load configuration file
load_config() {
    local config_file="$1"
    local session_name="$2"
    local work_dir="$3"

    if [[ ! -f "$config_file" ]]; then
        print_message "$RED" "Error: Configuration file not found: $config_file"
        return 1
    fi

    print_message "$BLUE" "Loading configuration from: $config_file"

    # Parse the YAML file
    local yaml_content
    yaml_content=$(parse_yaml_config "$config_file")

    # Extract root directory if specified
    local config_root
    config_root=$(echo "$yaml_content" | grep '^root:' | sed 's/^root:[[:space:]]*//' | sed 's/~/'$HOME'/g')
    if [[ -n "$config_root" ]]; then
        work_dir="$config_root"
        print_message "$BLUE" "Using root directory from config: $work_dir"
    fi

    # Parse windows
    local in_windows=false
    local in_window=false
    local in_panes=false
    local current_window_name=""
    local window_index=0
    local -a current_panes=()

    while IFS= read -r line; do
        # Check if we're entering windows section
        if [[ "$line" == "windows:" ]]; then
            in_windows=true
            continue
        fi

        if [[ "$in_windows" == true ]]; then
            # Check for new window (starts with "  - name:")
            if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]name: ]]; then
                # Save previous window if exists
                if [[ -n "$current_window_name" ]]; then
                    create_window_from_config "$session_name" "$current_window_name" "$window_index" "$work_dir" "${current_panes[@]}"
                    ((window_index++))
                fi

                # Start new window
                current_window_name=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]name:[[:space:]]*//')
                current_panes=()
                in_window=true
                in_panes=false
                continue
            fi

            # Check for panes section
            if [[ "$line" =~ ^[[:space:]]{4}panes: ]]; then
                in_panes=true
                continue
            fi

            # Parse pane commands (starts with "      -" or "      - command:")
            if [[ "$in_panes" == true ]]; then
                if [[ "$line" =~ ^[[:space:]]{6}-[[:space:]]command: ]]; then
                    local cmd=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]command:[[:space:]]*//')
                    current_panes+=("$cmd")
                elif [[ "$line" =~ ^[[:space:]]{6}- ]]; then
                    local cmd=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//')
                    current_panes+=("$cmd")
                fi
            fi
        fi
    done <<< "$yaml_content"

    # Create last window if exists
    if [[ -n "$current_window_name" ]]; then
        create_window_from_config "$session_name" "$current_window_name" "$window_index" "$work_dir" "${current_panes[@]}"
    fi

    # Select first window
    tmux select-window -t "$session_name:0"

    print_message "$GREEN" "✓ Configuration loaded successfully"
    return 0
}

# Main function
main() {
    local work_dir=""
    local session_name=""
    local force_recreate=false
    local config_file=""
    local layout=""
    local no_split=false
    local detach_mode=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                echo "tmux-session version 1.0.0"
                exit 0
                ;;
            -f|--force)
                force_recreate=true
                shift
                ;;
            -c|--config)
                config_file="$2"
                shift 2
                ;;
            -l|--layout)
                layout="$2"
                shift 2
                ;;
            -n|--no-split)
                no_split=true
                shift
                ;;
            -d|--detach)
                detach_mode=true
                shift
                ;;
            -*)
                print_message "$RED" "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$work_dir" ]]; then
                    work_dir="$1"
                elif [[ -z "$session_name" ]]; then
                    session_name="$1"
                else
                    print_message "$RED" "Too many arguments"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Check dependencies
    check_dependencies

    # Set default work directory to current directory
    if [[ -z "$work_dir" ]]; then
        work_dir="$(pwd)"
    fi

    # Resolve to absolute path
    work_dir=$(cd "$work_dir" 2>/dev/null && pwd || echo "$work_dir")

    # Check if directory exists
    if [[ ! -d "$work_dir" ]]; then
        print_message "$RED" "Error: Directory does not exist: $work_dir"
        exit 1
    fi

    # Get smart session name
    session_name=$(get_session_name "$work_dir" "$session_name")

    # Check if session already exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
        if [[ "$force_recreate" == "true" ]]; then
            print_message "$YELLOW" "Force recreating session: $session_name"
            tmux kill-session -t "$session_name"
        else
            print_message "$BLUE" "Session '$session_name' already exists. Attaching..."
            if [[ "$detach_mode" != "true" ]]; then
                attach_session "$session_name"
            fi
            exit 0
        fi
    fi

    # Create session based on configuration or defaults
    if [[ -n "$config_file" ]]; then
        # Create minimal session first (config will add windows/panes)
        tmux new-session -d -s "$session_name" -c "$work_dir"

        # Load configuration to set up windows and panes
        if ! load_config "$config_file" "$session_name" "$work_dir"; then
            print_message "$RED" "Failed to load configuration"
            tmux kill-session -t "$session_name" 2>/dev/null
            exit 1
        fi
    else
        # Create the session with default layout
        create_session "$session_name" "$work_dir" "$layout" "$no_split"
    fi

    # Attach to session unless in detach mode
    if [[ "$detach_mode" != "true" ]]; then
        attach_session "$session_name"
    else
        print_message "$GREEN" "Session '$session_name' created in detached mode"
        print_message "$BLUE" "Attach with: tmux attach-session -t '$session_name'"
    fi
}

# Run main function
main "$@"