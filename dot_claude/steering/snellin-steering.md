### Dynamic Workflows

**Only create a dynamic workflow when I explicitly ask for one** (e.g. "use a workflow", "run a workflow", or the `ultracode` keyword). Do NOT reach for a workflow on your own just because a task looks parallelizable — use plain subagents or handle it inline instead. If you think a workflow would help, suggest it and wait for me to confirm.

**Every workflow that produces findings, plans, or research MUST include an adversarial verification phase**: a fresh agent (or panel) that tries to *refute* each finding before it's reported. Filter out anything that doesn't survive. Verifiers should flag only gaps affecting correctness or the stated requirements — not style preferences.

When creating a workflow, don't default every stage to one model. Route cheap/mechanical stages (grep, file transforms) to Sonnet; reserve Opus for reasoning-heavy verify and synthesis stages. Use Fable only for the MOST complex phases, sparingly.

Base the effort level at high and scale up from high to max according to stage difficulty — use high for routine stages and reserve xhigh/max for the hardest reasoning and verification stages.

### Git and Code Review Operations

**ALWAYS delegate git commit and code review operations to specialized agents.**

#### Git Operations → `smangings:commit` Agent

Use the `smangings:commit` agent (via Task tool) for COMMIT git operations:
- Committing changes

**Do NOT use this agent for merges or rebases** 

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
