# Quickstart: Feature 012 — Descriptive References in Handoffs

**Feature**: `012-descriptive-id-handoffs`  
**Branch**: `012-keep-descriptive-refs`  
**Scope**: Add readable descriptive scope to numeric references in authored handoffs without changing the non-blocking nature of governance review  
**Date**: 2026-05-11

---

## Human Approval Boundary

- Planning is approved and complete for Phase 0 and Phase 1 artifacts.
- Generate `tasks.md` only when a later approved workflow step explicitly requests task generation; until then, do not generate tasks.
- **Do not scaffold iteration artifacts yet.**
- **Do not commit as part of this workflow.**

---

## What This Feature Does

Extends the existing feature 007 handoff-governance surfaces so feature numbers, iteration numbers, task codes, requirement codes, corpus references, and commits remain understandable on first read. The rule stays non-blocking and only applies to Squad-authored narration and stop messages.

---

## Pre-Implementation Baseline

Run the current handoff-governance baseline before implementation work starts.

```powershell
# Run from repo root: C:\Dev\Specrew
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-jargon-response-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-plain-language-response-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-review-file-reference-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Record any pre-existing failures before changing scope.

---

## Implementation Order

1. **Iteration 001 — rule and guidance rollout**
   - Extend the validator rule for opaque numeric references
   - Update coordinator prompts, checklist, contract/template guidance, Squad startup guidance, and worked examples
2. **Iteration 002 — replay and corpus proof**
   - Add scaffold-replay-path integration coverage
   - Seed corpus examples and trap reapplication evidence
   - Polish validation-lane and supporting documentation

Keep the iterations separate; Iteration 002 depends on stable Iteration 001 wording and examples.

---

## Step 1: Update the Validator Rule (Iteration 001)

**Primary file**: `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`

Implement a new descriptive-reference warning that:

- scans authored narration and stop-message prose only
- ignores quoted/tool-rendered/code/verbatim surfaces
- warns when three or more numeric references appear without descriptive scope
- remains a soft warning only
- preserves all existing feature 007 warnings

**Contract reference**: `contracts/descriptive-reference-handoff.md` → `GOV-C1` through `GOV-C5`

---

## Step 2: Update Durable Guidance Surfaces (Iteration 001)

**Primary files**:

- `extensions/specrew-speckit/prompts/coordinator-response.md`
- `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`
- `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`
- `specs/001-specrew-product/contracts/coordinator-handoff-template.md`
- `.github/agents/squad.agent.md`
- `.squad/templates/squad.agent.md`

Required outcomes:

- describe what counts as descriptive scope
- show how grouped lists or ranges can use a shared scope statement
- preserve feature 007 progress-status and next-step rules
- keep the rule explicitly non-blocking
- include acceptable and unacceptable worked examples

**Design references**:

- `data-model.md`
- `contracts/descriptive-reference-handoff.md`

**Important**: If `.github/agents/squad.agent.md` changes, a fresh session will be required before the updated startup guidance is active.

---

## Step 3: Run Iteration 001 Regression Checks

After the Iteration 001 edits, re-run the baseline commands plus any direct validator spot checks needed for the new rule.

Minimum regression pass:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-jargon-response-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-plain-language-response-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-review-file-reference-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Manual review:

- confirm the new rule is clearly explained in prompts, checklist, template, and Squad guidance
- confirm no existing feature 007 example lost progress-status or next-step clarity
- confirm the new rule is still documented as non-blocking

---

## Step 4: Add Replay Coverage and Corpus Seeding (Iteration 002)

**Delivered files** at the 2026-05-12 implementation boundary:

- `tests/integration/descriptive-reference-*.ps1`
- `tests/integration/fixtures/descriptive-reference-*/**`
- `extensions/specrew-speckit/governance/validation-lane.md`
- `.specrew/quality/known-traps.md`
- `specs/012-descriptive-id-handoffs/quality/hardening-gate.md`
- `specs/012-descriptive-id-handoffs/quality/trap-reapplication.md`

Required outcomes:

- replay-path assertions must exercise the real authored-message runtime path
- warn fixtures must prove the three-or-more opaque reference threshold
- pass fixtures must prove inline scope, shared scope, and excluded-surface handling
- corpus seeding must stay aligned with the approved non-blocking review behavior

**Implementation note**: Iteration 002 now uses fixture-backed replays that invoke `handoff-governance-validator.ps1` directly and assert on the validator's `status`, `findings`, and `summary` output. The `human-handoff-id-context` corpus row is seeded in `.specrew/quality/known-traps.md`, and feature-level follow-through artifacts now live under `specs/012-descriptive-id-handoffs/quality/`.

---

## Closeout Validation Expectations

The closeout tree for feature `012`, descriptive references in handoffs, should leave the handoff-governance lane with:

1. the existing three handoff-governance tests still passing
2. the iteration 001 readable-reference narration and stop-message tests still passing
3. the new descriptive-reference replay tests passing
4. `validate-governance.ps1 -ProjectPath .` passing
5. corpus/trap evidence recorded without converting the rule into a blocking gate

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-jargon-response-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-plain-language-response-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-review-file-reference-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-descriptive-narration-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-descriptive-stop-message-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\descriptive-reference-authored-prose.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\descriptive-reference-excluded-surfaces.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

**Closeout note**: This eight-command lane passed on 2026-05-12 for iteration `002`, the replay-path integration and corpus follow-through slice, and the resulting closeout tree remained additive and non-blocking.

---

## Manual Review Gate

Before review, a human reviewer should confirm:

1. numeric references in narration and stop messages are understandable on first read
2. grouped lists use shared scope only when the grouping is unmistakable
3. excluded verbatim surfaces are not being flagged
4. existing feature 007 handoff expectations still read naturally
5. the rule is still described as non-blocking everywhere it appears
6. the replay scripts prove the real validator path rather than state-only assertions

---

## Do Not Do

- Do not widen the rule to tool-rendered output, quoted text, or code blocks.
- Do not make the validator blocking.
- Do not generate `tasks.md` during planning unless a later approved workflow step explicitly requests task generation.
- Do not scaffold iteration `quality/` artifacts during planning.
- Do not treat `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` as independent sources of truth.
