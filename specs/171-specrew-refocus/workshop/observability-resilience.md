# Workshop Record — observability-resilience (Lens 7, medium)

**Feature**: 171-specrew-refocus
**Date**: 2026-06-06
**Confirmation**: human-confirmed (journal + reason codes agreed; rest bound through lenses 3/6)

## Bound earlier, recorded here for the lens's coverage map

- Fail-open (P1) + exactly-once (P2) + token budget (P3) + latency (P4) — requirements-nfr record
- Circuit breaker semantics + kill-switch levels + `--status` — devops-operations record
- Banner + WARN envelope — integration-api record (C1)

## New decisions (this lens)

### Injection journal (agreed)

Extend the per-session state file with a bounded journal — last ~20 injections, each:

```text
{at, trigger, scope, channel, tokens, outcome}
outcome ∈ injected | deduped | budget-clipped | breaker-suppressed | failed
```

- `--status` prints the tail
- Survives compaction (on disk, not in context) — the post-hoc "did B1 fire after that compaction?" question has a disk answer, not a scrollback answer
- Beta validation + dogfooding reports cite journal entries as evidence

### Enumerated WARN reason codes (agreed)

```text
EVENT_PARSE        host event JSON unreadable        -> host changed? research matrix
CATALOG_SCHEMA     schema_version mismatch           -> engine/catalog version skew
SOURCE_MISSING     digest/canonical file absent      -> run specrew update
SOURCE_CONFINED    catalog path escaped the repo     -> tampered/bad catalog
STATE_UNAVAILABLE  dedupe state unreadable           -> automation quiet (by design)
BUDGET_EXCEEDED    payload clipped to cap            -> catalog budget review
BREAKER_TRIPPED    auto-disabled this session        -> see trip message
PROVIDER_FAILED    a registry provider crashed       -> that provider skipped
```

### Failure trace (agreed — every branch ends in ONE named action)

```text
"refocus seems dead this session"
   -> refocus.ps1 --status
        breaker tripped?  --yes--> journal shows BREAKER_TRIPPED + reason
        env var set?      --yes--> unset it (someone killed it earlier)
        trigger disabled? --yes--> catalog enabled: false + date
        all green?        ------> journal tail: deduped? budget-clipped?
                                   nothing at all? -> hook not registered ->
                                   settings.local.json -> re-run specrew update
```

## Review-evidence rule (binding)

Every runtime claim in this feature's review cites journal entries or live-host evidence — never file presence.
