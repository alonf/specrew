# Review Result

- **Campaign**: `cmp-199-beta3-stabilization-i001`
- **Run**: `run-20260811-213318650-9ab64f34`
- **Harness**: `codex-cli-file-primary`
- **Target digest**: `8011465c67ad6f14136f78227559edf733af35a2`
- **Completion**: `complete`
- **Verdict**: `findings`
- **Runtime outcome**: `completed`
- **Currentness**: `current`
- **Can approve current snapshot**: `false`

## Summary

Complete risk-based review of the frozen feature delta. All three controller verification commands succeeded against the target digest, but the shipped decision CLI is unwired, the records-only exemption can authorize failed reviews, and the new allowance-reset recovery remains wedged. Two additional authority/consumer-surface defects were also established.

## Findings

| ID | Severity | Relevance | Location | Finding |
| --- | --- | --- | --- | --- |
| `finding-2d37bee0665d4c90` | blocking | current | scripts/specrew.ps1:364 | The shipped CLI rejects every new round-decision flag: The top-level `specrew review` whitelist omits `--approve-round` from its switch options and omits `--pause-choice` and `--pause-rationale` from its value options. This validation runs before `scripts/specrew-review.ps1` is launched. Failure scenario: a user follows either advertised command (`specrew review --live --approve-round` or `specrew review --pause-choice 2`), but the front door exits with `Unsupported argument`, so they can neither authorize the next round nor answer the decision surface through the shipped command. |
| `finding-56e86d2b26997fb2` | blocking | current | scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1:769 | A records-only delta turns any moved terminal result into signoff authority: The records-only branch returns `GateAllows $true` immediately after locating the latest result, before the later checks for `runtime_outcome`, `completion`, `validation`, `currentness`, verdict, or human disposition. Failure scenario: a reviewer times out or publishes a partial/invalid findings result, then a drift-log or other allowlisted record is committed; the result digest differs only by that record, this branch returns `records-only-delta-does-not-stale`, and the signoff gate maps it to `allow`. The exemption must preserve an already-authorizing result, not promote a non-authorizing one. |
| `finding-e01f7daadab9b161` | blocking | current | scripts/specrew-review.ps1:868 | Allowance reset does not make the exhausted round continuable: The reset branch records only a budget-reset fact and tells the user to run `specrew review --live --approve-round`; it neither answers nor supersedes the exhausted round's pending pause. Failure scenario: after round 4, the user performs the prescribed reset and then runs the prescribed next-review command; `Get-ReviewCampaignLatestPause` still returns the unanswered round-4 pause and the continuation guard refuses with `pause-decision-pending`. The resumed surface also continues to omit option 1 because its immutable pause fact still says 4 of 4 rounds were used. The advertised recovery remains wedged unless the user guesses an unoffered extra `--pause-choice 1` step. |
| `finding-8e4beb6a476bb5e6` | major | current | scripts/internal/continuous-co-review/review-authority-store.ps1:348 | Budget-reset authority is consumed without contract validation: `Get-ReviewCampaignLatestBudgetReset` parses every JSON file in `budget-resets` and selects one solely by its `observed_at` string. It does not use `Read-ReviewAuthorityFactFile`, validate `RoundBudgetResetFact`, verify the campaign/reset identity, or fail closed on an invalid file. Failure scenario: a stray or tampered JSON file containing only a future `observed_at` is selected as the latest reset; all prior rounds are excluded from the budget even though no human authority, reason, or valid reset fact exists. |
| `finding-31a00098fba1fdce` | major | current | scripts/internal/specrew-bootstrap-provider.ps1:123 | The orientation banner still emits bare requirement IDs: The new gloss helper has no production call sites, while the orientation provider explicitly emits lines such as `render this as VISIBLE PROSE ... FR-004/FR-020` and several other bare requirement IDs. The consumer-language tests inspect gate messages and stop blocks but never this named surface. Failure scenario: a first-time user receives the orientation banner and must look up unexplained IDs before its instructions make sense, violating the zero-unglossed-ID acceptance criterion. |

_This Markdown is a controller-generated projection. Authority is the sibling immutable `result.json`._