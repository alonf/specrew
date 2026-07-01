# Iteration 009 Review (reviewer robustness — graceful degradation)

**Feature**: 197-continuous-co-review
**Iteration**: 009 (reviewer robustness / graceful degradation; shipped 0.39.0-beta1)
**Date**: 2026-07-01
**Reviewers**: iteration 009's OWN continuous co-review, dogfooded live against the 0.39.0-beta1 change-set — the auto-fire navigator (un-darked mid-iteration) plus manual `specrew review --live` runs on codex/claude. The dogfood findings (D-197-I009-001…-014) ARE this iteration's review activity; there was no separate adversarial pass.
**Overall Verdict**: accepted

## Review activity

Iteration 009 delivered the graceful-degradation slice and shipped 0.39.0-beta1 (`35cb66c3`). Its review was performed by the feature reviewing itself: once the deployed navigator was un-darked (D-197-I009-001), the continuous co-review fired at real checkpoint Stops and on manual `--live` runs, and every finding in the Gap Ledger below was surfaced by that machinery and closed with a commit. The escalation loop correctly routed the one governance self-violation it could not auto-resolve (T091 marked done without its WSL hard-gate) to a human, who ruled defer-to-iter-010 (drift-log D-197-I009-006). Delivered scope is accepted; the four unfinished robustness tasks and the still-open findings carry to iter-010.

## Task Verdicts

| Task | Verdict | Evidence |
| ---- | ------- | -------- |
| T090 | pass | Partial-findings harvest + prose-salvage floor: incremental one-JSON-per-line emission, clean-prefix harvest on kill, salvage floor; `8d1e8add` (+ schema/timeout follow-ups `fee4ba5c`, `a0bfd6f6`); `partial-harvest` unit test. |
| T092 | pass | Human-gated time-extension gate: post-hoc "more time" menu note + pre-flight generous-budget heuristic for large diffs; `ba88e34e`; `time-extension-budget` + `partial-more-time-note` unit tests. |
| T095 | pass | Governance collision cleanup: renumbered the iter-008 Dogfood Repair Addendum T083-T085 → T087-T089 (iter-006's commit-cited T083-T086 stay canonical); `ab199d11` across iter-008 state.md + tasks.md. |
| T097 | pass | R7 detach-leak fix: zero-handle-inheritance detached spawn via `Win32_Process.Create` (Windows; Unix `-Redirect*` clean at 2.8s) + revert of T092's AUTO generous-budget bump; `df46389d` then root fix `fc7f5ed5` (+ hidden window `447c6211`); 4-level `detached-spawn-no-block` integration test. |
| T098 | pass | R8 revert of the unconfirmed ~17s flush-race conformance re-read (4x tail-200 parse) that taxed every material stop and starved the navigator's Stop budget; `df46389d` on both conformance-provider copies; `conformance-detection` 24/24. |
| T091 | pass | DEFERRED to iter-010 — NOT implemented in iter-009 (verdict `pass` = the deferral disposition carries no blocking review concern, not "delivered"). Demoted to needs-rework this iteration; the WSL hard-gate + genuine inline→supervisor consolidation are owed as iter-010 T091 (drift-log D-197-I009-006). |
| T093 | pass | DEFERRED to iter-010 — NOT implemented in iter-009 (verdict `pass` = deferral accepted, not delivered). Host-independence fallback carries to iter-010 T093 per the full-robustness decision. |
| T094 | pass | DEFERRED to iter-010 — NOT implemented in iter-009 (verdict `pass` = deferral accepted, not delivered). Tiered degraded-evidence gate carries to iter-010 T094 per the full-robustness decision. |
| T096 | pass | DEFERRED to iter-010 — NOT implemented in iter-009 (verdict `pass` = deferral accepted, not delivered). Human remediation menu carries to iter-010 T096 per the full-robustness decision. |

## Deferred to iteration 010

The four remaining robustness tasks were NOT delivered in iteration 009 (recorded above as `pass` = deferral-accepted, with explicit "NOT implemented" evidence); per the full-robustness decision (2026-07-01) they carry to iteration 010:

- **T091 (R5 hard timeout — WSL hard-gate + genuine consolidation)** — demoted to needs-rework this iteration; the WSL tree-kill proof, the live-inline-path orphan-kill proof, and the real inline→supervisor consolidation are owed (drift-log D-197-I009-006).
- **T093 (host-independence fallback)** — pre-flight independence check + labelled same-host fallback; not-in-code as of iter-009.
- **T094 (tiered degraded-evidence gate)** — 3-dimension completeness/independence/budget label with recorded first-class ack; not-in-code as of iter-009.
- **T096 (human remediation menu)** — more-time / different-host / narrow-scope / accept-partial / override; not-in-code as of iter-009.

Also carried: the escalation-latch (`9aa812cc`, `e70e655e`, `0b7bb1a9`) is COMMITTED BUT ORPHANED — `escalation-latch.ps1` is absent from `_load.ps1` with zero callers — so its wiring + integration test are staged for iter-010. By contrast the Option-A `escalated_to_human` parking (`b2e55921`) and the round-ceiling `ceiling_halted` fix (`e6d19e3a`, `721d3892`) ARE live-wired this iteration.

## Gap Ledger

- D-197-I009-001 (auto co-review navigator DARK — the deployed provider mirror was stale, never re-synced after the iter-008 worktree cutover, so every Stop went silently fail-open): fixed-now, commit 0b42c0f1.
- D-197-I009-002 (the un-darked co-review found real T090/T091 defects — schema-violating FindingsResult, a silent kill-fallback, stale state.md/tasks.md): fixed-now, commit fee4ba5c.
- D-197-I009-004 (a 2nd self-review caught two structural holes — the `agent-tasks/**` review blind-spot and an inert timeout prose-salvage on the real kill path): fixed-now, commit a0bfd6f6.
- D-197-I009-007 (version probe reported a false INCOMPATIBLE in every dev-trial — it ignored the SPECREW_MODULE_PATH override): fixed-now, commit 639fead9.
- D-197-I009-009 (codex reviewer could not operate in the ephemeral worktree — helper-resolution + per-run project-trust — resolved via `--dangerously-bypass-approvals-and-sandbox`): fixed-now, commit bf6f87c7.
- D-197-I009-010 (ceiling-halt FALSE-GREEN — a halted, unreviewed run reported done / 0-findings; now emits a visible escalation + `reviewed=false`): fixed-now, commit 721d3892.
- D-197-I009-011 (`specrew init` passed an unsupported `--force` to Spec Kit 0.8.4 `integration install`, so native host commands silently never installed): fixed-now, commit 7d6af165 (plus expected-skip classification d6d4e4db).
- D-197-I009-012 (SessionStart hook rendered an EMPTY banner item 3 for direct-`claude` pointer-mode users; now injects the resolved profile line): fixed-now, commit 4d29327f.
- D-197-I009-014 (`auto-select` authorizes no host → the recommended path fired into a silent `no-authorized-reviewer-host`; now an actionable authorize-a-reviewer message): fixed-now, commit 0002d2c8 (reachability corrected in b8fa62e3).

## Open and deferred findings (carried)

The still-open and deferred dogfood findings are recorded in full in the iteration 009 drift-log and are deliberately excluded from the Gap Ledger above because they were NOT closed by a commit this iteration: D-197-I009-003 (conformance flush-race — mitigation applied, live verification pending), D-197-I009-005 Phase 2 (robust supervisor + cheaper conversational stops, T099/T100), D-197-I009-006 (T091 R5 WSL closure), D-197-I009-008 (cross-machine session-cursor darkness → iter-010 navigator-stage fallback + Proposals 142/193), D-197-I009-013 (F-044 dev-trial CLI/hook version split), D-197-I009-015 (codex intermittent empty exit-0 reliability, OPEN — fails loudly, never a false pass), and D-197-I009-016 (orphaned `code-review-agent.md` — fold decided, iter-010 implementation).

## Disposition

Iteration 009's delivered scope is accepted: T090/T092/T095/T097/T098 landed with commit evidence and green tests, and the nine dogfood defects in the Gap Ledger were each closed with a commit. The four unfinished robustness tasks (T091/T093/T094/T096), the escalation-latch wiring, and the open findings (D-197-I009-003/-005-Phase-2/-006/-008/-013/-015/-016) carry to iteration 010 per the full-robustness decision (2026-07-01). Iteration 009 shipped 0.39.0-beta1 (`35cb66c3`), and the continuous co-review dogfooding that produced the D-197-I009-* findings WAS this iteration's review activity. Ready for retro / iteration-closeout.
