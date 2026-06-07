# Data Model: Specrew Refocus

**Feature**: 171-specrew-refocus
**Date**: 2026-06-06
**Purpose**: Define the entities, attributes, validation rules, and lifecycles for the refocus content, configuration, and runtime state. No persisted domain/business data — all entities are methodology content (versioned), configuration (versioned), or ephemeral runtime state (gitignored).

## Entity: RefocusDigest

**Purpose**: one purpose-authored injection unit (the always-true core or one lifecycle stage's discipline).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| scope | string | yes | `general` or a canonical stage name | which scope this digest serves |
| sources | string[] | yes | repo-relative paths; must exist at deploy | canonical files this digest digests |
| reviewed_at | date | yes | ISO date | last human review of digest-vs-sources currency |
| body | markdown | yes | token estimate ≤ cap (general ~600; stage ~1,500) | the injectable content; ends with file:/// pointers |

### Lifecycle / Relationships

Authored in `extensions/specrew-speckit/refocus/`; deployed as managed mirror; read at event time by RefocusEngine via ScopeCatalog mapping; currency watched by DigestDriftCheck (warn when any `sources[]` member changed after `reviewed_at`).

## Entity: ScopeCatalog (refocus-scopes.json)

**Purpose**: the single data-driven map from scopes/triggers to digests/budgets, and home of the provider registry.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| schema_version | string | yes | known version; mismatch → fail-open WARN | additive-only evolution |
| scopes | map | yes | digest paths repo-relative | scope id → digest file list |
| triggers | map | yes | trigger id ∈ {b1,b2,b3}; scopes exist; `enabled` bool | trigger → scope list + budget + enabled flag |
| budgets | map | yes | positive ints | per-trigger token caps |
| providers | row[] | yes | see ProviderRegistryRow | ordered provider registry |

### Lifecycle / Relationships

Canonical in `extensions/specrew-speckit/`; deployed **managed-with-overlay** (canonical keys refresh on update; user keys — `enabled:` flags, added providers — preserved). Read by engine + dispatcher; schema-checked at deploy and at read (fail-open).

## Entity: ProviderRegistryRow

**Purpose**: one mechanism's seat on the hook dispatcher (refocus is row #1; future: 130-P4 handover).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| id | string | yes | unique | provider id |
| kind | enum | yes | `inject` (default) \| `gate` | inject returns a markdown fragment; gate runs on PreToolUse, receives tool_input, returns allow/deny `permissionDecision`; gates FAIL OPEN to allow + WARN |
| events | string[] | yes | known host-neutral event names | which dispatcher events invoke it |
| order | int | yes | unique within event | deterministic execution order |
| budget_share | number | inject only | 0..1; shares ≤ 1 per event | token arbitration (n/a for gates) |
| command | string | yes | resolves under the deployed tree (deploy-time validation) | what the dispatcher runs |

**Forward-compat note (2026-06-07)**: no `gate` provider ships in F-171; the PreToolUse registration stays dormant (deploy-loop data) until the first gate row exists — reserving F-165's seat without paying a per-tool-call spawn for an empty seat.

## Entity: RuntimeSessionState (refocus-state-<session-id>.json)

**Purpose**: per-session dedupe, breaker, and journal truth; the only mutable state in the feature.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| session_id | string | yes | sanitized [a-zA-Z0-9-] (filename-safe) | host-provided session identity |
| last_seen_boundary | string | no | canonical boundary name | B3 state-diff anchor |
| fingerprints | string[] | no | bounded | injected-payload fingerprints (dedupe) |
| breaker | object | no | {tripped, reason, at, scope} | trip record; session-scoped |
| journal | JournalEntry[] | no | ring, max ~20 | post-hoc evidence |

### Lifecycle / Relationships

Created on first trigger event in a session under `.specrew/runtime/` (gitignored); pruned opportunistically (~7 days) at dispatcher startup / `specrew update`; unreadable/corrupt state ⇒ STATE_UNAVAILABLE trip (no automatic injection; manual + channel 1 unaffected).

## Entity: JournalEntry

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| at | datetime | yes | UTC | when |
| trigger | string | yes | manual \| b1 \| b2 \| b3 \| channel1 | what fired |
| scope | string | yes | catalog scope id | what was loaded |
| channel | string | yes | slash \| hook \| stdout | delivery path |
| tokens | int | yes | ≥0 | estimated payload size |
| outcome | enum | yes | injected \| deduped \| budget-clipped \| breaker-suppressed \| failed | what actually happened |

## Entity: HostHookBindingDeclaration

**Purpose**: per-host package data declaring which triggers that host binds and how (the contract realization).

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| host | string | yes | known host kind | claude / antigravity / cursor / codex |
| bound_triggers | string[] | yes | ⊆ {b1,b2,b3} | what this host's surface expresses |
| event_map | map | yes | research-matrix verified | host event → neutral event |
| settings_target | string | yes | per-user project-local file | where registration deploys (C6) |
| research_ref | string | yes | research-matrix section | the verification evidence |
