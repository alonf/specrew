# Drift Log: Iteration 002

**Schema**: v1

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: 1 detected, 1 resolved (lock-vs-cross-machine semantics; spec-clarified)

## Events

### D-003 — Lock file is gitignored but US3.1 says "different machine" (RESOLVED 2026-05-31, spec-clarified)

**Detected**: 2026-05-31 at Iteration 2a planning (grounded planning workflow).

**Drift**: US3 scenario 1 (spec) detects collision when a second developer starts "from a different machine or worktree," but the session lock file `.specrew/active-sessions.yml` is per-session/**gitignored** (Key Entities + FR-005 classification), so it is not shared across machines/worktrees. A gitignored lock therefore cannot, by construction, satisfy US3.1's cross-machine case via FR-010 lock collision (nor SC-002's 2s via git). Additionally, the iter-1 per-session gitignore patterns (`.specrew/last-*`, etc.) do NOT match `active-sessions.yml`, so today the lock file would be committed — contradicting its per-session classification (FR-005 gap).

**Resolution** (spec-clarified, human-approved 2026-05-31): the **lock is intentionally local** — it catches same-machine/same-worktree concurrent starts (FR-010). **Cross-machine** coordination is delivered by the **committed, append-only-shared** feature-claims file `.squad/active-features.yml` + the Layer-1 claim warning (FR-012/FR-015). This preserves FR-043 (the rich `machine_fingerprint` stays only in the gitignored lock; the committed claim carries only the coarse `user@machine`). US3.1's "different machine" acceptance is satisfied by the **claim** path (FR-015), not lock collision (FR-010). Recorded in spec Clarifications (Session 2026-05-31). **FR-005 gap fixed in 2a (T020c):** `.specrew/active-sessions.yml` added to `$script:SpecrewPerSessionPatterns` so the lock is actually gitignored as the data-model requires.

**Why surfaced not buried**: this is the "question the dev didn't know to ask" that spec-driven development exists to expose; leaving it inside a task description would silently resolve a real architectural decision (matches the iter-1 D-002 pause discipline).

**Follow-up (non-blocking, separate chore — NOT 2a or iter-4 scope):** the recurring per-boundary auto-deploy tax (`.claude/agents/*.md` + `.squad/config.json` tracked-but-unclassified; `.specrew/last-validator-summary.json` tracked-but-not-gitignored = an FR-006 follow-up) is a standalone gitignore/classification chore, per the iter-1 retro + the ordering analysis. File separately; do not smuggle into 2a.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
