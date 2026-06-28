# Design Analysis — Feature 197 Iteration 009: Reviewer Robustness (Graceful Degradation)

**Feature**: 197-continuous-co-review
**Iteration**: 009
**Date**: 2026-06-28
**Stage**: design-analysis (co-design)

**Driver**: live downstream field evidence (EnglishIntake, a real Specrew consumer). The worktree co-reviewer is built and closes the loop on the happy path, but is field-unstable on real change-sets: large diffs time out -> "no parseable findings" -> the review-signoff gate deadlocks; `--host` is silently overridden to the code-writer host (independence defeated); the configured timeout is unenforced (`--timeout-seconds 1200` ran 1h12m+).

## Guiding principle (maintainer ruling, 2026-06-28)

> "Make it a robust feature — any review is better than nothing; the gate must never hard-deadlock."

Every review problem is a **surfaced human choice with partial findings already in hand**, never a dead end.

## Requirements (R1-R6)

- **R1** — Harvest partial findings on timeout/incomplete; never discard as "no parseable verdict".
- **R2** — Human-gated time extension.
- **R3** — Human-gated host-independence fallback.
- **R4** — Gate accepts degraded-but-honestly-labelled evidence; never deadlocks.
- **R5** — Hard timeout enforcement (the configured timeout actually kills the reviewer process-tree).
- **R6** — Human-directed review remediation menu (time / host / scope: code · process · file · function / accept / override).

## Co-design decisions (agreed one-by-one with the maintainer, 2026-06-28)

### D1 — async human-gate interaction model -> Option C (hybrid, split by information timing)

R3 host-independence is known pre-flight -> asked upfront, but the same-host review fires immediately as a **labelled fallback** so nothing blocks; the answer upgrades the next run. R2 timeout is only knowable late -> post-hoc, plus a pre-flight generous-budget heuristic for large diffs. Rationale: each ask happens at the moment its information exists; no wasted same-host run; "any review > nothing" holds even before the human answers.

### D2 — partial-findings harvest -> Option C (incremental file-append emission) + B (prose-salvage floor)

The reviewer instruction contract changes to append each finding (one JSON object per line) to a findings file in the worktree the moment it is identified, so a kill always leaves a clean prefix of complete structured findings. Prose-salvage of the reviewer's reasoning is the floor for any host that ignores incremental-flush. Structurally retires the all-or-nothing final-blob fragility behind the unparseable class (both timeout and the `claude -p` 10 MB stdin cap).

### D3 — hard timeout kill -> watchdog + process-group/job-object tree-kill + stdio-redirect + 5s graceful

Root cause: the wait kills only the immediate child and/or blocks on inherited stdout (so the watchdog never fires). Fix: redirect reviewer stdio to files (never inherit pipes); an independent watchdog fires at the deadline; kill the whole process **tree** (Unix: own process group via `setsid` + `kill -- -PGID`; Windows: Job Object / `taskkill /T /F`); SIGTERM -> **5s grace** (flush the in-flight finding from D2) -> SIGKILL. **WSL-validation is a hard acceptance gate** (standing rule: spawn/detach work is Unix-validated, not Windows-only).

### D3 refinement (2026-06-28, before-implement gate) — consolidate on the existing isolated-task supervisor

Investigation at the before-implement gate found the original iter-005 (T077) process manager is intact and IS the watchdog: `scripts/internal/agent-tasks/isolated-task-supervisor.ps1` polls `$child.HasExited` against a deadline and on timeout does `Stop-Process -Force` + an explicit process-TREE kill (cross-platform-validated by the T076 spike); the async navigator fires/reaps through `Start/Stop-SpecrewIsolatedTask`. But there is a SECOND, divergent kill: `worktree-reviewer.ps1`'s inline `Invoke-ContinuousCoReviewAgentInWorktree` runs its OWN `WaitForExit` loop + `$proc.Kill($true)` (line 369, swallowed by a bare `catch {}`). The EnglishIntake 1h12m hang was on the MANUAL `specrew review --live` path, which uses that inline kill — NOT the supervisor.

**Decision (maintainer, 2026-06-28): T091 consolidates on the supervisor.** Route the inline/manual reviewer invocation through the same launcher/supervisor process manager the async path uses, so there is ONE hardened cross-platform tree-kill, not two divergent ones. First step: **instrument the live escape** (the exact failure — un-plumbed timeout vs. swallowed `Kill` exception vs. agent-waiting-on-an-already-killed-run — is not yet proven), then unify on the supervisor and remove `worktree-reviewer.ps1`'s duplicate inline kill.

### D4 — degraded-evidence gate policy -> Option C (tiered by actual assurance)

Label every run across 3 independent dimensions: completeness (`full` | `partial`), independence (`independent` | `same-host`), budget (`normal` | `time-extended`). `full`+`independent` (any budget) -> auto-allow. `partial` OR `same-host` -> allow only with an explicit human ack, recorded as a **first-class verdict** in the evidence trail. Never deadlocks (worst case: ack). `time-extended` is NOT reduced assurance -> auto-allows.

### D5 — blocking findings from a degraded review -> Option C (block, but degraded-review block is human-overridable with a recorded reason)

A blocking finding from any review surfaces and stops advancement (never silently shipped past). `full`-review blocks follow the normal address-and-rerun flow. Degraded-review blocks are overridable with a recorded rationale (lower-confidence findings get a conscious, auditable escape). Honors never-deadlock.

## The remediation menu (R6) — the unifying surface

On any review problem (timeout / no-independent-host / degraded-or-blocking result), the navigator surfaces ONE menu at the implementer's next Stop; the choice is carried in the round-state and applied to the re-run:

```text
[co-review] review of <checkpoint> hit a problem: <reason>. Partial findings: <N>. Proceed?
  1. More time         -> rerun with a larger budget                         (R2)
  2. Different host     -> pick/authorize another reviewer host              (R3)
  3. Narrow the scope   -> rerun on a subset:                                 (R6)
        - code only   - process only   - a file <path>   - a function/symbol <name>
  4. Accept partial     -> take harvested findings as-is, labelled degraded   (R4)
  5. Override the block  -> proceed with a recorded reason (degraded only)     (D5)
```

Scope-narrowing (3) is the primary leverage: it makes a too-big review **tractable** rather than merely slower, extending the reviewer's existing user-code/subtree scoping to honor a human-directed scope.

## Mechanism -> component map (seams in the existing pipeline)

| Req | Seam (existing script) | Change |
|---|---|---|
| R1 | reviewer instruction contract + `worktree-review-orchestrator.ps1` | incremental findings-file append; harvest = read the file; prose-salvage floor |
| R5 | `worktree-reviewer.ps1` | watchdog + process-tree kill + stdio-redirect + graceful SIGTERM/SIGKILL |
| R2 | `continuous-co-review-navigator.ps1` / `specrew-co-review-navigator-provider.ps1` + orchestrator (budget) + `co-review-round-state.json` | post-hoc menu option + pre-flight budget heuristic |
| R3 | `reviewer-selection-policy.ps1` + `reviewer-authorization-gate.ps1` | pre-flight independence check; labelled same-host fallback; menu option |
| R4 | `review-signoff-evidence-gate.ps1` | 3-dimension evidence label; tiered allow/ack; recorded ack verdict |
| R6 | navigator provider (menu) + round-state (choice) + orchestrator (apply scope/host/budget on rerun) | the remediation menu + human-directed scope honoring |
| D5 | `inline-review-gate-evaluator.ps1` / signoff gate | blocking-finding block + degraded-override-with-reason |

## Co-Design Record

**Decomposition method**: extend the existing layered worktree-reviewer pipeline at named seams (no new architecture); each requirement maps to one or two existing scripts (table above). Agreed with the maintainer.

**Component-to-responsibility map (agreed)**:

- **worktree-reviewer.ps1** — owns the hard timeout: watchdog, process-tree kill, stdio redirect, graceful flush window (R5).
- **worktree-review-orchestrator.ps1** — owns partial-findings harvest from the incremental findings-file + run evidence labelling (R1, R4 input).
- **reviewer instruction contract** — owns incremental finding emission (R1).
- **reviewer-selection-policy.ps1 + reviewer-authorization-gate.ps1** — own the pre-flight independence check + labelled same-host fallback (R3).
- **continuous-co-review-navigator.ps1 / specrew-co-review-navigator-provider.ps1** — own the remediation-menu surface at Stop (R2/R3/R6/accept/override).
- **co-review-round-state.json** — carries the human's remediation choice (budget / host / scope / accept / override) to the next run.
- **review-signoff-evidence-gate.ps1** — owns the tiered degraded-evidence policy + recorded ack verdict (R4) and the degraded-block override (D5).

**Agreed flow (review-hits-a-problem)**:

implementer Stop -> navigator fires detached review -> reviewer hard-times-out (R5 watchdog kills the tree after the 5s grace) -> orchestrator harvests partial findings from the incremental file (R1) and labels the run `partial` (R4) -> reap -> navigator surfaces the remediation menu at the next Stop (R6: more time / host / **narrow scope** / accept / override) -> human picks "code only" -> round-state records the scope -> next run reviews only the code subset -> completes `full` on the narrowed scope -> gate auto-allows.

**Human-agreed**: ✅ Maintainer (Alon Fliess) co-designed and agreed D1-D5 + R6 one-by-one in the 2026-06-28 design-analysis conversation.
