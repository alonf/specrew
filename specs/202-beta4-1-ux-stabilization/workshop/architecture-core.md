# Lens: architecture-core (light)

**Feature**: 202-beta4-1-ux-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-13. Receipt `2b8d17ceb0618e3ecd912aa2af1c385296baa8d3e9cebdc0fe421b0a9ab88719`.
**Question**: where each Tier 1 fix lives, so Claude, Codex and Copilot cannot diverge again (B4F-107, B4F-108, B4F-096).

## Turn path (as understood; diagram corrected by the maintainer)

The diagram was drawn from runtime records and hook messages, not from the engine source. The maintainer corrected the store paths.

```
  Claude hooks        Codex hooks        Copilot hooks
       |                   |                  |
       v                   v                  v
  +---------------------------------------------------+
  |  host adapters: INPUT normalization -> standard   |
  |  turn record {event, typed user text, host} under |
  |  a declared, tested contract; OUTPUT emission of  |
  |  shared text as-is. No wording, values or         |
  |  reply-counting decisions.                        |
  +---------------------------------------------------+
                          |
                          v
  +---------------------------------------------------+
  |  shared hook dispatcher (writes                   |
  |  hook-output-authority.jsonl.unhealthy on a       |
  |  journal append failure: B4F-108)                 |
  +---------------------------------------------------+
        |              |               |            |
        v              v               v            v
  conformance /   workshop-authority  orientation /  status /
  Stop decisions  store (receipts)    adaptation     dashboard
  (B4F-104/106/   (B4F-108)           text           (B4F-105)
   096/100)                           (B4F-107/096)
        |              |               |            |
        v              v               v            v
  .specrew/runtime/          .specrew/runtime/workshop-authority.jsonl (receipts)
  conformance-*, hook-       .specrew/handover/workshop-question.json (question record)
  output-authority.jsonl     .specrew/start-context.json, handover
```

## Decisions

1. **Placement rule (amended).** Content and decisions are made once, in the shared path. Adapters own host mechanics on both sides:
   - **Input normalization:** each adapter converts its host's payload into a standard turn record (event, typed user text, host) under a declared, tested contract.
   - **Output emission:** event names, payload shape, and getting shared text to the screen unchanged.

   An adapter never chooses wording or values, and never decides whether a reply counts. For B4F-107, the fix is one shared text that every adapter emits as-is.
2. **Decomposition style.** Keep the existing layered hook structure (adapters, dispatcher, shared engines, stores). No new method and no new components; this is consistent with skipping component-design.
3. **Structural done-ness (amended).**
   - **Cross-host test.** It runs through each host's real adapter, using recorded real hook payloads from Claude, Codex and Copilot as fixtures. It never calls into the shared path directly.
   - **B4F-108 fault-injection test.** Force a journal-lock collision, then assert three things: capture recovers, the degraded state is disclosed, and hook output still cannot count as a human reply.

## Out of scope

Any redesign of the hook dispatcher or stores, and everything in Tier 2.

## Bindings

- `fix-placement`: `shared-path-adapter-mechanics-only`
- `adapter-input-contract`: `standard-turn-record-tested`
- `decomposition-style`: `existing-layered-hooks`
- `cross-host-test-entry`: `real-adapter-recorded-payloads`
- `b4f108-fault-injection`: `required`
