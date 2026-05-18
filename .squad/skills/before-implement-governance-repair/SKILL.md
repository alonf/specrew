# Before-Implement Governance Repair

## When to use

Use this pattern when a feature is blocked at the `speckit.specrew-speckit.before-implement` boundary by artifact drift rather than runtime defects.

## Repair checklist

1. Record the latest human authorization text verbatim in `.squad/decisions.md`, including any conditional implementation-start rule.
2. Remove stale iteration-plan wording that still claims `tasks.md` is absent after task generation, and point the next boundary at before-implement review rather than earlier planning steps.
3. Make task body trace metadata echo every SC listed in a task's Trace field so traceability is explicit in both places.
4. Add a hardening-gate sign-off section that records authority, authorization text, implementation-start condition, and any explicitly deferred items with rationale.
5. Audit authoritative planning artifacts for accidental `FR-031`..`FR-033` references; if absent, leave scope alone.
6. Rerun `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\<feature>\iterations\<NNN>` and stop if new blockers remain.
7. If the iteration is parked at the implementation-start boundary, normalize the iteration-plan header to validator-recognized values: use execution-boundary status wording (`executing`) and keep the `Capacity` denominator equal to `.specrew\iteration-config.yml` capacity while preserving any smaller feature-slice lock in the body text.
