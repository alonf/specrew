# Data Model: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Date**: 2026-06-11
**Purpose**: Define the entities, attributes, validation rules, and relationships for the
work-kind taxonomy, the per-work-item declaration, the project-level governance capture, the
release-validation record, and the provider capability/adapter model.

**Note on persistence**: there is no database. All entities are file-backed YAML/JSON (a shipped
catalog, project-level config, and per-work-item declarations). Schemas validate them; the runtime
is fail-open + WARN on anything unknown/malformed.

## Entity: WorkKind (catalog entry)

**Purpose**: Define a work kind, its lifecycle weight, required evidence, and allowed changed-file
scope. Lives in the shipped `work-kinds.yml` catalog (one source of truth).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `id` | enum | yes | one of `software-feature`,`bug-bash`,`docs-only`,`devops`; stable, deprecate-not-delete | the work-kind identifier |
| `lifecycle_weight` | enum | yes | `full`,`focused`,`lightweight`,`operational` | how heavy the lifecycle is |
| `required_evidence` | string[] | yes | non-empty; named artifacts | evidence the kind must produce to close out |
| `allowed_scope` | glob[] | yes | glob patterns | changed-file globs this kind may touch |
| `branch_prefix_hint` | string | no | e.g. `docs/`,`devops/`,`fix/`,`feature/` | optional default-inference prefix |

### Lifecycle / Relationships

Shipped with Specrew; read by the lens, the lifecycle templates, the validator, and the docs.
Referenced by `WorkKindDeclaration.work_kind`. An allow-list (repository-global/generated files)
sits alongside `allowed_scope` so global ledgers/mirrors never produce false mismatches.

## Entity: WorkKindDeclaration

**Purpose**: How a given work item / PR declares its kind. The authoritative, forge-neutral,
checked-in `.specrew/work-kind.yml`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `work_kind` | enum | yes | must exist in the catalog | the declared kind |
| `schema_version` | string | yes | semver | for forward-compat |
| `notes` | string | no | free text | optional metadata |

### Lifecycle / Relationships

Created per work item (per feature branch / work-item branch). The validator reads it; an optional
branch-prefix convention supplies a default the file confirms/overrides. On GitHub an opt-in label
mirror may exist but is never authoritative. Missing file → infer from branch prefix if configured,
else advisory WARN.

## Entity: RepositoryGovernance

**Purpose**: The project-level governance decision captured by the DevOps lens. Lives in
`.specrew/repository-governance.yml` (decided once, inherited per feature, deltas re-asked).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `provider` | string | yes | e.g. `github`, or a synthesized adapter id | the forge |
| `branch_model.style` | enum | yes | `trunk`,`integration-branch`,`gitflow`,`custom` | branching method |
| `branch_model.release_truth_branch` | string | yes | user-named (`main`/`master`/`trunk`/…) | the protected release branch |
| `branch_model.branches[]` | object[] | yes | each: `name`,`role`,`protected`,`require_pull_request`,`required_checks[]`,`merges_from[]`,`allow_force_pushes`,`allow_deletions` | per-branch policy + promotion path |
| `branch_model.promotion_path` | string | no | derived from `merges_from` | human-readable |
| `review_gate.human_review.required_approvals` | int | yes | ≥0 (0 = no human gate) | reviewer count |
| `review_gate.human_review.require_comment_resolution` | bool | yes | — | unresolved comments block merge |
| `review_gate.automated_review.enabled` | bool | yes | default `false` (opt-in) | automated reviewer on/off |
| `review_gate.automated_review.provider_suggestion` | string | no | e.g. `copilot` (GitHub only) | suggested bot |
| `review_gate.merge_requires` | string[] | yes | subset of review signals | what gates merge |
| `apply_to_admins` | bool | yes | default `true` | protection applies to admins |
| `bypass_actors[]` | string[] | yes | default `[]` | explicit automation bypass list |
| `enforcement_mode` | enum | yes | `branch-protection`,`rulesets`,`ci-only`,`manual` | the achievable mechanism |

### Lifecycle / Relationships

Authored at the DevOps lens (brownfield: detect existing posture + adapt-or-change). Read by the
validator (`branch_model` resolves closeout-target vs promotion semantics) and the capability
detector. Embeds `MultiRepoModel` when multi-repo.

## Entity: MultiRepoModel

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `mode` | enum | yes | `single-repo` (default), `multi-repo` | orchestration mode |
| `orchestration_repo` | string | no | required when multi-repo | owns lifecycle truth |
| `participant_repos[]` | string[] | no | — | implementation repos |
| `merge_coordination` | enum | no | `independent`,`release-train`,`manual` | merge coordination |
| `release_coordination` | enum | no | `independent`,`release-train`,`manual` | release coordination |

## Entity: ReleaseValidationRecord

**Purpose**: A post-merge validation record (beta/stable/CI learning) **separate** from
feature-closeout. References the merged feature without reopening it.

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `merged_feature_ref` | string | yes | existing merged feature | what was validated |
| `merged_commit` | string | yes | commit hash | the merge commit |
| `findings[]` | object[] | no | each → a new work item ref | post-merge learning |
| `new_work_items[]` | string[] | no | docs-only/devops/bug-bash refs | follow-ups created (never a reopen) |

## Entity: ProviderCapability

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `provider` | string | yes | — | forge id |
| `plan` | string | no | — | plan/tier |
| `visibility` | enum | no | `public`,`private`,`internal` | repo visibility |
| `mechanism` | enum | yes | `branch-protection`,`rulesets`,`ci-only`,`manual` | achievable enforcement |
| `constraints[]` | string[] | no | — | honest caveats |

## Entity: ProviderAdapter (behavioral contract, not stored)

Operations: `detect_capability(ctx) → ProviderCapability`; `describe_protection(governance) → plan`
(read-only); `apply_protection(governance) → result` (guarded, human-approved; synthesized adapters
omit/stub); `read_pr_context() → {changed_files[],target_branch,source_branch,merge_state}` (with a
git-diff fallback). Implementations: `github` (reference), `generic/unknown` (fallback), `synthesized`
(on the fly, read-only by default). See contracts/work-kind-governance.md.
