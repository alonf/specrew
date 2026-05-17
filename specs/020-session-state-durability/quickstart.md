# Quickstart: Session-State Durability Implementation

**Feature**: 020-session-state-durability  
**Audience**: Implementers working on Iteration 1 (boundary sync + stale detection + version checks)  
**Purpose**: Provide step-by-step guide for implementing core session-state tracking mechanisms

---

## Prerequisites

- Completed Companion Chore (`.squad/identity/now.md` closeout pattern established)
- Pester 5.x installed for testing
- PowerShell 5.1+ or PowerShell Core 7+ environment
- Git 2.25+ available on PATH
- Reviewed `data-model.md` and `contracts/` for entity/API understanding

---

## Phase 1: Boundary-Event Sync Helper (Workstream 1.1)

### Step 1: Create Sync Helper Script Skeleton

**File**: `scripts/internal/sync-boundary-state.ps1`

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('specify', 'clarify', 'plan', 'tasks', 'review-signoff', 'iteration-closeout', 'feature-closeout')]
    [string]$BoundaryType,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{3}$')]
    [string]$FeatureNumber,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 99)]
    [int]$IterationNumber,

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^T\d{3}$')]
    [string]$TaskId,

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[0-9a-f]{7,40}$')]
    [string]$AuthCommitHash
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# TODO: Implement Write-FileAtomically helper
# TODO: Implement session-state file update logic
# TODO: Implement error handling and exit codes

Write-Verbose "Sync boundary state: boundary=$BoundaryType, feature=$FeatureNumber"
exit 0
```

**Checkpoint**: Script exists and runs without errors (no-op implementation).

### Step 2: Implement Write-FileAtomically Helper

Add to `sync-boundary-state.ps1`:

```powershell
function Write-FileAtomically {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $directory = Split-Path -Path $Path -Parent
    $filename = Split-Path -Path $Path -Leaf
    $tempPath = Join-Path -Path $directory -ChildPath "$filename.tmp"

    try {
        # Write to temp file
        Set-Content -Path $tempPath -Value $Content -NoNewline -ErrorAction Stop

        # Atomic rename
        Move-Item -Path $tempPath -Destination $Path -Force -ErrorAction Stop

        Write-Verbose "Updated: $Path"
        return $true
    }
    catch {
        Write-Error "Failed to update $Path: $_"
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -ErrorAction SilentlyContinue
        }
        return $false
    }
}
```

**Checkpoint**: Unit test `Write-FileAtomically` with success case, disk-full simulation, permission-denied simulation.

### Step 3: Implement Session-State File Updates

Add content generation functions:

```powershell
function Get-StartContextJson {
    param($BoundaryType, $FeatureNumber, $IterationNumber, $TaskId, $AuthCommitHash)
    
    $obj = @{
        active_feature = $FeatureNumber
        current_boundary = $BoundaryType
        recorded_at = (Get-Date).ToUniversalTime().ToString('o')
    }
    
    if ($IterationNumber) { $obj.iteration_number = $IterationNumber }
    if ($TaskId) { $obj.task_id = $TaskId }
    if ($AuthCommitHash) { $obj.last_completed_commit_hash = $AuthCommitHash }
    
    return ($obj | ConvertTo-Json -Depth 10)
}

function Get-LastStartPromptMd {
    param($BoundaryType, $FeatureNumber, $IterationNumber)
    
    $timestamp = (Get-Date).ToUniversalTime().ToString('o')
    $featureName = "TBD"  # TODO: Read from spec.md or feature.json
    
    return @"
---
active_feature: "$FeatureNumber"
current_boundary: "$BoundaryType"
recorded_at: "$timestamp"
---

# Welcome Back: Feature $FeatureNumber - $featureName

**Current State**: Boundary $BoundaryType completed

**Next Actions**:
- Run ``specrew where`` to see current context
- Proceed to next boundary per governance workflow
"@
}

function Get-SquadNowMd {
    param($BoundaryType, $FeatureNumber, $IterationNumber)
    
    $timestamp = (Get-Date).ToUniversalTime().ToString('o')
    
    return @"
# Squad Current Focus

**Active Feature**: $FeatureNumber  
**Current Boundary**: $BoundaryType  
**Last Updated**: $timestamp

Focus on next boundary per governance workflow.
"@
}

function Append-DecisionsMd {
    param($Path, $BoundaryType, $FeatureNumber, $IterationNumber, $AuthCommitHash)
    
    $timestamp = (Get-Date).ToUniversalTime().ToString('o')
    $entry = @"

## [$timestamp] Boundary: $BoundaryType (Feature $FeatureNumber)

**Decision**: $BoundaryType boundary crossed.

**Context**: Iteration $IterationNumber (if applicable).

**Authorization Commit**: ``$AuthCommitHash``

**Next Boundary**: TBD

"@
    
    Add-Content -Path $Path -Value $entry
}
```

**Main Logic**:

```powershell
# Derive file paths
$startContextPath = Join-Path $PSScriptRoot "../../.specrew/start-context.json"
$lastStartPromptPath = Join-Path $PSScriptRoot "../../.specrew/last-start-prompt.md"
$squadNowPath = Join-Path $PSScriptRoot "../../.squad/identity/now.md"
$decisionsPath = Join-Path $PSScriptRoot "../../.squad/decisions.md"

# Generate content
$startContextJson = Get-StartContextJson -BoundaryType $BoundaryType -FeatureNumber $FeatureNumber -IterationNumber $IterationNumber -TaskId $TaskId -AuthCommitHash $AuthCommitHash
$lastStartPromptMd = Get-LastStartPromptMd -BoundaryType $BoundaryType -FeatureNumber $FeatureNumber -IterationNumber $IterationNumber
$squadNowMd = Get-SquadNowMd -BoundaryType $BoundaryType -FeatureNumber $FeatureNumber -IterationNumber $IterationNumber

# Update files atomically
$success = $true
$success = $success -and (Write-FileAtomically -Path $startContextPath -Content $startContextJson)
$success = $success -and (Write-FileAtomically -Path $lastStartPromptPath -Content $lastStartPromptMd)
$success = $success -and (Write-FileAtomically -Path $squadNowPath -Content $squadNowMd)

# Append to decisions.md
Append-DecisionsMd -Path $decisionsPath -BoundaryType $BoundaryType -FeatureNumber $FeatureNumber -IterationNumber $IterationNumber -AuthCommitHash $AuthCommitHash

if ($success) {
    Write-Host "Session-state synchronized: boundary=$BoundaryType, feature=$FeatureNumber"
    exit 0
} else {
    Write-Error "Session-state sync failed. Files may be inconsistent."
    exit 1
}
```

**Checkpoint**: Script updates all four files. Manual test: invoke with sample parameters, verify files updated correctly.

---

## Phase 2: Stale-State Detection (Workstream 1.2)

### Step 1: Implement Merge-Detection Check

**File**: `scripts/specrew-start.ps1` (modify existing)

Add function:

```powershell
function Test-FeatureMergedToMain {
    param(
        [string]$FeatureNumber,
        [string]$BootstrapDate
    )
    
    if (-not $BootstrapDate) {
        $BootstrapDate = (Get-Date).AddDays(-90).ToString('yyyy-MM-dd')
        Write-Warning "bootstrap_date missing; using 90-day fallback: $BootstrapDate"
    }
    
    $grepPattern = $FeatureNumber
    $result = git log main --since="$BootstrapDate" --merges --grep="$grepPattern" --oneline
    
    if ($result) {
        return @{
            IsMerged = $true
            MergeCommit = $result[0]
        }
    }
    
    return @{ IsMerged = $false }
}
```

**Checkpoint**: Unit test with mocked git log output. Test cases: feature merged yesterday, feature merged 6 months ago, feature never merged, bootstrap_date missing.

### Step 2: Implement Branch-Existence Check

Add function:

```powershell
function Test-FeatureBranchExists {
    param([string]$BranchName)
    
    $null = git rev-parse --verify $BranchName 2>&1
    return $LASTEXITCODE -eq 0
}
```

**Checkpoint**: Unit test with mocked git rev-parse.

### Step 3: Implement Authorization-Record Check

Add function:

```powershell
function Test-AuthorizationRecordExists {
    param(
        [string]$FeatureNumber,
        [string]$DecisionsPath
    )
    
    if (-not (Test-Path $DecisionsPath)) { return $false }
    
    $content = Get-Content $DecisionsPath -Raw
    return $content -match "Feature $FeatureNumber"
}
```

**Checkpoint**: Unit test with sample decisions.md content.

### Step 4: Implement Cross-File Consistency Check

Add function:

```powershell
function Test-SessionStateConsistency {
    $startContext = Get-Content '.specrew/start-context.json' | ConvertFrom-Json
    $lastStartPrompt = Get-Content '.specrew/last-start-prompt.md' -Raw
    $squadNow = Get-Content '.squad/identity/now.md' -Raw
    
    # Extract feature number from each file
    $feature1 = $startContext.active_feature
    $feature2 = if ($lastStartPrompt -match 'active_feature: "(\d{3})"') { $matches[1] } else { $null }
    $feature3 = if ($squadNow -match 'Feature (\d{3})') { $matches[1] } else { $null }
    
    if ($feature1 -ne $feature2 -or $feature2 -ne $feature3) {
        return @{
            IsConsistent = $false
            Mismatch = "Features: $feature1, $feature2, $feature3"
        }
    }
    
    return @{ IsConsistent = $true }
}
```

**Checkpoint**: Integration test with consistent files, inconsistent files.

### Step 5: Implement Stale-State User Prompt

Add to `specrew-start.ps1` startup logic:

```powershell
# Read session-state
$startContext = Get-Content '.specrew/start-context.json' | ConvertFrom-Json
$activeFeature = $startContext.active_feature
$bootstrapDate = (Get-Content '.specrew/config.yml' | ConvertFrom-Yaml).bootstrap_date

# Run stale-state checks
$mergeCheck = Test-FeatureMergedToMain -FeatureNumber $activeFeature -BootstrapDate $bootstrapDate
$branchCheck = Test-FeatureBranchExists -BranchName "$activeFeature-*"
$authCheck = Test-AuthorizationRecordExists -FeatureNumber $activeFeature -DecisionsPath '.squad/decisions.md'
$consistencyCheck = Test-SessionStateConsistency

# Detect staleness
$isStale = $mergeCheck.IsMerged -or (-not $branchCheck) -or (-not $authCheck) -or (-not $consistencyCheck.IsConsistent)

if ($isStale) {
    Write-Host "STALE STATE DETECTED:" -ForegroundColor Red
    
    if ($mergeCheck.IsMerged) {
        Write-Host "  - Feature $activeFeature was merged to main: $($mergeCheck.MergeCommit)"
    }
    if (-not $branchCheck) {
        Write-Host "  - Feature branch for $activeFeature does not exist"
    }
    if (-not $authCheck) {
        Write-Host "  - No authorization record found for Feature $activeFeature"
    }
    if (-not $consistencyCheck.IsConsistent) {
        Write-Host "  - Session-state files inconsistent: $($consistencyCheck.Mismatch)"
    }
    
    Write-Host "`nOptions:" -ForegroundColor Yellow
    Write-Host "  (A) Re-anchor to correct feature"
    Write-Host "  (B) Create new feature"
    Write-Host "  (C) Exit and manually fix state"
    
    $choice = Read-Host "Select option (A/B/C)"
    
    # TODO: Implement re-anchor, create-new-feature, exit logic
}
```

**Checkpoint**: Integration test with various staleness scenarios. Verify prompt appears and options are actionable.

---

## Phase 3: Module Version Check (Workstream 1.3)

### Step 1: Implement Module-vs-Project Version Comparison

Add to `specrew-start.ps1`:

```powershell
function Test-ModuleVersionMismatch {
    $installedVersion = (Get-Module Specrew).Version.ToString()
    $configPath = '.specrew/config.yml'
    $projectVersion = (Get-Content $configPath | ConvertFrom-Yaml).specrew_version
    
    if ($installedVersion -ne $projectVersion) {
        return @{
            HasMismatch = $true
            Installed = $installedVersion
            Project = $projectVersion
        }
    }
    
    return @{ HasMismatch = $false }
}

# In specrew-start.ps1 startup logic
$versionCheck = Test-ModuleVersionMismatch
if ($versionCheck.HasMismatch) {
    Write-Warning "Module version mismatch detected: installed $($versionCheck.Installed), project expects $($versionCheck.Project). To update: specrew update"
}
```

**Checkpoint**: Integration test with matching versions (no warning), mismatched versions (warning appears), CI environment (warning doesn't block startup).

---

## Testing Checklist

### Unit Tests

- [ ] `Write-FileAtomically` success case
- [ ] `Write-FileAtomically` disk-full simulation
- [ ] `Write-FileAtomically` permission-denied simulation
- [ ] `Test-FeatureMergedToMain` with various git-log outputs
- [ ] `Test-FeatureBranchExists` with existing/missing branches
- [ ] `Test-AuthorizationRecordExists` with present/absent records
- [ ] `Test-SessionStateConsistency` with consistent/inconsistent files
- [ ] `Test-ModuleVersionMismatch` with matching/mismatched versions

### Integration Tests

- [ ] Boundary-event sync for all seven boundary types
- [ ] Cross-file consistency after boundary-event sync
- [ ] Stale-state detection with feature merged yesterday
- [ ] Stale-state detection with branch missing
- [ ] Stale-state detection with auth record missing
- [ ] Stale-state detection with cross-file inconsistency
- [ ] Module version check in CI environment
- [ ] Cross-platform validation (Windows, Linux, macOS)

---

## Common Issues & Troubleshooting

### Issue 1: Write-temp-then-rename fails on Docker bind mount

**Symptom**: `Move-Item` fails with "cross-device link" error  
**Cause**: Docker bind mounts on some filesystems don't support atomic rename across devices  
**Workaround**: Add fallback to direct write (document in implementation notes for future iteration)

### Issue 2: Git log bounded search misses merge commit

**Symptom**: Feature merged but stale-state detection doesn't catch it  
**Cause**: Merge commit message doesn't include feature number  
**Mitigation**: Branch-existence check compensates (if feature merged, branch typically deleted, so branch-missing signal triggers staleness)

### Issue 3: PSGallery version check slow in CI

**Symptom**: `specrew start` takes >10s in CI due to PSGallery query  
**Cause**: Network latency or PSGallery API throttling  
**Solution**: Set `SPECREW_SKIP_UPDATE_CHECK=1` in CI environment variables (deferred to Iteration 2 Workstream 2.4)

---

## Next Steps After Iteration 1

- **Iteration 2**: Add task progress tracking, cross-worktree awareness, recovery prompts, PSGallery check
- **Hardening Gate**: Run hardening gate per Phase 2 plan (focus on atomicity failure modes, stale-state false negatives)
- **Manual Test Scenarios**: Validate US1, US2, US4 acceptance criteria via manual reboot/boundary-crossing scenarios

**Estimated Time**: Iteration 1 implementation = 2-3 weeks (16 SP)
