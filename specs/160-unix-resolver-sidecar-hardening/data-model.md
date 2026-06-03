# Data Model: Unix Resolver Sidecar Hardening Investigations

**Feature**: `160-unix-resolver-sidecar-hardening`
**Date**: 2026-06-03
**Purpose**: Define transient investigation evidence entities for resolver path
and managed-refresh marker behavior.

## No Persisted Product Data

This feature does not add product storage, database schema, or user-facing data
models. It creates temporary test fixtures and governed evidence artifacts.

## Entity: ResolverPathProbe

**Purpose**: Captures one resolver path construction scenario and its observed
platform behavior.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `case_id` | string | yes | Unique within the test file | Stable identifier for the probe case |
| `platform` | string | yes | `windows`, `unix`, `macos`, or `deterministic-fixture` | Platform or fixture surface under test |
| `path_expression` | string | yes | Non-empty | Path construction shape being tested |
| `expected_target` | string | yes | Absolute or fixture-normalized path | Intended nested target path |
| `actual_target` | string | yes | Absolute or fixture-normalized path | Observed path produced or checked |
| `disposition` | string | yes | `confirmed`, `not-confirmed`, or `environment-blocked` | Finding result for the probe |

### Lifecycle / Relationships

A `ResolverPathProbe` is created by the resolver path test, compared against
expected separator behavior, and summarized into one `InvestigationFinding`.
Probe data is not persisted outside test output and review/quality evidence.

## Entity: ManagedRefreshFixtureCase

**Purpose**: Models a runtime deployment file and marker state across one
refresh attempt.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `case_id` | string | yes | Unique within the test file | Stable fixture case identifier |
| `host_surface` | string | yes | One of `copilot`, `claude`, `codex`, `cursor`, `antigravity`, `squad-deploy` | Deployment surface under test |
| `target_path_shape` | string | yes | Relative path only | Host-native file shape under the scratch project |
| `marker_state` | string | yes | `missing`, `sidecar`, or `inline` | Managed marker state before refresh |
| `canonical_changed` | boolean | yes | true or false | Whether canonical source content changed |
| `user_edit_present` | boolean | yes | true or false | Whether target content represents user edits |
| `expected_action` | string | yes | `written`, `preserved`, `updated`, or matching dry-run action | Expected refresh outcome |
| `actual_action` | string | yes | Must match emitted action vocabulary | Observed refresh outcome |

### Lifecycle / Relationships

A `ManagedRefreshFixtureCase` is created in a scratch project, run through direct
deploy logic, and removed after the test. It relates to an `InvestigationFinding`
for managed-refresh marker behavior.

## Entity: InvestigationFinding

**Purpose**: Records the final disposition for one suspected issue.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `finding_id` | string | yes | `resolver-path` or `managed-refresh-sidecar` | Suspected issue identifier |
| `evidence_source` | string | yes | File path, command, or manual evidence note | Where the proof came from |
| `disposition` | string | yes | `confirmed`, `not-confirmed`, or `environment-blocked` | Final finding state |
| `changed_files` | string[] | yes | Empty unless confirmed behavior changed | Files changed for a confirmed fix |
| `rationale` | string | yes | Non-empty | Why the finding did or did not lead to a fix |

### Lifecycle / Relationships

Each suspected issue must produce exactly one `InvestigationFinding` before
review signoff. A finding may aggregate multiple probe or fixture cases.
