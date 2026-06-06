# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-06
**Overall Verdict**: accepted
**Reviewer**: codex acting as Reviewer
**Baseline Ref**: 90c42993c3ff00dc3d18e64e32de065077d854a3
**Implementation Ref**: a09d95173dbd720249320494d500464f993b6278

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-015, TG-005, TG-007 | pass | Hygiene evidence recorded before implementation; unrelated dirty drift remained excluded from Feature 168 staging. |
| T002 | FR-001, FR-007, FR-010, FR-013, FR-014 | pass | Discovery found a small direct path: methodology docs, reviewer docs, validator plus mirror, synthetic tests, and proposals index status surfacing. |
| T003 | FR-001, FR-004, FR-005 | pass | Proposal mutability classes and direct-edit rules are documented. |
| T004 | FR-002, FR-003 | pass | Structured `Post-Ship Amendments` fields and allowed statuses are documented. |
| T005 | FR-006, FR-007, FR-008, FR-009, FR-015, TG-006, TG-007 | pass | Reviewer guidance requires amendment reference, preserve list, tests-required, disposition, and no unrelated shipped-scope reimplementation. |
| T006 | FR-002, FR-003, FR-010, FR-012 | pass | Validator reads proposal status and amendment records locally without introducing a broad parser surface. |
| T007 | FR-004, FR-010, FR-011, FR-015 | pass | Warning-first shipped/superseded normative edit detection is implemented and remains exit-code 0. |
| T008 | FR-002, FR-003, FR-012 | pass | Malformed amendment records emit a separate `malformed-amendment` warning. |
| T009 | FR-013 | pass | `proposals/INDEX.md` now has a human-maintained post-ship amendment backlog surface. |
| T010 | FR-013 | pass | Index guidance limits backlog rows to `accepted-unimplemented` and `active` amendments. |
| T011 | FR-010, FR-011, FR-012, FR-013, FR-014, FR-015 | pass | Only synthetic proposal fixtures were added under the Feature 168 fixture directory. |
| T012 | FR-010, FR-011, FR-012, FR-014 | pass | Focused replay covers unsafe shipped/superseded edits, valid amendments, allowed corrections, mutable statuses, active exclusion, and malformed records. |
| T013 | FR-001, FR-002, FR-003, FR-007, FR-013, FR-014 | pass | Focused replay asserts docs/template content, reviewer guidance, and index backlog visibility. |
| T014 | FR-010, FR-012, FR-014 | pass | Extension validator and `.specify` mirror are byte-identical. |
| T015 | FR-014, TG-006 | pass | Focused replay, markdownlint, parser/mirror check, and scoped governance validation passed. |
| T016 | FR-006, FR-007, FR-008, FR-009, FR-015, TG-006, TG-007 | pass | Gap ledger and claim-to-evidence ledger classify the policy as documented, implemented, enforced, observable, and tested. |
| T017 | FR-015, TG-005, TG-007 | pass | Delta-only diff audit found no real shipped proposal body rewrites and no bulk migration. |

## Gap Ledger

- Documented: proposal mutability classes, amendment template, allowed statuses, and active-proposal exclusion are present in `docs/methodology/proposal-discipline.md`: fixed-now.
- Implemented: validator warning paths, malformed-amendment finding, reviewer guidance, and proposal-index backlog instructions are delivered in the committed implementation: fixed-now.
- Enforced: warning-first validation detects unsafe shipped/superseded normative edits and malformed records without hard failing this slice: fixed-now.
- Observable: unimplemented amendment states are visible through `proposals/INDEX.md`, and warning output names the proposal, section, and amendment path: fixed-now.
- Tested: synthetic fixture replay, docs/status assertions, mirror parity, markdownlint, and scoped governance validation passed: fixed-now.
- Delta-only scope: review evidence confirms the implementation did not rewrite real shipped proposal bodies, bulk-migrate historical proposals, or reimplement prior shipped behavior: fixed-now.

## Claim-to-Evidence Ledger

| Claim | Evidence | Tests / Review Proof | Verdict |
| ----- | -------- | -------------------- | ------- |
| Proposal mutability classes and direct-edit rules are documented. | `docs/methodology/proposal-discipline.md` | Focused replay asserts required classes, fields, statuses, and active-proposal rule. | pass |
| `Post-Ship Amendments` schema and statuses are documented. | `docs/methodology/proposal-discipline.md` | Focused replay checks required fields and allowed statuses. | pass |
| Review guidance is delta-based and release-blocking for FR-006/FR-015. | `docs/methodology/review-instructions.md` | Focused replay checks amendment reference, preserve list, tests-required, unrelated shipped-scope reimplementation, and release-blocking text. | pass |
| Validator emits warning-first unsafe body-edit findings. | `extensions/specrew-speckit/scripts/validate-governance.ps1`; `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | Synthetic shipped/superseded fixture replay sees `WARN [post-ship-proposal] normative-body-edit` with exit code 0. | pass |
| Validator avoids false positives for allowed paths. | Synthetic fixtures under `tests/unit/fixtures/168-post-ship-proposal-amendment-discipline/` | Focused replay covers valid amendment, allowed correction, candidate, draft, and active cases. | pass |
| Malformed amendments are distinct from unsafe body edits. | Validator warning category and malformed fixture | Focused replay sees `malformed-amendment` and no `normative-body-edit` for malformed fixture. | pass |
| Unimplemented amendment visibility is status/index-only. | `proposals/INDEX.md`; synthetic index fixture | Focused replay asserts `A1 accepted-unimplemented` and `A2 active` are visible, while closed states are not backlog. | pass |
| Mirror parity is preserved. | Extension validator and `.specify` validator | Focused replay compares file contents exactly. | pass |

## Delta-Only Diff Audit

| Audit Question | Evidence | Result |
| -------------- | -------- | ------ |
| Were real shipped proposal bodies rewritten? | `git diff --name-only 90c42993...HEAD -- proposals/*.md` returns only `proposals/INDEX.md`. | pass |
| Were shipped proposal examples implemented through real proposal edits? | All proposal behavior fixtures live under `tests/unit/fixtures/168-post-ship-proposal-amendment-discipline/`. | pass |
| Was historical shipped behavior reimplemented? | Code changes are limited to governance docs, the validator warning path, index guidance, and tests; no runtime shipped-feature implementation files changed. | pass |
| Was bulk migration performed? | No proposal files other than `proposals/INDEX.md` changed in the implementation diff. | pass |
| Did FR-006 remain release-blocking? | Hardening gate, review guidance, and this review ledger require amendment id/delta/preserve/tests evidence. | pass |
| Did FR-015 remain release-blocking? | Hardening gate and this audit require no historical rewrite or reimplementation before signoff. | pass |

## Branch Hygiene Proof

| Check | Evidence | Result |
| ----- | -------- | ------ |
| Implementation-start parity | Human-confirmed and T001-recorded `HEAD == origin` at `14b214f92545708fa5bb2e869d1701b88f922005`. | pass |
| Path-limited staging | Implementation commits staged only Feature 168 docs, validator/mirror, index, tests, and lifecycle artifacts. | pass |
| Unrelated dirty drift | `.codex/`, `.github/agents/squad.agent.md`, `.squad/casting/registry.json`, `.squad/config.json`, Feature 140 task progress, `.cursor/`, and `.specrew/version-check-cache.json` remain excluded. | pass |
| Generated validation summary | `.specrew/last-validator-summary.json` was refreshed by scoped governance validation and remains unstaged generated output. | pass |
| Review boundary push | The final human packet must report the pushed review-boundary HEAD after the boundary sync commit. | pending-final-packet |

## Over-Strong-Claim Checks

| Potential Over-Claim | Bounded Claim Used Instead | Result |
| -------------------- | -------------------------- | ------ |
| "Validator proves all semantic proposal rewrites." | Validator provides warning-first structural tripwires for changed shipped/superseded sections; it does not claim full semantic diffing. | pass |
| "Status surfacing is generated everywhere." | Status surfacing is docs/index-only in this slice; no generated amendment index was created. | pass |
| "Real shipped proposals were validated by editing them." | Behavior proof uses synthetic fixtures only; real shipped proposal bodies were not rewritten. | pass |
| "Warnings are release hard failures." | Findings remain soft warnings with exit code 0, matching clarification defaults. | pass |

## Drift Check

**Verdict**: PASS

Concrete evidence: delivered files satisfy FR-001 through FR-015 and TG-005 through TG-007, focused replay covers the positive/negative validator paths, and the proposal diff audit shows no real shipped proposal body rewrite. No drift event is required.

## Notes

- The remaining governance warnings from scoped validation are out-of-scope legacy validator drift: repetition warning, old dashboard auto-render warning, and handoff-block warnings for earlier Feature 168 boundary commits.
- No human-approved deferrals are recorded for this iteration.
