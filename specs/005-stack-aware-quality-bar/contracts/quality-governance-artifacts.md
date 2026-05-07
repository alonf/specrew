# Contract: Phase 1 Quality Governance Artifacts

**Date**: 2026-05-07  
**Spec**: [../spec.md](../spec.md)  
**Plan**: [../plan.md](../plan.md)

## Purpose

This contract defines the user-facing artifact surfaces introduced by the Phase 1 quality-profile foundation. It is normative for artifact shape and discoverability, but intentionally limited to the first-slice scope.

## Downstream Artifact Layout

```text
.specrew/
├── config.yml
├── presets/
│   └── *.md
└── lenses/
    └── *.md

specs/<feature>/iterations/<NNN>/quality/
├── quality-evidence.md
└── mechanical-findings.json
```

## `.specrew/config.yml` additions

The downstream config MUST expose a `quality` block:

```yaml
quality:
  presets_path: ".specrew/presets"
  lenses_path: ".specrew/lenses"
  findings_schema_version: "v1"
  evidence_directory_name: "quality"
```

Rules:

- Paths MUST be repo-relative.
- `findings_schema_version` MUST match the JSON schema version in `mechanical-findings.schema.json`.
- Omitted paths are invalid once the Phase 1 slice is enabled.

## Preset Artifact Contract

Each preset Markdown artifact MUST contain:

1. title with preset ID and semantic version
2. supported stack signals
3. required quality dimensions
4. required mechanical checks
5. required lens checklist references
6. toolchain/evidence expectations
7. upgrade guidance
8. change log

Additional rule:

- `node-public-ws-service` MUST include a worked example section with concrete selections and mappings.

## Lens Checklist Contract

Each lens checklist Markdown artifact MUST contain:

1. title with lens ID and semantic version
2. purpose/scope
3. line-item table with acceptance criteria
4. row-level status vocabulary
5. upgrade guidance
6. change log

## Planning Artifact Contract

The feature `plan.md` generated for an active feature MUST expose a Phase 1 quality planning section containing:

- inferred profile identifier
- selected preset refs or explicit custom composition
- stack surfaces in scope
- risk dimensions
- quality tool bundle
- required quality gates
- not-applicable dimensions and rationale
- explicit Phase 1 deferrals

## Iteration Evidence Contract

`quality-evidence.md` MUST include a gate matrix table with:

| Column | Meaning |
| --- | --- |
| Gate | Stable gate identifier |
| Requirement | Governing FR(s) |
| Evidence Source | Command, artifact, or findings path |
| Status | `planned`, `passed`, `failed`, `excepted`, `not-applicable` |
| Exception | Approved exception or demotion reference |

Rules:

- Every required gate declared in the plan MUST appear in the matrix.
- `excepted` requires an explicit exception reference.
- `failed` MUST remain visible until resolved; it cannot be omitted from the matrix.

## Non-Goals for This Contract

This contract does **not** define:

- hardening-gate sign-off artifacts
- dedicated bug-hunter execution records
- known-traps corpus artifacts
- quality-drift ledgers
- reference-implementation comparison surfaces

Those remain deferred to later phases.
