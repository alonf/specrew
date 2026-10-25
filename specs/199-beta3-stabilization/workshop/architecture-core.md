# Architecture-Core Lens Record: 199-beta3-stabilization

**Feature**: 199-beta3-stabilization
**Depth**: medium
**Captured**: 2026-08-10
**Confirmation**: human-confirmed (typed "all — recommendations D1 through D5 accepted", with one addition to D3)

## The campaign machinery as shipped (grounding diagram)

```text
ROUND ENGINE (runs a review round)
  specrew-review.ps1 (CLI)
     └─> review-campaign-orchestrator.ps1 :: Invoke-ReviewCampaignRun
           reserve -> preflight -> claim -> spend -> invoke reviewer -> ingest
              |          |                                               |
              |          X  preflight failure still publishes a run      v
              |             record + charges the round (ledger F4)    result.json
              |                                                (findings, severity,
              v                                                 duration_ms)
        review-authority-core.ps1        review-authority-store.ps1
        (pure allowance/spend decisions) (facts on disk; also owns the
                                          reparse-point refusal, F1)
           LOOP DEFAULT: continue-until-clean — no pause, no economics (F8)

STOP SURFACE (a parallel governor, fires at session Stop)
  hook dispatcher -> worktree-navigator.ps1
     └─> review-signoff-evidence-gate.ps1 :: Resolve-ReviewCampaignVerdictPacketDecision
           emits review-stale / review-timeout / review-partial
           BLIND to: the signoff-gate decision, authorized in-flight runs,
                     records-only commits                        (F5)
     └─> Build-ReviewCampaignNavigatorStopBlock — "digest", "crossing" prose (F6)

SIGNOFF GATE (the OTHER governor — the two disagreed live in T067)
  Get-ContinuousCoReviewSignoffGateDecision
     └─> writes .specrew/review/signoff-gate/latest.json
```

## Decisions (all human-confirmed 2026-08-10)

### D1 — Decomposition style (binding constraint)

Bind beta3 to the codebase's existing layering: pure decision functions in the authority
core (`review-authority-core.ps1`), persistence in the store, workflow in orchestrators,
Stop-surface rendering in navigators. New decision logic (pause verdicts, round
accounting, stale suppression) lands as pure functions in the core; rendering lands in
navigators/templates; no new layers.

### D2 — Pause ownership (bridge, ledger item 1)

The pause is the ORCHESTRATOR'S TERMINAL STATE: after every round's ingest, the engine
renders the decision surface and exits — spend stops, console frees. Rejected
alternative: Stop-hook interception of a still-running loop (ruled out by T067's
held-console evidence — the intervention point must not depend on the hook layer).
**Beta4 replacement note**: beta4's redesigned disposition/economics pipeline replaces
the pause plumbing; the decision-surface contract (what the human sees) is durable.

### D3 — Single stop authority (bridge, ledger item 2)

All three checks land at the stale classifier's two emit sites in
`Resolve-ReviewCampaignVerdictPacketDecision` (review-signoff-evidence-gate.ps1:368/:385):
(1) consult `.specrew/review/signoff-gate/latest.json` before emitting a block;
(2) an authorized in-flight run suppresses the block;
(3) governance/records-only deltas never stale a reviewed digest.
Navigators above the classifier stay dumb.

**Human addition (recorded verbatim in intent)**: a PENDING PAUSE DECISION — round
completed on the current tree, decision surface rendered, human not yet answered — is a
sanctioned state in its own right. The stop governor treats it as QUIET: it demands
neither a review nor a disposition while the pause decision is pending.
**Beta4 replacement note**: beta4's stop-surface state model (author-attributed deltas,
in-flight modeling) subsumes these point checks; the consult-before-block ordering and
the pending-decision-is-quiet rule are the durable semantics.

### D4 — Composed "stop here" landing (bridge, ledger item 1)

One new orchestrator-level action chains the EXISTING pieces as a single human choice:
frozen-tree verification run -> identity-bound residual acceptance -> gate sync.
Composition only — no new authority semantics (beta4 redesigns disposition vocabulary).
Rationale: T067's endgame proved a bare stop ruling wedges against the signoff gate;
the human must never discover that collision by hand.
**Beta4 replacement note**: beta4's disposition vocabulary replaces the underlying
acceptance primitives; the one-action landing UX contract is durable.

### D5 — Bridge/durable seams

- **Bridge** (minimal, beta4 rebuilds the machinery): D2 pause plumbing, D3 classifier
  checks, D4 landing composition.
- **Durable** (survives beta4): verdict capture (`ConversationCaptureAccessor.ps1`),
  reparse-tag discrimination (store integrity check), init verification-plan
  scaffolding, reviewer-host window catalog rows, banner prerelease version, the
  consumer-language layer (navigator prose, packet templates, skills).

## Key seams found in the machinery map (implementation anchors)

- `review-stale` is emitted from exactly two lines of one function — D3's whole seam.
- The legacy engine already has the F4 accounting rule (`Get-ContinuousCoReviewRoundSpendClass`:
  preflight-failed is free); the campaign engine's `Complete-ReviewPreInvocationFailure`
  path is what charges wrongly.
- Banner bug is `specrew-bootstrap-provider.ps1:438` reading `ModuleVersion` and ignoring
  `PrivateData.PSData.Prerelease`; `specrew-start.ps1:Get-ManifestSpecrewVersionText` is
  the correct reference implementation. Mirror copy must update in lockstep.
