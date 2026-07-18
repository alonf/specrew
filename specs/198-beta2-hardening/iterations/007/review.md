# Iteration 007 Review Evidence

**Task**: T061
**Status**: pass — clean independent run 13 approves the reviewed parent and the bounded finalization envelope carries these six review artifacts without reopening the implementation digest
**Overall Verdict**: pass
**Reviewer**: Claude Code through the production `claude-code-file-primary` harness
**Recorded**: 2026-07-18
**Human Approval**: approved for review-signoff and for serialized additional invocations while concrete progress continued, 2026-07-18
**Reviewed Commit**: `58869dfe343e1183c08e22ed1a1dd7419a75dc71`
**Reviewed-State Digest**: `7c225e535f34597501ba1b3f0a80facfa7639e3e`

The maintainer required the complete T061 attempt-and-slot ledger and approved a small controller-owned finalization envelope. The envelope permits one direct child of the reviewed commit containing only the six enumerated review-evidence files, validates that diff deny-by-default, and publishes one immutable binding fact outside the reviewed digest. The signoff gate records and displays the pair “reviewed at X, finalized as F.” Retrospective and iteration closeout remain separate human-verdict boundaries.

## Review Mechanism

T061 used the Iteration 007 production campaign path itself: a clean external Git target, Claude's raw file-primary adapter, the Windows Job Object runtime, immutable grant/reservation/spend/run facts, strict candidate ingress, exact currentness, and controller-only terminal publication. The final reviewer was independent of the Codex implementer. No legacy inline review or substitute self-review is promoted as signoff evidence.

The final controller result is file:///C:/Dev/specrew-t061-authority-58869dfe/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-58869dfe-13/result.json and its projection is file:///C:/Dev/specrew-t061-authority-58869dfe/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-58869dfe-13/report.md.

## Current Authoritative Outcome

| Field | Authoritative value |
| --- | --- |
| Campaign | `cmp-198-beta2-hardening-i007` |
| Run | `run-t061-claude-windows-58869dfe-13` |
| Authorization | `standing-progress-grant-t061-claude-windows-20260718-slot-13` |
| Completion | `complete` |
| Verdict | `pass` |
| Runtime outcome | `completed` |
| Validation | `valid` |
| Currentness | `current` |
| Containment | `verified` |
| Termination verified | `true` |
| Findings | `0` |
| Can approve current | `true` |
| Duration | `415328 ms` |
| Result SHA-256 | `78147b86a72ae980a8178068e21d7c3a1817924cb1eaab2b184ad14d3619384a` |

Run 13 reviewed the complete frozen target with priority on the delta from run 12. It independently verified the shared campaign-scope predicate, the explicit-scope guard before finalization validation/publication, convergent `CreateNew` race handling, paired production regressions, and the five maintainer-approved finalization bindings. It found no blocking, major, minor, or note issue.

## Complete T061 Attempt and Slot Ledger

| Attempt | Run / authorization reference | Commit / digest | Provider invoked | Spend facts | Terminal outcome | Findings | Approval effect |
| ---: | --- | --- | ---: | ---: | --- | ---: | --- |
| 1 | `run-t061-claude-windows-138915e7-01` / `human-grant-t061-claude-windows-20260717-slot-1` | `138915e7f0eafec0e41363a18be9873745ce6a9e` / `2228cbb92043919dbb71ff2fb758a89d6a0dcb9e` | no | 0 | public binding returned `not-started`: omitted design context became one blank explicit ref; renderer then masked it with missing `store_root` | 0 | no authority store or spend; cannot approve |
| 2 | `run-t061-claude-windows-8150a74f-02` / `human-grant-t061-claude-windows-20260718-slot-2` | `8150a74f53f0461c3a4eb24cf959e4558cdf99be` / `pending-target` | no | 0 | immutable `preflight-failed` after 19813 ms: long Windows target prefix exceeded the path boundary | 0 | grant/reservation recorded, no invocation or spend; cannot approve |
| 3 | `run-t061-claude-windows-2db52891-03` / `human-grant-t061-claude-windows-20260718-slot-3` | `2db52891d946ed94a98d181bf0b4edcea683ba6c` / `4bd751edd91d406c44fa0c60b681aa32fdd348e9` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 299969 ms | 3 | non-approving correction input |
| 4 | `run-t061-claude-windows-fb2998d9-04` / `human-grant-t061-claude-windows-20260718-slot-4` | `fb2998d91a24607258557b380738570ff7d72a4c` / `66c219790e35b74157a04790d795bf3e69777dfa` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 314406 ms | 3 | non-approving correction input |
| 5 | `run-t061-claude-windows-067dbe10-05` / `human-grant-t061-claude-windows-20260718-slot-5` | `067dbe108d382bb41255fa9f0146beb2d3ab1ac0` / `6cb5ceab53835a7ba7ac2055cd2098ac03b80910` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 350704 ms | 4 | non-approving correction input |
| 6 | `run-t061-claude-windows-4bc832b9-06` / `human-grant-t061-claude-windows-20260718-slot-6` | `4bc832b927fc9f1047d1900147dacdbf8c46323e` / `8a08b74e28bd4ceb842670eea16fe2060289615e` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 318390 ms | 3 | non-approving correction input |
| 7 | `run-t061-claude-windows-d4664736-07` / `human-grant-t061-claude-windows-20260718-slot-7` | `d4664736fc405be3442946dec6144a800cf9081a` / `62285e6f4355aa40c58b129396b99bfd4b5679ef` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 377641 ms | 1 | non-approving correction input |
| 8 | `run-t061-claude-windows-dcb42d56-08` / `human-grant-t061-claude-windows-20260718-slot-8` | `dcb42d569ffd49b383c691911ffa51efaa24ce0c` / `7836b1219810361c26dbafc98faa3d8ceeccac39` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 320234 ms | 1 | non-approving correction input |
| 9 | `run-t061-claude-windows-41b1b048-09` / `human-grant-t061-claude-windows-20260718-slot-9` | `41b1b048f8dcd1af5d344d88099104b398d32784` / `e847197c371f767b079a2255c0bb7fac6644b587` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 360094 ms | 1 | non-approving correction input |
| 10 | `run-t061-claude-windows-fc1054b5-10` / `human-grant-t061-claude-windows-20260718-slot-10` | `fc1054b54badcfe2abded0203a1d785eeec0c59b` / `5fc6318a300afc654bb09d986d82c8c925506ed3` | yes, once | 1 | complete/current/valid pass; verified containment/termination; 320563 ms | 0 | approves its exact snapshot; later evidence commit exposed finalization circularity |
| 11 | `run-t061-claude-windows-772df845-11` / `human-grant-t061-claude-windows-20260718-slot-11-finalization-envelope` | `772df8455f150ed78c026f682d8cd0b0fbb919a0` / `52c275d194ff2e171c101ccb7bbf0abeb2f1325f` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 452765 ms | 1 | non-approving; production scope-backfill correction input |
| 12 | `run-t061-claude-windows-015d6295-12` / `human-grant-t061-claude-windows-20260718-slot-12-finalization-scope` | `015d629564af3a6b1e12fba45907012def9e11d9` / `640d6f6c4b130f72410a957adf899aaf02dcdec8` | yes, once | 1 | complete/current/valid findings result; verified containment/termination; 356937 ms | 3 | non-approving; identity/diagnostic/race correction input |
| 13 | `run-t061-claude-windows-58869dfe-13` / `standing-progress-grant-t061-claude-windows-20260718-slot-13` | `58869dfe343e1183c08e22ed1a1dd7419a75dc71` / `7c225e535f34597501ba1b3f0a80facfa7639e3e` | yes, once | 1 | complete/current/valid pass; verified containment/termination; 415328 ms | 0 | approves the exact reviewed parent and permits the bounded evidence finalization |

Ledger totals are mechanically reconciled: 13 unique attempt IDs and authorization references; 12 durable controller grant/reservation packages because attempt 1 failed before authority-store creation; 11 provider invocations; 11 immutable spend facts; 9 findings results containing 20 validated findings; 2 clean passes; 3887031 ms of provider-run duration. No attempt invoked more than once and no hidden retry occurred.

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
- Attempt 11: file:///C:/Dev/specrew-t061-772df845/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-772df845-11/result.json
- Attempt 12: file:///C:/Dev/specrew-t061-015d6295/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-015d6295-12/result.json
- Attempt 13: file:///C:/Dev/specrew-t061-authority-58869dfe/campaigns/cmp-198-beta2-hardening-i007/runs/run-t061-claude-windows-58869dfe-13/result.json

Attempt 1 ended before authority-store creation, so it has no fabricated result path. Its exact no-spend failure and correction are recorded under DRIFT-198-I007-014 in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/007/drift-log.md.

## Task Verdicts

T030–T034b and T051–T060 pass with the qualifications already recorded in the supporting evidence: DRIFT-198-I007-025 is explicitly deferred to the later stop/capture-mechanism slice; Cursor is live-proven but not claimed clean-current after free-credit exhaustion; and FR-048/FR-049/SC-015 remains an explicit open Beta2 command-plan dependency outside Iteration 007.

T061 passes. Runs 11 and 12 supplied immutable correction evidence for the finalization envelope; run 13 independently confirms the corrected final tree with no findings. The six-file finalization commit and one-time authority fact close the evidence/digest circularity without treating documentation mutation as reviewed implementation.

## Correction Verification

- Final local release registry: all 57 registered suites passed in 707.8 seconds.
- Final hosted CI: run `29650851763` completed successfully at exact reviewed commit `58869dfe343e1183c08e22ed1a1dd7419a75dc71`, including deterministic review-runtime jobs on Windows, Ubuntu, and macOS.
- Focused finalization authority/public-path verification: 78/78 passed.
- Bidirectional traceability: 16/16 tasks and 25/25 scoped requirements; no orphan task, invalid reference, or uncovered scoped requirement.
- Scoped and gap governance: PASS with historical warnings only.
- Final no-spend preflight: exact commit/digest, clean current target, five resolved design references, Claude readiness, Job Object readiness, invocation contract, and process contract all passed before attempt 13.

## Drift and Carry-Forward

DRIFT-198-I007-026 is resolved by the maintainer-approved bounded finalization envelope and the controller's one-time fact. DRIFT-198-I007-027 was corrected and independently confirmed by run 12. DRIFT-198-I007-028 was corrected at `58869dfe` and independently confirmed by clean run 13. Their source ledger remains part of the reviewed parent; this finalization commit deliberately changes only the six allowed review artifacts.

DRIFT-198-I007-025 remains explicitly deferred to a later stop/capture-mechanism repair. Cursor clean-current proof remains unavailable after free-credit exhaustion; support truth does not promote an older digest. FR-048/FR-049/SC-015 remains a separate open Beta2 command-plan dependency and blocks feature closeout until its own replanned slice. None of these truthful carry-forwards invalidates this bounded Iteration 007 review verdict.

## Acceptance Condition Status

Every T061 attempt and paid invocation is visible, every correction was committed and re-verified before the next slot, attempts 1 and 2 consumed no provider spend, and attempts 3–13 each consumed exactly one spend fact. Run 13 provides clean independent approval of the exact reviewed parent. The controller-owned finalization envelope carries only these six review artifacts and the authority store supplies the immutable reviewed/finalized binding. Retrospective remains the next separate verdict boundary.
