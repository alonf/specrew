# specrew-update

**Type**: Operational Skill
**Schema**: v1
**Status**: Active
**Namespace**: `/specrew`
**Canonical command**: `/specrew.update`

## Purpose

Refresh Specrew-managed assets and supported platform baselines (Spec Kit, Squad) in the current project.

## When to Use

- When a contributor wants to update Specrew assets in an existing project.
- When refreshing the slash-command surface after a new Specrew release.
- When synchronizing Spec Kit or Squad extensions to a newer version.
- Invoke this skill when the user says: "Update Specrew", "Refresh Specrew assets", "Update Spec Kit", "Update Squad".

## Boundary Safety

This skill updates **distribution-managed assets only**. It does **not** authorize or imply approval to advance any lifecycle boundary. The scope of updates is bounded by the documented argument whitelist — no undocumented expansion occurs.

## Coexistence Contract

This skill is additive. Refreshing Specrew assets does not remove or shadow `/speckit.*` command surfaces.

## Invocation

```text
/specrew.update [--project-path <path>] [--info] [--all]
                [--specrew] [--squad] [--spec-kit] [--skip-update-check]
```

Backed by: `specrew update` / `scripts/specrew-update.ps1`

## Inputs

| Input | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `--project-path` | string | No | Target Specrew project path (defaults to current directory) |
| `--info` | flag | No | Show version and update information without performing updates |
| `--all` | flag | No | Update all managed components (Specrew, Spec Kit, Squad) |
| `--specrew` | flag | No | Update Specrew-managed assets only |
| `--squad` | flag | No | Update Squad-managed assets only |
| `--spec-kit` | flag | No | Update Spec Kit extension only |
| `--skip-update-check` | flag | No | Skip the PSGallery version-available check |

## Outputs

- Update report showing which assets were refreshed, skipped, or newly provisioned.
- Slash-command surface status after the update.
- Version availability notice if a newer Specrew version is available on PSGallery.

## Argument Whitelist

Only the arguments listed above are accepted in v1. Unknown or unsupported arguments are rejected immediately with explicit help guidance.

## Failure Guidance

| Failure mode | Behavior |
| --- | --- |
| Unsupported argument | Rejected immediately with command-specific help guidance |
| Missing project setup | Stop with `specrew init` remediation |
| Outdated compatibility baseline | Stop with upgrade/remediation guidance |

## See Also

- `/specrew.version` — inspect the current version and compatibility state before updating
- `/specrew.help` — catalog fallback and full command list
