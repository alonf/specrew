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
**Post-Implementation Verification**: closed at the 2026-07-30 iteration-closeout with verification GREEN and certification NOT ACHIEVED — see `## Closure Follow-Through` below. Final state: registry 87/87 (the path-identity family was registered during this iteration, 82 → 87), bootstrap suites green, markdownlint clean, the three-OS matrix green with per-leg measurements read directly from the job logs, serial parity green, and both controller verification commands green against the exact target digest on every round. Eight independent Codex rounds were spent; the final one, `run-f198-i009-3d74f123-final` at digest `85bdfe01`, completed current/valid under verified containment and reported two majors of the path-identity/containment class (DRIFT-198-I009-041, -042), firing the pre-agreed termination rule. Disposition of record is the narrowed beta2 release claim, not a clean certification; corrections carry to Iteration 010. All immutable results are under `evidence/`.

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | Explicit exclusions are normalized, persisted, hashed, and applied to both digest and materialization; repository-relative paths remain contained; frozen consumer evidence is replayed only from disposable copies. | `true` | Candidate selection crosses the user-worktree/reviewer trust boundary and must not expose ignored credentials or mutate consumer evidence. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | Missing or mismatched engine markers, candidate/diff mismatch, unreadable candidate state, child-suite timeout, and missing provider result all fail closed with actionable diagnostics. | `true` | Silent fallback would run stale code, widen review scope, lose verification evidence, or duplicate provider spend. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `runtime-evidence` | `recorded` | Codex file delivery is primary and retries only when both file and stdout evidence are absent; each registry suite runs once per selected cycle; repeated snapshot construction produces the same source identity. | `true` | Provider and verification retries have cost and evidence side effects; replay must neither double invoke nor alter scope. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | Focused candidate, exclusion, engine-handshake, packaged-update, file-primary, classification, native cleanup, long-path disposal, and POSIX bounded-observation tests pass; frozen Article Amplifier replay passes; three 82/82 bounded-parallel registries and one 82/82 serial registry prove parity. Measured slow suites retain explicit bounded 420-second ceilings while the remaining 80 keep 300 seconds. | `true` | Candidate-fidelity fixes cannot be accepted from self-consistent unit fixtures alone; complete-registry and frozen-consumer proof are required, while timing ceilings must not create known near-zero-margin false reds. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `runtime-evidence` | `recorded` | Bounded concurrency, per-suite timeout, deterministic buffered output, serial tags for race-sensitive suites, machine-readable timing evidence, project/installed engine identity checks, concurrent native-output draining with process-tree timeout, and process-local Windows long-path Git support preserve diagnosability and cleanup. | `true` | The registry and review dispatcher are release machinery; concurrency, pipe deadlock, orphaned/stranded cleanup, long paths, or engine drift must not create intermittent or stale verification. | `—` |
| `candidate-source-identity` | `input-integrity` | `addressed` | `runtime-evidence` | `recorded` | One frozen Git-index source set includes tracked and untracked non-ignored product files, excludes ignored/runtime and authorized patterns, and binds the exclusion digest into target currentness. | `true` | F13/F16 proved that independently rediscovered source sets cannot converge. | `—` |
| `reviewer-independence-and-false-green-resistance` | `review-integrity` | `addressed` | `runtime-evidence` | `recorded` | Codex independently reviewed exact commit `29e9f6fa` after both controller commands passed and blocked approval with one blocking and two major grounded findings; missing/incomplete evidence also remained non-approving. | `true` | The catch rate is preserved: the review machinery surfaced a snapshot escape plus recovery and update convergence defects that deterministic tests had missed. These findings must be corrected before signoff. | `—` |
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

## Closure Follow-Through

Recorded at the 2026-07-30 iteration-closeout. Every concern above closes with
`Runtime Evidence Status: recorded` and real runtime evidence in this iteration —
none required the successor-iteration disposition that DRIFT-198-I009-021 describes
as missing from the schema.

This section exists to keep one distinction explicit, because the gate has no field
for it: **the concerns are satisfied by VERIFICATION, which passed. They are not a
claim that the iteration achieved CERTIFICATION, which it did not.**

- `reviewer-independence-and-false-green-resistance` is the concern most directly
  tested this iteration, and it held in an uncomfortable direction: eight independent
  rounds each found real defects, including in the corrections of the round before,
  and the review gate refused approval every time. False-green resistance was
  demonstrated by the gate declining to certify, not by a clean pass.
- `candidate-source-identity` carried the canonical-versus-mirror lesson twice
  (DRIFT-198-I009-030 and -037): a correction verified against the wrong artifact
  ships nothing. Both trees are now covered by the structural mirror-parity assertions.
- `provider-spend` closed clean: eight rounds, eight recorded spends, no unspent or
  double-spent grant; two runs failed pre-spend and correctly consumed no provider
  budget.
- `test-integrity-targets` is the concern with the most honest residual. The
  differential harness's fixtures do not span link states, which is precisely where
  DRIFT-198-I009-042 hid, and the case-distinct firewall fixture required by
  DRIFT-198-I009-040 was never added (DRIFT-198-I009-043). Both carry to Iteration 010.

Where the evidence lives: immutable review results under `../evidence/`; verification
and per-volume measurements in `../review.md`; the full defect ledger in
`../drift-log.md`; the release position in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta2-release-claim.md.
