# iter-008 Design Analysis — reviewer-context redesign (worktree-based)

## Summary

Redesign the continuous co-reviewer's CONTEXT flow from the fragile "heuristic-curated diff crammed into the
prompt + materialized-but-unused worktree" to a **worktree-based, agentic, async** model: the reviewer is a
trusted agent that runs in an ephemeral read-only-source worktree of the project, **sees all and runs all**
(reads files, runs tests/builds to verify), reads `.review/changes.diff` as its entry point, and emits a
FindingsResult — it **cannot fix** the source. All heavy work moves off the 20 s Stop budget into a detached
async process. The fragile exclusion heuristics + diff cap are removed.

## Co-Design Record (human-agreed)

**Decomposition / method:** keep F-197's modular contract-and-gate CCR architecture; one bounded fresh-context
reviewer per run. (architecture-core)

**Component map (agreed change-impact):**
- SURVIVES: reap, review-blackboard-writer, review-signoff-evidence-gate, reviewer-host adapters,
  reviewer-host-catalog + authorization.
- CHANGES: continuous-co-review-navigator (Stop-path → trigger only), isolated-task worktree-materialize
  (strip the methodology machinery; build from git tree; write `.review/`), reviewed-state-digest (moves into
  the detached process; drop the gitignored force-add), checkpoint-diff-provider (emit `.review/changes.diff`),
  review-prompt-composer (SLIM), code-review-agent.md (visibility: see-all/run-all), reviewer-execution-engine
  (agentic, cwd = worktree).
- NEW: detached "prepare+review" orchestrator (the heavy pipeline off the Stop budget); `.review/` assembler.
- REMOVED: `Get-ContinuousCoReviewDefaultExcludedPathPatterns` + exclusion threading; diff byte-cap + adapter
  input-size guard.

**Agreed flow (two doors, one pipeline, with rounds + result-delivery):**
```text
  [auto Stop-trigger]  OR  [/specrew-review]      (both → the SAME detached pipeline)
        ▼
  DETACHED prepare+review  (round r of N = co_review_max_rounds, default 2, configurable)
     identity/dedup → stripped read-only worktree → write .review/changes.diff + .review/design/*
        → agentic reviewer (claude -p/codex, read+run tools, slim prompt) → FindingsResult
        ▼
  RESULT DELIVERY  (human-gated: next Stop / "continue" / `specrew review --status`)
     ├─ pass                → done
     ├─ blocking AND r < N  → stop-block drives the code-writer agent to FIX → re-trigger round r+1
     └─ blocking AND r == N → ESCALATE to human
```

**Security boundary (human-agreed):** the reviewer is a fully-trusted component — SEES ALL (no confidentiality
blinding), RUNS ALL (executes tests/builds in the ephemeral worktree to verify), in a read-only-source worktree
that is discarded after; the ONLY restriction is it CANNOT FIX the code. Durable artifacts redact secret values
to location. Methodology machinery stripped for relevance, not secrecy.

**Worktree strip set (known, NOT a heuristic):** `.specrew`, `.specify`, `.squad`, `.git`, + the deployed runtime
under `scripts/internal/` (`continuous-co-review`, `agent-tasks`). `node_modules`/build = gitignored → absent.

**Process/progress review (added — human-confirmed).** The reviewer reviews BOTH design conformance AND
process/progress conformance: does the increment implement the claimed task (trace to tasks.md), stay on-plan,
record drift where it diverged, keep tasks-progress/state HONEST, and fit the current phase? It gets a CURATED
process context under `.review/process/` — the active feature/iteration/phase + snapshots of tasks/plan/
tasks-progress/drift/state — distilled from `specs/` + the `.specrew` boundary CURSOR, NOT the raw stripped
`.specrew` tree (which is noisy tool bookkeeping). The process/plan/tasks RECORD lives in `specs/` (kept in the
worktree); only the runtime bookkeeping is stripped. Runtime-governance POLICING (was the boundary authorized,
gate freshness) stays the GATES' job, not the reviewer's.

**MCP-readiness (host-neutral service — added, human-requested).** The co-review capabilities are NOT
Claude-Stop-hook-bound: they live in a HOST-NEUTRAL SERVICE (`co-review-service.ps1`) with TWO peer consumers —
the Claude Stop-hook navigator (today) and a future MCP server (any MCP host, tomorrow). The Stop-hook navigator
is just the FIRST consumer, not the architecture. The service surface (each returns structured data; the host
integration — stop-block / inject-note / an MCP tool result — is the consumer's job):
- `Start-ContinuousCoReviewServiceRun` (trigger a review of the committed state; `-Detached`) → MCP `trigger_review`
- `Get-ContinuousCoReviewServiceStatus` (a run's lifecycle status, or all pending) → MCP `get_review_status`
- `Get-ContinuousCoReviewServiceFindings` (a run's FindingsResult — the durable inline thread) → MCP `get_review_findings`
- `Invoke-ContinuousCoReviewServiceAsk` (a follow-up question — re-materialize the worktree + re-invoke the
  agentic host with the prior findings, via the SHARED `Invoke-ContinuousCoReviewAgentInWorktree`) → MCP `ask_reviewer`

The reviewer's durable data (`.specrew/review/inline/<run-id>/`) is the MCP resource. The MCP server is then a
THIN wrapper (a small process mapping the 4 functions to MCP tools + the inline dir to a resource). The SMALL
REFACTOR done now — extract the facade + the shared agent-in-worktree invocation (reused by review AND ask) — is
what makes building the MCP later easy; nothing in the pipeline assumes the Claude host.

Human-agreed: lens-by-lens confirmation recorded in `iterations/008/lens-applicability.json`.

## Gaps this iteration must close (trace targets)

From the current `/specrew-review` test (`iterations/008/specrew-review-current-gaps.md`): **G1** no
auto-resolution, **G2** in-place no-sandbox, **G3** synchronous/blocking, **G4** own source-layout contract
resolution, **G5** not deployed, **G6** shares the fragile diff model. Plus the navigator's **20 s-timeout
skip** (the digest's gitignored force-add) and the **worktree-cleanup debris**.

## Cross-lens resolutions (pinned before coding — advisor guardrails)

- **Reviewed-state identity (the hardest-to-reverse piece).** The digest serves THREE jobs at once: the worktree
  tree-id, the dedup key, AND the signoff-gate freshness proof. Keep it UNIFIED — one content-addressed tree-id
  is all three. The fix is the COMPUTATION, not the role: subtree-scope it (nested projects), strip the machinery
  set, and do NOT force-add gitignored package dirs (node_modules — the 50s bug). Identity = the user's reviewed
  SOURCE. The gate keeps working because the same (now-correct) tree-id is the freshness proof. (Digest SURVIVES,
  fixed — not "dropped".)
- **"Run all" vs node_modules-absent.** The worktree is the git tree of the machinery-stripped source (no
  node_modules → fast materialize, clean identity). "Run all" = the reviewer is an AGENT that MAY install deps and
  run in its EPHEMERAL sandbox if it judges a run worth the cost in its async budget; the system does NOT
  pre-provision deps. So run is best-effort-by-the-agent, not guaranteed-provisioned — the worktree stays fast and
  the identity stays source-only.
- **Single-source the machinery-strip set (the actual de-fragilization).** ONE constant/function defines "the
  methodology's deployed machinery" (.specrew/.specify/.squad/.git + deployed scripts/internal/continuous-co-review,
  agent-tasks), consumed by BOTH the worktree-strip AND the digest exclusion, aligned with Specrew.psd1's FileList.
  No second/third/fourth hardcoded array — else the redesign rebuilds the fragility it deletes.
  - **EMPIRICAL REFINEMENT (validated on EnglishIntake, 2026-06-26).** Baseline was already correct
    (`da289be8` = merge-base with trunk). The strip set, though, is genuinely hard to single-source from a
    *deployed* project: Specrew marks its deployed content INCONSISTENTLY (`.../skills` + `.../rules` carry
    `.specrew-managed`; `.../agents` + `.../prompts` do not; some are symlinks, some plain files). So pure
    marker-detection is incomplete on an existing project. `Get-ContinuousCoReviewMachineryPaths -RepoRoot`
    therefore unions THREE signals: (a) core methodology dirs + host-instruction files (known), (b) `.specrew-managed`
    marker dirs (self-describing), (c) the agent-framework mirror subdirs (agents/skills/commands/chatmodes/
    prompts/rules) under the AI-host dirs (a stable agent-tooling VOCABULARY, not a per-path guess; user config
    like workflows/settings is never one of them). This took EnglishIntake's change-set 385 → 168 files
    (user code + design + the user's own project config). **The DURABLE single-source is to fix the deploy to
    mark ALL deployed content with `.specrew-managed`** — then (b) alone suffices and (c) retires. Tracked as a
    broader-implementation deploy sub-task.

## Build order (advisor): NEW alongside OLD; first STOP = one real verdict

The curated-diff path WORKS today (EnglishIntake produces real verdicts). Stand the new worktree pipeline up
ALONGSIDE it, prove it on one real fire, then cut over — and delete the heuristics (item 5) LAST. First review
stop = the thinnest worktree-based agentic review producing a real FindingsResult on EnglishIntake.

## Implementation outline (→ plan/tasks)

1. **Detached pipeline + fast trigger** — shrink the navigator Stop-path to a trigger; move identity/dedup +
   materialize + diff + review into the detached process (no 20 s bound). [navigator timeout, G3]
2. **Worktree-strip + materialize** — build the worktree from the git tree minus the known machinery set;
   airtight ephemeral dispose. [worktree debris]
3. **`.review/` assembler + slim prompt** — write `changes.diff` + design files into the worktree; slim prompt
   pointing at them. [G6, the 10 MB cap]
4. **Agentic reviewer + visibility policy** — reviewer reads+runs in the worktree; rewrite code-review-agent.md
   visibility policy (see-all/run-all/cant-fix). [security]
5. **Remove the heuristics** — delete the scaffolding-exclusion + diff cap/input-guard. [G6]
6. **Shared contract/host/design-context resolution** — one deploy-aware resolver; auto-resolve host +
   design-context for BOTH doors. [G1, G4]
7. **`specrew-review` refactor** — make `/specrew-review --live` a second door into the same detached pipeline;
   deploy it. [G2, G3, G5]
8. **Configurable rounds** — `co_review_max_rounds` (default 2) drives the review→fix→re-review→escalate loop.
9. **Result-delivery** — keep/verify the human-gated status ("continue" / `--status`) + the fix-after-blocking loop.
10. **Tests + deploy-completeness** — Pester 5.5; deployed-and-fires smoke test; greenfield validation.
