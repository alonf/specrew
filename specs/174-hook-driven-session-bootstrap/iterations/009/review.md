# Review: Iteration 009

**Schema**: v1
**Reviewed**: 2026-06-11
**Overall Verdict**: accepted

Structured per Proposal 145. Iteration 009 made the Stop hook the PRIMARY delta-author of the rolling
handover (the iter-008 hollow-handover finding), with a multi-source save (Stop + PostToolUse + workshop
skill) and section ownership. This review is signed off against a **live cross-host dogfood** (the
validation iter-009 was pending), which confirmed the mechanism AND surfaced the next-iteration work.
**Accepted** for the delivered, dogfood-validated machinery; the **resume-side reconciliation** and the
**PostToolUse cost/value re-think** are formally **deferred to iteration 010** (see the Resume Qualification +
Gap Ledger).

## Resume Qualification (the carry to iteration 010 — read before any "resume works" reading)

The dogfood proved the handover is now **never hollow** and captures real content (after T007), and that it
hands off across hosts. But it also proved the handover is a **passive snapshot**: `SessionBootstrapManager`
**never re-computes `Get-SpecrewSessionDelta` on SessionStart** — it replays the last write. So if the last
Stop predates the latest work (codex/copilot have no PostToolUse; a hard kill fires no Stop), the resume
shows a stale snapshot, and the directive never tells the agent *"here's what changed since the last stop —
read it and continue from the real state."* The maintainer-confirmed conclusion: **the durable state is on
disk** (workshop lens files, the tree), so the per-tool-call PostToolUse refresh was the **wrong lever** (low
unique value + a `git status` cost every tool call); the real value is a **lean resume reconciliation**
(re-compute the cheap delta on resume + point the agent + author the non-durable intent). That redirection is
iteration 010. Read "resume restores context" as **grounding + pointer delivered; active reconciliation
NOT** — deferred.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-009, FR-021 | pass | Section-ownership in HandoverStore: mechanical (hook) refreshed, interpretive (agent) preserved per-boundary; `from_commit` exposed. |
| T002 | FR-010 | pass | `Get-SpecrewSessionDelta` accessor (branch/HEAD/uncommitted/new-commits; fail-safe). |
| T003 | FR-009, FR-010, FR-021 | pass | Stop provider authors the mechanical sections from the delta, accumulates across the boundary window, stamps the real `from_host`. Dogfood: `from_host: codex` / `claude` confirmed. |
| T004 | FR-002, FR-004 | pass | Bootstrap surfaces the hook-captured content as resume context; the hollow warning recalibrated to truly-empty only. Dogfood: `handover_valid=True`, `placeholder=False`, `mode=welcome-back` on codex + copilot re-entry. |
| T005 | SC-004 | pass | Bootstrap suite 21/21 (delta, accumulation, boundary reset, from_host, agent-preserve, atomic `.old`). |
| T006 | FR-009, FR-010, SC-004 | pass | Multi-source core `Update-SpecrewRollingHandover` (Stop + PostToolUse + workshop skill); dispatcher `--source-event`. Dogfood: PostToolUse mid-turn refresh CONFIRMED on Claude (16:51-16:54 PostToolUse bullets between Stops). |
| T007 | FR-010, FR-022 | pass | Delta-noise fix (the deferred fast-follow, delivered + verified live): partition managed vs user, surface user files first, `--untracked-files=all`. Dogfood: the bullet went from "53 [.agents/...]" to "7 changed user file(s) [.../spec.md, .../workshop/product-domain.md, ...] (+499 managed)" — the workshop progress became legible. |

## Seven-Phase Structured Review (Proposal 145)

- **Phase 0 — Context load**: pass. spec.md (FR-009/FR-010/FR-021/FR-022), iter-008's hollow-handover carry, the maintainer multi-source direction (T006).
- **Phase 1 — Branch hygiene**: pass. Work committed across the branch; the dogfood-driven fixes (T007 de-noise `67ec20b3`; the codex hook self-heal `ec08752f`, a chore) landed + pushed.
- **Phase 2 — Functional correctness**: pass (delivered scope). Non-hollow capture, real `from_host`, multi-source refresh, de-noised content — all confirmed live across codex + claude + copilot.
- **Phase 3 — Non-functional**: pass. Atomic single write path; material-change gate; local + write-only handover. **Note (-> iter-010):** the PostToolUse-per-tool-call `git status` cost is real and low-value given on-disk durability.
- **Phase 4 — Code quality**: pass. Clean IDesign seams (the accessor, the core orchestrator, the providers as thin triggers).
- **Phase 5 — Test coverage + integrity**: **qualified.** Bootstrap suite 21/21 incl. the multi-source paths. **Honest gap:** the dogfood-delivered fixes (T007 de-noise; the codex self-heal) were committed verified-LIVE but their committed regression tests land at this closeout / carry to iter-010 (the codex self-heal test).
- **Phase 6 — System safety + ops**: pass. Fail-open everywhere; the dogfood is the live-behavior check that surfaced the resume-reconciliation gap + the de-noise — the honest discipline working.
- **Phase 7 — Synthesis + falsification**: **ACCEPT, with the resume reconciliation + PostToolUse re-think DEFERRED to iteration 010.** The never-hollow, de-noised, multi-source handover is delivered + dogfood-validated; the resume does not yet actively reconcile, and PostToolUse is the wrong lever. No claim that "resume restores useful context" survives unqualified.

## Gap Ledger

- The rolling-handover RESUME does not RECONCILE (FR-022: SessionStart replays the snapshot, never re-computes the live delta or directs the agent to read changed-since-last-stop) is DEFERRED to iteration 010, which makes resume re-compute the cheap delta + point the agent + author the intent. Canonical defer entry `f174-i009-defer-reconciliation-to-010` in `.squad\decisions.md` (drift D-016).
- PostToolUse per-tool-call refresh is the wrong lever (low unique value — durable state is on disk — for a `git status`-per-tool-call cost): DEFERRED to iteration 010 to dial back (off/throttled). Same defer entry `f174-i009-defer-reconciliation-to-010` (drift D-016).
- Delta-noise (FR-010: the handover drowned in ~53 Specrew-managed scaffolding paths): fixed-now (T007, dogfood-verified live; drift D-015).
- `from_host: host` mislabel in the workshop-skill `--source workshop` refresh (the skill does not pass `--host-kind`) is DEFERRED to iteration 010 as a fix (same defer entry `f174-i009-defer-reconciliation-to-010`; drift D-016 carry).

## Follow-ups (tracked in `.squad/decisions.md`)

- Iteration 010 builds the lean resume reconciliation + dials PostToolUse back + surfaces the workshop lens/gate-stop tracking + fixes `from_host` + adds the codex array-shape self-heal regression test.
- Transcript-tail enrichment + folding `Write-SpecrewHandoverContext` into the gate-stop/workshop overlay remain out-of-scope fast-follows.
