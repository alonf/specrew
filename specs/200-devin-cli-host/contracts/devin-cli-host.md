# Contract: Devin CLI Host Public Surface

**Feature**: 200-devin-cli-host
**Stability**: pre-1.0

## Registry Validation

The existing registry remains the sole runtime catalog.

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Get-RegisteredHostKinds` | `() -> string[]` | Return deterministic registered kinds. | Invalid manifests are diagnosed and excluded according to existing registry rules. |
| `Get-HostManifest` | `-Kind <string> -> hashtable` | Resolve one manifest case-insensitively. | Throws actionable unknown-host guidance with the registered list. |
| `Test-SpecrewRegisteredHostKind` | `-Kind <string> -> bool` | Reusable validator for parameter boundaries. | Returns false or throws validator guidance; never embeds a host enum. |
| `Get-SpecrewCoordinatorHostDescriptors` | `() -> object[]` | Return manifest-declared coordinator-capable hosts and defaults. | Invalid conditional coordinator metadata fails manifest/package validation. |

### Invariants

- No second host catalog exists.
- The three production input callsites validate against the live registry.
- Unknown values name the currently registered host kinds.

## Host Manifest Additions

### Fields

| Field | Shape | Contract |
| --- | --- | --- |
| `CanCoordinate` | bool | Optional; default false. |
| `CoordinatorDefaults` | hashtable | Required when `CanCoordinate=true`; contains `Enabled`, `AccessPath`, and `StrengthRank`. |
| `SupportedVersions.TestedBuilds` | string[] | Exact tested-build identifiers; Devin starts with `2026.7.23 (3bd47f77)`. |
| `CompatibilityMonitoring.FragileSurfaces` | string[] | Declares launch, hook, payload, export, and normalized-handover surfaces for future monitoring. |
| `TranscriptExport` | hashtable | Package-owned export/normalization metadata and controlled runtime paths. |
| `RefocusHookBindings.EventPayloadAdapter` | relative path | Optional module-relative package adapter invoked before the shared dispatcher. |

### Invariants

- Missing additive fields preserve existing host behavior.
- Adapter paths cannot escape the declaring package.
- Coordinator eligibility is explicit and is not derived from host status.
- Authentication and credentials remain host-owned.

## Host Package FileList Projection

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Get-SpecrewHostPackageFileListEntries` | `-ProjectRoot <path> -> string[]` | Derive normalized required files and declared package assets. | Fails on missing required files, escaping paths, duplicates, or invalid manifests. |
| `Update-SpecrewHostPackageFileList` | `-ProjectRoot <path> [-Check] -> result` | Regenerate or verify the marked host-package segment of `Specrew.psd1`. | `-Check` is non-mutating and fails on drift. |

### Invariants

- Output order is ordinal and platform-independent.
- Hand-authored per-host paths are not the source of truth.
- Generated `Specrew.psd1` host rows may contain host names and are explicitly
  classified as generated artifacts.
- FileList-faithful package tests must consume the generated result.

## Devin Five-Handler Contract

`hosts/devin/handlers.ps1` implements exactly the existing five registry slots.

| Handler | Signature | Contract |
| --- | --- | --- |
| `New-DevinLaunchInvocation` | `-ProjectPath -Prompt -Agent [-AllowAll] [-UseAutopilot] [-UseRemote]` | Returns interactive `devin` invocation, positional prompt, controlled `--export` path, permission mode, and notices. |
| `ConvertTo-DevinFlag` | `-SpecrewFlag <flag>` | Maps normal/allow-all/autopilot semantics without a shared-core branch. |
| `Test-DevinRuntimeInstalled` | `-ProjectPath <path>` | Detects the manifest binary on `PATH`. |
| `Get-DevinSignals` | `()` | Returns only verified Devin runtime environment signals. |
| `Install-DevinCrewRuntime` | `-ProjectPath <path> [-DryRun]` | Projects canonical Crew charters to `.devin/agents/<name>/AGENT.md` while preserving canonical sources. |

### Launch invariants

- Normal sessions are interactive; `-p` is canary-only.
- Permission modes map normal → `auto`, autopilot → `smart`, allow-all →
  `dangerous`; dangerous has precedence and emits a notice.
- Session resume flags are not added in Feature 200.
- The export path remains under `.specrew/runtime/`.

## Devin Hook Adapter

`hosts/devin/hook-adapter.ps1` is package-private and is selected by the generic
`EventPayloadAdapter` manifest seam.

### Invocation

| Input/output | Contract |
| --- | --- |
| stdin | Raw Devin Claude-compatible event JSON. |
| arguments | Event, host kind/binding, project/module resolution values supplied by the generic launcher. |
| stdout | Exact shared-dispatcher output, including Stop decision JSON. |
| stderr | Bounded diagnostics with reason codes only. |
| exit | Preserve required hook semantics; adapter/normalization failure degrades visibly and never fabricates transcript success. |

### Normalizer

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `ConvertFrom-DevinAtif` | `-InputPath <path> -OutputPath <path> -> result` | Convert accepted ATIF user/agent string-message steps to existing Claude-like JSONL. | Returns bounded missing/unreadable/invalid reason; no raw content in diagnostics. |

Normalized rows are:

```json
{"type":"user","message":{"content":[{"type":"text","text":"..."}]}}
{"type":"assistant","message":{"content":[{"type":"text","text":"..."}]}}
```

### Invariants

- `ConversationCaptureAccessor.ps1` is unchanged.
- Writes are atomic and remain under local runtime storage.
- Non-message ATIF steps are ignored.
- Transcript bodies never enter logs or CI artifacts.
- Stop payload is enriched with `transcript_path` only after successful
  normalization.

## Direct Event-Map Hook Configuration

The generic hook deployer accepts `ConfigShape='direct-event-map'`, where event
keys live at the JSON root rather than under `hooks`.

### Invariants

- Merge/remove/status changes only Specrew-owned command rows.
- Existing user event rows and unrelated top-level properties are preserved.
- Unreadable/malformed JSON is never overwritten.
- Devin declares SessionStart, UserPromptSubmit, and Stop in
  `.devin/hooks.v1.json` and resolves the project through `DEVIN_PROJECT_DIR`.
- The direct-`pwsh` Windows form is evidence-gated. If unsupported by the host,
  `sh.exe` remains an explicit experimental prerequisite.

## Managed Coordinator Projection

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Merge-SpecrewManagedAgentProjection` | `-Content <string> -Descriptors <object[]> -Detection <object[]> -> string` | Replace only the marked managed `agents:` block. | Refuses ambiguous/corrupt ownership markers; preserves original content. |

### Merge rules

- Preserve valid mutable values by host key.
- Add missing coordinator-capable hosts using manifest defaults.
- Remove no-longer-eligible hosts only from the managed block.
- Preserve unrelated YAML and content outside the markers.
- Absent, legacy, partial, and current shapes converge in one run.
- A second run is byte-identical.

## CLI Compatibility Surface

| Command | Contract |
| --- | --- |
| `specrew start --host devin` | Supported backward-compatible launch entry; selects the Devin package through the registry. |
| `specrew update` | In an installed/disposable project, regenerates generic host assets and performs the known one-run managed-agent migration. |
| `specrew init` | Creates the same registry-derived managed-agent projection for new projects. |

Feature 200 does not require sequential version-by-version updates. It also does
not claim arbitrary historical convergence; that validation belongs to a
separate proposal and PR.
