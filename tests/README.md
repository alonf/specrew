# Specrew Tests

This directory contains test suites for the Specrew project.

## Test Structure

Tests are organized by component:

- `extensions/` - Tests for Spec Kit and Squad extensions
- `integration/` - End-to-end integration tests
- `manual/` - Operator-driven smoke harnesses for real Copilot/Squad handoff checks
- `unit/` - Unit tests for scripts and utilities

## Running Tests

Run from repository root (`c:/Dev/Specrew`).

### Unit-style checks (PowerShell scripts)

```powershell
pwsh -NoProfile -Command "if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) { Invoke-ScriptAnalyzer -Path . -Recurse -IncludeDefaultRules | Format-Table -AutoSize; if ($LASTEXITCODE) { exit $LASTEXITCODE } } else { Write-Host 'SKIP: PSScriptAnalyzer not installed' }"
```

### Integration checks

```powershell
pwsh -NoProfile -File tests/integration/bootstrap-to-iteration.ps1
pwsh -NoProfile -File tests/integration/start-command.ps1
pwsh -NoProfile -File tests/integration/bootstrap-asset-blocker-recovery.ps1
pwsh -NoProfile -File tests/integration/brownfield-conflict-handling.ps1
pwsh -NoProfile -File tests/integration/validate-versions-cli-behavior.ps1
pwsh -NoProfile -File tests/integration/drift-scenario.ps1
pwsh -NoProfile -File tests/integration/iteration-resume.ps1
pwsh -NoProfile -File tests/integration/planning-effort-model.ps1
pwsh -NoProfile -File tests/integration/planning-overcommit.ps1
pwsh -NoProfile -File tests/integration/process-quality-report.ps1
pwsh -NoProfile -File tests/integration/process-quality-scorer.ps1
```

### CI workflow parity

```powershell
pwsh -NoProfile -File tests/integration/bootstrap-to-iteration.ps1
pwsh -NoProfile -File tests/integration/start-command.ps1
pwsh -NoProfile -File tests/integration/bootstrap-asset-blocker-recovery.ps1
pwsh -NoProfile -File tests/integration/brownfield-conflict-handling.ps1
pwsh -NoProfile -File tests/integration/validate-versions-cli-behavior.ps1
pwsh -NoProfile -File tests/integration/drift-scenario.ps1
pwsh -NoProfile -File tests/integration/iteration-resume.ps1
pwsh -NoProfile -File tests/integration/planning-effort-model.ps1
pwsh -NoProfile -File tests/integration/planning-overcommit.ps1
pwsh -NoProfile -File tests/integration/process-quality-report.ps1
pwsh -NoProfile -File tests/integration/process-quality-scorer.ps1
```

GitHub Actions runs `.github/workflows/specrew-ci.yml`, which performs markdown lint, PowerShell lint, governance validation, and the integration scripts.

### Manual Copilot/Squad smoke harness

Use this when you want a real mission-completion check beyond CI-safe integration coverage:

```powershell
pwsh -NoProfile -File tests/manual/copilot-squad-smoke.ps1
pwsh -NoProfile -File tests/manual/copilot-squad-smoke.ps1 -LaunchCopilot
pwsh -NoProfile -File tests/manual/copilot-squad-smoke.ps1 -LaunchCopilot -NewWindow
```

What it does:

- creates a fresh scratch project folder
- runs `git init`
- runs `specrew init`
- runs `specrew start` with a tiny default feature request
- either prints the exact manual Copilot handoff command (`--no-launch` mode) or launches Copilot+Squad for a real handoff check
- when `-LaunchCopilot` is used, the harness defaults to **same-window** so an operator can monitor the live session; use `-NewWindow` only when you intentionally want detached observation

This harness is intentionally **not** part of CI because the final Copilot/Squad execution step is environment-dependent and may require trust prompts or live operator observation.

## Exit behavior

- Integration scripts return `0` on pass.
- Integration scripts return non-zero on validation failure.
- Scripts may print `SKIP:` and return `0` when required external tooling is unavailable.
