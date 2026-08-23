# Review Result

- **Campaign**: `cmp-199-beta3-stabilization-i001`
- **Run**: `run-20260811-175326143-cf6bc6a8`
- **Harness**: `codex-cli-file-primary`
- **Target digest**: `8b418a2898d64756534ec0186ff92e2a3714e5ec`
- **Completion**: `complete`
- **Verdict**: `findings`
- **Runtime outcome**: `completed`
- **Currentness**: `snapshot-moved`
- **Can approve current snapshot**: `false`

## Summary

Risk-based review covered controller verification evidence and the main review-authority, pause/decision, signoff, verdict-capture, filesystem-policy, verification-plan, and public CLI paths. All three configured verification commands succeeded, but production-path inspection found approval-blocking defects in stop-here, budget reset, and signoff decision projection, plus pause-reply and result-ingestion failures.

Failure reason: snapshot-moved

## Findings

| ID | Severity | Relevance | Location | Finding |
| --- | --- | --- | --- | --- |
| `finding-2ea30dc5d2b9e587` | blocking | snapshot-moved | scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1:781 | The production stop-here verifier cannot create its snapshot: The default VerifyPort calls New-GitReviewTargetSnapshot with -RepoRoot and supplies no run id, but that function requires -OriginRepo and mandatory -RunId. The public option-2 path does not inject a fixture port, so PowerShell throws before verification and the composition reports a failed landing. Failure scenario: a user selects stop-here after a review round; the final verification never starts and sign-off cannot complete. After correcting the arguments, this port also needs a finally block that disposes the linked worktree it creates. |
| `finding-fc642f2e23098498` | blocking | snapshot-moved | scripts/specrew-review.ps1:838 | The advertised campaign allowance reset is rejected: The exhausted-budget surface directs users to `specrew review --remediate allowance-reset`, but campaign authority rejects every remediation except override-block here. The campaign round count is derived from immutable prior results and no campaign reset fact is consulted elsewhere, so the legacy reset cannot replenish it indirectly. Failure scenario: after the fourth invoked round, option 1 disappears; following the exact reset command throws, leaving the campaign unable to run another authorized round without editing configuration or abandoning it. |
| `finding-8f2b0eba2d935f1d` | blocking | snapshot-moved | scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1:744 | A recorded signoff allow is projected back into a block: The matching recorded-allow branch returns a `review-current` packet without setting RenderBoundaryPacket, whose default is false. Get-ContinuousCoReviewSignoffGateDecision later maps that flag directly to `block`. The records-only-current shortcut has the same projection. Failure scenario: the stored gate says allow for the exact current tree (or an accepted findings result moves only by process records); the next gate evaluation says the review is signed off/current in its message but returns a blocking decision, contradicting the authority record and wedging sign-off. |
| `finding-073a5c5993c500e2` | major | snapshot-moved | scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1:1182 | The rendered pause reply command does not enter the reply handler: Both live and resumed pause surfaces print `specrew review --pause-choice <1\|2\|3>`, but pause choices are processed only inside `if ($Live)`, and PauseChoice is not included in the condition that loads the review engine. Even if the user adds `--live`, the command checks for a reviewer-round authorization before it processes the pause answer, so a fresh campaign can be asked to approve another round merely to stop or abandon. Failure scenario: a user follows the displayed command after a pause; no pause-decision fact is written, or the command exits asking for a round approval, and the campaign remains paused. |
| `finding-e99845b349a1c97a` | major | snapshot-moved | scripts/internal/continuous-co-review/review-result-ingestor.ps1:190 | Demotion can make a valid finding exceed the result contract: Candidate and terminal findings share the same maximum description length, but demotion prepends an explanatory note without reserving space or bounding the resulting string. Failure scenario: a valid blocking or major candidate uses the allowed maximum-length description but omits a Failure scenario clause; demotion pushes the terminal description over the limit, Publish-ReviewRunResultFact rejects it, and the already-paid run fails to publish instead of preserving the finding as a follow-up. In the campaign path this exception also bypasses normal claim completion. |
| `finding-3dc7c7952888d84f` | major | snapshot-moved | scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1:1167 | A resumed exhausted pause loses the required reset instruction: The live decision carries budget_refusal with the exact reset command, but PendingPauseFact does not persist that field and Format-ReviewCampaignOutstandingPause only removes option 1 when the recorded budget is exhausted. Failure scenario: a user returns in a later session after consuming the last round; the surface offers only stop or abandon without explaining why continuation vanished or how to request more rounds, contrary to the exhausted-budget next-step contract. |

_This Markdown is a controller-generated projection. Authority is the sibling immutable `result.json`._