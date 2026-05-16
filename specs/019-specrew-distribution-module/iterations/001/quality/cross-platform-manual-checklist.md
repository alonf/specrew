# Iteration 001 Cross-Platform Manual Checklist

**Status**: scaffolded-not-executed  
**Decision Ref**: T003 approved on 2026-05-16 (Option A — manual checklist/evidence for Iteration 001)  
**Scope**: Windows-first evidence only for Iteration 001. Do **not** treat this checklist as Ubuntu/macOS/WSL parity proof.  
**Execution Rule**: Leave items unchecked until the underlying command or scenario has actually been run and evidence has been captured.

| # | Deliverable | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1 | `Test-ModuleManifest` passes for `Specrew.psd1` | [x] Done | `Test-ModuleManifest .\Specrew.psd1` → Name=`Specrew`, Version=`0.18.0`, PowerShellVersion=`7.0`, CompatiblePSEditions=`Core` | Executed 2026-05-16 during Pillar 1 validation |
| 2 | `Import-Module ./Specrew.psd1 -Force` succeeds | [x] Done | `Import-Module .\Specrew.psd1 -Force` completed; only the expected unapproved-verb warning surfaced for Specrew command names | Executed 2026-05-16 during Pillar 1 validation |
| 3 | Exported function set matches FR-002 (`specrew`, `specrew-init`, `specrew-start`, `specrew-where`, `specrew-review`, `specrew-team`, `specrew-update`) | [x] Done | `Get-Command -Module Specrew` returned all seven expected functions | Executed 2026-05-16 during Pillar 1 validation |
| 4 | `specrew help` returns expected catalog | [x] Done | `Import-Module .\Specrew.psd1 -Force; specrew help` returned the expected command catalog and examples | Executed 2026-05-16 during Pillar 1 validation |
| 5 | In a fresh empty Windows directory, `specrew init` succeeds and populates `.specify/`, `.squad/`, `.github/` | [ ] Pending |  |  |
| 6 | `specrew start "test feature"` launches a Copilot CLI session with bootstrap prompt loaded | [ ] Pending |  |  |
| 7 | `specrew where` renders the dashboard from installed module path | [ ] Pending |  |  |
| 8 | `specrew update` template-refresh dry-run shows expected diff | [ ] Pending |  |  |
| 9 | Publish-Module workflow validates locally in dry-run/manual gate mode and does not perform a real PSGallery publish | [ ] Pending |  |  |

## Deferred Beyond This Checklist

- Ubuntu/macOS matrix automation
- WSL Ubuntu end-to-end verification
- Broad Join-Path audit / embedded-backslash sweep
- Real PSGallery publish

Track those items in `.specrew/cross-platform-backlog.md`.
