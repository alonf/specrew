# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-08
**Baseline Ref**: 0bfaf204817a667c1fca0d842de302be860e68cf
**Test-to-Code Ratio**: 0:1

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .claude/settings.local.json | 3 | 1 | T002, T004, T006, T009, T011 | Implementer |
| .github/copilot-instructions.md | 4 | 1 | T002, T004, T006, T009, T011 | Implementer |
| .gitignore | 15 | 0 | T002, T004, T006, T009, T011 | Implementer |
| .specify/templates/plan-template.md | 47 | 0 | T002, T004, T006, T009, T011 | Implementer |
| .squad/agents/planner/history.md | 10 | 1 | T002, T004, T006, T009, T011 | Implementer |
| extensions/specrew-speckit/README.md | 13 | 1 | T002, T004, T006, T009, T011 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md | 15 | 5 | T002, T004, T006, T009, T011 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-governance.ps1 | 126 | 17 | T002, T004, T006, T009, T011 | Implementer |
| extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | 5 | 3 | T002, T004, T006, T009, T011 | Implementer |

## Public-API Delta

### Added

- Ensure-ManagedDirectory (extensions/specrew-speckit/scripts/scaffold-governance.ps1)
- Save-ManagedTemplateTree (extensions/specrew-speckit/scripts/scaffold-governance.ps1)
- Save-ConfigFile (extensions/specrew-speckit/scripts/scaffold-governance.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none
