# Workshop Record — component-design (Lens 2, full)

**Feature**: 171-specrew-refocus
**Date**: 2026-06-06
**Confirmation**: human-confirmed (map iterated: dispatcher generalization human-raised; per-session state bound; final map approved)

## Agreed component map (12 components)

```text
                        TRIGGER ADAPTERS (volatile, per-host)
  +----------------+  +--------------------------------------+  +---------------------+
  | RefocusSkill   |  | SpecrewHookDispatcher                |  | CoordinatorAdvisory |
  | (slash surface |  |  ONE registered handler per host     |  | (governance fallback|
  |  per host)     |  |  event; provider registry (ordered + |  |  + boundary-packet  |
  +-------+--------+  |  budgeted, data); dedupe; fail-open  |  |  compact hygiene)   |
          |           +------+-----------------+-------------+  +----------+----------+
          |                  | runs by order   | keyed by session_id       | suggests
          |                  v                 v                           |
          |        +------------------+ +----------------------------+    |
          |        | RefocusProvider  | | RefocusRuntimeState        |    |
          |        | registry row #1: | | .specrew/runtime/refocus-  |    |
          |        | event/source ->  | | state-<session-id>.json    |    |
          |        | engine scope     | | per-session; pruned        |    |
          |        | (B1/B2/B3 logic) | +----------------------------+    |
          |        +--------+---------+   (future: handover row #2 -      |
          |                 |              data only, no host config)     |
          v                 v                                             v
  +--------------------------------------------------------------------------+
  | RefocusEngine  (stable, host-neutral; canonical + deployed mirror)       |
  | scope flags -> catalog resolve -> digest reads -> banner + payload       |
  | + --compact-instructions (preserve-list from lifecycle state)            |
  +------+------------------------------+------------------------------------+
         v                              v
  +---------------------+   +----------------------------------+
  | RefocusScopeCatalog |   | RefocusDigests                   |
  | refocus-scopes.yml: |   | refocus/general.md + <stage>.md  |
  | scope->digests,     |   | x10; frontmatter sources +       |
  | trigger->scopes,    |   | file:/// pointers                |
  | budgets + provider  |   +----------------------------------+
  | registry            |
  +---------------------+
         ^
  +------+--------------------------------------------+
  | WrapperEmission (channel 1) - boundary-sync       |
  | wrapper appends --boundary <next> payload (ALL    |
  | hosts, hook or not)                               |
  +---------------------------------------------------+

  Deployment + governance (cross-cutting):
    HostHookBindings - per-host binding declarations (hosts/<kind>)
    DeployIntegration - deploy loop + FileList + merge-aware hook-config writes
    DigestDriftCheck - test-lane parity warn (digest sources vs canonical)
```

## Component-to-responsibility list

**Trigger adapters (volatile, per-host):**

- `RefocusSkill` — the `/specrew-refocus` manual surface, deployed per host (Pillar A)
- `SpecrewHookDispatcher` — THE one registered Specrew handler per bound host event; parses host event JSON; runs providers sequentially by registry order under the total budget; one dedupe layer; one fail-open wrapper; single injection
- `RefocusProvider` — provider-registry row #1: thin adapter mapping event/source → engine scope call (B1/B2/B3 routing lives here, host-blind)
- `CoordinatorAdvisory` — governance fallback text (Copilot + any non-hook context) + boundary-packet context-hygiene (compact guidance) line

**Engine (stable, host-neutral):**

- `RefocusEngine` — scope/trigger flags → catalog resolve → digest reads → banner + markdown payload; `--compact-instructions` generates the paste-ready `/compact` preserve-list from lifecycle state; pure (no dedupe — a human asking always gets payload)

**Content + data (stable, versioned):**

- `RefocusScopeCatalog` — `refocus-scopes.yml`: scope→digests, trigger→scopes, per-trigger token budgets, **provider registry** (id, events, order, budget_share, command)
- `RefocusDigests` — `refocus/general.md` + one per-stage digest ×10; frontmatter-declared canonical sources; `file:///` pointers

**Runtime state:**

- `RefocusRuntimeState` — `.specrew/runtime/refocus-state-<session-id>.json` (gitignored): last-seen boundary + injection fingerprints; **per-session keyed by the host's session id** (multi-session correct per F-051); opportunistic pruning (~7 days)

**Channel 1:**

- `WrapperEmission` — deployed boundary-sync **wrapper** appends the engine's `--boundary <next>` payload to stdout after successful sync (all hosts; not in crew-169's footprint)

**Cross-cutting:**

- `HostHookBindings` — per-host hook config templates + binding declarations (hosts/claude, hosts/antigravity, hosts/cursor, hosts/codex)
- `DeployIntegration` — deploy loop + FileList + **merge-aware hook-config writer** (F-161 marker discipline; user hooks never clobbered)
- `DigestDriftCheck` — test-lane parity check: digest frontmatter sources vs canonical changes → warn

## Key decisions

1. **Dispatcher generalization (human-raised):** host-level multi-registration runs hooks in parallel with NO order guarantee (Claude; others unverified) — so Specrew registers ONE dispatcher per event and owns ordering/budget/dedupe internally via an ordered, budgeted, data-driven provider registry. Future mechanisms (130-P4 handover) are registry rows — host config is never touched again. Registry deliberately minimal in v1 (no plugin framework, no dynamic discovery).
2. **Dedupe placement:** in handlers (dispatcher + runtime state), NOT the engine — engine stays pure; the slash command never dedupes.
3. **Per-session runtime state:** `(a)` per-session files keyed by host session id (from hook event JSON; per-host equivalents in research matrix). Avoids both write contention (Proposal-123 class) and cross-session suppression under the maintainer's documented multi-worktree concurrent workflow.

## Key flow (dedupe-correct B3)

```text
boundary-sync advances cursor
  -> WrapperEmission appends payload (stdout, all hosts) AND fingerprints the
     injection via engine helpers
  -> next PostToolUse on a hook host: Dispatcher -> RefocusProvider statediffs
     per-session RuntimeState -> fingerprint present -> silent
  -> if the stdout path was bypassed (sync never ran / output ignored) ->
     state-diff sees un-fingerprinted crossing -> inject now
```

## Test seams (plan obligations)

- Engine: pure invocation with fixture digests/catalog (golden payloads, budget caps)
- Dispatcher: simulated host-event JSON on stdin (per event/source; provider ordering; budget arbitration; fail-open on provider crash)
- Provider: event/source → scope routing table tests
- WrapperEmission: integration test on a scratch project
- DeployIntegration: merge-aware config-writer cases (user hooks preserved, idempotent re-deploy)
- DigestDriftCheck: source-changed-after-review warn fixtures
