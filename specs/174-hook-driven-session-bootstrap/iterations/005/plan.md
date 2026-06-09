# Iteration Plan: 005

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 10/20 story_points
**Started**: 2026-06-09
**Completed**:

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity `<consumed>/<cap> <unit>`. Task Status one of
  planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Scope Summary

Iteration 005 fixes the **hollow-handover** greenfield finding (Finding 3): the rolling
`session-handover.md` body shipped as a hook-written placeholder because the Stop hook is
TRANSCRIPT-BLIND and cannot author rich content. Iter-5 makes the body **agent-authored** ("packet =
handover") and adds a **mechanical detector** so a hollow body is caught automatically, not only by
manual dogfood (maintainer carry `f174-i005-mechanical-detector-in-scope`).

**Two failure modes, scoped honestly (mechanism-not-pledge, per iteration-004 improvement-action-4):**

- **A — plumbing (FULLY mechanical, CI-blocking).** The Stop hook PRESERVES the agent body (never
  clobbers), writing the placeholder ONLY when none exists; the bootstrap SURFACES the rich body on
  resume; the file round-trips. A test floor blocks regressions in CI. This is the strong part.
- **B — the agent never authors a rich body (IRREDUCIBLY behavioral).** Only the agent has the
  transcript, so authoring CANNOT be automated — this is the ceiling transcript-blindness imposes, not
  a defect. Best achievable, and all this iteration claims for B:
  1. **the protocol** — author the body via `Write-SpecrewHandoverContext`, then render the boundary
     packet by reading it BACK, so what the human sees == what the next session inherits;
  2. **detection** — `Test-SpecrewHandoverBodyPlaceholder` raises a NON-BLOCKING warn at the
     boundary-moved Stop (same session, timely) AND at the next resume;
  3. **the human is the backstop.**

  B's protocol (1) and detector (2) are **ONE mechanism**: a behavioral protocol with its sole,
  after-the-fact enforcement — NOT two independent guarantees, and NOT a claim that authoring is
  mechanically forced. SC-010 encodes this split explicitly so the iteration does not bank a pledge as
  a mechanism (the exact iter-4 retro failure this lesson came from).

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-022 (new) | Agent-authored handover body; hook preserves + placeholder-when-absent; mechanical placeholder detector (warn, non-blocking) | US-3 |
| FR-009 | Reconcile: the hook owns the FLOOR (frontmatter + freshness + the 6 section headers); the AGENT owns the body content | US-3 |
| FR-010 | Reconcile: bootstrap surfaces the rich agent body on resume (not just the handover timestamp + next-step) | US-3 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T029 | HandoverStore floor/body split + `Write-SpecrewHandoverContext` (author body -> render by reading back; integrity: human-sees == successor-inherits) | FR-022, FR-009 | US-3 | 2 | Implementer | scripts/internal/bootstrap/HandoverStore.ps1 | done | claude | 2 | — |
| T030 | Stop provider: PRESERVE the agent body, refresh floor/freshness; Stop-time placeholder WARN when the boundary moved but the body is still placeholder (same-session, timely) | FR-022, FR-009 | US-3 | 2 | Implementer | scripts/internal/specrew-handover-provider.ps1 | done | claude | 2 | — |
| T031 | `Test-SpecrewHandoverBodyPlaceholder` (pure detector) + bootstrap resume WARN on a fresh-but-placeholder body | FR-022 | US-3 | 2 | Implementer | scripts/internal/bootstrap/ClassificationEngine.ps1 | done | claude | 2 | — |
| T032 | Bootstrap SURFACES the rich body on resume + directive: the author-via-helper-then-render-from-it protocol | FR-022, FR-010 | US-3 | 1 | Implementer | scripts/internal/bootstrap/SessionBootstrapManager.ps1, scripts/internal/specrew-bootstrap-provider.ps1 | done | claude | 1 | — |
| T033 | Tests: failure-mode-A floor (body preserved across Stop [CI-blocking], detector correctness, bootstrap surfaces, human-sees == successor-inherits) + B detection (placeholder flagged at Stop + resume, non-blocking) | FR-022, SC-010 | US-3 | 2 | Implementer | tests/bootstrap | done | claude | 2 | — |
| T034 | Spec: add FR-022 + SC-010 (explicit A/B split) + reconcile FR-009/FR-010 to the floor/body split; docs (getting-started: the agent authors the handover body, resume surfaces it) | FR-022, FR-008 | US-2 | 1 | Implementer | specs/174-hook-driven-session-bootstrap/spec.md | done | claude | 1 | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning chooses deferrals when over capacity. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Serial single-Implementer; the store (T029) -> provider (T030) -> detector (T031) -> bootstrap (T032)
  chain is sequential; tests (T033) + spec/docs (T034) follow.
- Apply the iter-3/iter-4 floors: T033 carries a CI-BLOCKING plumbing floor (failure-mode A) plus the
  on-disk read pattern; the failure-mode-B detector is NON-BLOCKING by design (the transcript-blindness
  ceiling) — the gate must not claim B is mechanically prevented.
- Recommendation: serial; no Junior/Senior split.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Design co-settled with the human (agent-authored hybrid) + carry `f174-i005-mechanical-detector-in-scope`. |
| Discovery/Spikes | 0 | No new research; builds on the iter-4 rolling-handover machinery. |
| Implementation | 10 | T029-T034. |
| Review | 2 | reviewer artifacts + Proposal-145 + the CI-blocking failure-mode-A floor. |
| Rework | 1 | needs-work buffer. |

## Traceability Summary

- Iteration 005 requirement scope: FR-022 (new — agent-authored body + mechanical detector),
  FR-009/FR-010 (reconcile to the floor/body split), FR-008 (docs), SC-010 (new — the A/B split).
- User stories: US-3 (handover), US-2 (docs).
- Honors carry `f174-i005-mechanical-detector-in-scope`: the mechanical detector (T031, plus the
  Stop-time warn in T030) is IN SCOPE and recorded HERE before building — not deferred to a pledge.
- SC-010 split (recorded so it cannot be banked as a pledge): **A (plumbing)** is test-guaranteed +
  CI-blocking; **B (hollow-authoring)** is detected-and-surfaced, NOT prevented — the human is the
  backstop.

## Notes

- **Detector home = the BOOTSTRAP, not the validator.** F-174 is behind main and the validator diverges
  there; a bootstrap-side detector is rebase-safe and composes with the beta-2 #2216 state-truth gate. A
  validator-side handover-body gate is a follow-up CANDIDATE, gated with the other validator work on the
  rebase (carry `f174-action4-reconcile-with-2216`).
- ~10 SP = the ~8 SP original hollow-handover fix + ~2 SP the instruction-#1 mechanical detector
  (T031 + the Stop-time warn in T030).
- Capacity 10/20: per-task SP (2+2+2+1+2+1) = 10. No overcommit.
- Sub-agents OUT OF SCOPE (single-agent only); per-worktree handover merge stays deferred (memory
  `f174-subagent-handover-merge-consideration`).
