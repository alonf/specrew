---
name: specrew-review
description: Run live continuous co-review or replay persisted reviewer evidence for an iteration.
---

# specrew-review

**Type**: Operational Skill
**Schema**: v1
**Status**: Active
**Namespace**: `/specrew`
**Canonical command**: `/specrew-review`

## Purpose

Trigger or inspect the Specrew review-oriented workflow. Use live mode to run the continuous co-review runtime and persist reviewer evidence under `.specrew/review/inline/<run-id>/`; use replay mode to inspect an existing reviewer closeout packet for a completed iteration.

## When to Use

- When a reviewer needs a live continuous co-review run before or during a review boundary.
- When a reviewer wants to inspect the review summary for a completed iteration.
- When replaying the reviewer closeout packet.
- Invoke this skill when the user says: "Run the reviewer", "Run live review", "Show the review summary", "Review the iteration", "Show reviewer output".

## Boundary Safety

This skill **supports review work** but does **not** bypass the required human decision point. A human reviewer must still explicitly approve lifecycle advancement. Invoking `/specrew-review` is not equivalent to approving an iteration for closure or advancement.

**Feature 016 rule**: Humans remain the approval authority for major boundary transitions. This command may not imply authorization to advance from any lifecycle boundary.

## Coexistence Contract

This skill is part of the `/specrew-*` command surface. It coexists with `/speckit.*` review-related commands without collision or shadow. Using `/specrew-review` does not substitute for `/speckit.*` lifecycle actions that require explicit human authorization.

## Invocation

```text
/specrew-review [<iteration>] [--project-path <path>] [--feature <id>]
                 [--iteration <NNN>] [--quiet] [--json] [--open]
/specrew-review --live [--baseline-ref <git-ref>] [--project-path <path>]   # baseline auto-anchors for signoff; an explicit --baseline-ref run is exploratory-only
                 [--checkpoint-id <id>] [--run-id <id>] [--host <host>]
                 [--model <model>] [--authorization-ref <ref>]
                 [--design-context-ref <path>] [--allowed-path <path>]
                 [--forbidden-path <path>] [--exclude-path <path>]
                 [--reviewer-config <path>] [--schema-root <path>]
                 [--run-root <path>] [--timeout-seconds <N>]
                 [--fallback-policy <none|one-authorized-availability-fallback>]
                 [--preserve-debug]
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
| `--live` | flag | No | Run the continuous co-review runtime instead of replaying prior closeout state |
| `--baseline-ref` | string | Yes for `--live` | Git ref used to compute the review change set |
| `--checkpoint-id` | string | No | Stable checkpoint identifier for the live review request |
| `--run-id` | string | No | Explicit run id for evidence under `.specrew/review/inline/<run-id>/` |
| `--host` | string | No | Reviewer host to request (`claude`, `codex`, `copilot`, `cursor-agent`, or `antigravity`) |
| `--model` | string | No | Reviewer model override; non-default models require `--authorization-ref` |
| `--authorization-ref` | string | No | Human authorization reference for host/model selection |
| `--design-context-ref` | string | No | Design or lifecycle artifact to include in the review request context |
| `--allowed-path` | string | No | Add a mutable path allowlist entry for this live review run |
| `--forbidden-path` | string | No | Add a protected path entry for this live review run |
| `--exclude-path` | string | No | Add a change-set exclusion entry for this live review run |
| `--reviewer-config` | string | No | JSON reviewer host configuration for deterministic or authorized hosts |
| `--schema-root` | string | No | Contract schema root for `ReviewRequest` and `FindingsResult` validation |
| `--run-root` | string | No | Override the evidence output root; defaults to `.specrew/review/inline` |
| `--timeout-seconds` | number | No | Live reviewer host timeout |
| `--fallback-policy` | string | No | Host fallback policy (`none` or `one-authorized-availability-fallback`) |
| `--preserve-debug` | flag | No | Preserve debug artifacts from the live review run |

## Outputs

- Live `ReviewRequest`, prompt bundle, host invocation metadata, `FindingsResult`, gate verdict, and run index under `.specrew/review/inline/<run-id>/` when `--live` is used.
- Reviewer closeout packet for the specified iteration when replay mode is used.
- Raw/native output from the underlying `specrew review` workflow with minimal wrapper context.

## Argument Whitelist

Only the arguments listed above are accepted in v1. Unknown arguments are rejected with command-specific help guidance.

## Failure Guidance

| Failure mode | Behavior |
| --- | --- |
| Unsupported argument | Rejected immediately with command-specific help guidance |
| Missing `--baseline-ref` in live mode | Error explaining that live review needs a baseline ref |
| Unauthorized reviewer host/model | Infrastructure failure with reviewer authorization guidance; do not treat this as reviewer approval |
| No iteration found | Error with guidance to check `specs/` directory structure |
| Missing project setup | Stop with `specrew init` remediation |

## See Also

- `/specrew-where` — current project status (live, not review replay)
- `/specrew-help` — catalog fallback and full command list
