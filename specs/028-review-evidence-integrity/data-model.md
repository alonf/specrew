# Data Model: Review Evidence Integrity (F-028)

**Prepared**: 2025-03-19  
**Phase**: Phase 1 Design  
**Purpose**: Define entities, data structures, validation model, and state transitions  
**Status**: Complete

---

## Core Entities

### 1. Iteration State (from `state.md`)

**Entity**: IterationState

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `Status` | string | Yes | Values: `pending`, `in-progress`, `completed`, `review`, `shipped`, `closed` |
| `Baseline` | string (git ref) | Yes | Git reference (commit SHA, branch, tag) used as baseline for diff computation |
| `CompletedTaskCount` | int | Yes | Number of tasks marked complete in current iteration |
| `TotalTaskCount` | int | Yes | Total tasks declared for iteration |
| `LastCompletedTask` | string (task ID) | No | Most recent task marked complete (e.g., `T011`) |
| `TaskVerdicts` | array of TaskVerdict | No | List of task verification results (pass/fail/blocked) |

**Example** (YAML from state.md):
```yaml
Status: completed
Baseline: main
CompletedTaskCount: 11
TotalTaskCount: 11
LastCompletedTask: T011
TaskVerdicts:
  - TaskID: T001
    Verdict: pass
  - TaskID: T002
    Verdict: pass
```

### 2. Form-vs-Meaning Parity Result

**Entity**: FormMeaningParityResult

Returned by `Test-FormMeaningParity` helper function.

| Field | Type | Notes |
| --- | --- | --- |
| `Declared` | int | Count/metric from declared state (form) |
| `Observed` | int | Count/metric from observed reality (meaning) |
| `Gap` | bool | `$true` if Declared ≠ Observed; `$false` otherwise |
| `Severity` | string | Values: `error` (zero-diff), `warning` (partial), `info` (no gap) |

**Severity Logic**:
- `error`: Declared ≥ 1 AND Observed = 0 (hard failure, blocks advancement)
- `warning`: Declared > Observed AND both > 0 (partial implementation, non-blocking)
- `info`: Declared = Observed or Declared = 0 (no gap)

**Example**:
```powershell
# When declared tasks = 11, committed files = 0
@{
    Declared = 11
    Observed = 0
    Gap = $true
    Severity = 'error'  # Zero-diff is hard failure
}
```

### 3. Validation Result

**Entity**: ValidationResult

Returned by validator rule when invoked via `validate-governance.ps1`.

| Field | Type | Notes |
| --- | --- | --- |
| `RuleID` | string | Identifier for rule (e.g., `pre-review-commit-gate`) |
| `Category` | string | Classification (e.g., `review-evidence-integrity`) |
| `Severity` | string | Values: `error`, `warning`, `info` |
| `Message` | string | Human-readable violation description |
| `RemediationHint` | string | Guidance for fixing the violation |
| `Evidence` | object | Structured evidence supporting the violation (optional) |

**Example**:
```powershell
@{
    RuleID = 'pre-review-commit-gate'
    Category = 'review-evidence-integrity'
    Severity = 'error'
    Message = 'Form-vs-meaning gap detected: state.md declares 11 completed tasks but git diff baseline...HEAD is empty'
    RemediationHint = 'Commit implementation work using `git add . && git commit -m "Implementation complete"`. Verify with `git diff main...HEAD --stat`. Re-run `validate-governance.ps1` to validate before advancing to review.'
    Evidence = @{
        DeclaredTaskCount = 11
        CommittedFileCount = 0
        Baseline = 'main'
        IterationPath = 'file:///C:/Dev/Specrew/specs/028-review-evidence-integrity'
    }
}
```

### 4. Review Artifact Metadata

**Entity**: ReviewArtifactMetadata

Metadata attached to scaffolded review artifacts when form-vs-meaning gap is detected.

| Field | Type | Notes |
| --- | --- | --- |
| `GeneratedAt` | datetime | Timestamp when artifact was scaffolded |
| `GitBaseline` | string (git ref) | Baseline used for diff computation |
| `GitHeadCommit` | string (SHA) | Current HEAD commit when scaffolded |
| `DeclaredTaskCount` | int | Declared task count at scaffold time |
| `CommittedFileCount` | int | Number of files in `git diff baseline...HEAD` |
| `FormVsMeaningGapDetected` | bool | `$true` if Declared > 0 AND CommittedFileCount = 0 |
| `WarningEmitted` | bool | `$true` if gap warning was written to artifact |

**Example** (metadata comment in review-diagrams.md):
```markdown
<!-- 
  Scaffold Metadata
  GeneratedAt: 2025-03-19T14:30:00Z
  GitBaseline: main
  GitHeadCommit: abc1234def5678
  DeclaredTaskCount: 11
  CommittedFileCount: 0
  FormVsMeaningGapDetected: true
  WarningEmitted: true
-->

⚠️ **Review evidence may be misleading**: this iteration's `state.md` declares completed tasks but the git diff against baseline is empty...
```

---

## State Transitions

### Validator Rule Invocation Workflow

```
Iteration in "implement" phase
       ↓
[Review Boundary Advance Triggered]
       ↓
validate-governance.ps1 runs
       ↓
Test-PreReviewCommitGate rule executes:
  - Read state.md → CompletedTaskCount
  - Run git diff --name-only baseline...HEAD
  - Invoke Test-FormMeaningParity -Declared $count -Observed $fileCount
       ↓
FormMeaningParityResult returned
       ↓
  If Gap = $true AND Severity = 'error':
    → ValidationResult with Category='review-evidence-integrity', Severity='error'
    → BLOCKS boundary advance (hard failure)
    → Message includes remediation hint
  
  Else:
    → No violation
    → Boundary advance allowed to proceed
       ↓
Iteration advances to "review" phase (or blocked until fixed)
```

### Scaffolder Re-run Workflow

```
Review artifacts exist (review-diagrams.md, code-map.md, etc.)
       ↓
scaffold-reviewer-artifacts.ps1 invoked with -Force flag
       ↓
PowerShell [CmdletBinding(SupportsShouldProcess=$true)] invokes ShouldProcess()
       ↓
  If -Confirm:$true (default, interactive):
    → User sees prompt: "⚠️ Re-running with `-Force` will overwrite existing review artifacts..."
    → User responds [Y]es / [N]o / [Y]es to all / [N]o to all
    → If Yes: proceed to overwrite
    → If No: abort, artifacts unchanged
  
  Else if -Confirm:$false (non-interactive, CI/CD):
    → Skip prompt entirely
    → Proceed to overwrite unconditionally
       ↓
Artifacts are cleanly overwritten with current git diff
       ↓
Metadata is updated (GeneratedAt, GitHeadCommit, etc.)
       ↓
If FormVsMeaningGapDetected = $true:
  → Warning is inserted at top of all review artifacts
  Else:
  → Artifacts generated cleanly (no gap, all evidence present)
```

---

## Validation Rules & Constraints

### Pre-Review Commit Gate Rule

**Rule ID**: `pre-review-commit-gate`  
**Category**: `review-evidence-integrity`  
**Trigger**: Review boundary advance (implement → review)  
**Input**: IterationPath, Baseline ref  
**Process**:
1. Parse `state.md` → Extract CompletedTaskCount
2. Execute `git diff --name-only <Baseline>...HEAD`
3. Count returned files → ObservedFileCount
4. Invoke `Test-FormMeaningParity -Declared $CompletedTaskCount -Observed $ObservedFileCount`
5. If result.Gap = $true AND result.Severity = 'error':
   - Return ValidationResult with Severity='error', RemediationHint
   - BLOCK advancement
6. Else:
   - Return $null (no violation)
   - ALLOW advancement

**Constraints**:
- Must not emit false positives for empty iterations (CompletedTaskCount = 0)
- Must handle merge commits correctly (three-dot syntax behavior documented)
- Baseline ref must be from iteration metadata (no overrides, per Q2 decision)

### Form-vs-Meaning Parity Helper

**Function Signature**: `Test-FormMeaningParity`

```powershell
function Test-FormMeaningParity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Declared,
        
        [Parameter(Mandatory=$true)]
        [int]$Observed
    )
    
    # Returns [PSCustomObject]@{
    #     Declared = [int]
    #     Observed = [int]
    #     Gap = [bool]
    #     Severity = [string] ('error' | 'warning' | 'info')
    # }
}
```

**Logic**:
```
IF Declared == Observed:
    Gap = $false
    Severity = 'info'
ELSE IF Declared > 0 AND Observed == 0:
    Gap = $true
    Severity = 'error'        # Hard failure
ELSE IF Declared > Observed AND Observed > 0:
    Gap = $true
    Severity = 'warning'      # Partial, non-blocking
ELSE IF Declared == 0 AND Observed == 0:
    Gap = $false
    Severity = 'info'         # Legitimate empty iteration
ELSE:
    Gap = $true
    Severity = 'warning'      # Mismatch, but not zero-diff
```

### Scaffolder Idempotency Rule

**Function**: `scaffold-reviewer-artifacts.ps1`

**Parameters**:
- `IterationPath` (required): Path to iteration directory
- `Force` (optional): Overwrite existing artifacts (default: $false)
- `Confirm` (optional, PS built-in): Interactive prompt control (default: $true for interactive, $false for automation)

**Idempotency Guarantee**:
1. Compute new artifacts from git diff
2. If artifacts exist and Force is not set:
   - Check if content differs
   - Only save if changed (prevent unnecessary writes)
3. If Force is set and -Confirm:$true (interactive):
   - Show prompt asking for confirmation
   - Save if user confirms
4. If Force is set and -Confirm:$false (non-interactive):
   - Skip prompt
   - Save unconditionally
5. Multiple invocations with same input produce identical output (idempotent)

---

## Data Validation Rules

### state.md Validation
- CompletedTaskCount MUST be ≥ 0
- CompletedTaskCount MUST be ≤ TotalTaskCount
- Baseline ref MUST be a valid git reference (resolvable by `git rev-parse`)
- Status MUST be one of: pending, in-progress, completed, review, shipped, closed

### Git Diff Validation
- Baseline ref MUST resolve in current git repository
- Three-dot diff syntax (baseline...HEAD) MUST be supported by git version ≥ 2.0

### Warning Text Validation
- Warning message MUST appear at top of review artifact (before any generated content)
- Warning message MUST mention:
  - Declared task count is not zero
  - Git diff is empty
  - Implementation work may be uncommitted
  - Proposal 073 reference (for context)
  - Pre-review commit gate (remediation pointer)

---

## Error Handling & Edge Cases

### Edge Case 1: Empty Iteration (Legitimate)
**Condition**: CompletedTaskCount = 0 AND git diff is empty  
**Handling**: No validation failure; treat as legitimate spec-clarify phase  
**Evidence**: Q4 resolution prevents false positives

### Edge Case 2: Partial Implementation
**Condition**: CompletedTaskCount > 0 AND git diff has some files (but fewer than expected)  
**Handling**: Return `warning`-level severity (non-blocking); allow review to proceed but with visibility to gap  
**Evidence**: Q1 resolution for threshold-based severity

### Edge Case 3: Merge Commits in Baseline...HEAD
**Condition**: Complex git history with merge commits between baseline and HEAD  
**Handling**: Use three-dot syntax (`git diff baseline...HEAD`); document as known limitation  
**Evidence**: Spec section on Known Limitations & Deferred Behaviors

### Edge Case 4: Missing state.md
**Condition**: Iteration path lacks state.md  
**Handling**: Validator rule fails gracefully; emit error about missing metadata  
**Evidence**: Standard governance-plane error handling

### Edge Case 5: User Cancels Confirmation Prompt
**Condition**: `-Confirm:$true` and user selects `[N]o` at prompt  
**Handling**: Scaffolder aborts; existing artifacts remain unchanged  
**Evidence**: PowerShell [CmdletBinding(SupportsShouldProcess=$true)] standard behavior

---

## Composition Points

### With Proposal 030 (Quality Hardening Bundle)
- `Test-FormMeaningParity` helper is imported by 030's additional form-vs-meaning validators
- No modification to function signature (immutable API per Q6)
- New validators compose the helper without understanding implementation details

### With Proposal 033 (Specrew Governance CLI)
- `-Force` flag is the primary backend mechanism for scaffolder re-run
- Optional `specrew review-evidence regenerate` CLI command wraps the scaffolder invocation
- No changes to data model when 033 ships

### With Proposal 004 (Validator Hardening, shipped)
- Pre-review commit gate rule plugs into the same validation plane
- Uses standard ValidationResult structure from Proposal 004
- No interference with existing validator rules
