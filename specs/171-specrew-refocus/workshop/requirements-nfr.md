# Workshop Record — requirements-nfr (Lens 3, medium)

**Feature**: 171-specrew-refocus
**Date**: 2026-06-06
**Confirmation**: human-confirmed (whole table agreed in one pass; P4 risk explicitly surfaced before agreement)

## Agreed quality-attribute priorities + measurable bars

```text
P1  Fail-open reliability        A trigger failure NEVER blocks or breaks a session.
                                 Bar: fault-injection suite (missing catalog, corrupt
                                 digest, locked state file, dead provider) -> session
                                 continues + exactly one visible warning line; hook
                                 exit codes never block. Zero tolerated exceptions.

P2  Injection correctness        Every boundary crossing -> exactly ONE injection
    (exactly-once)               across both channels (stdout + hook); compaction ->
                                 exactly one B1; no duplicates, no silent misses.
                                 Bar: simulated lifecycle run asserts
                                 injections == crossings; dedupe fixtures for the
                                 stdout-then-hook and hook-only paths.

P3  Token economy                Injections are overhead; size is capped by catalog.
                                 Bars: general.md <= ~600 tokens; each stage digest
                                 <= ~1,500; B2 launch pointer set <= ~1,200;
                                 B1/B3 composed payload <= ~2,500; banner reports
                                 actual estimate; size tests enforce digest caps.

P4  Trigger latency              B2 path (every launch): dispatcher end-to-end
                                 <= 1s. B3 check path (fires per tool call on hook
                                 hosts): added latency <= 150ms p95 — met via
                                 matcher narrowing (shell tools only) + stat-first
                                 cheap guard + early exit; pwsh spawn cost is the
                                 honest risk and gets MEASURED during implementation,
                                 not assumed.

P5  Maintainability currency     Digest drift parity warn when a declared canonical
                                 source changes; catalog schema check at deploy;
                                 mirror parity (132 discipline).
```

## Refuse-to-do register (agreed)

- Never block a session for any refocus reason
- Never exceed catalog budget caps
- Never clobber user-authored hook config
- Never dedupe a HUMAN-invoked `/specrew-refocus` (a human asking always gets payload)
- Never inject anything beyond methodology text + `file:///` pointers (no secrets, no environment values)

## Notes

- P4 surfaced as the honest risk: per-tool-call pwsh spawn cost on the B3 hook path. The bar (<=150ms p95) forces matcher narrowing + stat-first guard + early exit; if implementation measurement shows the bar unreachable, the fallback design is B3-via-channel-1-only on that host (channel 1 already covers B3 everywhere) — that decision returns to the human with data, not silently.
- These bars become SCs in spec.md; review must prove each with execution evidence (P1 fault-injection, P2 simulated lifecycle counts, P3 size tests, P4 measurements), not file presence.
