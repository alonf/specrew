# Iteration State: 007 — real-reviewer wiring + nested-project + deploy-completeness

**Schema**: v1
**Current Phase**: abandoned
**Iteration Status**: abandoned
**Last Completed Task**: iter-007 post-hoc T094 (Pester v4→v5.5 migration) — see the task-ID collision note below
**Tasks Remaining**: (none — pivoted to 008; delivered fixes carried forward)
**In Progress**: (none)
**Baseline Ref**: 49f887174c4a668ece3aaede6ca0910741e085c3
**Updated**: 2026-06-26

## Abandonment Reason

- **Status set to `abandoned`** (recorded 2026-06-26; canonical state fields added 2026-07-01 for governance completeness). Iteration 007 ran as an exploratory drive-the-real-path iteration and **pivoted to iteration 008 before running its own review/retro/signoff cycle** — no review-signoff verdict, no Task Verdicts table, and no retro were recorded. It is `abandoned` (its cycle did not complete) rather than `complete` because authoring those now would fabricate governance that never happened (the 2026-06-24 anti-fabrication ruling). Its DELIVERED fixes are live and were carried forward into 008/009: subtree-scoped change-set diff (`81b7070e`), scaffolding-exclusion + large-diff cap + adapter input-size guard + diagnostics (`85c12930`), deploy-completeness (`49f88717`), and the Pester v4→v5.5 migration. The reviewer-context flow was found architecturally fragile (see below) — the finding that justified the pivot.

## Governance note (2026-07-01) — task-ID collision (flagged, resolution pending)

iter-007's plan.md (a post-hoc reconstruction, commit `4a5ebb05`) labels its delivered work **T091–T095**, which COLLIDES with iteration 009's canonical, commit-cited **T090–T098** (e.g. T091 hard-timeout, T093 host-fallback, T094 degraded-gate). The delivered work is unaffected; only the labels collide. Resolution — renumber iter-007's post-hoc IDs to a free range — is flagged for a maintainer decision, mirroring the iter-009 T095 resolution of the earlier T083–T085 collision.

## What this iteration delivered

Wiring the REAL reviewer so continuous co-review actually reviews real code on a real (deployed) project, found and fixed by driving the live detached navigator→supervisor→reviewer→reap path on a dogfood project (EnglishIntake, a nested Specrew root in the iTeach-Avatar monorepo):

- **Subtree-scoped change-set diff** (`81b7070e`) — a nested governance root now scopes git ops to its own subtree (1-of-706 hollow diff → the real change-set).
- **Scaffolding exclusion + large-diff cap + adapter input-size guard + state-the-reason diagnostics** (`85c12930`) — the reviewer reviews user-authored code, not Specrew/host-deployed scaffolding; confirmed root cause of the prior "unparseable verdict" by instrument = `claude -p`'s hard 10 MB piped-stdin cap.
- **Deploy-completeness** (`49f88717`) — the co-review feature was INERT on every deployed project (source-layout assumptions): the contract resolver hardcoded the source layout, and the deploy shipped the co-review scripts but not the isolated-task launcher (`agent-tasks/`) or `atomic-write.ps1`. Both fixed; deploy validated by running it into a clean target (deployed runtime loads + can fire).
- **Pester v4→v5.5.0 migration** (`85c12930`) — the test suite was implicitly v4-pinned (green-but-inert risk); 44 CCR files migrated, count-parity verified (263→275, 0 drops).

Real result: a real claude review returned `kind=findings-result` with 5 substantive findings on EnglishIntake's .NET backend, including a BLOCKING one tracing a workshop design decision (`Program.cs` missing UseExceptionHandler vs the code-implementation idiomatic-error-handling rule).

## Why it pivots to iter-008 (the architectural finding)

Driving the real path surfaced that the reviewer-CONTEXT flow is architecturally fragile, and the worktree is materialized-but-unused:

- The reviewer (`claude -p`) reviews a **curated diff crammed into the prompt** — a fragile heuristic (the scaffolding exclusion) literally defines the review scope, and nothing guarantees that heuristic is right or that the reviewer doesn't need excluded artifacts.
- The instruction's visibility policy tells the reviewer to read **only the composed prompt** — so the materialized worktree (a `git archive` of the reviewed-state tree-id) is a read-only sandbox the reviewer never browses. Materializing it (e.g. a 6,359-file `node_modules`) costs ~50 s — which blows the dispatcher's 20 s provider budget so the navigator is skipped entirely (the "no review" symptom on a large project).

So the worktree promise ("clean checkout the reviewer sees") is NOT how it actually works. iter-008 redesigns the reviewer-context flow to the worktree-based model: the reviewer sees the project files (strip only governance noise), reads the diff/changed-list as an entry point (diff-as-file, no stdin cap), removing the fragile diff-exclusion heuristics. See iter-008 design-analysis. The co-review gate stays OPT-IN until that lands.
