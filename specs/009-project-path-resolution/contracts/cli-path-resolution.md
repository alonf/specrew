# Contract: CLI Path Resolution for Feature 009

**Date**: 2026-05-09
**Spec**: [../spec.md](../spec.md)  
**Plan**: [../plan.md](../plan.md)

## Purpose

This contract defines the behavior and artifact obligations for the bounded path-resolution repair in feature 009. It covers the shared helper, user entry-point adoption, internal audit scope, regression/testing duties, and compatibility constraints.

## Artifact Layout

```text
specs/009-project-path-resolution/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
    └── cli-path-resolution.md

scripts/
├── specrew-start.ps1
├── specrew-update.ps1
├── specrew-init.ps1
├── specrew-team.ps1
└── specrew-review.ps1

extensions/specrew-speckit/scripts/
.specify/extensions/specrew-speckit/scripts/
tests/integration/project-path-resolution-regression.ps1
.specrew/quality/known-traps.md
```

## Shared Helper Contract

`Resolve-ProjectPath` MUST:

- accept a user-supplied path string
- return `[System.IO.Path]::GetFullPath($Path)` unchanged for rooted/UNC inputs
- resolve relative inputs against `(Get-Location).Path`
- be the preferred implementation for entry-point `-ProjectPath` handling

It MUST NOT:

- resolve relative user paths directly against `.NET CurrentDirectory`
- change the meaning of already absolute path arguments

## Entry-Point Compatibility Contract

| Script | Path Input | Required Behavior | Compatibility Invariant |
| --- | --- | --- | --- |
| `scripts/specrew-start.ps1` | `ProjectPath` / default `.` | Keep current helper-backed behavior | No CLI or error-message drift |
| `scripts/specrew-update.ps1` | `ProjectPath` / default `.` | Keep current helper-backed behavior | No CLI or error-message drift |
| `scripts/specrew-init.ps1` | `ProjectPath` | Adopt shared helper | Existing bootstrap messaging remains verbatim |
| `scripts/specrew-team.ps1` | `ProjectPath` | Adopt shared helper for all five call sites | Command verbs/arguments stay unchanged |
| `scripts/specrew-review.ps1` | `ProjectPath` | Adopt shared helper | Existing project-path failure semantics stay unchanged |

Rules:

- Existing argument names, defaults, and documented usage remain unchanged.
- Existing errors such as `Project path does not exist`, `Project is not Specrew-managed`, and `Project is not fully bootstrapped` remain verbatim.
- Only the corrected absolute path reported inside those failures may change.

## Internal Audit Contract

The following internal script families are in scope when they accept user-supplied relative path arguments:

- `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1`
- `extensions/specrew-speckit/scripts/run-hardening-gate.ps1`
- `extensions/specrew-speckit/scripts/run-mechanical-checks.ps1`
- `extensions/specrew-speckit/scripts/validate-governance.ps1`
- mirrored `.specify/extensions/specrew-speckit/scripts/*` copies of the same files

Each in-scope call site MUST:

- use `Resolve-ProjectPath` or an equivalent inline relative-to-`Get-Location` normalization
- preserve absolute-path behavior
- be listed in the audit evidence or explicitly exempted with rationale

## Regression and Scan Contract

`tests/integration/project-path-resolution-regression.ps1` MUST:

- create or use a deterministic project fixture
- set PowerShell location and `.NET CurrentDirectory` to different directories
- invoke representative entry-point scripts with `-ProjectPath '.'` and/or default path behavior
- fail if any command resolves the project path against the wrong absolute directory
- include a static scan that flags raw `GetFullPath($ProjectPath/$FeaturePath/$SpecPath/$IterationPath/$DispositionPath)` usage outside allowed locations

## Known-Traps Contract

Before feature closure:

- `.specrew/quality/known-traps.md` must contain a `path-resolution` trap entry
- the entry must include the broken pattern, detection method, remediation guidance, and discovery date `2026-05-09`
- trap reapplication results must be recorded for feature 009

## Required Validation Commands

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -File .\tests\integration\validation-contract-lane.ps1
pwsh -NoProfile -File .\tests\integration\project-path-resolution-regression.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

## Non-Goals

This contract does **not** require:

- replacing all `GetFullPath` uses in the repository
- changing command syntax or introducing new CLI flags
- completing the optional feature-005 mechanical-lens mapping in the same slice
