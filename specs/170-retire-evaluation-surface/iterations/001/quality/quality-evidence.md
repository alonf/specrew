# Quality Evidence: Iteration 001

**Feature**: 170-retire-evaluation-surface
**Iteration**: 001
**Recorded**: 2026-06-06
**Method**: verification-first — every FR proven by an executed check (exit
codes, scan output, diff results), never by file presence (runtime-deliverable
rule, 2026-05-31).

## Per-FR Evidence Ledger

| FR | Check executed | Result | Evidence |
| --- | --- | --- | --- |
| FR-001 | `git ls-files evaluation/` | empty — PASS | T001 console run, 2026-06-06 |
| FR-002 | `git ls-files tests/support/` + repo-wide tracked-copy scan | exactly one scorer at `tests/support/process-quality-scorer.ps1` — PASS | T001 console run |
| FR-003 | `pwsh -File tests/integration/process-quality-scorer.ps1` | exit 0, all PASS lines — PASS | `t002-run.log` |
| FR-004 | `pwsh -File tests/integration/process-quality-report.ps1` + placement assert | exit 0; report at `.scratch/process-quality-report/project/test-results/process-quality-report.md`; `.scratch` confirmed gitignored — PASS | `t003-run.log` |
| FR-005 | Smoke Tests 9+10 executed directly (forward-slash literal; parse check) + `project-path-resolution-regression.ps1` | all PASS | `t004a-smoke.log`, `t004b-pathreg.log`; full-suite caveat in DRIFT-002 |
| FR-006 | Active-surface `evaluation/` scan (8 surface roots, 20 hits classified) | every hit in an allowed class: 1 retirement-wording (docs/user-guide.md:808), 14 frozen fixtures, 5 archived ledger — PASS | T005 scan output; SC-004 class (c) added via DRIFT-001 |
| FR-007 | Proposal 169 on main (`262325d3`) + INDEX entry with classification rationale | present — PASS | T006 console run |
| FR-008 | `git diff main HEAD` over historical fixture/spec paths | empty — PASS | T006 console run |

## Mechanical Checks

`run-mechanical-checks.ps1` (generator 0.32.0): **0 findings**
(`mechanical-findings.json`, generated 2026-06-06T19:36:13Z).

## Hardening-Gate Runtime Follow-Through

| Concern | Planning status | Runtime outcome |
| --- | --- | --- |
| error-handling-expectations | pending-post-implementation | PROVEN at T003: both tests rebuild scratch trees from scratch; report directory created on demand; exit 0 |
| test-integrity-targets | pending-post-implementation | PROVEN at T002-T004: real suites executed with exit codes recorded; no file-presence acceptance |
| operational-resilience-concerns | pending-post-implementation | PROVEN at T005: scan clean; both validator mirrors diff-identical (`git diff --no-index` of the two mirror files is empty within the branch); CI entry points untouched |
| branch-hygiene-and-dirty-drift | pending-post-implementation | PROVEN continuously: 145 preflights at plan + before-implement caught and fixed parity/dirty-state/token defects; path-limited staging kept session drift out of all 170 commits |
| proposal-145-review-discipline | pending-post-implementation | Gate preflights executed at every boundary so far; the seven-phase review executes at review-signoff |

## Known Blockers / Deferred

- DRIFT-002: full smoke-suite green blocked by a pre-existing main red
  (obsolete backslash assertion vs F-160 POSIX-safe shim), owned by sibling
  slice `169-found-bug-fixes`. The 170-relevant assertions pass directly.

## Gap Count

0 unresolved gaps attributable to this feature. 2 drift events, both resolved
(spec-updated; deferred-to-owning-slice) — see `../drift-log.md`.
