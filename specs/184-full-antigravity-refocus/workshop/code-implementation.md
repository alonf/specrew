# Code And Implementation Lens Record

**Feature**: 184-full-antigravity-refocus
**Date**: 2026-06-17
**Depth**: Standard
**Confirmation**: human-confirmed (lens-question scope)

## Decision

Use existing Specrew repo patterns as the source of code-rules truth. No
external guideline or example project is needed. The resolved stack is
PowerShell 7 plus JSON/YAML configuration, Pester-style tests, Markdown docs,
and existing repository tooling. No new runtime dependency is approved by
default.

## Implementation Rules Flow

```text
source of truth
  existing Specrew PowerShell/Pester patterns
  code-rules.yml catalog
  no external guideline/example project
        |
        v
implementation-rules.yml
  resolved_stack: powershell-json-yaml-pester
  dependency_policy: use-existing-no-new-dependency
        |
        v
implement-time guidance
  host manifest + Antigravity adapter/state extension
  SessionStateAccessor + ClassificationEngine reuse
  optional small helper only where it removes real branching
  behavior tests + real-host agy evidence before parity claims
```

## Baseline Craft Posture

- Use intent-revealing names and small functions that isolate a real decision
  or host boundary.
- Keep host-specific Antigravity schema/event normalization in host adapter or
  manifest-owned code, not scattered conditionals.
- Prefer existing helper seams, dependency injection by parameters or small
  functions, and current PowerShell module patterns over new frameworks.
- Keep state ownership inside `SessionStateAccessor`; Antigravity code should
  normalize host input and call the existing state/refocus machinery.
- Preserve user configuration and fail open for hook/runtime failures while
  emitting bounded, actionable diagnostics.
- Add behavior-proving tests for dispatcher/state/classification/config
  preservation; do not rely on file-presence tests alone.
- Preserve source-to-deployed `.specify` parity for any extension/runtime file
  touched by the feature.

## Consequential Decisions

- **Strategy and State over repeated conditionals**: use the existing host
  manifest/adapter strategy surface; if Edge 1 needs a helper, add a focused
  `ConcurrencyMarkerClassifier`-style helper instead of growing dispatcher
  branches.
- **Anti-corruption layer**: normalize Antigravity hook input and output into
  Specrew's existing dispatcher contract before it reaches refocus logic.
- **Error handling**: hook failures fail open, warn loudly, and avoid false
  parity claims when state or injection cannot be proven.
- **State boundaries**: per-session refocus state, dedupe, breaker, and anchor
  remain owned by `SessionStateAccessor` and existing refocus code.
- **Testing posture**: combine automated Pester coverage for adapter/state/config
  behavior with manual real-host `agy` evidence for hook firing, B3 injection,
  Stop handover, and exit/re-entry.
- **Public/reusable surface**: host matrix/docs/status wording must match the
  implemented and verified behavior, not planned behavior.

## Dependency Policy

Dependency stance: use existing project tools / no new dependency.

Allowed existing tools:

- PowerShell / `pwsh`
- Pester-style tests already present in the repo
- built-in JSON handling
- existing YAML handling patterns
- existing Markdown/documentation tooling
- `git` / `gh` where already used by the release or issue flow

Not allowed without a new human decision:

- new parser package
- new Antigravity SDK dependency
- new hook runner
- new test framework
- new release or packaging mechanism

## Confirmation

The human confirmed the baseline: use existing Specrew repo patterns, no
external guideline or example project, PowerShell/JSON/YAML/Pester stack, and no
new runtime dependency unless discovery proves one is necessary and a later
human decision approves it.
