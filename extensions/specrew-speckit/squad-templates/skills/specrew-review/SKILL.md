# specrew-review

**Type**: Operational Skill
**Schema**: v1
**Status**: Active
**Namespace**: `/specrew`
**Canonical command**: `/specrew.review`

## Purpose

Trigger or inspect the Specrew review-oriented workflow — replay the persisted reviewer closeout packet for a completed iteration.

## When to Use

- When a reviewer wants to inspect the review summary for a completed iteration.
- When replaying the reviewer closeout packet.
- Invoke this skill when the user says: "Show the review summary", "Review the iteration", "Show reviewer output".

## Boundary Safety

This skill **supports review work** but does **not** bypass the required human decision point. A human reviewer must still explicitly approve lifecycle advancement. Invoking `/specrew.review` is not equivalent to approving an iteration for closure or advancement.

**Feature 016 rule**: Humans remain the approval authority for major boundary transitions. This command may not imply authorization to advance from any lifecycle boundary.

## Coexistence Contract

This skill is part of the `/specrew.*` namespace. It coexists with `/speckit.*` review-related commands without collision or shadow. Using `/specrew.review` does not substitute for `/speckit.*` lifecycle actions that require explicit human authorization.

## Invocation

```text
/specrew.review [<iteration>] [--project-path <path>] [--feature <id>]
                [--iteration <NNN>] [--quiet] [--json] [--open]
```

Backed by: `specrew review` / `scripts/specrew-review.ps1`

## Inputs

| Input | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `<iteration>` | string (positional) | No | Iteration number to replay (defaults to most recent closed iteration) |
| `--project-path` | string | No | Target Specrew project path (defaults to current directory) |
| `--feature` | string | No | Restrict lookup to one feature directory under `specs\` |
| `--iteration` | string | No | Replay a specific iteration directory |
| `--quiet` | flag | No | Emit only the stable machine-parseable digest line |
| `--json` | flag | No | Emit JSON summary instead of the visual reviewer summary |
| `--open` | flag | No | Open reviewer-index.md and review-diagrams.md when present |

## Outputs

- Reviewer closeout packet for the specified iteration.
- Raw/native output from the underlying `specrew review` workflow with minimal wrapper context.

## Argument Whitelist

Only the arguments listed above are accepted in v1. Unknown arguments are rejected with command-specific help guidance.

## Failure Guidance

| Failure mode | Behavior |
| --- | --- |
| Unsupported argument | Rejected immediately with command-specific help guidance |
| No iteration found | Error with guidance to check `specs/` directory structure |
| Missing project setup | Stop with `specrew init` remediation |

## See Also

- `/specrew.where` — current project status (live, not review replay)
- `/specrew.help` — catalog fallback and full command list
