# Iteration 007 Review Evidence

**Task**: T061
**Status**: needs rework — run 10 is a valid zero-finding pass for its exact snapshot, but canonical sync proved the committed review ledger moves the digest and campaign mode has no bounded finalization rule
**Overall Verdict**: needs-rework
**Reviewer**: Claude Code through the production `claude-code-file-primary` harness
**Recorded**: 2026-07-18
**Human Approval**: approved for review-signoff, 2026-07-18
**Reviewed Commit**: `fc1054b54badcfe2abded0203a1d785eeec0c59b`
**Reviewed-State Digest**: `5fc6318a300afc654bb09d986d82c8c925506ed3`

The maintainer's explicit instruction-bearing verdict authorizes exactly this review-signoff work and requires the complete T061 attempt-and-slot ledger below. Retrospective and iteration closeout remain separate human-verdict boundaries. Canonical sync is still blocked by DRIFT-198-I007-026, so this artifact no longer claims the crossing is complete.

## Review Mechanism

T061 used the Iteration 007 production campaign path itself: a clean external Git target, Claude's raw file-primary adapter, the Windows Job Object runtime, immutable grant/reservation/spend/run facts, strict candidate ingress, exact currentness, and controller-only terminal publication. The final reviewer was independent of the Codex implementer. No legacy inline review or substitute self-review is promoted as signoff evidence.

The final controller result is file:///C:/Dev/specrew-t061-fc1054b5/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-fc1054b5-10/result.json and its projection is file:///C:/Dev/specrew-t061-fc1054b5/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-fc1054b5-10/report.md.

## Current Authoritative Outcome

| Field | Authoritative value |
| --- | --- |
| Campaign | `cmp-198-beta2-hardening-i007` |
| Run | `run-t061-claude-windows-fc1054b5-10` |
| Authorization | `human-grant-t061-claude-windows-20260718-slot-10` |
| Completion | `complete` |
| Verdict | `pass` |
| Runtime outcome | `completed` |
| Validation | `valid` |
| Currentness | `current` |
| Containment | `verified` |
| Termination verified | `true` |
| Findings | `0` |
| Can approve current | `true` |
| Duration | `320563 ms` |
| Result SHA-256 | `175f3ffd1c6d5a10f0da87d092c52a4e3f74a97facd0d24501daadb8ffddaaa0` |

Run 10 reviewed the final collision-race correction plus the complete recent hardening chain, found no blocking, major, minor, or note issue, and explicitly verified FR-059, FR-060, NFR-007, and SC-018 behavior. The original repository remained unchanged and the result is bound to the exact commit and digest above.

## Complete T061 Attempt and Slot Ledger

| Attempt | Run / authorization reference | Commit / digest | Provider invoked | Spend facts | Terminal outcome | Findings | Approval effect |
| ---: | --- | --- | ---: | ---: | --- | ---: | --- |
| 1 | `run-t061-claude-windows-138915e7-01` / `human-grant-t061-claude-windows-20260717-slot-1` | `138915e7f0eafec0e41363a18be9873745ce6a9e` / `2228cbb92043919dbb71ff2fb758a89d6a0dcb9e` | no | 0 | public binding returned `not-started`: omitted design context became one blank explicit ref; renderer then masked it with missing `store_root` | 0 | no authority store or spend; cannot approve |
| 2 | `run-t061-claude-windows-8150a74f-02` / `human-grant-t061-claude-windows-20260718-slot-2` | `8150a74f53f0461c3a4eb24cf959e4558cdf99be` / `pending-target` | no | 0 | immutable `preflight-failed` after 19813 ms: long Windows target prefix exceeded the path boundary | 0 | grant/reservation recorded, no invocation or spend; cannot approve |
| 3 | `run-t061-claude-windows-2db52891-03` / `human-grant-t061-claude-windows-20260718-slot-3` | `2db52891d946ed94a98d181bf0b4edcea683ba6c` / `4bd751edd91d406c44fa0c60b681aa32fdd348e9` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 299969 ms | 3 | non-approving; DRIFT-017 correction input |
| 4 | `run-t061-claude-windows-fb2998d9-04` / `human-grant-t061-claude-windows-20260718-slot-4` | `fb2998d91a24607258557b380738570ff7d72a4c` / `66c219790e35b74157a04790d795bf3e69777dfa` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 314406 ms | 3 | non-approving; DRIFT-018 correction input |
| 5 | `run-t061-claude-windows-067dbe10-05` / `human-grant-t061-claude-windows-20260718-slot-5` | `067dbe108d382bb41255fa9f0146beb2d3ab1ac0` / `6cb5ceab53835a7ba7ac2055cd2098ac03b80910` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 350704 ms | 4 | non-approving; DRIFT-020 correction input |
| 6 | `run-t061-claude-windows-4bc832b9-06` / `human-grant-t061-claude-windows-20260718-slot-6` | `4bc832b927fc9f1047d1900147dacdbf8c46323e` / `8a08b74e28bd4ceb842670eea16fe2060289615e` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 318390 ms | 3 | non-approving; DRIFT-021 correction input |
| 7 | `run-t061-claude-windows-d4664736-07` / `human-grant-t061-claude-windows-20260718-slot-7` | `d4664736fc405be3442946dec6144a800cf9081a` / `62285e6f4355aa40c58b129396b99bfd4b5679ef` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 377641 ms | 1 | non-approving; DRIFT-022 correction input |
| 8 | `run-t061-claude-windows-dcb42d56-08` / `human-grant-t061-claude-windows-20260718-slot-8` | `dcb42d569ffd49b383c691911ffa51efaa24ce0c` / `7836b1219810361c26dbafc98faa3d8ceeccac39` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 320234 ms | 1 | non-approving; DRIFT-023 correction input |
| 9 | `run-t061-claude-windows-41b1b048-09` / `human-grant-t061-claude-windows-20260718-slot-9` | `41b1b048f8dcd1af5d344d88099104b398d32784` / `e847197c371f767b079a2255c0bb7fac6644b587` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 360094 ms | 1 | non-approving; DRIFT-024 correction input |
| 10 | `run-t061-claude-windows-fc1054b5-10` / `human-grant-t061-claude-windows-20260718-slot-10` | `fc1054b54badcfe2abded0203a1d785eeec0c59b` / `5fc6318a300afc654bb09d986d82c8c925506ed3` | yes, once | 1 | complete/current/valid pass; verified containment/termination; 320563 ms | 0 | approves the exact reviewed snapshot |

Ledger totals are mechanically reconciled: 10 unique attempt IDs and authorization references; 9 durable controller grant/reservation packages because attempt 1 failed before authority-store creation; 8 provider invocations; 8 immutable spend facts; 7 findings results containing 16 validated findings; 1 clean pass; 2662001 ms of observed provider-run duration. No attempt invoked more than once and no hidden retry occurred.

## Machine Evidence by Attempt

- Attempt 2: file:///C:/Dev/specrew-t061-8150a74f/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-8150a74f-02/result.json
- Attempt 3: file:///C:/Dev/specrew-t061-2db52891/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-2db52891-03/result.json
- Attempt 4: file:///C:/Dev/specrew-t061-fb2998d9/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-fb2998d9-04/result.json
- Attempt 5: file:///C:/Dev/specrew-t061-067dbe10/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-067dbe10-05/result.json
- Attempt 6: file:///C:/Dev/specrew-t061-4bc832b9/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-4bc832b9-06/result.json
- Attempt 7: file:///C:/Dev/specrew-t061-d4664736/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-d4664736-07/result.json
- Attempt 8: file:///C:/Dev/specrew-t061-dcb42d56/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-dcb42d56-08/result.json
- Attempt 9: file:///C:/Dev/specrew-t061-41b1b048/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-41b1b048-09/result.json
- Attempt 10: file:///C:/Dev/specrew-t061-fc1054b5/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-fc1054b5-10/result.json

Attempt 1 ended before authority-store creation, so it has no fabricated result path. Its exact no-spend failure and correction are recorded under DRIFT-198-I007-014 in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/007/drift-log.md.

## Task Verdicts

| Task | Verdict | Evidence summary |
| --- | --- | --- |
| T030 | pass | Genuine-human versus machinery-turn paired capture fixtures and final registry proof. |
| T031 | pass | Leading explicit-verdict tokenization, quote/teaching/bare-number rejection, and temporal/cursor guards. |
| T032 | pass | Exact fabrication sequences preserve ledger and pending artifacts when no human replies. |
| T033 | pass with deferred capture follow-up | Append-only correction door and effective readers are delivered; the review-signoff capture incident is recorded separately as DRIFT-025. |
| T034b | pass | Strict design-context selection, physical containment, and empty-context fail-closed campaign behavior. |
| T051 | pass | Public campaign command, one-way cutover, recovery surface, and current-review verdict gate. |
| T052 | pass | Workshop-intermediate Stop plus ordinary/boundary non-regression and materiality-key correction. |
| T053 | pass | Shared strict file-primary contract, five-vector catalog, and complete malformed-output matrix. |
| T054 | pass | Codex and Copilot production adapters invoke once and use file-only authority. |
| T055 | pass | Cursor and Antigravity production adapters invoke once and preserve strict ingress. |
| T056 | pass | Windows Job Object descendant containment, termination, and stream-closure proof. |
| T057 | pass | Linux cgroup-v2 and macOS process-group production runtime proof. |
| T058 | pass | Informational progress/timing/usage plus validated retrospective projection. |
| T059 | pass | Hosted deterministic fake-provider matrix is green on Windows, Ubuntu, and macOS. |
| T060 | pass with truthful Cursor qualification | Four live harness paths across three OSes are proved; Cursor execution is valid but no clean-current claim is made after Free quota exhaustion. |
| T061 | needs-work | Run 10 is a complete, valid, current, contained, zero-finding pass for commit `fc1054b5`; the required committed ledger moved the digest and canonical campaign sync correctly refused it as stale. |

## Correction Verification

- Final local release registry: all 57 registered suites passed in 701.2 seconds.
- Final hosted CI: run `29625537074` completed successfully at exact commit `fc1054b54badcfe2abded0203a1d785eeec0c59b`, including deterministic review-runtime jobs on Windows, Ubuntu, and macOS.
- Bidirectional traceability: 16/16 tasks and 25/25 scoped requirements; no orphan task, invalid reference, or uncovered scoped requirement.
- Scoped governance: PASS for file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/007/.
- Final no-spend preflight: exact commit/digest, clean current target, five design references, Claude readiness, Job Object readiness, and bounded Windows path projection all passed before attempt 10.

## Drift and Carry-Forward

All code/test/documentation findings through DRIFT-024 are corrected and independently closed by the final deterministic, hosted, exact-preflight, and clean run-10 chain. DRIFT-025 records the review-signoff capture episode discovered after run 10: injected environment-context ordering and an instruction-bearing verdict shape required the documented `human-confirmed-at-resume` path. The maintainer has explicitly deferred the stop/capture mechanism repair to later work; no runtime code is changed under this boundary.

DRIFT-026 is blocking: canonical `review-signoff` sync against boundary commit `b094e69b` returned `latest-result-not-current`. A direct read using the external run-10 store confirmed current digest `4b4e5ee7b7434eac4865342ae90f8a0e59a2cadb` versus run-10 digest `5fc6318a300afc654bb09d986d82c8c925506ed3`. Another provider run alone cannot close this because adding that run to the required committed ledger changes the digest again. No result is promoted and no bypass is inferred.

Cursor clean-current proof remains unavailable after free-credit exhaustion; support truth does not promote an older digest. FR-048/FR-049/SC-015 remains a separate open Beta2 command-plan dependency and still blocks T029 and feature closeout. Neither limitation blocks this bounded Iteration 007 review verdict.

## Gap Ledger

- No in-scope implementation, test, review, or evidence gap remains; all T061 findings were corrected and final run 10 is clean: fixed-now.
- DRIFT-198-I007-025 capture-selection repair is deferred with maintainer approval to the later stop/capture-mechanism slice; see `.squad\decisions.md` entry `defer-198-i007-025`.
- Cursor clean-current support remains unavailable after Free quota exhaustion, while live execution and the qualified support state are truthfully recorded: fixed-now.
- FR-048/FR-049/SC-015 remains outside the approved Iteration 007 scope and visibly blocks feature closeout until its own Beta2 slice: fixed-now.
- DRIFT-198-I007-026 campaign review-ledger finalization circularity remains open and blocks this review-signoff; it requires an explicit bounded architecture decision before closure.

## Acceptance Condition Status

Every paid T061 run remains visible, every correction was committed and re-verified before the next slot, attempts 1 and 2 consumed no provider spend, and attempts 3–10 each consumed exactly one spend fact. Run 10 provides independent approval of its exact snapshot, but the campaign gate cannot authorize the later ledger commit. Retrospective is not yet available.
