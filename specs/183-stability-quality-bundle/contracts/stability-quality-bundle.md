# Contract: Stability and Quality Bundle Public Surface

**Feature**: 183-stability-quality-bundle
**Stability**: pre-1.0

## Hook Dispatcher and Providers

The hook dispatcher receives host hook events and composes provider fragments for
delivery to the host/model.

### Exported / Invoked Surface

| Surface | Signature / Invocation | Purpose | Errors |
| --- | --- | --- | --- |
| `specrew-hook-dispatcher.ps1` | `-Event <event> -HostKind <host> [-EventJson <json>]` | Dispatch verified hook events to providers and emit host-facing output. | Provider errors degrade to governed fallback and exit 0 where required. |
| Bootstrap provider | Provider-specific script invocation by dispatcher. | Produce bootstrap fragment. | Failure is caught by fallback path. |
| Refocus provider | Provider-specific script invocation by dispatcher. | Produce refocus/status fragment. | Lower priority than bootstrap under cap pressure. |

### Invariants

- Bootstrap fragment outranks refocus content for SessionStart delivery.
- Provider failure must not produce empty stdout as the user-facing result.
- Fallback output must be under cap, governed, and actionable.
- Host payload fields are untrusted and may be missing or malformed.

## Session State

Session state surfaces are local-file runtime state consumed by refocus status,
journal, dedupe, and breaker behavior.

### Contract

| Surface | Shape | Purpose | Errors |
| --- | --- | --- | --- |
| Session key resolver | Host session ID or generated fallback token. | Select filesystem-safe per-launch key. | Missing/malformed IDs generate a fallback token; they do not collapse to global `unknown`. |
| Runtime state files | `.specrew/runtime/refocus-state-<key>.json` and related state. | Persist best-effort local session state. | Historical `unknown` files are not migrated. |

### Invariants

- New state writes must not depend on global `unknown`.
- Per-launch fallback tokens must be filesystem-safe.
- Same-worktree multi-host concurrency remains advisory; disk artifacts are
  authoritative.

## Hook Deployment and Repair

Hook deployment installs, repairs, removes, and reports Specrew hook bindings.

### Invoked Surface

| Surface | Invocation | Purpose | Errors |
| --- | --- | --- | --- |
| `specrew hooks status` | CLI command | Report installed/missing/stale/failed hook status. | Degraded states are reported, not hidden. |
| `specrew hooks install --host <host>` | CLI command | Install or refresh host hooks. | Unknown or unsupported hosts fail clearly. |
| `specrew hooks remove --host <host>` | CLI command | Remove Specrew-owned hooks and record opt-out. | User hooks must be preserved. |
| `deploy-refocus-hooks.ps1` | `-HostKind <host> [-ProjectPath <path>] [-Remove] [-Force]` | Host-specific hook config deployment primitive. | Unsafe parse/merge fails open and preserves config. |

### Antigravity Binding

| Field | Contract |
| --- | --- |
| Config location | Project-scoped `.agents/hooks.json`. |
| Ownership | Specrew-owned entries only; user entries preserved. |
| Events | Only verified Antigravity events may map to Specrew behavior. |
| Fallback | `specrew start --host antigravity` remains the governed fallback. |
| Parity claims | Unsupported or unverified events are labeled degraded/deferred. |

## Closeout Sync

Closeout sync derives lifecycle state and human-visible messages from current
repo state.

### Invoked Surface

| Surface | Invocation | Purpose | Errors |
| --- | --- | --- | --- |
| `sync-boundary-state.ps1` | `-ProjectPath . -BoundaryType <boundary> -FeatureRef <feature>` | Advance boundary state and render closeout/dashboard artifacts. | Must not tell user a commit "must be pushed" without upstream. |
| Dashboard renderer | Existing closeout/dashboard render path. | Refresh dashboard on auto-detect paths. | Stale dashboard must not be silently reused when regeneration is required. |

### Invariants

- `.specify/extensions/` and companion `.specify` files classify coherently.
- No-upstream branches use local commit wording.
- Auto-detect closeout paths regenerate dashboard output.

## Mirror and Release Evidence

### Contract

| Surface | Purpose | Errors |
| --- | --- | --- |
| Source extension files | Authoritative implementation. | Touched file requires mirror check. |
| `.specify` mirror files | Deployed dogfood copy. | Mismatch blocks readiness unless explicitly deferred. |
| Release validation record | Records beta target and real-host validation. | Stable cannot promote without PASS evidence. |

### Invariants

- Exact beta suffix is selected at release time after tag/package inspection.
- Real-host validation is required before stable promotion.
- Fixing commits must link to issues #2446, #1627, and #1761 at closeout.
