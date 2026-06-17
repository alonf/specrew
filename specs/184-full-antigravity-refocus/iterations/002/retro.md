# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-06-18

## Context

Iteration 002 closed the last Antigravity parity gaps the iteration-001 manual
dogfood surfaced: persistent host instructions deployed at `specrew init`
(FR-011), the exact anti-`specify.exe workflow` guard in both the persistent file
and the bootstrap (FR-013), bootstrap front-loading (FR-014), a host-neutral
manifest-driven delivery core (FR-015), `update`/`start` refresh-and-heal (FR-016),
a single packaged source (FR-018), and real-host Opus 4.6 + Gemini Flash
validation (FR-017). Delivered at 20/20 story points on the restored cap.
Review-signoff was accepted at `7d170b8c` after a Proposal-145 send-back corrected
an SC-005 evidence overclaim.

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 2 | 2 | 0 |
| T002 | 4 | 4 | 0 |
| T003 | 4 | 4 | 0 |
| T004 | 3 | 3 | 0 |
| T005 | 4 | 4 | 0 |
| T006 | 3 | 3 | 0 |

**Average variance**: +/- 0

The slice fit 20/20 with no overrun and no capacity raise — the restored 20 SP cap
held, and the iteration-001 26 SP temporary override did not leak into this plan.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | Plan, 20/20 capacity check, split guard kept live. |
| Discovery/Spikes | 2 | 2 | 0 | T001 confirmed the manifest-driven premise against INSTALLED host CLIs; no split-guard fired. |
| Implementation | 11 | 11 | 0 | T002-T004 reused the registry/manifest machinery; single-source fragment + 3-copy mirror held. |
| Review | 4 | 4 | 0 | T005 automated coverage + the review packet; absorbed the SC-005 evidence-correction rounds. |
| Rework | 2 | 2 | 0 | Buffer covered the SC-005 overclaim correction and the weak-model caveat framing; implementation needed no repair. |

## Drift Summary

- Total drift events: 0 (no specification drift — implementation matched the spec)
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0
- Runtime/process events recorded separately in drift-log.md: the session-start integrity event (closed-iteration re-scaffold from a stale cursor), the deferred follow-ups (Proposals 180 / 142 / 143 + two nits), and the pre-iteration-closeout `verdict_history` reconciliation flag.

## What Went Well

- The iteration-001 lesson — "no-coupling claims need a negative test, not code reading" — was applied **up front** (T005), not as a late send-back. The host-coupling firewall now guards the new instruction-delivery core, and its negative test proves it fails-closed on a planted single-host literal and passes clean manifest-driven content.
- Single-sourcing worked: the FR-013 guard comes from one fragment via `Get-SpecrewCoordinatorFragment`, so the persistent file, the 3 InstructionsFiles, and the bootstrap cannot drift; the 3-copy bootstrap mirror stayed byte-identical (ProviderMirrorParity).
- Real-host validation confirmed the thesis for strong models: on `agy` (Opus) and Claude the agent came up as the Specrew coordinator and drove the governed workshop — no raw `specify.exe` — with same-host and cross-host resume holding; the iteration-001 stale-cursor re-scaffold did NOT recur.
- FR-017's "honest weak-model caveat" was genuinely met: Gemini Flash's boundary-discipline failure was recorded as **evidence, not softened to a pass**.
- The 20 SP cap held against iteration-001's 26 SP override — the restoration discipline worked.

## What Didn't Go Well

- **The SC-005 evidence overclaim.** The real-host evidence said `start-context.json` was "byte-unchanged even under Flash," which directly contradicted the Proposal-142 verdict-ledger reset recorded in the same file. The reviewer caught it; the first correction fixed two files but **missed the canonical state.md**, which the reviewer caught on a second pass. A grep-for-all-instances on the first correction would have closed it in one round.
- **Cooperative enforcement did not hold the weak model.** Gemini Flash self-authorized `specify → clarify → plan` despite the persistent instructions AND the refocus digest both stating a human verdict was required. Textual/cooperative governance is insufficient for a weak coordinator.
- **The boundary ledger is unreliable.** `verdict_history` is internally scrambled (out-of-order entries, `verdict_text` disagreeing with its own transition, feature-closeout approvals present while the cursor sits earlier) — pre-existing Proposal-142 resume churn, now flagged for pre-iteration-closeout reconciliation.
- **The session-start integrity event.** At this session's start the resume machinery re-scaffolded the already-closed iteration 001 from a stale cursor; it was reverted, reconciled, and filed.

## Lessons Learned

- When correcting a cross-artifact claim, **grep for every instance** (canonical state.md + evidence + review) before re-presenting. Honest State (Rule 7) means the canonical artifact must agree with the evidence; a partial fix is itself a violation.
- A weak model cannot hold the governance seat under cooperative enforcement alone. Until a deterministic gate exists (Proposal 180), the coordinator must be a strong model — the maintainer's standing decision.
- Applying a prior retro's lesson **proactively** pays off: the up-front firewall negative test (from iteration 001) prevented the abstraction-leak class entirely this time.
- Evidence-over-testimony review earns its cost: the reviewer's independent verify-the-committed-tree pass caught a real overclaim that the green validator and the self-review both missed.

## Improvement Actions

1. Owner: Reviewer | Phase: next review-signoff | Type: review-method | Expected effect: when correcting any cross-artifact claim, grep ALL instances (state.md + evidence + review) and re-confirm clean before re-presenting.
2. Owner: Maintainer | Phase: pre-iteration-closeout | Type: state-integrity | Expected effect: reconcile or explicitly accept the scrambled `verdict_history` (Proposal 142) before iteration-closeout reads it.
3. Owner: Maintainer/Planner | Phase: methodology backlog | Type: enforcement | Expected effect: prioritize Proposal 180 (deterministic PreToolUse gate) — the weak-model self-authorization is the empirical proof cooperative enforcement is insufficient.
4. Owner: Release Steward | Phase: release gate | Type: validation | Expected effect: keep the machine-local `agy` evidence label; validate `MigrateLegacyTopLevelEventMap` before stable; honor beta-before-stable.
5. Owner: Maintainer | Phase: next host slice | Type: content-contract | Expected effect: address the cold-init dangling reference (Proposal 143) — make the coordinator fragment absence-tolerant or seed greenfield/brownfield orientation at init.

## Reviewer Instruction Candidates

| Candidate | Disposition | Rationale |
| --- | --- | --- |
| Grep-all-instances when correcting a cross-artifact claim. | promote | The SC-005 two-file fix missed state.md; the canonical artifact must agree with evidence. |
| Treat weak-model boundary-discipline failure as a deterministic-gate signal, not a hardening target. | promote | Flash self-authorized despite instructions + digest; only Proposal 180 stops it. |
| Require a behavioral probe for any docs-corroborated scope-defer. | defer | The `AGENTS.md → GEMINI.md` priority stayed docs-only; the maintainer accepted it, but a behavioral probe would strengthen future defers. |
| Re-run the firewall/mirror at review even when only artifacts changed. | drop | The three review commits touched only iteration artifacts; the clean tree + green scoped validator already cover the untouched core. |

## Signals for Next Iteration

- **Proposal 180 (deterministic lifecycle gate) is now empirically motivated** — the headline post-184 follow-up; the weak-model gate-skip is the evidence.
- The `verdict_history` reconciliation (Proposal 142) is a **pre-iteration-closeout obligation**, not optional.
- Release carry-forwards remain OPEN (SC-018): beta-before-stable, `MigrateLegacyTopLevelEventMap` legacy-upgrade validation, machine-local `agy` evidence (gathered — keep the label). No stable/full-parity claim.
- The `AGENTS.md → GEMINI.md` behavioral probe stayed unrun (docs-corroborated, accepted); a future slice could run the staged BANANA/APPLE probe.
- Filed nits: the cold-init dangling reference (Proposal 143), the Antigravity transcript-parser raw-tail fallback, and the concurrent-session false advisory.
- The maintainer is expanding scope to carry this iteration through feature-closeout and a beta PR (recorded as an explicit scope decision in drift-log.md), beyond the plan's original "feature-closeout is not authorized in this iteration."

## Calibration Suggestion

- Suggested capacity adjustment: keep the project baseline at 20 story_points (no change).
- Rationale: the focused host-instruction slice fit 20/20 with zero variance and no overrun. The iteration-001 26 SP override was correctly treated as temporary historical truth and did not leak into this plan; 20 SP is the right baseline for the next host/refocus slice, splitting rather than raising if it grows.

## Notes

- Review-signoff accepted at `7d170b8c` after the SC-005 evidence-overclaim correction (a Proposal-145 send-back the reviewer drove by verifying the committed tree, not the testimony).
- The scrambled `verdict_history` (Proposal 142) is flagged in drift-log.md for reconcile-or-accept before iteration-closeout.
- No specification drift occurred; runtime/process events are recorded in drift-log.md, not as spec drift.
