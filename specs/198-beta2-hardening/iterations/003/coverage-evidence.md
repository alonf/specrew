# Coverage Evidence: Iteration 003

**Schema**: v1
**Reviewed**: 2026-07-12
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
- The whole-registry META-run (`tests/f198-regression-suite.ps1`) AND the governed real-dispatcher suite
  (`tests/integration/refocus-dispatcher.tests.ps1`, reused by the hook-suppression f1 test) are THEMSELVES
  recorded as digest-linked runner-observed evidence (script-suite exit + PASS-line count) — so the
  "18/18 registry green" / dispatcher pass claims here have runner-observed standing, not prose (co-review
  finding f1 test-evidence-honesty, 2026-07-12).
- Every suite is run FOR REAL in-session; the counts/exit/duration are runner-reported, never hand-typed.

## Tests Run

| Task | Suite | Result | Pass | Fail | Duration | Exit |
| ---- | ----- | ------ | ---- | ---- | -------- | ---- |
| T013 (FR-008) + T016 (FR-011/SC-003) | `worktree-containment.Tests.ps1` — outside-origin materialization; refuses inside/origin-itself; symlink/junction escape refused; shared physical-path helper (intermediate junction, in-scope link, plain path) + platform-appropriate-case predicate; T016 DETECTOR: SC-003 abuse (origin access → bounded/redacted `containment-violated` record) + legit (zero violations), redaction-at-source (only absolute path tokens extracted), false-kill guard (records, never kills), read-only sampler, STRUCTURED ARGV unit test (a quoted path with spaces is ONE token; the single-arg prompt yields NO path token) + STRUCTURED-ARGV sampler test (DRIFT-198-I003-004 root-cause fix: a quoted origin path with spaces is DETECTED not bypassed, the single-arg prompt naming origin is not flagged, a same-image worker + descendant real origin args stay observable → two violations, never the prompt; replaced the whitespace-split tokenizer + removed the prompt-subtraction workaround) + RELATIVE-TRAVERSAL abuse test (DRIFT-198-I003-004 stage 5, maintainer-approved fix: a `..` traversal escaping the worktree to an origin file is resolved against the reviewer cwd and DETECTED — silently dropped without a cwd) + FR-011 AMENDED (maintainer 2026-07-12): OPTION-ATTACHED `--name=value` origin path (absolute+relative) expanded and detected as an arg candidate; SAMPLER HEALTH (a CIM failure is recorded degraded, never silent); ALTERNATE-CHILD-CWD (relative-arg classification depends on the process cwd) | pass | 18 | 0 | ~9s | 0 |
| T014 (FR-009) | `origin-path-hygiene.Tests.ps1` — relativizes origin paths (all forms, multi-root); END-TO-END diff scrub | pass | 6 | 0 | ~5s | 0 |
| T015 (FR-010) prod + T016 (FR-011 amended) | `orchestrator-reviewer-integrity.Tests.ps1` — no auto-verification; reviewer-invocation integrity (source/authority/host-config mutation fails; findings.jsonl allowed; new host churn ok); honest prompt; T016 orchestrator (FR-011 AMENDED 2026-07-12): a STRONG signal (cwd/exe under origin) → failed/`containment-violated` + redacted record + findings discarded + disposition; an ARGV-only match → bounded diagnostic WARNING (review NOT discarded, findings PRESERVED) + `containment_warnings` + `sampler_health` (attempts/failures/final-sample-taken) recorded | pass | 10 | 0 | ~14s | 0 |
| T015 (FR-010) helper | `bounded-verification.Tests.ps1` — opt-in helper + removed-auto-rerun regression: timeout, process-tree kill, zero-disk byte cap, add/delete/modify + .review-authority mutation | pass | 11 | 0 | ~12s | 0 |
| T020 (FR-018/019, amended) | `review-spend-allowance.Tests.ps1` — two-budget classifier; preflight (no spend/round); post-invocation failed (spend+round); ceiling counts only reviewed rounds; consumer-legible halt; FR-019 SPLIT (DRIFT-198-I003-005): resolved-against-disk PRESERVES the spent rounds (never implicitly replenishes); allowance-reset is the separate human-approved replenish (records authorizer/when/prev-new, leaves resolved-finding evidence intact, requires --ack-reason) | pass | 13 | 0 | ~8s | 0 |
| T034b (FR-012, reuse of cca79708) | `review-context-and-harvest-hardening.Tests.ps1` — strict design-context: mixed/all-invalid/traversal/rooted/intermediate-dir-junction refs FAIL before reviewer selection (reviewer never invoked), valid in-repo ref passes, POSIX case-distinct sibling rejected (the +1 POSIX-only test, skipped on Windows); plus f1/f2 design-context + harvest | pass | 18 | 0 | ~9s | 0 |
| codex-reviewer hardening (empty-exit0) | `reviewer-hook-suppression.Tests.ps1` (reviewer spawn passes SPECREW_REFOCUS_DISABLE=1; dispatcher exits before governance when it inherits it; PAIRED via the REAL dispatcher in the SHARED governed fixture — the reviewer host's own hook inherits suppression (NO refocus marker) while a bounded-verification child clears it, reaches the real dispatcher, and governance PRODUCES the `[specrew-refocus] trigger=b1` marker; codex finding f1 + its round-2 escalation on the earlier env-proxy test) + `reviewer-file-primary-result.Tests.ps1` (a clean-exit, current-run, fully-contract-validated `.review/findings.jsonl` is a FULL file-primary result — no wasteful T108 retry, no 'partial' mislabel; FAIL-CLOSED on malformed/truncated/stale/mismatched-run/absent/empty; normal stdout-primary hosts unchanged) | pass | 14 | 0 | ~6s | 0 |
| `& ./tests/f198-regression-suite.ps1` | pass | 18 | 0 | ~100s | 0 | Whole-feature honesty gate: 18 suites (ratchet, spend allowance, containment, origin hygiene, bounded-verification helper + reviewer-integrity, tracker honesty, verdict capture, budget, signoff gate, shared-engine, digest/exec-bit, reviewer hook-suppression, file-primary result) |

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
| FR-011, SC-003 (AMENDED 2026-07-12 — T016 containment MONITOR: FR-008/T013 structural guarantee; cwd/exe-under-origin = HARD `containment-violated`; argv = best-effort diagnostic WARNING that never discards a valid review; sampler health recorded so weak visibility is never silent; never mid-flight kill) | tests/continuous-co-review/unit/worktree-containment.Tests.ps1 (checker + false-kill guard + read-only sampler + structured-argv + relative-traversal + option-attached + sampler-health + alt-cwd), tests/continuous-co-review/unit/orchestrator-reviewer-integrity.Tests.ps1 (strong-signal hard-fail + argv-warning-not-discarded) |
| FR-013 (reviewer taught what is absent; strict read-only) | tests/continuous-co-review/unit/orchestrator-reviewer-integrity.Tests.ps1 (honest-prompt cases) |
| FR-018, FR-019 (spend allowance + two-budget) | tests/continuous-co-review/unit/review-spend-allowance.Tests.ps1 |
| NFR-007 (CI enforcement) | tests/f198-regression-suite.ps1 (blocking CI step) |
