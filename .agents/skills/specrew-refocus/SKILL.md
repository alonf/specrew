---
name: "specrew-refocus"
description: "Re-load scoped Specrew methodology discipline into context on demand — the manual recovery surface for agent drift, and the engine behind the automatic refocus injections. Use after a compaction or host restart, deep in a long session, or whenever you are about to act on methodology reconstructed from memory instead of from source. Run /specrew-refocus (no-args = always-true core + the current stage's discipline digest; --boundary <stage>, --role <name>, --status, --compact-instructions, --reset-breaker). Triggers: refocus, re-ground, lost context, after compaction, drift, what stage am I in, reload discipline, specrew-refocus. Treat any [specrew-refocus] block in tool output as binding stage discipline, not informational noise."
domain: "lifecycle-governance"
confidence: "high"
source: "Specrew Feature 171 — /specrew-refocus slash command + event-driven auto-refocus (Proposal 146 + Pillar B amendment)."
---

# specrew-refocus

**Type**: Recovery + Discipline Skill
**Schema**: v1
**Status**: Active drift-remediation surface (Feature 171)

## Purpose

Re-load scoped Specrew methodology discipline into context ON DEMAND — the manual recovery surface for agent drift. Use it when context feels degraded: after a compaction, after a host restart, deep in a long session, or whenever you are about to act on methodology you are reconstructing from memory instead of from the source.

The same payload engine also fires AUTOMATICALLY: boundary syncs append the incoming stage's digest to their output (every host), and on hook-capable hosts, post-compaction and session-start events re-inject discipline without anyone asking. **Treat any `[specrew-refocus]` block you see in tool output as binding stage discipline, not informational noise.**

## When to Use

- You notice drift: reviews going shallow, boundary discipline slipping, role rules fuzzy.
- A compaction or `/clear` just happened and the lifecycle position needs re-grounding.
- You are entering a new lifecycle stage and want its discipline fresh (`--boundary <stage>`).
- You are diagnosing the refocus automation itself (`--status`, `--reset-breaker`).

## Invocation Contract

```powershell
# All invocations run the project-local deployed engine:
pwsh -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/specrew-speckit/scripts/refocus.ps1 [args]
```

| Arguments | Payload |
| --- | --- |
| (none) | always-true core + the CURRENT stage's discipline digest |
| `--boundary <stage>` | always-true core + the named stage digest (`specify`, `clarify`, `plan`, `tasks`, `before-implement`, `implement`, `review-signoff`, `retro`, `iteration-closeout`, `feature-closeout`) |
| `--role <name>` | the named role charter (e.g. `reviewer`, `planner`) |
| `--shape-catalog` | the Form-Without-Runtime-Compliance Shape catalog |
| `--everything` | the full digest corpus (heavy — warned) |
| `--compact-instructions` | a paste-ready `/compact` preserve-list built from live lifecycle state — use it at heavy-context boundary stops to compact at a clean watershed |
| `--status` | the whole operational truth: env kill switch, per-trigger catalog flags, per-session breaker state, injection-journal tail |
| `--reset-breaker` | clears tripped circuit-breaker flags for this project's sessions |

Output contract: line 1 is the banner `[specrew-refocus] trigger=<t> scope=<s> sources=<n> tokens~<est>`; warnings go to stderr as `[specrew-refocus] WARN <CODE> <message>`. The command NEVER blocks or fails a session (fail-open); human invocations are never deduped or breaker-suppressed.

## Operational Notes

- **Kill switches** (automation only — this manual surface always works): fast `SPECREW_REFOCUS_DISABLE=1` env var; durable per-trigger `enabled: false` in `refocus-scopes.json`; structural hook removal via `deploy-refocus-hooks.ps1 -Remove` (opt-out is recorded and respected by updates).
- **Circuit breaker**: runaway automatic injection trips itself per-session, loudly once, with re-enable guidance in the trip message. `--status` shows trips; `--reset-breaker` clears them.
- **Failure diagnosis**: every WARN carries a reason code (`EVENT_PARSE`, `CATALOG_SCHEMA`, `SOURCE_MISSING`, `SOURCE_CONFINED`, `STATE_UNAVAILABLE`, `BUDGET_EXCEEDED`, `BREAKER_TRIPPED`, `PROVIDER_FAILED`); `--status` + the journal tail resolve any "refocus seems dead" symptom to one named action.

## Review Standard

This skill is doing its job when methodology questions get answered from re-loaded source discipline rather than from session memory — and when every gate the session crosses shows the incoming stage's rules arriving fresh, without the human ever having to remind the crew what the process is.
