# amzn-team — Amazon Codebase Agent Team

Specialized agent team for Amazon codebase workflows. Provides autonomous agents for research, build fixing, test debugging, deployment troubleshooting, and multi-package coordination.

## Agents

| Agent | Purpose | Model |
|-------|---------|-------|
| `amzn-researcher` | Cross-system codebase research using Spec Studio, InternalCodeSearch, and InternalSearch | sonnet |
| `amzn-build-fixer` | Autonomous Brazil build diagnosis, fix, and verification loop | sonnet |
| `amzn-test-debugger` | 8-phase ToD/Hydra integration test failure investigation | opus |
| `amzn-deploy-fixer` | Pipeline and deployment troubleshooting (CloudFormation, Apollo, ECS, Lambda) | sonnet |
| `amzn-workspace-coord` | Multi-package dependency mapping, build ordering, and change planning | sonnet |
| `amzn-team-lead` | Team orchestrator that dispatches specialists for complex multi-domain tasks | opus |

## Commands

| Command | Description |
|---------|-------------|
| `/amzn-team <request>` | Classify your request and dispatch the right specialist agent |

## Usage Examples

### Research an unfamiliar package
```
/amzn-team how does OrderService handle payment processing?
```

### Fix a broken build
```
/amzn-team fix the build failure in src/MyService
```

### Debug a test failure
```
/amzn-team debug this test: https://tod.amazon.com/test_runs/12345
```

### Troubleshoot a deployment
```
/amzn-team my pipeline MyService-Pipeline is stuck on CloudFormation
```

### Coordinate multi-package work
```
/amzn-team map dependencies and plan changes across all packages in my workspace
```

### Full feature delivery
```
/amzn-team implement the new validation feature across model, service, and client packages
```

## How Team Coordination Works

The `amzn-team-lead` agent orchestrates other specialists using three patterns:

1. **Direct dispatch** — Simple requests route to one specialist
2. **Formal team** — Complex requests create a team with dependent tasks
3. **Parallel triage** — "Everything is broken" dispatches agents in parallel

## Installation

This plugin is part of the `amzn` marketplace. Install with:

```bash
claude plugin install amzn-team@amzn
```
