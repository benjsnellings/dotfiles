# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Dotfiles managed by [chezmoi](https://www.chezmoi.io/). The **source directory** (this repo at `~/.local/share/chezmoi`) declares the desired state of the home directory. Chezmoi computes the **target state** from source files + config + template data, then applies changes to the **destination directory** (`~`).

Configures: ZSH/Oh-My-ZSH, Git, Tmux, Vim, Helix, Sublime Text, Starship prompt, Karabiner (macOS), and Amazon internal dev tools.

## Chezmoi Essentials

### Source-to-Target Name Mapping

Chezmoi transforms source filenames to target filenames by stripping prefixes/suffixes:

| Prefix | Effect | Example |
|--------|--------|---------|
| `dot_` | Adds leading `.` | `dot_vimrc` → `.vimrc` |
| `private_` | Sets permissions 0600/0700 | `private_dot_config/` → `.config/` |
| `executable_` | Sets +x permission | `executable_script.sh` → `script.sh` |
| `run_` | Execute as script (not installed) | `run_install.sh` → runs during apply |
| `modify_` | Modify existing file via stdin | `modify_dot_bashrc` → modifies `.bashrc` |
| `create_` | Create only if absent | `create_dot_env` → `.env` (if missing) |
| `remove_` | Delete target | `remove_dot_old` → removes `.old` |
| `symlink_` | Create symlink | `symlink_dot_link` → `.link` symlink |
| `exact_` | Remove unmanaged children (dirs) | `exact_dot_config/` → strict sync |
| `encrypted_` | Decrypt during apply | Stored encrypted in source |
| `readonly_` | Remove write permissions | Target is read-only |
| `empty_` | Preserve empty files | Normally empty files are skipped |

**Suffix:** `.tmpl` triggers Go template processing before applying.

**Prefix order matters.** For files: `encrypted_` → `private_` → `readonly_` → `empty_` → `executable_` → `dot_`. For scripts: `run_` → `once_`/`onchange_` → `before_`/`after_`.

**Execution order:** Chezmoi applies actions in ASCII order of target name.

### Special Files

| File | Purpose |
|------|---------|
| `.chezmoidata.json` | Template data (this repo sets `devspace: "true"`) |
| `.chezmoiignore` | Patterns to exclude from target state (supports templates) |
| `.chezmoiremove` | Patterns for files to remove from destination |
| `.chezmoiexternal.<fmt>` | External files/archives to fetch |
| `.chezmoiroot` | Override source directory root |
| `.chezmoiversion` | Minimum chezmoi version requirement |

### Templates

Files ending in `.tmpl` use Go's `text/template` syntax plus [sprig](http://masterminds.github.io/sprig/) functions.

**Common template variables in this repo:**
- `.chezmoi.os` — `"darwin"` or `"linux"` (primary conditional)
- `.chezmoi.arch` — CPU architecture
- `.devspace` — `"true"` (set in `.chezmoidata.json`)

**Useful chezmoi template functions:**
- `output "cmd" "args"` — capture command output
- `lookPath "binary"` — find executable path (empty if not found)
- `fromJson`, `toJson`, `fromYaml`, `toYaml`, `fromToml`, `toToml` — format conversion
- `include "path"`, `includeTemplate "path"` — compose templates
- `stat "path"`, `glob "pattern"` — filesystem queries

### Config (`~/.config/chezmoi/chezmoi.toml`)

```toml
[git]
    autoCommit = true   # Auto-commits after chezmoi add/edit
    autoPush = true     # Auto-pushes after auto-commit

[template]
    options = ["missingkey=zero"]  # Missing keys → zero value (not error)
```

### Common Commands

```bash
chezmoi apply                    # Apply source state to home directory
chezmoi add ~/.example           # Add file to source state
chezmoi edit ~/.example          # Edit source file, then apply
chezmoi diff                     # Preview changes before applying
chezmoi cd                       # cd into source directory
chezmoi data                     # Show template data
chezmoi execute-template < file  # Test template rendering
chezmoi cat ~/.example           # Show what chezmoi would write
chezmoi managed                  # List all managed files
chezmoi unmanaged                # List unmanaged files in home
chezmoi forget ~/.example        # Stop managing a file (keeps target)
```

## Architecture: ZSH Startup Flow

`dot_zshrc.tmpl` → `~/.zshrc` sources all files in `~/.zsh/` alphabetically:

1. `01-environment.zsh` — Oh-My-ZSH bootstrap, plugins (git, sudo, docker, zsh-syntax-highlighting), theme
2. `03-amazon.zsh.tmpl` — Amazon paths, `ada_*` credential functions, SSH agent, auth helpers
3. `04-paths.zsh` — PATH additions, zfunc directory
4. `50-fzf.sh` — Fuzzy finder initialization
5. `executable_51-tmux.sh` — Tmux session aliases
6. `90-bitwarden.zsh` — Bitwarden CLI unlock function
7. `zsh_alias.zsh.tmpl` — Git aliases, Brazil/EDA build aliases, chezmoi shortcuts

After sourcing `~/.zsh/*`, `dot_zshrc.tmpl` conditionally adds macOS or Linux paths, runs `chezmoi git pull` for auto-updates, activates `mise`, starts ssh-agent, and lazy-loads NVM.

## Platform Branching

Templates branch on `.chezmoi.os`:
- **macOS** (`darwin`): Homebrew paths, Sublime Text path, Karabiner config, finch aliases, `gh auth git-credential` helper
- **Linux**: AWS EC2 metadata disabled, DevDesktop-specific config, different credential helper paths

## Key Dotfile Behaviors

- **Tmux**: Prefix is `Ctrl+a`, vim-style pane navigation (`Ctrl+hjkl`), plugins via TPM (resurrect, continuum)
- **Git**: GPG signing enabled, LFS configured, `dag` alias for colored graph log, 2GB HTTP buffer
- **Vim**: vim-plug manager, NerdTree, fzf integration, surround, peekaboo
- **Starship**: Prompt with git status, disabled container/kotlin/java modules

## Auto-Update on Shell Startup

Every new ZSH session runs:
```bash
chezmoi git pull -- --autostash --rebase && chezmoi diff --pager cat
```
Combined with `autoCommit`/`autoPush` in config, this keeps dotfiles synchronized across machines.
