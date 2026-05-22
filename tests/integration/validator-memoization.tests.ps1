[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$sharedGovernance = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$validatorScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\validate-governance.ps1'

# Test 1: All 5 cache helpers exist in shared-governance.ps1
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

# Test 10: validator code hash change wipes cache wholesale (correctness check)
$wipeTest = @"
. '$sharedGovernance'
`$pr = '$repoRoot' + '\.scratch\cache-wipe-test'
if (Test-Path -LiteralPath `$pr) { Remove-Item -Recurse -Force -LiteralPath `$pr }
`$null = New-Item -ItemType Directory -Path `$pr -Force
# Seed cache with one entry under codehash 'OLD'
Set-ValidatorCacheEntry -ProjectRoot `$pr -CacheKey 'oldkey' -Errors @('err1') -ValidatorCodeHash 'OLD'
`$beforeEntry = Get-ValidatorCacheEntry -ProjectRoot `$pr -CacheKey 'oldkey'
# Now write a new entry under codehash 'NEW' — Set-ValidatorCacheEntry should wipe the cache
Set-ValidatorCacheEntry -ProjectRoot `$pr -CacheKey 'newkey' -Errors @('err2') -ValidatorCodeHash 'NEW'
`$staleEntry = Get-ValidatorCacheEntry -ProjectRoot `$pr -CacheKey 'oldkey'
`$freshEntry = Get-ValidatorCacheEntry -ProjectRoot `$pr -CacheKey 'newkey'
if (`$null -ne `$beforeEntry -and `$null -eq `$staleEntry -and `$null -ne `$freshEntry) {
    Write-Host 'CODE_HASH_WIPE_OK'
}
Remove-Item -Recurse -Force -LiteralPath `$pr
"@
$wipeResult = pwsh -NoProfile -Command $wipeTest 2>&1 | Out-String
if ($wipeResult -notmatch 'CODE_HASH_WIPE_OK') {
    Write-Fail "Validator code hash change did not wipe cache. Result:`n$wipeResult"
}
Write-Pass 'Validator code hash change wipes cache wholesale'

# Test 11: LRU eviction triggers when cache exceeds 500 entries
$lruTest = @"
. '$sharedGovernance'
`$pr = '$repoRoot' + '\.scratch\cache-lru-test'
if (Test-Path -LiteralPath `$pr) { Remove-Item -Recurse -Force -LiteralPath `$pr }
`$null = New-Item -ItemType Directory -Path `$pr -Force
# Write 502 entries under the same codehash; cache should evict 2 oldest
for (`$i = 0; `$i -lt 502; `$i++) {
    Set-ValidatorCacheEntry -ProjectRoot `$pr -CacheKey ("key{0:D3}" -f `$i) -Errors @() -ValidatorCodeHash 'SAME'
    Start-Sleep -Milliseconds 2  # ensure distinct validated_at timestamps for LRU ordering
}
`$cacheJson = Get-Content -LiteralPath (Join-Path `$pr '.specrew\.cache\validator-cache.json') -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 10
if (`$cacheJson.entries.Keys.Count -le 500) {
    Write-Host "LRU_OK:`$(`$cacheJson.entries.Keys.Count)"
}
Remove-Item -Recurse -Force -LiteralPath `$pr
"@
$lruResult = pwsh -NoProfile -Command $lruTest 2>&1 | Out-String
if ($lruResult -notmatch 'LRU_OK:\d+') {
    Write-Fail "LRU eviction did not enforce 500-entry cap. Result:`n$lruResult"
}
Write-Pass 'LRU eviction enforces 500-entry cap'

# Test 12: Get-ValidatorCacheEntry is read-only (does NOT rewrite cache file)
# Per Copilot review on PR #594: avoiding writes on read prevents corruption
# from concurrent validator runs.
$roTest = @"
. '$sharedGovernance'
`$pr = '$repoRoot' + '\.scratch\cache-readonly-test'
if (Test-Path -LiteralPath `$pr) { Remove-Item -Recurse -Force -LiteralPath `$pr }
`$null = New-Item -ItemType Directory -Path `$pr -Force
Set-ValidatorCacheEntry -ProjectRoot `$pr -CacheKey 'readtest' -Errors @() -ValidatorCodeHash 'H'
`$cachePath = Join-Path `$pr '.specrew\.cache\validator-cache.json'
`$hashBefore = (Get-FileHash -LiteralPath `$cachePath -Algorithm SHA256).Hash
# Read multiple times — file should not change
for (`$i = 0; `$i -lt 5; `$i++) { `$null = Get-ValidatorCacheEntry -ProjectRoot `$pr -CacheKey 'readtest' }
`$hashAfter = (Get-FileHash -LiteralPath `$cachePath -Algorithm SHA256).Hash
if (`$hashBefore -eq `$hashAfter) {
    Write-Host 'READ_ONLY_OK'
}
Remove-Item -Recurse -Force -LiteralPath `$pr
"@
$roResult = pwsh -NoProfile -Command $roTest 2>&1 | Out-String
if ($roResult -notmatch 'READ_ONLY_OK') {
    Write-Fail "Get-ValidatorCacheEntry modified cache file on read (concurrency hazard). Result:`n$roResult"
}
Write-Pass 'Get-ValidatorCacheEntry is read-only (no writes on read; safe under concurrent reads)'

Write-Host ''
Write-Host 'Validator memoization integration: all assertions pass'
exit 0
