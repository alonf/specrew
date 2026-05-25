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

## 4) Verify update and redeploy decisions from docs

Use the operator docs only, not source code, to answer:

1. What is the normal installed-module update command?
2. When is `Install-Module -Force -SkipPublisherCheck` acceptable?
3. When should an existing project rerun `specrew init` after a module update?
4. What does `specrew init -Force` do, and what does it not bypass?

Expected answers:

- Normal update path: `Update-Module Specrew`, then `Import-Module Specrew -Force` and `specrew --version`.
- `Install-Module -Force -SkipPublisherCheck` is a trusted-source reinstall path, not a general habit for arbitrary modules.
- Rerun `specrew init` when release notes mention runtime/extension/template/skill-catalog changes, when `.specify/extensions/specrew-speckit/` is missing or stale, when `/specrew-*` skills are missing, or when `specrew start` reports a missing skill-catalog/runtime deployment gap.
- `specrew init -Force` intentionally refreshes managed Specrew project surfaces, but it does not approve lifecycle gates or bypass brownfield conflict checks.

## 5) Produce Phase 1 mechanical + quality evidence artifacts

```powershell
pwsh -NoProfile -File .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1 -ProjectPath C:/Dev/Specrew -IterationPath specs/045-v0271-bugfix-bundle/iterations/002
```

Expected outputs:

- `specs/045-v0271-bugfix-bundle/iterations/002/quality/mechanical-findings.json`
- `specs/045-v0271-bugfix-bundle/iterations/002/quality/quality-evidence.md`

## 6) Validate governance gates for the iteration slice

```powershell
pwsh -NoProfile -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath C:/Dev/Specrew -IterationPath specs/045-v0271-bugfix-bundle/iterations/002
```

## 7) Manual spot checks for the 7-item bundle

```powershell
specrew --version
specrew -v
specrew version
```

Additionally perform:

- `specrew start` in a project with missing skill catalogs and confirm auto-repair.
- `specrew init` and `specrew init -Force` with missing skill catalogs and confirm deployment-gap behavior.
- Brownfield run with self-hosting signal present and existing `.squad/agents/` path.
- Guided operator review from `docs/getting-started.md`, `docs/user-guide.md`, and this quickstart completes the update/redeploy decision check in under 3 minutes.
