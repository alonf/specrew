# Quickstart: Stack-Aware Quality Bar (Phase 2 / Deferred Quality Gates)

This quickstart describes how the next deferred Phase 2 slice should be validated **after implementation lands**. It is a planning artifact only; it does not imply that any Phase 2 command or artifact already exists.

## Prerequisites

- PowerShell 7+
- Existing Specrew bootstrap in the target repo
- Accepted Phase 1 quality baseline with deterministic findings/evidence already green
- A feature spec with clarified Phase 2 scope

## 1. Confirm the plan exposes the bounded Phase 2 scope

Run the normal planning flow and confirm `specs/005-stack-aware-quality-bar/plan.md` includes:

- an explicit Phase 2 scope marker
- the inherited Phase 1 baseline and green-governance prerequisite
- hardening-gate concern areas
- the lens activation matrix (`required` / `optional` / `not-applicable`)
- strongest-available routing policy
- known-traps corpus location
- explicit deferral of FR-041 through FR-046 and all other out-of-scope work

## 2. Scaffold the Phase 2 quality artifacts

After implementation, a normal scaffold/reviewer flow should produce:

```text
.specrew/
└── quality/
    └── known-traps.md

specs/<feature>/iterations/<NNN>/quality/
├── hardening-gate.md
├── quality-evidence.md
├── mechanical-findings.json
├── lenses/
│   └── *.md
└── trap-reapplication.md
```

Review expectations:

- `known-traps.md` is seeded and versioned
- `hardening-gate.md` contains explicit concern rows and blocking semantics
- each required lens has a dedicated execution artifact

## 3. Run deterministic mechanical checks first

Phase 2 still depends on the accepted Phase 1 mechanical tier:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\run-mechanical-checks.ps1 -ProjectPath .
```

Confirm:

- `mechanical-findings.json` is produced or refreshed
- required findings remain visible before any model-based lens review begins
- the subsequent lens execution artifacts reference the mechanical findings payload

## 4. Run the pre-implementation hardening gate

After implementation, the expected hardening gate flow is:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\run-hardening-gate.ps1 -ProjectPath .
```

Validate `hardening-gate.md` for:

- security surface analysis
- error-handling expectations
- retry/idempotency review, even when not applicable
- test-integrity targets
- operational/resilience concerns
- explicit sign-off or human-approved deferral for any unresolved critical concern

Implementation readiness should stay blocked when any critical row remains `TBD`.

## 5. Execute required bug-hunter lenses

After the hardening gate and mechanical checks are satisfied, the expected lens flow is:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\run-bug-hunter-lenses.ps1 -ProjectPath .
```

For each required lens artifact under `quality/lenses/`, confirm:

- the checklist version is recorded
- execution is row-by-row, not generic prose
- each row records `pass`, `fail`, `not-applicable`, or `advisory`
- focused findings or approved exceptions remain visible
- the requested and effective reasoning/review class are recorded
- any lower-tier override includes justification and human approval

## 6. Verify the known-traps workflow

After implementation, confirm:

- `.specrew/quality/known-traps.md` contains seeded project traps
- newly confirmed review patterns can be added only through an explicit approved workflow
- `trap-reapplication.md` records whether the scan was offered and what it found

## 7. Enforce governance

Run governance validation:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Expected Phase 2 PASS conditions:

- `hardening-gate.md` exists and has no unresolved blocking `TBD` concerns
- every required lens has row-level evidence or an approved explicit exception
- mechanical checks ran before required lens execution
- requested/effective routing is recorded for each required lens
- any lower-tier override has approval and justification
- known-traps corpus and trap-reapplication artifacts satisfy the declared contract

## 8. Run deterministic integration coverage

The expanded regression lane should include the existing Phase 1 tests plus new Phase 2 suites, for example:

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\mechanical-findings-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\bug-hunter-lens-execution.ps1
pwsh -NoProfile -File .\tests\integration\known-traps-corpus.ps1
pwsh -NoProfile -File .\tests\integration\strongest-class-routing.ps1
pwsh -NoProfile -File .\tests\integration\process-quality-scorer.ps1
pwsh -NoProfile -File .\tests\integration\process-quality-report.ps1
```

## Validation Outcome

The Phase 2 slice is ready for task generation and later execution when:

1. the plan stays bounded to the requested deferred FRs only
2. hardening-gate expectations are explicit and blocking semantics are defined
3. required bug-hunter lenses, routing policy, and row-level evidence surfaces are defined
4. known-traps storage and trap-reapplication behavior are explicit
5. governance and tests can fail closed without claiming Phase 3/4 capability
