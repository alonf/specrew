# Data Storage Lens

## Decision

Use the same durable per-session refocus state model as the other hosts.
Antigravity must not introduce a private runtime state shape.

## Runtime State Model

```text
Antigravity PreInvocation
        |
        v
+-----------------------------+
| real agy session key        |
| sanitized conversation id   |
+--------------+--------------+
               |
               v
+-----------------------------+
| .specrew/runtime/           |
| refocus-state-<session>.json|
+--------------+--------------+
               |
      +--------+---------+----------------+
      |                  |                |
      v                  v                v
+------------+   +---------------+   +---------------+
| boundary   |   | anchor/context|   | dedupe/breaker|
| cursor     |   | metadata      |   | journal       |
+------------+   +---------------+   +---------------+
```

## Ownership

- `SessionStateAccessor` remains the only owner of refocus state read/write.
- The Antigravity event adapter normalizes the host event and real
  session/conversation key, then calls the existing state/classification/B3
  path.
- The dispatcher must not write Antigravity-specific JSON directly.
- No service or adapter may create a second private state file for
  Antigravity.

## Persistence And Retention

- The per-session refocus state and anchor must survive `agy` exit and re-entry,
  as they do for the other supported hosts.
- Transient hook input payloads and self-marker probes do not need to survive.
- Startup-only or stale Antigravity state is disposable runtime data; do not add
  a migration unless discovery proves existing files must be preserved.
- Runtime cleanup should use the existing cleanup behavior for stale session
  state.

## Consistency Model

```text
Antigravity PreInvocation
  -> normalize real session/conversation key
  -> read refocus-state-<session>.json
  -> read current boundary cursor
  -> Test-B3ShouldInject
  -> write updated anchor/cursor/dedupe/breaker state once
```

The consistency model is file-backed, single-session state update through the
existing accessor. If state read/write fails, use the existing governed
failure/fallback path and surface the failure instead of pretending full
refocus worked.

## Validation Obligations

- Prove Antigravity never falls back to global `unknown`.
- Prove Antigravity does not write a second private state shape.
- Prove exit/re-entry loads the same per-session anchor.
- Prove B3 reads current boundary cursor state before deciding whether to
  inject.

## Confirmation

The human confirmed that Antigravity must behave like all other hosts for
per-session durable refocus state, that `SessionStateAccessor` owns state
read/write, that no old startup-only Antigravity state migration is required,
and that this consistency/validation model closes the data-storage lens.
