# specrew-where

**Type**: Operational Skill
**Schema**: v1
**Status**: Active
**Namespace**: `/specrew`
**Canonical command**: `/specrew.where`

## Purpose

Show the current Specrew project status dashboard — the "where am I?" velocity view for the active feature and iteration.

## When to Use

- When a contributor wants to know the current project status, active feature, and iteration state.
- When checking progress against iteration capacity.
- When troubleshooting stale or unexpected lifecycle state.
- Invoke this skill when the user asks: "Where am I?", "Show me the Specrew dashboard", "What is the current status?", or "What feature is active?"

## Boundary Safety

This skill provides **read-only status information only**. Invoking `/specrew.where` does **not** authorize or imply approval to advance any lifecycle boundary. Human review is still required for lifecycle transitions.

## Invocation

```text
/specrew.where [--project-path <path>] [--feature <id>] [--iteration <NNN>]
               [--compact] [--ascii] [--no-color] [--json]
               [--team] [--worktrees] [--recentcount <N>] [--barwidth <N>]
```

Backed by: `specrew where` / `scripts/specrew-where.ps1`

## Inputs

| Input | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `--project-path` | string | No | Target Specrew project path (defaults to current directory) |
| `--feature` | string | No | Restrict view to a specific feature directory under `specs\` |
| `--iteration` | string | No | Restrict view to a specific iteration number |
| `--compact` | flag | No | Emit a compact single-line summary |
| `--ascii` | flag | No | Use ASCII-safe output (no Unicode box-drawing) |
| `--no-color` | flag | No | Suppress color output |
| `--json` | flag | No | Emit machine-parseable JSON output |
| `--team` | flag | No | Include team member status in the view |
| `--worktrees` | flag | No | Include worktree awareness information |
| `--recentcount` | number | No | Number of recent iterations to include (default: 6) |
| `--barwidth` | number | No | Width of progress bar in characters (default: 28) |

## Outputs

- Project status dashboard with active feature, iteration state, capacity, and velocity metrics.
- Raw/native output from the underlying `specrew where` workflow with only minimal slash-command wrapper context.

## Argument Whitelist

Only the arguments listed above are accepted. Unsupported or unknown arguments will be rejected with help guidance pointing to this skill.

## Failure Guidance

| Failure mode | Behavior |
| --- | --- |
| Unsupported argument | Rejected immediately; see `/specrew.help` for the allowed argument list |
| Missing project setup | Stop with `specrew init` remediation |
| Outdated compatibility baseline | Stop with upgrade guidance (`specrew update`) |

## Coexistence

This skill is part of the `/specrew.*` namespace. It coexists with `/speckit.*` commands without collision. Neither namespace shadows the other.

## See Also

- `/specrew.status` — alias for this command; produces the same semantic result
- `/specrew.help` — catalog fallback and full command list
- `/specrew.version` — show installed Specrew version and compatibility state
