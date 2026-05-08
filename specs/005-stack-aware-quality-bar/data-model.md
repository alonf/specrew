# Data Model: Stack-Aware Quality Bar (Phase 2 / Deferred Quality Gates)

**Date**: 2026-05-08  
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)

## Entities

### Quality Profile

The active feature-level quality baseline inferred during planning.

**Location**: feature `plan.md`

| Field | Type | Description |
| --- | --- | --- |
| `profile_id` | string | Feature-local identifier for the inferred profile |
| `phase_scope` | string | For this slice, `phase-2-hardening-bug-hunter-known-traps` |
| `preset_refs[]` | string[] | Versioned preset references, if any |
| `custom_lens_refs[]` | string[] | Lens references used for bounded custom composition |
| `risk_dimensions[]` | string[] | Quality concerns materially active for the feature |
| `required_quality_gates[]` | `Quality Gate`[] | Declared prerequisite gates |

**Validation**:

- Phase 2 planning MUST inherit the accepted Phase 1 baseline rather than redefining it silently.
- The profile MUST keep out-of-scope Phase 3/4 behavior explicitly deferred.

---

### Hardening Gate Review

Pre-implementation review packet covering silent-omission risk before coding begins.

**Location**: `specs/<feature>/iterations/<NNN>/quality/hardening-gate.md`

| Field | Type | Description |
| --- | --- | --- |
| `gate_id` | string | Stable identifier, e.g. `pre-implementation-hardening` |
| `feature_ref` | path | Governing feature path |
| `iteration_ref` | string | Active iteration identifier |
| `requested_review_class` | string | Requested reasoning/review tier (`strongest-available` by default) |
| `effective_review_class` | string | Actual tier used for the hardening review |
| `concern_rows[]` | `Hardening Concern`[] | Security, error handling, retry/idempotency, test integrity, operational concerns |
| `overall_verdict` | enum | `ready`, `blocked`, `deferred-with-approval` |
| `approval_ref` | string? | Required when critical concerns are deferred rather than resolved |
| `reviewed_by` | string | Reviewer or role |
| `reviewed_at` | ISO datetime | Review timestamp |

**Validation**:

- Any critical concern with `status = tbd` forces `overall_verdict = blocked`.
- `deferred-with-approval` requires explicit human approval evidence.

---

### Hardening Concern

One explicitly reviewed readiness concern inside the hardening gate.

| Field | Type | Description |
| --- | --- | --- |
| `concern_id` | string | Stable key such as `security-surface` |
| `category` | enum | `security`, `error-handling`, `retry-idempotency`, `test-integrity`, `operational` |
| `status` | enum | `addressed`, `not-applicable`, `tbd`, `deferred-with-approval` |
| `rationale` | string | Required when not applicable, deferred, or addressed with non-obvious reasoning |
| `blocking` | boolean | Whether unresolved state blocks implementation |
| `approval_ref` | string? | Human approval reference for any deferred critical concern |

---

### Bug-Hunter Lens Definition

Versioned specialist checklist artifact for a focused defect class.

**Location**: `.specrew/lenses/*.md`

| Field | Type | Description |
| --- | --- | --- |
| `lens_id` | string | Stable identifier, e.g. `security-issues` |
| `version` | semver string | Checklist version |
| `defect_class` | string | Risk class covered by the lens |
| `checklist_rows[]` | table rows | Reviewable line items |
| `default_statuses[]` | enum[] | Allowed row states: `pass`, `fail`, `not-applicable`, `advisory` |
| `upgrade_guidance` | markdown section | Adoption guidance for newer versions |
| `change_log` | markdown table | Version history |

**Validation**:

- Phase 2 MUST publish the minimum lens families required by FR-017.
- Lens definitions remain versioned independently from presets.

---

### Lens Activation Plan

Planning-time classification of specialist lenses for the active feature.

**Location**: feature `plan.md`

| Field | Type | Description |
| --- | --- | --- |
| `lens_id` | string | Referenced lens |
| `status` | enum | `required`, `optional`, `not-applicable` |
| `rationale` | string | Why the lens was activated or omitted |
| `evidence_path` | path | Where execution evidence will appear if activated |
| `requested_review_class` | string | Default requested routing tier |

**Validation**:

- Every materially relevant lens must be classified explicitly.
- `required` lenses must point to an execution evidence surface.

---

### Lens Execution Record

Reviewable execution artifact for one activated specialist lens.

**Location**: `specs/<feature>/iterations/<NNN>/quality/lenses/<lens-id>.md`

| Field | Type | Description |
| --- | --- | --- |
| `lens_id` | string | Executed lens |
| `lens_version` | semver string | Version used |
| `requested_review_class` | string | Tier requested by policy |
| `effective_review_class` | string | Tier actually used |
| `override_ref` | string? | Required if the effective class is lower-tier by override |
| `mechanical_prereq_ref` | path | Prior `mechanical-findings.json` evidence |
| `rows[]` | `Lens Checklist Row Result`[] | Line-by-line execution results |
| `overall_verdict` | enum | `passed`, `failed`, `excepted` |

**Validation**:

- Required lens execution MUST not begin without a mechanical prerequisite reference.
- Generic unstructured review is invalid; row-level execution is mandatory.

---

### Lens Checklist Row Result

Outcome for one checklist line item within a lens execution.

| Field | Type | Description |
| --- | --- | --- |
| `row_id` | string | Stable within the lens |
| `status` | enum | `pass`, `fail`, `not-applicable`, `advisory` |
| `finding` | string? | Focused issue description |
| `evidence_ref` | path/string? | Supporting artifact, command, or rationale |
| `exception_ref` | string? | Required when the row is justified as excepted/not-applicable in a way that needs approval |

---

### Routing Policy

Explicit policy for selecting the strongest available review path.

**Location**: `.specrew/config.yml` and `.specrew/iteration-config.yml`

| Field | Type | Description |
| --- | --- | --- |
| `default_policy` | enum | `strongest-available` |
| `reasoning_classes[]` | object[] | Available classes/access paths with strength metadata |
| `allow_lower_tier_override` | boolean | Whether FR-039 overrides are permitted |
| `approval_required` | boolean | Must be true for lower-tier overrides |

**Validation**:

- The routing policy MUST be explicit and configurable.
- Available classes and effective routing must remain reviewable after execution.

---

### Routing Override Record

Approved exception allowing a lower-tier review class for a specific lens.

| Field | Type | Description |
| --- | --- | --- |
| `override_id` | string | Stable identifier |
| `lens_id` | string | Affected lens |
| `requested_class` | string | Stronger default class |
| `effective_class` | string | Lower-tier class approved for use |
| `justification` | string | Why the override is needed |
| `approved_by` | string | Human approver |
| `approved_at` | ISO datetime | Approval timestamp |

**Validation**:

- Overrides are Phase 2-scoped only for routing behavior, not general gate/tool overrides.

---

### Known Trap Entry

Persistent project-wide record of a confirmed defect pattern.

**Location**: `.specrew/quality/known-traps.md`

| Field | Type | Description |
| --- | --- | --- |
| `trap_id` | string | Stable identifier |
| `category` | string | Defect category |
| `example` | markdown/code block | Concrete example or snippet |
| `detection_method` | string | How the defect can be found |
| `remediation_guidance` | string | How to fix or avoid it |
| `discovery_date` | date | When it was confirmed |
| `source_ref` | path/string | Originating review or iteration evidence |

**Validation**:

- The initial corpus must be seeded; it cannot begin empty for this feature.

---

### Trap Reapplication Scan

Iteration-local record of scanning existing code for a known trap pattern.

**Location**: `specs/<feature>/iterations/<NNN>/quality/trap-reapplication.md`

| Field | Type | Description |
| --- | --- | --- |
| `scan_id` | string | Stable identifier |
| `trap_refs[]` | string[] | Traps re-applied in the scan |
| `scope` | string | Files or surfaces scanned |
| `result` | enum | `matches-found`, `none-found`, `skipped-with-rationale` |
| `matches[]` | string[] | Optional references to discovered matches |
| `recorded_at` | ISO datetime | When the scan result was recorded |

## Relationships

- `Quality Profile` declares the Phase 2 scope and required quality gates.
- `Hardening Gate Review` must exist before implementation readiness is accepted.
- `Lens Activation Plan` determines which `Bug-Hunter Lens Definition` records become required execution.
- `Lens Execution Record` depends on `mechanical-findings.json` and the active `Routing Policy`.
- `Routing Override Record` may change the effective review class for a lens but must remain explicit and approved.
- `Known Trap Entry` records confirmed project memory and may be sourced from `Lens Execution Record` findings.
- `Trap Reapplication Scan` reuses one or more `Known Trap Entry` definitions against current code.
