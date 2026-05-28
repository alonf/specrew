# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-05-29

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.5 | 0.5 | 0 |
| T002 | 1 | 1 | 0 |
| T003 | 0.5 | 0.5 | 0 |
| T004 | 0.5 | 0.5 | 0 |
| T005 | 0.5 | 0.5 | 0 |
| T006 | 1 | 1 | 0 |
| T007 | 0.25 | 0.25 | 0 |
| T008 | 0.5 | 0.5 | 0 |
| T009 | 0.25 | 0.25 | 0 |
| T010 | 1 | 2 | +1 |

**Average variance**: +0.1 SP/task. T010 ("verify registry discovery") underestimated — it absorbed the unplanned antigravity-parity edits across ~10 core/test files (DRIFT-001), which the 6-SP envelope did not anticipate as a single task.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done | done | 0 | Clarify resolved 3 items empirically; plan + Wave-B artifacts clean. |
| Discovery/Spikes | 0 | 0 | 0 | CLI probe at clarify removed the need for spikes. |
| Implementation | 5.75 | ~7 | +1.25 | Antigravity-parity blast radius (DRIFT-001) + registry fractional-priority fix (DRIFT-002) beyond the per-package estimate. |
| Review | ~1 | ~3 | +2 | Two cross-reviewer DECLINE cycles: (1) interactive-contract authority mismatch (DRIFT-004), (2) artifact-integrity staleness (form-vs-meaning, commit-lag, diagram Test-fn). |
| Rework | buffer | ~2 | — | Spec reconciliation + reviewer-artifact refresh; no code changes needed (code was correct). |

## Drift Summary

- Total drift events: 4
- Resolved via spec update: 3 (DRIFT-002 sort-fix as spec-honoring defect fix, DRIFT-003 test-path, DRIFT-004 interactive contract)
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 1 (DRIFT-001 SC-006 per-host-cost — advisor + human acknowledged)

## What Went Well

- Review verdict recorded as **accepted** (review-signoff approved by Alon Fliess after independent cross-reviewer convergence).
- **Empirical clarify paid off**: probing `cursor-agent --help`/`--version` at the clarify boundary resolved all 3 deferred items with ground truth instead of guesses; binary name + non-interactive support were settled cleanly.
- **Codex was the right analog**: `HasUserSlashCommandSurface=$false` + `AGENTS.md` + `.cursor/rules` mapping made the package mechanical and consistent.
- **Advisor unblocked the SC-006 fork decisively**: the "grep antigravity = definitive per-host checklist" guidance turned an open-ended discovery into a bounded file list and prevented one-at-a-time hardcode hunting.
- **The registry `[double]` fix** correctly realized the spec's fractional MenuPriority intent (cursor sorts between claude and codex) — a latent defect surfaced by the first non-integer host.
- Independent cross-review caught two real classes of defect (contract authority mismatch; artifact integrity) the implementing session had missed — the cross-reviewer pattern earned its keep.

## What Didn't Go Well

- **Spec-implementation reconciliation lag (DRIFT-004)**: the launch shape + runtime-detection were corrected in code during implementation (correctly) but NOT propagated back to spec/contract/plan/tasks/data-model/diagrams. This is a Rule-34 violation that the cross-reviewer correctly blocked on. **Repeatable failure pattern**: when implementation corrects a clarify-time guess, the authoritative artifacts must be reconciled in the SAME boundary, not left for review to catch.
- **SC-006 over-promise (DRIFT-001)**: spec/plan implied a host addition is confined to `hosts/<kind>/`; reality is ~17 files (allow-listed ValidateSets + tests + UX strings). The "just create `hosts/<kind>/`" framing is aspirational until the Phase-D ValidateScript refactor lands.
- **Reviewer-artifact integrity churn**: the form-vs-meaning heuristic false-positives on doc-heavy features (10 tasks vs 38 files); the scaffolder's drift-resolved regex is brittle (`(N/N resolved)` must be bare); reviewer artifacts inherently lag HEAD by one commit. Three avoidable review round-trips resulted.

## Improvement Actions

1. Owner: Crew coordinator | Phase: every implement boundary | Type: process | Expected effect: when implementation corrects a clarify/plan assumption, reconcile the authoritative spec/contract/tasks/data-model/diagrams in the SAME boundary commit and log the drift then — do not defer to review. (Prevents DRIFT-004-class blocks.)
2. Owner: methodology | Phase: proposal | Type: process | Expected effect: capture the SC-006 per-host-cost finding (DRIFT-001) as a candidate proposal — Phase-D `[ValidateScript({registry})]` refactor to make `--host` enums registry-driven, shrinking the per-host blast radius toward the architecture's stated promise.
3. Owner: methodology | Phase: proposal | Type: tooling | Expected effect: harden the reviewer-artifact scaffolder — (a) form-vs-meaning heuristic should account for governance-artifact files / multi-file tasks (or support an explicit per-iteration disposition input), (b) drift-resolved regex tolerance, (c) document the one-commit-lag convention so cross-reviewers accept content-HEAD references.

## Calibration Suggestion

- Suggested capacity adjustment: per-host-package features → budget ~8-10 SP (not 6), explicitly carving out a "host-integration parity" task (ValidateSets + tests + UX strings) separate from "create the package."
- Rationale: T010 + implementation overran by ~2.25 SP almost entirely due to the antigravity-parity blast radius, which is a predictable, repeatable cost for any new host.

## Notes

- Iteration 001 = core slice (T001–T010). Iterations 002 (integration smoke FR-006/007) + 003 (docs FR-008 + real live-Cursor smoke SC-001/005) remain before feature-closeout.
- Code/tests were correct throughout; both review DECLINEs were artifact/spec-reconciliation issues, not behavior defects.
