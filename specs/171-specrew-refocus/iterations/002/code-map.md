# Code Map: Iteration 002 — research-gated host bindings, carries, docs, beta evidence

**Schema**: v1
**Reviewed**: 2026-06-07
**Baseline Ref**: 3ba1d8d77a17bf27be16a20471861322b1b5f3a2
**Test-to-Code Ratio**: 3:9

> **Review Evidence Warning disposition** _(reviewed, explained)_: the 5-tasks-vs-39-files scaffold flag decomposes into 19 implementation files (3 scripts x3 trees, catalog+digests x2 trees, init/update wiring, 4 manifests), 2 test suites, 3 docs, 9 spec/lifecycle artifacts, 6 state-trail files - all committed and task-traceable; full decomposition in coverage-evidence.md.

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/refocus-scopes.json | 1 | 1 | T013, T014, T015, T016, T017 | Implementer |
| .specify/extensions/specrew-speckit/refocus/implement.md | 1 | 1 | T013, T014, T015, T016, T017 | Implementer |
| .specify/extensions/specrew-speckit/refocus/plan.md | 2 | 1 | T013, T014, T015, T016, T017 | Implementer |
| .specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1 | 152 | 70 | T013, T014, T015, T016, T017 | Implementer |
| .specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 | 47 | 15 | T013, T014, T015, T016, T017 | Implementer |
| .specrew/last-validator-summary.json | 4 | 4 | T013, T014, T015, T016, T017 | Implementer |
| .specrew/runtime/refocus-channel1.json | 1 | 1 | T013, T014, T015, T016, T017 | Implementer |
| .squad/active-features.yml | 1 | 1 | T013, T014, T015, T016, T017 | Implementer |
| .squad/decisions.md | 22 | 0 | T013, T014, T015, T016, T017 | Implementer |
| .squad/events/lifecycle-events.jsonl | 1 | 0 | T013, T014, T015, T016, T017 | Implementer |
| .squad/identity/now.md | 5 | 5 | T013, T014, T015, T016, T017 | Implementer |
| README.md | 1 | 0 | T013, T014, T015, T016, T017 | Implementer |
| Specrew.psd1 | 1 | 0 | T013, T014, T015, T016, T017 | Implementer |
| docs/troubleshooting.md | 12 | 0 | T013, T014, T015, T016, T017 | Implementer |
| docs/user-guide.md | 9 | 0 | T013, T014, T015, T016, T017 | Implementer |
| extensions/specrew-speckit/refocus-scopes.json | 1 | 1 | T013, T014, T015, T016, T017 | Implementer |
| extensions/specrew-speckit/refocus/implement.md | 1 | 1 | T013, T014, T015, T016, T017 | Implementer |
| extensions/specrew-speckit/refocus/plan.md | 2 | 1 | T013, T014, T015, T016, T017 | Implementer |
| extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1 | 152 | 70 | T013, T014, T015, T016, T017 | Implementer |
| extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 | 47 | 15 | T013, T014, T015, T016, T017 | Implementer |
| hosts/codex/host.psd1 | 11 | 0 | T013, T014, T015, T016, T017 | Implementer |
| hosts/copilot/host.psd1 | 12 | 0 | T013, T014, T015, T016, T017 | Implementer |
| hosts/cursor/host.psd1 | 11 | 0 | T013, T014, T015, T016, T017 | Implementer |
| scripts/internal/deploy-refocus-hooks.ps1 | 152 | 70 | T013, T014, T015, T016, T017 | Implementer |
| scripts/internal/refocus-deploy-integration.ps1 | 106 | 0 | T013, T014, T015, T016, T017 | Implementer |
| scripts/internal/specrew-hook-dispatcher.ps1 | 47 | 15 | T013, T014, T015, T016, T017 | Implementer |
| scripts/specrew-init.ps1 | 24 | 0 | T013, T014, T015, T016, T017 | Implementer |
| scripts/specrew-update.ps1 | 13 | 0 | T013, T014, T015, T016, T017 | Implementer |
| specs/171-specrew-refocus/beta-validation.md | 25 | 0 | T013, T014, T015, T016, T017 | Implementer |
| specs/171-specrew-refocus/iterations/001/retro.md | 13 | 2 | T013, T014, T015, T016, T017 | Implementer |
| specs/171-specrew-refocus/iterations/002/drift-log.md | 50 | 0 | T013, T014, T015, T016, T017 | Implementer |
| specs/171-specrew-refocus/iterations/002/plan.md | 101 | 0 | T013, T014, T015, T016, T017 | Implementer |
| specs/171-specrew-refocus/iterations/002/quality/hardening-gate.md | 28 | 0 | T013, T014, T015, T016, T017 | Implementer |
| specs/171-specrew-refocus/iterations/002/state.md | 35 | 0 | T013, T014, T015, T016, T017 | Implementer |
| specs/171-specrew-refocus/research-matrix.md | 77 | 0 | T013, T014, T015, T016, T017 | Implementer |
| specs/171-specrew-refocus/spec.md | 1 | 1 | T017 | Implementer |
| specs/171-specrew-refocus/tasks.md | 3 | 2 | T013, T014, T015, T016, T017 | Implementer |
| tests/integration/refocus-deploy.tests.ps1 | 127 | 0 | T017 | Implementer |
| tests/integration/refocus-dispatcher.tests.ps1 | 34 | 0 | T017 | Implementer |

## Public-API Delta

### Added

- Test-IsSpecrewCommandText (.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Test-IsSpecrewGroup (.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Remove-SpecrewEntriesFromEventMap (.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Get-HostEventGroups (.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Save-Target (.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Test-IsSpecrewCommandText (extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Test-IsSpecrewGroup (extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Remove-SpecrewEntriesFromEventMap (extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Get-HostEventGroups (extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Save-Target (extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Test-IsSpecrewCommandText (scripts/internal/deploy-refocus-hooks.ps1)
- Test-IsSpecrewGroup (scripts/internal/deploy-refocus-hooks.ps1)
- Remove-SpecrewEntriesFromEventMap (scripts/internal/deploy-refocus-hooks.ps1)
- Get-HostEventGroups (scripts/internal/deploy-refocus-hooks.ps1)
- Save-Target (scripts/internal/deploy-refocus-hooks.ps1)
- Get-RefocusCatalogOverlay (scripts/internal/refocus-deploy-integration.ps1)
- Set-RefocusCatalogOverlay (scripts/internal/refocus-deploy-integration.ps1)
- Invoke-RefocusHookDeployment (scripts/internal/refocus-deploy-integration.ps1)

### Removed

- Test-IsSpecrewHook (.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Remove-SpecrewEntries (.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Test-IsSpecrewHook (extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Remove-SpecrewEntries (extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1)
- Test-IsSpecrewHook (scripts/internal/deploy-refocus-hooks.ps1)
- Remove-SpecrewEntries (scripts/internal/deploy-refocus-hooks.ps1)

## Module Hotspots

- Threshold: 250 changed lines per file
- none
