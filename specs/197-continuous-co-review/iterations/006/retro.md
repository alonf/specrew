# Iteration 006 Retro

**Feature**: 197-continuous-co-review
**Iteration**: 006 (real reviewer + full-findings reporting, T082–T086)
**Date**: 2026-06-24
**Provenance**: RECONSTRUCTED 2026-07-01 from this iteration's review.md + git history (iteration 006 reached the review phase with an accepted verdict + a passing live e2e, but was superseded by iteration 007 before a formal retro was authored). Distilled from recorded evidence only — no invented reflection.

## What went well

- The **live-dispatcher end-to-end proof**: codex fired via the real dispatcher and landed 6 findings at two severities (blocking + advisory) in `inline/<run-id>/findings-result.json`, surfaced as the stop-block, with codex selected independent of the claude code-writer and the source file left UNMUTATED (`069b21b0`; review.md T085). This was the meaningful "real findings reach the developer through the live hook path" proof.
- The **adversarial Proposal-145 review out-performed green tests on soundness** again: it caught M1 (below) that the 12 deterministic wiring tests + the accept all missed.

## What hurt (friction -> learning)

1. **"Code-writer-independent" was independent by config accident, not by logic (M1, MAJOR).** Independence depended on `SPECREW_HOST`/`SPECREW_ACTIVE_HOST`, which Specrew never sets; the provider discarded `--host-kind`, so the policy tiebroke alphabetically and could pick claude to review claude's own code — held only by the codex-only authorization config. **Learning: a safety-critical property (reviewer independence) must be guaranteed by logic + a test with the env UNSET, never by an ambient default.** Fixed `ecf7c768` (`--host-kind` → `-CodeWriterHost` → policy; env fallback-only; param-path test).
2. **Green tests hid a mocked seam (M1 corollary + G-197-I006-03).** The deterministic tests MOCKED `Select-...ReviewerCandidate`, so the un-wired selection + the missing persisted authorization stayed invisible until the live run. **Learning: mock the reviewer, not the selection policy — the un-mocked policy path needs its own test.** (Same "green != live-wired" theme as iteration 005.)
3. **First-live-run failures only the live e2e surfaced (G-197-I006-04):** `_load` load-order left the navigator no-op'ing on every live Stop, and a missing composer SchemaRoot let codex emit schema-mismatched output that silently lost a real review. Fixed `289addba`. **Learning: a live-dispatch smoke is not optional for a hook-fired feature.**
4. **A per-path git subprocess in the dedup digest ran ~24 s on a deployed `.specify` (G-197-I006-05),** blowing the dispatcher budget so the navigator never fired in real projects. Fixed `97b4eb91` (batched, 24 s → 1.5 s). **Learning: budget-bounded hook work must be measured on a deployed-size repo, not the source tree.**

## Estimation Accuracy

Not reliably reconstructable — iteration 006's SP plan is a post-hoc record; planned-vs-actual variance is not evidenced in git. (No estimation claim is fabricated here.)

## Drift Summary

No specification drift recorded for iteration 006 (`drift-log.md`: 0 events). The M1/M2 + G-03..G-05 items were implementation/wiring defects the review + live e2e caught and fixed within the iteration, not spec drift.

## Improvement Actions

- [x] Wire reviewer-independence by logic + prove it with env UNSET (`ecf7c768`).
- [x] Persisted human-authorization seam + a NON-MOCKED selection test (`6a24838b`).
- [x] Run the live-dispatcher multi-severity e2e as the acceptance proof (`069b21b0`).
- [ ] Carry the "mock the reviewer, not the policy" + "measure hook budget on a deployed-size repo" lessons forward (relevant to iter-009/010 robustness).

## Process Notes

- Reconstructed post-hoc for governance completeness (2026-07-01). The authoritative contemporaneous record is this iteration's review.md (verdict `accepted`; NEEDS-WORK M1/M2 fixed) + the closeout-validation. Iteration 006 was **superseded by iteration 007** before a formal review-signoff/retro was executed — that supersession is its honest closeout status.
