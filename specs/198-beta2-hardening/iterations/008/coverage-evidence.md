# Coverage Evidence: Iteration 008

**Schema**: v1
**Reviewed**: 2026-07-20
**Overall Verdict**: pass for T066 review-signoff
**Reviewed-State Digest**: `45255b42eb97820858c9cd858956e7c78ad0a591`

## Executed Evidence

| Evidence | Result | Binding |
| --- | --- | --- |
| Feature 198 release registry | 73/73 registered suites green in 783.5 seconds | T071 corrected implementation commit `b3fb1ab3` |
| Scoped Iteration 008 governance | PASS in 11.2 seconds | T071 corrected implementation commit |
| T071 hosted proof `29775507402` | success, all eight jobs | Exact commit `b3fb1ab3037342ec7677cad694a0f7567789b7c2`; Windows, Ubuntu, and macOS paths |
| Final candidate hosted proof `29775891668` | success, all eight jobs | Exact reviewed commit `659bec289646a2fa6f062973a94d2cbd3249632f` |
| T071 controller containment proof | provider-free byte identity, disposable verification, external evidence, startup vector, read-only probes, and cleanup pass | file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/008/quality/t071-controller-containment-proof.json |
| Claude/Windows independent signoff | attempt 10 complete/pass/current/valid; zero findings | Exact reviewed parent/digest; Job Object containment and termination verified |
| Bidirectional traceability | PASS, 19/19 tasks and 32/32 selected requirements | No orphan task, invalid selected reference, or uncovered selected requirement |
| Attempt/slot reconciliation | 10 attempts, 8 invocations, 8 spends, 17 findings, one clean pass | Immutable campaign authority store and file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/008/review.md |
| Bounded review finalization | one direct child, six-file allowlist, one immutable fact | Carries review evidence without reopening the implementation digest |

The earlier push run `29773556546` is not authority because its hosted macOS runner wedged and the run was cancelled. The corrected exact-commit retry and the final-candidate CI are the authoritative hosted proofs.

## Requirement Coverage

| Requirement group | Review status | Executable evidence |
| --- | --- | --- |
| FR-041, FR-042, FR-044, FR-045 | verified | Stale-binding rebind, effective-state resolution, actual-identity pairing, and current/stale refusal fixtures |
| FR-055, FR-056 | verified | Owner-scoped capture, genuine turn-start baselines, host-independent deltas, and all five prompt adapters |
| FR-048, FR-049, SC-015 | verified | Governed plan supplier, guarded materializer, frozen-target runner, exact-digest evidence injection, pre-spend refusal, and end-to-end matrix |
| FR-024–FR-032 | verified | Methodology/work-kind workflow deployment, consumer allowlist, local host config, hash-guard update, bootstrap, and release-model teaching |
| FR-035, FR-036, FR-046, FR-047 | verified | Deny-list pairs, heterogeneous prompt fixtures, technology/delivery applicability, and self-leak firewall |
| NFR-002, NFR-007 | verified | Truthful user-visible state, no false “this turn” count, paired false-allow/false-deny integrity tests, and no authority from stale evidence |
| FR-040, SC-012, SC-013 | implementation reviewed; execution pending | Version/release surfaces remain behind T029's separate authorization |
| SC-014 | pending published artifact | T067 must install and exercise the actual published beta; stable promotion is excluded |

## Integrity Notes

- Fake-provider CI proves deterministic contracts only and never counts as live provider support.
- Attempts 01, 02, and 05–09 remain visible non-approving evidence; none is promoted as signoff.
- Attempts 03 and 04 stopped before provider invocation and have zero spend facts.
- Every invoked T066 attempt has exactly one spend fact and one unique authorization reference.
- Final review authority is file:///C:/Dev/specrew-beta2-hardening/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i008/runs/run-t066-claude-windows-659bec28-45255b42-10/result.json.
- The finalization fact lives outside the reviewed digest and binds the clean run, reviewed commit/digest, and sole allowed finalization commit exactly once.
- T029 release and T067 published-beta dogfood are deliberately absent from the completion claim.
