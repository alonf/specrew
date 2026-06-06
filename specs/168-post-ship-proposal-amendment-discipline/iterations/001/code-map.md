# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-06
**Baseline Ref**: 90c42993c3ff00dc3d18e64e32de065077d854a3
**Implementation Ref**: a09d95173dbd720249320494d500464f993b6278
**Test-to-Code Ratio**: focused-regression

## Files Touched

| Surface | Paths | Owning Task(s) | Review Focus |
| ------- | ----- | -------------- | ------------ |
| Proposal discipline docs | `docs/methodology/proposal-discipline.md` | T003, T004 | Mutability classes, amendment template, statuses, active-proposal exclusion, allowed direct edits. |
| Reviewer guidance | `docs/methodology/review-instructions.md` | T005 | Delta-based review, preserve list, tests-required, disposition, FR-006/FR-015 release blocking. |
| Validator and mirror | `extensions/specrew-speckit/scripts/validate-governance.ps1`; `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | T006, T007, T008, T014 | Proposal status parsing, changed-section detection, warning-first body-edit findings, malformed-amendment findings, mirror parity. |
| Status surfacing | `proposals/INDEX.md` | T009, T010 | Human-maintained backlog for `accepted-unimplemented` and `active` post-ship amendments. |
| Synthetic fixtures | `tests/unit/fixtures/168-post-ship-proposal-amendment-discipline/**` | T011 | Shipped/superseded unsafe edits, valid amendment edits, allowed corrections, malformed amendments, index status fixture. |
| Focused replay | `tests/unit/validate-governance.post-ship-proposal-amendment.tests.ps1` | T012, T013 | Positive and negative validator behavior, docs assertions, reviewer guidance assertions, index assertions, mirror parity. |
| Lifecycle review evidence | `specs/168-post-ship-proposal-amendment-discipline/iterations/001/**` | T015, T016, T017 | Quality evidence, hardening gate proof, drift log, review verdict, reviewer artifacts. |

## Public Validator Delta

### Added Internal Helpers

- `Get-ProposalFrontMatterBounds`
- `Get-ProposalFrontMatterValue`
- `ConvertTo-NormalizedProposalSectionName`
- `Get-ProposalTopLevelSectionName`
- `Test-AllowedPostShipProposalDirectEdit`
- `Get-ProposalDiffChangedLines`
- `Get-GitBlobLines`
- `Get-PostShipAmendmentSection`
- `Get-PostShipAmendmentField`
- `Get-PostShipAmendmentRecords`
- `Test-PostShipAmendmentRecords`
- `Test-PostShipProposalAmendmentGovernance`
- `Write-PostShipProposalWarning`

### Removed

- none

## Hotspots

| Path | Rationale | Review Result |
| ---- | --------- | ------------- |
| `extensions/specrew-speckit/scripts/validate-governance.ps1` | Main validator delta. | pass |
| `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | Required mirror copy. | pass |
| `tests/unit/validate-governance.post-ship-proposal-amendment.tests.ps1` | Focused synthetic replay. | pass |

## Review Notes

- No runtime product files or shipped proposal bodies were rewritten.
- The validator delta is intentionally structural and warning-first; it does not claim full semantic diffing.
