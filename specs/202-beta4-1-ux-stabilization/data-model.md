# Data Model: 202 beta4.1 UX stabilization

All records are JSON or JSONL under `.specrew/`. Integrity stores hold hashes, event names and timestamps only, never prompt or reply text. Existing records are extended additively, and legacy entries are never rewritten.

## Standard turn record (in memory; produced by `ConvertTo-SpecrewTurnRecord`)

| Field | Type | Rule |
| --- | --- | --- |
| `event` | string | Dispatcher event name after host registration mapping |
| `host` | enum | claude, codex, copilot, cursor, antigravity |
| `session_id` | string or null | From the binding's field map; null when the host supplies none |
| `typed_text` | string or null | User prompt text, for prompt events only |
| `origin` | enum | `typed-user`, `host-injected` or `unknown`, from the binding's origin rules and named transform |
| `transcript_path` | string or null | When the host supplies one |

Only `origin = typed-user` may produce a receipt (FR-006). The journal and outage-buffer match still applies to every reply (FR-005).

## Host binding additions (`hosts/<host>/host.psd1`, `RefocusHookBindings`)

| Key | Type | Purpose |
| --- | --- | --- |
| `InputFieldMap` | hashtable | Payload paths for session id, prompt text and transcript path |
| `OriginRules` | array | Declarative conditions that classify origin |
| `InputTransform` | string or null | Name of one transform in the shared registry |

## Hook-output journal line (existing, unchanged shape)

`.specrew/runtime/hook-output-authority.jsonl`: hash records of emitted hook text. FR-001 changes only the write path, to concurrent-append safe.

## Outage buffer file (new)

`.specrew/runtime/hook-output-buffer/<pid>-<guid>.jsonl`. Same line shape as the journal. It is read before every prompt decision, and flushed into the journal and removed on recovery.

## Health journal line (new)

`.specrew/runtime/hook-output-health.jsonl`: `{ transition: degraded|recovered, class, error_text_hash, first_seen, count, recovered_at }`. A legacy `hook-output-authority.jsonl.unhealthy` file is read as a `degraded` state and cleared by the next good append.

## Presented-crossing record (new)

`.specrew/runtime/turn-end/<ownerHash>/presented-crossings.json`: `{ crossing_id, reviewed_artifact_state, presented_at, session_start_kind }`. It is cleared by a context gap (DA-2). HEAD movement alone does not clear it.

## Turn draft (new location)

`.specrew/runtime/turn-end/<ownerHash>/turn-message.md`. UTF-8, written by `declare-turn-end.ps1` from stdin (FR-021). It is ignored by git.

## Current-feature pointer (`start-context.json` `session_state`, extended)

| Field | Change |
| --- | --- |
| `feature_ref` | existing |
| `branch` | **new**: the branch the pointer was written for (FR-017) |
| `resolved_by` | **new**, on readers' output only: `controller`, `crossing`, `pointer` or `branch-hint` (FR-018 disclosure) |

## Ledger additions (`boundary_enforcement`)

| Record | Change |
| --- | --- |
| `verdict_history[]` new entries | **new** `feature_ref` |
| `pending_crossing` | **new** `feature_ref` |
| Legacy entries | never rewritten; `auth-83b0f0c2...` (out-of-band specify) is kept permanently |

The cycle-reset rule is one function: `feature-closeout -> specify` resets when the syncing feature differs from the feature of the last authorized feature-closeout (FR-026). The review-coverage line selects only campaigns whose `feature_ref` matches the resolved feature (SC-009).
