# Quickstart: Validate Feature 022 Planning Scope

**Feature**: 022-hotfix-schema-tests  
**Audience**: Maintainers, reviewers, and implementation owners  
**Purpose**: Provide the bounded validation recipe planned for Feature 022 without crossing the task-generation boundary.

## Overview

Feature 022 validation is intentionally split into three standalone PowerShell integration scripts so each confirmed bug has its own proof surface:

1. `tests/integration/closeout-identity-schema-parity.tests.ps1` — FR-004
2. `tests/integration/lifecycle-boundary-sync.tests.ps1` — FR-009
3. `tests/integration/start-recovery-flow.tests.ps1` — FR-015

These scripts are planned to remain independently runnable now and later composable into Proposal 054 scenarios.

## Prerequisites

- PowerShell 7+
- A Feature 022 implementation tree
- Git available on PATH
- Repository references:
  - `specs/022-hotfix-schema-tests/spec.md`
  - `specs/022-hotfix-schema-tests/contracts/closeout-identity-state-contract.md`
  - `specs/022-hotfix-schema-tests/contracts/lifecycle-boundary-sync-contract.md`
  - `specs/022-hotfix-schema-tests/contracts/restart-recovery-contract.md`

## Step 1: Run the governance validator

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\022-hotfix-schema-tests\iterations\001
```

**Expected result**:

- The validator reports no new blocking drift outside the authorized Feature 022 hotfix scope.
- The hardening gate remains the canonical pre-implementation quality artifact.

## Step 2: Verify closeout identity schema parity

```powershell
pwsh -NoProfile -File tests/integration/closeout-identity-schema-parity.tests.ps1
```

**Expected result**:

- Closeout-generated `.squad/identity/now.md` remains human-readable.
- The same file contains parser-readable `session_state_*` frontmatter.
- The stale-state/session-state parser accepts the closeout output without a special-case path.

## Step 3: Verify seven-boundary synchronization

```powershell
pwsh -NoProfile -File tests/integration/lifecycle-boundary-sync.tests.ps1
```

**Expected result**:

- A simulated lifecycle emits exactly seven ordered `Boundary sync:` ledger entries.
- Review-signoff, iteration-closeout, and feature-closeout are explicitly covered.
- Any intentionally skipped boundary remains visible as stale-state or evidence drift.

## Step 4: Verify restart recovery UX

```powershell
pwsh -NoProfile -File tests/integration/start-recovery-flow.tests.ps1
```

**Expected result**:

- Stale-state detection exposes an actionable A/B/C recovery flow.
- `specrew start --recover` bypasses the blocking stale-state gate and enters recovery mode directly.
- Recovery messaging explains why the operator was routed into recovery and what happens next.
- Approval/autopilot behavior remains unchanged by `--recover`.

## Step 5: Record pre-handoff checks

Before claiming the boundary ready for the next human review:

1. Confirm the planned artifacts remain aligned (`plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`, `iterations/001/plan.md`, `iterations/001/state.md`, `iterations/001/quality/hardening-gate.md`).
2. Confirm every planning commit was pushed.
3. Confirm `git rev-parse HEAD` equals `git rev-parse origin/022-hotfix-schema-tests`.

## Stop Condition

This quickstart ends at the plan-completion boundary only. It does **not** authorize `/speckit.tasks`, implementation, review, or closeout on its own.
