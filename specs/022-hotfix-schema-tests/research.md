# Research: Feature 022 Hotfix Decisions

**Feature**: 022-hotfix-schema-tests  
**Date**: 2026-05-18  
**Purpose**: Resolve the planning-time brownfield questions for schema parity, lifecycle synchronization, restart recovery, and scope governance before implementation planning.

## Decision 1: Treat closeout identity state as a dual-surface contract

**Decision**: Feature-closeout must preserve the human-readable identity narrative in `.squad/identity/now.md` while also writing the machine-readable `session_state_*` frontmatter required by restart validation.

**Rationale**: The current helper contract expects parser-readable frontmatter, while the closeout dashboard scaffolder also owns human-facing identity content. The hotfix therefore has to reconcile the two writers instead of choosing one audience over the other. This resolves FR-001 through FR-004 without broadening the schema audit beyond the closeout identity surface.

**Alternatives considered**:
- Replace the closeout identity body with a machine-only template — rejected because it would violate FR-003.
- Audit every state artifact for parity in this hotfix — rejected because FR-005 explicitly defers that work.

## Decision 2: Plan FR-004, FR-009, and FR-015 as three standalone integration scripts

**Decision**: The hotfix will plan three independent PowerShell integration scripts under `tests/integration/`: `closeout-identity-schema-parity.tests.ps1`, `lifecycle-boundary-sync.tests.ps1`, and `start-recovery-flow.tests.ps1`.

**Rationale**: Each confirmed bug needs its own durable regression surface, and the user explicitly directed the plan to keep these suites standalone so Proposal 054 can compose them later. Separate scripts also keep debugging and evidence review narrow when one lane fails.

**Alternatives considered**:
- One monolithic restart hotfix suite — rejected because it would blur which bug regressed and would block later Proposal 054 composition.
- Unit-only coverage — rejected because the failures are lifecycle/integration defects.

## Decision 3: Audit the seven-boundary sync path with explicit late-boundary focus

**Decision**: Implementation planning will treat `review-signoff`, `iteration-closeout`, and `feature-closeout` as the highest-risk lifecycle boundaries and require ordered ledger evidence across all seven lifecycle boundaries.

**Rationale**: Existing brownfield evidence already shows early-boundary sync surfaces, but Feature 022 was opened because later-boundary synchronization drifted or never landed durably. The planned recovery evidence must therefore prove both wiring and observability, not merely re-run a single plan-boundary sync.

**Alternatives considered**:
- Re-test only the plan boundary because the helper exists — rejected because FR-006 through FR-010 explicitly scope all seven boundaries.
- Defer late-boundary verification to a future audit — rejected because the current restart defect is production-facing now.

## Decision 4: Recovery mode stays operator-explicit and orthogonal to approval behavior

**Decision**: The hotfix will preserve the A/B/C recovery model, make it actionable, and add `specrew start --recover` as a bypass into recovery mode without changing best-guess or approval defaults.

**Rationale**: The clarified spec explicitly keeps `--recover` orthogonal to autopilot or approval behavior. Planning must therefore treat recovery intent, stale-state explanation, and approval behavior as separate controls so the hotfix fixes the production blocker without widening policy behavior.

**Alternatives considered**:
- Fold recovery into existing approval flags — rejected because it would violate FR-014.
- Skip the interactive flow and rely only on `--recover` — rejected because FR-011 requires the operator-facing A/B/C path.

## Decision 5: Preserve carry-forward governance defaults inside planning artifacts

**Decision**: The plan will explicitly retain push-after-every-commit, pre-handoff origin verification, pre-handoff artifact checks, the 3-cycle repair policy, and single-iteration capacity discipline.

**Rationale**: FR-017 requires Feature 021 operating defaults to carry forward. Because this task ends at plan completion, those defaults must already appear in the plan, iteration plan, and hardening gate instead of waiting for implementation.

**Alternatives considered**:
- Assume the defaults are implied by precedent — rejected because the user explicitly required them to remain visible in planning/governance surfaces.
- Re-open a broader governance redesign for restart workflows — rejected because it exceeds the hotfix scope lock.
