# Roadmap Maintenance

The velocity dashboard reads `.specrew/roadmap.yml`.

## Schema

```yaml
phases:
  - id: phase-1-foundations
    name: "Phase 1: Foundations"
    description: "Bootstrap and governance groundwork"
    planned_effort_sp: 48
    status: shipped
    feature_refs:
      - 009-project-path-resolution
      - 011-specrew-start-conditional-pause
```

## Rules

- `planned_effort_sp` is the human-maintained target for the phase.
- `feature_refs` must point at real `specs/<feature>` directories once the phase is scoped; placeholder phases can temporarily leave the list empty with explicit TODO notes.
- shipped effort is derived from canonical closed-iteration history, not entered
  manually in the roadmap.
- the validator may emit `WARN [dashboard] roadmap-schema` or
  `WARN [dashboard] roadmap-drift` when the roadmap becomes misleading.
- phases where derived shipped effort exceeds planned effort surface a
  `drifted-over` effective status and warning until reconciled.

## Updating phases

1. add or remove feature refs as scope changes
2. keep the declared phase `status` aligned with actual shipped progress
3. rerun:

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 where --no-color
pwsh -NoProfile -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```
