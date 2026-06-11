# Review: Iteration 006

**Schema**: v1
**Reviewed**: 2026-06-10
**Overall Verdict**: accepted

Structured per Proposal 145. This is a **retroactive closure artifact** (2026-06-11): iteration 006 closed
"honestly-qualified" on 2026-06-10 without a committed review.md/retro.md; this record reconstructs the
documented review outcome from the iteration's own plan.md closure note, its task ledger, and the iter-005
review precedent. Iteration 006 set out to make the SessionStart hook DRIVE at parity with `specrew start`
(reuse the launch-contract generator, init `boundary_enforcement`, prove a deployed live-wiring floor). The
**delivered, validator-green deliverable — the `launch-contract.ps1` generator extraction (T035/T035a,
byte-identical, guarded by the characterization net) plus the carries (T040 evidence_locus, T041 dormant
cleanup, T042 docs) — is ACCEPTED and KEPT.** The PARITY GOAL itself was **disproven at review-signoff** and
is **deferred to iteration 007** (read the Parity Qualification below before any "delivered" reading).

## Parity Qualification (the honest scope — the iteration closed NOT a parity success)

**This is a SEND-BACK that closed honestly-qualified, not a clean acceptance of the iteration's goal.** At
review-signoff a maintainer side-by-side DISPROVED hook ↔ `specrew start` parity: the hook path skips the
coordinator-prompt-surgery step (so it writes a THIN contract), and the agent does not actually read
`last-start-prompt.md` and follow it. **T038's deployed floor was GREEN but proved the WRONG thing** — the
presence of the contract file + the correct provider copy on disk, NOT the live read-and-follow experience.
That is the exact `build != live` overclaim (iter-5 D-009, drift D-011) this iteration existed to kill,
recurring one level up in the floor built to catch it. The task verdicts below are "pass" for **code
delivered + tests green for what they assert**; the iteration's PARITY OUTCOME (FR-023 read-and-follow
parity, FR-024 injection-reaches-model, FR-022 deployed live wiring) is **NOT delivered** and carries to
iteration 007 (`../007/plan.md`). What the human accepted: keep the safe, byte-identical T035 extraction;
do not bank parity. Read every "drives / fires / reaches the model" claim as **disproven-and-deferred**.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T035a | FR-023 | pass | Characterization net FIRST: asserts `Get-StartPrompt`'s invariant contract markers + `boundary_enforcement` init survive a `specrew start` run — the genuine regression floor the extraction needed (the existing suite did NOT pin the contract; drift D-010). |
| T035 | FR-023 | pass | `scripts/internal/launch-contract.ps1` extracted (Get-StartPrompt + prompt-block helpers moved out of specrew-start.ps1; specrew-start dot-sources it). Behavior-preserving + byte-identical + validator-green, guarded by T035a. **The kept deliverable.** |
| T036 | FR-023, FR-001 | pass | SessionBootstrapManager calls the shared generator on SessionStart → writes last-start-prompt.md + ensures boundary_enforcement (preserve-merge). Code landed; but see Parity Qualification — the contract it writes is THIN (skips coordinator surgery), so it is not at parity. |
| T037 | FR-002, FR-007 | pass | Bootstrap provider injects the read-and-follow contract (replacing the iter-5 thin orient/menu) + dedupe-safe. Code landed; the agent not reading-and-following is the disproven-parity gap (deferred). |
| T038 | FR-022, FR-024, SC-011 | pass | The deployed live-wiring floor runs green on the installed-module layout. **Honesty flag (load-bearing):** its green proves the contract file + provider copy exist on disk, NOT the live read-and-follow experience — the build != live recurrence. Re-scoped + deferred to iter-007. |
| T039 | FR-024, FR-005 | pass | Per-host injection enumerated: Claude plumbing auto-proven; injection-reaches-model is a MANUAL per-host observation; codex/copilot/cursor re-tests filed as explicit follow-on (`f174-followup-multihost-injection-verification`), not silently dropped. |
| T040 | FR-024 | pass | evidence_locus carry: `evidence_locus` (dev-tree | deployed) added to the 145 claim-ledger + hardening-gate concern schema; the review refuses "delivered-live" on dev-tree-only evidence. Filed as a Proposal-145 reviewer-family candidate. |
| T041 | FR-009 | pass | Dormant-SessionEnd cleanup: SessionEndHandoverManager + FileList entry + SessionEndHandover.Tests + the timestamped handover funcs deleted; the inaccurate "REUSED" design-record phrase corrected. |
| T042 | FR-008 | pass | Docs repositioned WITH the honesty guard: Claude driving is the PROVEN-in-practice host; codex/copilot/cursor plumbing-ready but injection-UNVERIFIED → `specrew start` fallback. NEVER "all-host parity" on Claude-only evidence. |

## Seven-Phase Structured Review (Proposal 145)

- **Phase 0 — Context load**: pass. spec.md (FR-023/FR-024/SC-011 added), the iter-006 charter
  (`f174-i006-charter`), the iter-005 deferral (`f174-i005-defer-live-wiring`, D-009), and the before-implement
  approval (`f174-i006-before-implement-approved`).
- **Phase 1 — Branch hygiene**: pass. before-implement + implementation committed on the feature branch
  (push held to feature-closeout per the maintainer — ship 1-N together).
- **Phase 2 — Functional correctness**: **qualified.** The generator extraction (T035) is byte-identical and
  green. The DRIVE path (T036/T037) writes the contract + directive, but a maintainer side-by-side disproved
  read-and-follow PARITY (thin contract; agent does not follow). Functional for the kept scope; the parity
  goal is not met.
- **Phase 3 — Non-functional**: pass. Local + preserve-merge anchor (no clobber); fail-open; the hook stays
  additive (degrades to orientation).
- **Phase 4 — Code quality**: pass. Clean IDesign seams (the new shared lib dot-sourced by both callers; the
  manager orchestrates; the provider injects). Behavior-preserving extraction guarded by T035a.
- **Phase 5 — Test coverage + integrity**: **qualified — the headline finding.** T038's deployed floor is
  green but asserts on-disk file/copy existence, NOT the live read-and-follow experience. The same
  `build != live` class the iteration was built to kill (D-009 → D-011). The floor's claim is re-scoped to
  "plumbing present", and the live parity is deferred to iter-007.
- **Phase 6 — System safety + ops**: pass. The bootstrap never blocks (fail-open); the writes are
  host-agnostic so a non-injecting host still has the files for a subsequent `specrew start`.
- **Phase 7 — Synthesis + falsification**: **ACCEPT WITH QUALIFICATION (send-back honored).** Accept + keep
  the T035 extraction + the carries; the parity goal (FR-022/FR-023/FR-024) is DISPROVEN and formally
  DEFERRED to iteration 007. No claim of parity survives this review; the qualification is the verdict.

## Gap Ledger

- Hook <-> `specrew start` read-and-follow PARITY (FR-023 read-and-follow, FR-024 injection-reaches-model, FR-022 deployed live wiring) is DEFERRED to iteration 007: the hook writes a THIN contract (skips coordinator-prompt-surgery) and the agent does not read-and-follow `last-start-prompt.md` (disproven by a maintainer side-by-side); T038's deployed floor proved file-existence, not the live read-and-follow experience (drift D-011, the build != live recurrence). Canonical defer entry `f174-i006-defer-parity-to-007` in `.squad\decisions.md`.
- T035a characterization gap (the specrew-start regression suite did not pin the contract content): fixed-now — T035a built the genuine characterization net before the extraction (drift D-010).

## Follow-ups (scoped out of iteration 6; tracked in `.squad/decisions.md`)

- Multi-host injection-reaches-model re-tests (codex / copilot / cursor):
  `f174-followup-multihost-injection-verification` — the "all hosts" intent, a follow slice past the 20 SP cap.
- The iter-007 parity slice carries FR-022/FR-023/FR-024 to a REAL read-and-follow floor (not a file-existence
  smoke), per the maintainer charter.
