# Data Storage Workshop Record

**Lens**: data-storage · **Depth**: medium · **Confirmation**: human-confirmed
**Facilitated**: one decision at a time with the human (2026-06-08).

```text
Record                     Owner        Committed?            Authoritative for resume?
------                     -----        ---------             -------------------------
Handover (.md + index)     Proposal 130 written on exit;      only after validation vs
                                        no hook commit/push   current project state
Session anchor/start-ctx   Feature 174  local-only / advisory NO if absolute-path or closed
SessionStart marker        Feature 174  local-only, no commit advisory only (unclean-exit hint)
active-session signal      Feature 174  local-only            advisory warning only
```

## Decision 1 - commit-scope + exit-hook write policy

**Chosen: refined option 3 - exit hook is WRITE-ONLY.**

- The SessionEnd hook writes the Proposal 130 handover to disk on clean exit and performs
  **no git operations** (no `git add -A`, no commit, no push) by default. We can exit
  mid-gate, so a blanket add would sweep the user's in-progress work into a hook-authored
  commit - explicitly rejected.
- Live anchor + SessionStart marker + active-session signals are **local-only and
  advisory**; never committed.
- Any residual committed session-state is **non-authoritative**: no absolute-path resume,
  cleared on merge/closeout (FR-013/014/015).
- Interactive "commit on exit? y/n" is **not supported** - SessionEnd fires non-interactively
  during teardown (FR-003). The "commit/push to continue on another machine?" choice is
  therefore **surfaced at the next bootstrap**, where the agent is interactive (ties to
  ui-ux decision 3 "unclean prior exit / uncommitted work" state), or the user commits
  manually.
- Optional opt-in config flag (e.g. `handover_commit_on_exit`, **off by default**) may let
  the hook do a scoped local commit of the handover/index only - still no `-A`, still no push.
- Cross-machine continuity stays **best-effort** (consistent with architecture-core decision 3).

## Decision 2 - freshness / staleness policy

**Chosen: option 3 - event/state-first hybrid.**

- Handover staleness is judged primarily by the **event/state checks** decided in
  architecture-core (HEAD moved past the recorded commit, feature merged/closed,
  branch/worktree non-portable, artifact mismatch). Proposal 130's wall-clock value is
  only a **secondary hint**. No new competing handover TTL is invented.
- The **active-session marker** uses a single **configurable time window** (sensible
  default, overridable) because wall-clock age is its only real signal.

## Decision 3 - project-local feature resolution + merged/closed detection

**Chosen: option 3 - project-local metadata primary + git corroboration.**

- Re-resolve the feature ref against the **current project root** - never the committed
  absolute path (FR-015).
- Judge resumability from **project-local metadata**: `specs/<ref>/` presence +
  `.squad/active-features.yml` active status + feature/iteration artifact status
  (not complete/closed).
- Use **git merged-status** as a corroborating "not resumable" signal where available
  (feature branch merged into base).
- Resumable **only if**: present locally AND active in the registry AND not closed in
  artifacts AND not merged. Otherwise clear the anchor (FR-013) and offer full bootstrap
  with a "cleared a stale anchor" reason line (ui-ux decision 3).
