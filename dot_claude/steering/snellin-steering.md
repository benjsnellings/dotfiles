
### Git and Code Review Operations

**ALWAYS delegate git and code review operations to specialized agents.**

#### Git Operations → `smangings:commit` Agent

Use the `smangings:commit` agent (via Task tool) for ALL git operations:
- Committing changes
- Viewing git status, log, diff
- Creating/switching branches
- Staging files
- Managing stash
- Cleaning up [gone] branches

**Do NOT run git commands directly** - always invoke the agent.

#### Code Reviews → `smangings:cr` Agent

Use the `smangings:cr` agent (via Task tool) for ALL CRUX code review operations:
- Creating new code reviews (`cr` command)
- Updating existing CRs
- Addressing reviewer feedback
- Reviewing code changes (local or CRUX URLs)
- Multi-package reviews

#### How to Invoke

```
Task tool with:
  subagent_type: smangings:commit  # for git operations
  OR
  subagent_type: smangings:cr          # for code reviews
  prompt: [describe the operation]
```

#### Examples

| User Request | Agent to Use |
|--------------|--------------|
| "Commit these changes" | `smangings:commit` |
| "Show me git status" | `smangings:commit` |
| "Create a code review" | `smangings:cr` |
| "Address the CR feedback" | `smangings:cr` |
| "Review this CR link" | `smangings:cr` |

### Working with Quip Documents

When working with Quip documents, use the appropriate MCP tool based on your intent:

#### Tool Selection Rules

**ALWAYS use ReadInternalWebsites for read-only operations:**
- Viewing document content
- Reading comments (add `?includeComments=true` to URL)
- Batch reading multiple documents
- Any operation where you only need to retrieve information

**ONLY use QuipEditor when making edits:**
- Creating new Quip documents
- Modifying existing content (append, prepend, replace)
- Restructuring documents (moving sections, updating headings)
- Any operation that changes the document state

#### Examples

**Reading a Quip document (use ReadInternalWebsites):**
```json
{
  "inputs": ["https://quip-amazon.com/ABC123?includeComments=true"]
}
```

**Editing a Quip document (use QuipEditor):**
```json
{
  "documentId": "ABC123",
  "content": "New content to add",
  "format": "markdown",
  "location": 0
}
```

#### Rationale
ReadInternalWebsites is more efficient for read-only operations as it's a simpler, general-purpose tool designed for retrieving content from internal websites. QuipEditor has additional overhead for edit capabilities and should only be used when modifications are actually needed. This ensures optimal performance and follows the principle of using the simplest tool that accomplishes the task.

### Claude Code: Verbose Command Output Bug

**Problem**: Claude Code has issues detecting completion of commands that produce massive output (87,000+ characters). The process gets killed (SIGKILL, exit code 137) even after the command completes successfully.

**Affected Commands**:
- `brazil-build` / `brazil-build release` (CDK synth produces massive output)
- Any command that outputs tens of thousands of characters

**Symptoms**:
- Exit code 137 (128 + 9 = SIGKILL)
- Message: `[Request interrupted by user for tool use]`
- Build actually succeeded (visible in truncated output)
- Background tasks accumulate and never clean up properly

**Workaround**: Redirect output to a file and capture only the exit code:

```bash
# Instead of:
brazil-build release

# Use:
brazil-build release > /tmp/build.log 2>&1; echo "EXIT_CODE=$?"

# Then check results:
tail -20 /tmp/build.log  # Verify BUILD SUCCEEDED
```

**Why This Happens**: Claude Code's process handling appears to have buffer/stream issues with very large output. When output exceeds ~30,000 characters (truncation threshold), the underlying process management struggles to properly detect command completion.

**Date Discovered**: 2025-12-19
