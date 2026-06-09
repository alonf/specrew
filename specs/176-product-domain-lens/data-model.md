# Data Model: Product & Problem Domain Lens

**Feature**: 176-product-domain-lens
**Date**: 2026-06-09
**Purpose**: Define the entities, attributes, and validation rules for the product-domain record. No
runtime/domain persistence — these are design-time artifacts written once per feature intake.

## Entity: ProductDomainRecord

**Purpose**: the per-feature product-domain capture, persisted in two forms — structured
(`product-domain.yml`) and human-readable (`product-domain.md`) under `specs/<feature>/workshop/`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `schema_version` | string | yes | semver-ish; mismatch → fail-open WARN | additive evolution marker |
| `depth` | enum | yes | `light` \| `standard` \| `deep` | selected capture depth |
| `depth_reason` | string | yes | non-empty, non-placeholder | why this depth (risk + novelty) |
| `context_scope` | enum | yes | `feature_standalone` \| `product_baseline` \| `feature_delta`; V1 writes `feature_standalone` | run-cadence mode (FR-014) |
| `product_id` | string | no | stable id when present | forward-compat hook for Proposal 162 inheritance |
| `product_context_ref` | string | no | reference to a product-level record when present | forward-compat hook for Proposal 162 |
| `areas` | object | yes | keys per captured decision area | per-area answers at the selected depth |
| `statements` | array<EvidenceStatement> | yes | non-empty for Standard/Deep | the material product-domain statements |
| `skipped` | array<SkippedArea> | no | each with a reason | areas deliberately not captured |
| `follow_up_research` | array<string> | no | — | research carried forward |
| `confirmation` | enum | yes | `human-confirmed` \| `human-delegated` \| `human-skipped` | SC-026 provenance (FR-010) |
| `confirmation_scope` | enum | yes | `lens-question` \| `explicit-delegation` \| `explicit-skip`; must match `confirmation` | SC-026 provenance scope |

### Lifecycle / Relationships

Created by the product-domain phase at feature intake (before the applicability questionnaire);
validated by the specify-gate floor; summarized into `spec.md` (FR-006); consumed later by Proposal
156 `workshop-decisions.yml` (forward-compatible shape; emission deferred). In `feature_delta` mode
(post-162) it references a `product_baseline` record via `product_id` / `product_context_ref` and
records only deltas.

## Entity: EvidenceStatement

**Purpose**: a single material product-domain statement with its evidence quality.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `text` | string | yes | non-empty | the statement |
| `area` | string | yes | one of the captured areas | which decision area it belongs to |
| `evidence` | enum | yes | `known` \| `assumed` \| `unknown` \| `research-needed` | evidence quality (FR-004) |
| `load_bearing` | bool | conditional | required when `evidence = research-needed` | drives FR-011 conditional plan-block |
| `divergence_reason` | string | conditional | required when the statement contradicts inherited context (post-162) | honest divergence record |

## Entity: DecisionArea (the `areas` object keys)

**Purpose**: the captured product-domain decision areas; depth governs which are required.

| Area key | Light | Standard | Deep | Description |
| --- | --- | --- | --- | --- |
| `users_stakeholders` | required | required | required | user / customer-buyer / operator / stakeholder, separated when they differ |
| `pain_job` | required | required | required | pain / job-to-be-done / current workaround |
| `mvp` | required | required | required | smallest valuable slice |
| `out_of_scope` | required | required | required | explicit non-goals |
| `constraints` | required | required | required | budget/schedule/tech/compliance/ops constraints |
| `existing_system` | — | required | required | new / extension / replacement / integration / migration |
| `outcomes` | — | required | required | measurable intended outcomes |
| `alternatives` | — | required | required | competitors / workarounds / build-vs-buy (Standard/Deep only — FR-003) |
| `adoption` | — | optional | required | pilot/rollout/migration/training |
| `stakeholder_map` | — | — | required | context diagram + stakeholder map |
| `business_model` | — | — | required | value/business model |

## Enumerations

- **Depth**: `light` \| `standard` \| `deep`.
- **EvidenceTag**: `known` \| `assumed` \| `unknown` \| `research-needed`.
- **ContextScope**: `feature_standalone` (V1) \| `product_baseline` (162) \| `feature_delta` (162).
- **Confirmation**: `human-confirmed` \| `human-delegated` \| `human-skipped`.
- **ConfirmationScope**: `lens-question` \| `explicit-delegation` \| `explicit-skip`.
