# Data Model: Devin CLI Host — Clean-Extensibility Proof

**Feature**: 200-devin-cli-host
**Date**: 2026-06-24
**Purpose**: Define host metadata, generated projections, managed project state,
transcript artifacts, and compatibility evidence introduced or extended by
Feature 200.

## Entity: HostPackage

**Purpose**: One registry-discovered host implementation rooted under
`hosts/<kind>/`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `kind` | lowercase string | yes | Equals folder name; unique. | Canonical host identifier. |
| `manifest_path` | relative path | yes | Existing `host.psd1`. | Declarative host metadata. |
| `handlers_path` | relative path | yes for active hosts | Existing file with all five contract handlers. | Runtime strategy implementation. |
| `coordinator_rules_path` | relative path | yes | Existing PSD1; rules may be empty. | Coordinator prompt surgery data. |
| `package_assets` | relative path[] | no | Must remain within the host folder. | Package-private adapters such as Devin's hook adapter. |

### Lifecycle / Relationships

Discovered from disk by the single registry, validated, and cached for the
PowerShell process. It produces `HostPackageFileListEntry` rows and may expose a
`CoordinatorDescriptor`. Adding a normal host package does not mutate an
independent catalog.

## Entity: HostManifest

**Purpose**: Canonical declarative capability/default record for a host.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| existing contract fields | PSD1 values | yes/conditional | Existing host contract remains authoritative. | Identity, binary, runtime layout, handlers, hooks, instructions, skills. |
| `CanCoordinate` | bool | no | Defaults to false. | Eligibility for managed coordinator projection. |
| `CoordinatorDefaults` | hashtable | when `CanCoordinate=true` | Requires `Enabled`, `AccessPath`, `StrengthRank`. | Defaults used when a project has no preserved value. |
| `SupportedVersions.TestedBuilds` | string[] | for Devin | Exact non-empty identifiers; no invented semver ordering. | Builds with empirical evidence. |
| `CompatibilityMonitoring.FragileSurfaces` | string[] | for volatile hosts | Bounded known vocabulary. | Upstream surfaces future monitoring must canary. |
| `TranscriptExport` | hashtable | when export normalization is used | Paths stay under local runtime storage; adapter path remains in package. | Export format, paths, normalizer, and normalized shape. |
| `RefocusHookBindings.EventPayloadAdapter` | relative path | no | Module-relative, remains in declaring host package. | Optional pre-dispatch event adapter. |

### Lifecycle / Relationships

Loaded from the host package and validated before use. New fields are additive:
missing coordinator fields mean ineligible; missing event adapter means direct
shared-dispatch behavior. No project data migration is required to load an
older package manifest.

## Entity: CoordinatorDescriptor

**Purpose**: Registry-derived row used to generate or migrate the managed
project `agents:` block.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `kind` | string | yes | Registered host with `CanCoordinate=true`. | YAML map key. |
| `default_enabled` | bool | yes | Manifest value. | Initial project opt-in state. |
| `access_path` | string | yes | Non-empty bounded identifier. | Coordinator access mechanism such as `host_process`. |
| `strength_rank` | integer | yes | Non-negative, deterministic. | Existing routing preference metadata. |
| `availability` | string | yes at projection time | Derived from runtime detection or preserved project state. | Current project availability. |

### Lifecycle / Relationships

Created transiently from manifests and runtime detection. It is merged with
existing managed project values to produce `ManagedAgentEntry`.

## Entity: ManagedAgentEntry

**Purpose**: One host row in the Specrew-owned block of
`.specrew/iteration-config.yml`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `host_key` | string | yes | Coordinator-capable registry key. | YAML child key under `agents`. |
| `enabled` | bool | yes | Preserve existing value by key; otherwise manifest default. | Project consent. |
| `access_path` | string | yes | Preserve mutable value when valid; otherwise manifest default. | How coordinator reaches the host. |
| `availability` | string | yes | Detection result or preserved safe value. | Runtime presence state. |
| `strength_rank` | integer | yes | Preserve valid value; otherwise manifest default. | Routing preference. |

### Lifecycle / Relationships

Generated only inside explicit start/end ownership markers. Migration accepts
absent, legacy-three-host, partial, and current blocks; it preserves unrelated
YAML and becomes byte-idempotent after one run. Entries no longer eligible are
removed only from the managed block.

## Entity: HostPackageFileListEntry

**Purpose**: Deterministic generated package membership row in
`Specrew.psd1`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `relative_path` | normalized string | yes | Existing file under a registered host package. | File shipped in the module. |
| `source` | enum | yes | `required-contract-file` or `manifest-declared-asset`. | Why the file is included. |
| `host_kind` | string | yes | Registered package owner. | Traceability only; not emitted separately. |

### Lifecycle / Relationships

Derived from all host packages, sorted ordinally with `/`-normalized paths, and
written to a marked generated segment. Generate/check parity fails on missing,
stale, duplicate, escaping, or non-deterministic entries.

## Entity: DevinTranscriptExport

**Purpose**: Controlled local ATIF output produced by the pinned Devin CLI.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `format` | string | yes | `ATIF`; tested schema version recorded. | Source transcript format. |
| `raw_path` | local relative path | yes | Under `.specrew/runtime/`; never committed or uploaded. | `--export` destination. |
| `normalized_path` | local relative path | yes | Under `.specrew/runtime/`; fixed/bounded path. | Existing-parser JSONL input. |
| `steps` | object[] | yes for successful capture | Accept only `source=user|agent` string-message turns; ignore non-turn records. | Source conversation records. |
| `result` | enum | yes | `normalized`, `missing`, `invalid`, `unreadable`. | Bounded adapter outcome. |
| `reason_code` | string | no | No prompt/transcript content. | Diagnostic classification. |

### Lifecycle / Relationships

The CLI refreshes the raw file before Stop. The package-local adapter validates
and rewrites the normalized file atomically, then supplies its path to the
shared dispatcher. Fixed runtime paths prevent unbounded archive growth.

## Entity: NormalizedConversationTurn

**Purpose**: Existing Claude-like JSONL row consumed by the unchanged parser.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `type` | enum | yes | `user` or `assistant`. | Existing parser role selector. |
| `message.content` | object[] | yes | At least one `{type="text", text=<string>}` element. | Existing parser content shape. |

### Lifecycle / Relationships

Produced only by the Devin normalizer from accepted ATIF steps. It introduces
no durable schema and no parser edit.

## Entity: CompatibilityEvidence

**Purpose**: Bounded proof record for experimental/supported status and future
compatibility monitoring.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `tested_build` | string | yes | Exact `2026.7.23 (3bd47f77)` for the initial gate. | Host build identity. |
| `os` | string | yes | Bounded platform identifier. | Validation platform. |
| `surface` | enum | yes | launch, permission, hook-load, SessionStart, UserPromptSubmit, Stop, hook-merge, ATIF, handover. | Tested fragile surface. |
| `mechanism` | string | yes | Bounded implementation label. | Path exercised. |
| `result` | enum | yes | pass, fail, degraded, not-applicable. | Outcome. |
| `reason_code` | string | no | Bounded and non-sensitive. | Failure/degradation class. |

### Lifecycle / Relationships

Created by prerelease validation and reviewed before status promotion. It never
contains prompts, transcript bodies, credentials, or authentication state.
