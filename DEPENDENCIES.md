# Dependencies

This document lists all dependencies required for this dotfiles configuration. Dependencies are organized by category, with platform-specific and Amazon-internal tools listed separately.

## Core Shell Environment

| Tool | Description | Required |
|------|-------------|----------|
| **zsh** | Z shell - primary shell | ✓ |
| **oh-my-zsh** | ZSH framework with plugins | ✓ |
| **starship** | Cross-shell prompt with customizations | ✓ |
| **fzf** | Fuzzy finder for command history and file search | ✓ |
| **tmux** | Terminal multiplexer | ✓ |
| **delta** | git diffing tool | ✓ |

### ZSH Plugins (via Oh-My-ZSH)
- `git` - Git aliases and completions
- `sudo` - Prefix commands with sudo
- `docker` - Docker autocompletion
- `zsh-syntax-highlighting` - Command syntax highlighting

### Tmux Plugins (via TPM)
- `tmux-plugins/tpm` - Tmux Plugin Manager
- `tmux-plugins/tmux-resurrect` - Session persistence
- `tmux-plugins/tmux-continuum` - Continuous session saving

## Editors

| Tool | Description | Required |
|------|-------------|----------|
| **vim** | Text editor with vim-plug plugin manager | ✓ |
| **helix** | Modern modal terminal editor | Recommended |

### Vim Plugins (via vim-plug)
- `preservim/nerdtree` - File tree explorer
- `tpope/vim-surround` - Surround text manipulation
- `junegunn/vim-peekaboo` - Register preview
- `junegunn/fzf` - Fuzzy finder integration
- `junegunn/fzf.vim` - FZF Vim integration

## Development Tools

| Tool | Description | Required |
|------|-------------|----------|
| **git** | Version control system | ✓ |
| **git-lfs** | Git Large File Storage | Recommended |
| **gh** | GitHub CLI | Recommended |
| **mise** | Development environment manager | Recommended |
| **nvm** | Node Version Manager | Optional |
| **rustup** | Rust toolchain manager | Optional |
| **cargo** | Rust package manager (installed with rustup) | Optional |
| **chezmoi** | Dotfile manager (this tool itself) | ✓ |
| **kdiff3** | Three-way merge tool for chezmoi conflicts | Recommended |

## CLI Utilities

| Tool | Description | Required |
|------|-------------|----------|
| **jq** | JSON processor | ✓ |
| **curl** | HTTP client | ✓ |
| **less** | Terminal pager | ✓ |
| **bitwarden-cli** | Password manager CLI (bw command) | Optional |

## Security/Authentication

| Tool | Description | Required |
|------|-------------|----------|
| **ssh** | SSH client | ✓ |
| **ssh-agent** | SSH key management | ✓ |
| **gpg** | GPG encryption for git signing | Recommended |

---

## macOS-Specific Dependencies

| Tool | Description | Required |
|------|-------------|----------|
| **homebrew** | Package manager for macOS | ✓ |
| **karabiner-elements** | Keyboard customization tool | Optional |
| **finch** | Docker alternative for macOS | Optional |
| **sublime-text** | GUI text editor | Optional |

### Homebrew-Managed Paths
- Node.js 14: `/opt/homebrew/opt/node@14/bin`
- OpenSSL 1.0.2t: `/usr/local/opt/openssl@1.0.2t/bin`
- GNU getopt: `/usr/local/opt/gnu-getopt/bin`

---

## Linux-Specific Dependencies

No Linux-specific tools beyond the core dependencies listed above. Standard package manager (apt, yum, etc.) required for installation.

---

## Amazon-Internal Tools (Optional)

These tools are specific to Amazon's internal development environment and are only needed if you work at Amazon.

### Build and Development
| Tool | Description |
|------|-------------|
| **brazil-build** | Amazon's build system |
| **brazil-runtime-exec** | Brazil runtime executor |
| **brazil-recursive-cmd** | Multi-package Brazil builds |
| **eda** | EDA build system |

### Authentication and Access
| Tool | Description |
|------|-------------|
| **ada** | AWS credential management |
| **mwinit** | Midway authentication |
| **kinit** | Kerberos authentication |
| **isengardcli** | Isengard CLI |

### Development Tools
| Tool | Description |
|------|-------------|
| **claude-code** | Claude Code CLI with Bedrock integration |
| **toolbox** | Amazon standard development tools installer |
| **builder-mcp** | Builder MCP for internal tools |
| **mcp-registry** | MCP server registry |
| **aim** | AI skills manager |

### Infrastructure and Deployment
| Tool | Description |
|------|-------------|
| **apollo** | Amazon's deployment service |
| **axe** | Amazon cloud desktop tool |
| **wssh** | Amazon SSH proxy for VPN access |
| **unison** | Bidirectional file synchronization |

### Code Management
| Tool | Description |
|------|-------------|
| **cr** | Code review tool (CRUX) |
| **code-search** | Search Amazon's code repositories |

---

## Installation

See `install-dependencies.sh` for an automated installation script that handles:
- Platform detection (macOS vs Linux)
- Core dependencies
- Optional components
- Amazon-internal tools (with `--skip-amazon` flag to skip)

### Quick Start

```bash
# Install all dependencies (interactive prompts)
./install-dependencies.sh

# Preview what would be installed
./install-dependencies.sh --dry-run

# Skip Amazon-internal tools
./install-dependencies.sh --skip-amazon
```

---

## Notes

- **Vim-plug** is automatically installed by the script referenced in `.vimrc`
- **TPM** (Tmux Plugin Manager) is automatically installed by the configuration in `.tmux.conf`
- **Oh-My-ZSH** plugins are managed in `dot_zsh/01-environment.zsh`
- Font requirements: Starship prompt may benefit from a Nerd Font for proper icon display
- Some tools require manual configuration after installation (AWS credentials, SSH keys, etc.)
