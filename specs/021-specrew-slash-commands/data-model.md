# Phase 1 Design: Data Model

**Feature**: 021-specrew-slash-commands  
**Branch**: `021-specrew-slash-commands`  
**Date**: 2026-05-18

## Overview

Feature 021 does not introduce a database or service-side schema. Its design model is an artifact contract for a session-facing command surface backed by PowerShell scripts and Squad-native skill deployment. The key entities are:

1. **Slash Command Catalog**
2. **Slash Command Definition**
3. **Slash Invocation Request**
4. **Compatibility Baseline**
5. **Namespace Policy**

## Entity Definitions

### Entity 1: Slash Command Catalog

**Purpose**: Represent the full user-facing `/specrew.*` v1 surface and its discovery/help contract.

| Attribute | Type | Description | Required | Constraints |
| --- | --- | --- | --- | --- |
| `catalog_id` | string | Stable identifier for the v1 catalog | ✓ | `specrew-slash-v1` |
| `version_policy` | string | Minimum compatible release rule | ✓ | Must state “first published release shipping Feature 021” |
| `commands` | list[SlashCommandDefinition] | Canonical commands in the catalog | ✓ | Exactly 7 entries in v1 |
| `alias_map` | map[string,string] | Alias-to-canonical mapping | ✓ | `/specrew.status -> /specrew.where` only in v1 |
| `discovery_policy` | object | Preferred and fallback discovery behavior | ✓ | Host-native `/specrew.` preferred; `/specrew.help` fallback required |
| `expansion_policy` | string | Rule for future additions | ✓ | Additive explicit entries only; no wildcard routing |
| `boundary_guard` | string | Statement of lifecycle-boundary behavior | ✓ | Must preserve Feature 016 review-stop discipline |

**Validation Rules**:

- The catalog must contain `/specrew.where`, `/specrew.status`, `/specrew.update`, `/specrew.team`, `/specrew.review`, `/specrew.help`, and `/specrew.version`.
- Only `/specrew.status` may be modeled as an alias in v1.
- Discovery policy must always name a fallback path.

### Entity 2: Slash Command Definition

**Purpose**: Describe one canonical slash command or alias and the contract it exposes.

| Attribute | Type | Description | Required | Constraints |
| --- | --- | --- | --- | --- |
| `canonical_name` | string | User-facing slash command | ✓ | Must use `/specrew.<command>` |
| `skill_directory` | string | Runtime skill folder name | ✓ | Must be namespaced `specrew-*` |
| `backend_route` | string | Underlying PowerShell route | ✓ | Must resolve to an existing dispatcher/script path or documented built-in behavior |
| `alias_of` | string/null | Canonical target when this command is an alias | ✗ | Null except for `/specrew.status` |
| `usage_shape` | string | Human-readable invocation form | ✓ | Must align with documented whitelist |
| `supported_args` | list[string] | Forwarded arguments accepted in v1 | ✓ | No undocumented passthrough |
| `help_summary` | string | Discovery/help text shown to users | ✓ | Concise and non-empty |
| `raw_output_policy` | enum | Output wrapping behavior | ✓ | `native-minimal-wrapper` for all routed commands |
| `failure_guidance` | string | Expected remediation guidance on failure | ✓ | Must be explicit and actionable |
| `boundary_behavior` | string | Lifecycle-boundary guard statement | ✓ | Must not imply approval to advance planning/implementation |

**Validation Rules**:

- `canonical_name` must remain stable once shipped.
- `backend_route` must preserve the current semantic intent of the underlying command.
- `supported_args` must be a whitelist, not a passthrough indicator.
- Alias definitions must not create a second independent behavior model.

### Entity 3: Slash Invocation Request

**Purpose**: Represent a user's attempt to run a Specrew slash command inside a session.

| Attribute | Type | Description | Required | Constraints |
| --- | --- | --- | --- | --- |
| `raw_input` | string | Original command text entered by the user | ✓ | Non-empty |
| `resolved_command` | string | Canonical slash command after alias normalization | ✓ | Must exist in catalog |
| `forwarded_args` | list[string] | Accepted args forwarded to backend | ✓ | Must be a subset of the command whitelist |
| `project_context` | object | Current project root, feature context, and host capability state | ✓ | Project root required for routed commands |
| `validation_result` | enum | Validation outcome | ✓ | `accepted`, `rejected-args`, `missing-setup`, `incompatible-version`, `unsupported-host` |
| `diagnostic_message` | string/null | User-facing failure or warning text | ✗ | Required when validation is not `accepted` |
| `dispatch_target` | string/null | Normalized backend invocation target | ✗ | Required when validation is `accepted` |

**Validation Rules**:

- Only `accepted` requests may produce a dispatch target.
- Rejected requests must emit explicit help/remediation guidance.
- Invocation handling must preserve raw/native backend output after validation succeeds.

### Entity 4: Compatibility Baseline

**Purpose**: Capture whether the current project/runtime is eligible for the slash-command surface.

| Attribute | Type | Description | Required | Constraints |
| --- | --- | --- | --- | --- |
| `installed_specrew_version` | string | Runtime/module version in use | ✓ | Semantic version |
| `project_baseline_version` | string | Version declared in `.specrew/config.yml` | ✓ | Semantic version |
| `minimum_slash_version_rule` | string | Policy for minimum slash-command support | ✓ | “First release shipping Feature 021” |
| `host_discovery_capability` | enum | Inline discovery capability status | ✓ | `native`, `degraded`, `unknown` |
| `execution_capability` | enum | Whether commands may still run | ✓ | `available`, `blocked` |
| `remediation_path` | string | Upgrade/setup guidance | ✓ | Must mention supported init/update path |

**Validation Rules**:

- A degraded discovery host may still be compatible if execution and `/specrew.help` work.
- A version mismatch must block execution only when the required baseline is missing.
- Remediation must never be blank when compatibility fails.

### Entity 5: Namespace Policy

**Purpose**: Define the coexistence rules between `/specrew.*` and `/speckit.*`.

| Attribute | Type | Description | Required | Constraints |
| --- | --- | --- | --- | --- |
| `namespace` | string | Protected namespace root | ✓ | `/specrew` |
| `coexists_with` | list[string] | Other namespaces intentionally preserved | ✓ | Must include `/speckit` |
| `collision_rule` | string | Behavior when a collision or ambiguity is detected | ✓ | Fail clearly; do not shadow or silently override |
| `approval_rule` | string | Human-boundary rule | ✓ | Specrew commands cannot imply lifecycle approval |
| `expansion_rule` | string | How future commands are added | ✓ | Explicit new catalog entries only |

**Validation Rules**:

- No rule may authorize silent takeover of another namespace.
- Coexistence rules must remain additive and human-review safe.

## Relationships

- One **Slash Command Catalog** contains many **Slash Command Definitions**.
- One **Slash Invocation Request** resolves to exactly one **Slash Command Definition** after alias normalization.
- Every **Slash Invocation Request** is evaluated against one **Compatibility Baseline**.
- The **Namespace Policy** governs every command in the **Slash Command Catalog**.

## State Transitions

### Slash Invocation Request

```text
received
  -> normalized
  -> validated
     -> dispatched
        -> completed
        -> failed
     -> rejected-args
     -> blocked-missing-setup
     -> blocked-incompatible-version
     -> degraded-discovery-fallback
```

### Slash Command Definition Lifecycle

```text
planned
  -> authored
  -> deployed
  -> discoverable
  -> validated
```

Rules:

- A command cannot become `discoverable` before it is `deployed`.
- A command cannot be treated as production-ready before it is `validated`.

## Design Notes

- This feature intentionally keeps the data model file-based and contract-oriented.
- Alias behavior is explicit and narrow: `/specrew.status` reuses `/specrew.where`.
- No unresolved data-model clarifications remain after Phase 1.
