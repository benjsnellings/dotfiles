# cr

Amazon CRUX code review automation plugin for Claude Code.

## Overview

This plugin provides an intelligent agent for working with Amazon's CRUX code review system. The `cr` agent helps you:

- **Create code reviews** - Stage changes, enforce single-commit-per-package, run `cr` commands, handle templates
- **Address feedback** - Read comments, make changes, squash commits, publish revisions
- **Monitor analyzers** - Auto-poll dry-run build results after CR creation/update, report failures
- **Review code** - Analyze local changes or remote CRs using a 6-dimension framework

## Agent Triggering

The `cr` agent automatically activates when you:

- Ask to create a code review or CR
- Need help addressing reviewer feedback
- Want to review code changes (local or remote)
- Work with multi-package reviews
- Encounter `cr` CLI errors
- Reference code.amazon.com/reviews/ URLs
- Want to monitor CR analyzer/dry-run build results
- Need to check if analyzers passed on a CR

## Example Usage

```
# Creating a CR
"Help me create a code review for my changes"
"Create a CR for ServiceA and ServiceB"

# Addressing feedback
"Help me address the feedback on CR-123456"
"Update my CR with the latest changes"

# Monitoring analyzers
"Check the analyzers on CR-123456"
"Did the dry run build pass on my CR?"

# Reviewing code
"Review my local changes before I create a CR"
"Review the code at code.amazon.com/reviews/CR-123456"
```

## Installation

```bash
# Install via marketplace
/plugin install cr@smangings

# Or test locally
claude --plugin-dir ./smangings/cr
```

## Requirements

- Claude Code CLI
- Brazil workspace (for cr commands)
- Access to code.amazon.com (for remote reviews)
