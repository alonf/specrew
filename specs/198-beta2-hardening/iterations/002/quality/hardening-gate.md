# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/198-beta2-hardening/spec.md`
**Iteration Ref**: `specs/198-beta2-hardening/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Planner
**Reviewed At**: 2026-07-11T00:00:00Z
**Post-Implementation Verification**: pending (runtime evidence recorded at iteration close)

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | This iteration IS the trust-boundary work: the ratchet makes a second unapproved boundary advance impossible; reconciliation keeps the human at input provenance (retroactive approvals recorded with `kind: retroactive`; REVERSION is destructive and executes ONLY behind an explicit human confirm — never auto); the honesty check is fail-closed so the evidence bypass is earned, never defaulted; teaching texts follow the amended T096 reading (agent asks approve/deny, human never copy-pastes) and carry zero Specrew-internal identifiers. D5 untouched: nothing here overrides a blocking verdict. | `true` | Paired tests per invariant; the revert path's confirm requirement gets its own abuse test (no-confirm → no revert); message-content tests assert identifier hygiene. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The ratchet refusal is a structured loud outcome naming the skipped boundary and both doors — never a swallowed error or a silent pass-through; an unparseable cursor/verdict-history is a hard fail (never treated as delta zero); the honesty check's parse failure declines the bypass (stales as today, FR-020); budget resolution on a missing/malformed catalog row falls through the chain to the 600 floor (tolerant reader, I3) and says so. | `true` | Fixtures for corrupt start-context, missing verdict history, unparseable tracker claims, and absent catalog rows; each proves the loud/fail-closed direction. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Sync crossings stay idempotent per boundary (re-running sync for an already-recorded crossing is a no-op, F-174 preserved); the delta primitive is pure (same inputs, same answer — trivially re-runnable); a re-fired retroactive approval for an already-reconciled boundary is a no-op, not a duplicate history entry; the announced bypass re-evaluates deterministically per gate run. | `true` | Idempotence tests: double-sync, double-retro-approve, repeated gate evaluation on the same tree. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Iteration-001's LIVE incidents become the fixtures: the specify/review-signoff capture-latency sequences replay as ratchet/re-confirm tests; the reconcile-toward-truth vs falsify-forward pair (FR-020) uses real tracker shapes from iteration 001; budget resolution is proven across all four cascade positions with the REAL catalog rows; message-content assertions ride every teaching surface (SC-007 as amended). No claim rests on file existence. | `true` | The paired-honesty-tests custom rule is the review enforcement item; ledger counts derive from run output (retro improvement action #3 applies from this iteration). | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Enforcement lives entirely in scripts + data (hooks stay surfacing-only, FR-006) so every host gets identical teeth; the catalog stays the ONLY harness-data seam (budget rows are data, decided values: antigravity 900 / claude 600 / codex 600 / copilot 300 from field evidence); mirror parity for every extension-script change in the same commit; capacity 7.0/26 with the retro's 2x-review calibration acknowledged (honest forecast ~9 SP wall-clock); defer order T012 then T009 if a slice spills. | `true` | The four call sites consume ONE primitive (drift impossible by construction); validator + CI lanes unchanged otherwise; the W14 warning fires at resolution time so operators see downgrades before losing a cycle. | `—` |

## Before-Implement Conditions

| Condition | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `condition-a-human-authorization` | `met` | The `tasks -> before-implement` boundary stop is being presented now; implementation MUST NOT start until the human authorizes it. The design approval (Option B, decision commit `423175fc`) does NOT authorize implementation. | Implementation starts only on the explicit before-implement verdict. |
| `condition-b-live-state-safety` | `met` | T007-T009 modify the very machinery THIS session runs on (sync, resume, verdict capture). All changes land behind the existing test suites first; the session's own lifecycle state (.specrew/start-context.json) is never hand-edited as part of development; fixtures use temp copies. | If a change would require mutating this session's live boundary state to test, STOP — build the fixture instead. |
| `condition-c-fail-direction-review` | `met` | Every new check's fail direction is pinned before code: ratchet delta unparseable → hard fail; honesty check unparseable → decline bypass; catalog row absent → 600 floor; revert without confirm → refuse. | A fail-direction change during implementation is a spec drift — record it in drift-log.md with the FR citation before proceeding. |
| `condition-d-capacity-discipline` | `met` | Capacity 7.0/26 story_points planned; retro calibration says expect ~2x review wall-clock until T020 lands. Defer order: T012 first, then T009. | Do not silently expand past the planned slice; a spill triggers the human split/defer decision. |

## Notes

- Planning-time gate; per-concern Runtime Evidence Status flips to
  `recorded` with `runtime-evidence` basis at iteration close (the
  iteration-001 precedent shape).
- The catalog values carry the maintainer's design-gate approval
  (Option B defaults, 2026-07-11) including the measurement-evidence
  reading.
