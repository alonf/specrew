# Iteration Plan: 010

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 24.00/26 story_points
**Started**: 2026-07-01

<!--
  Validator schema (canonical):
  - Iteration Status: planning | executing | reviewing | retro | complete | abandoned
  - Capacity: `<consumed>/<cap> <unit>` with NO trailing prose.
  - Task Status: planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Robustness completion + reviewer-instruction fold, closing F-197 as **0.40.0** (maintainer scope + version decision 2026-07-01). Iteration 009 delivered the graceful-degradation spine (R1/R2 + Option-A + round-ceiling); iteration 010 completes the charter and adds the deferred Phase-2 supervisor. Design of record: [design-analysis.md](design-analysis.md) (Option A, approved for plan 2026-07-01, auth commit `ab1b516b`). iter-009's D1–D5 + the R6 menu stand; the new decisions are N1–N8 in the design-analysis. No new dependencies; PowerShell 7.x + Pester. The only new architecture is the OS-native process containment (T100), localized to the isolated-task supervisor+launcher seam.

| Requirement / Issue | Summary |
| ------------------- | ------- |
| FR-037 (R5) | Hard-timeout completion: consolidate the inline `--live` path onto the isolated-task supervisor; delete the duplicate inline kill; WSL-validate (hard gate). |
| FR-035 (R3) | Host-independence fallback: pre-flight independence check + labelled same-host fallback (never block). |
| FR-036 (R4) | Tiered degraded-evidence gate: 3-dimension label; full+independent auto; partial/same-host need a recorded ack; never deadlock. |
| FR-038 (R6) | Remediation menu at the next Stop (more time / host / narrow scope / accept / override), carried via round-state. |
| FR-040 (R8) | Material-turn gate for the Stop-hook conformance parse (cheap stops stay cheap). |
| FR-039 (R7) | OS-native robust supervisor: Job Object (Win) / setsid+PGID (Unix) atomic containment + session-scoped reaper + `terminal_reason`. |
| FR-017/018/021, SEC-007, SC-013/014 | code-review-agent.md preservation fold into the slim prompt (D-197-I009-016 + manifest). |
| D-197-I009-010 | escalation-latch wiring (surface-once-then-latch + convergence reset). |
| D-197-I009-015 | codex reliability: retry-once on a 0-byte result + diagnostic. |
| D-197-I009-003 | conformance flush-race: forensic confirm/refute, then close (cheaper mitigation only if confirmed). |
| SC-012 / SC-022 | cross-host manual validation (installed+authorized hosts; rest recorded unavailable). |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ |
| T091 | R5 hard-timeout completion: route the inline `specrew review --live` spawn through the isolated-task supervisor; delete `worktree-reviewer.ps1`'s duplicate inline `$proc.Kill($true)`; instrument the live escape first; WSL-validated (hard gate). | FR-037, SC-024, NFR-001 | Hard timeout | 3.00 | Architect | `scripts/internal/continuous-co-review/worktree-reviewer.ps1`; `scripts/internal/agent-tasks/isolated-task-supervisor.ps1`; `scripts/internal/agent-tasks/isolated-task-launcher.ps1`; `tests/continuous-co-review/**` | done |
| T093 | Host-independence fallback: pre-flight independence check; fire a labelled same-host fallback immediately (never block); the answer upgrades the next run; honour-or-surface `--host`. | FR-035, FR-016, SEC-004 | Host fallback | 1.50 | Implementer | `scripts/internal/continuous-co-review/reviewer-selection-policy.ps1`; `scripts/internal/continuous-co-review/reviewer-authorization-gate.ps1`; `tests/continuous-co-review/**` | done |
| T094 | Tiered degraded-evidence gate: 3-dimension label (completeness/independence/budget); full+independent auto-allows; partial OR same-host need a recorded first-class ack verdict; never deadlock; degraded-block override with recorded reason. | FR-036, SC-019, SC-020, SC-024 | Degraded gate | 2.50 | Reviewer | `scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1`; `scripts/internal/continuous-co-review/inline-review-gate-evaluator.ps1`; `tests/continuous-co-review/**` | done |
| T096 | Remediation menu at the next Stop (more time / different host / narrow scope: code · process · file · function / accept partial / override), carried via `co-review-round-state.json`; honour the human-directed scope. | FR-038, FR-024, FR-025 | Remediation menu | 3.00 | Implementer | `scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1`; `extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1`; `tests/continuous-co-review/**` | done |
| T099 | Material-turn gate for the Stop-hook conformance parse: run the parse only when a stop follows a material turn, so trivial/conversational stops stay cheap. | FR-040, SC-025 | Stop-hook budget | 1.50 | Implementer | `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` (+ `.specify` mirror); `tests/continuous-co-review/**` | done |
| T100 | OS-native robust supervisor: Windows Job Object (`KILL_ON_JOB_CLOSE`) + Unix `setsid`+PGID group kill (cgroup where delegated) so the whole reviewer tree dies atomically; session-scoped pidfile registry + SessionStart orphan reaper; record `terminal_reason`. WSL-validated. | FR-039, SC-025, NFR-001 | Robust supervisor | 4.00 | Architect | `scripts/internal/agent-tasks/isolated-task-supervisor.ps1`; `scripts/internal/agent-tasks/isolated-task-launcher.ps1`; `scripts/internal/agent-tasks/process-tree.ps1`; `tests/continuous-co-review/**` | done |
| T106 | Wire the escalation-latch: load `escalation-latch.ps1` via `_load.ps1`; invoke from the navigator so a ceiling escalation surfaces once then latches quiet; reset round-state on a converged checkpoint; integration test on real transcript data. | FR-029, NFR-005 | Escalation-latch | 1.50 | Implementer | `scripts/internal/continuous-co-review/escalation-latch.ps1`; `scripts/internal/continuous-co-review/_load.ps1`; `scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1`; `tests/continuous-co-review/**` | done |
| T107 | code-review-agent.md preservation fold: graft the TO-FOLD manifest rows (falsification stance, P145 phases, per-lens validation, workshop-conformance, claim/design-trace, deterministic-failure≠clean, secret-non-exfiltration) into `Get-ContinuousCoReviewSlimPrompt`; drop the DROP rows (ReviewRequest.v2 / read-only-composed-prompt / composer / mirror-authority); retire the file to a reference doc; re-point the test at the outbound slim prompt. | FR-017, FR-018, FR-021, SEC-007, SC-013, SC-014 | Reviewer fold | 2.00 | Implementer | `scripts/internal/continuous-co-review/worktree-reviewer.ps1`; `scripts/internal/continuous-co-review/code-review-agent.md`; `tests/continuous-co-review/contracts/reviewer-instruction.Tests.ps1` | done |
| T108 | Codex reliability (D-197-I009-015): adapter-level retry-once on a 0-byte result before declaring `no-parseable-findings`; a diagnostic capturing whether the empty exit-0 is a capture-path gap vs codex finalization. Preserves never-false-green (a still-empty retry fails loudly). | FR-033, SC-024 | Codex reliability | 1.50 | Implementer | `scripts/internal/continuous-co-review/reviewer-host-catalog.ps1`; `scripts/internal/continuous-co-review/worktree-reviewer.ps1`; `tests/continuous-co-review/**` | done |
| T109 | Flush-race forensic (D-197-I009-003): a forensic test confirming or refuting the conformance stop-block flush/read race on real captured data. If confirmed, a cheaper mitigation than the reverted 4×-tail-200 re-read (gated by T099's material-turn check); if refuted, close the finding refuted-with-evidence. | FR-040, SC-025 | Flush-race forensic | 1.50 | Reviewer | `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`; `tests/continuous-co-review/**` | done |
| T110 | SC-012/SC-022 cross-host manual validation: exercise the Stop-hook co-review fire across the installed+authorized harnesses (claude, codex today); honestly record which harnesses were exercised vs unavailable. | SC-012, SC-022 | Cross-host validation | 2.00 | Spec Steward | `specs/197-continuous-co-review/iterations/010/**` | planned |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 26 | Maintainer-raised from the standing 20 for the full-scope robustness-completion iteration (D2 decision 2026-07-01). |
| Iteration Bounding | scope | `scope` keeps requirements fixed; time varies. |
| Time Limit (hours) | n/a | Not used for this scope-bounded iteration. |
| Overcommit Threshold | 1.0 | Planned effort must stay at or below the 26-SP cap. |
| Defer Strategy | manual | Any overcommit requires explicit human deferral; lowest-priority slice (T110 or T108) drops first if needed. |
| Calibration Enabled | true | Retro compares planned and actual effort. |

## Traceability Summary

- **In-scope requirements**: FR-035, FR-036, FR-037, FR-038, FR-039, FR-040 (R3–R8), FR-017/018/021 + SEC-007 + SC-013/014 (canonical-instruction fold), SC-012, SC-019, SC-020, SC-022, SC-024, SC-025, NFR-001, NFR-005; plus findings D-197-I009-003/-010/-015/-016.
- **Bidirectional**: every task T091/T093/T094/T096/T099/T100/T106–T110 traces to ≥1 FR/SC/finding (Requirement column); every in-scope requirement above has ≥1 covering task (FR-035→T093, FR-036→T094, FR-037→T091, FR-038→T096, FR-039→T100, FR-040→T099+T109, FR-017/018/021+SEC-007+SC-013/014→T107, D-010→T106, D-015→T108, D-003→T109, SC-012/022→T110). Full traceability check runs at after-tasks.
- **Carried IDs**: T091/T093/T094/T096/T099/T100 retain their iter-009 IDs (same work, deferred to iter-010); T106–T110 are new. No collision with iter-007's renumbered T101–T105.
- **Capacity status**: PASS — 24.00/26 story_points (2.00 headroom).

## Acceptance gates

- **R5 WSL-validation (hard gate, T091 + T100)**: a configured timeout kills the reviewer process **tree** with no orphaned children, proven on WSL (not Windows-only). Applies to both the inline consolidation (T091) and the OS-native containment (T100).
- **Never-deadlock (T094)**: a `partial`/`same-host` review allows only with a recorded first-class ack verdict; the gate never blocks on "no parseable verdict".
- **Preservation manifest (T107)**: every TO-FOLD manifest row present in the slim prompt and asserted by the re-pointed test; every DROP row confirmed absent (no critical reviewer instruction lost).
- **Never-false-green (T108)**: a still-empty codex retry fails loudly (`status=failed`), never counts as gate evidence.
- **Escalation-latch (T106)**: a ceiling escalation surfaces once then latches quiet; round-state resets on convergence (integration-tested on real transcript data).
- **Cross-host honesty (T110)**: the SC-012/022 evidence records exactly which harnesses were exercised vs unavailable — no all-five claim without all-five evidence.
- **Deploy-completeness smoke**: the new paths fire in a deployed consumer project, not only self-host unit tests.

## Notes

- Design of record: [design-analysis.md](design-analysis.md); Option A approved for plan 2026-07-01 (`ab1b516b`). iter-009 D1–D5 stand.
- No new dependencies; no F-184 protected-surface edits (the navigator provider is F-197-owned — confirm via the protected-surface guard before committing T096).
- The boundary-cursor null-history defect (D-197-I010-001) was locally reconciled; the durable multi-machine fix stays deferred to Proposals 142/193.
- Ships as 0.40.0 (beta → stable) at feature-closeout, per the D2 version decision.
