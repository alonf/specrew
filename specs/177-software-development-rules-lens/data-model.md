# Data Model: Code & Implementation Lens

**Feature**: 177-software-development-rules-lens
**Date**: 2026-06-10
**Purpose**: Define the entities, attributes, relationships, and validation rules for the
code-implementation lens. All entities are on-disk artifacts (no database).

## Entity: Rule (catalog entry)

**Purpose**: one implementation-craft rule in the canonical catalog `code-rules.yml`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `id` | string | yes | unique across the catalog; stable; kebab/dotted (e.g. `code-rule.object-invariants`); deprecate-not-delete | the join key used by the manifest, plan, and a future 156 adapter |
| `group` | enum | yes | one of `baseline-default` / `decision-prompt` / `applicability-filtered` / `enforcement-mode` | drives presentation (baseline summarized; decision-prompts surfaced; applicability-filtered context-gated) |
| `scope` | string | yes | `cross-language` or `language:<x>` or `framework:<y>` | combines common rules across stacks; gates per-stack rules |
| `applies` | bool/expr | yes | default true for baseline; an applicability predicate for filtered rules | whether the rule is presented for a given stack/context |
| `default` | string | yes | non-empty | the baseline statement/posture |
| `enforcement_mode` | string[] | no | informational only (no 145 gate) — e.g. `review`, `unit-tests`, `analyzer`, `formatter`, `compiler` | how the rule would be verified; surfaced to the agent for self-check |
| `title` | string | yes | short | human label in the checklist |

### Lifecycle / Relationships

Authored once in `code-rules.yml` (Specrew release); read by the lens (presentation) and the
`specrew-code-rules` skill (rule-text resolution by `id`). Changed only on a Specrew release. A
`ProjectOverlay` may add or per-rule-override a Rule but never silently drop a shipped Rule.

## Entity: RuleCatalog (`code-rules.yml`)

**Purpose**: the canonical set of Rules + per-stack defaults shipped with Specrew.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `schema_version` | string | yes | additive; mismatch is fail-open WARN | evolution marker |
| `rules` | Rule[] | yes | the 49 maintainer rules + per-stack defaults; unique ids | the catalog body |

### Lifecycle / Relationships

Single source of truth. Merged with an optional `ProjectOverlay` at read time (additive + per-rule
override). Volatile per-stack/version content lives here (isolated as data, lens rule 7).

## Entity: ProjectOverlay (`code-rules.local.yml`)

**Purpose**: project/company-level rules — the ingested coding guideline + reusable custom rules
(product-baseline tier).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `schema_version` | string | yes | additive; fail-open WARN | evolution marker |
| `added_rules` | Rule[] | no | unique ids; may carry provenance (`from_guideline`) | new rules not in the shipped catalog |
| `overrides` | object[] | no | reference an existing `id`; toggle/text override | per-rule overrides; never drops a shipped rule |

### Lifecycle / Relationships

Optional, per project. Written when a company guideline is ingested or a reusable custom rule is
promoted. Merged onto the `RuleCatalog` at read time. Inherited by every feature (forward-compatible
with Proposal 162's product-baseline tier).

## Entity: ImplementationRulesManifest (`implementation-rules.yml`)

**Purpose**: the per-feature selection + decisions — the artifact the guidance skill reads.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `schema_version` | string | yes | additive; fail-open WARN | evolution marker |
| `context_scope` | enum | yes | `feature_standalone` (V1) / `product_baseline` / `feature_delta` (162) | inheritance hook; V1 writes feature_standalone |
| `resolved_stack` | string | yes | the stack chosen at the lens turn | drives which slices apply |
| `selections` | object[] | yes | each references a catalog `id`; `checked` bool; optional `decision` + `enforcement` | reference-by-ID selected rules + per-rule decisions; unchecked baseline = recorded exception |
| `custom_rules` | Rule[] | no | unique ids; `provenance` (`free-text` / `pasted-doc` / `from-guideline` / `from-example-project`) | feature-scoped custom rules (incl. conventions inferred from an example project) |
| `dependency_policy` | DependencyPolicy | no | present when FR-013 triggered | the tooling/dependency selection |
| `provenance` | object | yes | confirmation provenance (mirrors lens confirmation) | how the selections were confirmed |

### Lifecycle / Relationships

Written once per feature by the workshop; read by the `specrew-code-rules` skill (+ plan.md) at
implement time. References catalog Rules by `id` (skill resolves text from the catalog). Validated
against `implementation-rules.schema.json`.

## Entity: DependencyPolicy (`dependency_policy` block, FR-013)

**Purpose**: the design-time tooling/dependency selection.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `stance` | enum | yes | default `use-existing-no-new-dependency` | the default-first stance |
| `selected` | object[] | no | one per chosen dependency | the new dependencies the human approved |

Each `selected` entry captures: `name`, `version`, `license`, `source_org`, `canonical_url`,
`maintenance_signal`, `security_advisory_status`, `compatibility`, `cost_or_quota` (if relevant),
`coupling_weight`, `replaceability`, `test_implications`.

### Lifecycle / Relationships

Captured at the lens turn when implementation may add/choose a dependency; persisted in the manifest;
surfaced by the guidance skill so the agent honors it (no silent adds). NOT auto-enriched — registry/CVE/
coupling automation is out of scope (097/122/178).

## Entity: LensRecord (in `lens-applicability.json`)

**Purpose**: the workshop record for the code-implementation lens (gate-relevant).

### Attributes

Standard workshop record fields: `agenda`, `decision`, `depth`, `moved_on`, `confirmation`,
`confirmation_scope` (per the SC-021/SC-026 floor).

### Lifecycle / Relationships

Written at intake; read by the specify gate. Unchanged contract (the lens participates in the existing
gate; the manifest itself is not gated).

## No persisted runtime state

All entities are design-time / install-time on-disk artifacts. No database, no session state, no
network calls. Fail-open is the rule everywhere: a missing/malformed artifact degrades to the baseline
(catalog defaults) with a surfaced WARN.
