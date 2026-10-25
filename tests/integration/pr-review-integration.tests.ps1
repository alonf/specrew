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

# Test 1: Both helpers present in shared-governance.ps1
$sharedContent = Get-Content -LiteralPath $sharedGovernance -Raw -Encoding UTF8
foreach ($fn in @('Get-SpecrewPrReviewResolutionPath', 'Test-HostProvidesAutomatedPrReview')) {
    if ($sharedContent -notmatch ('function ' + [regex]::Escape($fn) + '\b')) {
        Write-Fail "Helper $fn not found in shared-governance.ps1"
    }
}
Write-Pass 'Both PR-review-integration helpers present in shared-governance.ps1'

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

# Test 4: Validator emits pr-review-soft-warning string
$validatorContent = Get-Content -LiteralPath $validatorScript -Raw -Encoding UTF8
if ($validatorContent -notmatch '\[pr-review-soft-warning\]') {
    Write-Fail '[pr-review-soft-warning] string not present in validator'
}
Write-Pass '[pr-review-soft-warning] string present in validator code'

# Functional tests

# Test 5: Path helper returns canonical location
$pathTest = @"
. '$sharedGovernance'
`$result = Get-SpecrewPrReviewResolutionPath -IterationPath 'C:/repo/specs/030-x/iterations/001'
if (`$result -match 'specs[\\/]030-x[\\/]iterations[\\/]001[\\/]pr-review-resolution\.md`$') {
    Write-Host 'PATH_OK'
} else {
    Write-Host "PATH_WRONG `$result"
}
"@
$pathResult = pwsh -NoProfile -Command $pathTest 2>&1 | Out-String
if ($pathResult -notmatch 'PATH_OK') {
    Write-Fail "Get-SpecrewPrReviewResolutionPath returned wrong path. Result:`n$pathResult"
}
Write-Pass 'Get-SpecrewPrReviewResolutionPath returns canonical artifact path'

# Test 6: Test-HostProvidesAutomatedPrReview returns hashtable with Active key
$hostTest = @"
. '$sharedGovernance'
`$info = Test-HostProvidesAutomatedPrReview -ProjectRoot '$repoRoot'
if (`$info.ContainsKey('Active')) {
    Write-Host ("HOST_OK active=" + `$info.Active)
}
"@
$hostResult = pwsh -NoProfile -Command $hostTest 2>&1 | Out-String
if ($hostResult -notmatch 'HOST_OK active=') {
    Write-Fail "Test-HostProvidesAutomatedPrReview did not return hashtable with Active key. Result:`n$hostResult"
}
Write-Pass 'Test-HostProvidesAutomatedPrReview returns hashtable with Active key'

# Test 7: Soft warning is non-blocking. The historical F-038 iteration now fails a newer, unrelated
# campaign-evidence gate, so an absolute exit-0 assertion would make this fixture stale every time a
# new hard validator lands. Exercise the current validator end-to-end to prove the warning fires,
# then prove structurally that its block cannot mutate the already-computed hard-failure result or
# call an exit/throw surface.
$nonBlockTest = @"
`$out = & pwsh -NoProfile -NoLogo -File '$validatorScript' -ProjectPath '$repoRoot' -IterationPath '$repoRoot\specs\038-pr-review-integration\iterations\001' -NoParallel -NoCacheRead 2>&1 | Out-String
`$exitCode = `$LASTEXITCODE
if (`$out -match '\[pr-review-soft-warning\]') {
    Write-Host "NONBLOCK_WARNING_REACHED exit=`$exitCode"
} else {
    Write-Host "NONBLOCK_WARNING_MISSING exit=`$exitCode"
}
"@
$nonBlockResult = pwsh -NoProfile -Command $nonBlockTest 2>&1 | Out-String
if ($nonBlockResult -notmatch 'NONBLOCK_WARNING_REACHED') {
    Write-Fail "Validator soft-warning E2E reachability check failed. Result:`n$nonBlockResult"
}
Write-Pass 'Validator E2E reaches the PR-review soft warning on the current historical fixture'

$softBlockMatch = [regex]::Match(
    $validatorContent,
    '(?s)# Proposal 089: PR review integration soft-warning\..*?\r?\n\s*if \(\$hasFailures\) \{'
)
if (-not $softBlockMatch.Success) { Write-Fail 'Could not isolate the PR-review soft-warning block from the hard-failure exit' }
$softBlock = $softBlockMatch.Value
if ($softBlock -match '(?m)^\s*\$hasFailures\s*=' -or
    $softBlock -match '\bWrite-ValidatorSummaryAndExit\b' -or
    $softBlock -match '(?m)^\s*(throw|exit)\b') {
    Write-Fail 'PR-review soft-warning block can alter or terminate the hard validator result'
}
Write-Pass 'PR-review warning block is downstream of hard-result computation and has no result mutation or exit path'

Write-Host ''
Write-Host 'PR review integration: all assertions pass'
exit 0
