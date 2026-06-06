# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/170-retire-evaluation-surface/spec.md`
**Iteration Ref**: `specs/170-retire-evaluation-surface/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-06T19:30:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | — | `false` | The slice deletes stale repository files, relocates a test-support script, and edits docs. No authentication, authorization, secrets, or privacy-sensitive data is touched; the start-context security hint is generic and does not materialize here. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | The report test must tolerate a missing scratch directory: the scorer's `Resolve-ReportPath`/write path creates the report directory on demand, and both integration tests rebuild their scratch trees from scratch. T003 records the runtime proof. | `true` | Spec edge case (missing scratch dir on fresh clone) is the only failure-semantics surface; the planned control is on-demand directory creation already present in the moved scorer, verified empirically at T003 rather than assumed from code reading. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | — | `false` | Deterministic local test scripts with no queues, network calls, background work, or recovery workflows. Re-runs are naturally idempotent because each test deletes and rebuilds its scratch tree. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | AC2-AC4 must be proven by running the real suites (exit codes + run logs in quality-evidence.md), not inferred from file presence. T002-T004 are the runtime layer; T007 consolidates the evidence. | `true` | The whole slice is test-continuity; the beta-validation lesson (2026-05-31) makes file-presence acceptance explicitly insufficient. Verification-first task ordering enforces this. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | CI job names and test semantics stay frozen (proposal out-of-scope guarantee); both `handoff-governance-validator.ps1` mirrors must stay in parity; the SC-004 scan proves no active surface dangles on the deleted path. | `false` | The move must be invisible to CI; mirror parity and the reference scan are checked at T005/T007 and re-checked at review. | `—` |
| `branch-hygiene-and-dirty-drift` | `governance-integrity` | `addressed` | `runtime-evidence` | `recorded` | Proposal-145 gate preflight before every approval packet (scoped validator, parity, dirty-state classification); path-limited staging keeps session drift (design-workshop deploy dirs, `.cursor/`, session caches, F-159 leftover) out of 170 commits. | `true` | Adoption-before-governance is this feature's declared conflict (TG-004); preflight discipline is the active control, already exercised at the plan gate (parity + dirty-state gaps caught and fixed). | `—` |
| `proposal-145-review-discipline` | `review-quality` | `addressed` | `runtime-evidence` | `recorded` | Gate-local preflight at every remaining boundary; the full seven-phase structured review at review-signoff, including a claim-to-evidence ledger and a delta-only diff audit against the adoption snapshot. | `true` | Maintainer explicitly invoked Proposal 145 at the plan gate; the two-tier model (cheap per-gate preflight + deep review-signoff) is recorded as the operating contract for this feature. | `—` |

## Notes

- Closure follow-through (2026-06-06): the four addressed rows flipped to
  runtime-evidence/recorded — proof in quality-evidence.md ("Hardening-Gate Runtime Follow-Through" table): T003 scratch rebuild + exit 0; T002-T004 executed suites; mirror-parity diff; per-boundary 145 preflights + the manual 145-style review at signoff.
- No deferred-with-approval rows; no human deferral decisions outstanding.
- Release-blocking rows: error-handling, test-integrity, branch-hygiene,
  145-review-discipline.
