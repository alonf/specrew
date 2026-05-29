# Iteration Plan: 004

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: reviewing
**Capacity**: 10.0/25 story_points
**Started**: 2026-05-29
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of: planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose.
  - Task Status MUST be one of: planned | in-progress | done | needs-rework | deferred | blocked
-->

## Summary

Iteration `004` delivers the **Proposal 120 Five-Pillar Bypass Detection** scope reserved for this slice (`FR-018..FR-022`, `SC-004`, anchored to Proposal 120 @ `4da969bc` per `TG-008`). An implementation-state audit found that **Pillars 1–3 already shipped in Feature 047 (trust-hardening, commit `d4284c8a`)** and **Pillars 4–5 are not yet complete**. So this iteration is **completion + certification, not a reduction of Proposal 120** (`TG-016` honored): it certifies the three shipped pillars against `FR-018..FR-020` + `SC-004` with traceability, **completes Pillar 4 (FR-021) validator-side detection**, and **builds Pillar 5 (FR-022) from scratch** (the most consequential shape — working-tree-only review evidence). One blocker and one fork (below) materially affect FR-018 and FR-021 scope and require a human decision at the before-implement gate.

## Audit: current implementation state (evidence for scope)

| Pillar | Req | State | Evidence |
| ------ | --- | ----- | -------- |
| 1 — missing `=== SPECREW HANDOFF ===` detection | FR-018 | **Fixture-only** | `Test-HandoffEvidenceGovernance` + `Test-SpecrewHandoffBlockPresent` exist (F-047), but they read `.specrew/handoff-evidence.json` which **nothing in the live lifecycle produces** (validator only reads it; absent in this repo). Fires only against the synthesized F-047 test fixture — form-without-runtime-compliance. |
| 2 — trigger-bypass diagnosis | FR-019 | **Shipped + live** | `Get-MissingDashboardDiagnosis` (F-047); fired in real F-049 runs (`missing-dashboard-non-specrew-managed` / `-auto-render-regression`). |
| 3 — wrong-location | FR-020 | **Shipped + live** | `Test-WrongLocationCanonicalArtifacts` (F-047); runs each validation against ephemeral host-scratch roots. |
| 4 — state-advance-without-verdict | FR-021 | **Partial** | Sync-side `Add-SpecrewBoundaryAuthorization` appends verdict_history + AC8 hard-block — but gated `if ($lastAuthIndex -lt $targetIndex)`, so a **stale/ahead `last_authorized_boundary` silently skips recording AND bypasses the hard-block** (observed empirically in i005). **Validator-side cross-check + tests missing.** |
| 5 — review-cited-files-in-tree | FR-022 | **Missing** | No `Test-ReviewCitedFilesInTree`, no `git ls-tree` verification, no iteration-closeout gate, no test. |

## Scope Summary

| Requirement | Summary | Story |
| ----------- | ------- | ----- |
| FR-018 | Governance validation MUST detect missing `=== SPECREW HANDOFF ===` evidence at boundary/lifecycle stops and surface an explicit handoff warning **in real runs** (not fixture-only). | US4 |
| FR-019 | Distinguish trigger-bypass artifact gaps from generic missing-artifact failures (certify shipped). | US4 |
| FR-020 | Detect canonical artifacts written to ephemeral host session-scratch locations (certify shipped). | US4 |
| FR-021 | Detect state advances across human-judgment boundaries lacking matching human verdict history; prevent silent state progression. | US4 |
| FR-022 | Compare accepted review evidence against the cited Tree Under Review; **block iteration closeout** if production files cited as delivered are absent from that tree; test-only mismatches stay warning-level. | US4 |
| SC-004 | All five pillars surface during governance validation; 0 accepted closeouts rely on production evidence files absent from the cited committed tree. | US4 |
| TG-004 | US4 maps to FR-018..FR-022 + SC-004. | US4 |
| TG-008 | Anchored to Proposal 120 @ `4da969bc`; preserve all five pillars incl. Pillar 5. | US4 |
| TG-016 | Adding Iteration 005 must not reduce/reinterpret/defer FR-018..FR-022/SC-004/TG-008 — this slice completes them. | US4 |

## Human Decisions Required at the before-implement Gate

| # | Decision | Options | Recommendation |
| - | -------- | ------- | -------------- |
| Blocker | **FR-018 is currently fixture-only** (no live producer for `handoff-evidence.json`). To genuinely satisfy FR-018, Pillar 1 needs a live signal. | (a) Add a live producer so the validator detects real missing-handoff stops (recommended, T006); (b) Re-derive Pillar 1 from existing live signals (git boundary commits / `.squad/decisions.md` sync entries) without a new file; (c) Accept FR-018 as detection-rule-only and defer the live producer to a follow-up (would mean FR-018 not truly met this slice). | (a) or (b) — FR-018 wording demands real-run detection. |
| Fork | **Pillar 4 sync short-circuit** (`if ($lastAuthIndex -lt $targetIndex)` skips recording + AC8 hard-block when `last_authorized` is stale/ahead — the i005 symptom). | (a) Fix the recording path so a stale-ahead cursor is detected/repaired and the AC8 hard-block cannot be silently bypassed (T005, recommended — it is inside FR-021's "prevent silent state progression"); (b) Detection-only: validator WARNs on the symptom (T004) and the sync-fix is deferred. | (a) — the validator WARN alone catches the symptom but does not prevent the silent skip. |

## Planned Workstreams

| Workstream | Outcome | Requirements | Surfaces | Effort | Owner |
| ---------- | ------- | ------------ | -------- | ------ | ----- |
| W001 | Pillar 5 helper + validator rule + iteration-closeout hard-gate (FAIL on production file cited but absent from cited tree; WARN on test files) | FR-022, SC-004, TG-008 | `shared-governance.ps1` (+ mirror), `validate-governance.ps1` (+ mirror) | 2.5-3.0 | Implementer |
| W002 | Pillar 4 validator-side cross-check (state.md Current Phase change vs verdict_history) + (fork-A) sync short-circuit repair | FR-021 | `validate-governance.ps1` (+ mirror), `scripts/internal/sync-boundary-state.ps1` (+ mirror) | 1.8-2.6 | Implementer |
| W003 | Pillar 1 live producer / live re-derivation so FR-018 detection fires in real runs (blocker option a/b) | FR-018 | `scripts/internal/*` (sync/boundary path) + `validate-governance.ps1` | 1.5-2.0 | Implementer |
| W004 | Certify Pillars 2–3 fire live + add FR-018..FR-020 traceability markers | FR-018, FR-019, FR-020 | `validate-governance.ps1` (+ mirror) | 0.4-0.6 | Reviewer |
| W005 | SC-004 fixtures: extend bypass tests with Pillar 4 + Pillar 5 (+ live Pillar 1) shapes; prove all five surface; confirm mirror parity | SC-004, FR-018..FR-022, TG-008 | `tests/integration/non-specrew-session-bypass.tests.ps1` | 1.5-2.0 | Reviewer |

**Planned Total**: 7.7-10.2 story_points (the band's swing is the two human-decision items; core without fork-A/blocker-a ≈ 6 SP).

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Create Iteration 004 audit scaffold and evidence envelope | FR-018, FR-019, FR-020, FR-021, FR-022, SC-004, TG-008, TG-016 | US4 | 0.4 | Reviewer | `specs/049-pipeline-hardening-intake/iterations/004/quality/quality-evidence.md` | done | claude | as-planned | pass |
| T002 | Pillar 5 `Test-ReviewCitedFilesInTree` helper (git ls-tree vs cited evidence) | FR-022, TG-008 | US4 | 1.2 | Implementer | `extensions/specrew-speckit/scripts/shared-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` | done | claude | as-planned | pass |
| T003 | Pillar 5 validator rule (FAIL production / WARN test) + iteration-closeout hard-gate | FR-022, SC-004, TG-008 | US4 | 1.5 | Implementer | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | done | claude | as-planned | pass |
| T004 | Pillar 4 validator-side state-advance-without-verdict cross-check (WARN) | FR-021 | US4 | 1.2 | Implementer | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | done | claude | as-planned | pass |
| T005 | Pillar 4 sync short-circuit repair (stale-ahead cursor detection; AC8 hard-block cannot be silently bypassed) — fork A | FR-021 | US4 | 1.3 | Implementer | `scripts/internal/sync-boundary-state.ps1`, `extensions/specrew-speckit/scripts/shared-governance.ps1` | done | claude | as-planned | pass |
| T006 | Pillar 1 live handoff-evidence signal so FR-018 detection fires in real runs — blocker option a/b | FR-018 | US4 | 1.7 | Implementer | `scripts/internal/sync-boundary-state.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1` | done | claude | as-planned | pass |
| T007 | Certify Pillars 2–3 fire live + add FR-018..FR-020 traceability markers | FR-018, FR-019, FR-020 | US4 | 0.5 | Reviewer | `extensions/specrew-speckit/scripts/validate-governance.ps1` | done | claude | as-planned | pass |
| T008 | SC-004 fixtures: Pillar 4 + Pillar 5 (+ live Pillar 1) shapes; prove all five surface | FR-018, FR-019, FR-020, FR-021, FR-022, SC-004 | US4 | 1.6 | Reviewer | `tests/integration/non-specrew-session-bypass.tests.ps1` | done | claude | as-planned | pass |
| T009 | Mirror parity + Proposal 120 evidence (SHA parity on modified extension scripts) | TG-008, SC-004 | US4 | 0.6 | Reviewer | `tests/integration/non-specrew-session-bypass.tests.ps1`, `specs/049-pipeline-hardening-intake/iterations/004/quality/quality-evidence.md` | done | claude | as-planned | pass |

**Planned Task Total**: 10.0 story_points (incl. both human-decision items T005 + T006; deferring either drops toward the 6-8 SP core)
**Bounded Slice Truth**: Proposal 120 remains a 6-10 SP slice inside the repository-wide 25 story-point iteration-capacity model.

## Required Quality Gates

| Gate | Target | Notes |
| ---- | ------ | ----- |
| Pillar 5 closeout hard-gate | required | A production code file cited in review.md evidence but absent from the cited `Tree Under Review` commit (`git ls-tree -r <hash>`) MUST produce FAIL severity and block iteration-closeout (AC9, AC11). Test files → WARN (AC10). |
| Pillar 4 silent-advance detection | required | Validator WARNs when state.md `Current Phase` advances across a human-verdict boundary with no matching `verdict_history` entry; (fork A) sync cannot silently skip recording when `last_authorized` is stale-ahead (AC7, AC8). |
| Pillar 1 live detection | required (pending blocker decision) | FR-018 missing-handoff detection MUST fire in real lifecycle runs, not only against synthesized fixtures. |
| Five-pillar surfacing (SC-004) | required | A single governance validation run over prepared fixtures surfaces all five bypass shapes; 0 accepted closeouts rely on absent production evidence. |
| Mirror parity | required | Modified `validate-governance.ps1` + `shared-governance.ps1` (+ any sync helper) stay SHA256-equal between `extensions/specrew-speckit` and `.specify/extensions/specrew-speckit` (AC6). |
| Backward compatibility | required | New rules add WARN/FAIL only where specified; do not change exit codes for iterations that previously passed except the intended Pillar 5 closeout gate (AC4). |
| Roadmap truth (TG-016) | required | No FR-018..FR-022/SC-004/TG-008 reduction; Pillars 1–3 certified (not re-implemented), 4–5 completed. |

## Planned Execution Order

1. Scaffold + evidence envelope (T001).
2. Pillar 5 first (highest value, well-specified, hard-gates closeout) — helper then validator rule (T002, T003).
3. Pillar 4 validator-side cross-check (T004), then (fork A) sync short-circuit repair (T005).
4. Pillar 1 live signal (T006, per blocker decision).
5. Certify Pillars 2–3 + traceability (T007).
6. Fixtures proving all five surface, then mirror-parity + evidence (T008, T009).

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Same unit used across Feature 049. |
| Capacity per Iteration | 25 | Canonical repository iteration-capacity value from `.specrew/iteration-config.yml`. |
| Iteration Bounding | scope | Fixed to the Proposal 120 five-pillar completion scope. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Authorized Slice | 6-10 | Human-approved band for Proposal 120 (spec line 441). |
| Planned Task Load | 10.0 | Includes both human-decision items; core ≈ 6 SP. |
| Overcommit Threshold | 1.0 | Warn when total estimated effort exceeds 25 story_points; this slice stays well below. |
| Defer Strategy | manual | Any spillover requires explicit human approval. |
| Calibration Enabled | true | Capture variance after execution. |

## Dependencies

- W001 (Pillar 5) is independent and highest value; do it first.
- W002 fork-A repair depends on the validator-side cross-check (W002 base) being designed first.
- W003 (Pillar 1 live) depends on the blocker decision.
- W005 fixtures depend on W001–W004 detection behavior being stable.
- Shipped Pillars 1–3 must not be reshaped (certify-only) per TG-016.

## Traceability Summary

- Requirement scope: `FR-018..FR-022`, `SC-004`.
- Governance anchors: `TG-004`, `TG-008`, `TG-016`.
- Protected adjacent scope: Iteration 005 (Proposal 141) is closed; Iterations 001–003 closed; this slice must not alter them.
- Planning boundary: this is the validator-facing package for Proposal 120 completion; ready for task refresh + governance rerun after the two human decisions are recorded.

## Notes

- Pillars 1–3 shipped in F-047 (`d4284c8a`); this iteration certifies them against FR-018..FR-020 + SC-004 and adds traceability — it does NOT re-implement or reduce them (TG-016).
- A-001 (the `Get-QualityEvidenceContent` StrictMode crash) will affect scaffold/mechanical/reviewer-artifact generation for this iteration too; evidence + reviewer artifacts will be hand-authored as in Iteration 005, and A-001 itself stays the human-deferred framework-fix candidate.
- Iteration 004 was reserved/unopened until now; Iteration 005 (Proposal 141) shipped first as a bounded correction slice — that out-of-order sequencing is intentional and approved (TG-006).
