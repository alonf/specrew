# Quickstart Guide: Legacy-State Read-Tolerance Implementation

**Feature Branch**: `023-legacy-state-read-tolerance`  
**Target Audience**: Specrew developers implementing schema versioning and reader tolerance  
**Estimated Reading Time**: 10 minutes

---

## Overview

This guide helps you implement schema versioning and reader tolerance for Specrew state files. By following these patterns, you'll:

✅ Prevent crashes from missing optional fields under StrictMode  
✅ Enable safe version upgrades without manual migration  
✅ Ensure backward compatibility with v0 (legacy) state files  
✅ Pass legacy fixture regression tests on Windows and Linux

---

## Quick Reference

### When Writing State Files

```powershell
# JSON
$state = @{
    schema = 'v1'  # Always add this field
    session_state = @{ ... }
    feature_path = '/path/to/feature'
}
$state | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $path -Encoding UTF8

# YAML (manual construction)
$yamlContent = @"
schema: v1
team_id: $teamId
"@
$yamlContent | Set-Content -LiteralPath $path -Encoding UTF8
```

### When Reading State Files

```powershell
# JSON - Use -AsHashtable for StrictMode compatibility
$state = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | 
         ConvertFrom-Json -AsHashtable -Depth 12

# Access optional fields safely (hashtable indexer, not property access)
$sessionState = $state['session_state']  # Returns $null if missing, no throw
if ($sessionState) {
    # Use session state
}
```

---

## Implementation Checklist

### For Iteration 1 (Writers + Readers)

**Step 1: Audit Your Script**

- [ ] Identify if your script reads or writes state files in `.specrew/`, `.specify/`, `.squad/` directories
- [ ] Check if you use `ConvertFrom-Json` (reader) or `ConvertTo-Json` (writer)
- [ ] Verify if your script has `Set-StrictMode -Version Latest` (should be line 1)

**Step 2: Migrate Readers to Hashtables**

```powershell
# BEFORE (PSCustomObject - throws under StrictMode)
$state = Get-Content $path -Raw | ConvertFrom-Json
$value = $state.optional_field  # ❌ Throws if field missing

# AFTER (Hashtable - safe under StrictMode)
$state = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | 
         ConvertFrom-Json -AsHashtable -Depth 12
$value = $state['optional_field']  # ✅ Returns $null if missing
```

**Step 3: Add Schema Markers to Writers**

```powershell
# BEFORE
$state = @{
    feature_path = '/path/to/feature'
}

# AFTER
$state = @{
    schema = 'v1'  # ✅ Add this field
    feature_path = '/path/to/feature'
}
```

**Step 4: Handle Schema Version Dispatch (if needed)**

```powershell
$schema = $state['schema']
if (-not $schema) {
    # Legacy v0 file
    Write-Debug "schema-implied-v0 for $path"
    # Apply v0-compatible logic
}
else {
    # Explicit v1+ schema
    # Apply version-specific logic
}
```

**Step 5: Test Against Legacy Fixtures**

```powershell
# Run Pester tests
Invoke-Pester -Path tests/integration/Test-LegacyStateReaders.Tests.ps1
```

---

## Common Patterns

### Pattern 1: Reading Optional Fields Safely

```powershell
# Safe default for missing string field
$featurePath = $state['feature_path']
if (-not $featurePath) {
    $featurePath = ''  # Or compute default
}

# Safe default for missing object field
$sessionState = $state['session_state']
if (-not $sessionState) {
    $sessionState = @{}  # Empty hashtable
}

# Safe default for missing array field
$tasks = $state['tasks']
if (-not $tasks) {
    $tasks = @()  # Empty array
}
```

### Pattern 2: Checking for Field Existence

```powershell
# Use ContainsKey for explicit checks
if ($state.ContainsKey('optional_field')) {
    $value = $state['optional_field']
}
else {
    # Field not present
}
```

### Pattern 3: Writing YAML State Files (Manual Parsing)

```powershell
# Current Specrew pattern: manual line-by-line construction
$yamlLines = @(
    'schema: v1'
    "team_id: $teamId"
    "capacity_unit: $capacityUnit"
)
$yamlContent = $yamlLines -join "`n"
$yamlContent | Set-Content -LiteralPath $path -Encoding UTF8
```

### Pattern 4: Extension Manifest (Separate Schema Field)

```yaml
extension:
  id: specrew-speckit
  version: "0.22.0"  # Extension content version
  schema: "v1"       # Schema version (separate field per FR-003)
```

---

## High-Priority Reader Migrations (Iteration 1)

| Script | File | Current Issue | Fix |
|--------|------|---------------|-----|
| `scripts/specrew-start.ps1:375` | `.specify/feature.json` | PSCustomObject access | Add `-AsHashtable` |
| `scripts/internal/worktree-awareness.ps1:57-75` | `.specify/feature.json` | PSCustomObject access | Add `-AsHashtable` |
| `.specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1:106-121` | `.specify/feature.json` | PSCustomObject access, throws on missing field | Add `-AsHashtable` + null check |
| `scripts/internal/version-check.ps1:113-143` | `.specrew/version-check-cache.json` | PSCustomObject access | Add `-AsHashtable` |
| `scripts/internal/coordinator-resume.ps1:28-56` | `.specrew/last-validator-summary.json` | PSCustomObject access in try/catch | Add `-AsHashtable` |

---

## Legacy Fixture Test Structure

### Directory Layout

```
tests/fixtures/legacy-versions/
├── 0.18.0/
│   ├── .specrew/
│   │   ├── config.yml
│   │   └── start-context.json
│   ├── .specify/
│   │   └── feature.json
│   └── .squad/
│       └── identity/now.md
├── 0.19.0/  # Motivating crash repro
├── 0.20.0/
├── 0.21.0/
└── 0.22.0/
```

### Pester Test Template

```powershell
Describe "Legacy State Reader Tolerance" {
    Context "Version 0.19.0 fixtures" {
        It "Reads start-context.json without throwing" {
            $path = "tests/fixtures/legacy-versions/0.19.0/.specrew/start-context.json"
            { Get-SpecrewStartContextSessionState -Path $path } | Should -Not -Throw
        }
        
        It "Returns safe defaults for missing fields" {
            $path = "tests/fixtures/legacy-versions/0.19.0/.specrew/start-context.json"
            $state = Get-SpecrewStartContextSessionState -Path $path
            $state | Should -Not -BeNull
            # session_state field missing in 0.19.0 → should return $null, not throw
            $state['session_state'] | Should -BeNullOrEmpty
        }
    }
}
```

---

## Validator Rule (Iteration 2)

### Rule Implementation (gap #11)

Add to `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`:

```powershell
function Test-ReaderTolerance {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.List[string]]$Errors
    )
    
    # Find all PowerShell scripts
    $scripts = Get-ChildItem -Path $ProjectRoot -Filter *.ps1 -Recurse
    
    foreach ($script in $scripts) {
        $content = Get-Content -LiteralPath $script.FullName -Raw
        
        # Check if script uses ConvertFrom-Json
        if ($content -match 'ConvertFrom-Json') {
            # Check if function reads state files
            $isStateReader = (
                $content -match '\.specrew[\\/]' -or
                $content -match '\.specify[\\/]' -or
                $content -match '\.squad[\\/]' -or
                $content -match 'Get-Specrew\w+State'
            )
            
            if ($isStateReader) {
                # Check for -AsHashtable parameter
                if ($content -notmatch 'ConvertFrom-Json\s+.*-AsHashtable') {
                    Add-RepoStructuredValidationFailure `
                        -Errors $Errors `
                        -ProjectRoot $ProjectRoot `
                        -TargetPath $script.FullName `
                        -Category "reader-tolerance" `
                        -Message "State reader uses ConvertFrom-Json without -AsHashtable" `
                        -RemediationHint "State readers must use hashtables to tolerate missing fields under StrictMode. Add -AsHashtable parameter."
                }
            }
        }
    }
}
```

---

## Troubleshooting

### Issue: PropertyNotFoundException under StrictMode

**Symptom**: Script throws `PropertyNotFoundException` when accessing optional fields

**Cause**: Using PSCustomObject property access (e.g., `$state.field`) instead of hashtable indexer

**Fix**:

```powershell
# Change this:
$value = $state.field

# To this:
$value = $state['field']
```

### Issue: Validator Rule False Positives

**Symptom**: Validator flags scripts that don't actually read state files

**Cause**: Overly broad pattern matching (e.g., any script using `ConvertFrom-Json`)

**Fix**: Refine rule scope to only flag functions reading from `.specrew/`, `.specify/`, `.squad/` paths or matching `Get-Specrew*State` name pattern

### Issue: Legacy Fixture Test Failures on Linux

**Symptom**: Tests pass on Windows but fail on Linux with line-ending or path issues

**Cause**: Line-ending differences (CRLF vs LF), case-sensitive paths

**Fix**:

- Ensure Git `core.autocrlf` is configured correctly
- Use `Test-Path -LiteralPath` and `-LiteralPath` parameter consistently
- Normalize paths with `Join-Path` or `[System.IO.Path]::Combine()`

---

## Cross-Platform Considerations

### Line Endings

- **Git normalization**: Use `core.autocrlf=true` on Windows, `core.autocrlf=input` on Linux/macOS
- **Fixture files**: Committed with LF endings; Git converts to platform-native on checkout
- **State file writes**: PowerShell `Set-Content` uses platform-native line endings

### Path Separators

```powershell
# ✅ Cross-platform safe
$path = Join-Path -Path $projectRoot -ChildPath '.specrew' -AdditionalChildPath 'config.yml'

# ❌ Windows-only
$path = "$projectRoot\.specrew\config.yml"
```

### Case Sensitivity

```powershell
# ✅ Case-insensitive key access (hashtables are case-insensitive by default)
$value = $state['FeaturePath']  # Works on both platforms

# ✅ Explicit case-insensitive hashtable
$state = [System.Collections.Hashtable]@{}  # Case-insensitive by default
```

---

## Success Criteria Validation

### SC-001: Zero Crashes from Legacy State Files

**Validation**: Run `specrew start` against projects initialized at versions 0.18.0-0.22.0; no exceptions thrown

### SC-002: 100% Pass Rate for Legacy Fixture Tests

**Validation**: `Invoke-Pester -Path tests/integration/Test-LegacyStateReaders.Tests.ps1` → all tests pass

### SC-003: Schema Markers in New State Files

**Validation**: Create new project with `specrew init` → all state files contain `schema: v1`

### SC-004: Validator Rule Effectiveness

**Validation**: Manual audit of PSCustomObject-based parsers → validator detects 100%

### SC-006: Cross-Platform CI Evidence

**Validation**: GitHub Actions runs tests on ubuntu-latest; check CI logs for pass/fail

---

## Next Steps

1. Complete Iteration 1 reader/writer migrations
2. Hand-curate legacy fixtures (0.18.0-0.22.0) from real projects
3. Write Pester tests for each reader function against each fixture
4. Add Linux test lane to `.github/workflows/specrew-ci.yml`
5. Validate cross-platform CI runs (Windows + Linux)
6. Proceed to Iteration 2: validator rule (gap #11), docs, closeout template

---

## Resources

- **Spec**: `file:///C:/Dev/Specrew-023/specs/023-legacy-state-read-tolerance/spec.md`
- **Research**: `file:///C:/Dev/Specrew-023/specs/023-legacy-state-read-tolerance/research.md`
- **Data Model**: `file:///C:/Dev/Specrew-023/specs/023-legacy-state-read-tolerance/data-model.md`
- **Schema Contract**: `file:///C:/Dev/Specrew-023/specs/023-legacy-state-read-tolerance/contracts/state-file-schema-v1.md`
- **Proposal 059**: `file:///C:/Dev/Specrew/proposals/059-legacy-state-read-tolerance.md`

---

**Questions or Issues?** Escalate to human Spec Steward for schema design decisions or fixture content validation.
