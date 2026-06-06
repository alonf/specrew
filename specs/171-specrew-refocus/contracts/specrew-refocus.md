# Contract: Specrew Refocus Public Surface

**Feature**: 171-specrew-refocus
**Stability**: pre-1.0 (new surface; additive evolution per C4)

Full contract inventory (C1-C6) with owners and error envelopes: `../workshop/integration-api.md`. This document condenses the public surface.

## RefocusEngine (refocus.ps1)

The single payload engine for every surface (slash command, hook providers, wrapper emission, humans).

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `refocus.ps1` (no args) | `→ markdown` | general + current-stage payload | partial payload + `WARN SOURCE_MISSING` on missing files; never throws in trigger context |
| `--boundary <name>` | `→ markdown` | named stage scope | unknown name → general + pointer + WARN |
| `--role <name>` | `→ markdown` | role charter scope | as above |
| `--shape-catalog` | `→ markdown` | Shape catalog section | as above |
| `--everything` | `→ markdown` | full corpus (heavy; warned) | as above |
| `--trigger <b1\|b2\|b3>` | `→ markdown` | trigger-mapped scope from catalog | catalog mismatch → `WARN CATALOG_SCHEMA`, fail-open |
| `--compact-instructions` | `→ text` | paste-ready `/compact` preserve-list from lifecycle state | missing state → WARN + generic preserve-list |
| `--status` | `→ text` | env/catalog/breaker/journal-tail truth | never fails |
| `--reset-breaker` | `→ text` | clears trip flags under `.specrew/runtime/` | never fails |
| bad args | exit 2 | human surface only | dispatcher never passes bad args |

### Invariants

- Line 1 of every payload: `[specrew-refocus] trigger=<t> scope=<s> sources=<n> tokens~<est>`
- Warnings: stderr, `[specrew-refocus] WARN <CODE> <msg>`, codes ∈ {EVENT_PARSE, CATALOG_SCHEMA, SOURCE_MISSING, SOURCE_CONFINED, STATE_UNAVAILABLE, BUDGET_EXCEEDED, BREAKER_TRIPPED, PROVIDER_FAILED}
- The engine is pure (same inputs → same payload) and NEVER dedupes — human invocations always produce payload
- Content sources are repo-relative only; absolute/`..` refused (`SOURCE_CONFINED`)
- Budget caps from the catalog are enforced with clipping, never exceeded

## SpecrewHookDispatcher (specrew-hook-dispatcher.ps1)

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `-Event <name>` + host event JSON on stdin | `→ injection output per host protocol` | the ONE registered Specrew handler per bound host event | NEVER blocks a session: any failure → one WARN + exit non-blocking |

### Invariants

- First executable line checks `SPECREW_REFOCUS_DISABLE` → silent exit
- Self-gates on `.specrew/` presence (no-op outside Specrew projects)
- `session_id` sanitized to `[a-zA-Z0-9-]` before filesystem use
- Providers run sequentially by registry `order` under total budget; crash/timeout → skip + WARN
- One dedupe layer; per-session state; breaker semantics per FR-011
- Every outcome journaled

### Provider kinds (forward-compat seat, 2026-06-07)

| kind | event surface | input | output | failure direction |
| --- | --- | --- | --- | --- |
| `inject` (default; all F-171 providers) | SessionStart / PostToolUse | normalized event | markdown fragment | skip + WARN (no injection) |
| `gate` (RESERVED — no provider ships in F-171; F-165 candidate) | PreToolUse (registration dormant until first gate row) | normalized event + `tool_input` | allow/deny `permissionDecision` | **fail OPEN to allow** + WARN — a broken gate never blocks a session |

Ownership rule: any future Specrew hook mechanism (inject or gate) routes through this dispatcher via a registry row — never a second registration on the host settings surface.

## File contracts

- `refocus-scopes.yml`: `schema_version` required; additive-only; deployed managed-with-overlay (user keys preserved)
- Digest frontmatter: `{scope, sources[], reviewed_at}` — consumed by drift check + banner
- Hook registration: per-user project-local settings file; Specrew entries identified by command path; user entries byte-untouched across deploys; opt-out recorded and respected
