# Data Model: Full Antigravity Refocus

F-184 uses local file and hook-event data only. There is no database and no new
runtime dependency.

## Entity: AntigravityHookEvent

**Purpose**: normalized event consumed by the existing Specrew dispatcher.

| Field | Source | Notes |
| --- | --- | --- |
| `event_name` | Antigravity hook runtime | `PreInvocation` and `Stop` are carriers in this feature. |
| `conversation_id` | Antigravity hook payload | Stable `agy` session identity; must sanitize before path use. |
| `transcript_path` | Antigravity hook payload | Evidence reference only; do not log full transcript content. |
| `workspace_paths` | Antigravity hook payload | Used to resolve project context. |
| `invocation_num` | Antigravity hook payload | Correlation and evidence signal. |
| `tool_call` / `step_idx` | Tool events | Observed but not injection carrier for F-184. |

## Entity: RefocusSessionState

**Purpose**: existing per-session state file owned by `SessionStateAccessor`.

Path shape:

```text
.specrew/runtime/refocus-state-<sanitized-session>.json
```

Required F-184 behavior:

- Antigravity session state keys derive from real sanitized `conversationId`.
- No global `unknown` fallback when the host supplies identity.
- Boundary cursor, anchor/context metadata, dedupe, breaker, and journal data
  remain in the shared state model.
- State read/write failures use existing fail-open warning behavior.

## Entity: ConcurrencyMarker

**Purpose**: advisory same-worktree marker used to warn about possible parallel
sessions.

F-184 classification:

- Current Antigravity session marker -> no advisory.
- Different session marker in same worktree -> existing advisory.
- Stale or malformed marker -> existing fail-open/stale behavior.

## Entity: AntigravityHookBinding

**Purpose**: host manifest/config information used by hook deployment.

Fields are already manifest-driven:

- host kind: `antigravity`
- config file: `.agents/hooks.json`
- definition: Specrew-owned named hook definition
- selected carriers: `PreInvocation`, `Stop`
- opt-out marker: host-specific runtime marker

F-184 may extend binding metadata only as needed for B3 support and must not
change non-Antigravity host contracts.

## Entity: ValidationEvidence

**Purpose**: review and release proof for status claims.

Required evidence labels:

- automated Pester evidence
- manual real-host `agy` evidence
- repo-reproducible vs machine-local label
- beta/stable release gate evidence
- legacy-upgrade/config-migration evidence before stable
