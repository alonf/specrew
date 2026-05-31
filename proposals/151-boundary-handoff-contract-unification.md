---
proposal: 151
title: Boundary Handoff Contract Unification
status: draft
phase: phase-2
estimated-sp: 2-4
priority-tier: 1
type: small-fix
discussion: HIGH PRIORITY immediate small-fix extracted from Proposal 120 on 2026-05-31 after a live review-signoff handoff regression: the generated start prompt still instructed agents to emit the legacy `=== SPECREW HANDOFF ===` block, while Proposal 007 and the role charters require the three-section boundary handoff with clickable `file:///` inspection targets. This fixes the user-visible contract before broad validator enforcement hardens the wrong shape.
composes-with:
  - 007  # Substantive Interaction Model - canonical three-section boundary handoff
  - 120  # Broader handoff contract validator/backstop bundle
  - 143  # Session-start orientation; adjacent, not the stop-handoff owner
  - 150  # Agent-support hardening; prompt surfaces must make the right behavior easy
---

# Boundary Handoff Contract Unification

## Why

The boundary-stop instructions have drifted into two competing contracts:

1. `scripts/specrew-start.ps1` still tells the coordinator to append a legacy `=== SPECREW HANDOFF ===` block with `STOPPED AT`, `STATUS`, `WHY STOPPED`, `HUMAN ACTION NEEDED`, and `RESUME WITH`.
2. Shipped Proposal 007, coordinator governance, and role charters require the human-facing three-section handoff:
   - `## What I just did`
   - `## Why I stopped`
   - `## What I need from you`

The three-section contract is the load-bearing Specrew UX guarantee because it tells the human what changed, why the agent stopped, and what verdict/action is needed. It also requires clickable `file:///` inspection targets for local artifacts. The legacy sentinel block can satisfy "handoff exists" evidence while still omitting the substantive summary and clickable review targets.

The live regression that triggered this proposal was a review-signoff stop that presented status text and an interactive verdict menu, but did not provide the required three-section handoff or artifact `file:///` links. That is exactly the failure Proposal 007 was meant to prevent.

This proposal is intentionally narrow. Proposal 120 remains the broader validator/backstop bundle; this proposal fixes the canonical prompt and evidence contract first so future enforcement hardens the right shape.

## What

Unify all generated boundary-stop instructions around the Proposal 007 contract:

- The canonical human-blocked boundary stop is the three-section handoff:
  - `## What I just did`
  - `## Why I stopped`
  - `## What I need from you`
- The `What I need from you` section must include clickable `file:///` inspection targets when local artifacts exist.
- Interactive verdict menus are allowed and encouraged, but only after the three-section handoff. They are not a replacement for it.
- The legacy `=== SPECREW HANDOFF ===` sentinel must not be the primary UX contract. If retained for migration evidence, it must be clearly subordinate and must not teach agents to omit the three-section handoff.
- Handoff evidence detection must recognize the canonical three-section form rather than only the legacy sentinel.

## Functional Requirements

- **FR-001**: `specrew start` generated coordinator instructions MUST name the Proposal 007 three-section format as the canonical boundary-stop contract.
- **FR-002**: Generated instructions MUST NOT require the legacy `=== SPECREW HANDOFF ===` block as the primary final output at boundary stops.
- **FR-003**: Generated instructions MUST say that structured verdict menus are additive affordances, not replacements for `What I just did` / `Why I stopped` / `What I need from you`.
- **FR-004**: Generated instructions MUST require clickable `file:///` inspection targets in `What I need from you` whenever the human is asked to review local artifacts.
- **FR-005**: Handoff evidence helpers MUST treat the canonical three-section form as handoff-present evidence.
- **FR-006**: Legacy sentinel-only text MUST be classified as insufficient for canonical handoff evidence unless explicitly grandfathered for historical data.
- **FR-007**: Coordinator template, deployed/mirrored coordinator surfaces, and role charters MUST remain internally consistent after the change.

## Acceptance Criteria

- **AC1**: A generated `last-start-prompt.md` contains the three-section canonical contract and does not instruct the agent to append a mandatory legacy sentinel block as the primary boundary-stop output.
- **AC2**: A handoff containing an interactive verdict menu but missing the three required sections is detected by tests as non-compliant.
- **AC3**: A handoff containing the three required sections but no legacy sentinel is accepted as handoff-present evidence.
- **AC4**: A handoff that asks the human to review local artifacts without any `file:///` URI is detected as non-compliant.
- **AC5**: Existing role charter guidance remains aligned with the generated start prompt and coordinator governance template.
- **AC6**: Mirror/deployed prompt surfaces remain byte- or content-equivalent where Specrew's mirror-parity rules require it.

## Implementation Scope

Expected touch points:

| Area | Files |
| --- | --- |
| Start prompt generation | `scripts/specrew-start.ps1` |
| Handoff evidence helper | `extensions/specrew-speckit/scripts/shared-governance.ps1` and `.specify` mirror |
| Handoff governance validator tests | `tests/integration/*handoff*`, `tests/unit/*interaction-model*` as applicable |
| Coordinator template parity check | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` and deployed mirrors if needed |

The implementation should be a small-fix slice. It should not attempt the rest of Proposal 120's broader non-Specrew-session bypass detection.

## Out of Scope

- Full Proposal 120 validator/backstop implementation
- Hook-based runtime enforcement from Proposal 105
- Session-start welcome orientation from Proposal 143
- Redesigning the verdict menu UX
- Changing lifecycle boundary semantics or authorization rules

## Sequencing

Implement this proposal next, before Proposal 120. Proposal 120 should consume this result as its canonical contract baseline.

## Cross-References

- file:///C:/Dev/Specrew/proposals/007-substantive-interaction-model.md
- file:///C:/Dev/Specrew/proposals/120-handoff-block-validator-enforcement.md
- file:///C:/Dev/Specrew/proposals/143-session-start-welcome-orientation-reset-surface.md
- file:///C:/Dev/Specrew/proposals/150-agent-support-hardening-bundle.md
- file:///C:/Dev/Specrew/scripts/specrew-start.ps1
- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md

## Status History

- 2026-05-31: Drafted as an immediate small-fix proposal after a live handoff regression showed the generated start prompt and shipped Proposal 007 handoff contract disagree. User direction: create a small proposal and implement it next, while also amending Proposal 120 so the broader enforcement work does not harden the wrong contract.
