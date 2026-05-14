# Quickstart: Substantive Interaction Model

**Feature**: 016 Substantive Interaction Model  
**Branch**: `016-substantive-interaction-model`  
**Phase**: 1 — Iteration 001 implemented; review authorization pending  
**Date**: 2026-05-14

---

## What This Feature Delivers

Feature 016 makes Specrew's console-first lifecycle explicit and enforceable. The feature delivers
three linked outcomes:

1. **Boundary discipline** — one human authorization advances at most one boundary
2. **Essence in console** — boundary stops contain substantive, reviewable summaries
3. **Click-through navigation** — Squad-authored artifact references use `file:///` links

The implementation works by extending existing coordinator guidance, authorization-recording
contracts, validator rules, replay fixtures, corpus rows, and documentation. Feature 017 visual
artifacts remain out of scope.

---

## Iteration Overview

### Iteration 1 — Prompt + validator semantics + authorization shape

**Scope**: FR-001–FR-019 except the Iteration 2 graduation portion of FR-016; no Feature 017 work  
**Effort**: ~13 story points  
**Goal**: Ship the governance semantics and initial rule surface without overreaching the approved
rollout

**Deliverables**:

| Deliverable | Path / Surface | Requirement |
| --- | --- | --- |
| Coordinator single-boundary stop rules + worked examples | `.github/agents/squad.agent.md`, `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/.../coordinator/specrew-governance.md` | FR-001–FR-005, FR-010, FR-014, FR-015 |
| Bundled-boundary hard fail | `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror as required) | FR-006, FR-007 |
| Canonical authorization-recording shape | `.squad/decisions.md` governing contract + prompt guidance | FR-008, FR-009 |
| Pillar 2 soft-warning rules | validator surfaces + handoff validator integration | FR-011–FR-013 |
| Bare-path rule in Iteration 1 rollout shape | validator surfaces | FR-016, FR-017, FR-018, FR-019 |

**Acceptance check for Iteration 1**:

- User `continue` advances one boundary only, then stops again
- Missing intervening authorization between two boundary commits produces
  `validation-fail.bundled-boundary-advance`
- One pasted paired authorization yields two distinct `.squad/decisions.md` entries
- `What I just did`, `Why I stopped`, and `What I need from you` warnings remain advisory only
- Boundary-handoff bare paths produce **soft warnings only** in Iteration 1
- Validator scope remains limited to Squad-authored artifacts/handoffs; no transcript scraping

---

### Iteration 2 — Proof fixtures + corpus + docs + graduation

**Scope**: FR-020–FR-024 plus the Iteration 2 graduation portion of FR-016  
**Effort**: ~9 story points  
**Goal**: Prove bounded false positives, add durable corpus memory, and update public guidance

**Deliverables**:

| Deliverable | Path / Surface | Requirement |
| --- | --- | --- |
| Violating + compliant replay fixtures | `tests/integration/`, `tests/unit/fixtures/`, `tests/unit/` | FR-021 |
| New corpus rows + historical cross-refs | `.specrew/quality/known-traps.md` | FR-020, FR-024 |
| README lifecycle update | `README.md` | FR-022 |
| Handoff template update | `specs/001-specrew-product/contracts/coordinator-handoff-template.md` or equivalent governed template surface | FR-023 |
| Bare-path severity flip by configuration | validator configuration / rule table | FR-016 |

**Acceptance check for Iteration 2**:

- Violating fixtures warn/fail as expected and compliant fixtures stay clean
- Exemption fixtures prove bounded false positives before severity promotion
- `bare-path-in-boundary-handoff` flips from soft warning to hard fail **without rewriting the detector**
- README "Recommended Lifecycle" explicitly reflects the three-pillar model
- Historical corpus rows are cross-referenced from the new Feature 016 rows

---

## Key File Paths

```text
# Prompt and coordinator guidance
.github/agents/squad.agent.md
extensions/specrew-speckit/prompts/coordinator-response.md
extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md

# Validator and helper surfaces
extensions/specrew-speckit/scripts/validate-governance.ps1
.specify/extensions/specrew-speckit/scripts/validate-governance.ps1
extensions/specrew-speckit/scripts/shared-governance.ps1
extensions/specrew-speckit/validators/handoff-governance-validator.ps1
extensions/specrew-speckit/checklists/coordinator-handoff-governance.md

# Governance memory and contracts
.squad/decisions.md
.specrew/quality/known-traps.md
specs/001-specrew-product/contracts/coordinator-handoff-template.md

# Proof surfaces
tests/integration/
tests/unit/
tests/unit/fixtures/

# Feature 016 planning artifacts
specs/016-substantive-interaction-model/
```

---

## Developer Workflow Reference

### Iteration 1 Steps

1. Update coordinator guidance to enumerate the seven per-iteration boundaries by name and to
   forbid bundled advances.
2. Add the compliant seven-authorization example and the violating bundled-advance example.
3. Define the canonical `.squad/decisions.md` authorization schema and paired-entry expansion path.
4. Extend `validate-governance.ps1` to:
   - classify canonical boundary commit signatures
   - detect missing intervening authorization
   - warn on thin handoff content, unspecific stop boundary, unactionable user request
   - warn on bare-path-in-boundary-handoff and bare-path-in-narration
   - warn on broken `file:///` references
5. Keep Pillar 2 warnings advisory and keep `bare-path-in-boundary-handoff` in Iteration 1 soft
   rollout shape.
6. Record the Iteration 1 replay commands and scenario expectations in `quickstart.md`; full
   violating/compliant fixture implementation remains deferred to Iteration 2.

Suggested validation commands during implementation:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\<feature-016-replay>.ps1
Invoke-Pester .\tests\unit\
```

### Implementation Evidence — 2026-05-14

- **Baseline repo validator**: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` → pass, `109134 ms`
- **Baseline handoff regressions**:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-jargon-response-test.ps1` → pass
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-plain-language-response-test.ps1` → pass
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-review-file-reference-test.ps1` → pass
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-descriptive-narration-test.ps1` → pass
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-descriptive-stop-message-test.ps1` → pass
- **Feature 016 validation additions**:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\substantive-interaction-model-handoff-test.ps1` → pass
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\substantive-interaction-model-boundary-discipline-test.ps1` → pass
- **Final repo validator**: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` → pass, `113070 ms`
- **NFR-001 baseline vs actual**: repo validator moved from `109134 ms` to `113070 ms` (`+3936 ms`, about `+3.6%`, within the `+15%` tolerance captured in the hardening gate notes). The ad-hoc Feature 016 response-validation path measured `1332 ms` command-level wall time, and the bundled-boundary fixture replay measured `6180 ms` end-to-end including fixture setup.
- **NFR-002 prompt-line budget**: prompt/governance guidance additions totaled `100` added lines across `.github\agents\squad.agent.md`, `.squad\templates\squad.agent.md`, `extensions\specrew-speckit\prompts\coordinator-decision-guidance.md`, `extensions\specrew-speckit\prompts\coordinator-response.md`, `extensions\specrew-speckit\checklists\coordinator-handoff-governance.md`, `extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md`, and `.specify\extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md` (budget: `<=150`).
- **Authorized-scope outcome**: Iteration 001 delivered the authorized FR-001 through FR-019 scope only. FR-020 through FR-024 and the Iteration 2 promotion half of FR-016 remain intentionally untouched.

### Iteration 2 Steps

1. Add violating + compliant fixtures for every new interaction-model rule.
2. Add exemption-list fixtures demonstrating bounded false positives.
3. Promote `bare-path-in-boundary-handoff` from soft warning to hard fail via config/rule-table
   flip once proof exists.
4. Add the new known-trap rows and historical cross-references.
5. Update README "Recommended Lifecycle" with the three-pillar interaction model and scope note.
6. Update the per-feature handoff template with explicit substantive examples for each boundary.

Suggested validation commands during implementation:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\<feature-016-fixture-replay>.ps1
Invoke-Pester .\tests\unit\
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

---

## Dependencies and Constraints

- Depends on established lifecycle and validator surfaces from Features 013, 014, and 015
- Must preserve the clarified answers already embedded in `spec.md`
- Must not pull Feature 017 visual-artifact work into this scope
- Must keep validator scope limited to Squad-authored artifacts/handoffs
- Must preserve Iteration 1 soft-warning / Iteration 2 hard-fail promotion for boundary-handoff bare
  paths
- Must keep Pillar 2 rules soft-warning-only throughout Feature 016

---

## Scope Reminder

> Feature 016 now has an implemented Iteration 001 slice plus recorded evidence in
> `specs/016-substantive-interaction-model/` and `specs/016-substantive-interaction-model/iterations/001/`.
>
> Review, retro, iteration closeout, and all Iteration 2 proof/doc/corpus work still require their
> own explicit authorizations.
>
> The remaining deferred scope is FR-020 through FR-024 plus the Iteration 2 promotion half of
> FR-016 only.
