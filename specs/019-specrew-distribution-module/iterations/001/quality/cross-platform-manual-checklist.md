# Iteration 001 Cross-Platform Manual Checklist

**Status**: executed-windows-first
**Decision Ref**: T003 approved on 2026-05-16 (Option A — manual checklist/evidence for Iteration 001)  
**Scope**: Windows-first evidence only for Iteration 001. Do **not** treat this checklist as Ubuntu/macOS/WSL parity proof.  
**Execution Rule**: Leave items unchecked until the underlying command or scenario has actually been run and evidence has been captured.

| # | Deliverable | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1 | `Test-ModuleManifest` passes for `Specrew.psd1` | [x] Done | `Test-ModuleManifest .\Specrew.psd1` → Name=`Specrew`, Version=`0.18.0`, PowerShellVersion=`7.0`, CompatiblePSEditions=`Core` | Executed 2026-05-16 during Pillar 1 validation |
| 2 | `Import-Module ./Specrew.psd1 -Force` succeeds | [x] Done | `Import-Module .\Specrew.psd1 -Force` completed; only the expected unapproved-verb warning surfaced for Specrew command names | Executed 2026-05-16 during Pillar 1 validation |
| 3 | Exported function set matches FR-002 (`specrew`, `specrew-init`, `specrew-start`, `specrew-where`, `specrew-review`, `specrew-team`, `specrew-update`) | [x] Done | `Get-Command -Module Specrew` returned all seven expected functions | Executed 2026-05-16 during Pillar 1 validation |
| 4 | `specrew help` returns expected catalog | [x] Done | `Import-Module .\Specrew.psd1 -Force; specrew help` returned the expected command catalog and examples | Executed 2026-05-16 during Pillar 1 validation |
| 5 | In a fresh empty Windows directory, `specrew init` succeeds and populates `.specify/`, `.squad/`, `.github/` | [x] Done | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\distribution-module-init.ps1` passed; module-path bootstrap created `.specify\templates\spec-template.md`, `.squad\identity\now.md`, `.squad\decisions.md`, `.github\agents\squad.agent.md`, and `.github\workflows\specrew-ci.yml` | Re-run 2026-05-16 during final validation after the bundled coordinator-prompt repair |
| 6 | `specrew start "test feature"` launches a Copilot CLI session with bootstrap prompt loaded | [x] Done | Imported the scratch module produced by `distribution-module-init.ps1`, injected a fake `copilot.cmd`, and ran `specrew-start -ProjectPath .scratch\distribution-module-init\project "Validate installed module start flow"`; the fake Copilot log captured `--agent Squad`, `.specrew\last-start-prompt.md`, `.specrew\start-context.json`, and `--allow-all` | Executed 2026-05-16; validates the installed-module handoff without requiring a real interactive Copilot session |
| 7 | `specrew where` renders the dashboard from installed module path | [x] Done | After importing the scratch module, `specrew-where -ProjectPath tests\integration\fixtures\feature-017-dashboard\healthy-repository -NoColor` rendered the full dashboard headings and roadmap sections | Executed 2026-05-16 against the installed-module command surface |
| 8 | `specrew update` template-refresh dry-run shows expected diff | [x] Done | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\distribution-module-update.ps1` passed; verified conflict markers, `.conflict`/`.deletion` artifacts, new-template addition, and version refresh behavior | Iteration 001 has no dedicated `specrew update --dry-run`; this fixture is the truthful Windows-first evidence for the expected diff/artifact behavior |
| 9 | Publish-Module workflow validates locally in dry-run/manual gate mode and does not perform a real PSGallery publish | [x] Done | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\distribution-module-publish.ps1` passed; validated version stamping, signing, `Publish-Module -WhatIf`, tag-gated live publish, and clear missing-secret error reporting | Executed 2026-05-16; no real PSGallery publish occurred |

## Deferred Beyond This Checklist

- Ubuntu/macOS matrix automation
- WSL Ubuntu end-to-end verification
- Broad Join-Path audit / embedded-backslash sweep
- Real PSGallery publish

Track those items in `.specrew/cross-platform-backlog.md`.
