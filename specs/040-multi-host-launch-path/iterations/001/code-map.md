# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-23
**Baseline Ref**: 30545071fc5b0b9d3f99e16b9ea6c39f3a7c3c1d (plan-boundary commit)
**Test-to-Code Ratio**: 1:5 (15 assertions across ~550 SLOC of new code)

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| scripts/internal/detect-hosts.ps1 (new) | 198 | 0 | T002, T007 | Implementer |
| scripts/internal/host-flag-translation.ps1 (new) | 95 | 0 | T003 | Implementer |
| scripts/internal/coordinator-prompt-surgery.ps1 (new) | 125 | 0 | T004 | Implementer |
| scripts/specrew-start.ps1 | ~150 | ~80 | T001, T005, T006, T008 | Implementer |
| tests/integration/multi-host-launch-path.tests.ps1 (new) | 195 | 0 | T009 | Implementer |
| docs/getting-started.md | ~30 | ~5 | T010 | Implementer |
| docs/user-guide.md | ~80 | 0 | T010, T010a | Implementer |
| Specrew.psd1 | 1 | 1 | T011 | Implementer |
| .specrew/config.yml | 1 | 1 | T011 | Implementer |
| extensions/specrew-speckit/extension.yml | 1 | 1 | T011 | Implementer |
| .specify/extensions/specrew-speckit/extension.yml | 1 | 1 | T011 | Implementer |
| CHANGELOG.md | 8 | 0 | T012 | Implementer |
| proposals/069-multi-host-launch-path.md | 5 | 4 | T013 | Implementer |
| proposals/INDEX.md | 4 | 2 | T014 | Implementer |
| specs/040-multi-host-launch-path/iterations/001/*.md | ~250 | 0 | T009-T014 | Implementer |

## Public-API Delta

### Added

- `specrew start -HostKind <copilot|claude|codex>` parameter (CLI alias: `--host`)
- `specrew start -HostKind antigravity` and `--host auto` accepted by parser but rejected with explicit "deferred" guidance (intentional sentinel surface for follow-up slices)
- `.specrew/start-context.json` additive fields: `selected_host`, `available_hosts`, `crew_runtime_status`
- PowerShell module functions (internal): `Get-SpecrewSupportedHostKinds`, `Get-SpecrewDeferredHostKinds`, `Get-SpecrewHostBinary`, `Get-SpecrewHostInstallGuidance`, `Get-SpecrewDeferredHostGuidance`, `Test-SpecrewHostAvailable`, `Get-SpecrewAvailableHosts`, `Test-HostSkillRoot`, `Get-SpecrewHostSkillRoot`, `Get-HostFlagTranslation`, `Get-SpecrewUniversalCoordinatorHeader`, `Invoke-SpecrewCoordinatorPromptSurgery`, `Get-SpecrewHostLaunchInvocation`

### Removed

- none

### Changed

- `specrew start` coordinator-prompt opening line: `"You are Squad running inside a Specrew-bootstrapped repository."` → `"You are the Crew team coordinator running inside a Specrew-bootstrapped repository."` — applied to ALL hosts including Copilot per FR-011 + INDEX.md 2026-05-21 terminology alignment

## Module Hotspots

- Threshold: 250 changed lines per file
- `scripts/specrew-start.ps1` (~230 changed lines including the dispatch rewrite + parameter wiring + Save-StartArtifacts schema extension)
