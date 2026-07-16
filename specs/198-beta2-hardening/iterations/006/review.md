# Iteration 006 Review Evidence

**Task**: T050
**Status**: incomplete — the v4 timing-contract finding is corrected and exactly one v5 rerun is authorized after the correction commit
**Reviewer**: Claude Code 2.1.210
**Recorded**: 2026-07-16

## Current Authoritative Outcome

Run `run-i006-t050-claude-v4` reviewed exact digest
`5ffcca9fb50d47abd922e5352baaeca16e0d83f5`. The controller verified containment, termination, and
currentness, accepted the strict JSON candidate, and published one note finding. A valid findings
verdict cannot approve the tree.

| Field | Authoritative value |
| --- | --- |
| Campaign | `cmp-i006-t050-claude-v2` |
| Run | `run-i006-t050-claude-v4` |
| Completion | `complete` |
| Verdict | `findings` |
| Runtime outcome | `completed` |
| Validation | `valid` |
| Currentness | `current` |
| Containment | `verified` |
| Termination verified | `true` |
| Can approve current | `false` |
| Observed duration | 638.140 seconds |

The immutable result and its Markdown projection are at
file:///C:/Dev/specrew-beta2-hardening/.specrew/review/campaign-t050-i006/authority-store-v2/campaigns/cmp-i006-t050-claude-v2/runs/run-i006-t050-claude-v4/.

## Attempt Ledger

| Attempt | Provider invoked | Allowance effect | Outcome |
| --- | --- | --- | --- |
| Legacy rehearsal `i006-t050-claude-01` | no | none | historical legacy round ceiling; `reviewed=false` |
| New-contract preflight `run-i006-t050-ceiling-v2` | no | reservation released | visible bounded preflight failure; no spend |
| `run-i006-t050-claude-v2` | yes | one provider slot spent | authoritative invalid-output; cannot approve |
| `run-i006-t050-claude-v3` | yes | one separately granted provider slot spent | complete, valid, current findings result; cannot approve |
| `run-i006-t050-claude-v4` | yes | one separately granted provider slot spent | complete, valid, current note finding; cannot approve |

The invalid v2 attempt remains immutable historical evidence at
file:///C:/Dev/specrew-beta2-hardening/.specrew/review/campaign-t050-i006/authority-store-v2/campaigns/cmp-i006-t050-claude-v2/runs/run-i006-t050-claude-v2/.
Its prose-wrapped candidate supplied five advisory comments; all were corrected before the v3 run,
and v3 independently confirmed those corrections as sound and complete.

## Validated Findings and Disposition

| Finding | Severity | Disposition |
| --- | --- | --- |
| Idempotent replay could falsely report conflicting immutable facts when PowerShell coerced high-precision ISO timestamps during reread | minor | fixed: validate the existing winner, then compare its persisted canonical UTF-8 text directly; a `DateTimeOffset.ToString('o')` replay regression passes |
| Active claim contention was published as `preflight-failed` after every preflight passed | minor | fixed: closed contracts, classification, ingress, and orchestration now use `claim-contended`; a no-spend/released-reservation regression passes |
| A possibly live reviewer snapshot was disposed on `awaiting-termination-verification` | note | fixed: disposal is deferred to recovery until termination is verified; the regression proves no disposal on the unverified path |
| T042/T046 owner globs named placeholder files rather than delivered components | note | fixed: the iteration plan and root task artifact now identify the actual pure-core and target-port files; recorded as `DRIFT-198-I006-002` |
| The v1 terminal `duration_ms` ceiling equaled the maximum invocation timeout and could not publish truthful max-timeout evidence with termination/controller overhead | note | fixed: invocation timeout is capped at 7,200 seconds; the terminal maximum is derived from timeout + 10-second maximum grace + 120-second bounded overhead; project config is rejected above 7,200; measured duration is never clamped |

The drift record is at
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/006/drift-log.md.

## Correction Verification

- Focused authority/ingress/orchestrator suites: 50 passed, 0 failed, 0 skipped; the config-boundary regression also passes.
- Iteration 006 foundation: 91 passed, 0 failed, 0 skipped.
- Bidirectional traceability: PASS; 10/10 tasks and 14/14 scoped requirements, with no orphans, gaps, or invalid references.
- Complete F-198 registry: all 45 explicitly registered suites green in 421.1 seconds.
- The legacy lineage-lease race fixture initially exposed a timing-dependent false failure: its first
  winner exited before slower racers inspected the lease, legitimately enabling dead-owner recovery.
  The synchronized fixture keeps the winner alive through every first decision and passes five
  consecutive runs, 75/75 tests, before the green full registry.

## Remaining Acceptance Condition

T050 remains open. The v4 review is complete, valid, and current for its target digest, but its
findings verdict cannot approve, and the correction necessarily creates a new digest. The maintainer
authorized exactly one Claude v5 invocation after the correction is committed. It must use a new run
ID, target that exact committed digest, and publish a complete schema-valid result. There is no hidden
retry: findings stop the workflow without another fix, while a clean result closes T050.

## Carry-Forward Obligations

- `DRIFT-198-I006-001` remains open. Iteration closeout must not rely on the stale global ledger, and
  the matcher correction belongs to a scoped amendment or the engine backlog, not a quiet point-fix.
- Iteration 007's adapter suite must include a deterministic prose-wrapped-JSON malformed-output
  fixture and production prompt-contract hardening for the failure that spent the v2 provider slot.
