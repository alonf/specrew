# Design Analysis — Feature 197 Iteration 010: Robustness Completion + Reviewer-Instruction Fold (ship 0.40.0)

**Feature**: 197-continuous-co-review
**Iteration**: 010
**Date**: 2026-07-01
**Stage**: design-analysis (co-design)

**Driver**: the 2026-07-01 "finish it perfectly" decision. Iteration 009 delivered the graceful-degradation *spine* (R1/R2 harvest + time-extension, plus Option-A escalation parking and the round-ceiling) but left its charter incomplete: R3/R4/R6 (host fallback, tiered degraded gate, remediation menu) were planned-not-built, R5 (hard timeout) was needs-rework with an unevidenced WSL gate, the escalation-latch was committed-but-orphaned, and two reliability findings stayed open. iteration 010 **completes the robustness charter**, adds the deferred Phase-2 supervisor (T099/T100), executes the `code-review-agent.md` preservation fold, resolves the open findings, and closes the feature as **0.40.0** (maintainer scope + version decision, 2026-07-01).

## Relationship to iteration 009 (no design re-derivation)

Iteration 009's design-analysis already co-designed **D1–D5 + the R6 remediation menu** (async human-gate model, incremental partial-findings harvest, hard-timeout kill approach, tiered degraded-evidence gate, degraded-block override) and the seam→component map. **Those decisions stand.** Iteration 010 *implements* the parts iter-009 planned-but-did-not-build (R3/R4/R6) per that design, and adds the genuinely-new decisions below. Where a task's design is unchanged from iter-009, this document references it rather than re-deciding it.

## Scope (full, per the maintainer D2 decision 2026-07-01)

| Item | Requirement / finding | Design source |
|---|---|---|
| T091-R5 | FR-037 hard-timeout completion + WSL validation | iter-009 D3 + **N1** below |
| T093 | FR-035 host-independence fallback | iter-009 D1 (build per design) |
| T094 | FR-036 tiered degraded-evidence gate | iter-009 D4 (build per design) |
| T096 | FR-038 remediation menu | iter-009 D6/R6 (build per design) |
| escalation-latch wiring | smooth-UX (D-197-I009-010 carry) | **N4** below |
| code-review-agent.md fold | FR-017/018/021, SEC-007, SC-013/014 (D-197-I009-016) | **N5** + preservation manifest |
| T099 | FR-040 Stop-hook cheap-work gate | **N3** below |
| T100 | FR-039 robust supervisor (atomic kill, no orphans) | **N2** below |
| D-197-I009-003 | conformance flush-race (verify/close) | **N7** below |
| D-197-I009-015 | codex reliability (~50% empty exit-0) | **N6** below |
| SC-012 / SC-022 | cross-host manual validation (owed) | **N8** below |

**Capacity**: full scope estimates to ~24 SP against the standing 20-SP cap — a real overcommit. Per the maintainer's "include everything in iter-010" decision, the design proposes **raising the iteration-010 cap to 26 story_points** (explicit maintainer decision, not a silent overcommit) with the effort model's `manual` defer-strategy as the backstop if a slice must drop. Confirmed at the plan boundary via the capacity-planning pass.

## New design decisions (N1–N8) — co-designed with the maintainer 2026-07-01

### N1 — T091-R5: finish the supervisor consolidation iter-009 half-did

iter-009's D3-refinement decided "consolidate the inline reviewer spawn onto the isolated-task supervisor," but only shared the tree-kill *helper*; the inline `worktree-reviewer.ps1` watchdog loop + `$proc.Kill($true)` were retained (two divergent kills). **N1 completes it**: route the inline `specrew review --live` invocation through the same launcher/supervisor process manager the async path uses, **delete** the duplicate inline kill, and prove the timeout kills the reviewer tree with **no orphaned children on WSL** (the hard acceptance gate). Instrument the live escape first (exact failure mode confirmed) before removing the inline path.

### N2 — T100 robust supervisor -> OS-native atomic containment (chosen: Option A)

**Problem**: the 1h12m field hang came from a kill that missed *forked grandchildren* — a recursive poll-then-kill races processes the reviewer spawns. **Options weighed** (maintainer chose **A**):

- **Option A (chosen) — OS-native atomic containment.** Windows: assign the reviewer process to a **Job Object** with `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` so the entire tree dies atomically when the job handle closes. Unix: launch under **`setsid`** (own process group) and kill the whole group (`kill -- -PGID`), using a cgroup where delegation is available. Plus a **session-scoped launcher + pidfile registry** so orphans from a crashed dispatcher are reaped on the next SessionStart, and a recorded `terminal_reason` on every kill. Atomic by construction; no daemon.
- Option B — enhance the poll-based watchdog only (activity-watchdog + recursive `Stop-SpecrewProcessTree`). Lowest code, but grandchildren can still race the recursive walk — the exact failure class. Rejected as too weak.
- Option C — a full standalone supervisor daemon (cgroup v2 delegation + durable registry + reaper daemon). Strongest, but over-engineered / heavy ops surface for a per-checkpoint reviewer. Rejected as disproportionate.

**Rationale (maintainer, "OS base")**: guarantee the whole tree dies by OS primitive, not by a best-effort walk. WSL-validated alongside N1.

### N3 — T099: material-turn gate for the Stop-hook conformance parse (FR-040)

The conformance re-read that iter-009 reverted for cost is gated behind an **"any material turn since the last stop?"** check so trivial/conversational stops stay cheap; the parse runs only when a stop actually followed material work. Keeps the Stop-hook budget honest.

### N4 — escalation-latch wiring

The escalation-latch (`escalation-latch.ps1`, committed iter-009 but absent from `_load.ps1`, zero callers) is **wired**: loaded via `_load.ps1`, invoked by the navigator so a ceiling escalation **surfaces once then latches quiet** (no re-nagging each stop), and the round-state resets on a converged checkpoint. An integration test proves the surface-once-then-latch behavior on real transcript data.

### N5 — code-review-agent.md fold (execute the preservation manifest)

Per the maintainer-approved fold decision (D-197-I009-016) and the **preservation manifest** in file:///C:/Dev/specrew-197-continuous-co-review/specs/197-continuous-co-review/requirement-reconciliation.md §D: graft the load-bearing canonical bindings (report-falsification/adversarial stance, P145 phase structure, per-lens validation, workshop-conformance, claim/design-trace, deterministic-failure≠clean, secret-non-exfiltration) into `Get-ContinuousCoReviewSlimPrompt`; **drop** the stale `ReviewRequest.v2` / "read only the composed prompt" / prompt-composer language; retire `code-review-agent.md` to a reference doc; re-point `reviewer-instruction.Tests.ps1` at the actual outbound slim prompt. Acceptance = every TO-FOLD manifest row present + asserted; every DROP row confirmed absent.

### N6 — D-197-I009-015 codex reliability (~50% empty exit-0)

**Retry-once on a 0-byte result** at the adapter seam before declaring `no-parseable-findings` (the immediate robustness), **plus** a diagnostic that captures whether the empty exit-0 is a capture-path gap vs codex finalization. Preserves the never-false-green invariant (a still-empty retry fails loudly). If the diagnostic shows codex is systematically flaky, a more-reliable default reviewer is a follow-up (not in scope unless the diagnostic proves it necessary).

### N7 — D-197-I009-003 conformance flush-race (confirm or refute, then close)

The mitigation was reverted for perf, leaving the finding unverified. **N7 adds a forensic test** to confirm-or-refute the flush/read race on real captured data. If confirmed, a *cheaper* mitigation than the reverted 4×-tail-200 re-read (e.g. a single bounded re-read gated by N3's material-turn check). If refuted, record it closed with the forensic evidence. Either way the finding stops being "open/unverified."

### N8 — SC-012 / SC-022 cross-host validation (the owed acceptance)

The maintainer real-host validation across the supported harnesses (the long-standing SC-012 owed item + SC-022's cross-harness Stop-hook fire) is executed as an iter-010 acceptance step, documented in the iteration's manual-validation evidence. Scope: the authorized/installed hosts (claude, codex today; others as available), honestly recording which harnesses were exercised vs unavailable.

## Seam -> component map (extends the iter-009 table)

| Item | Seam (existing script) | Change |
|---|---|---|
| N1/T091-R5 | `worktree-reviewer.ps1` + `agent-tasks/isolated-task-supervisor.ps1` + `isolated-task-launcher.ps1` | route inline path through the supervisor; delete duplicate inline kill; WSL-validate |
| N2/T100 | `agent-tasks/isolated-task-supervisor.ps1` + `isolated-task-launcher.ps1` + `process-tree.ps1` | Job Object (Win) / setsid+PGID (Unix) atomic containment; session-scoped pidfile registry + SessionStart reaper; `terminal_reason` |
| N3/T099 | `specrew-conformance-provider.ps1` (+ `.specify` mirror) | material-turn gate before the conformance parse |
| N4 | `escalation-latch.ps1` + `_load.ps1` + `continuous-co-review-navigator.ps1` | wire into load + navigator; surface-once-then-latch; round-state reset on convergence |
| N5 | `worktree-reviewer.ps1` (`Get-ContinuousCoReviewSlimPrompt`) + `code-review-agent.md` + `reviewer-instruction.Tests.ps1` | fold per manifest; retire file; re-point test |
| N6 | reviewer adapter (codex exec path in `reviewer-host-catalog`/agent-command) | retry-once on 0-byte + diagnostic |
| N7 | `specrew-conformance-provider.ps1` + tests | forensic confirm/refute; cheaper mitigation if confirmed |
| T093 | `reviewer-selection-policy.ps1` + `reviewer-authorization-gate.ps1` | build per iter-009 D1 (pre-flight independence check + labelled same-host fallback) |
| T094 | `review-signoff-evidence-gate.ps1` + `inline-review-gate-evaluator.ps1` | build per iter-009 D4 (3-dimension label + recorded ack + degraded override) |
| T096 | `continuous-co-review-navigator.ps1` + `specrew-co-review-navigator-provider.ps1` + `co-review-round-state.json` | build per iter-009 D6/R6 (the remediation menu + human-directed scope) |

## Co-Design Record

**Decomposition method**: extend the existing worktree-reviewer pipeline + the iter-005 isolated-task supervisor at named seams; the only new architecture is N2's OS-native process containment (Job Object / process-group), localized to the supervisor+launcher seam. Agreed with the maintainer.

**Component-to-responsibility map (agreed)**:

- **isolated-task-supervisor.ps1 + isolated-task-launcher.ps1** — own atomic OS-native reviewer containment (Job Object / setsid+PGID), the session-scoped pidfile registry, orphan reaping, and `terminal_reason` (N2/T100); and are the SINGLE process manager the inline path now also uses (N1/T091-R5).
- **worktree-reviewer.ps1** — owns the slim reviewer prompt with the folded canonical rubric (N5); no longer owns a divergent inline kill (removed by N1).
- **reviewer-selection-policy.ps1 + reviewer-authorization-gate.ps1** — own the pre-flight independence check + labelled same-host fallback (T093).
- **review-signoff-evidence-gate.ps1 + inline-review-gate-evaluator.ps1** — own the 3-dimension degraded-evidence label, the recorded ack verdict, and the degraded-block override (T094).
- **continuous-co-review-navigator.ps1 + provider + co-review-round-state.json** — own the remediation menu and carry the human's choice to the rerun (T096); and invoke the wired escalation-latch (N4).
- **specrew-conformance-provider.ps1** — owns the material-turn-gated conformance parse (N3) + the flush-race forensic/mitigation (N7).
- **reviewer adapter (codex path)** — owns retry-once-on-empty + the reliability diagnostic (N6).

**Agreed flow (finish-perfectly happy path)**: implementer Stop -> navigator fires the detached review under the OS-contained supervisor (N2) -> reviewer runs; if it hangs, the supervisor's atomic tree-kill guarantees no orphan and records `terminal_reason` (N1/N2, WSL-validated) -> orchestrator harvests partial findings + labels the run (iter-009 R1/R4) -> if independence/host/scope is at issue, the remediation menu surfaces once (T096) and the escalation-latch keeps it quiet thereafter (N4) -> human picks a remediation -> round-state carries it -> rerun completes -> tiered gate allows on full+independent or a recorded ack (T094). The reviewer throughout runs the folded slim prompt carrying the canonical falsification/P145 rubric (N5).

**Human-agreed**: ✅ Maintainer (Alon Fliess) co-designed and agreed the iter-010 scope (D2: full, incl. T099/T100), the 0.40.0 version target, the N2/T100 OS-native-containment option ("OS base"), and the N1/N3–N8 approaches in the 2026-07-01 design conversation.

## Crew recommendation

**Approve for plan with Option A** — complete the robustness charter (T091-R5/T093/T094/T096 per iter-009's standing design) + the OS-native atomic supervisor (N2/T100) + the material-turn conformance gate (N3/T099) + escalation-latch wiring (N4) + the code-review-agent.md preservation fold (N5) + the codex retry-once reliability fix (N6) + the flush-race forensic close (N7) + the SC-012/022 cross-host validation (N8), at a maintainer-raised 26-SP cap, shipping as 0.40.0. Option A is the co-designed package above; the meaningfully-distinct alternatives were the T100 containment strength (Options B/C, rejected) and deferring T099/T100 (rejected by the D2 full-scope decision).
