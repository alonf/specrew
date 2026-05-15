# Quickstart: Velocity Dashboard

This quickstart describes the intended Feature 017 workflow once implementation is complete.

## 1. Add roadmap input

Create `.specrew/roadmap.yml` with ordered phases and feature references:

```yaml
phases:
  - id: phase-1-foundations
    name: "Phase 1: Planning & Foundations"
    description: "Bootstrap and governance foundations"
    planned_effort_sp: 48
    status: shipped
    feature_refs:
      - 011-specrew-start-conditional-pause
      - 013-validator-hardening

  - id: phase-2-core
    name: "Phase 2: Core Features & Integration"
    description: "Core product and integration work"
    planned_effort_sp: 60
    status: in-progress
    feature_refs:
      - 015-public-readiness-pass
      - 016-substantive-interaction-model
      - 017-velocity-dashboard
```

## 2. Render the dashboard on demand

Canonical command:

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 where
```

Alias:

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 status
```

Dedicated script entry point:

```powershell
pwsh -NoProfile -File .\scripts\specrew-where.ps1
```

## 3. Use supported v1 options

Compact closeout-friendly view:

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 where --compact
```

Force monochrome output:

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 where --no-color
```

Reserved team path (friendly fallback to personal view):

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 where --team
```

## 4. Expected output shape

The dashboard should always preserve this high-level order:

1. Repository identity/header
2. Active work
3. Velocity headline
4. Recently shipped work
5. Recent iterations plan-vs-reality table
6. Full-history iteration summary
7. Roadmap progress
8. Remaining effort and projection
9. Data quality/setup warnings

Compact mode keeps the same meaning but compresses the output to a fixed 24-line layout.

## 5. Closeout artifact behavior

Iteration closeout generates:

```text
specs/<feature>/iterations/<NNN>/dashboard.md
```

Feature closeout generates:

```text
specs/<feature>/closeout-dashboard.md
```

These files are historical snapshots. Re-running the dashboard later produces a fresh live view and
must not silently overwrite stored closeout artifacts.

## 6. Verification targets

Recommended verification commands for implementation review:

```powershell
pwsh -NoProfile -File tests/integration/<feature-017-dashboard-test>.ps1
pwsh -NoProfile -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
pwsh -NoProfile -Command "if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) { Invoke-ScriptAnalyzer -Path . -Recurse -IncludeDefaultRules }"
```

## 7. Expected degraded behavior

- Missing roadmap file: render non-roadmap sections and show onboarding guidance.
- Sparse or malformed history: skip unusable records, emit bounded warnings, and continue.
- Non-TTY / `NO_COLOR` / dumb terminal: render readable monochrome output.
- `--team` before multi-developer support: explain limitation, then render the personal dashboard.
