# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-07
**Baseline Ref**: f58362bc6e951b821dad81260eee141d2c843521
**Test-to-Code Ratio**: 1:1

## Files Touched

| Path | Role | Owning Task ID(s) | Notes |
| --- | --- | --- | --- |
| `scripts/internal/user-profile.ps1` | Runtime helper | T002 | Adds setup-only labels/questions and `Normalize-CrewInteractionProfileSetupInput`; preserves stable keys and persona IDs. |
| `tests/integration/f049-i003-intake-engine-tests.ps1` | Integration test | T003 | Adds P170 assertions for setup metadata and parser normalization. |
| `proposals/170-new-user-profile-setup-copy.md` | Proposal | T001 | Captures problem, scope, acceptance criteria, and non-goals. |
| `proposals/INDEX.md` | Proposal index | T001 | Adds candidate entry for Proposal 170. |
| `specs/172-profile-setup-ux-copy/**` | Specrew artifacts | T001, T004 | Spec, plan, tasks, evidence, review, retro, dashboard, and quality artifacts. |

## Public-API Delta

### Added

- `Normalize-CrewInteractionProfileSetupInput` exported from
  `scripts/internal/user-profile.ps1`.

### Removed

- none

## Stable Contracts Preserved

| Contract | Status |
| --- | --- |
| `product_management` expertise key | preserved |
| `ui_ux` expertise key | preserved |
| `software_architecture` expertise key | preserved |
| `ai_research_project_management` expertise key | preserved |
| `product-manager` persona ID | preserved |
| `ux-ui-specialist` persona ID | preserved |
| `architect` persona ID | preserved |
| `ai-researcher-project-manager` persona ID | preserved |

## Module Hotspots

- Threshold: 250 changed lines per file.
- none.
