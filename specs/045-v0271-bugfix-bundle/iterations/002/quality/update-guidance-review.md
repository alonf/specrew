# Update Guidance Review: Iteration 002

**Schema**: v1
**Feature**: `045-v0271-bugfix-bundle`
**Requirement**: FR-007
**Success Criterion**: SC-005
**Status**: passed

## Timing Rubric

The guided review passes only when a maintainer can answer all required decisions in under 3 minutes total using the updated docs.

| Decision | Source Expected | Pass Condition |
| --- | --- | --- |
| Standard update path | `docs/getting-started.md` | Reviewer can name the default update command and when to use it. |
| Force / publisher-check bypass boundary | `docs/getting-started.md` | Reviewer can state that `-Force` is for intentional redeploy/overwrite cases and that publisher-check bypass is exceptional and risk-bearing, not routine. |
| Re-deploy/init trigger | `docs/user-guide.md` and `quickstart.md` | Reviewer can identify when a missing skill-catalog/runtime gap requires rerunning `specrew init` and when no redeploy is needed. |

## Procedure

1. Start a stopwatch.
2. Open `docs/getting-started.md`, `docs/user-guide.md`, and `specs/045-v0271-bugfix-bundle/quickstart.md`.
3. Answer the three rubric decisions above without using source code or release notes.
4. Stop the timer when all answers are recorded.
5. Pass only if elapsed time is less than 3 minutes and all answers cite the relevant decision trigger.

## Evidence Capture

| Field | Value |
| --- | --- |
| Reviewer | Codex |
| Started At | 2026-05-25T17:16:00Z |
| Completed At | 2026-05-25T17:18:05Z |
| Elapsed | 2m05s |
| Result | passed |
| Notes | All three operator decisions were answered from documentation and quickstart material only, under the 3-minute SC-005 limit. |

## Review Answers

| Decision | Answer | Source Line / Section | Verdict |
| --- | --- | --- | --- |
| Standard update path | Run `Update-Module Specrew`, reload with `Import-Module Specrew -Force`, then verify with `specrew --version`. Use this as the default path for normal module updates. | `docs/getting-started.md` "Updating Specrew later"; `docs/user-guide.md` "Updating and Redeploying Specrew" | passed |
| Force / publisher-check bypass boundary | Package-manager `-Force` is for intentional reinstall or overwrite of the module package; `-SkipPublisherCheck` is exceptional and should only be used for a trusted Specrew package source after understanding it bypasses publisher validation. Neither switch approves lifecycle gates or brownfield conflicts. | `docs/getting-started.md` "Updating Specrew later"; `docs/user-guide.md` "Updating and Redeploying Specrew" | passed |
| Re-deploy/init trigger | Rerun `specrew init` after updates when release notes or runtime checks indicate extension, template, governance, or skill-catalog gaps; `specrew start` can repair missing skill catalogs on normal launch, while `specrew init -Force` is reserved for intentional full redeploy and still preserves conflict checks. | `docs/user-guide.md` "Updating and Redeploying Specrew"; `specs/045-v0271-bugfix-bundle/quickstart.md` "Verify update and redeploy decisions from docs" | passed |
