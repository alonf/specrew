[CmdletBinding()]
param()

# F-044 iter-006 regression tests for the dispatch hardening + scaffolder-tolerance fixes
# surfaced by Antigravity's empirical lifecycle exercise.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path

# Test 1: Specrew.psm1 sets $env:SPECREW_MODULE_PATH on import (iter-006 T001)
$psm1Content = Get-Content -LiteralPath (Join-Path $repoRoot 'Specrew.psm1') -Raw -Encoding UTF8
if ($psm1Content -notmatch '\$env:SPECREW_MODULE_PATH\s*=\s*\$ScriptRoot') {
    Write-Fail "Specrew.psm1 must set \$env:SPECREW_MODULE_PATH = \$ScriptRoot on import so child processes dispatch to the active Dev tree (iter-006 T001)."
}
Write-Pass "Specrew.psm1 sets \$env:SPECREW_MODULE_PATH on import (iter-006 T001)"

# Test 2: sync-boundary-state.ps1 shim honors $env:SPECREW_MODULE_PATH override
$shimContent = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\sync-boundary-state.ps1') -Raw -Encoding UTF8
if ($shimContent -notmatch '\$env:SPECREW_MODULE_PATH') {
    Write-Fail "sync-boundary-state.ps1 must honor \$env:SPECREW_MODULE_PATH override (iter-006 T001)."
}
Write-Pass "sync-boundary-state.ps1 honors \$env:SPECREW_MODULE_PATH override"

# Test 3: sync-boundary-state.ps1 has stale-install detection
if ($shimContent -notmatch 'Stale Specrew install') {
    Write-Fail "sync-boundary-state.ps1 must detect stale installs (project specrew_version > resolved module version) and refuse dispatch with actionable guidance (iter-006 T001)."
}
Write-Pass "sync-boundary-state.ps1 detects stale install (project version > installed version)"

# Test 4: shim reads specrew_version from project's .specrew/config.yml
if ($shimContent -notmatch '\.specrew\\config\.yml') {
    Write-Fail "sync-boundary-state.ps1 must read specrew_version from project's .specrew/config.yml for stale-install comparison."
}
if ($shimContent -notmatch 'specrew_version:') {
    Write-Fail "sync-boundary-state.ps1 must regex-match specrew_version: line in project config."
}
Write-Pass "sync-boundary-state.ps1 reads specrew_version from project .specrew/config.yml"

# Test 5: scaffold-iteration-plan.ps1 degrades gracefully when spec has no canonical FRs (iter-006 T003)
$planScaffoldContent = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-iteration-plan.ps1') -Raw -Encoding UTF8
if ($planScaffoldContent -match 'throw "No functional requirements were found') {
    Write-Fail "scaffold-iteration-plan.ps1 still throws hard on zero FRs. Should degrade to placeholder + warning (iter-006 T003)."
}
if ($planScaffoldContent -notmatch 'FR-PLACEHOLDER') {
    Write-Fail "scaffold-iteration-plan.ps1 must emit FR-PLACEHOLDER fallback when spec has no canonical FRs (iter-006 T003)."
}
Write-Pass "scaffold-iteration-plan.ps1 degrades gracefully when spec has no canonical FRs"

# Test 6: scaffold-iteration-plan.ps1 has the $null -ne $RequirementScope StrictMode fix (iter-006 T002 canonicalization of Antigravity's patch)
if ($planScaffoldContent -notmatch '\$null -ne \$RequirementScope -and \$RequirementScope\.Count') {
    Write-Fail "scaffold-iteration-plan.ps1 must use '\$null -ne \$RequirementScope -and ...' StrictMode-safe pattern (iter-006 T002 — canonicalized from Antigravity's empirical patch)."
}
Write-Pass "scaffold-iteration-plan.ps1 RequirementScope null-check is StrictMode-safe (iter-006 T002)"

# Test 7: Smoke — parse-check the 3 touched files (catches syntax breaks before runtime)
foreach ($file in @('Specrew.psm1', 'extensions\specrew-speckit\scripts\sync-boundary-state.ps1', 'extensions\specrew-speckit\scripts\scaffold-iteration-plan.ps1')) {
    $errs = $null
    [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot $file), [ref]$null, [ref]$errs) | Out-Null
    if ($null -ne $errs -and $errs.Count -gt 0) {
        Write-Fail "Parse error in '$file': $($errs[0].Message)"
    }
}
Write-Pass "All 3 iter-006-touched files parse cleanly"

Write-Host "`nMulti-host lifecycle smoke (iter-006): all assertions pass" -ForegroundColor Green
