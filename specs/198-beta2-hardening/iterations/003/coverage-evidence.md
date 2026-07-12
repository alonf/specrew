# Coverage Evidence: Iteration 003

**Schema**: v1
**Reviewed**: 2026-07-11
**Overall Verdict**: in-progress (mid-implementation runtime evidence; the reviewer-closeout
generator supersedes this at the iteration review boundary)

> This is a **hand-authored, worktree-visible** runtime-evidence record for the containment +
> round-economy tasks completed so far (T013/T014/T015/T020), created in response to co-review
> finding 90173dc6-2 / 4b124d0e-2: narrative "green" counts have zero evidence standing under the
> review contract, so the exact commands, counts, exit codes, and durations are recorded here where
> the reviewer can see them (specs/ is not stripped from the reviewer worktree). The **digest-linked
> runner-observed record** for EVERY suite below (T013/T014/T015 production+helper/T020 + the T034b
> strict-resolution integration) lives under `.specrew/review/test-evidence/<digest>.json`
> (digest-excluded runtime state) and is injected into the reviewer worktree as
> `.review/implementer-evidence.json`; so each row's count has runner-observed standing, not prose-only
> (co-review findings 40a06e84 / d5511d31 / ea521faf). This file is the human-readable companion to that
> record.

## Test Strategy

- EVERY iteration-003 DONE-task suite (T013/T014/T015/T020) below is recorded as **digest-linked
  runner-observed evidence** injected as `.review/implementer-evidence.json` — so each row's count has
  runner-observed standing, not prose (co-review findings 40a06e84 / d5511d31). Under the simplified
  model the reviewer READS this evidence; it is not re-run.
- The F-198 honesty regression suite (`tests/f198-regression-suite.ps1`) is a bounded, EXPLICIT registry
  (never a glob) wired as a blocking CI step (NFR-007); it runs these suites plus the shared-engine
  suites as the whole-feature gate. Its per-suite counts are the individual records below.
- Every suite is run FOR REAL in-session; the counts/exit/duration are runner-reported, never hand-typed.

## Tests Run

| Task | Suite | Result | Pass | Fail | Duration | Exit |
| ---- | ----- | ------ | ---- | ---- | -------- | ---- |
| T013 (FR-008) | `worktree-containment.Tests.ps1` — outside-origin materialization; refuses inside/origin-itself; symlink/junction escape refused; shared physical-path helper (intermediate junction, in-scope link, plain path) + platform-appropriate-case predicate | pass | 8 | 0 | ~5s | 0 |
| T014 (FR-009) | `origin-path-hygiene.Tests.ps1` — relativizes origin paths (all forms, multi-root); END-TO-END diff scrub | pass | 6 | 0 | ~5s | 0 |
| T015 (FR-010) prod | `orchestrator-reviewer-integrity.Tests.ps1` — no auto-verification; reviewer-invocation integrity (source/authority/host-config mutation fails; findings.jsonl allowed; new host churn ok); honest prompt | pass | 8 | 0 | ~7s | 0 |
| T015 (FR-010) helper | `bounded-verification.Tests.ps1` — opt-in helper + removed-auto-rerun regression: timeout, process-tree kill, zero-disk byte cap, add/delete/modify + .review-authority mutation | pass | 11 | 0 | ~12s | 0 |
| T020 (FR-018/019) | `review-spend-allowance.Tests.ps1` — two-budget classifier; preflight (no spend/round); post-invocation failed (spend+round); ceiling counts only reviewed rounds; consumer-legible halt | pass | 11 | 0 | ~7s | 0 |
| T034b (FR-012, reuse of cca79708) | `review-context-and-harvest-hardening.Tests.ps1` — strict design-context: mixed/all-invalid/traversal/rooted/intermediate-dir-junction refs FAIL before reviewer selection (reviewer never invoked), valid in-repo ref passes, POSIX case-distinct sibling rejected (the +1 POSIX-only test, skipped on Windows); plus f1/f2 design-context + harvest | pass | 18 | 0 | ~9s | 0 |
| `& ./tests/f198-regression-suite.ps1` | pass | 16 | 0 | ~88s | 0 | Whole-feature honesty gate: 16 suites (ratchet, spend allowance, containment, origin hygiene, bounded-verification helper + reviewer-integrity, tracker honesty, verdict capture, budget, signoff gate, shared-engine, digest/exec-bit) |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression (paired honesty tests per requirement) + full-registry gate
- Tool: Pester 5.8.0

## Coverage-to-Requirements

| Requirement | Test Files / Commands |
| ----------- | --------------------- |
| FR-008 (worktree relocation) | tests/continuous-co-review/unit/worktree-containment.Tests.ps1 |
| FR-009 (origin-path hygiene) | tests/continuous-co-review/unit/origin-path-hygiene.Tests.ps1 |
| FR-010 (confinement contract + reviewer-invocation integrity; opt-in bounded helper) | tests/continuous-co-review/unit/bounded-verification.Tests.ps1, tests/continuous-co-review/unit/orchestrator-reviewer-integrity.Tests.ps1 |
| FR-013 (reviewer taught what is absent; strict read-only) | tests/continuous-co-review/unit/orchestrator-reviewer-integrity.Tests.ps1 (honest-prompt cases) |
| FR-018, FR-019 (spend allowance + two-budget) | tests/continuous-co-review/unit/review-spend-allowance.Tests.ps1 |
| NFR-007 (CI enforcement) | tests/f198-regression-suite.ps1 (blocking CI step) |
