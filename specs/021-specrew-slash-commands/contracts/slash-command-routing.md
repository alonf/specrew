# Contract: Specrew Slash-Command Routing

**Contract Version**: 1.0.0  
**Feature**: 021-specrew-slash-commands  
**Effective Boundary**: Plan-complete / pre-implementation

## Overview

This contract defines how a `/specrew.*` invocation is normalized, validated, routed to existing PowerShell entry points, and failed when setup or compatibility checks do not pass.

## Routing Principles

1. Normalize aliases before dispatch.
2. Reuse the existing PowerShell dispatcher and explicit script entry points.
3. Forward only documented per-command arguments.
4. Preserve raw/native backend output after validation succeeds.
5. Reject unsupported or ambiguous extras with help guidance.
6. Keep warnings and failures reviewer-visible.

## Invocation Flow

```text
/specrew.<command> [args]
  -> normalize alias
  -> validate setup/version/host capability
  -> validate arg whitelist
  -> dispatch to existing backend route
  -> emit native output with only minimal wrapper context
```

## Per-Command Whitelist

| Slash command | Accepted v1 arguments | Backend mapping |
| --- | --- | --- |
| `/specrew.where` | `--project-path`, `--feature`, `--iteration`, `--compact`, `--ascii`, `--no-color`, `--json`, `--team`, `--worktrees`, `--recentcount`, `--barwidth` | `specrew where ...` / `scripts/specrew-where.ps1` |
| `/specrew.status` | Same as `/specrew.where` | Alias to `/specrew.where` |
| `/specrew.update` | `--project-path`, `--info`, `--all`, `--specrew`, `--squad`, `--spec-kit`, `--skip-update-check` | `specrew update ...` / `scripts/specrew-update.ps1` |
| `/specrew.team` | `list`; `add <member> --role <role> --charter <text>`; `update <member> [--role <role>] [--charter <text>]`; `remove <member>`; optional `--project-path` | `specrew team ...` / `scripts/specrew-team.ps1` |
| `/specrew.review` | `[iteration]`, `--project-path`, `--feature`, `--iteration`, `--quiet`, `--json`, `--open` | `specrew review ...` / `scripts/specrew-review.ps1` |
| `/specrew.help` | none in v1 | Catalog/help output |
| `/specrew.version` | optional `--project-path` in v1 | Version/baseline inspection against installed/runtime and project config state |

## Validation Gates

### Setup gate

- If the project has not completed supported Specrew setup, routed commands fail with an explicit “run `specrew init` first” remediation.

### Compatibility gate

- If the installed or project baseline is older than the first release shipping Feature 021, the command fails with upgrade guidance.
- A degraded host-discovery surface is not a compatibility failure if execution and `/specrew.help` remain available.

### Argument gate

- Unknown or ambiguous extras are rejected.
- Errors must identify the offending argument and point to the appropriate help surface.

## Failure Semantics

| Failure mode | Required behavior |
| --- | --- |
| Unknown slash command | Show explicit “unknown command” guidance and the Specrew catalog path |
| Unsupported argument | Reject immediately with command-specific help guidance |
| Missing project setup | Stop with `specrew init` remediation |
| Outdated compatibility baseline | Stop with upgrade/remediation guidance (`specrew update` or supported refresh path) |
| Discovery unavailable in host | Continue to support `/specrew.help` and direct command execution if compatible |
| Namespace collision or ambiguity | Fail explicitly; do not silently remap or suppress either namespace |

## Diagnostics Contract

- Use reviewer-visible warnings/errors rather than silent fallbacks.
- Preserve PowerShell/CLI-native output for successful commands.
- Keep failure text concise but actionable.
- Avoid hidden behavior differences between slash invocation and direct CLI invocation.

## Boundary Safety

- `/specrew.review` supports review work but does not auto-approve a boundary.
- No `/specrew.*` command implies authorization to advance from the current lifecycle boundary.
- Routing must preserve the Feature 016 rule that humans remain the approval authority for major boundary transitions.
