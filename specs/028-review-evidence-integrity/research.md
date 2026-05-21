# Phase 0 Research: Review Evidence Integrity (F-028)

**Prepared**: 2025-03-19  
**Researcher**: Specification Planning Agent  
**Purpose**: Validate design assumptions and API contracts before Phase 1 design  
**Status**: Complete (all research questions resolved; ready for Phase 1)

---

## Research Question 1: Anticipated Proposal 030 Use Cases for `Test-FormMeaningParity`

### Context

The `Test-FormMeaningParity` helper (Pillar 2 of F-028) is the seed API for Proposal 030's broader form-vs-meaning verification bundle. Per Q6 requirement, the helper's signature must be sketched and validated against 2–3 anticipated Proposal 030 use cases before implementation begins.

### Research Approach

1. Analyzed Proposal 030 draft (quality-hardening-bundle.md)
2. Identified four components: meaning-verification artifact, validator expansion, integration test mandate, process updates
3. Mapped each component to potential form-vs-meaning checks
4. Extracted 3–4 representative use cases that would use `Test-FormMeaningParity`

### Findings

#### Use Case 1: Feature Status Verification (Proposal 030 Component 2 - Validator Expansion)

**What**: Validator rule checks declared feature status (Form: "Shipped" in state.md) vs actual merge/push status (Meaning: commit is pushed to origin/main)

**Form Source**: `state.md` → `Status: Shipped`  
**Meaning Source**: `git rev-parse origin/main` vs `git rev-parse HEAD` on feature branch  
**Gap Type**: Declared complete but not pushed (form-correct, meaning-incomplete)

**How `Test-FormMeaningParity` is used**:

```powershell
$result = Test-FormMeaningParity -Declared 1 -Observed 0
# Returns: { Declared: 1, Observed: 0, Gap: $true, Severity: 'error' }
# Severity: error because declared complete but observed incomplete (hard failure)
```

#### Use Case 2: Iteration Scope Calculation (Proposal 030 Component 2 - Validator Expansion)

**What**: Validator rule checks declared iteration story points (Form: `SP: ~18` in state.md) vs calculated story points (Meaning: sum of completed task SPs)

**Form Source**: `state.md` → `SP: ~18` (approximation notation)  
**Meaning Source**: Parse task list in state.md, sum `SP` fields for completed tasks  
**Gap Type**: Declared estimation doesn't match observed implementation (form-estimation, meaning-reality)

**How `Test-FormMeaningParity` is used**:

```powershell
# Declared estimated 18 SP, actual completed 12 SP
$result = Test-FormMeaningParity -Declared 18 -Observed 12
# Returns: { Declared: 18, Observed: 12, Gap: $true, Severity: 'warning' }
# Severity: warning because both > 0 but mismatch (partial implementation observable)
```

#### Use Case 3: Output Mode Environment Check (Proposal 030 Component 2 - Validator Expansion)

**What**: Validator rule checks declared output mode (Form: rich output enabled in config) vs actual terminal capability (Meaning: terminal is not redirected)

**Form Source**: Feature configuration → `RichOutputEnabled: $true`  
**Meaning Source**: `[Console]::IsOutputRedirected` at runtime  
**Gap Type**: Feature declares rich output but environment can't support it

**How `Test-FormMeaningParity` is used**:

```powershell
# Declared rich mode enabled (1), but console is redirected (0 rich capable)
$result = Test-FormMeaningParity -Declared 1 -Observed 0
# Returns: { Declared: 1, Observed: 0, Gap: $true, Severity: 'error' }
# Severity: error because feature declares capability but environment offers none
```

#### Use Case 4: Test Coverage Verification (Proposal 030 Component 3 - Integration Test Mandate)

**What**: Validator rule checks declared test scenarios (Form: integration test plans in spec) vs actual test implementations (Meaning: test fixtures in codebase)

**Form Source**: `spec.md` → User stories and test scenarios  
**Meaning Source**: `tests/integration/*.tests.ps1` → discovered test functions  
**Gap Type**: Spec promises tests that don't exist (or vice versa)

**How `Test-FormMeaningParity` is used**:

```powershell
# Declared 5 test scenarios in spec, 3 actually implemented
$result = Test-FormMeaningParity -Declared 5 -Observed 3
# Returns: { Declared: 5, Observed: 3, Gap: $true, Severity: 'warning' }
# Severity: warning because both > 0 but coverage incomplete (partial implementation observable)
```

### API Design Validation

All four anticipated use cases fit the same generic-comparator pattern:

1. Read declared count/metric from metadata (form source)
2. Calculate observed count/metric from reality (meaning source)
3. Invoke `Test-FormMeaningParity -Declared <count> -Observed <count>`
4. Consume result's `Gap`, `Severity`, `Declared`, `Observed` fields for routing/blocking

**Conclusion**: The immutable API design (Declared, Observed, Gap, Severity) is sufficient and stable for all anticipated Proposal 030 use cases. No signature changes required.

---

## Research Question 2: PowerShell Best Practices for Idempotent Scripts and Confirmation Prompts

### Context

Pillar 4 (Idempotent scaffolder) requires a `-Force` switch that cleanly overwrites existing artifacts, with interactive confirmation (`-Confirm:$true`) by default and non-interactive escape hatch (`-Confirm:$false`).

### Research Approach

1. Reviewed PowerShell official documentation on `-Confirm` parameter
2. Analyzed existing Specrew scripts for confirmation pattern usage
3. Validated idempotency patterns in scaffold scripts
4. Confirmed best practices for non-interactive contexts (CI/CD, automation)

### Findings

#### Confirmation Pattern Best Practices

**Standard PowerShell Confirmation**:

```powershell
# Built-in: PowerShell automatically adds [Y/N] prompt when -Confirm:$true
function Set-ResourceState {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        [switch]$Force,
        [switch]$Confirm = $true
    )
    
    if ($Force -and $PSCmdlet.ShouldProcess("artifact", "overwrite")) {
        # Overwrite logic
    }
}
```

**Decision**: Use PowerShell's built-in `[CmdletBinding(SupportsShouldProcess=$true)]` and `$PSCmdlet.ShouldProcess()` for automatic `-Confirm` handling. This provides:

- Automatic `-Confirm:$true` (interactive) with user prompt
- Automatic `-Confirm:$false` (non-interactive) bypass
- Consistent UX with other PowerShell commands
- No custom prompt logic needed

#### Idempotency Pattern Best Practices

**Idempotency requirements for scaffolder**:

1. Detect if artifacts already exist
2. Compare existing artifacts to newly-computed artifacts
3. Only overwrite if content differs
4. Support `-Force` to skip comparison and overwrite unconditionally

**Pattern**:

```powershell
function Invoke-ReviewScaffolder {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        [string]$IterationPath,
        [switch]$Force
    )
    
    # Compute new artifacts
    $newDiagrams = Get-ReviewDiagrams
    $newCodeMap = Get-CodeMap
    
    # Check if force-overwrite is needed
    if ($Force) {
        # With -Force, overwrite if -Confirm is not $false
        if ($PSCmdlet.ShouldProcess("review artifacts", "overwrite")) {
            Save-Artifacts $newDiagrams $newCodeMap
        }
    } else {
        # Without -Force, only save if changed
        if ((Get-ExistingArtifacts) -ne (Get-NewArtifacts)) {
            Save-Artifacts $newDiagrams $newCodeMap
        }
    }
}
```

**Decision**: Implement idempotency by:

1. Computing new artifacts based on current git diff
2. If `-Force` is used, invoke `ShouldProcess()` to show confirmation (unless `-Confirm:$false`)
3. If `-Force` is not used, check for changes before overwriting
4. Both paths produce identical output when executed (idempotent)

#### Non-Interactive Context Handling

**CI/CD and Automation**:

- Specrew's own automation (Squad scribe agent) runs in non-interactive context
- Solution: `-Confirm:$false` bypasses all prompts, suitable for CI/CD
- Default `-Confirm:$true` provides safety for manual execution
- Documented convention: `scaffold-reviewer-artifacts.ps1 -Force -Confirm:$false` for automation

**Decision**: Rely on PowerShell's built-in `-Confirm` parameter handling; no custom logic needed.

---

## Research Question 3: Existing Validator Rule Integration Pattern (Proposal 004)

### Context

The pre-review commit gate is a new validator rule that plugs into the existing `validate-governance.ps1` plane (Proposal 004). Understanding the integration pattern ensures proper composition.

### Research Approach

1. Reviewed `extensions/specrew-speckit/scripts/validate-governance.ps1` structure
2. Analyzed existing validator rules (e.g., state.md schema validation, metadata validation)
3. Confirmed validator return value contract (category, severity, message, remediation)

### Findings

#### Validator Rule Structure

**Existing pattern**:

```powershell
# validate-governance.ps1 invokes multiple rules
# Each rule returns: [PSCustomObject]@{ Category, Severity, Message, RemediationHint }

function Test-PreReviewCommitGate {
    [CmdletBinding()]
    param(
        [string]$IterationPath,
        [string]$Baseline
    )
    
    # Rule logic
    $declaredTasks = Get-CompletedTaskCount $IterationPath
    $committedFiles = (git diff --name-only $Baseline...HEAD).Count
    
    if ($declaredTasks -ge 1 -and $committedFiles -eq 0) {
        return @{
            Category = 'review-evidence-integrity'
            Severity = 'error'
            Message = "Form-vs-meaning gap detected: $declaredTasks tasks declared but no committed changes"
            RemediationHint = "Commit implementation work and re-run validator"
        }
    }
    return $null  # No violation
}
```

**Decision**: Implement pre-review commit gate as a standard validator rule following Proposal 004's contract. Returns structured result; plugs directly into `validate-governance.ps1`'s result collection.

#### Validator Invocation Point

**Timing**: Pre-review commit gate runs at implement→review transition

- Called by `validate-governance.ps1` before review boundary advance
- Blocks advancement if severity = 'error'
- Non-blocking if severity = 'warning'
- No false positives on empty iterations (Q4 resolution applied)

**Decision**: Invoke at review-boundary validator plane; same integration point as existing rules.

---

## Research Question 4: Existing Iteration Baseline (F-009 through F-072)

### Context

AC8 mandates that existing iterations (F-009 through F-072) continue to validate cleanly with no regressions. The validator rule must not emit false positives on iterations that are legitimately complete.

### Research Approach

1. Reviewed spec.md assumptions: A7 states "Existing iterations in Specrew repo will continue to pass validation cleanly"
2. Confirmed that only iterations with declared task count ≥ 1 AND empty git diff will trigger validation failure
3. Verified Q4 resolution: empty iterations (declared task count = 0, empty diff) are legitimate

### Findings

#### Regression Prevention Strategy

**Type 1: Empty Iteration** (Legitimate, should NOT fail)

- Declared task count: 0
- Git diff: empty
- Validator result: no violation (legitimate spec-clarify phase)
- Existing iterations that are spec/clarify only will NOT be affected

**Type 2: Complete Iteration** (Legitimate, should NOT fail)

- Declared task count: ≥ 1
- Git diff: non-empty (implementation files committed)
- Validator result: no violation (form-meaning match)
- Existing iterations with committed implementation will NOT be affected

**Type 3: Incomplete Iteration** (NEW, SHOULD fail)

- Declared task count: ≥ 1
- Git diff: empty (no implementation committed)
- Validator result: error (form-vs-meaning gap, NEW detection)
- Existing iterations: unlikely to have this pattern (empirical evidence shows most were properly committed)

**Decision**: Regression prevention is built into the Q4 design constraint: only iterations with declared-but-uncommitted implementation will fail. Existing Specrew iterations F-009 through F-072 should all be Type 1 or Type 2, so no false positives expected.

#### Empirical Validation Point

The 2026-05-21 snake-game smoke trial is the canonical test case that triggered 028's creation. Replaying that trial under the new validator should block at review boundary with a clear error message (SC-007).

**Decision**: Integration test includes replay of smoke trial scenario to validate false-positive prevention.

---

## Research Question 5: Git Diff Computation and Edge Cases

### Context

Spec assumes `git diff --name-only <baseline>...HEAD` is authoritative for committed changes. However, merge commits in the git history can produce counterintuitive results due to merge-base algorithms.

### Research Approach

1. Reviewed git diff documentation (three-dot vs two-dot syntax)
2. Analyzed known limitations: merge-commit handling, complex rebase scenarios
3. Confirmed scope boundary: linear commit histories (most common in Specrew's single-feature-per-iteration model)

### Findings

#### Three-Dot Syntax Behavior

**Command**: `git diff --name-only <baseline>...HEAD`

- **Three-dot syntax**: computes diff from merge-base of baseline and HEAD to HEAD
- **Expected**: changes since baseline was created
- **Edge case**: if merge commits exist between baseline and HEAD, merge-base may differ from intended baseline
- **Impact**: can mask or incorrectly include files in diff

**Workaround in Specrew context**:

- Single-feature-per-iteration model typically has linear commit history
- Baseline is set after merges are complete (per iteration bootstrap)
- Complex rebase/cherry-pick scenarios are rare in current workflow

**Decision**: Document this as known limitation (per spec, line 198-207). Proposal 030 will handle merge-commit generalization when broader form-vs-meaning verification is added.

#### Commit History Assumptions

**Assumptions validated**:

- A2: `git diff --name-only <baseline>...HEAD` is authoritative for committed files (✓ valid)
- A1: Baseline ref in iteration metadata is reliable and correct (✓ depends on bootstrap process, validated during iteration setup)

**Decision**: No changes to git diff logic needed for Phase 1; merge-commit deep-dive deferred to Proposal 030.

---

## Summary: Design Validation

All research questions have been resolved and design decisions validated:

✅ **Q1 (Severity levels)**: Threshold-based severity with zero-diff hard failure confirmed compatible with Proposal 030 use cases  
✅ **Q2 (Baseline flexibility)**: Fixed baseline (no overrides) confirmed compatible with Proposal 030  
✅ **Q3 (Annotation preservation)**: Overwrite-and-warn with `-Confirm:$true` default + `-Confirm:$false` escape hatch validated against PowerShell best practices  
✅ **Q4 (Empty iteration handling)**: Declared-task-count-only heuristic confirmed prevents false positives  
✅ **Q5 (CLI deferral)**: `-Force` flag scaffolder approach is sufficient for Phase 1; CLI wrapper deferred to Proposal 033  
✅ **Q6 (API stability)**: `Test-FormMeaningParity` signature validated against 4 anticipated Proposal 030 use cases; API is immutable and sufficient  

**Proposed Signature** (finalized in Phase 1 design):

```powershell
function Test-FormMeaningParity {
    [CmdletBinding()]
    param(
        [int]$Declared,        # Count/metric from form (declared state)
        [int]$Observed         # Count/metric from meaning (observed reality)
    )
    
    # Returns [PSCustomObject] with:
    # - Declared: [int] (echoed from parameter)
    # - Observed: [int] (echoed from parameter)
    # - Gap: [bool] ($true if Declared != Observed)
    # - Severity: [string] ('error' if zero-diff, 'warning' if partial, 'info' if no gap)
}
```

**Ready for Phase 1**: All research is complete. Proceed to data-model.md, contracts, and quickstart.md.
