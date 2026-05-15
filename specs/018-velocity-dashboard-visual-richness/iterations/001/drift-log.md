# Drift Log: Iteration 001

**Schema**: v1
**Feature**: 018 — Velocity Dashboard Visual Richness + PoC-Parity Restoration
**Logging Date**: 2026-05-15
**Monitoring Boundary**: planning-time assessment; execution-time findings should be added only after implementation begins

## Planning-Time Drift Assessment

Iteration 001 scaffolding aligns to the approved feature bundle (`spec.md`, `plan.md`, `tasks.md`) and the
reviewer inbox note at `.squad/decisions/inbox/reviewer-feature018-preimpl.md`. The pre-implementation
artifact repair does not widen scope; it only makes the iteration boundary truthful for the upcoming
before-implement gate.

**Planning-time drift status**: ✅ **ZERO DRIFT**

No planning drift was introduced while creating the execution scaffold. The five approved pillars, three
user stories, and explicit out-of-scope items remain unchanged.

## Monitoring Areas for Execution

### 1. **Terminal Capability Decision Precedence**
- **What to watch**: `--ASCII`, `NO_UNICODE`, redirected output, `LANG`, and Windows VT checks must resolve
  in one deterministic order.
- **Drift signal**: rich mode activates when an explicit fallback signal should win, or different entry
  points choose different precedence.
- **Owner**: CLI steward + UX steward
- **Monitoring method**: T003-T005 implementation review plus T014/T021/T028 fixture replay.

### 2. **Windows VT Fallback Truthfulness**
- **What to watch**: Windows consoles without virtual-terminal support must keep the same meaning as rich
  mode without ANSI dependence.
- **Drift signal**: semantic emphasis or sparkline meaning disappears, or ASCII fallback becomes less
  informative than the approved baseline.
- **Owner**: UX steward
- **Monitoring method**: T016-T019 fallback implementation review plus monochrome expected-output fixtures.

### 3. **Render-Budget Stop-Ship Evidence**
- **What to watch**: the richer dashboard still renders within the 1.5 second budget on the representative
  16-feature repository.
- **Drift signal**: performance evidence is missing, inconclusive, or exceeds the budget without explicit
  deferral approval.
- **Owner**: Reliability steward
- **Monitoring method**: T024 budget harness and T028 replay lane.

### 4. **ANSI Stripping with Unicode Preservation**
- **What to watch**: stored dashboard artifacts remain ANSI-free while preserving readable Unicode glyphs.
- **Drift signal**: snapshots lose Unicode meaning, keep ANSI escape codes, or diverge between live and
  persisted output.
- **Owner**: UX steward + Reliability steward
- **Monitoring method**: T019/T020 implementation review, T022 validator compatibility tests, and T029 replay.

### 5. **Closeout Dashboard Artifact Rendering**
- **What to watch**: iteration-closeout and feature-closeout scaffolds keep the same rendering and
  immutability rules as live dashboard output.
- **Drift signal**: closeout artifacts use different fallback logic, mutate historical files, or omit the
  approved richer surfaces.
- **Owner**: Reliability steward
- **Monitoring method**: T020 scaffold updates plus T022/T029 replay.

### 6. **Flag Surface and Documentation Alignment**
- **What to watch**: help, README, dashboard guide, and manual quickstart all explain `--ASCII`,
  `--RecentCount`, `--BarWidth`, eligibility rules, and snapshot behavior consistently.
- **Drift signal**: docs promise controls or defaults the CLI does not actually expose.
- **Owner**: Documentation steward + CLI steward
- **Monitoring method**: T003 help review plus T026-T027 documentation verification.

## Resolution Strategies (Reserved)

If drift is detected later during execution, use one of these explicit outcomes:

- **spec-updated**: Update the spec or plan because the approved intent changed with human approval
- **implementation-reverted**: Revert implementation to restore the approved scope
- **deferred**: Record the drift as a named deferral to a later authorized slice
- **human-decision**: Escalate to Alon when the implementation/spec mismatch cannot be resolved locally

## Handoff to Implementation

Execution should begin only after `/speckit.specrew-speckit.before-implement` confirms the artifact set.
The first live monitoring checkpoint should happen immediately after T003-T005, because that is where most
cross-cutting drift can first appear.
