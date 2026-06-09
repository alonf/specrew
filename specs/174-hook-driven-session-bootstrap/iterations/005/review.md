# Review: Iteration 005

**Schema**: v1
**Reviewed**: 2026-06-09
**Overall Verdict**: accepted

Structured per Proposal 145. Matrix + claim ledger + design-code trace in
[review-report.yml](./review-report.yml). The implementation report is treated as a claim to
disprove. This iteration fixes the hollow-handover finding: the rolling-handover BODY becomes
AGENT-authored (the Stop hook is transcript-blind), with a NON-BLOCKING mechanical detector - scoped
honestly as failure-mode A (plumbing, CI-blocking) vs failure-mode B (authoring, detected-not-prevented).

## Live-Wiring Qualification (corrected post-verdict)

**This section corrects the originally-presented verdict.** The phase narrative and claim ledger below
were written as if the surfacing/handover round-trip were DELIVERED. They are not - not LIVE. Every smoke
in this iteration ran in the DEV tree, where the provider resolves its components via
`$PSScriptRoot/bootstrap` (co-located). In a DEPLOYED downstream project the Stop provider cannot resolve
HandoverStore (the bootstrap components are not deployed there, and SPECREW_MODULE_PATH does not reach the
Stop-hook child), so the agent-authored handover silently never fires (PROVIDER_FAILED, no file). The
failure-mode-A "floor" asserted persisted-bytes == surfaced-bytes but NEVER that the provider can RESOLVE
the persisting code in a deployed tree - a pledge dressed as the mechanism, the same build != live class
as F-054 and the iter-3 D-002 send-back (drift D-009).

What iteration 5 DOES deliver and the human approved: the dev-tree body-authoring machinery (floor/body
split, `Write-SpecrewHandoverContext`, the non-blocking detector, the bootstrap render) is BUILT,
unit-tested, and reviewable. FR-022's LIVE (deployed-tree) behavior is **deferred** to iteration 6
(canonical defer entry `f174-i005-defer-live-wiring` in `.squad\decisions.md`), which must carry a
live-wiring floor asserting a real deployed session writes the contract + handover to disk. Read every
"delivered / surfaces / fires" claim below as **dev-tree-verified, not deployed-verified**. The human's
verdict was APPROVE WITH QUALIFICATION on that basis (`f174-i005-review-signoff-qualified`).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T029 | FR-022, FR-009 | pass | HandoverStore floor/body split + Write-SpecrewHandoverContext (agent authors the body, renders FROM the file) + hook preserve-or-placeholder. Smoke-verified. |
| T030 | FR-022, FR-009 | pass | Stop provider (option-1): preserve the body for the current boundary, else placeholder; non-blocking same-session hollow detection (stderr + handover-journal). Provider smoke verified. |
| T031 | FR-022 | pass | Test-SpecrewHandoverBodyPlaceholder (pure, structural; authored / marker / null). |
| T032 | FR-022, FR-010 | pass | DirectiveEngine handover field; manager surfaces body + placeholder; provider renders the rich body / prominent HOLLOW warn / author-before-stop protocol. Render asserted A7/A8. |
| T033 | FR-022, SC-010 | pass | AgentAuthoredHandover.Tests: A1-A8 (CI-blocking plumbing floor incl. the provider render) + B1-B2 (non-blocking detection). 19/19 suites green. |
| T034 | FR-022, FR-008 | pass | Spec FR-022 + SC-010 + FR-009/FR-010 reconcile + SC-003/SC-007/US-3 extends (carry #1 spec-wide; zero stale refs); docs updated. |

## Seven-Phase Structured Review (Proposal 145)

- **Phase 0 - Context load**: pass. Loaded spec.md (reconciled), iterations/005 plan + hardening-gate, the
  approved design + carries (`f174-i005-before-implement-approved`, `f174-i005-mechanical-detector-in-scope`),
  and drift D-008 (the P1 ceiling that reshaped instruction #2 into option-1).
- **Phase 1 - Branch hygiene**: pass. before-implement committed (`995eb3d7`); the implementation is staged
  in the working tree (the boundary commit lands at this review). Branch unpushed (push held to
  feature-closeout per the human - ship 1-5 together).
- **Phase 2 - Functional correctness**: pass. The agent authors the body (Write-SpecrewHandoverContext) and
  renders FROM the file (human-sees == successor-inherits). The hook refreshes the floor + PRESERVES the
  agent body for the current boundary, writing a placeholder only when none exists (smoke + A3/A4). The
  bootstrap surfaces the rich body on resume (A5/A7) and a PROMINENT hollow warn on a placeholder (A6/A8).
- **Phase 3 - Non-functional**: pass. Local + gitignored + write-only unchanged (FR-021); fail-open; the
  detector is NON-BLOCKING (P1); the material-change gate keeps quiet Stops cheap.
- **Phase 4 - Code quality**: pass. PSScriptAnalyzer 0 findings on the 6 changed scripts; clean IDesign
  seams (ResourceAccessor HandoverStore, pure ClassificationEngine detector, manager orchestration).
- **Phase 5 - Test coverage + integrity**: pass. **Carry #2 honored**: the CI-blocking failure-mode-A floor
  tests the PLUMBING round-trip (persisted bytes == surfaced bytes, A2/A5), NOT an agent-display claim - so
  it does not depend on the B authoring behavior. A7/A8 assert the PROVIDER render (the user-facing prose).
  B1/B2 assert the non-blocking detection. 19/19 bootstrap suites green. **The review found + closed a
  coverage gap**: the provider-render path was untested before A7/A8.
- **Phase 6 - System safety + ops**: pass. The detector never blocks (P1 fail-open; the provider exits 0);
  B1/B3 unchanged (Regression test); the journal detection (`hollow-handover-at-stop`) is observable
  (SC-007). **Honesty check (the iter-5 lesson on its own deliverable)**: SC-010 + D-008 encode
  detect-NOT-prevent; nothing claims authoring is mechanically forced.
- **Phase 7 - Synthesis + falsification**: APPROVE for review-signoff. All phases pass; claims map to
  committed files + reproduced smokes/tests; no claim exceeds its evidence (the detector is honestly a weak
  enforcer, not parity with a blocking gate); no new dependencies.

## Gap Ledger

- Provider-render coverage gap (the HOLLOW warn + the protocol line were untested) is closed by tests A7/A8: fixed-now.
- Stale spec ref (US-3 acceptance scenario 1 implied the hook authors the handover) corrected to the floor/body split: fixed-now.
- FR-022 LIVE (deployed-tree) wiring is deferred to iteration 6: the agent-authored handover does not fire in a deployed downstream project (all iter-5 smokes ran in the dev tree where the provider resolves components via `$PSScriptRoot/bootstrap`); canonical defer entry `f174-i005-defer-live-wiring` in `.squad\decisions.md`. See the Live-Wiring Qualification section + drift D-009.

## Follow-ups (scoped out of iteration 5; not gaps in this delivery — tracked in `.squad/decisions.md`)

- A validator-side handover-body gate (a stronger, BLOCKING enforcement of failure-mode B) — gated on the
  F-174 rebase + the #2216 reconcile (`f174-action4-reconcile-with-2216`); the bootstrap-side detector
  ships now and is sufficient for iteration 5.
- The dormant SessionEnd code cleanup carried from iter-4 (`f174-followup-remove-dormant-sessionend-code`),
  bundled with feature-closeout (non-blocking).
