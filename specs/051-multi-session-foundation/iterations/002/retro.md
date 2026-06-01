# Retrospective: Iteration 002 — Iteration 2a: Collision Detection & Feature Claims

**Schema**: v1
**Date**: 2026-05-31

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T020 | 1 | 1 | 0 |
| T020b | 0.5 | 0.5 | 0 |
| T020c | 0.5 | 0.5 | 0 |
| T021 | 1 | 1 | 0 |
| T022 | 0.5 | 0.5 | 0 |
| T023 | 1 | 1 | 0 |
| T024 | 1 | 1 | 0 |
| T025 | 0.5 | 0.5 | 0 |
| T026 | 0.5 | 0.5 | 0 |
| T026b | 0.5 | 0.5 | 0 |
| T027 | 1 | 1 | 0 |
| T028 | 0.5 | 0.5 | 0 |
| T029 | 0.5 | 0.5 | 0 |
| T030 | 1 | 1 | 0 |
| T031 | 0.5 | 0.5 | 0 |
| T032 | 0.5 | 0.5 | 0 |
| T033 | 0.5 | 0.5 | 0 |
| T033b | 0.5 | 0.5 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done | done | 0 | The 12 SP re-sum held; the 2a split stayed within the 20 SP cap. |
| Discovery/Spikes | 0 | 0 | 0 | Research decisions R2/R3/R4 were sufficient; no extra spike was needed. |
| Implementation | ~8.5 SP | ~8.5 SP | 0 | Core modules and call-site wiring landed without scope expansion. |
| Review | ~2 SP | high | + | Structured review found real branch/state-truth/reporting gaps across three send-back rounds. |
| Rework | ~1.5 SP | high | + | Code rework was low; governance artifact rework was underestimated. |

## Drift Summary

- Total drift events: 1
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- The implementation itself stayed within the Iteration 2a scope: local session locks, feature claims, stale-lock cleanup, collision warnings, conflict continue/decline behavior, boundary refresh, and closeout cleanup all shipped with focused tests.
- The D-003 split held under review: rich machine fingerprints remain gitignored/local-only, while committed claims carry only coarse `user@machine`.
- The concurrency guarantee stayed honest. Tests and docs verify torn-write safety plus last-write-wins reconciliation, not a false all-writers-atomically-merged claim.
- Proposal 145 structured review and Proposal 082 push-parity discipline caught real closeout blockers before the iteration advanced.

## What Didn't Go Well

- Review-signoff took three send-back rounds after the content was accepted. The misses were mostly durable-state truth and artifact-ledger coherence, not implementation behavior.
- Round 1 caught push parity and uncommitted `.squad/decisions.md`; the accepted boundary review existed only locally until the reviewer forced a push-parity check.
- Round 2 caught stale lifecycle prose across `state.md`, `plan.md`, `.squad/identity/now.md`, and `hardening-gate.md`; frontmatter/structured fields were not enough.
- Round 3 caught `review-report.yml` lagging behind round-2 remediation and duplicate `## Notes` template residue in `state.md`.
- The review-signoff sync halted on markdownlint auto-fixes, proving again that sync exit status must be treated as load-bearing and committed before continuing.

## Improvement Actions

1. Owner: tooling | Phase: small-fix slice before remaining F-051 iterations | Type: validator | Promote Proposal 142 validator expansion ahead of Iterations 2b/3/4. Add checks for frontmatter/body lifecycle contradictions, duplicate scaffold headings, stale lifecycle phrases, uncommitted `.squad/decisions.md`, and review-report remediation-count drift.
2. Owner: methodology | Phase: review | Type: process | Promote Proposal 102 cross-model reviewer ahead of remaining F-051 iterations. This feature produced 6+ depth-N+1 catches; independent review depth is no longer theoretical.
3. Owner: tooling | Phase: scaffold maintenance | Type: template fix | Fix the iteration-plan and iteration-state scaffold sources that emitted stale lifecycle boilerplate (`Status stays planning...` and duplicate generic `## Notes` blocks) in Iterations 1 and 2.
4. Owner: methodology | Phase: every remediation round | Type: review discipline | If `review-report.yml` exists and any round-N remediation happens, update the structured report in the same repair commit before re-presenting.
5. Owner: tooling | Phase: sync hardening | Type: process+bug | Treat any halted sync as a boundary blocker: inspect the generated diff, commit required fixes, rerun sync, and verify state after sync. The markdownlint gate did the right thing, but the workflow must make the halt impossible to miss.
6. Owner: methodology | Phase: boundary closeout | Type: audit | Whole-file re-read remains mandatory for every load-bearing artifact; grep for known stale phrases is insufficient because each round introduced new variants.

## Calibration Suggestion

- Suggested capacity adjustment: keep the 12 SP delivery estimate for comparable implementation slices, but explicitly budget review/governance artifact remediation as a separate risk buffer.
- Rationale: task effort was accurate; the underestimated cost was review depth, state-truth repair, push discipline, and durable report maintenance.

## Notes

- Retro complete. Next lifecycle gate is iteration-closeout.
