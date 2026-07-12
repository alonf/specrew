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
> runner-observed record** for BOTH T015 suites — the FR-010 production-path suite
> (`orchestrator-reviewer-integrity.Tests.ps1`) and the opt-in helper (`bounded-verification.Tests.ps1`)
> — lives under `.specrew/review/test-evidence/<digest>.json` (digest-excluded runtime state) and is
> injected into the reviewer worktree as `.review/implementer-evidence.json`; so the counts below have
> runner-observed standing, not prose-only (co-review finding 40a06e84). This file is the human-readable
> companion to that record.

## Test Strategy

- The F-198 honesty regression suite (`tests/f198-regression-suite.ps1`) is a bounded, EXPLICIT
  registry (never a glob) wired as a blocking CI step (NFR-007). It is the whole-feature honesty gate.
- `orchestrator-reviewer-integrity.Tests.ps1` is the **production-path** evidence for FR-010 (the
  orchestrator never auto-runs verification; the reviewer invocation is integrity-checked). It is
  recorded as digest-linked runner-observed evidence the reviewer READS (the simplified model does not
  re-run it), alongside the opt-in helper suite `bounded-verification.Tests.ps1`.
- Every suite is run FOR REAL in-session; the counts/exit/duration below are runner-reported, never
  hand-typed.

## Tests Run

| Command | Result | Pass | Fail | Duration | Exit | Notes |
| ------- | ------ | ---- | ---- | -------- | ---- | ----- |
| `$env:SPECREW_MODULE_PATH=(Get-Location).Path; Invoke-Pester -Path 'tests/continuous-co-review/unit/bounded-verification.Tests.ps1' -PassThru` | pass | 11 | 0 | ~12s | 0 | FR-010 opt-in helper + regression evidence for the removed auto-reruns: timeout, process-tree kill, zero-disk byte-bounded streaming cap, add/delete/modify mutation, reviewer-authority (.review) mutation reported, allowlist, empty set |
| `$env:SPECREW_MODULE_PATH=(Get-Location).Path; Invoke-Pester -Path 'tests/continuous-co-review/unit/orchestrator-reviewer-integrity.Tests.ps1' -PassThru` | pass | 7 | 0 | ~9s | 0 | FR-010 simplified: orchestrator never auto-runs the helper + injects no verification results; reviewer-invocation integrity fails on source/authority mutation, allows only .review/findings.jsonl, ignores volatile host dirs; honest strict-read-only prompt |
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
