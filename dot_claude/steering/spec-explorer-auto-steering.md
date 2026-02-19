### Automatic Spec Studio Context Gathering

**ALWAYS gather Spec Studio context in parallel with codebase exploration before making code changes to Amazon packages.**

When starting any code modification task, you MUST spawn the SpecExplorer agent **in parallel with** the Explore agent. Both should be launched in the same message (multiple Task tool calls) so they run concurrently — SpecExplorer gathers Spec Studio specification context while Explore searches the local codebase. This ensures you understand existing architecture, API contracts, business rules, and constraints before writing code.

#### When to Spawn SpecExplorer

**MUST spawn** (in parallel with Explore) when the task involves:
- Implementing a new feature or capability
- Fixing a bug that requires understanding system behavior
- Refactoring existing code
- Integrating with or calling another service
- Modifying API interfaces or data models
- Changing business logic or validation rules

**SKIP** when the task is:
- Purely cosmetic (formatting, comments, typos, whitespace)
- Updating configuration values (version bumps, feature flags)
- Adding or updating documentation files only
- Running build/test commands without code changes
- Git operations (commit, branch, status)
- The user explicitly says "skip context gathering" or "I already have context"

#### How to Invoke

Launch SpecExplorer and Explore as parallel Task tool calls in a single message:

    Task tool with:
      subagent_type: smangings:spec-explorer
      prompt: |
        Gather Spec Studio context for the following task:

        **Packages**: [package name(s) from workspace or user context]
        **Task**: [brief description of what will be changed]
        **Change type**: [new-feature | bug-fix | refactor | integration]
        **Affected areas**: [optional - specific files, APIs, or components]

    Task tool with:
      subagent_type: Explore
      prompt: [explore the local codebase for relevant files and patterns]

To determine the package name:
- Check the current working directory for a Brazil `Config` file
- Or ask the user which package they're working in
- For multi-package changes, list all affected packages

#### Using the Returned Context

After both SpecExplorer and Explore return their results:
1. Read the full context brief from SpecExplorer before starting any code changes
2. Combine with Explore results for a complete picture
3. Pay special attention to **Constraints and Risks** — these are guardrails
4. Use **API Contracts** to ensure changes maintain compatibility
5. Reference **Business Rules** to validate implementation logic
6. Check **Gaps** to understand what specs did not cover

#### When SpecExplorer Reports No Specs

If SpecExplorer reports no specifications exist for the target package:
- This is not a blocker — proceed with the task
- The Explore agent results are still available for local codebase context
- Consider using `smangings:researcher` for deeper research if the codebase is unfamiliar
- Read source code directly using Glob, Grep, and Read tools
