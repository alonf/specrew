# Data Model: 0.40.0-beta2 Hardening Bundle

**Feature**: 198-beta2-hardening
**Date**: 2026-07-10
**Purpose**: Define the entities, attributes, validation rules, and
relationships for the bundle's data seams. No database is introduced; all
entities are versioned files or structured records in existing stores.

## Entity: DenyListEntry (SelfLeakDenyList)

**Purpose**: one self-fact pattern the firewall prevents from shipping.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| pattern | string (regex) | yes | compiles as .NET regex | the self-fact matcher |
| class | enum | yes | release-model \| dev-path \| feature-id \| maintainer-id \| registry \| repo-ref \| decision-ref | leak taxonomy |
| reason | string | yes | non-empty | why this is a self-fact |
| source | string | yes | non-empty | field report / proposal ref that added it |
| added | date | yes | ISO date | when the term joined the list |

File-level: `schema_version` (string, required). Consumer-side version
mismatch = fail-open WARN; repo-side is version-locked (I3). Annotation
escape: `specrew-self-ok: <reason>` — HTML comment for `.md`, `#` line
comment for `.ps1`/`.psd1`/`.yml`; same line or the line immediately above
the hit; an escape without reason text is treated as unannotated.

### Lifecycle / Relationships

Created in iteration 001 with the proposal-205 seed; grows one entry per
field-found leak (W6 makes that a one-line fix). Read by SelfLeakLintLane
(repo CI), and in iteration 004 by the gateway advisory, the update heal
surface, and PromptFixtureTest — always the same shipped file.

## Entity: MachineryPathEntry (MachineryPathList) — iteration 003

**Purpose**: one path-granular glob machinery-stripped from BOTH the digest
and the reviewer worktree (S2).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| glob | string | yes | non-empty path glob | e.g. `.claude/**`, `.github/prompts/**` |
| side | const | yes | always `both` | one list, both strips — divergence impossible by construction |
| reason | string | yes | non-empty | why this is machinery |

### Lifecycle / Relationships

Consumed by DigestIdentity and WorktreeMaterializer. Every change ships a
reviewer-can-still-see-it regression test (FR-012).

## Entity: ReviewerHostCatalogRow (extended) — iteration 002

**Purpose**: per-host harness data; the ONLY harness-data seam.

### Attributes (added)

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| default_timeout_seconds | int | no | > 0 when present | per-host review budget; absent → 600 floor (tolerant reader) |

Shipped values (clarify 2026-07-09): antigravity 900, claude 600; codex +
copilot rows added from consumer-test-project measurements during
iteration 002.

## Entity: ReleaseModelRecord — iteration 004

**Purpose**: the project's release model, recorded once at init, resolved
at feature-closeout (FR-030).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| release_model | enum | yes | local-only \| push-only \| pr-flow \| beta-stable | drives closeout teaching |
| provenance | enum | yes | recorded \| inferred | ask-once at init, infer as default |

Lives in `.specrew/repository-governance.yml`. Inference: no remote →
local-only; remote without forge config → push-only; forge → pr-flow;
publish target → beta-stable.

## Entity: BoundaryVerdictRecord (extended) — iteration 002

**Purpose**: the authorization truth for one boundary crossing (#2906).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| boundary | enum | yes | canonical boundary names | the crossing |
| auth_commit_hash | string | yes | git short/long hash | the anchor reversion targets |
| kind | enum | yes | standard \| retroactive | retroactive approvals are recorded distinctly (FR-005) |

`last_authorized_boundary` + `verdict_history` in
`.specrew/start-context.json` stay the single cursor truth.

## Entity: TrackerClaims (parsed, transient) — iteration 002

**Purpose**: the deterministic parse of `state.md` + `tasks-progress.yml`
the honesty check compares against the accepted review record (FR-020).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| task_statuses | map | yes | canonical enums only (planned/in-progress/done/needs-rework/deferred/blocked) | per-task claim |
| capacity | string | no | `<consumed>/<cap> <unit>` shape | capacity-line claim |
| test_counts | ints | no | non-negative | claimed totals |

Parse failure of any claim → fail-closed (digest stales as today). A
claims comparison is subset-only: any claim increasing beyond the accepted
review verdict + run records → stale.

## Entity: ContainmentRecord — iteration 003

**Purpose**: origin-side durable evidence of an observed reviewer escape
(FR-011).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| run_id | string | yes | existing run-id scheme | correlation key |
| process / command_line / path | strings | yes | non-empty | what was observed |
| observed_at | timestamp | yes | ISO | when |

Never enters reviewer-visible artifacts (W2-consistent).

## Entity: RunRecord (extended) — iterations 002/003

**Purpose**: existing durable review run evidence under
`.specrew/review/**`, gaining: `independence_source`
(flag \| env \| unverified, FR-023), frozen fire-time tree id +
stale-vs-current label (FR-017), last-reviewed checkpoint identity
(FR-016), and machine-observed test evidence via the recorded-run wrapper
(FR-015; caller-supplied numbers rejected or labeled
implementer-recorded).
