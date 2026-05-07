# Data Model: Stack-Aware Quality Bar (Phase 1 / First Slice)

**Date**: 2026-05-07  
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)

## Entities

### Quality Governance Config

Extension-managed discovery metadata for downstream quality assets.

**Location**: `.specrew/config.yml`

| Field | Type | Description |
| --- | --- | --- |
| `quality.presets_path` | string | Relative path to scaffolded preset artifacts |
| `quality.lenses_path` | string | Relative path to scaffolded lens checklist artifacts |
| `quality.findings_schema_version` | string | Active schema version for mechanical findings JSON |
| `quality.evidence_directory_name` | string | Iteration-local directory name used for quality evidence artifacts |

**Validation**:

- All paths MUST be repo-relative and rooted under `.specrew/` or `specs/<feature>/iterations/<NNN>/`.
- `findings_schema_version` MUST match the schema declared in `contracts/mechanical-findings.schema.json`.

---

### Stack Preset

Versioned, named quality configuration for a recognized stack.

**Location**: `.specrew/presets/*.md`

| Field | Type | Description |
| --- | --- | --- |
| `preset_id` | string | Stable identifier, e.g. `node-public-ws-service` |
| `version` | semver string | Independent preset version |
| `stack_signals[]` | string[] | Repo/spec signals that justify selection |
| `toolchain[]` | string[] | Required mechanical or ecosystem tools |
| `required_lenses[]` | string[] | Lens checklist IDs + versions required by the preset |
| `mechanical_checks[]` | string[] | Required deterministic checks |
| `risk_dimensions[]` | string[] | Quality concerns activated by the preset |
| `worked_example` | markdown section | Required for `node-public-ws-service` in Phase 1 |
| `upgrade_guidance` | markdown section | How teams adopt a newer preset version |
| `change_log` | markdown table | Version-to-version delta history |

**Validation**:

- `version` MUST be semantic version text.
- `node-public-ws-service` MUST include a fully specified worked example.
- Every required lens reference MUST point to a versioned lens checklist artifact.

---

### Versioned Lens Checklist

Concrete line-item checklist for a bug-hunter or advisory quality lens.

**Location**: `.specrew/lenses/*.md`

| Field | Type | Description |
| --- | --- | --- |
| `lens_id` | string | Stable identifier, e.g. `security-baseline` |
| `version` | semver string | Checklist version |
| `purpose` | string | Defect class or concern covered |
| `line_items[]` | table rows | Concrete checks with acceptance criteria |
| `default_statuses[]` | enum[] | Allowed row states: `pass`, `fail`, `not-applicable`, `advisory` |
| `upgrade_guidance` | markdown section | How to review/apply added checks |
| `change_log` | markdown table | Version history |

**Validation**:

- Checklist content MUST remain Markdown-table based.
- Each line item MUST be execution-ready and reviewable without external hidden policy.

---

### Quality Profile

The active feature-level quality baseline inferred during planning.

**Location**: feature `plan.md`

| Field | Type | Description |
| --- | --- | --- |
| `profile_id` | string | Feature-local identifier for the inferred profile |
| `feature_ref` | path | Governing `spec.md` path |
| `stack_surfaces[]` | `Stack Surface`[] | Technology surfaces materially relevant to the feature |
| `preset_refs[]` | string[] | Versioned stack preset references selected for the feature |
| `custom_lens_refs[]` | string[] | Extra lens references used when no preset fully covers the shape |
| `risk_dimensions[]` | string[] | Required quality dimensions for this feature |
| `tool_bundle` | `Quality Tool Bundle` | Selected deterministic tools/evidence sources |
| `not_applicable_dimensions[]` | string[] | Dimensions explicitly omitted with rationale |
| `phase_scope` | string | Must read `phase-1-first-slice` |

**Validation**:

- Profile MUST cite either one or more preset refs or an explicit custom-composition rationale.
- `phase_scope` MUST prevent later-phase behavior from being implied as implemented.

---

### Stack Surface

Materially distinct technology boundary within the feature.

| Field | Type | Description |
| --- | --- | --- |
| `surface_id` | string | Stable feature-local identifier |
| `path_globs[]` | string[] | File/system boundaries for the surface |
| `language` | string | Dominant implementation language or artifact type |
| `runtime_shape` | string | Service, SPA, worker, script surface, etc. |
| `recognized_stack` | string | Preset-matching stack name or `custom` |

**Validation**:

- Surface boundaries MUST be explicit enough to support future mixed-stack handling even if Phase 1 uses one dominant surface.

---

### Quality Tool Bundle

Selected deterministic tools and evidence paths used to satisfy the active profile.

| Field | Type | Description |
| --- | --- | --- |
| `bundle_id` | string | Stable identifier for the resolved bundle |
| `mechanical_checks[]` | `Quality Gate`[] | Required Phase 1 deterministic gates |
| `ecosystem_tools[]` | string[] | Stack-specific lint/static/test commands or evidence sources |
| `manual_evidence[]` | string[] | Human-reviewed evidence paths used where tooling is not yet automated |

**Validation**:

- Mechanical checks MUST be first-class entries, not implied notes.
- Every listed gate MUST map to an evidence source or approved exception path.

---

### Quality Gate

Reviewable expectation that must be satisfied or explicitly excepted.

| Field | Type | Description |
| --- | --- | --- |
| `gate_id` | string | Stable gate key |
| `category` | enum | `mechanical`, `tooling`, `manual-evidence` |
| `requirement_refs[]` | string[] | Governing FRs |
| `status` | enum | `planned`, `passed`, `failed`, `excepted`, `not-applicable` |
| `evidence_ref` | path/string | Evidence artifact or command result |
| `exception_ref` | path/string? | Approved exception or demotion record |

**State transitions**:

```text
planned -> passed
planned -> failed
planned -> excepted
planned -> not-applicable
failed -> passed
failed -> excepted
```

---

### Mechanical Check Finding

Structured, actionable finding emitted by a deterministic check.

**Location**: `specs/<feature>/iterations/<NNN>/quality/mechanical-findings.json`

| Field | Type | Description |
| --- | --- | --- |
| `finding_id` | string | Stable within a run |
| `gate_id` | string | Triggering quality gate |
| `rule_id` | string | Specific deterministic rule |
| `surface_id` | string | Stack surface where the issue was found |
| `severity` | enum | `error`, `warning`, `info` |
| `message` | string | Human-readable summary |
| `remediation` | string | Actionable fix guidance |
| `source.path` | string | Relative file path |
| `source.line` | integer | 1-based line number |
| `source.column` | integer? | Optional column |
| `requirement_refs[]` | string[] | Traceability to FRs |
| `demoted` | boolean | Whether the rule was demoted from blocking behavior |

**Validation**:

- Every finding MUST include source location, severity, and remediation guidance.
- `demoted = true` requires an associated `Mechanical Rule Disposition Record`.

---

### Quality Evidence Record

Human-reviewable matrix of planned gates, findings, and exceptions.

**Location**: `specs/<feature>/iterations/<NNN>/quality/quality-evidence.md`

| Field | Type | Description |
| --- | --- | --- |
| `profile_ref` | string | Linked `Quality Profile` |
| `preset_refs[]` | string[] | Versioned preset references used |
| `gate_rows[]` | table rows | Gate, requirement refs, expected evidence, observed status, exception |
| `findings_ref` | path | JSON findings payload path |
| `reviewed_by` | string | Reviewer or role |
| `reviewed_at` | ISO datetime | Review timestamp |

**Validation**:

- Every required gate from the plan MUST appear in the matrix.
- Missing evidence is only valid when `exception_ref` is populated and approved.

---

### Mechanical Rule Disposition Record

Reviewed record for rule demotion when a mechanical check becomes too noisy.

| Field | Type | Description |
| --- | --- | --- |
| `disposition_id` | string | Stable identifier |
| `rule_id` | string | Rule being changed |
| `old_behavior` | enum | `blocking`, `warning` |
| `new_behavior` | enum | `advisory`, `warning` |
| `scope` | enum | `global`, `preset`, `project` |
| `rationale` | string | Why the rule was demoted |
| `approved_by` | string | Human approver |
| `approved_at` | ISO datetime | Approval timestamp |
| `change_log_ref` | path | Preset/lens/change-log entry path |

**Validation**:

- Demotions MUST never silently remove the rule; they only change how it is surfaced.

## Relationships

- `Quality Governance Config` discovers `Stack Preset` and `Versioned Lens Checklist` artifacts.
- `Quality Profile` references one or more `Stack Surface`, `Stack Preset`, and `Versioned Lens Checklist` records.
- `Quality Tool Bundle` contains `Quality Gate` records.
- `Mechanical Check Finding` rows satisfy or fail `Quality Gate` entries.
- `Quality Evidence Record` summarizes gate outcomes and points at `Mechanical Check Finding` payloads.
- `Mechanical Rule Disposition Record` can change the effective severity/blocking behavior of a rule but must remain traceable from both findings and change logs.
