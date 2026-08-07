# Hardening Gate: Iteration 011

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/198-beta2-hardening/spec.md`
**Iteration Ref**: `specs/198-beta2-hardening/iterations/011`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available` (codex-cli-file-primary, independent of the code writer)
**Overall Verdict**: `deferred-with-approval`
**Approval Ref**: f198-i011-named-limitation-tag-basis
**Reviewed By**: Implementer (authored), Reviewer (codex, 3 certification rounds)
**Reviewed At**: 2026-08-06T13:19:56Z
**Post-Implementation Verification**: partial — `security-surface` carries an approved deferral; the other four are complete with runtime evidence
**Verified At**: 2026-08-06T14:05:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `deferred-with-approval` | `planning-time-analysis` | `pending-post-implementation` | FR-066's mint guard: a crossing that failed to record must never be convertible into an authorized cursor by any bootstrap path. FR-068's evidence binding: stage evidence read from the tree the crossing is BOUND to, tree-relative through `git -C $ProjectRoot`. | `false` | **Split result, recorded at half-granularity.** DELIVERED: evidence binding (closes DRIFT-198-I011-003's time-of-check false-authorization and the `$ProjectRoot`-ignored foreign-checkout hole) and the arrival state, both validated by certification round 2 and byte-unchanged since. **NOT DELIVERED: the mint guard.** Measured live — opening the next session converts a failed crossing into `last_authorized_boundary=specify` with an empty `verdict_history`, across three bootstrap sites funnelling through `Initialize-SpecrewBoundaryEnforcementState`. Two designs were built and both faulted by independent review (round 2: a double write-failure window; round 3: a concurrent clear of a project-wide latch), and both were REVERTED rather than shipped half-trusted. Enters beta3 as a design spike whose deliverable is the concurrency/failure matrix, priced before implementation. | `f198-i011-named-limitation-tag-basis` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | The evidence gate must FAIL CLOSED on anything it cannot verify, with a named reason, and "could not check" must never be spelled the same way as "exists". | `true` | Closes DRIFT-198-I011-005. Unknown boundary, unresolvable feature path, missing iteration identity, unreadable tree and the catch-all each return a distinct unverifiable reason that SUPPRESSES the demand instead of waving it through. The residual catch-all was found while landing finding 4 — it had survived the re-cut and would have re-armed a verdict demand against unverified evidence on any unexpected throw. Also corrected: a discriminator that existed on only one branch of a two-branch return, which threw under StrictMode on the HEALTHY path. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `runtime-evidence` | `recorded` | Re-running a boundary sync or a stop-block evaluation must not change the outcome, and no retry may convert an unverified state into an approved one. | `true` | The evidence gate is a pure read against an immutable tree id — re-reads are idempotent by construction. Verdict capture is idempotent by crossing identity (`crossing_id` is a hash over the crossing's fields; a duplicate hook fire for the same message is deduped, proven by conformance cases 22–24). **A concurrency defect WAS found here by round 3** — a project-wide refusal latch cleared unconditionally by any successful sync — and the machinery carrying it was reverted, so no shared-latch state remains in the tree. The next design starts from a concurrency/failure matrix rather than an implementation. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | Every correction must be proven by a RED→GREEN transition against the real production path, and negative paths must be observable rather than asserted. | `true` | Every fix this iteration carried a proven RED first; a fix without one was never trusted. Fixtures drive the REAL seams (the SessionStart hook, the real conformance provider, the real crossing writer) rather than primitives in isolation — the T089 lesson, where locally-correct code sat on an unreachable path. **INCONCLUSIVE is a required third outcome** and prevented five would-be false passes; four of the five would have read as passes under a two-outcome harness. Regression floor: `all 90 suites green in 504.054s`. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | Failures must be branchable states rather than console text, and a broken measurement must not read as a green one. | `true` | The unrecordable crossing travels as `RecordStatus`/`FailureReason` with `success=false` (NFR-002: a warning is not a state a caller can branch on). **Four measurement hazards were found and recorded**, each of which nearly produced a false conclusion: Git-Bash `tar` (phantom red — run the gate from PowerShell), a harness truncating its own error at 220 chars, `Write-Utf8FileAtomic` succeeding onto a directory destination so a write reports success where no reader looks (DRIFT-198-I011-009, carried to beta3 at MAJOR), and `git stash create` failing during an in-progress revert. One cure: read what the measurement measured before trusting its colour. | `—` |

## Post-Implementation Verification

**Partial, and named as such.** Four canonical concerns are complete with recorded runtime evidence. One
— `security-surface` — carries an **approved deferral**: FR-066's evidence binding and arrival state are
delivered and verified, its mint guard is not, and the difference is visible to anyone reading the tag
basis.

**This gate does not claim release readiness for FR-066.** Marking `security-surface` `addressed` here
would be the same over-claim the release gate caught in this iteration's first closure attempt — a
status asserting more than its artifacts support. The deferral is recorded against a human approval
reference instead, which is what that status exists for.

Two concerns carry defects that are real but do not block the beta2 tag under the named-limitation
basis, and both are carried to beta3 with their evidence attached rather than closed by assertion:
`DRIFT-198-I011-009` (atomic writer, MAJOR) and the concurrency design constraint on any future refusal
latch.
