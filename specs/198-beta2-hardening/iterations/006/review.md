# Iteration 006 Review Evidence

**Task**: T050
**Status**: incomplete — v5 failed strict ingress; the scoped file-primary hardening is underway and exactly one v6 rerun is authorized after a green committed correction
**Reviewer**: Claude Code 2.1.210
**Recorded**: 2026-07-16

## Current Authoritative Outcome

Run `run-i006-t050-claude-v5` reviewed exact digest
`8a8702862cd0caed22103b9617057a66d04dd548`. The controller verified containment, termination, and
currentness, but strict ingress rejected Claude's prose-prefixed candidate. The controller published
zero authoritative findings and did not accept the embedded pass object. Invalid output cannot
approve the tree.

| Field | Authoritative value |
| --- | --- |
| Campaign | `cmp-i006-t050-claude-v2` |
| Run | `run-i006-t050-claude-v5` |
| Completion | `none` |
| Verdict | `incomplete` |
| Runtime outcome | `invalid-output` |
| Validation | `invalid` |
| Currentness | `current` |
| Containment | `verified` |
| Termination verified | `true` |
| Can approve current | `false` |
| Observed duration | 475.187 seconds |

The immutable result and its Markdown projection are at
file:///C:/Dev/specrew-beta2-hardening/.specrew/review/campaign-t050-i006/authority-store-v2/campaigns/cmp-i006-t050-claude-v2/runs/run-i006-t050-claude-v5/.

## Attempt Ledger

| Attempt | Provider invoked | Allowance effect | Outcome |
| --- | --- | --- | --- |
| Legacy rehearsal `i006-t050-claude-01` | no | none | historical legacy round ceiling; `reviewed=false` |
| New-contract preflight `run-i006-t050-ceiling-v2` | no | reservation released | visible bounded preflight failure; no spend |
| `run-i006-t050-claude-v2` | yes | one provider slot spent | authoritative invalid-output; cannot approve |
| `run-i006-t050-claude-v3` | yes | one separately granted provider slot spent | complete, valid, current findings result; cannot approve |
| `run-i006-t050-claude-v4` | yes | one separately granted provider slot spent | complete, valid, current note finding; cannot approve |
| `run-i006-t050-claude-v5` | yes | one separately granted provider slot spent | authoritative invalid-output; embedded pass remains non-authoritative |

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

- Focused authority/ingress/orchestrator suites: 52 passed, 0 failed, 0 skipped; the config-boundary regression also passes.
- Iteration 006 foundation: 93 passed, 0 failed, 0 skipped in 25.054 seconds.
- Bidirectional traceability: PASS; 10/10 tasks and 14/14 scoped requirements, with no orphans, gaps, or invalid references.
- Complete F-198 registry: all 45 explicitly registered suites green in 393.5 seconds.
- Packaged artifact: 2 passed, 0 failed, 0 skipped; module manifest, changed PowerShell syntax, JSON, loader/FileList entries, and `git diff --check` pass. PSScriptAnalyzer is not installed, so no analyzer result is inferred.
- The legacy lineage-lease race fixture initially exposed a timing-dependent false failure: its first
  winner exited before slower racers inspected the lease, legitimately enabling dead-owner recovery.
  The synchronized fixture keeps the winner alive through every first decision and passes five
  consecutive runs, 75/75 tests, before the green full registry.

The maintainer then authorized a scoped pull-forward from Iteration 007 after v5 repeated the v2
delivery failure. The Claude harness now supplies the exact candidate path in the prompt and treats
that file as the only candidate channel; the file must contain only one raw JSON object, and stdout is
never parsed for authority. Strict ingress remains unchanged and performs no salvage. The paired
regression rejects a prose-wrapped candidate file even when stdout contains valid JSON, and accepts a
raw candidate file while ignoring prose-wrapped stdout. This exact adapter slice and pair must be
subtracted from Iteration 007; its full malformed-output matrix and remaining adapter hardening remain
deferred.

## Remaining Acceptance Condition

T050 remains open. The v5 result is immutable, current for its target digest, and correctly
non-authoritative because its candidate was malformed. The maintainer authorized exactly one Claude
v6 invocation after the scoped hardening passes the full suites and is committed. It must use a new
run ID, target that exact committed digest, and publish a complete schema-valid result through the
candidate file. There is no hidden retry: findings or invalid output stop the workflow without a fix
or further spend, while a clean result closes T050.

## Carry-Forward Obligations

- `DRIFT-198-I006-001` remains open. Iteration closeout must not rely on the stale global ledger, and
  the matcher correction belongs to a scoped amendment or the engine backlog, not a quiet point-fix.
- The Claude file-primary prompt contract and exact prose-file/raw-file regression pair were pulled
  forward under `DRIFT-198-I006-003`; Iteration 007 must not plan them twice. Its full malformed-output
  fixture matrix and all remaining adapter hardening stay Iteration 007 work.
