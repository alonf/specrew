# Feature Closeout: Specrew Update Downgrade Guard and Compatibility Message Cleanup

**Schema**: v1  
**Feature**: 159-update-ux-small-fixes  
**Branch**: 159-update-ux-small-fixes  
**Closed**: 2026-06-06  
**Status**: COMPLETE - branch-ready evidence only  
**Closer**: Codex, authorized by Alon Fliess for feature-closeout

## Executive Summary

Feature 159 is complete as a branch-ready small-fix slice. Proposal 159 Tier 1 was implemented only: mutating `specrew update` operations now refuse to run when the executing Specrew source/module version is older than the project's recorded `.specrew/config.yml` `specrew_version`. Active generated/routine `0.24.0` compatibility-baseline wording was removed from normal user-facing governance/version/update guidance while historical references remain intact.

No Tier 2 self-update flow, Proposal 160 resolver work, Feature 141 design-lens intake work, release promotion, stable tag, pull request, merge, or main-branch push is included in this closeout.

## Delivered Scope

| Capability | Status | Evidence |
| --- | --- | --- |
| Stale-module downgrade refusal for mutating `specrew update` scopes | complete | `scripts/specrew-update.ps1`, `tests/integration/update-command.ps1` |
| Actionable refusal text naming `Update-Module Specrew` and `SPECREW_MODULE_PATH` | complete | `scripts/specrew-update.ps1`, `tests/integration/update-command.ps1` |
| Equal/newer running module behavior preserved | complete | `tests/integration/update-command.ps1` |
| Deterministic protected-surface no-mutation proof | complete | `tests/integration/update-command.ps1`, `iterations/001/coverage-evidence.md` |
| Active `0.24.0` compatibility-baseline cleanup | complete | `scripts/specrew-version.ps1`, `scripts/internal/version-check.ps1`, active skills/governance templates, compatibility tests |
| Proposal 145 review discipline | accepted | `iterations/001/review.md`, `review-report.yml`, `review-claim-ledger.yml`, `design-code-trace.yml` |

## Tests and Validation

The accepted review-signoff packet records these passing checks:

- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\update-command.ps1`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\slash-command-compatibility.tests.ps1`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\slash-command-routing.tests.ps1`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\version-checks.tests.ps1`
- PowerShell parser tokenization over changed `.ps1` files
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\slash-command-distribution.tests.ps1`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\slash-command-multi-path.tests.ps1`
- Governance validation for Feature 159 passes.

## Accepted Review and Retro Evidence

- Review-signoff accepted stale-module refusal, deterministic no-mutation proof, equal/newer no-regression, active `0.24.0` cleanup, branch hygiene, test integrity, and scope/collision evidence.
- The generated active governance touch was accepted as required parity cleanup and limited to stale `0.24.0` wording.
- The adjacent slash-command distribution assertion repair was accepted as test-integrity cleanup discovered during review.
- Retro accepted the small-fix baseline calibration and recorded the scaffold-hardening follow-up for preserving populated quality evidence.

## Known Non-Blocking Warnings

| Warning | Disposition |
| --- | --- |
| Feature 141 has adjacent active-governance wording overlap. | Non-blocking for Feature 159 feature-closeout; must be reconciled before either branch lands on main. |
| Proposal 160 sidecar/resolver work is separate. | No changed-file collision recorded for Feature 159 closeout. |
| Existing stashes remain present. | Preserved unapplied and outside Feature 159. Validator-summary-only stashes are isolated runtime churn. |
| Repository-level governance warnings outside Feature 159 remain. | Non-blocking for this branch-ready closeout; validator passes Feature 159. |

## Branch-Ready Constraints

- Do not release.
- Do not tag.
- Do not merge.
- Do not open a PR.
- Do not push to main.
- Next valid action after this feature-closeout is a separate human authorization for PR/release/main workflow, with Feature 141 overlap reconciliation handled before landing.

## Branch Hygiene at Closeout Preparation

- Branch: `159-update-ux-small-fixes`
- Upstream: `origin/159-update-ux-small-fixes`
- Pre-closeout synced HEAD: `1804fd81b153b89f7261d9e45302c64acdb1e630`
- Worktree was clean before feature-closeout authorization.
- Feature-closeout authorization was persisted for `iteration-closeout -> feature-closeout`.

## Final Status

Feature 159 is complete and ready as branch evidence only. It is not released, tagged, merged, PR-opened, or promoted to main.
