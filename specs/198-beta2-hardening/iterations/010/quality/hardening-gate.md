# Hardening Gate: Iteration 010

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/198-beta2-hardening/spec.md`
**Iteration Ref**: `specs/198-beta2-hardening/iterations/010`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `f198-i010-plan-approval-stream-a-only`
**Reviewed By**: Planner
**Reviewed At**: 2026-07-31
**Post-Implementation Verification**: pending — certification evidence and the 3-round cap are defined in `../plan.md` under `## Certification and the Termination Rule`.

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Containment must hold against reparse points at the authority-store root and at every campaign/run ancestor, before any enumeration, directory creation, read or write. The store holds grants, reservations, spend and results — the evidence chain every certification claim rests on. Git carries symlinks in tree objects, so an attacker-authored link arrives by CHECKOUT of an untrusted branch or fork PR, with no local user action; Specrew runs over branches under review, which makes the checkout itself the exposure. | `true` | T082 with a real linked-ancestor regression, plus T080 fixtures placing links AT the store root and at campaign/run ancestors. Fixtures must be RED against pre-fix HEAD. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Containment refusal is fail-closed and loud: a reparse point in the resolved chain refuses the operation rather than proceeding on a lexical pass. The case probe returns `$null` (undetermined) rather than guessing when a link state cannot be resolved, and every caller states its safe direction. | `true` | Paired tests per refusal direction; the undetermined path exercised, not just the determined ones. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `planning-time-analysis` | `not-needed` | This iteration adds no new retry, lease, or resumable operation. The authority-store writes it hardens are already append-only with existing idempotency guarantees, unchanged here. | `false` | — | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | **The central concern of this iteration.** Iteration 009's differential harness proved the primitive's answers on three real volumes and still missed DRIFT-198-I009-042, because its fixtures contained zero link states. Every T080 fixture MUST be demonstrated RED against pre-fix HEAD with the output recorded; a fixture that passes before the fix proves nothing. The volume remains the oracle — no authored expectations for link behaviour, measure what the OS does on each runner. The mutation gate extends to link states and must itself be proven able to fail against a link-blind primitive. | `true` | T080 RED evidence in the drift log; T081 mutation results per volume; `[volume-oracle]` measurements read directly from each job log rather than inferred from a green conclusion. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Fixtures must degrade honestly where a runner cannot materialize them: a Windows junction has no ext4 equivalent, and an unprivileged Windows runner may not create symlinks. Where a volume cannot materialize a fixture, that failure IS the measurement and must be recorded as such — never silently skipped, which is the DRIFT-198-I009-019 pattern. | `true` | Per-leg emitted measurements; no platform-conditional skips that hide an unexercised assertion. | `—` |
| `review-round-economy` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Round cap 3, agreed in advance. Iteration 009 spent eight and every round after the third found defects introduced by the round before it. A new blocking or major finding of a class already corrected here terminates the campaign in favour of the narrowed-claim update. | `true` | The termination rule in `../plan.md`; certification requires exactly one clean certifying review, not an open-ended sequence. | `—` |

## Before-Implement Conditions

1. **T080 precedes T082 and T083.** Fixtures first, proven RED. This is the finding, not a
   sequencing preference.
2. **No authored link expectations.** The volume is the oracle; each runner's behaviour is
   measured and asserted against.
3. **Push per focused commit; check every workflow individually before the next cycle.**
   A red workflow is a stop.
4. **Untruncated CI logs only** — `gh api repos/<owner>/<repo>/actions/jobs/<id>/logs`. Do not
   trust an exit code taken from a pipeline truncated by `Select-Object -First`.
5. **Scoped validator during work, full validator before commit.**
6. **Never edit the tree while a registry or review run is in flight.**

## Notes

Iteration 009's residual risk is carried here explicitly: four of that iteration's defects were
introduced by its own corrections. The mitigation this iteration adopts is not "be more careful"
— it is fixtures that span the state space, written first and proven able to fail.
