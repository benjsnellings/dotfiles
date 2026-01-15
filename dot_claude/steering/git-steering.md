### Git Commit Operations

**ALWAYS delegate git commit operations to the `amzn-commit` agent.**

While you have permissions to run git commands directly, you MUST use the `amzn-commit` agent for all commit-related operations. This ensures consistent, well-formatted commit messages following Conventional Commits specification.

#### Operations requiring amzn-commit
- `git commit` - Creating commits (agent ensures proper message format)
- `git add` + `git commit` - Staging and committing together

#### Operations you CAN run directly
- `git status` - Checking repository state
- `git log` - Viewing commit history
- `git diff` - Viewing changes
- `git branch` - Listing/managing branches

#### How to Use

When the user asks to commit changes, use the Task tool:

```
Task tool with:
  subagent_type: amzn-commit
  prompt: [describe the commit operation and context]
```

The amzn-commit agent will:
1. Check `git status` to understand the changes
2. Review `git diff` to understand what's being committed
3. Create a properly formatted commit message following Conventional Commits
4. Execute the commit

#### Conventional Commits Specification

All commit messages MUST follow the Conventional Commits format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
| Type | When to Use |
|------|-------------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only changes |
| `style` | Changes that don't affect code meaning (formatting, whitespace) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or correcting tests |
| `chore` | Build process, tooling, or auxiliary changes |
| `ci` | CI/CD configuration changes |

**Rules:**
- Use imperative mood ("add" not "added" or "adds")
- Limit subject to 50 characters
- Capitalize subject line
- No period at end of subject
- Wrap body at 72 characters
- Body explains WHAT and WHY, not HOW

#### Commit Message Quality Requirements

The amzn-commit agent MUST ultrathink before creating commit messages:

1. **Deep Analysis**: Thoroughly explore `git diff` output to understand:
   - What files were changed and why
   - The nature of changes (new code, modifications, deletions)
   - Relationships between changed files
   - The intent behind the changes

2. **Context Gathering**:
   - Review recent commit history (`git log`) to match existing style
   - Consider the broader purpose of the changes
   - Identify if changes are part of a larger feature or fix

3. **Message Crafting**:
   - Choose the most accurate type (feat vs fix vs refactor)
   - Write a description that captures the essence of the change
   - Include body text for non-trivial changes explaining the "why"
   - Reference related issues/tickets when applicable

**Example of thorough analysis:**
```
# Bad (surface-level):
chore: Update files

# Good (after ultrathink analysis):
feat(auth): Add session timeout handling for inactive users

Implement automatic session expiration after 30 minutes of inactivity.
Sessions are now tracked with a last-activity timestamp and validated
on each request. This addresses security requirements for PCI compliance.
```