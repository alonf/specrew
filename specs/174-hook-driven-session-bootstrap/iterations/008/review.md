# Review: Iteration 008

**Schema**: v1
**Reviewed**: 2026-06-11
**Overall Verdict**: accepted

Structured per Proposal 145. This is a **retroactive closure artifact (2026-06-11)**: iteration 008 closed at
the boundary (commit `7fe04228 boundary(iteration): close iter-008, open iter-009`) without a committed
review.md/retro.md; this record reconstructs the documented review outcome from the iteration's plan.md +
state.md closure narrative and the iter-005/006 precedent. Iteration 008 delivered its three maintainer asks
on the all-hosts-green baseline: T048 (reposition `specrew start` as optional, FR-008), T049 (user-profile
intake at `specrew init`, FR-025), T050 (rolling-handover validation across exit modes, FR-022), and T051
(session-continuity documentation). The **delivered scope is ACCEPTED**; T050's validation surfaced a finding
— the rolling handover is HOLLOW in practice — which is the deliberate **carry to iteration 009** (read the
Handover-Quality Qualification + Gap Ledger before any "the handover works" reading).

## Handover-Quality Qualification (the carry to iteration 009)

T050's multi-host (claude / codex / copilot) exit-resume dogfood PROVED the resume re-anchor works across
exit, restart, and host-switch, AND it found + fixed two real bugs in-iteration (the deployable-mirror skew,
D-013; the anchorless-workshop no-surface bug, D-014). But it ALSO found the rolling-handover **BODY is
hollow in practice** (84/84 and 15/15 `hollow-handover-at-stop` across the dogfood worktrees): authoring was
agent-/gate-dependent and the Stop hook is transcript-blind, so build / workshop / kill-mid-flight stops
never authored, and the most valuable moment (mid-implement, uncommitted) was the hollowest. **This is not a
failure of T050 — the validation did exactly its job: it surfaced the gap before it shipped silently.** The
architectural fix (the Stop hook becomes the PRIMARY delta-author) is iteration 009 (drift D-012, defer entry
`f174-i008-defer-hollow-handover-to-009`). Read "the handover surfaces / persists" as **mechanically present
but hollow in practice — fixed in iteration 009**.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T048 | FR-008, FR-001 | pass | `specrew start` repositioned as an optional host-selector / launcher (README Quick Start + getting-started + host-pick note + CHANGELOG); after `specrew init` the SessionStart hook drives. |
| T049 | FR-025 | pass | User-profile intake moved to `specrew init` (`Invoke-SpecrewInitProfileCapture`): asks only when ABSENT + INTERACTIVE; skips silently on `-Force`/CI (the load-bearing no-hang guard); retains the `specrew start` fallback + a hook nudge. `SPECREW_USER_PROFILE_PATH` seam + user-profile-init-capture.tests.ps1 (7/7). |
| T050 | FR-022, FR-009 | pass | Rolling-handover validation across exit modes + the cross-host dogfood. Found + FIXED the deployable-mirror skew (D-013) and the anchorless-workshop no-surface bug (D-014); 4 resolver unit tests + 1 integration test + bootstrap 20/20. Surfaced the hollow-handover finding (D-012) -> deferred to iter-009. The validation succeeded; the finding is the carry, not a task failure. |
| T051 | FR-008, FR-022 | pass | Session-continuity documentation: user-guide "Session Continuity" section + 3 troubleshooting entries + symptom-guide rows + the design-workshop checkpoint-timing conduct (agenda-persist-at-confirm + per-lens persistence). |

## Seven-Phase Structured Review (Proposal 145)

- **Phase 0 — Context load**: pass. spec.md (FR-025 added), the iter-008 scope (3 maintainer asks on the all-hosts-green baseline), and the iter-7 FR-024 multi-host completion it builds on.
- **Phase 1 — Branch hygiene**: pass. Work committed on the feature branch; boundary-close commit `7fe04228` opened iteration 009 on the hollow-handover finding.
- **Phase 2 — Functional correctness**: pass (for the delivered scope). Docs repositioned (T048); intake-at-init guarded interactive with the no-hang skip (T049); the handover wrote at Stop after the mirror-skew + anchorless fixes (T050); continuity docs (T051).
- **Phase 3 — Non-functional**: pass. The intake skip is the load-bearing no-hang guard (CI / `-Force` / piped); fail-open; the handover stays local + write-only.
- **Phase 4 — Code quality**: pass. The mirror-parity guard (ProviderMirrorParity.Tests) prevents the deployable-skew recurrence; the branch-feature resolver is a clean fail-safe accessor.
- **Phase 5 — Test coverage + integrity**: pass. user-profile-init-capture (7/7), the resolver units (4), the anchorless-workshop integration test, bootstrap suite 20/20, the E2E no-hang + invalid->valid->welcome-back checks.
- **Phase 6 — System safety + ops**: pass. The cross-host dogfood is the live-behavior check that surfaced the hollow-handover gap — the honest `build != live` discipline working as intended.
- **Phase 7 — Synthesis + falsification**: **ACCEPT (delivered scope), with the hollow-handover finding formally DEFERRED to iteration 009.** T048-T051 delivered + tested; the validation surfaced FR-022's practical-quality gap, carried to iteration 009. No claim that the handover is rich-in-practice survives this review.

## Gap Ledger

- The rolling handover is HOLLOW in practice (FR-022 practical quality: authoring agent-/gate-dependent, the Stop hook transcript-blind, the build != live class) is DEFERRED to iteration 009 where the Stop hook becomes the PRIMARY delta-author (never hollow, host-universal). Canonical defer entry `f174-i008-defer-hollow-handover-to-009` in `.squad\decisions.md` (drift D-012).
- Deployable-mirror skew (the handover never wrote at Stop in a deployed layout): fixed-now — the mirror was re-synced byte-identical + the ProviderMirrorParity guard added (drift D-013).
- Anchorless-workshop handover never surfaced (blank feature_ref -> no-feature): fixed-now — the Stop floor-writer resolves the feature from the current branch (drift D-014).

## Follow-ups (scoped out of iteration 8; tracked in `.squad/decisions.md`)

- The early-anchor central-state write-back (the prior design for the anchorless case) is DEFERRED — the handover-first resolution made it unnecessary for iteration 008; revisit only if a non-handover consumer needs the eager anchor.
- `Get-SpecrewSessionDelta` should exclude/deprioritize the Specrew-managed dirs so the user's real source is not pushed past the delta file cap (surfaced in the iter-009 dogfood, tracked there).
