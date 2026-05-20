---
name: specrew-team
description: Manage Squad team members and baseline-role composition in the current Specrew project.
---

# specrew-team

**Type**: Operational Skill
**Schema**: v1
**Status**: Active
**Namespace**: `/specrew`
**Canonical command**: `/specrew-team`

## Purpose

Manage Squad team members and baseline-role composition in the current Specrew project.

## When to Use

- When adding, listing, updating, or removing Squad team members.
- When managing the team composition for a project.
- Invoke this skill when the user says: "Show team members", "Add a team member", "List the Squad team", "Manage the team".

## Boundary Safety

This skill manages **team configuration only**. It does **not** authorize or imply approval to advance any lifecycle boundary. Managed baseline roles (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator) are preserved according to the baseline-role rules.

## Coexistence Contract

This skill is part of the `/specrew-*` command surface and does not collide with `/speckit.*` commands.

## Invocation

```text
/specrew-team list [--project-path <path>]
/specrew-team add <member-name> --role <role> --charter <text> [--project-path <path>]
/specrew-team update <member-name> [--role <role>] [--charter <text>] [--project-path <path>]
/specrew-team remove <member-name> [--project-path <path>]
```

Backed by: `specrew team` / `scripts/specrew-team.ps1`

## Inputs

### Subcommands

| Subcommand | Description |
| --- | --- |
| `list` | Show current team members and their roles |
| `add <member-name>` | Add a new team member |
| `update <member-name>` | Update an existing team member's role or charter |
| `remove <member-name>` | Remove a non-baseline team member |

### Common Options

| Input | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `--project-path` | string | No | Target Specrew project path (defaults to current directory) |

### add / update Options

| Input | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `--role` | string | Required for add | Human-readable role name |
| `--charter` | string | Required for add | Charter text describing the role's responsibilities |

## Outputs

- Team member list with roles and charter references.
- Confirmation of changes made (add/update/remove).

## Argument Whitelist

Only the subcommands and options listed above are accepted in v1. Unknown subcommands or options are rejected with explicit help guidance.

## Failure Guidance

| Failure mode | Behavior |
| --- | --- |
| Unknown subcommand | Rejected with usage guidance |
| Missing required option (for example `--role` for `add`) | Rejected with command-specific help |
| Attempt to remove a baseline role | Blocked with explanation that baseline roles are managed by Specrew |
| Missing project setup | Stop with `specrew init` remediation |

## See Also

- `/specrew-help` — catalog fallback and full command list
- `/specrew-where` — project status dashboard (includes team view with `--team`)
