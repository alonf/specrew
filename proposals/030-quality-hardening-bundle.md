---
proposal: 030
title: Quality Hardening Bundle (Form-vs-Meaning Verification)
status: draft
phase: phase-2
estimated-sp: 35
discussion: tbd
---

# Quality Hardening Bundle (Form-vs-Meaning Verification)

## Why

After Feature 017 (Velocity Dashboard) and Feature 018 (Visual Richness) shipped, a recurring bug class became visible: features pass every safety net Specrew currently has — validator, unit tests, integration tests, hardening gate, pre-implementation review — but ship with wrong real-environment behavior.

The pattern is **form-correct, meaning-wrong**: tests measure the renderer's output shape given synthetic inputs, but don't measure whether the renderer correctly *interprets* the real environment. Hardening gate items get marked "ready" via self-attestation. Validator checks file shapes. Nothing exercises the actual end-to-end user-visible behavior.

Concrete instances observed across F-017 + F-018:
- Active feature status derivation false-positive ("Shipped" when not merged)
- Velocity math with "high confidence" label despite implausible numbers
- Iteration SP reading as 0 because state.md used "~18" approximation marker
- ETA labels claiming "shipped" when scope wasn't shipped
- Rich-mode rendering never activates in real PowerShell terminals (`[Console]::IsOutputRedirected` trap)
- WARN message says "Output is redirected" regardless of actual cause
- Recent Shipped duplicate iteration entries
- Roadmap phase status markers uniform across all phase states

All eight instances passed validator + tests + hardening gate. The bugs were only caught when a human ran the feature in a real terminal. This is a structural verification gap — not a one-off oversight.

Without this bundle, every subsequent feature is at risk of the same pattern. Multiplied across Phase 2's 10+ planned features, the unmitigated repair-cycle cost is significant. Multi-developer and multi-host work (Phase 4-5) compound the risk because environment-dependence increases.

## What

Four-component bundle that gets PRIORITY ELEVATION ahead of other Phase 2 work because quality affects every subsequent feature:

### Component 1: Empirical Meaning-Verification at Review Boundary (NEW FEATURE, ~10-15 SP)

A new lifecycle artifact at the review boundary: `meaning-verification.md`. For every feature producing user-visible output, the artifact captures:
- Each FR producing user-visible output or environment-dependent behavior
- The verification mode performed (Squad self-test / human terminal verification / fixture replay)
- The verification outcome with concrete evidence (output sample, measurement, screenshot)
- Honest disclosure of which environments were tested vs which weren't

The review boundary's "accepted" verdict requires this artifact to show empirical evidence, not just form-correctness from validator + tests. Extends Feature 016's substantive-interaction model from boundary handoffs to the review surface specifically.

### Component 2: Validator Hardening scope expansion (~10 SP additional)

Absorbs four corpus rows captured during F-018's lifecycle into the already-queued Validator Hardening feature:
- `is-output-redirected-unreliable-in-powershell-scripts` — flag use as TTY signal
- `subshell-loses-parent-console-encoding` — flag entry scripts that render Unicode without encoding setup
- `boundary-commit-not-pushed-at-end-of-boundary` — at `specrew start`, warn when local HEAD differs from origin
- `hardening-gate-self-attestation-without-evidence` — flag hardening-gate items marked "ready" without test fixture or measurement
- `synthetic-profile-bypass` — flag tests using capability overrides without at least one real-environment test

### Component 3: Spec-Scenario Integration Test Mandate priority promotion (~15 SP)

Originally captured in private notes 2026-05-13 as a Phase 2 candidate. F-018 reinforces priority: every feature producing user-visible behavior must have at least one integration test that runs end-to-end in the real environment, not via capability-override short-circuits.

### Component 4: Process changes via coordinator prompts (~2-3 SP)

Lightweight chore updates to coordinator-prompt files:
- "Boundary completion includes push" — explicit rule that Squad's "stop at boundary" means commit + push, not just commit
- "PoC-parity audit before /speckit.specify" — when a feature references a PoC as shaping reference, mandate explicit audit before spec ingestion
- "Form vs meaning at review boundary" — explicit rule distinguishing form-correctness verification from meaning-correctness verification

## Effort

- **Component 1**: ~10-15 SP, 1-2 iterations
- **Component 2**: ~10 SP additional to existing queued Validator Hardening feature
- **Component 3**: ~15 SP, 1-2 iterations (already estimated in 2026-05-13 notes)
- **Component 4**: ~2-3 SP, chore-commit scope
- **Total bundle**: ~30-40 SP across 3-4 features

## Phase placement

**Phase 2, FIRST priority** — ahead of Session-State Durability, Branch Reconciliation, and other Phase 2 features.

Sequencing:
1. F-018 close + retro + iteration-closeout + feature-closeout (in flight at proposal date)
2. Stage 1 chore (immediate session-state fix, ~3 hours)
3. **Quality Hardening Bundle** (this proposal, ~30-40 SP)
4. Then: Session-State Durability, Branch Reconciliation, etc.

Rationale for priority elevation:
- The form-vs-meaning bug class compounds across features. Catching it early is cheaper than catching it 5+ times.
- State-foundation features themselves produce environment-dependent behavior — they need the quality machinery.
- Quality is load-bearing for public flip equity.

## Open questions

1. Should the meaning-verification artifact replace or augment the existing review.md?
2. Self-attestation flag severity: soft warning vs hard fail?
3. Which features qualify as "environment-dependent"? Explicit list or heuristic detection?
4. Validator rule scope: detect synthetic-only tests across all features or only flagged ones?
5. Is the bundle one feature (sequencing all four components together) or multiple parallel features?
6. How do the four components compose with the queued Outcome Scoring concept (Phase 4)?

## Risks

- **Process overhead risk**: more verification steps may slow feature velocity. Mitigation: focus the meaning-verification mandate on environment-dependent features only; cosmetic-only features stay light.
- **Self-attestation gaming**: any verification protocol can be filled in superficially. Mitigation: validator rule that flags "ready" without evidence; reviewer judgment on substance.
- **Test-fixture complexity**: real-environment tests are harder to write than synthetic-profile tests. Mitigation: provide test-harness scaffolding as part of Component 3; document patterns.

## Cross-references

- Feature 016 Substantive Interaction Model — extends to review surface
- Feature 017 Velocity Dashboard — empirical bug source for form-vs-meaning class
- Feature 018 Velocity Dashboard Visual Richness — empirical bug source + corpus rows
- Proposal 004 (Validator Hardening) — Component 2 absorbs additional scope
- Proposal 020 (Spec-Scenario Integration Test Mandate) — Component 3 promotion
- Proposal 016 (Outcome Scoring) — future composition for empirical methodology measurement

## Status history

- 2026-05-16: captured after F-018 retro question surfaced the meta-bug-class observation; user direction to elevate priority because quality is load-bearing for adoption
