# Hardening Gate: Iteration 003

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/202-beta4-1-ux-stabilization/spec.md`
**Iteration Ref**: `specs/202-beta4-1-ux-stabilization/iterations/003`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Planner (Claude), planning-time analysis; the codex co-review covers the lenses at implement
**Reviewed At**: 2026-10-21T14:35:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | A hook acts only for its own host on every channel the host runs, Claude's hooks under Copilot included, matched by declared payload shapes (T026). A payload carrying a sub-agent field is host-injected and never records an approval, on any channel (T028). A closeout records "closed" (the closed-iterations entry, the active-feature clear, the session-lock release) only in the human approval's capture, never when the closeout is asked for (T031, T032). The append-only ledger is never rewritten. No new dependencies. | `true` | The iteration's scope is again the trust boundary between a human act and the records that follow from it: a second host's hooks, a model-written sub-agent prompt, and a record written ahead of the human's decision are each a record the human did not make. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | An unrecognized payload is still handled and logged once, and now every log has a reader that fails a check (T027). A declined or re-asked closeout leaves the closed-iterations index, the active feature and the session lock as they were (T031, T032). | `true` | No human act is dropped without a trace, and no unapproved decision leaves a trace that reads as approved. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | A closeout asked again adds nothing; the approval's capture adds the closed-iterations entry once (the existing idempotent append). The seal stays the capture's last write (B4F-063). | `true` | B4F-146 was seen twice in one day because the closeout was asked twice. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T025 to T029 were written red first against payloads captured live on Copilot 1.0.101, Claude 2.1.303 and Codex 0.163.0 (the probe passes 108 of 108). T031 and T032 land red first through the real sync and the real capture, in temp projects with the repository's stores guarded (B4F-148). SC-011 is proven live by the maintainer's re-walk with the capture hook, and its captures become fixtures. | `true` | The iteration-002 fix passed its tests and failed live because its fixtures came from the wrong channel; every test here runs on captured payloads or the shipped entry point. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The re-walk counts hook rows under `claude` and unrecognized-payload records and expects 0 of each. The capture hook is installed and removed by a script and leaves the user's settings as they were. No CI workflow change is planned. | `false` | 202 ships no server surface; operability is local visibility of what the hooks recorded. | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/202-beta4-1-ux-stabilization/iterations/003/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/202-beta4-1-ux-stabilization/iterations/003/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/202-beta4-1-ux-stabilization/iterations/003/quality/lenses/test-integrity.md` |

## Notes

- This is a planning-time artifact. Runtime evidence is collected after implementation in the planned evidence paths.
- T025 to T029 were implemented in iteration 002 before the move (`2fd7f2d6`); this gate covers them as written and
  T031 and T032 as planned. The review round also reads round 8's fixes (`ac87d96c`).
