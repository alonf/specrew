# T019: Regression test for duplicate-row deploy bug (FR-013)
# Trace: commit 2d52b9f9, FR-013, Bug 1
#
# This test verifies that `specrew update` does NOT duplicate Squad role entries
# in .squad/team.md and .squad/routing.md when executed multiple times on the
# same project. The fix in deploy-squad-runtime.ps1 (commit 2d52b9f9) implements
# a key-based merge strategy instead of naive append.
#
# Expected behavior:
# - First `specrew update` deploys baseline Squad roles
# - Subsequent `specrew update` calls preserve existing entries without duplication
# - Table rows are keyed by the first column (role name or work type)

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message, [string]$Detail = '')
    Write-Host "FAIL: $Message" -ForegroundColor Red
    if ($Detail) {
        Write-Host "      $Detail" -ForegroundColor Yellow
    }
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Get-TableRowKeys {
    param(
        [string]$FilePath,
        [string]$SectionHeader
    )
    
    if (-not (Test-Path -LiteralPath $FilePath)) {
        return @()
    }
    
    $content = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8
    $escapedHeader = [regex]::Escape($SectionHeader)
    
    # Match table section: header, then table header row, separator, then body rows
    $tablePattern = "$escapedHeader[^\r\n]*\r?\n(?:.*?\r?\n)*?\|[^\r\n]+\|\r?\n\|[\s\-|]+\|\r?\n"
    
    if ($content -notmatch $tablePattern) {
        return @()
    }
    
    $match = $Matches[0]
    $index = $content.IndexOf($match)
    if ($index -lt 0) { return @() }
    
    $postTableContent = $content.Substring($index + $match.Length)
    $lines = $postTableContent -split '\r?\n'
    
    $keys = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $lines) {
        if ($line -match '^\s*\|') {
            $parts = $line -split '\|'
            if ($parts.Count -gt 1) {
                $key = $parts[1].Trim()
                if (-not [string]::IsNullOrWhiteSpace($key)) {
                    $null = $keys.Add($key)
                }
            }
        }
        else {
            break
        }
    }
    
    return $keys.ToArray()
}

# -----------------------------------------------------------------------------
# Test Setup
# -----------------------------------------------------------------------------

Write-Section "Test Setup: Create Temporary Project"

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\')).Path
$testsPath = Join-Path -Path $repoRoot -ChildPath 'tests'
$testProjectPath = Join-Path -Path $testsPath -ChildPath ".test-dup-$(Get-Random)"

try {
    # Create clean test project
    New-Item -ItemType Directory -Path $testProjectPath -Force | Out-Null
    Write-Host "Created test project at: $testProjectPath"
    
    # Initialize git repo (required by specrew init)
    Push-Location $testProjectPath
    try {
        git init 2>&1 | Out-Null
        git config user.email "test@example.com" 2>&1 | Out-Null
        git config user.name "Test User" 2>&1 | Out-Null
        Write-Pass "Initialized git repository"
        
        # Import Specrew module
        $modulePath = Join-Path -Path $repoRoot -ChildPath 'Specrew.psm1'
        Import-Module $modulePath -Force -Global
        Write-Pass "Loaded Specrew module"
        
        # -----------------------------------------------------------------------------
        # Test Phase 1: Initial specrew init
        # -----------------------------------------------------------------------------
        
        Write-Section "Phase 1: Initial specrew init"
        
        try {
            Initialize-Specrew --force 2>&1 | Out-Null
            Write-Pass "specrew init succeeded"
        } catch {
            Write-Fail "specrew init failed" $_.Exception.Message
            exit 1
        }
        
        # Verify baseline Specrew config was created
        $configPath = Join-Path -Path $testProjectPath -ChildPath '.specrew\config.yml'
        if (-not (Test-Path -LiteralPath $configPath)) {
            Write-Fail ".specrew/config.yml not created by init"
            exit 1
        }
        Write-Pass "Specrew config created"
        
        # Squad files may not exist initially - that's ok, they'll be created by specrew update
        # Skip Squad file checks in Phase 1 and focus on specrew update behavior
        
        # Commit initial state
        git add -A 2>&1 | Out-Null
        git commit -m "Initial specrew init" 2>&1 | Out-Null
        Write-Pass "Committed baseline state"
        
        # -----------------------------------------------------------------------------
        # Test Phase 2: First specrew update (creates Squad baseline)
        # -----------------------------------------------------------------------------
        
        Write-Section "Phase 2: First specrew update (creates Squad baseline)"
        
        try {
            Update-Specrew --force 2>&1 | Out-Null
            Write-Pass "First specrew update succeeded"
        } catch {
            Write-Fail "First specrew update failed" $_.Exception.Message
            exit 1
        }
        
        # NOW verify Squad files were created
        $teamPath = Join-Path -Path $testProjectPath -ChildPath '.squad\team.md'
        $routingPath = Join-Path -Path $testProjectPath -ChildPath '.squad\routing.md'
        
        if (-not (Test-Path -LiteralPath $teamPath)) {
            Write-Fail ".squad/team.md not created by first update"
            exit 1
        }
        if (-not (Test-Path -LiteralPath $routingPath)) {
            Write-Fail ".squad/routing.md not created by first update"
            exit 1
        }
        Write-Pass "Squad files created by first update"
        
        # Get baseline row keys after first update
        $baselineTeamKeys = Get-TableRowKeys -FilePath $teamPath -SectionHeader '## Specrew Baseline Roles'
        $baselineRoutingKeys = Get-TableRowKeys -FilePath $routingPath -SectionHeader '## Routing Table'
        
        Write-Host "After first update - team.md roles: $($baselineTeamKeys.Count)" -ForegroundColor Cyan
        Write-Host "After first update - routing.md routes: $($baselineRoutingKeys.Count)" -ForegroundColor Cyan
        
        if ($baselineTeamKeys.Count -eq 0) {
            Write-Fail "No baseline team roles found in team.md after first update"
            exit 1
        }
        if ($baselineRoutingKeys.Count -eq 0) {
            Write-Fail "No baseline routing entries found in routing.md after first update"
            exit 1
        }
        Write-Pass "Baseline Squad roles populated"
        
        # Commit state after first update
        git add -A 2>&1 | Out-Null
        git commit -m "First specrew update" 2>&1 | Out-Null
        Write-Pass "Committed state after first update"
        
        # -----------------------------------------------------------------------------
        # Test Phase 3: Second specrew update (redundant - critical regression test)
        # -----------------------------------------------------------------------------
        
        Write-Section "Phase 3: Second specrew update (redundant - Bug 1 test)"
        
        try {
            Update-Specrew --force 2>&1 | Out-Null
            Write-Pass "Second specrew update succeeded"
        } catch {
            Write-Fail "Second specrew update failed" $_.Exception.Message
            exit 1
        }
        
        # Get keys after second update
        $secondUpdateTeamKeys = Get-TableRowKeys -FilePath $teamPath -SectionHeader '## Specrew Baseline Roles'
        $secondUpdateRoutingKeys = Get-TableRowKeys -FilePath $routingPath -SectionHeader '## Routing Table'
        
        Write-Host "After second update - team.md roles: $($secondUpdateTeamKeys.Count)" -ForegroundColor Cyan
        Write-Host "After second update - routing.md routes: $($secondUpdateRoutingKeys.Count)" -ForegroundColor Cyan
        
        # Check for duplicates (the critical bug case - redundant update)
        $teamDuplicates2 = @($secondUpdateTeamKeys | Group-Object | Where-Object { $_.Count -gt 1 })
        $routingDuplicates2 = @($secondUpdateRoutingKeys | Group-Object | Where-Object { $_.Count -gt 1 })
        
        if ($teamDuplicates2.Count -gt 0) {
            Write-Fail "Duplicate team entries detected after SECOND update (FR-013 regression - CRITICAL):"
            foreach ($dup in $teamDuplicates2) {
                Write-Host "  ❌ '$($dup.Name)' appears $($dup.Count) times" -ForegroundColor Red
            }
            Write-Host ""
            Write-Host "This is the EXACT bug scenario commit 2d52b9f9 was meant to fix!" -ForegroundColor Yellow
            exit 1
        }
        Write-Pass "No duplicate team entries after second update (FR-013 fix verified)"
        
        if ($routingDuplicates2.Count -gt 0) {
            Write-Fail "Duplicate routing entries detected after SECOND update (FR-013 regression - CRITICAL):"
            foreach ($dup in $routingDuplicates2) {
                Write-Host "  ❌ '$($dup.Name)' appears $($dup.Count) times" -ForegroundColor Red
            }
            Write-Host ""
            Write-Host "This is the EXACT bug scenario commit 2d52b9f9 was meant to fix!" -ForegroundColor Yellow
            exit 1
        }
        Write-Pass "No duplicate routing entries after second update (FR-013 fix verified)"
        
        # Verify counts STILL match baseline
        if ($secondUpdateTeamKeys.Count -ne $baselineTeamKeys.Count) {
            Write-Fail "Team role count changed after second update" "Expected $($baselineTeamKeys.Count), got $($secondUpdateTeamKeys.Count)"
            exit 1
        }
        if ($secondUpdateRoutingKeys.Count -ne $baselineRoutingKeys.Count) {
            Write-Fail "Routing entry count changed after second update" "Expected $($baselineRoutingKeys.Count), got $($secondUpdateRoutingKeys.Count)"
            exit 1
        }
        Write-Pass "Row counts preserved after second update"
        
        # -----------------------------------------------------------------------------
        # Test Phase 4: Third specrew update (belt-and-suspenders)
        # -----------------------------------------------------------------------------
        
        Write-Section "Phase 4: Third specrew update (belt-and-suspenders)"
        
        try {
            Update-Specrew --force 2>&1 | Out-Null
            Write-Pass "Third specrew update succeeded"
        } catch {
            Write-Fail "Third specrew update failed" $_.Exception.Message
            exit 1
        }
        
        # Get keys after third update
        $thirdUpdateTeamKeys = Get-TableRowKeys -FilePath $teamPath -SectionHeader '## Specrew Baseline Roles'
        $thirdUpdateRoutingKeys = Get-TableRowKeys -FilePath $routingPath -SectionHeader '## Routing Table'
        
        Write-Host "After third update - team.md roles: $($thirdUpdateTeamKeys.Count)" -ForegroundColor Cyan
        Write-Host "After third update - routing.md routes: $($thirdUpdateRoutingKeys.Count)" -ForegroundColor Cyan
        
        # Final duplicate check
        $teamDuplicates3 = @($thirdUpdateTeamKeys | Group-Object | Where-Object { $_.Count -gt 1 })
        $routingDuplicates3 = @($thirdUpdateRoutingKeys | Group-Object | Where-Object { $_.Count -gt 1 })
        
        if ($teamDuplicates3.Count -gt 0) {
            Write-Fail "Duplicate team entries detected after THIRD update:"
            foreach ($dup in $teamDuplicates3) {
                Write-Host "  ❌ '$($dup.Name)' appears $($dup.Count) times" -ForegroundColor Red
            }
            exit 1
        }
        Write-Pass "No duplicate team entries after third update"
        
        if ($routingDuplicates3.Count -gt 0) {
            Write-Fail "Duplicate routing entries detected after THIRD update:"
            foreach ($dup in $routingDuplicates3) {
                Write-Host "  ❌ '$($dup.Name)' appears $($dup.Count) times" -ForegroundColor Red
            }
            exit 1
        }
        Write-Pass "No duplicate routing entries after third update"
        
        # Final count verification
        if ($thirdUpdateTeamKeys.Count -ne $baselineTeamKeys.Count) {
            Write-Fail "Team role count changed after third update" "Expected $($baselineTeamKeys.Count), got $($thirdUpdateTeamKeys.Count)"
            exit 1
        }
        if ($thirdUpdateRoutingKeys.Count -ne $baselineRoutingKeys.Count) {
            Write-Fail "Routing entry count changed after third update" "Expected $($baselineRoutingKeys.Count), got $($thirdUpdateRoutingKeys.Count)"
            exit 1
        }
        Write-Pass "Row counts preserved after third update"
        
    } finally {
        Pop-Location
    }
    
    # -----------------------------------------------------------------------------
    # Final Summary
    # -----------------------------------------------------------------------------
    
    Write-Section "Duplicate-Row Regression Test Summary"
    
    Write-Host "✅ All regression checks PASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verified fix from commit 2d52b9f9 (Bug 1):" -ForegroundColor Cyan
    Write-Host "  ✓ No duplicate team roles after 3 consecutive updates" -ForegroundColor Green
    Write-Host "  ✓ No duplicate routing entries after 3 consecutive updates" -ForegroundColor Green
    Write-Host "  ✓ Row counts stable across all updates" -ForegroundColor Green
    Write-Host "  ✓ Key-based merge strategy working correctly (FR-013)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Bug 1 (duplicate-row deploy) is FIXED and protected by regression test." -ForegroundColor Green
    
    exit 0
    
} finally {
    # Cleanup test project
    if (Test-Path -LiteralPath $testProjectPath) {
        try {
            # Force unlock any handles before removal
            Start-Sleep -Milliseconds 500
            Remove-Item -Path $testProjectPath -Recurse -Force -ErrorAction Stop
        } catch {
            Write-Warning "Could not clean up test project at: $testProjectPath (process may still have handles open)"
        }
    }
}
