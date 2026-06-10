# Contract: Code & Implementation Lens Public Surface

**Feature**: 177-software-development-rules-lens
**Stability**: pre-1.0 (forward-compatible with Proposals 156 / 162)

## Lens registration surface

| Symbol | Where | Purpose |
| --- | --- | --- |
| lens id `code-implementation` | `index.yml`, design-workshop lens map, `$lensIds` (conduct-driven; deliberately NOT in the deterministic `applicability-map.json` -- drift D-001, asserted by the unit test) | makes the lens discoverable + selectable; always-applicable-for-code-features (explicit skip for doc-only) |
| `code-implementation.md` | design-lens catalog | the lens knowledge: decision spine + per-stack dilemmas + run-cadence + conduct |

## Catalog contract (`code-rules.yml`)

- A list of rules, each `{ id, group, scope, applies, default, enforcement_mode?, title }`.
- **Invariants**: ids are unique + stable (deprecate-not-delete); the 49 maintainer rules + per-stack
  defaults are present; `group` and `scope` are from the closed vocabularies.
- **Overlay merge** (`code-rules.local.yml`): additive (`added_rules`) + per-rule `overrides`; **never
  silently drops a shipped rule**.

## Manifest contract (`implementation-rules.yml`)

- Schema: `contracts/implementation-rules.schema.json`.
- Reference-by-ID: `selections[]` reference catalog ids; the skill resolves rule text from the catalog.
- Carries `context_scope` (V1 `feature_standalone`), `resolved_stack`, `custom_rules[]`,
  `dependency_policy` (FR-013), and confirmation provenance.
- **Invariants**: every selection id exists in the merged catalog OR is a declared custom rule; stable ids
  are the future-156 join key; `schema_version` mismatch is fail-open WARN.

## Guidance skill contract (`specrew-code-rules`)

| Behavior | Guarantee |
| --- | --- |
| resolve active feature | reads the manifest at the known location (`specs/<feature>/implementation-rules.yml`) |
| compose | baseline (catalog `baseline-default`) + per-feature overlay (the manifest's selections/decisions/custom/dependency_policy) |
| surface | task-scoped (service/client/concurrency/API) — never a flat dump |
| no manifest | falls back to baseline-default rules (baseline mode) |
| unknown id / malformed | warn + skip / warn + use shipped (fail-open); never crashes |
| static | byte-identical across host skill dirs; changed only on a Specrew release |

## Invariants (whole feature)

- Rule **content** lives only in the catalog (one source of truth); the system prompt / Implementer
  charter carries only a pointer.
- The manifest is **advisory/guidance** — no review-time mechanical gate (no 145), no parallel
  code-quality engine.
- Everything fails open and surfaces a WARN; nothing silently skips the grounding.
- Multi-host parity: the lens md + the guidance skill deploy identically to every host via the existing
  engine.
