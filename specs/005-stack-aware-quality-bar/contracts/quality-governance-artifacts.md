# Contract: Phase 1-2 Quality Governance Artifacts

**Date**: 2026-05-08  
**Spec**: [../spec.md](../spec.md)  
**Plan**: [../plan.md](../plan.md)

## Purpose

This contract defines the user-facing artifact surfaces for the accepted Phase 1 baseline and the planned Phase 2 deferred-quality-gates slice. It is normative for artifact shape and discoverability and intentionally excludes Phase 3/4 behavior.

## Downstream Artifact Layout

```text
.specrew/
├── config.yml
├── presets/
│   └── *.md
├── lenses/
│   └── *.md
└── quality/
    └── known-traps.md                 # Phase 2

specs/<feature>/iterations/<NNN>/quality/
├── hardening-gate.md                 # Phase 2
├── quality-evidence.md               # Phase 1+
├── mechanical-findings.json          # Phase 1+
├── lenses/
│   └── *.md                          # Phase 2
└── trap-reapplication.md             # Phase 2
```

## `.specrew/config.yml` additions

The downstream config MUST expose a `quality` block:

```yaml
quality:
  presets_path: ".specrew/presets"
  lenses_path: ".specrew/lenses"
  findings_schema_version: "v1"
  evidence_directory_name: "quality"
  known_traps_path: ".specrew/quality/known-traps.md"
  routing:
    default_policy: "strongest-available"
    allow_lower_tier_override: true
    approval_required: true
```

Rules:

- Paths MUST be repo-relative.
- `findings_schema_version` MUST match `mechanical-findings.schema.json`.
- `known_traps_path` is required once Phase 2 is enabled.
- Routing defaults MUST be explicit; hidden implicit model preference is invalid.

## `.specrew/iteration-config.yml` additions

Agent metadata remains the availability source and MUST be extended so routing can be resolved explicitly:

```yaml
agents:
  <agent-id>:
    enabled: true|false
    access_path: "<path>"
    availability: available|unavailable
    strength_rank: <integer>
```

Rules:

- `strength_rank` is required for any agent that may satisfy a required hardening or lens review.
- Missing ranking means the agent cannot be selected by the `strongest-available` policy.

## Lens Checklist Contract

Each specialist lens Markdown artifact MUST contain:

1. title with lens ID and semantic version
2. purpose/scope
3. defect class covered
4. line-item table with acceptance criteria
5. row-level status vocabulary
6. upgrade guidance
7. change log

Phase 2 minimum supported families MUST cover:

- idempotency/retry safety
- concurrency/race-condition risk
- error handling/failure semantics
- security issues
- dependency/package health
- algorithmic complexity/performance-path traps

## Planning Artifact Contract

The feature `plan.md` generated for an active Phase 2 feature MUST expose:

- inherited Phase 1 baseline and green-governance prerequisite
- explicit Phase 2 boundary and deferred out-of-scope families
- hardening-gate concern areas
- lens activation matrix (`required` / `optional` / `not-applicable`)
- routing-policy baseline
- known-traps corpus location
- dependency-aware delivery slices

## Hardening Gate Contract

`hardening-gate.md` MUST include:

| Column / Field | Meaning |
| --- | --- |
| Concern | Reviewed hardening topic |
| Status | `addressed`, `not-applicable`, `tbd`, or `deferred-with-approval` |
| Blocking | Whether unresolved state blocks implementation |
| Rationale | Why the conclusion is valid |
| Approval | Human approval reference when required |

Rules:

- Any critical concern with `tbd` status blocks implementation.
- Deferred critical concerns require human approval.
- Requested and effective review class MUST be recorded.

## Lens Execution Contract

Each file under `quality/lenses/*.md` MUST include:

| Column / Field | Meaning |
| --- | --- |
| Lens Ref | Lens ID + version |
| Requested Class | Requested review/reasoning class |
| Effective Class | Effective class used |
| Override Ref | Lower-tier override evidence when applicable |
| Mechanical Prereq Ref | Required `mechanical-findings.json` reference |
| Checklist Rows | Row-level execution results |
| Overall Verdict | `passed`, `failed`, or `excepted` |

Rules:

- Required lens execution MUST walk the checklist row-by-row.
- Generic unstructured review is invalid.
- A lower-tier effective class requires explicit approval and justification.

## Known-Traps Contract

`.specrew/quality/known-traps.md` MUST include, per trap:

1. defect category
2. concrete example or snippet
3. detection method
4. remediation guidance
5. discovery date
6. source reference

Rules:

- The initial corpus MUST be seeded from existing Specrew findings rather than starting empty.
- New confirmed traps require explicit approved addition.

## Trap Reapplication Contract

`trap-reapplication.md` MUST record:

| Column | Meaning |
| --- | --- |
| Trap Ref | Trap(s) scanned for |
| Scan Scope | Files/surfaces checked |
| Result | `matches-found`, `none-found`, or `skipped-with-rationale` |
| Matches | Optional discovered locations |

## Non-Goals for This Contract

This contract does **not** define:

- Phase 3 quality-drift ledgers or baseline-diff workflows
- general gate/tool override workflows outside routing overrides
- Phase 4 reference-implementation companion storage or comparison surfaces

Those remain explicitly deferred.
