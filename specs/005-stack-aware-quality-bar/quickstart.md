# Quickstart: Stack-Aware Quality Bar (Hardening Evidence Boundary Repair)

This quickstart defines the validation path for the bounded hardening-gate evidence-boundary repair. It is a planning artifact only; it does **not** claim that the implementation already exists.

## Prerequisites

- PowerShell 7+
- Existing Specrew bootstrap in the target repo
- Accepted Phase 1 quality baseline
- Approved `spec.md` clarifications from 2026-05-09
- New repair iteration artifact at `specs/005-stack-aware-quality-bar/iterations/004/`

## 1. Confirm the plan stays tightly bounded

Review `specs/005-stack-aware-quality-bar/plan.md` and confirm it:

- targets only the hardening-gate evidence-boundary repair
- keeps one `hardening-gate.md` artifact across lifecycle phases
- requires planning-time analysis before implementation begins
- reserves runtime evidence for post-implementation review/closure
- limits `deferred-with-approval` to runtime-only final proof
- keeps bug-hunter, known-traps, routing expansion, drift, and reference-implementation work deferred

## 2. Confirm the iteration repair artifact exists

Review `specs/005-stack-aware-quality-bar/iterations/004/plan.md` and `state.md` and confirm they:

- preserve completed Iteration `003`
- name the affected governance/code/test surfaces
- define the bounded repair slices
- list the deterministic validation commands

## 3. Validate the repaired hardening-gate contract

The future implementation must make `hardening-gate.md` support:

- one lifecycle-visible artifact
- planning-time analysis and expected controls before implementation
- explicit `not-applicable` reasoning where valid
- `deferred-with-approval` only after planning-time analysis already exists
- runtime-evidence follow-through that remains open until later review records it

The contract/regression lanes for this repair are:

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
```

## 4. Run the hardening gate against the repair iteration

Once implementation exists, the repair must be provable with:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\run-hardening-gate.ps1 -ProjectPath . -IterationPath .\specs\005-stack-aware-quality-bar\iterations\004 -OutputFormat Json
```

Expected review behavior:

- blocking concerns with missing planning-time analysis stay blocked
- runtime-only final proof may remain pending only with explicit approval and rationale
- the artifact records whether the current basis is planning-time analysis or runtime evidence
- no concern is marked fully closed before required runtime proof exists

## 5. Enforce fail-closed governance

Run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Expected PASS conditions for this repair:

- the repaired hardening-gate contract is present
- missing planning-time analysis blocks implementation readiness
- `deferred-with-approval` is rejected when used as a substitute for missing pre-implementation analysis
- runtime-only concerns remain visibly open or deferred until later runtime evidence is recorded

## Validation Outcome

The bugfix slice is ready for later implementation when:

1. the feature plan and Iteration `004` stay bounded to this repair only
2. the hardening-gate contract explicitly distinguishes planning-time analysis from runtime evidence
3. the approval boundary for `deferred-with-approval` is explicit and narrow
4. the named regression lanes and governance commands are the required validation path
