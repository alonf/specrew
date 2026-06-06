# Data Model: Specrew Update Downgrade Guard and Compatibility Message Cleanup

**Feature**: 159-update-ux-small-fixes  
**Date**: 2026-06-05  
**Purpose**: Define the transient configuration/version entities used by the update guard and compatibility-message cleanup.

## No Persisted Data

This feature does not introduce a database or new persisted application entity. It reads existing project configuration and source manifests, then either refuses before mutation or lets existing update behavior continue.

## Entity: RunningSpecrewVersion

**Purpose**: Represents the Specrew module/source version executing `specrew update`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `rawText` | string | Yes | Non-empty semantic version text from the running extension/module manifest | Original version string used for display and comparison input. |
| `parsedVersion` | version | Yes | Must parse through the existing Specrew semantic-version helper | Comparable version value. |
| `sourcePath` | string | Yes | Must point inside the resolved running Specrew source/module tree | Explains where the running version was derived. |

### Lifecycle / Relationships

Created during `specrew update` startup after the project path and repository root are resolved. It is compared to `ProjectSpecrewBaseline` before any mutating update operation.

## Entity: ProjectSpecrewBaseline

**Purpose**: Represents the target project's recorded `.specrew/config.yml` `specrew_version`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `rawText` | string | No | Empty or absent means no downgrade comparison is possible | Existing baseline stored in the project config. |
| `parsedVersion` | version | Conditional | Required when `rawText` is present | Comparable project baseline. |
| `configPath` | string | Yes | Must be the resolved target project's `.specrew/config.yml` | Source file for the baseline. |

### Lifecycle / Relationships

Read before mutation and never modified on stale-module refusal. When the running version is equal or newer, existing update behavior may rewrite it as before.

## Entity: UpdateInvocation

**Purpose**: Captures whether a `specrew update` invocation is read-only or mutating and which scopes are requested.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `infoMode` | boolean | Yes | `true` means read-only | Whether `--info` was requested. |
| `scopes` | string[] | Yes | Values from `Specrew`, `Spec Kit`, `Squad` | Requested update targets. |
| `isMutating` | boolean | Yes | Must be false for `--info`; true for all update scopes | Determines whether downgrade refusal applies. |

### Lifecycle / Relationships

Derived from parsed CLI arguments. `UpdateInvocation` gates the downgrade check: read-only info mode remains non-mutating; all other scopes require stale-module safety.

## Entity: ProtectedAssetSnapshot

**Purpose**: Test-only representation of files that must remain unchanged when stale-module refusal occurs.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `path` | string | Yes | Path inside the scratch project | Protected file or directory entry. |
| `contentHash` | string | Yes | Stable hash captured before and after refusal | Byte-level mutation proof. |
| `exists` | boolean | Yes | Compared before and after refusal | Detects creation or deletion. |

### Lifecycle / Relationships

Created by regression tests before running stale `specrew update`; compared after command refusal to prove no mutation happened.

## Entity: ActiveCompatibilityMessage

**Purpose**: Represents current generated/routine user-facing compatibility text subject to `0.24.0` cleanup.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `path` | string | Yes | Must be an active script or generated template path | Source containing current user-facing guidance. |
| `messageKind` | string | Yes | `help`, `report`, `governance`, or `skill` | Message category. |
| `containsOldBaseline` | boolean | Yes | Must be false for active current-baseline wording after implementation | Whether stale `0.24.0` baseline language remains. |

### Lifecycle / Relationships

Active surfaces are scanned and updated during implementation. Historical artifacts are excluded from this entity and remain unchanged.
