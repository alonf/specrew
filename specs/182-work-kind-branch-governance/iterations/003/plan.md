# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 14/20 story_points
**Started**: 2026-06-12
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of: planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status MUST be one of: planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Iteration 003 = the **forge-neutralization migration** (FR-019), the feature's final slice. It consumes
the [Iteration-3 neutralization inventory](neutralization-inventory.md) (the Iter-1 coupling inventory
augmented by a planning-time sweep of ALL surface types) and decouples Specrew's **downstream-governing**
surfaces from Specrew's own GitHub-dev habits — **without** changing Specrew's own GitHub usage.

**Binding guardrail**: this is the downstream-governance neutralization slice ONLY, NOT a general GitHub
cleanup. Only confirmed downstream-governing couplings (inventory section A = G1–G5; section B = D1
pending disposition) are changed. Own-infra, the GitHub host adapter, and false positives are
out-of-scope (inventory sections C/D).

**Change classification (maintainer's ask — methodology-wording vs runtime/script kept separate):**

- **Methodology-wording** (prose surfaces): T301 (G1–G3 closeout SDLC), T302 (G4 regenerate), T303 (D1).
- **Runtime/script** (PowerShell): T304 (G5 reviewer routing) + T305 (its tests).
- **Validation** (the no-over-claim sweep + parity): T306 (SC-008 scope-aware sweep), T307 (SC-013),
  T308 (Specrew-own-flow-still-works).

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-019 | Decouple ALL downstream-governing surfaces from Specrew's own GitHub dev habits (no own-infra change) | US2 |
| SC-008 | Every enforcement claim in shipped surfaces labeled with its true posture; reviewer finds no over-claim | US2 |
| SC-013 | The audit inventory exists/complete; migrated surfaces carry no GitHub-only mandate; own infra unchanged | US2 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T301 | Neutralize the shared closeout-SDLC prose (G1+G2+G3): project-agnostic + forge-neutral PR/MR + publish-per-project-mechanism + review_gate opt-in | FR-019 | US2 | 3 | Spec Steward | extensions/specrew-speckit/prompts/coordinator-decision-guidance.md | planned | claude | | |
| T302 | Regenerate + verify the lifecycle-prompt Rule 46/47 feature-closeout block (G4) reflects the neutralized closeout (no GitHub-only mandate) | FR-019 | US2 | 1 | Spec Steward | extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | planned | claude | | |
| T303 | D1 disposition (per DP-2 ruling): label `lifecycle-discipline.md` SDLC as a non-mandatory example OR record the own-doc exclusion | FR-019 | US2 | 1.5 | Spec Steward | docs/methodology/lifecycle-discipline.md | planned | claude | | |
| T304 | Route reviewer detection through the adapter (G5): Copilot becomes a GitHub-adapter opt-in suggestion, not a baked-in reviewer | FR-019 | US5 | 2.5 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1 | planned | claude | | |
| T305 | Tests for the G5 reviewer-routing change (adapter-mediated; the generic/non-GitHub path bakes in no Copilot) | FR-019 | US5 | 1.5 | Implementer | tests/unit/forge-neutral-reviewer.tests.ps1 | planned | claude | | |
| T306 | SC-008 scope-aware no-over-claim sweep test: downstream-governing surfaces carry no GitHub-only mandate; allowlist mirrors the inventory (host-adapter + own-infra exempt) | SC-008 | US2 | 2.5 | Reviewer | tests/integration/forge-neutralization-sweep.tests.ps1 | planned | claude | | |
| T307 | SC-013 verification: inventory complete; migrated surfaces carry no GitHub-only mandate; Specrew's own infra is unchanged (diff-verify own-infra untouched) | SC-013 | US2 | 1 | Reviewer | tests/integration/forge-neutralization-sweep.tests.ps1 | planned | claude | | |
| T308 | Verify Specrew's OWN closeout flow still works post-edit (the provider:github instantiation still yields the gh + beta-publish steps) | FR-019 | US2 | 1 | Reviewer | specs/182-work-kind-branch-governance/iterations/003/neutralization-inventory.md | planned | claude | | |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning should choose deferrals when over capacity. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Task dependency graph: T301 (G1–G3 prose) precedes T302 (G4 regenerate) and T306 (the sweep asserts
  the neutralized state); T304 (G5 script) precedes T305 (its tests); T306/T307/T308 are the verification
  wave and run after the change waves. Serial single-developer execution.
- Workstream separability: methodology-wording (T301–T303) and runtime/script (T304–T305) touch disjoint
  files and could parallelize, but are run serial under single-developer execution to keep the sweep
  (T306) authoritative over a settled tree.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Implementation | ~9.5 SP | T301–T305 (methodology-wording + the G5 script + its tests). |
| Review | ~3.5 SP | T306–T308 (the SC-008 scope-aware sweep + SC-013 + own-flow parity). |
| Rework | small | needs-work buffer. |

## Traceability Summary

- Requirement scope for **iteration 003 (forge-neutralization migration)**: FR-019 → SC-008, SC-013.
  (FR-007/011/012/013/015/016/020/021 = Iter-2 runtime, complete; FR-001..006/008..010/014/017/018 =
  Iter-1 methodology, complete.)
- User stories: the decouple serves US2 (DevOps-lens governance that is real on ANY forge, not a
  GitHub-shaped default) and US5 (the adapter is the only forge seam — G5 routes the reviewer through it).
- Success criteria targeted: SC-008 (no over-claim sweep), SC-013 (inventory complete + migrated surfaces
  carry no GitHub-only mandate + own infra unchanged).
- Overcommit: 14 SP planned vs cap 20 — within capacity (no split needed; the split-to-sibling escape
  hatch is unused).

## Notes

- **Two decisions are deferred to the before-implement gate** (see the inventory section E): DP-1 (where
  the GitHub + beta-publish specifics go once the prose is genericized — recommended Option (b),
  genericize-the-shape with GitHub as a labeled non-mandatory example that `provider: github`
  instantiates) and DP-2 (the D1 / `lifecycle-discipline.md` disposition). T303's exact shape depends on
  DP-2; its 1.5 SP estimate assumes the label-as-example path.
- **T013b stays OUT** of Iteration 3 — it remains the release/deploy step at feature-closeout
  (drift-log D-001), not pulled into the decouple.
- The Iteration-2 dashboard WARN is an untouched standing carry-item (confirm-not-harden at
  feature-closeout); nothing in Iteration 3 resolves or disturbs it.
- **Specrew's own GitHub usage is unchanged** by every task here; T308 is the explicit guard that the
  neutralized surfaces still yield Specrew's own gh + beta-publish closeout via its `provider: github`
  configuration.
