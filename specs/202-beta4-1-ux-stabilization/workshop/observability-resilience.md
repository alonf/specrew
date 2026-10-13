# Lens: observability-resilience (medium)

**Feature**: 202-beta4-1-ux-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-13. Receipt `7764a2c3530b0cd7de538b20ef347fea527c27341f5dc0563d9d9a0e4fe28721`.
**Question**: how a hook-output journal write failure recovers instead of latching, and how a degraded state is disclosed (B4F-108).

## Health lifecycle of the hook-output journal (agreed, with amendments)

```
 TODAY                                   AGREED
 -----                                   ------
 append fails once                       concurrent appends PERMITTED by the write path
 (FileShare.Read guarantees a            (compatible share mode or per-write cross-process
  concurrent append fails)                lock) -> the production trigger cannot occur
      |                                       |
      v                                       v  (append still fails for another reason)
 write .unhealthy  (forever)             bounded retry in-hook (backup, not the fix)
      |                                       |-- succeeds --> HEALTHY (nothing shown)
      v                                       |
 every reply = "hook output"             still failing --> DEGRADED
 no receipt, no disclosure                    |   health journal: class, error, first-seen, count
 (silent, 2026-09-09 -> 2026-10-13)           |   disclose SAME turn: what happened, whether
                                              |   the turn was consumed, what the system is doing
                                              |
                                              |-- next successful append --> HEALTHY
                                              |       record recovered-at (self-clearing)
                                              |
                                              '-- still degraded after self-recovery
                                                      --> ask ONE decision
                                                          ("may I move this marker aside?")

 MIGRATION: a marker left by an older version = an ordinary DEGRADED state,
            cleared by the next successful append.
```

## Decisions

1. **Error classes, with prevention first (amended).** The dispatcher opens the journal with `FileShare.Read`, so a concurrent append is guaranteed to fail. Concurrent writers are a normal condition: several hosts or sessions write the same journal. The write path must therefore permit them, either through a compatible share mode or through a cross-process lock held per write. A bounded in-hook retry stays as a backup. A failure that persists after the retry is exceptional (access denied, full disk, corrupt file), and only that kind enters the degraded state.
2. **Lifetime of the degraded state: self-clearing, with a migration (amended).** The next successful append ends the degraded state and records the recovery time. A marker that only a human can clear is used solely when self-recovery fails, and even then the system asks one decision, not a diagnosis. **Migration:** a marker left by an older version is treated as an ordinary degraded state and clears on the next successful append, so the bug does not survive the upgrade on existing installs.
3. **Disclosure in all three places.** (a) The affected prompt turn, in that same turn, saying whether the reply was consumed. (b) `specrew status` / `where`, as a health line shown only while degraded. (c) Session-start orientation, because a degraded state counts as an external state change and therefore a context gap.
4. **Logging.** A health journal with one record per transition: failure class, error text, first-seen, count and recovered-at. No user text, only hashes. **Handed to the security lens:** buffer any hook output that could not be journaled, and write it to the journal on recovery, so the integrity check stays complete across the outage window.
5. **Fault-injection test, through a real adapter with a recorded payload.**
   - (a) A lock released within the retry window: the reply is captured normally and nothing is disclosed.
   - (b) A lock held beyond the window: the state becomes degraded and is disclosed in the same turn, including whether the turn was consumed.
   - (c) After release: the next turn records recovery and a receipt is minted.
   - (d) Throughout, hook output is never counted as a human reply.
   - **(e) Added: two real hook processes append at the same time, both succeed, and nothing degrades. This is the actual production trigger.**

   The retry window and attempt count are tuning values left to the plan.

## Bindings

- `journal-concurrency`: `concurrent-appends-permitted`
- `journal-retry`: `bounded-backup-only`
- `degraded-lifetime`: `self-clearing-on-next-append`
- `legacy-marker-migration`: `treat-as-degraded-self-clear`
- `degraded-disclosure`: `turn-status-orientation`
- `health-journal`: `transition-records-hashes-only`
- `b4f108-fault-injection`: `required` (unchanged from architecture-core; cases a-e)
