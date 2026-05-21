# Contract: Validator Rule Input & Output (F-028)

**Purpose**: Define the interface contract for the pre-review commit gate validator rule  
**Version**: 1.0  
**Status**: Complete

---

## Validator Rule Interface

### Input Contract

**Function**: `Test-PreReviewCommitGate`

```powershell
function Test-PreReviewCommitGate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$IterationPath,
        
        [Parameter(Mandatory=$true)]
        [string]$Baseline
    )
}
```

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| `IterationPath` | string | Yes | File system path to iteration directory (e.g., `C:\Dev\Specrew\specs\028-review-evidence-integrity`); must contain `state.md` |
| `Baseline` | string | Yes | Git reference used as baseline (e.g., `main`, `origin/main`, commit SHA); must be valid and resolvable in current repo |

### Output Contract

**Returns**: `[PSCustomObject]` or `$null`

#### When violation is detected:
```powershell
@{
    RuleID = 'pre-review-commit-gate'
    Category = 'review-evidence-integrity'
    Severity = 'error'
    Message = [string]  # Human-readable description
    RemediationHint = [string]  # Guidance for fixing
    Evidence = @{
        DeclaredTaskCount = [int]
        CommittedFileCount = [int]
        Baseline = [string]
        IterationPath = [string]
    }
}
```

#### When no violation:
```powershell
$null  # No output; validator treats as success
```

### Invocation Contract

**Invoked by**: `validate-governance.ps1` (Proposal 004 validator plane)  
**Invocation Point**: Review boundary advance (implement → review transition)  
**Error Handling**: Rule must not throw; return ValidationResult with appropriate Severity  
**Blocking Semantics**: When Severity = 'error', validator must block advancement

### Example Usage

```powershell
# Called by validate-governance.ps1
$result = Test-PreReviewCommitGate `
    -IterationPath 'C:\Dev\Specrew\specs\028-review-evidence-integrity' `
    -Baseline 'main'

if ($null -ne $result) {
    # Violation detected
    if ($result.Severity -eq 'error') {
        Write-Error "Validation blocked: $($result.Message)"
        exit 1
    } elseif ($result.Severity -eq 'warning') {
        Write-Warning "Validation warning: $($result.Message)"
    }
}
```

---

## Dependencies

**On Proposal 004 (Validator Hardening)**: Expects ValidationResult structure and validator-plane invocation contract  
**On Proposal 030 (Quality Hardening Bundle)**: No explicit dependency; rule is self-contained but composes with 030's validators

---

## Stability

**API Stability**: `v1` frozen  
**Expected Changes**: No breaking changes expected for Phase 1  
**Compatibility**: Must remain compatible with Proposal 030 validators when they are added (030 should not need to modify this rule)
