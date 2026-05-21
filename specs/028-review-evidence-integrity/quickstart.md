# Quickstart: Integrating Review Evidence Integrity (F-028)

**Prepared**: 2025-03-19  
**Phase**: Phase 1 Design  
**Audience**: Implementation engineers, Proposal 030 consumers  
**Purpose**: Integration guide for the five pillars

---

## Overview

Feature 028 provides four components for hardening the review boundary:

1. **Test-FormMeaningParity helper** (`shared-governance.ps1`): Generic form-vs-meaning comparator
2. **Pre-review commit gate** (`validate-governance.ps1`): Validator rule blocking incomplete iterations
3. **Scaffolder warnings** (`scaffold-reviewer-artifacts.ps1`): Loud signals when gaps detected
4. **Idempotent re-run** (`-Force` flag): Clean artifact regeneration with confirmation

---

## Component 1: Using the Test-FormMeaningParity Helper

### Location

```
extensions/specrew-speckit/scripts/shared-governance.ps1
```

### Function Signature

```powershell
function Test-FormMeaningParity {
    [CmdletBinding()]
    param(
        [int]$Declared,   # Count from declared state (form)
        [int]$Observed    # Count from observed reality (meaning)
    )
}
```

### Return Value

```powershell
@{
    Declared = [int]       # Echoed from parameter
    Observed = [int]       # Echoed from parameter
    Gap = [bool]           # $true if Declared ≠ Observed
    Severity = [string]    # 'error' | 'warning' | 'info'
}
```

### Example: Checking Task Completion

```powershell
# Import the helper
. '.\extensions\specrew-speckit\scripts\shared-governance.ps1'

# Read declared task count from state.md
$statePath = 'C:\Dev\Specrew\specs\028-review-evidence-integrity\state.md'
$state = (Get-Content $statePath -Raw | ConvertFrom-Yaml)
$declaredCount = $state.CompletedTaskCount  # e.g., 11

# Count committed files
$baseline = $state.Baseline  # e.g., 'main'
$observedCount = (git diff --name-only "$baseline...HEAD" | Measure-Object).Count  # e.g., 0

# Check parity
$result = Test-FormMeaningParity -Declared $declaredCount -Observed $observedCount

Write-Host "Declared: $($result.Declared), Observed: $($result.Observed)"
Write-Host "Gap: $($result.Gap), Severity: $($result.Severity)"

# Output:
# Declared: 11, Observed: 0
# Gap: True, Severity: error
```

### Usage in Validator Rules

```powershell
function Test-MyCustomRule {
    param(
        [string]$IterationPath,
        [string]$MetricSource  # e.g., 'sp' for story points, 'tests' for test count
    )
    
    # Read declared metric
    $declared = Get-DeclaredMetric -Path $IterationPath -Type $MetricSource
    
    # Calculate observed metric
    $observed = Get-ObservedMetric -Path $IterationPath -Type $MetricSource
    
    # Use helper to determine severity
    $result = Test-FormMeaningParity -Declared $declared -Observed $observed
    
    if ($result.Severity -eq 'error') {
        return @{
            Category = 'form-vs-meaning'
            Severity = 'error'
            Message = "Form-vs-meaning gap: declared $declared but observed $observed"
            Evidence = $result
        }
    }
}
```

### Severity Interpretation

| Severity | Meaning | Action |
| --- | --- | --- |
| `error` | Hard failure (Declared > 0, Observed = 0) | Block advancement; require remediation |
| `warning` | Partial mismatch (both > 0, but unequal) | Log warning; allow advancement with visibility |
| `info` | No gap (equal or both zero) | No action; safe to proceed |

---

## Component 2: Pre-Review Commit Gate Validator

### Location

```
extensions/specrew-speckit/scripts/validate-governance.ps1
```

### When It Runs

At review boundary advance (implement → review transition), `validate-governance.ps1` invokes the pre-review commit gate rule.

### What It Does

1. Reads `state.md` → extracts CompletedTaskCount
2. Executes `git diff --name-only <baseline>...HEAD` → counts files
3. Invokes `Test-FormMeaningParity -Declared $taskCount -Observed $fileCount`
4. If Severity = 'error' → blocks advancement with remediation hint

### Example Validation Run

```powershell
# Manually invoke validator to test
cd C:\Dev\Specrew
& '.\extensions\specrew-speckit\scripts\validate-governance.ps1' -IterationPath './specs/028-review-evidence-integrity'

# Output (if gap detected):
# [ERROR] Validation Failed (review-evidence-integrity)
# Form-vs-meaning gap: state.md declares 11 completed tasks but git diff baseline...HEAD is empty.
# Remediation: Commit implementation work and re-run validator.
```

### Integration with Specrew Workflow

The validator is automatically invoked at the review boundary. No manual invocation needed for normal workflows; it's part of the governance plane.

---

## Component 3: Scaffolder Warnings

### Location

```
extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1
```

### What It Does

When scaffolding review artifacts (diagrams, code-map, etc.), the script:

1. Checks if form-vs-meaning gap exists (declared > 0, diff empty)
2. If gap detected → emits warning at top of artifact
3. Warning explains the gap and provides context

### Example Warning Message

In `review-diagrams.md`:

```markdown
<!-- Generated: 2025-03-19T14:30:00Z -->
<!-- Baseline: main | Diff: 0 files | Declared Tasks: 11 -->

⚠️ **Review evidence may be misleading**: this iteration's `state.md` declares completed tasks but the git diff against baseline is empty. Implementation work may be uncommitted. See Proposal 073 and the pre-review commit gate.

---

## Structure Diagram

(Structure diagram omitted: modules touched (0) below threshold (3))
```

### Interpreting Warnings

| Warning | Meaning | Next Steps |
| --- | --- | --- |
| "declares completed tasks but diff is empty" | Form-vs-meaning gap detected | Return to implement phase; commit work; re-run scaffolder |
| (no warning) | Git diff has files; evidence is accurate | Proceed with review; diagrams are trustworthy |

---

## Component 4: Idempotent Re-Run with `-Force`

### Location

```
extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 -Force
```

### Usage

#### Interactive (Default)

```powershell
# Prompts user before overwriting
& '.\extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1' `
    -IterationPath './specs/028-review-evidence-integrity' `
    -Force

# Output:
# ⚠️ Re-running with `-Force` will overwrite existing review artifacts.
# Human annotations should be maintained in `review.md` and re-integrated after scaffolding.
# Continue? [Y] Yes [N] No [Y] Yes to All [N] No to All [?] Help (default is "Y"):
```

#### Non-Interactive (CI/CD)

```powershell
# Bypasses prompt; overwrites unconditionally
& '.\extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1' `
    -IterationPath './specs/028-review-evidence-integrity' `
    -Force `
    -Confirm:$false
```

### Idempotency Guarantee

Running the scaffolder multiple times with `-Force` produces identical output (no duplicates, no side effects).

### Preserving Human Annotations

**Key Convention**: Human annotations belong in `review.md`, NOT in generated review artifacts.

**Workflow**:

1. Review artifacts are generated: `review-diagrams.md`, `code-map.md`, etc.
2. Humans add notes directly to `review.md` (separate file)
3. If artifacts need to be regenerated (after late commits):
   - Run scaffolder with `-Force`
   - Artifacts are cleanly overwritten
   - Human annotations in `review.md` are preserved
4. After overwrite, re-integrate annotations from `review.md` into artifacts if needed

**Example**:

```
Directory structure:
  iteration/
  ├── state.md
  ├── review.md                  ← Human annotations here
  ├── review-diagrams.md         ← Generated (can be overwritten)
  ├── code-map.md                ← Generated (can be overwritten)
  └── coverage-evidence.md       ← Generated (can be overwritten)
```

---

## Full Lifecycle Example

### Scenario: Implementation is Late-Committed

**Phase 1: Incomplete Iteration**

```
1. Developer finishes implementation but forgets to commit
2. Reviews "ready for review" checkbox in state.md
3. Runs `validate-governance.ps1` for review boundary advance
4. ❌ Validator BLOCKS advancement: "Form-vs-meaning gap detected"
5. Error message provides remediation: "Commit implementation work"
```

**Phase 2: Remediation**

```
6. Developer commits work: `git add . && git commit -m "Implementation complete"`
7. Re-runs validator: `validate-governance.ps1`
8. ✅ Validator ALLOWS advancement (no gap)
9. Iteration advances to review phase
```

**Phase 3: Review Artifacts (Late Regeneration)**

```
10. Review happens; reviewer wants fresh diagrams after late commit
11. Runs scaffolder with -Force: `scaffold-reviewer-artifacts.ps1 -Force`
12. Scaffolder prompts: "⚠️ Re-running will overwrite artifacts"
13. Reviewer confirms [Y]es
14. Artifacts regenerated with current git diff
15. Review evidence is now accurate (diagrams, code-map, etc.)
```

---

## FAQ & Troubleshooting

### Q: What if I see "git diff is empty" warning?

**A**: You're in the form-vs-meaning gap. Go back to implement phase, commit your work with `git add . && git commit`, then re-run the scaffolder or validator.

### Q: Can I disable the confirmation prompt for automation?

**A**: Yes, use `-Confirm:$false`. Example:

```powershell
scaffold-reviewer-artifacts.ps1 -Force -Confirm:$false
```

### Q: Where should I put reviewer notes?

**A**: In `review.md` (separate from generated artifacts). When artifacts are regenerated with `-Force`, your notes in `review.md` are safe.

### Q: What counts as "committed"?

**A**: Files tracked by git and visible in `git diff baseline...HEAD`. Working-tree changes (not committed) do not count.

### Q: How do I know if the validator is blocking for a legitimate reason?

**A**: Check the remediation hint in the error message. If it says "no files committed since baseline", go commit your work. If it's confusing, check the git history: `git log --oneline baseline...HEAD` and `git diff --stat baseline...HEAD`.

---

## Next Steps

1. **Implementation**: Proceed to `/speckit.tasks` to break plan into work items
2. **Integration**: Add pre-review commit gate rule to `validate-governance.ps1`
3. **Testing**: Implement integration test suite in `tests/integration/review-evidence-integrity.tests.ps1`
4. **Documentation**: Update `docs/user-guide.md` with validator failure troubleshooting

---

## Related Artifacts

- **Data Model**: `specs/028-review-evidence-integrity/data-model.md`
- **Contracts**: `specs/028-review-evidence-integrity/contracts/`
- **Specification**: `specs/028-review-evidence-integrity/spec.md`
- **Proposal 073**: `proposals/073-review-evidence-integrity.md`
- **Proposal 030**: `proposals/030-quality-hardening-bundle.md`
