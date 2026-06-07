# Workshop Record — security-compliance (Lens 5, light)

**Feature**: 171-specrew-refocus
**Date**: 2026-06-06
**Confirmation**: human-confirmed (trust-boundary walk agreed as rendered)

## Agreed trust-boundary walk + controls

```text
  +- HOST EVENT (untrusted-ish input) ------------------------------+
  | event JSON on stdin: session_id, source, tool args              |
  | CONTROL: strict parse; NEVER eval content from event JSON;      |
  | session_id SANITIZED to [a-zA-Z0-9-] before any filename use    |
  | (state file is refocus-state-<id>.json - unsanitized id would   |
  | be a path-traversal vector)                                     |
  +---------------+--------------------------------------------------+
                  v
  +- HOOK REGISTRATION (who can make hooks run) --------------------+
  | settings.local.json - per-machine, gitignored, written ONLY by  |
  | specrew init/update that the USER ran. A cloned repo cannot     |
  | carry our hooks in (the C6 decision); we never touch            |
  | shared/project settings, so no new clone-time execution surface |
  +---------------+--------------------------------------------------+
                  v
  +- WHAT EXECUTES (the command itself) ----------------------------+
  | fixed: pwsh -File <project-local deployed dispatcher> - same    |
  | trust class as every existing deployed lifecycle script; same   |
  | user, same privileges as the agent's own shell tool; NO new     |
  | elevation, NO network, NO credential access anywhere in F-171   |
  +---------------+--------------------------------------------------+
                  v
  +- WHAT GETS INJECTED (payload confinement) ----------------------+
  | catalog-declared repo-relative paths ONLY - engine REFUSES      |
  | absolute paths or .. traversal in catalog/digest sources (WARN);|
  | payload = methodology text + file:/// pointers; refuse-to-do    |
  | register already bans secrets/env values in payloads            |
  +---------------+--------------------------------------------------+
                  v
  +- AUDIT ---------------------------------------------------------+
  | every injection is VISIBLE in-band (the banner names trigger +  |
  | scope + sources) - the conversation IS the audit trail; state   |
  | file fingerprints record what fired per session                 |
  +-----------------------------------------------------------------+
```

## Net assessment (agreed)

No new privilege, no new secret surface, no network. Two real injection vectors, each with a concrete confinement control:

1. `session_id` → state filename: sanitize to `[a-zA-Z0-9-]` before filesystem use
2. catalog/digest source paths → file reads: repo-relative only; absolute/`..` refused with WARN; provider commands must resolve under the project's deployed tree (registry validation at deploy time)

## Denial-path test obligations

- Malformed event JSON → fail-open + WARN (session unaffected)
- Hostile `session_id` (`../../x`) → sanitized; state write confined to `.specrew/runtime/`
- Catalog source with absolute or `..` path → refused + WARN
- Provider registry command outside the deployed tree → rejected at deploy-time validation
