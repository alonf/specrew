# Quality Evidence — Feature 049 Iteration 004

**Feature**: `049-pipeline-hardening-intake`  
**Iteration**: `004` (Proposal 120 — Five-Pillar Bypass Detection, completion + certification)  
**Evidence recorded**: `2026-05-29`  
**Tree Under Review**: `(recorded at review-signoff)`

> Scaffold note: hand-authored to the canonical gate-matrix shape because `Get-QualityEvidenceContent`
> crashes under StrictMode on the in-use plan quality-gate table (anomaly A-001, see `../drift-log.md`).

## Commands Run

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\non-specrew-session-bypass.tests.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\049-pipeline-hardening-intake\iterations\004 -NoCacheRead
```

## Gate Matrix

| Gate | Requirement | Evidence Source | Status | Exception |
| --- | --- | --- | --- | --- |
| Pillar 1 handoff-block detection (live) | FR-018 | `Add-SpecrewHandoffEvidence` producer + `Test-HandoffEvidenceGovernance` | addressed | — |
| Pillar 2 trigger-bypass diagnosis | FR-019 | `Get-MissingDashboardDiagnosis` (F-047, certified live) | addressed | — |
| Pillar 3 wrong-location detection | FR-020 | `Test-WrongLocationCanonicalArtifacts` (F-047, certified live) | addressed | — |
| Pillar 4 state-advance-without-verdict | FR-021 | `Test-BoundaryStateAdvanceVerdict` (validator) + sync short-circuit repair | addressed | — |
| Pillar 5 review-cited-files-in-tree | FR-022 | `Test-ReviewCitedFilesInTree` + `Test-ReviewEvidenceTreeIntegrity` closeout gate | addressed | — |
| Five-pillar surfacing | SC-004 | `non-specrew-session-bypass.tests.ps1` (all five shapes) | addressed | — |
| Mirror parity | TG-008/AC6 | SHA256 parity on validate/shared-governance + sync wrapper | addressed | — |
| Roadmap truth (no descope) | TG-016 | Pillars 1–3 certified (not re-implemented); 4–5 completed | addressed | — |

## Results

| Check | Outcome | Evidence |
| --- | --- | --- |
| Pillar 1 live producer (FR-018) | PASS | `Add-SpecrewHandoffEvidence` records positive (handoff_present=true) + negative (false) boundary_events; threaded through the sync wrapper + `Invoke-SpecrewBoundaryStateSync` so `Test-HandoffEvidenceGovernance` fires in real runs, not only fixtures. |
| Pillar 2 (FR-019) | PASS (certified live) | `Get-MissingDashboardDiagnosis` (F-047) fired in real F-049 runs (`missing-dashboard-non-specrew-managed` / `-auto-render-regression`); FR-019 traceability added. |
| Pillar 3 (FR-020) | PASS (certified live) | `Test-WrongLocationCanonicalArtifacts` (F-047) runs on every validation; FR-020 traceability added. |
| Pillar 4 (FR-021) | PASS | Validator `Test-BoundaryStateAdvanceVerdict` WARNs when a human-judgment boundary advanced without a matching verdict_history entry; sync short-circuit repaired so a stale-ahead `last_authorized` no longer silently skips recording / bypasses the AC8 hard-block (verified on a temp project). |
| Pillar 5 (FR-022/AC9-AC11) | PASS | Production file cited in an accepted review.md but absent from the cited `Tree Under Review` (present only in the working tree) → FAIL blocking iteration-closeout; test files → WARN. Verified positive + negative + closeout-gate integration. |
| Five-pillar surfacing (SC-004) | PASS | `non-specrew-session-bypass.tests.ps1` green (exit 0); all five shapes surface in governance validation. |
| Mirror parity (AC6) | PASS | `validate-governance.ps1`, `shared-governance.ps1`, and the `sync-boundary-state.ps1` wrapper are SHA256-equal across `extensions/` ↔ `.specify/`; internal sync is single-source. |
| Scoped governance validation | PASS | `PASS specs\049-pipeline-hardening-intake\iterations\004`. |

## Integration Test Output

```text
PASS: Pillar 1 (FR-018) live handoff-evidence producer records positive + negative events
PASS: Pillar 5 (FR-022) flags production evidence cited but absent from the cited Tree Under Review (test files -> WARN)
PASS: Pillar 4 (FR-021) warns when a human-judgment boundary advanced without a matching verdict_history entry
PASS: Pillar 5 (FR-022/AC11) blocks closeout when accepted review evidence cites a production file absent from the cited Tree Under Review
PASS: F-049 Iteration 004: all five Proposal 120 bypass-detection pillars surface during governance validation (SC-004)
PASS: F-047 trust-hardening fixtures cover WARN-only handoff, dashboard, wrong-location, mermaid, skill-root, closeout-template, and task-progress reconciliation paths
```

## Notes

- Pillars 1–3 shipped in F-047 (`d4284c8a`); certified here against FR-018..020 with traceability, not re-implemented (TG-016).
- Latent defect discovered: `validate-governance.ps1` defines `Get-ObjectPropertyString` twice with different parameter names (`-Names` @690 vs `-PropertyNames` @1551); the later shadows the former. Pillar 4 was rewritten to use direct property access; the duplicate-helper cleanup is out of scope and deferred (see `../drift-log.md`).
- A-001 (`Get-QualityEvidenceContent` StrictMode crash) still affects scaffold/mechanical/reviewer-artifact generation; evidence + reviewer artifacts hand-authored as in Iteration 005.
