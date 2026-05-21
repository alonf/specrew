# Contract: Test-FormMeaningParity Helper Function (F-028)

**Purpose**: Define the immutable API contract for the form-vs-meaning parity helper function  
**Version**: 1.0 (immutable, per Q6 decision)  
**Status**: Complete  
**Audience**: Implementation engineers; Proposal 030 consumers

---

## Function Signature

```powershell
function Test-FormMeaningParity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Declared,
        
        [Parameter(Mandatory=$true)]
        [int]$Observed
    )
}
```

| Parameter | Type | Required | Default | Notes |
| --- | --- | --- | --- | --- |
| `Declared` | int | Yes | N/A | Count/metric from declared state (form); must be ≥ 0 |
| `Observed` | int | Yes | N/A | Count/metric from observed reality (meaning); must be ≥ 0 |

---

## Return Value Contract

**Returns**: `[PSCustomObject]` with four fields (always)

```powershell
@{
    Declared = [int]      # Echo of Declared parameter
    Observed = [int]      # Echo of Observed parameter
    Gap = [bool]          # $true if Declared ≠ Observed; $false otherwise
    Severity = [string]   # 'error' | 'warning' | 'info'
}
```

### Field Definitions

| Field | Type | Values | Notes |
| --- | --- | --- | --- |
| `Declared` | int | ≥ 0 | Echoed from input parameter; represents count/metric from form |
| `Observed` | int | ≥ 0 | Echoed from input parameter; represents count/metric from meaning |
| `Gap` | bool | `$true` \| `$false` | `$true` if Declared ≠ Observed; `$false` if Declared = Observed |
| `Severity` | string | 'error' \| 'warning' \| 'info' | Ordinal severity level for routing/blocking logic |

### Severity Assignment Logic

| Condition | Gap | Severity | Notes |
| --- | --- | --- | --- |
| Declared = Observed | `$false` | 'info' | No form-vs-meaning gap |
| Declared > 0 AND Observed = 0 | `$true` | 'error' | Hard failure: declared complete but nothing observed (e.g., zero-diff) |
| Declared > Observed AND Observed > 0 | `$true` | 'warning' | Partial implementation: both > 0 but mismatch (e.g., 11 tasks declared, 7 completed) |
| Declared = 0 AND Observed = 0 | `$false` | 'info' | No gap; legitimate empty state (e.g., spec-only iteration) |
| Declared < Observed | `$true` | 'warning' | Unexpected but handled: observed exceeds declared (e.g., more files committed than tasks estimated) |

---

## Composition Contract

**Designed for**: Consumption by other validator rules and governance scripts  
**Non-side-effects**: Function must be purely functional; no I/O, no file writes, no git invocations  
**Idempotency**: Multiple invocations with identical inputs must produce identical outputs

### Example Compositions

#### Use Case 1: Pre-review commit gate (Feature 028)

```powershell
$result = Test-FormMeaningParity -Declared $declaredTaskCount -Observed $committedFileCount
if ($result.Severity -eq 'error') {
    # Block review advancement
}
```

#### Use Case 2: Iteration scope validation (Proposal 030)

```powershell
$result = Test-FormMeaningParity -Declared $declaredSP -Observed $completedSP
if ($result.Gap) {
    Write-Host "Warning: Iteration scope mismatch detected"
}
```

#### Use Case 3: Test coverage verification (Proposal 030)

```powershell
$result = Test-FormMeaningParity -Declared $specScenarioCount -Observed $implementedTestCount
if ($result.Severity -eq 'error') {
    # Flag missing test coverage
}
```

---

## Stability & Versioning

**API Version**: 1.0  
**Status**: Frozen (immutable as per Q6 decision)  
**Backward Compatibility**: This is the v1 contract; Proposal 030 must compose around it, not modify it  
**Extension Strategy**: New helpers (e.g., `Test-FormMeaningParity-Advanced`) can be added; this one cannot change

### What Cannot Change

- Function name: `Test-FormMeaningParity` (no renaming)
- Parameter names or types: `-Declared [int]` and `-Observed [int]` (no adding/removing/renaming)
- Return value structure: Always `[PSCustomObject]` with Declared, Observed, Gap, Severity
- Severity value set: Always 'error', 'warning', 'info' (no new severity levels)
- Severity logic: The four conditions above are fixed

### What Can Change (Without Breaking)

- Implementation optimization (e.g., faster Gap computation)
- Extended documentation or examples
- Addition of optional `-Verbose` or `-Debug` output (via Write-Verbose, not return value)
- New helper functions alongside this one (composition, not modification)

---

## Error Handling

### Input Validation

- `$Declared` must be integer ≥ 0; non-negative values are assumed
- `$Observed` must be integer ≥ 0; non-negative values are assumed
- Function must not throw on valid inputs; invalid inputs may throw with clear message

### Example Error Cases

```powershell
# Valid: returns { Declared: -1, Observed: 5, Gap: $true, Severity: 'warning' }
# Note: Negative inputs are accepted but treated as unusual; severity logic still applies

# Valid: zero-zero case
# Test-FormMeaningParity -Declared 0 -Observed 0
# Returns: { Declared: 0, Observed: 0, Gap: $false, Severity: 'info' }

# Invalid input would throw (e.g., string passed instead of int)
# Test-FormMeaningParity -Declared "abc" -Observed 5
# Throws: Cannot bind argument to parameter 'Declared'...
```

---

## Testing Requirements

### Unit Test Cases

| Test Case | Declared | Observed | Expected Gap | Expected Severity | Notes |
| --- | --- | --- | --- | --- | --- |
| No gap | 5 | 5 | `$false` | info | Baseline: perfect parity |
| Zero-diff (hard failure) | 5 | 0 | `$true` | error | Critical: form with no meaning |
| Empty iteration | 0 | 0 | `$false` | info | Legitimate: no work declared, none observed |
| Partial implementation | 11 | 7 | `$true` | warning | Common: some work done, some pending |
| Over-delivery | 5 | 8 | `$true` | warning | Unusual: more observed than declared |

### Composition Test Cases

- Proposal 030 validators must consume this helper without modification
- Multiple validators can invoke helper with different Declared/Observed pairs
- Results must be correct regardless of calling context

---

## Documentation

**For Implementers**:

- Function is located in `extensions/specrew-speckit/scripts/shared-governance.ps1`
- Documented with inline comment explaining parameters and return value
- Example invocations in quickstart.md

**For Consumers (Proposal 030)**:

- See `docs/api-reference.md` for usage examples
- See `specs/028-review-evidence-integrity/quickstart.md` for integration patterns
- This contract is the source of truth; no modifications permitted

---

## Related Contracts

- **Validator Rule Contract**: `specs/028-review-evidence-integrity/contracts/validator-rule-contract.md`
- **Scaffolder Contract**: Documented in `quickstart.md`
- **Data Model**: `specs/028-review-evidence-integrity/data-model.md`
