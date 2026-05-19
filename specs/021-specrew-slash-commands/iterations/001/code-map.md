# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-18T14:13:50Z
**Baseline Ref**: d80fd4b
**Test-to-Code Ratio**: 7:7

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .squad/decisions.md | 343 | 0 | I1-W002, I1-W003 | Implementer |
| .squad/identity/now.md | 10 | 10 | I1-W002, I1-W003 | Implementer |
| README.md | 4 | 1 | I1-W002, I1-W003 | Implementer |
| Specrew.psd1 | 11 | 0 | I1-W002, I1-W003 | Implementer |
| Specrew.psm1 | 10 | 0 | I1-W002, I1-W003 | Implementer |
| extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 | 15 | 1 | I1-W002, I1-W003 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/README.md | 14 | 0 | I1-W002, I1-W003 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/specrew-help/SKILL.md | 67 | 0 | I1-W002, I1-W003 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/specrew-review/SKILL.md | 70 | 0 | I1-W002, I1-W003 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/specrew-status/SKILL.md | 73 | 0 | I1-W002, I1-W003 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/specrew-team/SKILL.md | 83 | 0 | I1-W002, I1-W003 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/specrew-update/SKILL.md | 70 | 0 | I1-W002, I1-W003 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/specrew-version/SKILL.md | 74 | 0 | I1-W002, I1-W003 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/specrew-where/SKILL.md | 75 | 0 | I1-W002, I1-W003 | Implementer |
| scripts/internal/version-check.ps1 | 4 | 0 | I1-W002, I1-W003 | Implementer |
| scripts/specrew-init.ps1 | 6 | 0 | I1-W002, I1-W003 | Implementer |
| scripts/specrew-update.ps1 | 6 | 0 | I1-W002, I1-W003 | Implementer |
| scripts/specrew-version.ps1 | 218 | 0 | I1-W002, I1-W003 | Implementer |
| scripts/specrew.ps1 | 349 | 1 | I1-W002, I1-W003 | Implementer |
| specs/021-specrew-slash-commands/iterations/001/drift-log.md | 26 | 0 | I1-W002, I1-W003 | Implementer |
| specs/021-specrew-slash-commands/iterations/001/plan.md | 8 | 8 | I1-W002, I1-W003 | Implementer |
| specs/021-specrew-slash-commands/iterations/001/quality/hardening-gate.md | 21 | 13 | I1-W002, I1-W003 | Implementer |
| specs/021-specrew-slash-commands/iterations/001/review.md | 64 | 0 | I1-W002, I1-W003 | Implementer |
| specs/021-specrew-slash-commands/iterations/001/state.md | 50 | 0 | I1-W002, I1-W003 | Implementer |
| specs/021-specrew-slash-commands/iterations/001/tasks.md | 25 | 13 | I1-W002, I1-W003 | Implementer |
| tests/README.md | 6 | 0 | I1-W004 | Reviewer |
| tests/integration/slash-command-coexistence.tests.ps1 | 141 | 0 | I1-W004 | Reviewer |
| tests/integration/slash-command-compatibility.tests.ps1 | 139 | 0 | I1-W004 | Reviewer |
| tests/integration/slash-command-discovery.tests.ps1 | 124 | 0 | I1-W004 | Reviewer |
| tests/integration/slash-command-distribution.tests.ps1 | 122 | 0 | I1-W004 | Reviewer |
| tests/integration/slash-command-routing.tests.ps1 | 139 | 0 | I1-W004 | Reviewer |
| tests/unit/slash-command-arg-whitelist.tests.ps1 | 124 | 0 | I1-W004 | Reviewer |

## Public-API Delta

### Added

- Show-SpecrewVersion (Specrew.psm1)
- Get-SpecrewSlashCommandMinVersion (scripts/internal/version-check.ps1)
- Show-Usage (scripts/specrew-version.ps1)
- Convert-UnixStyleVersionArguments (scripts/specrew-version.ps1)
- Write-UnsupportedArgumentError (scripts/specrew.ps1)
- Write-MissingArgumentValueError (scripts/specrew.ps1)
- Resolve-ProjectPathFromArguments (scripts/specrew.ps1)
- Assert-OptionArguments (scripts/specrew.ps1)
- Assert-TeamArguments (scripts/specrew.ps1)
- Assert-WhitelistedArguments (scripts/specrew.ps1)
- Assert-ProjectSetup (scripts/specrew.ps1)
- Assert-SlashCommandCompatibility (scripts/specrew.ps1)
- Write-Pass (tests/integration/slash-command-coexistence.tests.ps1)
- Write-Fail (tests/integration/slash-command-coexistence.tests.ps1)
- Assert-True (tests/integration/slash-command-coexistence.tests.ps1)
- Assert-Contains (tests/integration/slash-command-coexistence.tests.ps1)
- Assert-NotContains (tests/integration/slash-command-coexistence.tests.ps1)
- Write-Pass (tests/integration/slash-command-compatibility.tests.ps1)
- Write-Fail (tests/integration/slash-command-compatibility.tests.ps1)
- Assert-True (tests/integration/slash-command-compatibility.tests.ps1)
- Assert-Contains (tests/integration/slash-command-compatibility.tests.ps1)
- Write-Pass (tests/integration/slash-command-discovery.tests.ps1)
- Write-Fail (tests/integration/slash-command-discovery.tests.ps1)
- Assert-True (tests/integration/slash-command-discovery.tests.ps1)
- Assert-Contains (tests/integration/slash-command-discovery.tests.ps1)
- Write-Pass (tests/integration/slash-command-distribution.tests.ps1)
- Write-Fail (tests/integration/slash-command-distribution.tests.ps1)
- Assert-True (tests/integration/slash-command-distribution.tests.ps1)
- Assert-Contains (tests/integration/slash-command-distribution.tests.ps1)
- Write-Pass (tests/integration/slash-command-routing.tests.ps1)
- Write-Fail (tests/integration/slash-command-routing.tests.ps1)
- Assert-True (tests/integration/slash-command-routing.tests.ps1)
- Assert-Contains (tests/integration/slash-command-routing.tests.ps1)
- Assert-ExitCode (tests/integration/slash-command-routing.tests.ps1)
- Write-Pass (tests/unit/slash-command-arg-whitelist.tests.ps1)
- Write-Fail (tests/unit/slash-command-arg-whitelist.tests.ps1)
- Assert-True (tests/unit/slash-command-arg-whitelist.tests.ps1)
- Assert-Contains (tests/unit/slash-command-arg-whitelist.tests.ps1)
- Invoke-Specrew (tests/unit/slash-command-arg-whitelist.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- .squad/decisions.md (343 changed lines)
- scripts/specrew.ps1 (350 changed lines)
