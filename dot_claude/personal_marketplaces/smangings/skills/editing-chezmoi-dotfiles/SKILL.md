---
name: editing-chezmoi-dotfiles
description: Correctly edit, create, and commit dotfiles managed by chezmoi. Use whenever modifying or creating any file under the home directory (~) that could be chezmoi-managed — shell config (.zshrc, .zsh/*, .zprofile), git config (.gitconfig), tmux (.tmux.conf), vim/helix, starship, .mcp.json, anything under ~/.claude/ (CLAUDE.md, agents, skills, marketplaces, settings), or anything the user calls a "dotfile" or asks to "add/commit with chezmoi". Prevents three specific failures — (1) editing the applied target so the change is silently reverted on next apply and never reaches the dotfiles repo, (2) destroying a Go template with a blind `chezmoi add` that overwrites the .tmpl source with rendered output, and (3) losing changes because a raw source edit was never captured into the git-backed source repo. The user prefers chezmoi's autoCommit/autoPush to commit changes.
---

# Editing Chezmoi Dotfiles

Dotfiles are managed by chezmoi. The chezmoi **source** (`~/.local/share/chezmoi`,
a git repo) is the source of truth; the files under `~` are **applied targets**
generated from it. Get this wrong and the change is either reverted on the next
`chezmoi apply`, never committed to the repo, or clobbers a template.

## Setup facts (this machine)

- Source dir: `~/.local/share/chezmoi` (the dotfiles git repo).
- Config `~/.config/chezmoi/chezmoi.toml`: **`autoCommit = true`, `autoPush = true`**.
  A `chezmoi` **source-mutating command** (`add`, `re-add`, `edit`, `chattr`)
  auto-commits with chezmoi's default message AND pushes. A raw editor write to a
  source file does NOT auto-commit — it must be captured by such a command.
- Templates (`.tmpl` source, rendered per-machine): include `.zshrc`, `.gitconfig`,
  `.mcp.json`, `.zsh/03-amazon.zsh`, `.zsh/zsh_alias.zsh`, `.config/starship.toml`.
  Confirm per file with step 1 rather than trusting this list.

## Step 1 — Is the file managed, and is it a template?

```bash
chezmoi source-path <target>        # e.g. ~/.zshrc  or  ~/.claude/CLAUDE.md
```

- Errors ("not in source state") → **unmanaged**. Edit directly with normal file
  tools; chezmoi is not involved. Done.
- Prints a source path → **managed**. If the path ends in **`.tmpl`** it is a
  template → use path B. Otherwise → path A.

## Path A — Managed, NOT a template

Edit, then capture with a source-mutating command so autoCommit fires:

```bash
# edit the target (~/.foo) OR the source; either works for non-templates
chezmoi re-add <target>             # captures into source, auto-commits + pushes
```

`re-add` is preferred over `add` because it refuses to clobber templates — safe
even if the earlier check was wrong. Verify with `chezmoi diff <target>` (empty
== source and target match).

## Path B — Managed template (`.tmpl` source)

The source contains Go template logic (`{{ if ... }}`, `{{ .chezmoi.os }}`).
NEVER `chezmoi add` a template — it overwrites the `.tmpl` with rendered output
and destroys the logic.

```bash
# 1. Edit the SOURCE path from step 1 with normal file tools, preserving all
#    template conditionals. Do NOT flatten them into rendered output.
# 2. Apply and sanity-check the render:
chezmoi apply <target>
chezmoi diff  <target>              # empty == applied cleanly
# 3. Capture into the repo (autoCommit + push). re-add is template-safe:
chezmoi re-add <target>
```

## Adding a NEW file to management

```bash
chezmoi add <target>                # imports plain file, auto-commits + pushes
```

For a new file that should be a template, `chezmoi add` first, then rename the
source to add the `.tmpl` suffix and edit in the template logic (or use
`chezmoi add --template`).

## Committing

The user prefers chezmoi's **autoCommit/autoPush** over the `smangings:commit`
agent for dotfiles. The `chezmoi add`/`re-add` in the steps above already commits
(default message) and pushes — no separate commit step. Note this can also sweep
any other changes already staged in the source repo into the same commit; that
is accepted here.

## Hazards — do NOT do these

- **Never `chezmoi add` a template** — use `re-add` (template-safe) or edit the
  source directly.
- **Never edit an applied target and leave it** without a `re-add`/`add` — the
  change is not in the repo and may be reverted on next apply.
- **Never assume unmanaged** — always run `chezmoi source-path` first. Much of
  `~` is managed, including `~/.claude/*` and this marketplace itself.

## Quick reference

| Command | Purpose |
|---|---|
| `chezmoi source-path <t>` | Map target → source; errors if unmanaged; `.tmpl` = template |
| `chezmoi diff <t>` | Preview / verify target vs. source |
| `chezmoi apply <t>` | Render source → target |
| `chezmoi re-add <t>` | Capture managed file into source (template-safe); autoCommits |
| `chezmoi add <t>` | Import a NEW file into source; autoCommits |
| `chezmoi cat <t>` | Show rendered output without applying |
| `chezmoi managed` | List all managed files |
