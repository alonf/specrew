# Dependency Report: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-16
**Baseline Ref**: `a8f413d0f2d46deff4fce0965e1d337a96d212d1`
**Review Commit**: `b79b59d8`
**Overall Verdict**: accepted

## Dependency Delta

| Ecosystem | Package | Prior Version | New Version | Change Type | License | Owning Task |
| --------- | ------- | ------------- | ----------- | ----------- | ------- | ----------- |
| (none) | (none) | none | none | none | n/a | n/a |

## New-to-Project

- none

## Vulnerability Scan

- status: not_applicable
- reason: no package manifest, module manifest dependency block, lockfile, or new runtime dependency changed in F-183.

## Runtime/Tooling Notes

- F-183 stays within the existing PowerShell, JSON, YAML, and Pester profile.
- Antigravity support uses the existing `agy` host surface and project
  `.agents/hooks.json`; no global Antigravity config or new parser package is
  introduced.
- Generated file:///C:/Dev/183-stability-quality-bundle/.agents/hooks.json is
  intentionally per-session and ignored because it contains per-developer
  launcher paths.
