---
description: Dispatch the Amazon codebase agent team for complex development tasks
argument-hint: What you need help with (e.g., "fix broken build", "research OrderService", "debug test failure")
---

# Amazon Team Dispatch

You are dispatching the Amazon codebase agent team. Analyze the request and route to the appropriate specialist agent(s).

## Request

$ARGUMENTS

## Step 1: Classify the Request

Determine which category the request falls into:

| Category | Keywords / Signals | Agent |
|----------|-------------------|-------|
| **Research** | understand, explain, find, discover, onboard, how does X work | `smangings:researcher` |
| **Build Fix** | build fails, compilation error, dependency issue, brazil-build | `smangings:build-fixer` |
| **Test Debug** | test failure, tod.amazon.com, hydra, integration test, flaky | `smangings:test-debugger` |
| **Deploy Fix** | pipeline stuck, deployment failed, CloudFormation, Apollo | `smangings:deploy-fixer` |
| **Multi-Package** | multiple packages, workspace, dependency order, cross-package | `smangings:workspace-coord` |
| **Full Feature** | implement, ship, end-to-end, multiple steps needed | `smangings:team-lead` |
| **Triage** | everything broken, multiple failures, help | `smangings:team-lead` |

## Step 2: Dispatch

### For single-domain requests
Launch the matching specialist agent directly using the Task tool with the user's request as the prompt.

### For multi-domain or complex requests
Launch `smangings:team-lead` to orchestrate the full team. Provide:
- The user's original request
- The current working directory and workspace context
- Any URLs or specific identifiers mentioned

## Step 3: Report

After the agent completes, present the results to the user with clear next steps.
