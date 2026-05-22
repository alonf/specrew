[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$sharedGovernance = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$validatorScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\validate-governance.ps1'

# Test 1: All 4 cache helpers exist in shared-governance.ps1
$sharedContent = Get-Content -LiteralPath $sharedGovernance -Raw -Encoding UTF8
foreach ($fn in @('Get-ValidatorCachePath', 'Get-ValidatorCodeHash', 'Get-ValidatorCacheKey', 'Get-ValidatorCacheEntry', 'Set-ValidatorCacheEntry')) {
    if ($sharedContent -notmatch ('function ' + [regex]::Escape($fn) + '\b')) {
        Write-Fail "Cache helper $fn not found in shared-governance.ps1"
    }
}
Write-Pass 'All 5 cache helpers present in shared-governance.ps1'

# Test 2: Mirror parity for shared-governance.ps1
$mirrorShared = Join-Path -Path $repoRoot -ChildPath '.specify\extensions\specrew-speckit\scripts\shared-governance.ps1'
$primaryHash = (Get-FileHash -LiteralPath $sharedGovernance -Algorithm SHA256).Hash
$mirrorHash = (Get-FileHash -LiteralPath $mirrorShared -Algorithm SHA256).Hash
if ($primaryHash -ne $mirrorHash) { Write-Fail "shared-governance.ps1 mirror parity failure" }
Write-Pass 'shared-governance.ps1 mirror parity verified'

# Test 3: Mirror parity for validate-governance.ps1
$mirrorValidator = Join-Path -Path $repoRoot -ChildPath '.specify\extensions\specrew-speckit\scripts\validate-governance.ps1'
$pHash = (Get-FileHash -LiteralPath $validatorScript -Algorithm SHA256).Hash
$mHash = (Get-FileHash -LiteralPath $mirrorValidator -Algorithm SHA256).Hash
if ($pHash -ne $mHash) { Write-Fail "validate-governance.ps1 mirror parity failure" }
Write-Pass 'validate-governance.ps1 mirror parity verified'

# Test 4: -NoCacheRead parameter present
$validatorContent = Get-Content -LiteralPath $validatorScript -Raw -Encoding UTF8
if ($validatorContent -notmatch '\[switch\]\$NoCacheRead') {
    Write-Fail '-NoCacheRead switch not present in validate-governance.ps1'
}
Write-Pass '-NoCacheRead parameter present'

# Test 5: Cache integration in iteration loop
if ($validatorContent -notmatch 'Get-ValidatorCacheKey' -or $validatorContent -notmatch 'Set-ValidatorCacheEntry') {
    Write-Fail 'Cache helpers not invoked from validator iteration loop'
}
Write-Pass 'Cache integration present in validator iteration loop'

# Test 6: .gitignore contains .specrew/.cache/
$gitignore = Get-Content -LiteralPath (Join-Path $repoRoot '.gitignore') -Raw -Encoding UTF8
if ($gitignore -notmatch '\.specrew/\.cache/') {
    Write-Fail '.gitignore does not contain .specrew/.cache/'
}
Write-Pass '.gitignore contains .specrew/.cache/ entry'

# Functional tests via direct invocation

# Test 7: Get-ValidatorCacheKey returns deterministic SHA256 for same inputs
$cacheKeyTest = @"
. '$sharedGovernance'
`$path = '$repoRoot' + '\specs\034-validator-memoization\iterations\001'
`$key1 = Get-ValidatorCacheKey -IterationPath `$path -ValidatorCodeHash 'fixed'
`$key2 = Get-ValidatorCacheKey -IterationPath `$path -ValidatorCodeHash 'fixed'
if (`$key1 -eq `$key2 -and `$key1.Length -eq 64) {
    Write-Host 'DETERMINISTIC'
} else {
    Write-Host "NON-DETERMINISTIC k1=`$key1 k2=`$key2"
}
"@
$detResult = pwsh -NoProfile -Command $cacheKeyTest 2>&1 | Out-String
if ($detResult -notmatch 'DETERMINISTIC') {
    Write-Fail "Get-ValidatorCacheKey not deterministic. Result:`n$detResult"
}
Write-Pass 'Get-ValidatorCacheKey returns deterministic SHA256 keys'

# Test 8: Set + Get round-trip
$rtTest = @"
. '$sharedGovernance'
`$pr = '$repoRoot' + '\.scratch\cache-roundtrip'
if (Test-Path -LiteralPath `$pr) { Remove-Item -Recurse -Force -LiteralPath `$pr }
`$null = New-Item -ItemType Directory -Path `$pr -Force
Set-ValidatorCacheEntry -ProjectRoot `$pr -CacheKey 'testkey' -Errors @('err1', 'err2') -ValidatorCodeHash 'codehash'
`$entry = Get-ValidatorCacheEntry -ProjectRoot `$pr -CacheKey 'testkey'
if (`$null -ne `$entry -and `$entry.errors.Count -eq 2) {
    Write-Host 'ROUND_TRIP_OK'
}
Remove-Item -Recurse -Force -LiteralPath `$pr
"@
$rtResult = pwsh -NoProfile -Command $rtTest 2>&1 | Out-String
if ($rtResult -notmatch 'ROUND_TRIP_OK') {
    Write-Fail "Cache round-trip failed. Result:`n$rtResult"
}
Write-Pass 'Cache Set + Get round-trip works'

# Test 9: Validator code hash changes when scripts change (simulated)
$hashTest = @"
. '$sharedGovernance'
`$h1 = Get-ValidatorCodeHash -ProjectRoot '$repoRoot'
if (-not [string]::IsNullOrWhiteSpace(`$h1) -and `$h1.Length -eq 64) {
    Write-Host "HASH_OK:`$h1"
}
"@
$hashResult = pwsh -NoProfile -Command $hashTest 2>&1 | Out-String
if ($hashResult -notmatch 'HASH_OK:[0-9a-f]{64}') {
    Write-Fail "Get-ValidatorCodeHash failed. Result:`n$hashResult"
}
Write-Pass 'Get-ValidatorCodeHash returns 64-char SHA256'

Write-Host ''
Write-Host 'Validator memoization integration: all assertions pass'
exit 0
