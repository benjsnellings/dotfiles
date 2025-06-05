# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains dotfiles managed by [Chezmoi](https://www.chezmoi.io/), a dotfile manager that helps keep configuration files synchronized across multiple machines. The dotfiles primarily configure:

- ZSH shell environment with Oh-My-ZSH
- Git configuration
- Tmux terminal multiplexer
- Vim, Helix, and Sublime Text editors
- Amazon-specific development tools
- Keyboard customization via Karabiner (macOS)

## Structure and Organization

- `.zsh/` - Contains modular ZSH configuration files
  - `01-environment.zsh` - Base environment variables
  - `03-amazon.zsh.tmpl` - Amazon-specific configurations (templated)
  - `zsh_alias.zsh` - Shell aliases
  - `zsh_functions.zsh` - Shell functions
- `.config/` - XDG config directory
  - `chezmoi/chezmoi.toml` - Chezmoi configuration
  - `helix/config.toml` - Helix editor configuration
  - `karabiner/` - Keyboard customization for macOS
  - `starship.toml.tmpl` - Starship prompt configuration (templated)
- Various dotfiles in the root directory (`.vimrc`, `.tmux.conf`, etc.)

## Important Templating Context

Chezmoi uses templates (`.tmpl` files) to customize configurations based on the host system:

- Files with `.tmpl` extension contain Go template directives
- Different configurations are applied for macOS vs Linux environments
- Amazon-specific configurations are conditionally included

## Working with Chezmoi

When making changes to this repository, follow these Chezmoi workflows:

### Apply Changes

To apply changes from the repository to the actual dotfiles:

```bash
chezmoi apply
```

### Add a New Dotfile

To add a new dotfile to be managed by Chezmoi:

```bash
chezmoi add ~/.example_config
```

### Edit an Existing Dotfile

To edit a file managed by Chezmoi:

```bash
chezmoi edit ~/.example_config
```

### Commit Changes

The repository is configured for auto-versioning, but you can manually commit changes:

```bash
cd ~/.local/share/chezmoi
git add .
git commit -m "Update description"
git push
```

## Amazon-Specific Development

This repository contains numerous Amazon-specific configurations and helper functions for:

- Brazil build system (br, bb, etc.)
- AWS credential management
- Account switching between different AWS environments
- Developer authentication (mwinit, kinit)
- Unison synchronization for development environments

## Key Configuration Features

- **Tmux**: Uses Control+a as prefix, has vim-style navigation
- **Git**: Includes numerous aliases and helper functions
- **ZSH**: Customized with Starship prompt and productivity enhancements
- **Keyboard**: Karabiner configuration for key remapping on macOS