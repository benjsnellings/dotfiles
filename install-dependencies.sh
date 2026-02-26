#!/bin/bash
# install-dependencies.sh
# Cross-platform dependency installation script for dotfiles
# Supports macOS (Homebrew) and Linux (apt/yum)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false
SKIP_AMAZON=false
INTERACTIVE=true

# Platform detection
detect_platform() {
    case "$(uname -s)" in
        Darwin)
            PLATFORM="macos"
            PKG_MANAGER="brew"
            ;;
        Linux)
            PLATFORM="linux"
            if command -v apt-get &> /dev/null; then
                PKG_MANAGER="apt"
            elif command -v yum &> /dev/null; then
                PKG_MANAGER="yum"
            else
                echo -e "${RED}Error: No supported package manager found (apt or yum)${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Error: Unsupported platform $(uname -s)${NC}"
            exit 1
            ;;
    esac
    echo -e "${BLUE}Detected platform: $PLATFORM (package manager: $PKG_MANAGER)${NC}"
}

# Helper functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

install_package() {
    local package=$1
    local package_name=${2:-$package}

    if check_command "$package"; then
        success "$package_name is already installed"
        return 0
    fi

    info "Installing $package_name..."

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Would install: $package"
        return 0
    fi

    case $PKG_MANAGER in
        brew)
            brew install "$package" || error "Failed to install $package_name"
            ;;
        apt)
            sudo apt-get update -qq && sudo apt-get install -y "$package" || error "Failed to install $package_name"
            ;;
        yum)
            sudo yum install -y "$package" || error "Failed to install $package_name"
            ;;
    esac

    success "$package_name installed"
}

install_with_curl() {
    local url=$1
    local name=$2

    info "Installing $name via curl..."

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Would run: curl -fsSL $url | sh"
        return 0
    fi

    curl -fsSL "$url" | sh || error "Failed to install $name"
    success "$name installed"
}

# Core shell environment
install_shell_tools() {
    echo ""
    info "=== Installing Core Shell Environment ==="

    # ZSH
    install_package "zsh" "ZSH shell"

    # Oh-My-ZSH
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing Oh-My-ZSH..."
        if [ "$DRY_RUN" = false ]; then
            RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || error "Failed to install Oh-My-ZSH"
            success "Oh-My-ZSH installed"
        else
            echo "  [DRY-RUN] Would install Oh-My-ZSH"
        fi
    else
        success "Oh-My-ZSH is already installed"
    fi

    # ZSH Syntax Highlighting
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        info "Installing zsh-syntax-highlighting..."
        if [ "$DRY_RUN" = false ]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
                "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" || \
                error "Failed to install zsh-syntax-highlighting"
            success "zsh-syntax-highlighting installed"
        else
            echo "  [DRY-RUN] Would install zsh-syntax-highlighting"
        fi
    else
        success "zsh-syntax-highlighting is already installed"
    fi

    # Starship
    if ! check_command "starship"; then
        install_with_curl "https://starship.rs/install.sh" "Starship"
    else
        success "Starship is already installed"
    fi

    # FZF
    if [ ! -d "$HOME/.fzf" ]; then
        info "Installing FZF..."
        if [ "$DRY_RUN" = false ]; then
            git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" || error "Failed to clone FZF"
            "$HOME/.fzf/install" --all --no-bash --no-fish || error "Failed to install FZF"
            success "FZF installed"
        else
            echo "  [DRY-RUN] Would install FZF"
        fi
    else
        success "FZF is already installed"
    fi

    # Tmux
    install_package "tmux" "Tmux"

    # TPM (Tmux Plugin Manager)
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        info "Installing TPM (Tmux Plugin Manager)..."
        if [ "$DRY_RUN" = false ]; then
            git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" || error "Failed to install TPM"
            success "TPM installed (run 'prefix + I' in tmux to install plugins)"
        else
            echo "  [DRY-RUN] Would install TPM"
        fi
    else
        success "TPM is already installed"
    fi
}

# Editors
install_editors() {
    echo ""
    info "=== Installing Editors ==="

    # Vim
    install_package "vim" "Vim"

    # Vim-plug
    if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
        info "Installing vim-plug..."
        if [ "$DRY_RUN" = false ]; then
            curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
                https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || \
                error "Failed to install vim-plug"
            success "vim-plug installed (run :PlugInstall in vim)"
        else
            echo "  [DRY-RUN] Would install vim-plug"
        fi
    else
        success "vim-plug is already installed"
    fi

    # Helix
    if ! check_command "helix" && ! check_command "hx"; then
        if [ "$PLATFORM" = "macos" ]; then
            install_package "helix" "Helix editor"
        else
            warning "Helix installation on Linux may require snap or building from source"
            info "See: https://docs.helix-editor.com/install.html"
        fi
    else
        success "Helix is already installed"
    fi
}

# Development tools
install_dev_tools() {
    echo ""
    info "=== Installing Development Tools ==="

    # Git
    install_package "git" "Git"

    # Git LFS
    if ! check_command "git-lfs"; then
        if [ "$PLATFORM" = "macos" ]; then
            install_package "git-lfs" "Git LFS"
        else
            warning "Git LFS may need to be installed from git-lfs.github.com"
        fi
    else
        success "Git LFS is already installed"
    fi

    # GitHub CLI
    if ! check_command "gh"; then
        if [ "$PLATFORM" = "macos" ]; then
            install_package "gh" "GitHub CLI"
        elif [ "$PKG_MANAGER" = "apt" ]; then
            info "Adding GitHub CLI repository..."
            if [ "$DRY_RUN" = false ]; then
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y gh
                success "GitHub CLI installed"
            else
                echo "  [DRY-RUN] Would install GitHub CLI"
            fi
        else
            install_package "gh" "GitHub CLI"
        fi
    else
        success "GitHub CLI is already installed"
    fi

    # Mise
    if ! check_command "mise"; then
        install_with_curl "https://mise.run" "Mise"
    else
        success "Mise is already installed"
    fi

    # NVM
    if [ ! -d "$HOME/.nvm" ]; then
        if [ "$INTERACTIVE" = true ]; then
            read -p "Install NVM (Node Version Manager)? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                install_with_curl "https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh" "NVM"
            fi
        fi
    else
        success "NVM is already installed"
    fi

    # Rustup
    if ! check_command "rustup"; then
        if [ "$INTERACTIVE" = true ]; then
            read -p "Install Rustup (Rust toolchain manager)? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                info "Installing Rustup..."
                if [ "$DRY_RUN" = false ]; then
                    curl -fsSL https://sh.rustup.rs | sh -s -- -y || error "Failed to install Rustup"
                    # shellcheck disable=SC1091
                    source "$HOME/.cargo/env"
                    success "Rustup installed"
                else
                    echo "  [DRY-RUN] Would install Rustup"
                fi
            fi
        fi
    else
        success "Rustup is already installed"
        # Ensure cargo is in PATH for subsequent installs (e.g., delta)
        # shellcheck disable=SC1091
        [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
    fi

    # Delta (git diff tool) - installed via cargo
    if ! check_command "delta"; then
        if check_command "cargo"; then
            if [ "$INTERACTIVE" = true ]; then
                read -p "Install delta (git diff tool) via cargo? [y/N] " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    info "Installing delta via cargo..."
                    if [ "$DRY_RUN" = false ]; then
                        cargo install git-delta || error "Failed to install delta"
                        success "delta installed"
                    else
                        echo "  [DRY-RUN] Would install delta via cargo"
                    fi
                fi
            fi
        else
            warning "delta requires cargo (Rust). Install Rustup first to enable delta installation"
        fi
    else
        success "delta is already installed"
    fi

    # Chezmoi
    if ! check_command "chezmoi"; then
        install_with_curl "https://get.chezmoi.io" "Chezmoi"
    else
        success "Chezmoi is already installed"
    fi

    # kdiff3
    if ! check_command "kdiff3"; then
        if [ "$PLATFORM" = "macos" ]; then
            if [ "$INTERACTIVE" = true ]; then
                read -p "Install kdiff3 (merge tool)? [y/N] " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    install_package "kdiff3" "kdiff3"
                fi
            fi
        else
            install_package "kdiff3" "kdiff3"
        fi
    else
        success "kdiff3 is already installed"
    fi
}

# CLI utilities
install_cli_utils() {
    echo ""
    info "=== Installing CLI Utilities ==="

    install_package "jq" "jq (JSON processor)"
    install_package "curl" "curl"
    install_package "less" "less"

    # Bitwarden CLI
    if ! check_command "bw"; then
        if [ "$INTERACTIVE" = true ]; then
            read -p "Install Bitwarden CLI? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if check_command "npm"; then
                    info "Installing Bitwarden CLI via npm..."
                    if [ "$DRY_RUN" = false ]; then
                        npm install -g @bitwarden/cli || error "Failed to install Bitwarden CLI"
                        success "Bitwarden CLI installed"
                    else
                        echo "  [DRY-RUN] Would install Bitwarden CLI via npm"
                    fi
                else
                    warning "npm not found. Please install Node.js first"
                fi
            fi
        fi
    else
        success "Bitwarden CLI is already installed"
    fi
}

# macOS-specific
install_macos_specific() {
    if [ "$PLATFORM" != "macos" ]; then
        return 0
    fi

    echo ""
    info "=== Installing macOS-Specific Tools ==="

    # Homebrew
    if ! check_command "brew"; then
        info "Installing Homebrew..."
        if [ "$DRY_RUN" = false ]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || \
                error "Failed to install Homebrew"
            success "Homebrew installed"
        else
            echo "  [DRY-RUN] Would install Homebrew"
        fi
    else
        success "Homebrew is already installed"
    fi

    # Karabiner-Elements
    if [ "$INTERACTIVE" = true ]; then
        read -p "Install Karabiner-Elements (keyboard customization)? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ "$DRY_RUN" = false ]; then
                brew install --cask karabiner-elements || error "Failed to install Karabiner-Elements"
                success "Karabiner-Elements installed"
            else
                echo "  [DRY-RUN] Would install Karabiner-Elements"
            fi
        fi
    fi

    # Sublime Text
    if [ "$INTERACTIVE" = true ]; then
        read -p "Install Sublime Text? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ "$DRY_RUN" = false ]; then
                brew install --cask sublime-text || error "Failed to install Sublime Text"
                success "Sublime Text installed"
            else
                echo "  [DRY-RUN] Would install Sublime Text"
            fi
        fi
    fi

    # Finch (Docker alternative)
    if [ "$INTERACTIVE" = true ]; then
        read -p "Install Finch (Docker alternative)? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ "$DRY_RUN" = false ]; then
                brew install --cask finch || error "Failed to install Finch"
                success "Finch installed"
            else
                echo "  [DRY-RUN] Would install Finch"
            fi
        fi
    fi
}

# Amazon-internal tools
install_amazon_tools() {
    if [ "$SKIP_AMAZON" = true ]; then
        warning "Skipping Amazon-internal tools (--skip-amazon flag)"
        return 0
    fi

    echo ""
    info "=== Amazon-Internal Tools ==="
    warning "Amazon-internal tools require Amazon network access and credentials"

    if [ "$INTERACTIVE" = true ]; then
        read -p "Install Amazon-internal tools? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Skipping Amazon-internal tools"
            return 0
        fi
    fi

    # Check for Toolbox
    if ! check_command "toolbox"; then
        warning "Toolbox not found. Install from: https://toolbox.corp.amazon.com/"
    else
        success "Toolbox is already installed"
    fi

    # Check for Claude Code
    if ! check_command "claude"; then
        info "Claude Code can be installed via:"
        echo "  curl -fsSL https://claude.ai/install.sh | bash"
    else
        success "Claude Code is already installed"
    fi

    # Check for Brazil
    if ! check_command "brazil-build"; then
        warning "Brazil build system not found. This is typically pre-installed on Amazon developer machines"
    else
        success "Brazil build system is available"
    fi

    # Check for ADA
    if ! check_command "ada"; then
        warning "ADA not found. Install via: toolbox install ada"
    else
        success "ADA is available"
    fi

    # Check for mwinit
    if ! check_command "mwinit"; then
        warning "mwinit not found. This is typically pre-installed on Amazon developer machines"
    else
        success "mwinit is available"
    fi

    info "For more Amazon tools, see DEPENDENCIES.md under 'Amazon-Internal Tools'"
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Dotfiles Dependency Installation${NC}"
    echo -e "${BLUE}========================================${NC}"

    detect_platform

    if [ "$DRY_RUN" = true ]; then
        warning "DRY-RUN mode enabled - no actual installations will be performed"
    fi

    # Run installation functions
    install_shell_tools
    install_editors
    install_dev_tools
    install_cli_utils
    install_macos_specific
    install_amazon_tools

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    info "Next steps:"
    echo "  1. Run 'vim +PlugInstall +qall' to install Vim plugins"
    echo "  2. Start tmux and press 'prefix + I' to install tmux plugins"
    echo "  3. Configure Git: git config --global user.name 'Your Name'"
    echo "  4. Configure Git: git config --global user.email 'your@email.com'"
    echo "  5. Run 'chezmoi init' to initialize your dotfiles"
    echo ""
    info "See DEPENDENCIES.md for complete documentation"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-amazon)
            SKIP_AMAZON=true
            shift
            ;;
        --non-interactive)
            INTERACTIVE=false
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run           Show what would be installed without installing"
            echo "  --skip-amazon       Skip Amazon-internal tools"
            echo "  --non-interactive   Run without prompts (skip optional tools)"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                       # Interactive installation"
            echo "  $0 --dry-run             # Preview what would be installed"
            echo "  $0 --skip-amazon         # Skip Amazon tools"
            echo "  $0 --non-interactive     # Install only required tools"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run main function
main
