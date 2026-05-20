---
name: specrew-version
description: Show the installed Specrew version and the slash-command compatibility state.
---

# specrew-version

**Type**: Informational Skill
**Schema**: v1
**Status**: Active
**Namespace**: `/specrew`
**Canonical command**: `/specrew-version`

## Purpose

Show the installed Specrew version and slash-command compatibility state. Reports both the installed/runtime version and the project baseline version from `.specrew/config.yml`.

## When to Use

- When a contributor wants to know which version of Specrew is installed.
- When checking whether the slash-command surface is compatible with the current baseline.
- When diagnosing compatibility issues before or after `specrew update`.
- Invoke this skill when the user says: "What version of Specrew is installed?", "Show Specrew version", "Is the slash-command surface compatible?", "Check Specrew version".

## Boundary Safety

This skill provides **version and compatibility information only**. It does **not** authorize or imply approval to advance any lifecycle boundary.

## Invocation

```text
/specrew-version [--project-path <path>]
```

Backed by: `specrew version` / `scripts/specrew-version.ps1`

## Inputs

| Input | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `--project-path` | string | No | Target Specrew project path (defaults to current directory) |

## Outputs

- Installed Specrew version (from module or `Specrew.psd1`)
- Project baseline version (from `.specrew/config.yml`)
- Slash-command compatibility state:
  - `compatible` — the installed version ships the Feature 024 multi-host slash-command surface
  - `incompatible` — the installed version predates the multi-host slash-command surface; upgrade guidance is shown
  - `unknown` — the installed version cannot be determined
- Remediation guidance when compatibility is not met:
  - For outdated installed version: `Update-Module Specrew` or equivalent
  - For outdated project baseline: `specrew update`

## Argument Whitelist

Only `--project-path` is accepted in v1. Unknown arguments are rejected with explicit help guidance.

## Failure Guidance

| Failure mode | Behavior |
| --- | --- |
| Unsupported argument | Rejected immediately with command-specific help guidance |
| Missing project setup | Continue with version inspection, report the project baseline as missing, and point to `specrew init` if the project has not been bootstrapped yet |
| Version cannot be determined | Report `unknown` state and suggest verifying the Specrew module installation |
| Incompatible baseline | Report upgrade guidance (`specrew update` or `Update-Module Specrew`) |

## Compatibility Baseline

The minimum compatible version is the **first published Specrew release that ships Feature 024** (the multi-host slash-command surface). Projects running on a pre-v0.24.0 baseline must upgrade to access the full `/specrew-*` command surface.

## Coexistence

Part of the `/specrew-*` command surface. Coexists with `/speckit.*` without collision.

## See Also

- `/specrew-update` — refresh Specrew assets and compatibility baseline
- `/specrew-help` — catalog fallback and full command list
