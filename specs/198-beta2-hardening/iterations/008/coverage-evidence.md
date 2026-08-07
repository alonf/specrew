# Coverage Evidence: Iteration 008

**Schema**: v1
**Reviewed**: 2026-07-21
**Overall Verdict**: pass for T066 review-signoff
**Reviewed-State Digest**: `eb9643d51780361d1009ba3267e7e14cb011b385`

## Executed Evidence

| Evidence | Result | Binding |
| --- | --- | --- |
| Feature 198 registry | 73/73 green in 840.8 seconds during preparation; green again inside attempt 11 | Exact corrected candidate |
| Scoped Iteration 008 governance | PASS in 11.2 seconds; green again inside attempt 11 | Exact corrected candidate |
| Focused finalization regressions | 40/40 green in 43.59 seconds | Local overlay allowed; ordinary settings denied |
| Candidate CI `29781470846` | success, all eight jobs | Exact reviewed commit `9a6b88540088be2ff82fec145079b3f8765e863e` |
| T071 controller-containment proof | provider-free byte identity, disposable verification, external evidence, startup vector, read-only probes, cleanup | file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/008/quality/t071-controller-containment-proof.json |
| Claude/Windows independent signoff | attempt 11 complete/pass/current/valid; zero findings | Exact reviewed parent/digest; Job Object containment and termination verified |
| Bidirectional traceability | PASS, 19/19 tasks and 32/32 selected requirements | No orphan or uncovered selected scope |
| Attempt/slot reconciliation | 11 attempts, 9 invocations/spends, 17 findings, two clean passes | Immutable authority store and file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/008/review.md |
| Bounded finalization | one direct child, six-file allowlist, one immutable fact | Carries evidence without reopening implementation digest |

The earlier T071 push run `29773556546` is not authority because its hosted macOS runner wedged and the run was cancelled. T071 retry `29775507402` and candidate run `29781470846` are the relevant successful hosted proofs.

## Requirement Coverage

| Requirement group | Review status | Executable evidence |
| --- | --- | --- |
| FR-041, FR-042, FR-044, FR-045 | verified | Actual-identity rebind and current/stale refusal fixtures |
| FR-055, FR-056 | verified | Owner-scoped capture, genuine turn-start baseline, all five prompt adapters |
| FR-048, FR-049, SC-015 | verified | Plan supplier/materializer/runner, exact evidence injection, pre-spend refusal, end-to-end matrix |
| FR-024–FR-032 | verified | Workflow deployment, consumer allowlist, local config, guarded update, bootstrap, release-model teaching |
| FR-035, FR-036, FR-046, FR-047 | verified | Deny-list, heterogeneous prompts, applicability, self-leak firewall |
| NFR-002, NFR-007 | verified | Truthful visible state, paired integrity tests, no stale authority |
| FR-040, SC-012, SC-013 | implementation reviewed; execution pending | T029 remains behind separate release authorization |
| SC-014 | pending published artifact | T067 installs and exercises the actual beta; stable promotion excluded |

## Integrity Notes

- Fake-provider CI proves deterministic contracts only and never live support.
- Attempts 01–10 remain visible; none is promoted beyond its exact target.
- Attempts 03 and 04 stopped before provider invocation and have zero spend facts.
- Every invoked T066 attempt has exactly one spend fact and unique authorization.
- Final authority is file:///C:/Dev/specrew-beta2-hardening/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i008/runs/run-t066-claude-windows-9a6b8854-eb9643d5-11/result.json.
- The finalization fact lives outside the reviewed digest and binds run, reviewed digest/commit, and sole finalization commit once.
- T029 release and T067 dogfood are absent from the completion claim.
