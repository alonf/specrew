# Iteration 006 Review Evidence

**Task**: T050
**Status**: complete — v6 is a valid current pass with zero findings and can approve the reviewed snapshot
**Overall Verdict**: accepted
**Reviewer**: Claude Code 2.1.210
**Recorded**: 2026-07-16

## Review Mechanism

The maintainer explicitly made the new campaign/run contract the independent T050 review mechanism
and required a clean v6 to close T050 and open this review-signoff gate. v6 is that one authorized
live provider invocation. A second legacy inline provider run would exceed the grant and duplicate
the reviewed work, so none was started.

## Current Authoritative Outcome

Run `run-i006-t050-claude-v6` reviewed committed HEAD
`2157017f77a225f9497c44ffb013e101bff6f2a7` at exact digest
`bedc0172de77fda277f764cd07b90d5af291e2cc`. The controller verified containment, termination, and
currentness, accepted the strict file-primary candidate, and published a complete valid pass with
zero findings. This result can approve the reviewed snapshot.

| Field | Authoritative value |
| --- | --- |
| Campaign | `cmp-i006-t050-claude-v2` |
| Run | `run-i006-t050-claude-v6` |
| Completion | `complete` |
| Verdict | `pass` |
| Runtime outcome | `completed` |
| Validation | `valid` |
| Currentness | `current` |
| Containment | `verified` |
| Termination verified | `true` |
| Can approve current | `true` |
| Observed duration | 507.609 seconds |

The immutable result and its Markdown projection are at
file:///C:/Dev/specrew-beta2-hardening/.specrew/review/campaign-t050-i006/authority-store-v2/campaigns/cmp-i006-t050-claude-v2/runs/run-i006-t050-claude-v6/.

## Attempt Ledger

| Attempt | Provider invoked | Allowance effect | Outcome |
| --- | --- | --- | --- |
| Legacy rehearsal `i006-t050-claude-01` | no | none | historical legacy round ceiling; `reviewed=false` |
| New-contract preflight `run-i006-t050-ceiling-v2` | no | reservation released | visible bounded preflight failure; no spend |
| `run-i006-t050-claude-v2` | yes | one provider slot spent | authoritative invalid-output; cannot approve |
| `run-i006-t050-claude-v3` | yes | one separately granted provider slot spent | complete, valid, current findings result; cannot approve |
| `run-i006-t050-claude-v4` | yes | one separately granted provider slot spent | complete, valid, current note finding; cannot approve |
| `run-i006-t050-claude-v5` | yes | one separately granted provider slot spent | authoritative invalid-output; embedded pass remains non-authoritative |
| `run-i006-t050-claude-v6` | yes | one separately granted provider slot spent | complete, valid, current pass; zero findings; can approve |

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

## Acceptance Condition Satisfied

T050 is complete. The scoped hardening passed the full suites and was committed before the provider
slot was spent. v6 used a new run ID, matched the stable post-commit digest, delivered through the
candidate file, and published a complete schema-valid current pass. No hidden retry occurred.

## Carry-Forward Obligations

- `DRIFT-198-I006-001` remains open. Iteration closeout must not rely on the stale global ledger, and
  the matcher correction belongs to a scoped amendment or the engine backlog, not a quiet point-fix.
- The Claude file-primary prompt contract and exact prose-file/raw-file regression pair were pulled
  forward under `DRIFT-198-I006-003`; Iteration 007 must not plan them twice. Its full malformed-output
  fixture matrix and all remaining adapter hardening stay Iteration 007 work.
