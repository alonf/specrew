# Quality Evidence: Iteration 001

**Iteration**: 001
**Feature**: 168-post-ship-proposal-amendment-discipline
**Phase**: before-implement readiness
**Last Updated**: 2026-06-06

## Quality Profile and Scope

**Selected Profile**: `quality-profile.custom-composition.v1`

| Stack Surface | Path Globs | Recognized Stack | Coverage Status |
| --- | --- | --- | --- |
| Proposal discipline docs | `docs/methodology/proposal-discipline.md` | Markdown governance docs | planned |
| Reviewer guidance | `docs/methodology/review-instructions.md` | Markdown review docs | planned |
| Governance validator | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | PowerShell governance script | planned |
| Synthetic proposal fixtures | `tests/**/fixtures/**` | Markdown fixtures | planned |
| Proposal status surfacing | `proposals/INDEX.md` or narrower discovered renderer | Markdown/PowerShell status surface | planned |

## Required Quality Gates

| Required Quality Gate | Category | Status | Evidence Source | Notes |
| --- | --- | --- | --- | --- |
| FR-006 delta evidence | manual-evidence | planned | review gap ledger | Release-blocking. |
| FR-015 no shipped rewrite | manual-evidence | planned | final diff audit | Release-blocking. |
| Shipped/superseded unsafe edit warning | validator | planned | focused tests and governance validation | Warning-first only. |
| Malformed amendment finding | validator | planned | focused tests | Separate from unsafe body-edit warnings. |
| Status surfacing | observable-output | planned | focused tests or documented index/status diff | Docs/index-only unless narrower renderer exists. |
| Mirror parity | mechanical | planned | file comparison or focused test | Required if validator script changes. |
| Test integrity | mechanical | planned | focused unit/integration tests | Synthetic fixtures only. |

## Proposal 145 Review Evidence Plan

| Review Discipline | Required Evidence |
| --- | --- |
| Claim-to-evidence ledger | Map every delivered claim to changed files, tests, and review proof. |
| Delta-only diff audit | Confirm no real shipped proposal bodies were rewritten and no shipped behavior was reimplemented. |
| Branch hygiene proof | Record HEAD/upstream parity and unrelated dirty drift classification. |
| Over-strong-claim checks | Reject claims that validator/tests/status output do not actually prove. |

## Pending Commands

Commands will be finalized after T002 discovers exact test locations. Expected baseline:

```powershell
npx markdownlint-cli docs/methodology/proposal-discipline.md docs/methodology/review-instructions.md
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\unit\post-ship-proposal-amendment-discipline.tests.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\.specify\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

## Notes

- Implementation has not started.
- This file records planned evidence only until T015 updates it with actual commands and outcomes.
