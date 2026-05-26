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
pwsh -NoProfile -File tests/integration/review-command.ps1
pwsh -NoProfile -File tests/integration/lifecycle-trace-contract.ps1
pwsh -NoProfile -File tests/integration/validation-contract-lane.ps1
pwsh -NoProfile -File tests/integration/closeout-identity-schema-parity.tests.ps1
pwsh -NoProfile -File tests/integration/lifecycle-boundary-sync.tests.ps1
pwsh -NoProfile -File tests/integration/start-recovery-flow.tests.ps1
pwsh -NoProfile -File tests/integration/bootstrap-asset-blocker-recovery.ps1
pwsh -NoProfile -File tests/integration/brownfield-conflict-handling.ps1
pwsh -NoProfile -File tests/integration/deploy-extension-missing-source-tolerance.tests.ps1
pwsh -NoProfile -File tests/integration/validate-versions-cli-behavior.ps1
pwsh -NoProfile -File tests/integration/drift-scenario.ps1
pwsh -NoProfile -File tests/integration/iteration-resume.ps1
pwsh -NoProfile -File tests/integration/planning-effort-model.ps1
pwsh -NoProfile -File tests/integration/planning-overcommit.ps1
pwsh -NoProfile -File tests/integration/process-quality-report.ps1
pwsh -NoProfile -File tests/integration/process-quality-scorer.ps1
pwsh -NoProfile -File tests/integration/feature-017-dashboard-core.ps1
pwsh -NoProfile -File tests/integration/review-evidence-integrity.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-routing.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-distribution.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-compatibility.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-discovery.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-coexistence.tests.ps1
pwsh -NoProfile -File tests/unit/slash-command-arg-whitelist.tests.ps1
```

### CI workflow parity

```powershell
# Deterministic gate
pwsh -NoProfile -File tests/integration/bootstrap-to-iteration.ps1
pwsh -NoProfile -File tests/integration/bootstrap-asset-blocker-recovery.ps1
pwsh -NoProfile -File tests/integration/brownfield-conflict-handling.ps1
pwsh -NoProfile -File tests/integration/deploy-extension-missing-source-tolerance.tests.ps1
pwsh -NoProfile -File tests/integration/validate-versions-cli-behavior.ps1
pwsh -NoProfile -File tests/integration/drift-scenario.ps1
pwsh -NoProfile -File tests/integration/iteration-resume.ps1
pwsh -NoProfile -File tests/integration/planning-effort-model.ps1
pwsh -NoProfile -File tests/integration/planning-overcommit.ps1
pwsh -NoProfile -File tests/integration/process-quality-report.ps1
pwsh -NoProfile -File tests/integration/process-quality-scorer.ps1
pwsh -NoProfile -File tests/integration/feature-017-dashboard-core.ps1
pwsh -NoProfile -File tests/integration/closeout-identity-schema-parity.tests.ps1
pwsh -NoProfile -File tests/integration/lifecycle-boundary-sync.tests.ps1
pwsh -NoProfile -File tests/integration/start-recovery-flow.tests.ps1

# Contract lane
pwsh -NoProfile -File tests/integration/validation-contract-lane.ps1
```

GitHub Actions runs `.github/workflows/specrew-ci.yml`, which performs markdown lint, PowerShell lint, governance validation, the deterministic gate, and the contract lane.

### Manual Copilot/Squad smoke harness

Use this when you want a real mission-completion check beyond CI-safe integration coverage:

```powershell
pwsh -NoProfile -File tests/manual/copilot-squad-smoke.ps1
pwsh -NoProfile -File tests/manual/copilot-squad-smoke.ps1 -LaunchCopilot
pwsh -NoProfile -File tests/manual/copilot-squad-smoke.ps1 -LaunchCopilot -NewWindow
pwsh -NoProfile -File tests/manual/copilot-squad-confidence-lane.ps1
pwsh -NoProfile -File tests/manual/copilot-squad-confidence-lane.ps1 -LaunchCopilot
```

What it does:

- creates a fresh scratch project folder
- runs `git init`
- runs `specrew init`
- runs `specrew start` with a tiny default feature request
- either prints the exact manual Copilot handoff command (`--no-launch` mode) or launches Copilot+Squad for a real handoff check
- when `-LaunchCopilot` is used, the harness defaults to **same-window** so an operator can monitor the live session; use `-NewWindow` only when you intentionally want detached observation

This harness is intentionally **not** part of CI because the final Copilot/Squad execution step is environment-dependent and may require trust prompts or live operator observation.

### Confidence lane traces

`tests/manual/copilot-squad-confidence-lane.ps1` wraps the smoke harness and persists a structured JSON trace with:

- lane name and execution mode
- replay input paths (`last-start-prompt.md`, `start-context.json`, `start-summary.md`)
- captured output lines
- policy evidence copied from `start-context.json`

The scheduled confidence workflow uploads these traces as build artifacts so live/smoke failures can be replayed later as deterministic fixtures.

## Exit behavior

- Integration scripts return `0` on pass.
- Integration scripts return non-zero on validation failure.
- Scripts may print `SKIP:` and return `0` when required external tooling is unavailable.

### Dashboard-specific checks

```powershell
pwsh -NoProfile -File tests/integration/feature-017-dashboard-core.ps1
pwsh -NoProfile -File tests/unit/feature-017-dashboard.tests.ps1
Get-Content tests/manual/feature-017-dashboard-quickstart.md
```
