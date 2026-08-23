# Review Result

- **Campaign**: `cmp-199-beta3-stabilization-i001`
- **Run**: `run-20260811-140522865-0122b46b`
- **Harness**: `codex-cli-file-primary`
- **Target digest**: `2ff07df66a81c7c8c6d0b161467e82bf962ae9c4`
- **Completion**: `complete`
- **Verdict**: `findings`
- **Runtime outcome**: `completed`
- **Currentness**: `snapshot-moved`
- **Can approve current snapshot**: `false`

## Summary

Controller verification passed, but the new pause protocol has approval-blocking failure paths: a failed stop-here action cannot be retried, a pre-invocation failure consumes the continuation decision even though no round was spent, and a failed pause write permits another review. The resumed decision surface also omits the choices and finding details needed to answer it. The reparse contract remains inconsistent with the amended requirement and implementation.

Failure reason: snapshot-moved

## Findings

| ID | Severity | Relevance | Location | Finding |
| --- | --- | --- | --- | --- |
| `finding-835a171e734b60ae` | blocking | snapshot-moved | scripts/specrew-review.ps1:930 | A failed stop-here landing consumes the only answer and cannot be retried: The CLI writes the immutable pause-decision fact before Invoke-ReviewCampaignStopHereLanding runs. If verification, residual acceptance, or gate sync fails, the landing message tells the user to choose stop here again. That retry cannot work: Get-ReviewCampaignPendingPause excludes answered pauses, so the CLI reports that no round is waiting, while the latest decision also prevents another review. Failure scenario: the final verification command fails transiently -> option 2 is permanently recorded -> after the user fixes the named problem, option 2 cannot be submitted again and the campaign is wedged. |
| `finding-bc846e0026e6862d` | blocking | snapshot-moved | scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1:1323 | A pre-invocation failure permanently consumes the continuation decision: RoundsSinceDecision counts every terminal result whose started_at follows the pause decision, including preflight-failed, claim-contended, and launch-failed records produced without invoking a reviewer. After such a failure, the grant reservation is released and the CLI explicitly says the authorization remains available, but the next attempt is rejected as single-run-grant-already-spent before that restored slot can be reused. Failure scenario: choose fix-and-continue -> preflight fails before invocation -> fix the preflight issue and retry -> the campaign refuses forever even though FR-014 says no round or allowance was consumed. |
| `finding-0e282c4994081e57` | blocking | snapshot-moved | scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1:725 | Failure to persist a round pause fails open to another reviewer spend: Add-ReviewCampaignRoundPause catches every pending-pause write error and only returns recorded=false; Invoke-ReviewCampaignRun also catches any exception from the pause terminal and still returns a normal terminal result. Because the continuation guard reads pause facts from the store, the next command sees no latest pause and may reserve and invoke another reviewer without a numbered answer. Failure scenario: disk, permission, or conflicting-fact error prevents pending-pause.json from being written -> the completed round appears terminal -> another invocation proceeds and spends, recreating the unbounded loop the feature is meant to stop. |
| `finding-6bd8da7827b4f519` | major | snapshot-moved | scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1:1087 | The resumed pause surface omits findings, locations, and numbered choices: The persisted pause fact stores only counts and a recommendation, and Format-ReviewCampaignOutstandingPause consequently renders neither the finding titles/locations nor options 1-3 nor even a prompt naming how to answer. This is the surface shown when a later invocation is refused by an outstanding pause. Failure scenario: a user returns in a new session -> the CLI says nothing will run until they answer -> the only displayed surface contains no choices or actionable finding locations, so the promised single decision surface cannot be used without reconstructing context elsewhere. |
| `finding-dba3cc5b8bdd80e3` | minor | snapshot-moved | specs/199-beta3-stabilization/contracts/beta3-stabilization.md:77 | The public reparse contract contradicts the amended requirement and implementation: The contract still says unknown reparse tags are refused, while the amended spec and Resolve-SpecrewReparseDisposition admit non-linking reparse points and trust the bytes read via hashing. This gives maintainers and integrators two incompatible definitions of the shipped policy and risks reintroducing the OneDrive failure during future contract-driven work. |

_This Markdown is a controller-generated projection. Authority is the sibling immutable `result.json`._