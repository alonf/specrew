# Architecture Core Lens — iter-008 reviewer-context redesign

## Lens

architecture-core (full). Reuses F-197's modular contract-and-gate CCR architecture + one bounded
fresh-context read-only reviewer per run; reopens F-197 decision-agenda line 13 ("how is the review context
packaged and bounded?").

## Decision agenda (raised)

- Context-delivery model: curated-diff-in-prompt vs worktree-the-reviewer-reads.
- Worktree contents: what is stripped vs kept.
- Reviewed-state identity + the dispatcher's 20s Stop budget.
- What is out of scope for this iteration.

## Agreed direction (human-confirmed)

**Worktree-based context delivery.** The reviewer runs in a `git`-tree worktree of the *project* and READS the
real files; the change-set is the entry point, not the review payload.

```text
  Stop hook  (FAST, <1s — JUST a trigger; never the constraint)
    └─ implement checkpoint? → spawn DETACHED review process → return immediately

  DETACHED process  (async, non-blocking, GENEROUS budget — scale to the change, minutes if huge)
    1. identity + dedup        (already reviewed this exact state? → exit)
    2. WORKTREE = git tree of the project, MINUS the methodology's deployed machinery
                               (.specrew /.specify /.squad + deployed scripts/internal/continuous-co-review,
                               agent-tasks)  —  node_modules/dist/build = gitignored → already absent
    3. write .review/changes.diff  (entry point: what changed)  +  .review/design/*  (spec, design-analysis)
    4. reviewer (claude -p): SLIM prompt → reads the diff + BROWSES the real files → FindingsResult
    5. verdict surfaces on the next Stop (reap)
```

**Decisions:**

1. **Context-delivery = worktree-based.** Reviewer reads real files; `.review/changes.diff` is the entry point;
   design context written as files under `.review/design/`; the prompt is slim (instruction + pointers).
2. **Worktree strip = the methodology's KNOWN deployed machinery only** (deploy-manifest-derived, NOT a
   heuristic): `.specrew`, `.specify`, `.squad`, and the deployed runtime under `scripts/internal/`
   (`continuous-co-review`, `agent-tasks`). Everything the developer authored is KEPT (`.github`, `.claude`,
   `.cursor`, `.vscode`, `specs/`, all source). `node_modules`/build dirs need no rule — gitignored, so a
   git-tree worktree excludes them (this is also where the 50s digest cost came from: it was force-adding them).
   Replaces the fragile scaffolding-exclusion/denylist heuristics with a known list.
3. **No 20s cap on the review.** The 20s is only the Stop-hook's don't-hang-the-human budget; it was never meant
   to bound the review. ALL heavy work (identity/dedup, materialize, diff, the review itself) moves to the
   DETACHED async process with a generous budget scaled to the change. The Stop hook only triggers (<1s). A huge
   change gets a full, untimed review — never skipped, never blocking.
4. **Nothing out of scope by fiat.** "Done" = the whole co-reviewer working end-to-end. The context-flow redesign
   is the centerpiece; gate / host-selection / authorization are CHECKED against what already exists (F-197 +
   this session) and FIXED or COMPLETED — not assumed, not excluded.

Human verdict: "OK, agreed."
