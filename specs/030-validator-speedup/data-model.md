# Data Model: Local Validator Auto-Scope for Feature-Branch Invocations

**Schema**: v1  
**Feature**: Proposal 083  
**Context**: PowerShell script-based validator configuration and control flow  
**No new persistent entities created**

---

## Overview

Proposal 083 adds a new layer to the validator's control flow: base-ref detection and auto-scope logic. The feature operates entirely on existing entities (git state, script parameters) and introduces no new database, configuration file, or persistent data structures.

This document defines the **control flow model**, **parameter schema**, and **state transitions** involved in the feature.

---

## Input Configuration Model

### `validate-governance.ps1` Parameters

#### Current Parameters (Unchanged)

| Parameter | Type | Default | Purpose | Validation |
|-----------|------|---------|---------|-----------|
| `-ProjectPath` | string | Required | Root path of project to validate | Must be valid directory |
| `-IterationPath` | string | Optional | Specific iteration to validate (if not project-wide) | If provided, must be subdirectory of ProjectPath |

#### New Parameter (FR-003)

| Parameter | Type | Default | Purpose | Validation | Precedence |
|-----------|------|---------|---------|-----------|-----------|
| `-FullRun` | boolean | $false | Bypass auto-scope heuristics; force full-repo validation | N/A (flag is present or absent) | **Highest**: If present, all auto-scope logic is skipped |

#### Existing Parameters (Documented for Completeness)

| Parameter | Type | Default | Purpose | Validation | Precedence |
|-----------|------|---------|---------|-----------|-----------|
| `-ChangedOnly` | boolean | $false (no auto-scope) | Run validation only on changed files/iterations | N/A (flag is present or absent) | **High**: If explicitly passed, honored over auto-scope default |
| `-BaseBranch` | string | Optional | Base branch ref for `-ChangedOnly` scoping | Must be valid git ref if provided | **High**: Used when `-ChangedOnly` is passed |

---

## Helper Function Model

### `Get-SpecrewLocalScopeBaseRef` (New; FR-001)

**Location**: `scripts/internal/shared-governance.ps1` (+ mirrors in `extensions/specrew-speckit/scripts/shared-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1`)

**Signature**

```powershell
function Get-SpecrewLocalScopeBaseRef {
    param(
        [string]$RepoRoot = (Get-Location).Path
    )
    # Returns [string] ref name or [null] if undetectable
}
```

**Input State**

| State | Source | Type | Required |
|-------|--------|------|----------|
| Current git branch | `git rev-parse --abbrev-ref HEAD` | string | Yes |
| Environment variable | `$env:GITHUB_BASE_REF` | string or null | Conditional |
| Default upstream | `git symbolic-ref refs/remotes/origin/HEAD` | string or null | Conditional |
| Remote refs | `git for-each-ref refs/remotes/origin/main refs/remotes/origin/master` | array or empty | Conditional |

**Output (Control Path Decision Point)**

| Output | Meaning | Next Action |
|--------|---------|-------------|
| `"origin/main"` (or other valid ref) | Base ref successfully detected | Auto-scope applies (if on feature branch and no explicit flags) |
| `$null` | Base ref undetectable (no remote, detached HEAD, etc.) | Full-repo validation fallback with info banner |

**Priority Chain Logic** (FR-001)

```
1. if ( $env:GITHUB_BASE_REF is set ) → return $env:GITHUB_BASE_REF
2. elseif ( git symbolic-ref refs/remotes/origin/HEAD resolves ) → return resolved ref
3. elseif ( git for-each-ref finds refs/remotes/origin/main or refs/remotes/origin/master ) → return first match (prefer main)
4. else → return $null (undetectable)
```

**State Contract**

- Function MUST NOT modify git state (read-only queries only)
- Function MUST handle detached HEAD gracefully (return `$null` rather than error)
- Function MUST handle no-remote scenario gracefully (return `$null` rather than error)

---

## Validator Behavior State Machine

### Branch Detection State

| State | Condition | Detection Method |
|-------|-----------|------------------|
| On main/master | Current branch matches `main` or `master` | `git rev-parse --abbrev-ref HEAD` |
| On feature branch | Current branch does NOT match `main` or `master` | Same |
| Detached HEAD | HEAD is not symbolic | `git rev-parse --abbrev-ref HEAD` returns `HEAD` |

### Scope Decision Logic (FR-002, FR-004, FR-005)

**Input**: Branch state, flags, base-ref detection result

**Decision Tree**

```
if ( -FullRun flag is present )
  scope = FULL_REPO
  reason = "FullRun override"
elseif ( -ChangedOnly flag is present )
  scope = CHANGED_ONLY
  base = $BaseBranch or (query git)
  reason = "explicit flag"
elseif ( current branch is main or master )
  scope = FULL_REPO
  reason = "on main branch"
elseif ( base ref detectable )
  scope = CHANGED_ONLY (auto-apply)
  base = detected ref
  reason = "auto-scoped"
else
  scope = FULL_REPO (fallback)
  reason = "base undetectable"
```

**Output State**

| Field | Type | Values | Example |
|-------|------|--------|---------|
| `scope` | enum | `FULL_REPO`, `CHANGED_ONLY` | `CHANGED_ONLY` |
| `reason` | string | One of: "FullRun override", "explicit flag", "on main branch", "auto-scoped", "base undetectable" | `"auto-scoped"` |
| `base_ref` | string or null | Git ref name if scoped | `"origin/main"` |
| `iteration_count` | int | Total iterations (full) or changed iterations (scoped) | `3` |
| `file_count` | int or null | Number of changed files (scoped only) | `5` |

---

## Output Reporting Model

### `[validator-scope]` Banner (FR-006)

**Output**: Stdout line (first informational output of validator run)

**Format Variants**

| Scenario | Banner Format | Fields |
|----------|---------------|--------|
| Auto-scoped run | `[validator-scope] auto-scoped to <base-ref>...HEAD (<iteration-count> iterations, <file-count> files in diff)` | base-ref, iteration-count, file-count |
| Full-repo on main | `[validator-scope] full-repo (on main; <iteration-count> iterations)` | iteration-count |
| Full-repo base undetectable | `[validator-scope] full-repo (base-undetectable; <iteration-count> iterations)` | iteration-count |
| Full-repo -FullRun override | `[validator-scope] full-repo (-FullRun override; <iteration-count> iterations)` | iteration-count |

**Constraints**

- Banner MUST appear as the first line of every validator run (before any other informational output)
- Banner MUST include scope type (auto-scoped, full-repo) and reason
- Banner MUST include iteration count (always)
- Banner MUST include file count if scoped to changed-only (optional if full-repo)
- Banner format MUST be stable and parseable by audit trails and tooling

---

## Validation Scope Model

### Full-Repo Validation

**Definition**: Validator runs against all iterations and global-state pathspecs in the repository

**When Applied**:

- User on main/master branch with no flags
- `-FullRun` flag explicitly passed
- Base ref undetectable (graceful fallback)

**Iteration Set**: All iterations in `specs/` directory

**File Set**: All files matching global-state pathspecs (from `Get-ValidatorGlobalStatePathspecs`)

### Changed-Only Validation (Auto-Scoped)

**Definition**: Validator runs only against files and iterations that differ between base ref and HEAD

**When Applied**:

- User on feature branch, base ref detectable, no explicit flags

**Iteration Set**: Only iterations containing changed files in the diff between base and HEAD

**File Set**: Only files matching global-state pathspecs that appear in the diff

**Diff Computation**:

- Uses existing `Get-ChangedIterations` helper from `ci(lint-scoping)`
- Computes diff as `git diff <base-ref>...HEAD --name-only`
- Handles Windows path normalization (backslash → forward slash)

---

## Mirror Parity Model

### Primary-to-Mirror Sync Requirements

Three locations must be kept in sync (FR-012):

| Component | Primary | Mirror 1 | Mirror 2 | Sync Strategy |
|-----------|---------|----------|----------|---------------|
| Base-ref helper | `scripts/internal/shared-governance.ps1` | `extensions/specrew-speckit/scripts/shared-governance.ps1` | `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` | Identical copies; manual sync |
| Validator script | `scripts/internal/validate-governance.ps1` | `extensions/specrew-speckit/scripts/validate-governance.ps1` | `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | Identical copies; manual sync |
| Coordinator governance prompt | N/A | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | Identical copies; manual sync |
| Reviewer charter | N/A | `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` | `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` | Identical copies; manual sync |

**Parity Verification** (Task T-009):

- Byte-for-byte comparison of primary vs. mirrors
- Fail if any mirror diverges from primary
- Document sync date and verifier

---

## State Transition Diagram

```
[Validator Invoked]
        ↓
[Read Flags & Branch State]
        ↓
    ┌─────────────────────────────────────────────────────┐
    │ Decision Logic                                      │
    ├─────────────────────────────────────────────────────┤
    │ -FullRun? → FULL_REPO (-FullRun override)           │
    │ -ChangedOnly? → CHANGED_ONLY (explicit)             │
    │ On main/master? → FULL_REPO (on main)               │
    │ Base detectable? → CHANGED_ONLY (auto-scoped)       │
    │ Default → FULL_REPO (base-undetectable)             │
    └─────────────────────────────────────────────────────┘
        ↓
    [Determine Scope]
        ↓
    ┌─────────────────────────────────────────────────────┐
    │ If CHANGED_ONLY:                                    │
    │   Compute changed iterations (Get-ChangedIterations)│
    │   Compute changed files (git diff)                  │
    │   Count: iteration_count, file_count                │
    │ If FULL_REPO:                                       │
    │   Count: iteration_count (all), file_count (null)   │
    └─────────────────────────────────────────────────────┘
        ↓
    [Emit [validator-scope] Banner]
        ↓
    [Execute Validation Against Determined Scope]
        ↓
    [Output Results]
        ↓
    [Validator Complete]
```

---

## Configuration Constraints

### No Persistent Configuration Required

- No new `.specify/config/` files or YAML configuration added
- No new environment variables introduced (only reads existing `$env:GITHUB_BASE_REF` for CI path)
- All behavior controlled via script parameters or git state

### Backward Compatibility Constraints

- Existing `-ChangedOnly` invocations MUST continue to work unchanged
- Existing `-BaseBranch` invocations MUST continue to work unchanged
- Existing full-repo invocations (no flags) on main MUST continue to run full-repo
- No breaking changes to existing helper function signatures

---

## Validation Rules & Constraints

### Input Validation

| Input | Rule | Enforcement |
|-------|------|-------------|
| `-ProjectPath` | Must be valid directory | Existing validator logic (unchanged) |
| `-BaseBranch` | Must be valid git ref | Existing validator logic (when `-ChangedOnly` used) |
| Git state | Must have .git directory or config | Graceful fallback to full-repo if not available |
| Feature branch detection | Branch name any non-main/master ref | Auto-detect via git branch state |

### Scope Safety Constraints

| Constraint | Rationale | Enforcement |
|-----------|-----------|-------------|
| Main/master NEVER auto-scoped | Truth branch must always run full validation | Explicit branch name check before auto-scope |
| `-FullRun` bypasses auto-scope entirely | Deliberate opt-out must work | Flag checked first in decision logic |
| Base-undetectable falls back safely | No failure mode for detached HEAD/no-remote | `$null` check returns FULL_REPO with info banner |
| Explicit flags honored over defaults | Backward compatibility | Flag presence checked before auto-scope logic |

---

## Summary

**Data Entities Created**: None (feature operates on existing git state and script parameters)

**Control Flow Changes**: New decision layer added to `validate-governance.ps1` scope selection logic

**Helper Functions Added**: `Get-SpecrewLocalScopeBaseRef` (new function in `shared-governance.ps1`)

**Parameter Changes**: New `-FullRun` boolean flag (non-breaking addition)

**Output Changes**: New `[validator-scope]` stdout banner (first line of every run)

**Configuration Changes**: None (no new configuration files; no new environment variables)

**Backward Compatibility**: Fully preserved; existing scripts and flags continue unchanged

**Mirror Parity**: Four locations must be kept in sync (task T-009)
