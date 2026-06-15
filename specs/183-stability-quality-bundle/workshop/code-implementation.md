# Code and Implementation Lens Record: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Date**: 2026-06-16
**Depth**: Light
**Confirmation**: human-confirmed (lens-question scope)

## Implementation Rules

```text
Source of code-rules truth
  - Use existing Specrew PowerShell/Pester patterns.
  - No external guideline or example project needed beyond this repo.

Stack
  - PowerShell 7+
  - JSON/YAML config files
  - Pester-style integration/unit tests
  - git/gh where already used by the repo
  - no new runtime dependency

Coding posture
  - small focused helper functions where variation is real
  - keep host-specific schema logic behind host-specific deploy/event adapters
  - fail-open for hooks, but emit actionable diagnostics
  - preserve user config when parsing/merge is unsafe
  - tests exercise behavior through scripts/helpers, not file presence only
  - source-to-.specify mirror parity for touched extension files
```

## Dependency Policy

Dependency stance: use existing project tools / no new dependency.

Allowed existing tools:

- PowerShell / `pwsh`
- Pester-style tests already present
- `git` / `gh` where already used for issue/release flow
- built-in JSON handling
- existing YAML handling patterns, if needed

Not allowed without a new decision:

- new parser package
- new CLI dependency for Antigravity hook handling
- new test framework
- new release/publish mechanism
