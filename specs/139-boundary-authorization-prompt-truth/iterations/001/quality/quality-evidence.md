# Quality Evidence: Iteration 001

**Feature**: 139-boundary-authorization-prompt-truth
**Iteration**: 001
**Status**: implementation evidence captured

## Planned Evidence

| Evidence Area | Planned Source | Blocking? |
| --- | --- | --- |
| Policy-derived prompt truth | T004-T010 tests and generated prompt diff | yes |
| `boundary_enforcement.policy_classes` snapshot | T005-T006 tests | yes |
| Six-section human re-entry packet | T011-T016 tests | yes |
| No legacy duplication / grouped prompts / `discuss prompt #N` | T017-T021 tests | yes |
| Non-compliant handoff fixtures | T022-T024 tests | yes |
| `Status: Approved` evidence check | T025-T026 tests | yes |
| Beta3 smoke evidence | T027 artifact | yes |
| Governance validation | T028 command output | yes |
| Implemented/enforced/observable/documented gap ledger | T029 review evidence | yes |

## Commands To Record During Implementation

```powershell
pwsh -File <focused prompt/status/handoff test selected by T003>
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

## Current Evidence

- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\unit\validate-governance.interaction-model.tests.ps1` — PASS after send-back repair. The prior failure was the exact assertion `Assert-True -Condition ($readmeText -match 'Post-Commit Verification Protocol')`, which exposed an existing Feature 016 README docs/template-truth defect. The adjacent defect was repaired by adding the missing [README.md](file:///C:/tmp/Specrew-main-boundary-auth/README.md) protocol section.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\unit\boundary-authorization-prompt-truth.tests.ps1` — PASS after send-back repair. Covers policy snapshot resolution, generated prompt contract text, beta2-bad phrase rejection, six-section packet guidance, no required legacy duplication, non-compliant handoff fixtures, and positive/negative `Status: Approved` contradiction validation.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\launch-mode-boundary-enforcement.tests.ps1` — PASS after send-back repair. Confirms policy seam and boundary authorization behavior still block unauthorised `plan -> tasks` progression.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\start-command.ps1` — PASS after send-back repair. Confirms fresh project start artifact generation remains functional after prompt/state changes.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` — PASS after send-back repair for Feature 139 scoped validation. Existing warnings remain for old Feature 048 dashboard auto-render evidence and historical missing handoff evidence.
- Automated pre-publish smoke artifact updated at [beta3-smoke-evidence.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md). It records a local candidate PASS for prompt/state generation and explicitly preserves the manual published beta3 Copilot/Squad replay as pending before stable promotion.

## Gap Ledger

| Behavior | Implemented | Enforced | Observable | Documented | Gap / Action |
| --- | --- | --- | --- | --- | --- |
| Policy-derived boundary prompt truth | yes | yes | yes | yes | No gap. Implemented in `scripts/specrew-start.ps1`; tested by `boundary-authorization-prompt-truth.tests.ps1` and start-command coverage. |
| `boundary_enforcement.policy_classes` snapshot | yes | yes | yes | yes | No gap. Implemented in shared governance state helpers and start artifact persistence; observable in generated `start-context.json`. |
| Removal of beta2-bad four-gate / auto-chain guidance | yes | yes | yes | yes | No gap. Unit test rejects the bad generated prompt phrases. |
| Six-section human re-entry packet | yes | yes | yes | yes | No gap. Generated prompt and coordinator governance template define all six sections. |
| Bare `file:///` review target guidance | yes | yes | yes | yes | No gap. Packet guidance and coordinator governance require bare URIs; existing handoff validator still enforces bare-path failures. |
| Contextual discussion prompts and `discuss prompt #N` loop | yes | yes | yes | yes | No gap. Generated prompt includes grouped prompts, approve-with-defaults affordance, response shapes, and renewed approval after prompt-specific discussion. |
| Future packet primary, no required legacy duplication | yes | yes | yes | yes | No gap. Generated prompt removed the mandatory legacy block template and states the packet is primary. |
| `Status: Approved` without verdict evidence check | yes | yes | yes | yes | No gap. Implemented as an active-feature validator check that exits non-zero when `Status: Approved` lacks matching human verdict evidence. |
| Non-compliant handoff fixtures | yes | yes | yes | yes | No gap. Missing `Why I Stopped`, approve-only, and context-free prompt fixtures fail the handoff validator. |
| Beta3 smoke evidence | yes | partial | yes | yes | Automated pre-publish prompt/state smoke PASS is committed. Published beta3 Copilot/Squad clarify replay remains pending before stable promotion because no beta3 package has been published in this implementation turn. |
| Proposal 145 review lens | yes | yes | yes | yes | No gap for this feature scope. Full Proposal 145 implementation remains out of scope. |
| Scope exclusions | yes | yes | yes | yes | No gap. No full Proposal 150, hook enforcement, broad Proposal 151 migration, or lifecycle redesign was implemented. |
