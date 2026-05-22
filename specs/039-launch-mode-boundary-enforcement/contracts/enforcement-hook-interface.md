# Contract: Enforcement Hook Interface

**Feature**: F-039  
**Date**: 2026-05-22  
**Status**: Phase 1 design complete

This contract defines the four boundary-enforcement helpers planned for the mirrored shared-governance surfaces:

- `extensions\specrew-speckit\scripts\shared-governance.ps1`
- `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`

The two copies must remain functionally and structurally identical. Mirror drift is a contract failure, not a documentation issue.

---

## Shared conventions

### Canonical boundaries

`specify`, `clarify`, `plan`, `tasks`, `before-implement`, `review-signoff`, `retro`, `iteration-closeout`, `feature-closeout`

### Deterministic directive sentinels

The first line of every emitted directive should be a stable sentinel so tests and host wrappers can assert exact behavior:

- `SPECREW_BOUNDARY_BLOCKED`
- `SPECREW_BOUNDARY_AUTHORIZED`
- `SPECREW_BOUNDARY_BYPASS_ACTIVE`
- `SPECREW_BOUNDARY_VERDICT_UNRECOGNIZED`

### Fail-safe rule

If any helper cannot prove the boundary is authorized, the helper must return blocked semantics or throw. No helper may silently downgrade to allow.

---

## 1. `Test-SpecrewBoundaryAuthorization`

### Purpose

Checks whether the requested boundary is currently authorized for entry.

### Signature

```powershell
function Test-SpecrewBoundaryAuthorization {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$CurrentBoundary,

        [Parameter(Mandatory = $true)]
        [string]$RequestedBoundary,

        [AllowNull()]
        [string]$SessionId,

        [AllowNull()]
        [string]$AgentResponseSnippet,

        [switch]$EmergencyBypassActive
    )
}
```

### Returns

```powershell
[pscustomobject]@{
    Authorized            = $false
    Decision              = 'blocked' # blocked | authorized | bypassed
    CurrentBoundary       = 'plan'
    RequestedBoundary     = 'tasks'
    MatchedVerdict        = $null
    DirectiveSentinel     = 'SPECREW_BOUNDARY_BLOCKED'
    BypassAttemptDetected = $true
    Reason                = 'No persisted authorization matched plan -> tasks.'
}
```

### Required behavior

1. Read `.specrew\start-context.json` and validate the `boundary_enforcement` section.
2. Normalize `CurrentBoundary` and `RequestedBoundary` to canonical names.
3. If `EmergencyBypassActive` is set and a valid bypass session exists, return `Decision = bypassed`.
4. Otherwise search `verdict_history` for the latest verdict that authorizes the requested boundary from the current boundary.
5. If no verdict matches, return `Authorized = $false` and a blocked sentinel.
6. If `AgentResponseSnippet` contains advancement evidence, set `BypassAttemptDetected = $true` for logging.

### Fail-safe semantics

- Throw on malformed or missing `boundary_enforcement` once schema `v2` is expected.
- Throw on invalid canonical boundary names after normalization.
- Never return `Authorized = $true` merely because the store is missing; missing proof means blocked.

---

## 2. `Add-SpecrewBoundaryAuthorization`

### Purpose

Persists an accepted maintainer verdict into `boundary_enforcement.verdict_history`.

### Signature

```powershell
function Add-SpecrewBoundaryAuthorization {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$CurrentBoundary,

        [Parameter(Mandatory = $true)]
        [string]$AuthorizedBoundary,

        [Parameter(Mandatory = $true)]
        [string]$AuthorizingHuman,

        [Parameter(Mandatory = $true)]
        [string]$VerdictText,

        [AllowNull()]
        [string]$AuthCommitHash,

        [AllowNull()]
        [string]$RecordedAt
    )
}
```

### Required behavior

1. Resolve the effective commit hash with the existing boundary-auth helper when possible.
2. Append a new `verdict_history` row containing `from_boundary`, `to_boundary`, exact verdict text, human, timestamp, and commit hash.
3. Set `last_authorized_boundary = AuthorizedBoundary`.
4. Clear `pending_next_boundary` if it matches `AuthorizedBoundary`.
5. Persist atomically.

### Return contract

```powershell
[pscustomobject]@{
    AuthorizedBoundary = 'tasks'
    StoredVerdict      = 'approved for tasks-boundary entry'
    RecordedAt         = '2026-05-22T15:12:00Z'
    DirectiveSentinel  = 'SPECREW_BOUNDARY_AUTHORIZED'
}
```

### Fail-safe semantics

- Throw if the verdict would skip outside the canonical order without a recognized compound-verdict exception.
- Throw on atomic write failure.
- Never partially update `last_authorized_boundary` without also appending the corresponding history row.

---

## 3. `Parse-SpecrewBoundaryVerdict`

### Purpose

Parses maintainer text into a structured boundary verdict.

### Signature

```powershell
function Parse-SpecrewBoundaryVerdict {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VerdictText,

        [string[]]$CanonicalBoundaries = @(Get-SpecrewCanonicalBoundaryTypes())
    )
}
```

### Returns

```powershell
[pscustomobject]@{
    Authorized         = $true
    Action             = 'approved' # approved | rejected | parked | unrecognized
    Boundaries         = @('tasks')
    NormalizedVerdict  = 'approved for tasks-boundary entry'
    DirectiveSentinel  = 'SPECREW_BOUNDARY_AUTHORIZED'
    FailureReason      = $null
}
```

### Recognized shapes

- `approved for <boundary>-boundary entry`
- `approved for <boundary>`
- `approved for review-boundary AND review-signoff`
- `rejected for <boundary>`
- `parked`

### Rejection behavior

Ambiguous verdicts such as `looks good`, `yep`, `continue`, `fine`, and `okay` must not throw. They must return:

```powershell
[pscustomobject]@{
    Authorized        = $false
    Action            = 'unrecognized'
    Boundaries        = @()
    DirectiveSentinel = 'SPECREW_BOUNDARY_VERDICT_UNRECOGNIZED'
    FailureReason     = 'Verdict did not match a recognized boundary authorization shape.'
}
```

### Fail-safe semantics

- Unknown text returns unauthorized, never authorized-by-default.
- Invalid compound verdicts (for example, malformed `AND` usage) return unauthorized.
- Throw only for programming/configuration failures, not for ordinary human ambiguity.

---

## 4. `Write-SpecrewBoundaryAuthorizationDirective`

### Purpose

Builds the deterministic operator-facing directive shown after a blocked, bypassed, or unrecognized verdict outcome.

### Signature

```powershell
function Write-SpecrewBoundaryAuthorizationDirective {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentBoundary,

        [Parameter(Mandatory = $true)]
        [string]$RequestedBoundary,

        [Parameter(Mandatory = $true)]
        [string]$DirectiveSentinel,

        [AllowNull()]
        [pscustomobject]$ParseResult,

        [AllowNull()]
        [string]$BypassReason
    )
}
```

### Output contract

The first line must be the sentinel. Example blocked directive:

```text
SPECREW_BOUNDARY_BLOCKED
Boundary `plan -> tasks` requires explicit human authorization.
Recognized verdicts:
- approved for tasks-boundary entry
- approved for tasks
- rejected for tasks
- parked
```

Example bypass directive:

```text
SPECREW_BOUNDARY_BYPASS_ACTIVE
Boundary enforcement is bypassed for this session.
Reason: schema migration replay
```

### Required behavior

1. Emit only canonical boundary names in examples.
2. Include the recognized verdict shapes when the parse result is unrecognized.
3. Be pure: no file writes, no state mutation.
4. Produce text stable enough for integration tests.

### Fail-safe semantics

If the directive cannot be rendered with valid canonical boundaries, throw rather than emit misleading instructions.

---

## Mirror parity requirements

1. The four functions must exist in both mirrored `shared-governance.ps1` files with identical parameter names, defaults, and return shapes.
2. Any future helper that one function depends on (for example, snippet truncation or schema validation) must also remain mirrored.
3. Tests should compare the mirrored files or at minimum assert that both copies export the same function signatures.
4. Documentation changes that alter signatures or sentinel strings must update both copies in the same implementation slice.

---

## Boundary between launcher and skill hooks

- `scripts\specrew-start.ps1` is responsible for activating emergency bypass, migration preflight, and startup messaging.
- The four functions above are responsible for actual boundary authorization, persistence, parsing, and deterministic operator guidance.
- The contract deliberately avoids host-specific assumptions so the same helpers can serve Copilot CLI, Codex, Claude, or future launch hosts.
