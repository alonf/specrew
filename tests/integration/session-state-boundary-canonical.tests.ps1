[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validatorScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$sharedGovernance = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\shared-governance.ps1'

# Test 1: Get-SpecrewCanonicalBoundaryTypes includes all 8 canonical values
$sharedContent = Get-Content -LiteralPath $sharedGovernance -Raw -Encoding UTF8
$canonicalFuncMatch = [regex]::Match($sharedContent, "function Get-SpecrewCanonicalBoundaryTypes \{[\s\S]*?\}")
if (-not $canonicalFuncMatch.Success) {
    Write-Fail "Get-SpecrewCanonicalBoundaryTypes function not found in shared-governance.ps1"
}
$canonicalBody = $canonicalFuncMatch.Value
foreach ($expected in @('specify', 'clarify', 'plan', 'tasks', 'review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')) {
    if ($canonicalBody -notmatch ("'" + [regex]::Escape($expected) + "'")) {
        Write-Fail "Get-SpecrewCanonicalBoundaryTypes is missing canonical value: $expected"
    }
}
Write-Pass 'Get-SpecrewCanonicalBoundaryTypes contains all 8 canonical boundary values'

# Test 2: Get-SpecrewClosureBoundaryTypes return list contains feature-closeout but NOT iteration-closeout
# (scope the regex to just the return @(...) line; the function body includes a comment that mentions
# 'iteration-closeout' as the explicit exclusion, which we don't want to false-positive on)
$closureFuncMatch = [regex]::Match($sharedContent, "function Get-SpecrewClosureBoundaryTypes \{[\s\S]*?\}")
if (-not $closureFuncMatch.Success) {
    Write-Fail "Get-SpecrewClosureBoundaryTypes function not found in shared-governance.ps1"
}
$closureReturnMatch = [regex]::Match($closureFuncMatch.Value, "return\s+@\(([^)]*)\)")
if (-not $closureReturnMatch.Success) {
    Write-Fail "Get-SpecrewClosureBoundaryTypes return @(...) statement not found"
}
$closureReturnList = $closureReturnMatch.Groups[1].Value
if ($closureReturnList -notmatch "'feature-closeout'") {
    Write-Fail "Get-SpecrewClosureBoundaryTypes return list is missing 'feature-closeout'"
}
if ($closureReturnList -match "'iteration-closeout'") {
    Write-Fail "Get-SpecrewClosureBoundaryTypes return list incorrectly includes 'iteration-closeout' (iteration-closeout has active=true)"
}
Write-Pass "Get-SpecrewClosureBoundaryTypes return list correctly contains feature-closeout but not iteration-closeout"

# Test 3: Test-SessionStateBoundaryCanonical function exists in validate-governance.ps1
$validatorContent = Get-Content -LiteralPath $validatorScript -Raw -Encoding UTF8
if ($validatorContent -notmatch "function Test-SessionStateBoundaryCanonical") {
    Write-Fail "Test-SessionStateBoundaryCanonical function not found in validate-governance.ps1"
}
Write-Pass "Test-SessionStateBoundaryCanonical function present in validate-governance.ps1"

# Test 4: Validator rule integration point exists in main flow
if ($validatorContent -notmatch "Test-SessionStateBoundaryCanonical -ProjectRoot") {
    Write-Fail "Test-SessionStateBoundaryCanonical is not invoked from validator's main entry flow"
}
Write-Pass "Test-SessionStateBoundaryCanonical invoked from validator main entry flow"

# Test 5+: Functional tests against the rule via direct invocation (avoids requiring full
# validator fixture setup; the rule is self-contained and reads state files directly).
$fixtureRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\session-boundary-canonical-fixture'
if (Test-Path -LiteralPath $fixtureRoot) {
    Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force
$null = New-Item -ItemType Directory -Path (Join-Path $fixtureRoot '.specrew') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $fixtureRoot '.squad\identity') -Force

function Invoke-BoundaryRule {
    param([string]$ProjectRoot)
    # Dot-source dependencies then directly invoke the rule function; return its stdout + exit code
    $cmd = @"
. '$sharedGovernance'
. '$validatorScript' -ProjectPath '$ProjectRoot' -SkipReportOutput 2>&1 | Out-Null
`$count = Test-SessionStateBoundaryCanonical -ProjectRoot '$ProjectRoot'
[pscustomobject]@{ Count = `$count }
"@
    # Note: we can't actually invoke the validator's main flow because it requires full project structure.
    # Instead, we'll just dot-source shared-governance + extract the function bodies and test directly.
    $directCmd = @"
. '$sharedGovernance'

# Extract and define Test-SessionStateBoundaryCanonical from the validator script
`$validatorSource = Get-Content -LiteralPath '$validatorScript' -Raw -Encoding UTF8
`$funcMatch = [regex]::Match(`$validatorSource, 'function Test-SessionStateBoundaryCanonical \{[\s\S]*?\n\}')
if (-not `$funcMatch.Success) {
    Write-Error 'Could not extract Test-SessionStateBoundaryCanonical from validator script'
    exit 1
}
Invoke-Expression `$funcMatch.Value
Test-SessionStateBoundaryCanonical -ProjectRoot '$ProjectRoot'
"@
    $output = pwsh -NoProfile -Command $directCmd 2>&1 | Out-String
    return $output
}

# Fixture A: non-canonical 'feature-closed' string
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.specrew\start-context.json'), '{ "schema": "v1", "session_state": { "active": true, "boundary_type": "feature-closed", "feature_ref": "001-test", "feature_path": "x", "iteration_number": "001", "task_id": null, "auth_commit_hash": null, "recorded_at": "2026-05-22T05:00:00Z" } }', [System.Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.specrew\last-start-prompt.md'), "---`nsession_state_active: true`nsession_state_boundary: feature-closed`n---`n", [System.Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.squad\identity\now.md'), "---`nsession_state_active: true`nsession_state_boundary: feature-closed`n---`n", [System.Text.UTF8Encoding]::new($false))

$resultA = Invoke-BoundaryRule -ProjectRoot $fixtureRoot
if ($resultA -notmatch 'feature-closed') {
    Write-Fail "Rule did not flag 'feature-closed' string. Output:`n$resultA"
}
if ($resultA -notmatch 'FAIL Test-SessionStateBoundaryCanonical') {
    Write-Fail "Rule did not emit FAIL banner. Output:`n$resultA"
}
Write-Pass "Rule rejects non-canonical 'feature-closed' across all 3 state surfaces"

# Fixture B: canonical 'feature-closeout' + active=true (contradiction)
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.specrew\start-context.json'), '{ "schema": "v1", "session_state": { "active": true, "boundary_type": "feature-closeout", "feature_ref": "001-test", "feature_path": "x", "iteration_number": "001", "task_id": null, "auth_commit_hash": null, "recorded_at": "2026-05-22T05:00:00Z" } }', [System.Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.specrew\last-start-prompt.md'), "---`nsession_state_active: true`nsession_state_boundary: feature-closeout`n---`n", [System.Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.squad\identity\now.md'), "---`nsession_state_active: true`nsession_state_boundary: feature-closeout`n---`n", [System.Text.UTF8Encoding]::new($false))

$resultB = Invoke-BoundaryRule -ProjectRoot $fixtureRoot
if ($resultB -notmatch 'contradictory') {
    Write-Fail "Rule did not catch active=true + boundary=feature-closeout contradiction. Output:`n$resultB"
}
Write-Pass "Rule catches active=true + boundary=feature-closeout contradiction"

# Fixture C: clean canonical post-closeout state (active=false + boundary=feature-closeout)
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.specrew\start-context.json'), '{ "schema": "v1", "session_state": { "active": false, "boundary_type": "feature-closeout", "feature_ref": "001-test", "feature_path": "x", "iteration_number": "001", "task_id": null, "auth_commit_hash": null, "recorded_at": "2026-05-22T05:00:00Z" } }', [System.Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.specrew\last-start-prompt.md'), "---`nsession_state_active: false`nsession_state_boundary: feature-closeout`n---`n", [System.Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.squad\identity\now.md'), "---`nsession_state_active: false`nsession_state_boundary: feature-closeout`n---`n", [System.Text.UTF8Encoding]::new($false))

$resultC = Invoke-BoundaryRule -ProjectRoot $fixtureRoot
if ($resultC -match 'FAIL Test-SessionStateBoundaryCanonical') {
    Write-Fail "Rule falsely flagged clean canonical state (active=false + boundary=feature-closeout). Output:`n$resultC"
}
Write-Pass "Rule passes clean canonical state (active=false + boundary=feature-closeout)"

# Fixture D: active=true + boundary=review-signoff (NOT a contradiction; review-signoff isn't a closure boundary)
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.specrew\start-context.json'), '{ "schema": "v1", "session_state": { "active": true, "boundary_type": "review-signoff", "feature_ref": "001-test", "feature_path": "x", "iteration_number": "001", "task_id": null, "auth_commit_hash": null, "recorded_at": "2026-05-22T05:00:00Z" } }', [System.Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.specrew\last-start-prompt.md'), "---`nsession_state_active: true`nsession_state_boundary: review-signoff`n---`n", [System.Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.squad\identity\now.md'), "---`nsession_state_active: true`nsession_state_boundary: review-signoff`n---`n", [System.Text.UTF8Encoding]::new($false))

$resultD = Invoke-BoundaryRule -ProjectRoot $fixtureRoot
if ($resultD -match 'FAIL Test-SessionStateBoundaryCanonical') {
    Write-Fail "Rule falsely flagged active=true + boundary=review-signoff. Output:`n$resultD"
}
Write-Pass "Rule passes active=true + boundary=review-signoff (no contradiction)"

# Fixture E: active=true + boundary=iteration-closeout (NOT a contradiction; iteration-closeout has active=true)
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.specrew\start-context.json'), '{ "schema": "v1", "session_state": { "active": true, "boundary_type": "iteration-closeout", "feature_ref": "001-test", "feature_path": "x", "iteration_number": "001", "task_id": null, "auth_commit_hash": null, "recorded_at": "2026-05-22T05:00:00Z" } }', [System.Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.specrew\last-start-prompt.md'), "---`nsession_state_active: true`nsession_state_boundary: iteration-closeout`n---`n", [System.Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.squad\identity\now.md'), "---`nsession_state_active: true`nsession_state_boundary: iteration-closeout`n---`n", [System.Text.UTF8Encoding]::new($false))

$resultE = Invoke-BoundaryRule -ProjectRoot $fixtureRoot
if ($resultE -match 'FAIL Test-SessionStateBoundaryCanonical') {
    Write-Fail "Rule falsely flagged active=true + boundary=iteration-closeout (iteration-closeout is not in closure set). Output:`n$resultE"
}
Write-Pass "Rule passes active=true + boundary=iteration-closeout (iteration-closeout is not in closure set)"

# Cleanup
Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ''
Write-Host 'Session-state boundary canonical validator rule: all assertions pass'
exit 0
