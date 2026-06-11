# Code Map: Iteration 009

**Schema**: v1
**Reviewed**: 2026-06-11
**Baseline Ref**: iteration-008 HEAD (`7fe04228`)
**Test-to-Code Ratio**: 1 suite (HandoverHookPrimary, 21 + 7 T007 assertions) : 8 code files

## Changed Surface (iteration 009)

| File | Requirement | What changed |
| ---- | ----------- | ------------ |
| `scripts/internal/bootstrap/HandoverStore.ps1` | FR-009, FR-021 | Section-ownership model; the core `Update-SpecrewRollingHandover` single save path; the de-noised render leading with user files + a managed count (T007). |
| `scripts/internal/bootstrap/ProjectMetadataAccessor.ps1` | FR-010 | `Get-SpecrewSessionDelta` accessor; the managed-vs-user partition + `--untracked-files=all` (T007). |
| `scripts/internal/specrew-handover-provider.ps1` (+ extensions mirror) | FR-009, FR-010 | Thin adapter to the core; reads `--source-event`. |
| `scripts/internal/specrew-hook-dispatcher.ps1` (+ extensions mirror) | FR-009 | Passes `--source-event` to non-refocus inject providers. |
| `scripts/internal/deploy-refocus-hooks.ps1` (+ extensions mirror) | FR-009 | Registers the Claude `PostToolUse` host hook (multi-source); + the codex array-shape self-heal (chore `ec08752f`). |
| `extensions/specrew-speckit/refocus-scopes.json` | FR-009 | Adds `PostToolUse` to the handover provider events. |
| `extensions/specrew-speckit/squad-templates/skills/design-workshop.md` | FR-009 | Per-lens `--source workshop` handover refresh. |
| `tests/bootstrap/HandoverHookPrimary.Tests.ps1` | SC-004 | Multi-source coverage + the T007 de-noise regression block (f). |

## Hotspots

- None flagged. Changes are confined to the bootstrap components (the accessor, the core orchestrator, the
  thin providers as triggers) + the deploy registration + the workshop-skill step — clean IDesign seams.

## Notes

- The reviewer-artifact scaffold (`scaffold-reviewer-artifacts.ps1`) crashed under `Set-StrictMode -Version
  Latest` on this iteration (`The property 'Count' cannot be found on this object`); this code-map is
  hand-authored. The scaffold crash is filed as a **tooling-defect finding** (iteration-010 chore candidate).
