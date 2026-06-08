# Architecture Core Workshop Record

**Lens**: architecture-core · **Depth**: full · **Confirmation**: human-confirmed
**Facilitated**: one decision at a time with the human (2026-06-08).

```text
1. Read handover (index + .md) FIRST
        |
        +-- recent AND validated against current project state -> primary resume context
        +-- missing / stale / invalid / mismatched -> historical context only, or ignore
        |
        v
2. Evaluate session anchor
        |
        +-- project-local, active, fresh, not merged/closed -> light welcome-back / resume
        +-- invalid / stale / merged / closed / non-portable -> clear, then full bootstrap menu
        |
        v
3. Agent renders visible orientation + Resume / New / Pick-feature menu
```

## Decision 1 - `specrew start` vs hook division of labor

**Chosen: Option 2 - launcher preface + hook bootstrap.** `specrew start` may render a
short preface or host-selection confirmation, but the SessionStart hook is the
**only** full orientation and Resume / New / Pick-feature bootstrap source. The
launcher stays useful (host selection, flag pass-through, explicit launch flows)
without being the real bootstrap owner; this minimizes duplicate-state risk vs a
shared-bootstrap model.

## Decision 2 - B2 classification: handover-first, two-stage

Classification is **not** anchor-first. Order:

1. **Read handover first.** If a handover index/`.md` exists and is recent, surface
   the last SessionEnd message + recommended next step as the primary resume context.
2. **Validate handover against current project state - recency is necessary but not
   sufficient.** Required checks before treating handover as authoritative resume:
   - feature exists locally or can be resolved project-locally;
   - feature is not merged/closed;
   - referenced branch/worktree is portable or re-resolved;
   - boundary/iteration/task state is consistent with on-disk artifacts;
   - recorded commit is reachable or explainably absent.
   Valid -> resume context. Mismatch -> not authoritative; clear/fallback.
3. **Then evaluate the session anchor.** Full bootstrap when there is no valid active
   anchor, or it is stale / merged / closed / missing / non-portable. Light
   welcome-back only when the anchor is project-local, active, fresh, and not
   merged/closed. Any absolute path to a different worktree is untrusted and must be
   re-resolved from project-local metadata before it can count as valid.

This reinforces the original failure case: even a fresh handover cannot override a
project state that says the feature is closed or non-portable (the merged Feature 171
stale-recovery incident).

## Decision 3 - concurrency posture: advisory only, no locks

- **No lock/lease baseline.** Locks require housekeeping; a session that dies without
  a SessionEnd hook leaves the lock stuck. Rejected.
- Detect local concurrent-session signals only as **advisory** state, from existing
  active-session / handover / journal metadata with freshness checks.
- If the prior session emitted no SessionEnd, stale local metadata degrades to a
  warning or is ignored after freshness expiry - it never blocks bootstrap.
- Cross-machine concurrent work on the same feature is **best-effort warning only**
  (from shared metadata or normal git conflict detection); no global prevention.
  A real distributed lease/coordination mechanism is a separate future proposal
  (remote state, identity, leases, expiry, permissions, conflict policy) and would
  violate this feature's thin-synthesis scope.

## Decision 4 - decomposition style

**IDesign volatility-based decomposition.** Isolate the volatile parts behind stable
engines:

- **Volatile (adapters)**: host hook event payloads, structured-picker behavior,
  handover file/index shape if Proposal 130 varies.
- **Stable (engines)**: session classification, handover precedence, current-project-
  state validation, stale-anchor clearing, bootstrap directive construction.
- **Existing manager**: F-171 dispatcher / deploy loop (reused, unchanged).

## Out-of-scope boundaries (recorded)

- B1 post-compaction behavior unchanged from F-171.
- B3 boundary-cross behavior unchanged from F-171.
- B4 pre-compaction capture deferred.
- Antigravity hook binding deferred.
- Distributed multi-developer same-feature **prevention** deferred to a future proposal.
- No lock semantics; advisory freshness-based detection only.
- Handover/anchor validation MUST analyze current project state before treating any
  state as resumable.

## Spec impact to carry into clarify / plan

- New requirement: B2 checks a recent **validated** handover before anchor classification.
- New requirement: local same-worktree active-session conflicts are detected and surfaced (advisory, non-blocking).
- New assumption / out-of-scope note: cross-machine concurrent work cannot be prevented by hook bootstrap alone.
