[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$sharedGovernance = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$validatorScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$mirrorShared = Join-Path -Path $repoRoot -ChildPath '.specify\extensions\specrew-speckit\scripts\shared-governance.ps1'
$mirrorValidator = Join-Path -Path $repoRoot -ChildPath '.specify\extensions\specrew-speckit\scripts\validate-governance.ps1'

# Test 1: All 5 helpers present in shared-governance.ps1
# Per Copilot review PR #661: also verify Get-SpecrewClosedIterationFromStateFile.
$sharedContent = Get-Content -LiteralPath $sharedGovernance -Raw -Encoding UTF8
foreach ($fn in @('Get-SpecrewClosedIterationIndexPath', 'Get-SpecrewClosedIterationIndex', 'Test-SpecrewIterationClosed', 'Add-SpecrewClosedIterationEntry', 'Get-SpecrewClosedIterationFromStateFile')) {
    if ($sharedContent -notmatch ('function ' + [regex]::Escape($fn) + '\b')) {
        Write-Fail "Helper $fn not found in shared-governance.ps1"
    }
}
Write-Pass 'All 5 closed-iteration-index helpers present in shared-governance.ps1'

# Test 2: Mirror parity for shared-governance.ps1
$primaryHash = (Get-FileHash -LiteralPath $sharedGovernance -Algorithm SHA256).Hash
$mirrorHash = (Get-FileHash -LiteralPath $mirrorShared -Algorithm SHA256).Hash
if ($primaryHash -ne $mirrorHash) { Write-Fail "shared-governance.ps1 mirror parity failure" }
Write-Pass 'shared-governance.ps1 mirror parity verified'

# Test 3: Mirror parity for validate-governance.ps1
$vHash = (Get-FileHash -LiteralPath $validatorScript -Algorithm SHA256).Hash
$mvHash = (Get-FileHash -LiteralPath $mirrorValidator -Algorithm SHA256).Hash
if ($vHash -ne $mvHash) { Write-Fail "validate-governance.ps1 mirror parity failure" }
Write-Pass 'validate-governance.ps1 mirror parity verified'

# Test 4: -IncludeClosed switch parameter present
$validatorContent = Get-Content -LiteralPath $validatorScript -Raw -Encoding UTF8
if ($validatorContent -notmatch '\[switch\]\$IncludeClosed') {
    Write-Fail '-IncludeClosed switch parameter not present in validate-governance.ps1'
}
Write-Pass '-IncludeClosed switch parameter present'

# Test 5: -RebuildClosedIndex switch parameter present
if ($validatorContent -notmatch '\[switch\]\$RebuildClosedIndex') {
    Write-Fail '-RebuildClosedIndex switch parameter not present in validate-governance.ps1'
}
Write-Pass '-RebuildClosedIndex switch parameter present'

# Test 6: Closed-iteration filter present in validator
if ($validatorContent -notmatch 'closed-iteration filter') {
    Write-Fail 'closed-iteration filter banner string not present in validator code'
}
Write-Pass 'Closed-iteration filter banner present in validator'

# Test 7: Initial backfill exists at .specrew/closed-iterations.yml
$indexPath = Join-Path $repoRoot '.specrew\closed-iterations.yml'
if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
    Write-Fail '.specrew/closed-iterations.yml does not exist (initial backfill required)'
}
Write-Pass '.specrew/closed-iterations.yml exists (initial backfill)'

# Functional tests

# Test 8: Add-SpecrewClosedIterationEntry is idempotent
$idemTest = @"
. '$sharedGovernance'
`$pr = '$repoRoot' + '\.scratch\idem-test'
if (Test-Path -LiteralPath `$pr) { Remove-Item -Recurse -Force -LiteralPath `$pr }
`$null = New-Item -ItemType Directory -Path `$pr -Force
Add-SpecrewClosedIterationEntry -ProjectRoot `$pr -Feature '042-test' -Iteration '001' -ClosedAt '2026-05-22T10:00:00Z'
Add-SpecrewClosedIterationEntry -ProjectRoot `$pr -Feature '042-test' -Iteration '001' -ClosedAt '2026-05-22T10:00:00Z'
Add-SpecrewClosedIterationEntry -ProjectRoot `$pr -Feature '042-test' -Iteration '002' -ClosedAt '2026-05-22T10:00:00Z'
`$index = Get-SpecrewClosedIterationIndex -ProjectRoot `$pr
if (`$index.Count -eq 2 -and `$index.ContainsKey('042-test/001') -and `$index.ContainsKey('042-test/002')) {
    Write-Host 'IDEM_OK'
} else {
    Write-Host ("IDEM_FAIL count=" + `$index.Count)
}
Remove-Item -Recurse -Force -LiteralPath `$pr
"@
$idemResult = pwsh -NoProfile -Command $idemTest 2>&1 | Out-String
if ($idemResult -notmatch 'IDEM_OK') {
    Write-Fail "Add-SpecrewClosedIterationEntry not idempotent. Result:`n$idemResult"
}
Write-Pass 'Add-SpecrewClosedIterationEntry is idempotent (re-add does not duplicate)'

# Test 9: Test-SpecrewIterationClosed returns correct value
$testTest = @"
. '$sharedGovernance'
`$pr = '$repoRoot' + '\.scratch\test-closed-test'
if (Test-Path -LiteralPath `$pr) { Remove-Item -Recurse -Force -LiteralPath `$pr }
`$null = New-Item -ItemType Directory -Path `$pr -Force
Add-SpecrewClosedIterationEntry -ProjectRoot `$pr -Feature '050-x' -Iteration '001' -ClosedAt '2026-05-22T10:00:00Z'
if ((Test-SpecrewIterationClosed -ProjectRoot `$pr -Feature '050-x' -Iteration '001') -and -not (Test-SpecrewIterationClosed -ProjectRoot `$pr -Feature '999-x' -Iteration '001')) {
    Write-Host 'TEST_OK'
}
Remove-Item -Recurse -Force -LiteralPath `$pr
"@
$testResult = pwsh -NoProfile -Command $testTest 2>&1 | Out-String
if ($testResult -notmatch 'TEST_OK') {
    Write-Fail "Test-SpecrewIterationClosed returned wrong value. Result:`n$testResult"
}
Write-Pass 'Test-SpecrewIterationClosed returns correct boolean'

# Test 10: Boundary sync at iteration-closeout calls Add-SpecrewClosedIterationEntry
$boundarySyncContent = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/internal/sync-boundary-state.ps1') -Raw -Encoding UTF8
if ($boundarySyncContent -notmatch "BoundaryType -eq 'iteration-closeout'[\s\S]*?Add-SpecrewClosedIterationEntry") {
    Write-Fail 'sync-boundary-state.ps1 does not call Add-SpecrewClosedIterationEntry at iteration-closeout boundary'
}
Write-Pass 'Boundary sync calls Add-SpecrewClosedIterationEntry at iteration-closeout'

# Test 11: -RebuildClosedIndex against scratch tree produces populated index
# Per Copilot review PR #661: verify rebuild end-to-end.
$rebuildTest = @"
. '$sharedGovernance'
`$pr = '$repoRoot' + '\.scratch\rebuild-test'
if (Test-Path -LiteralPath `$pr) { Remove-Item -Recurse -Force -LiteralPath `$pr }
`$null = New-Item -ItemType Directory -Path (Join-Path `$pr 'specs\042-fake\iterations\001') -Force
`$state = "# Iteration State`n`n**Current Phase**: iteration-closeout`n"
Set-Content -LiteralPath (Join-Path `$pr 'specs\042-fake\iterations\001\state.md') -Value `$state -Encoding UTF8
`$entry = Get-SpecrewClosedIterationFromStateFile -StatePath (Join-Path `$pr 'specs\042-fake\iterations\001\state.md')
if (`$null -ne `$entry -and `$entry.feature -eq '042-fake' -and `$entry.iteration -eq '001') {
    Write-Host 'DETECTOR_OK'
}
Remove-Item -Recurse -Force -LiteralPath `$pr
"@
$rebuildResult = pwsh -NoProfile -Command $rebuildTest 2>&1 | Out-String
if ($rebuildResult -notmatch 'DETECTOR_OK') {
    Write-Fail "Get-SpecrewClosedIterationFromStateFile did not detect a fake closed iteration. Result:`n$rebuildResult"
}
Write-Pass 'Get-SpecrewClosedIterationFromStateFile detects closed iteration from state.md heuristic'

# Test 12: validate-governance.ps1 -RebuildClosedIndex against a scratch project
# produces a non-empty index containing the expected feature/iteration keys.
$rebuildE2ETest = @"
`$scratchRoot = '$repoRoot' + '\.scratch\rebuild-e2e-test'
if (Test-Path -LiteralPath `$scratchRoot) { Remove-Item -Recurse -Force -LiteralPath `$scratchRoot }
`$null = New-Item -ItemType Directory -Path (Join-Path `$scratchRoot 'specs\044-stub\iterations\001') -Force
`$null = New-Item -ItemType Directory -Path (Join-Path `$scratchRoot 'specs\045-stub\iterations\002') -Force
Set-Content -LiteralPath (Join-Path `$scratchRoot 'specs\044-stub\iterations\001\state.md') -Value "**Current Phase**: iteration-closeout`n" -Encoding UTF8
Set-Content -LiteralPath (Join-Path `$scratchRoot 'specs\045-stub\iterations\002\state.md') -Value "**Current Phase**: complete`n" -Encoding UTF8
& pwsh -NoProfile -NoLogo -File '$validatorScript' -ProjectPath `$scratchRoot -RebuildClosedIndex 2>&1 | Out-Null
`$indexPath = Join-Path `$scratchRoot '.specrew\closed-iterations.yml'
if (-not (Test-Path -LiteralPath `$indexPath -PathType Leaf)) { Write-Host 'NO_INDEX'; return }
`$content = Get-Content -LiteralPath `$indexPath -Raw -Encoding UTF8
if (`$content -match '044-stub' -and `$content -match '045-stub' -and `$content -match '001' -and `$content -match '002') {
    Write-Host 'E2E_OK'
} else {
    Write-Host ("E2E_FAIL content=" + `$content)
}
Remove-Item -Recurse -Force -LiteralPath `$scratchRoot
"@
$rebuildE2EResult = pwsh -NoProfile -Command $rebuildE2ETest 2>&1 | Out-String
if ($rebuildE2EResult -notmatch 'E2E_OK') {
    Write-Fail "-RebuildClosedIndex end-to-end did not produce expected index. Result:`n$rebuildE2EResult"
}
Write-Pass '-RebuildClosedIndex end-to-end produces index with expected feature/iteration entries'

Write-Host ''
Write-Host 'Closed-iteration index integration: all assertions pass'
exit 0
