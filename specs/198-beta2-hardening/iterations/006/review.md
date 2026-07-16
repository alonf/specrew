# Iteration 006 Review Evidence

**Task**: T050
**Status**: incomplete — complete current-tree rerun requires a new human allowance
**Reviewer**: Claude Code 2.1.210
**Recorded**: 2026-07-16

## Authority Outcome

The only provider invocation in campaign `cmp-i006-t050-claude-v2` reviewed exact digest
`2540aad2e6c0b3205eecece4a457a2cf38545078`. The controller verified containment, termination, and
currentness, but rejected the candidate because it contained prose before the JSON object.

| Field | Authoritative value |
| --- | --- |
| Run | `run-i006-t050-claude-v2` |
| Completion | `none` |
| Verdict | `incomplete` |
| Runtime outcome | `invalid-output` |
| Validation | `invalid` |
| Currentness | `current` |
| Containment | `verified` |
| Termination verified | `true` |
| Can approve current | `false` |
| Failure reason | `prose-wrapped-json: prose-wrapped-json` |
| Observed duration | 639.140 seconds |

The immutable result and its Markdown projection are at
file:///C:/Dev/specrew-beta2-hardening/.specrew/review/campaign-t050-i006/authority-store-v2/campaigns/cmp-i006-t050-claude-v2/runs/run-i006-t050-claude-v2/.
The rejected raw candidate is at
file:///C:/Dev/specrew-beta2-hardening/.specrew/review/campaign-t050-i006/staging-v2/campaigns/cmp-i006-t050-claude-v2/runs/run-i006-t050-claude-v2/staging/candidate.json.

## Attempt Ledger

| Attempt | Provider invoked | Allowance effect | Outcome |
| --- | --- | --- | --- |
| Legacy rehearsal `i006-t050-claude-01` | no | none | historical legacy round ceiling; `reviewed=false` |
| New-contract preflight `run-i006-t050-ceiling-v2` | no | reservation released | visible bounded preflight failure; no spend |
| `run-i006-t050-claude-v2` | yes | one provider slot spent | authoritative invalid-output; cannot approve |

## Advisory Findings and Disposition

No finding in the invalid candidate is authoritative. The comments remain useful advisory evidence,
consistent with the approved policy that partial, stale, or invalid review output may inform a fix but
cannot approve the current tree.

| Candidate comment | Advisory disposition |
| --- | --- |
| Duplicate-combination policy reads a field absent from stored ReviewRun facts | fixed: compare the closed ReviewRun `schema_version`; realistic fixture added |
| Runtime preflight failure is reported as a harness failure | fixed: distinct required `runtime` preflight key and `preflight-failed:runtime` proof |
| Reservation IDs can collide across runs | fixed: `reservation-id-already-used` rejection and regression |
| Dead `$claimHeld` variable | fixed: removed |
| Premature campaign-mode flip has no public command-reachable replacement | documented as an explicit operational warning in the foundation map; Iteration 007 owns public wiring |

## Correction Verification

- Focused authority/store/orchestrator suites: 48 passed, 0 failed, 0 skipped.
- Iteration 006 foundation: 87 passed, 0 failed, 0 skipped.
- Complete F-198 registry: all 45 explicitly registered suites green.
- Whitespace integrity: `git diff --check` passed.

## Remaining Acceptance Condition

T050 remains open. The spent invalid run cannot be reinterpreted as a complete review, and its target
digest is superseded by the advisory correction. A new run must use a new run ID, target the exact
post-correction committed digest, and publish a complete, schema-valid terminal result. Starting that
provider invocation requires a separate explicit human allowance; the controller must not retry it
automatically.
