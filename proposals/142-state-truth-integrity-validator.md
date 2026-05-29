---
proposal: 142
title: State-Truth Integrity Validator (Cross-Artifact Lifecycle Consistency Enforcement)
status: draft
phase: phase-2
estimated-sp: 3-5
priority-tier: 1
type: tooling
discussion: surfaced 2026-05-29 by second empirical instance of iteration-closeout state-artifact-truth gap within F-049 alone (instances 2 + 5 in [[cross-reviewer-3rd-empirical-instance-2026-05-28]]); cross-reviewer caught both via reading state-artifact contents but no tooling enforcement exists
composes-with:
  - 102  # Cross-Model Independent Reviewer — defense-in-depth layer 3
  - 120  # Handoff-Block Validator Enforcement — defense-in-depth layer parallel
  - 132  # Mirror-Parity Validator Enforcement — same pattern (cross-artifact consistency)
  - 140  # Reviewer Instruction Surface — defense-in-depth layer 2 (reviewer-charter discipline)
audience: tooling
---

# State-Truth Integrity Validator (Cross-Artifact Lifecycle Consistency Enforcement)

## Why

Specrew has multiple durable state-truth artifacts that independently track lifecycle position:

- `specs/<feature>/iterations/<N>/state.md` — per-iteration phase + transitions + prose
- `.squad/identity/now.md` — Crew session-state frontmatter + focus_area + body prose
- `.specrew/start-context.json` — `boundary_enforcement.last_authorized_boundary` + `verdict_history` + `session_state` fields
- `.specrew/last-start-prompt.md` — session-state frontmatter + welcome-back snapshot
- `.squad/decisions.md` — routing + decision-entry log

These files are written on lifecycle transitions but updated INDEPENDENTLY by different code paths. Drift between them accumulates silently, and the cross-artifact inconsistency is invisible to substance-focused review (FR coverage, test pass, evidence audit).

### Empirical motivation: two state-truth integrity catches in F-049 alone

**Instance 1 (2026-05-28, F-049 iter-3 iteration-closeout)**: cross-reviewer (Codex) caught:

1. `review.md` line 7: "retro remains unopened pending fresh human authorization" while `state.md` / `retro.md` / `now.md` all said retro complete
2. `state.md` cited `b34de704` as reviewing→retro transition commit, but `b34de704` was the review-signoff state repair commit; actual retro-establishing commit was `2eba2a91`. **False lifecycle transition provenance baked into git-readable history.**
3. `.specrew/start-context.json` claimed `last_authorized_boundary: retro` but `verdict_history` was missing the corresponding review-signoff→retro entry

**Instance 2 (2026-05-29, F-049 iter-5 iteration-closeout)**: cross-reviewer (Codex, again) caught:

1. `state.md` line 18: "Next boundary is review-signoff (human gate); not auto-advanced." — stale text from end-of-implementation; we were past review-signoff + retro
2. `.squad/identity/now.md` `focus_area` + body prose: "Iteration 005 planning package... awaiting explicit human planning review/approval before implementation." Stale by 4 boundaries (past planning, before-implement, implement, review-signoff, retro)
3. `.specrew/start-context.json` `last_authorized_boundary: iteration-closeout` — **falsely claimed the boundary was already crossed** while we were AT the gate FOR it

Both instances:

- Were caught by cross-reviewer reading state-artifact contents — NOT by single-reviewer Pillar 5 form check or substance audit
- Were caught at iteration-closeout — the boundary class where lifecycle-state is the PRIMARY shipping artifact (no code ships; state-sync ships)
- Required human-discipline reviewer-charter additions to catch durably (per memory `[[cross-reviewer-3rd-empirical-instance-2026-05-28]]` Instance 5 conclusion)

**Two empirical instances of the same failure mode in the same feature warrants tooling enforcement.** Reviewer-charter discipline (Proposal 140) is the human-side fix; this proposal is the mechanical-side fix that runs even without a cross-reviewer.

### Why prose-rule-only is insufficient

Same pattern as `[[proposal-132-mirror-parity-validator-enforcement]]` (mirror parity prose rule → mechanical validator backfill) and `[[proposal-105-host-native-hook-deployment]]`'s "if a prompt says X you have a request; if a hook blocks it you have a boundary" framing. State-truth integrity today is a discipline expectation with no mechanical enforcement.

## What

A validator rule that runs at boundary-recording time (and at each `validate-governance.ps1` invocation) and FAILS with named delta if state-truth artifacts are inconsistent.

### Functional requirements

- **FR-001**: Validator MUST cross-check `state.md` "Current Phase" field against `state.md` prose claims (Execution Summary, Notes section). Inconsistency = FAIL with the conflicting text passages cited.
- **FR-002**: Validator MUST cross-check `.squad/identity/now.md` `focus_area` and body prose against `state.md` Current Phase. If focus_area names a different lifecycle position than state.md says, FAIL with both quoted.
- **FR-003**: Validator MUST cross-check `.specrew/start-context.json` `boundary_enforcement.last_authorized_boundary` against `verdict_history[-1].to_boundary`. Mismatch = FAIL (claims boundary crossed without supporting verdict entry).
- **FR-004**: Validator MUST cross-check `.specrew/start-context.json` `session_state.boundary_type` against `boundary_enforcement.last_authorized_boundary`. Drift = WARN (allows mid-transition states but flags long-lived inconsistency).
- **FR-005**: Validator MUST cross-check `.specrew/last-start-prompt.md` frontmatter session-state fields against `.specrew/start-context.json` session_state. If they diverge, WARN (regenerated artifact may catch up; failure to converge over time = FAIL).
- **FR-006**: At iteration-closeout boundary specifically, validator MUST execute all five checks above as a HARD-BLOCK precondition. iteration-closeout cannot record without state-truth consistency.

### Validator rule shape

```text
RULE state-truth-iteration-closeout (severity: FAIL):
  CONTEXT: iteration is at retro → iteration-closeout gate
  CHECK 1: state.md "Current Phase" matches state.md prose claims
  CHECK 2: now.md focus_area matches current lifecycle position
  CHECK 3: start-context.json last_authorized_boundary == verdict_history[-1].to_boundary
  CHECK 4: start-context.json session_state.boundary_type aligned (WARN if drift)
  CHECK 5: last-start-prompt.md frontmatter aligned (WARN if drift)
  ON FAIL: emit named delta with quoted text passages from each conflicting artifact
```

### Out of scope

- Auto-repair (validator surfaces inconsistency; agent or human repairs)
- Cross-feature state-truth checks (this proposal is per-iteration scoped)
- Squad-side state files outside `.squad/identity/now.md` (decisions.md, team.md, routing.md have their own validators or no validator)
- Validator for lifecycle artifacts that don't have explicit "Current Phase" semantics (plan.md, tasks.md, retro.md — those carry implicit state but not the same way)

## How

Add a new rule to `validate-governance.ps1` (and `shared-governance.ps1` for cross-feature checks).

| Component | File | Effort |
|---|---|---|
| Rule implementation | `extensions/specrew-speckit/scripts/validate-governance.ps1` (new function `Test-StateArtifactTruthIntegrity`) | 1-2 SP |
| Mirror to `.specify/extensions/specrew-speckit/scripts/` | byte-identical copy per FR-014 (Proposal 132 pattern) | 0.2 SP |
| Unit tests for the rule | `tests/governance/state-truth-integrity.tests.ps1` covering: consistent (PASS), state.md prose drift (FAIL), now.md focus_area drift (FAIL), verdict_history mismatch (FAIL), boundary_type drift (WARN), last-start-prompt drift (WARN) | 1-2 SP |
| Integration into iteration-closeout hard-block | `sync-boundary-state.ps1` integration so iteration-closeout fails if validator emits FAIL | 0.3 SP |
| Documentation | `docs/methodology/lifecycle-discipline.md` add State-Truth Integrity section | 0.5 SP |

**Total estimate**: 3-5 SP for a single iteration.

## Composition

### With Proposal 120 (Handoff-Block Validator Enforcement)

120 enforces handoff-block STRUCTURE at validator level. This proposal enforces CROSS-ARTIFACT CONSISTENCY at validator level. Both are mechanical enforcement of disciplines previously prose-only. Could fold this proposal in as Proposal 120 Pillar 6 if 120 hasn't shipped yet; ships standalone otherwise.

### With Proposal 132 (Mirror-Parity Validator Enforcement)

Same pattern (cross-artifact consistency check) on different surface (mirror parity vs. state truth). 132 ships first as the smaller / simpler shape; this proposal follows the same architecture.

### With Proposal 140 (Reviewer Instruction Surface)

140 ships reviewer-charter discipline to catch what tooling misses (semantic claims). This proposal ships tooling to catch what reviewer-discipline misses (mechanical inconsistencies humans skim past). Defense-in-depth across the two layers.

### With Proposal 102 (Cross-Model Independent Reviewer)

102's empirical motivation INCLUDES the same instances this proposal addresses. Once 102 ships, cross-reviewers will catch these gaps as a backup. This proposal makes the catch mechanical and consistent rather than dependent on reviewer attentiveness.

## Risks

- **Validator-friction-against-mid-transition states**: state files are written sequentially during a boundary transition; momentarily inconsistent state is normal. Mitigation: FAIL only at iteration-closeout (final state-sync moment); WARN during in-flight transitions.
- **False-positive on legitimate stale-but-pending content**: e.g., a retro.md that says "(to be filled in)" might trip a prose check. Mitigation: validator is structured-fields-aware; doesn't free-text-grep arbitrary prose.
- **Tooling defect on edge-case state files**: e.g., `last-start-prompt.md` regenerated by `specrew-start` may briefly diverge before convergence. Mitigation: that check is WARN not FAIL; persistent divergence over multiple runs would warrant escalation but not block.

## Empirical motivation captured

- **2026-05-28 F-049 iter-3 iteration-closeout** — Codex cross-reviewer caught 3 state-artifact integrity gaps (review.md stale text + state.md false transition-commit provenance + start-context verdict_history missing entry); single-reviewer Pillar 5 form check missed all three; repair landed at `e85a5ced`
- **2026-05-29 F-049 iter-5 iteration-closeout** — Codex cross-reviewer caught 3 state-artifact integrity gaps AGAIN at same boundary class (state.md prose stale, now.md focus_area stale, start-context.json `last_authorized_boundary` false-already-crossed claim); single-reviewer (Claude in this session) Pillar 5 + substance audit missed all three; repair in progress at proposal draft time

Two empirical instances of the same failure mode in the same feature = strong evidence the boundary class has a specific tooling gap. Iteration-closeout's failure mode is **state-artifact-truth inconsistency**, not substance error.

## Status history

- **2026-05-29** — Drafted as direct response to F-049 iter-5 iteration-closeout state-truth gap (2nd in F-049 alone). Maintainer raised the question "Why can't we enforce the methodology?" The most leveraged single answer is a validator rule at boundary-recording time. This proposal codifies that rule. Ships as draft because empirical motivation is concrete, ~3-5 SP scope is small, and shipping captures immediate methodology lift across all in-flight features.
