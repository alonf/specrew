# Quickstart — Validate v0.27.1 Bug-Fix Bundle

## Preconditions

- Working directory: `C:\Dev\Specrew`
- PowerShell 7+ available

## 1) Validate top-level version aliases and parity

```powershell
pwsh -NoProfile -File tests/integration/validate-versions-cli-behavior.ps1
```

## 2) Validate brownfield ownership conflict handling

```powershell
pwsh -NoProfile -File tests/integration/brownfield-conflict-handling.ps1
```

## 3) Validate start/init recovery-path integrity

```powershell
pwsh -NoProfile -File tests/integration/start-recovery-flow.tests.ps1
```

## 4) Produce Phase 1 mechanical + quality evidence artifacts

```powershell
pwsh -NoProfile -File .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1 -ProjectPath C:/Dev/Specrew -IterationPath specs/045-v0271-bugfix-bundle/iterations/001
```

Expected outputs:

- `specs/045-v0271-bugfix-bundle/iterations/001/quality/mechanical-findings.json`
- `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md`

## 5) Validate governance gates for the iteration slice

```powershell
pwsh -NoProfile -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath C:/Dev/Specrew -IterationPath specs/045-v0271-bugfix-bundle/iterations/001
```

## 6) Manual spot checks for the 7-item bundle

```powershell
specrew --version
specrew -v
specrew version
```

Additionally perform:

- `specrew start` in a project with missing skill catalogs and confirm auto-repair.
- `specrew init` and `specrew init -Force` with missing skill catalogs and confirm deployment-gap behavior.
- Brownfield run with self-hosting signal present and existing `.squad/agents/` path.
