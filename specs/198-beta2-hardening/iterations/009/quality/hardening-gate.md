# Hardening Gate: Iteration 009

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/198-beta2-hardening/spec.md`
**Iteration Ref**: `specs/198-beta2-hardening/iterations/009`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Planner
**Reviewed At**: 2026-07-26
**Post-Implementation Verification**: T072–T078 focused proof and three bounded-parallel complete registries plus serial parity are recorded; governance and independent review remain in T079.

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | Explicit exclusions are normalized, persisted, hashed, and applied to both digest and materialization; repository-relative paths remain contained; frozen consumer evidence is replayed only from disposable copies. | `true` | Candidate selection crosses the user-worktree/reviewer trust boundary and must not expose ignored credentials or mutate consumer evidence. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | Missing or mismatched engine markers, candidate/diff mismatch, unreadable candidate state, child-suite timeout, and missing provider result all fail closed with actionable diagnostics. | `true` | Silent fallback would run stale code, widen review scope, lose verification evidence, or duplicate provider spend. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `runtime-evidence` | `recorded` | Codex file delivery is primary and retries only when both file and stdout evidence are absent; each registry suite runs once per selected cycle; repeated snapshot construction produces the same source identity. | `true` | Provider and verification retries have cost and evidence side effects; replay must neither double invoke nor alter scope. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | Focused candidate, exclusion, engine-handshake, packaged-update, file-primary, and classification tests pass; frozen Article Amplifier replay passes; three 82/82 bounded-parallel registries and one 82/82 serial registry prove parity. | `true` | Candidate-fidelity fixes cannot be accepted from self-consistent unit fixtures alone; complete-registry and frozen-consumer proof are required. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `runtime-evidence` | `recorded` | Bounded concurrency, per-suite timeout, deterministic buffered output, serial tags for race-sensitive suites, machine-readable timing evidence, project/installed engine identity checks, and concurrent native-output draining with process-tree timeout preserve diagnosability. | `true` | The registry and review dispatcher are release machinery; concurrency, pipe deadlock, orphaned cleanup, or engine drift must not create intermittent or stale verification. | `—` |
| `candidate-source-identity` | `input-integrity` | `addressed` | `runtime-evidence` | `recorded` | One frozen Git-index source set includes tracked and untracked non-ignored product files, excludes ignored/runtime and authorized patterns, and binds the exclusion digest into target currentness. | `true` | F13/F16 proved that independently rediscovered source sets cannot converge. | `—` |
| `reviewer-independence-and-false-green-resistance` | `review-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Independent selection, escalation latching, substantive finding thresholds, and missing/invalid evidence blocking semantics remain unchanged; T079 performs independent review of the exact candidate. | `true` | Friction reduction must preserve the machinery’s demonstrated defect catch rate. | `—` |
| `provider-spend` | `cost` | `addressed` | `runtime-evidence` | `recorded` | A valid current-run Codex result file with empty stdout completes after one invocation; version mismatch stops before provider dispatch. | `false` | The historical retry doubled billing despite successful file delivery. | `—` |

## Fail-Direction Requirements

- A candidate/diff mismatch fails closed.
- An unreadable ignore/exclusion decision fails with actionable evidence; it
  does not silently widen or narrow the candidate.
- Parallel runner infrastructure failure reports the affected suite and fails
  the complete registry.
- Selected/partial registry execution cannot produce signoff evidence.
- Version mismatch cannot silently dispatch the stale engine.

## Value Preservation

Iteration 009 changes what is reviewed, not how substantive findings are
judged. It must increase candidate fidelity without weakening independent
review, escalation latching, drift-ledger discipline, or test-integrity
enforcement.
