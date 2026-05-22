# Quickstart: Launch-Mode Boundary Enforcement

**Feature**: F-039  
**Date**: 2026-05-22  
**Status**: Phase 1 design complete

This is the minimum end-to-end rehearsal for the planned enforcement flow. It exercises one blocked boundary, one approved continuation, and one emergency bypass using the proposed helper contracts and CLI syntax.

---

## Prerequisites

Run from the repository root:

```powershell
Set-Location C:\Dev\Specrew
. .\extensions\specrew-speckit\scripts\shared-governance.ps1
```

Assume the active session is paused at `plan`, matching the recorded F-039 drift incident.

---

## 1. Boundary block: `plan -> tasks`

### Command

```powershell
$result = Test-SpecrewBoundaryAuthorization `
  -ProjectRoot . `
  -CurrentBoundary 'plan' `
  -RequestedBoundary 'tasks' `
  -SessionId 'qs-f039-block-001' `
  -AgentResponseSnippet '/speckit.plan -> /speckit.tasks in one turn'

$directive = Write-SpecrewBoundaryAuthorizationDirective `
  -CurrentBoundary 'plan' `
  -RequestedBoundary 'tasks' `
  -DirectiveSentinel $result.DirectiveSentinel

$directive
```

### Expected sentinels

- First line of output: `SPECREW_BOUNDARY_BLOCKED`
- `$result.Authorized` is `False`
- `$result.BypassAttemptDetected` is `True`
- `.squad\decisions.md` receives a `Boundary enforcement: tasks` entry with `Enforcement Action: blocked`

---

## 2. Approved continuation: maintainer authorizes `tasks`

### Commands

```powershell
$parsed = Parse-SpecrewBoundaryVerdict -VerdictText 'approved for tasks-boundary entry'
$parsed.DirectiveSentinel

Add-SpecrewBoundaryAuthorization `
  -ProjectRoot . `
  -CurrentBoundary 'plan' `
  -AuthorizedBoundary 'tasks' `
  -AuthorizingHuman 'Alon Fliess' `
  -VerdictText 'approved for tasks-boundary entry'

$recheck = Test-SpecrewBoundaryAuthorization `
  -ProjectRoot . `
  -CurrentBoundary 'plan' `
  -RequestedBoundary 'tasks' `
  -SessionId 'qs-f039-allow-001'

$recheck.DirectiveSentinel
```

### Expected sentinels

- Parse step returns `SPECREW_BOUNDARY_AUTHORIZED`
- Re-check returns `SPECREW_BOUNDARY_AUTHORIZED`
- `.specrew\start-context.json` now contains a `verdict_history` row for `plan -> tasks`
- `boundary_enforcement.last_authorized_boundary` becomes `tasks`
- `boundary_enforcement.pending_next_boundary` is cleared

---

## 3. Emergency bypass: session-scoped launch override

### Command

```powershell
specrew start --resume-feature auto --bypass-boundary-enforcement --reason "schema migration replay"
```

### Expected sentinels

- Startup/posture output includes `[BYPASS ACTIVE]` when the companion visibility surface is present; until then, the persisted session state is the authoritative marker
- `.specrew\start-context.json` gains a `bypass_history` activation row with reason `schema migration replay`
- Each later bypassed boundary appends:
  - `SPECREW_BOUNDARY_BYPASS_ACTIVE` in the surfaced directive/message path, and
  - a `.squad\decisions.md` entry with `Enforcement Action: bypassed`

---

## 4. Fast verification checks

### Decisions ledger

```powershell
Select-String -Path .\.squad\decisions.md -Pattern 'Boundary enforcement: tasks','Enforcement Action','schema migration replay'
```

### Start-context state

```powershell
(Get-Content .\.specrew\start-context.json -Raw | ConvertFrom-Json).boundary_enforcement
```

### What success looks like

- Blocked path is observable and deterministic.
- Approved continuation leaves a reconstructible verdict trail.
- Emergency bypass is explicit, session-scoped, and auditable.

---

## Notes

- This quickstart deliberately uses the F-039 `plan -> tasks` incident path because it is the empirical proof that motivated Proposal 065.
- The quickstart assumes mirror parity: the same commands and return shapes work from either mirrored `shared-governance.ps1` copy.
- `before-implement` is part of the canonical nine-boundary set even though the current repository helpers still need to be extended to include it.
