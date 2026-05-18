# specrew-status

**Type**: Operational Skill
**Schema**: v1
**Status**: Active (alias)
**Namespace**: `/specrew`
**Canonical command**: `/specrew.status`
**Alias of**: `/specrew.where`

## Purpose

Alias for `/specrew.where`. Show the current Specrew project status dashboard. Produces the exact same semantic result as `/specrew.where`.

## When to Use

- When a contributor asks for project status using "status" phrasing.
- Whenever `/specrew.where` would be appropriate — this command is a full semantic alias.
- Invoke this skill when the user says: "Show Specrew status", "What's the project status?", or "Status".

## Alias Contract

`/specrew.status` is the **only** alias in the v1 Specrew slash-command catalog. It is routed to the same backend, uses the same validation path, and produces identical output to `/specrew.where`. It is **not** a separate status model.

## Boundary Safety

This skill provides **read-only status information only**. Invoking `/specrew.status` does **not** authorize or imply approval to advance any lifecycle boundary.

## Invocation

```text
/specrew.status [--project-path <path>] [--feature <id>] [--iteration <NNN>]
                [--compact] [--ascii] [--no-color] [--json]
                [--team] [--worktrees] [--recentcount <N>] [--barwidth <N>]
```

Backed by: `specrew status` (alias route) → `specrew where` / `scripts/specrew-where.ps1`

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

- Same project status dashboard as `/specrew.where` — semantic parity is a hard requirement.

## Argument Whitelist

Same whitelist as `/specrew.where`. Only the arguments listed above are accepted.

## Failure Guidance

Same failure guidance as `/specrew.where`.

## Coexistence

Part of the `/specrew.*` namespace. Coexists with `/speckit.*` without collision.

## See Also

- `/specrew.where` — canonical command; this alias produces identical output
- `/specrew.help` — catalog fallback and full command list
