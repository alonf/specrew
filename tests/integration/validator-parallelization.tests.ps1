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

# Test 1: Invoke-WithFileLock helper exists in shared-governance.ps1
$sharedContent = Get-Content -LiteralPath $sharedGovernance -Raw -Encoding UTF8
if ($sharedContent -notmatch 'function Invoke-WithFileLock\b') {
    Write-Fail 'Invoke-WithFileLock helper not found in shared-governance.ps1'
}
Write-Pass 'Invoke-WithFileLock helper present in shared-governance.ps1'

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

# Test 4: -NoParallel switch parameter present
$validatorContent = Get-Content -LiteralPath $validatorScript -Raw -Encoding UTF8
if ($validatorContent -notmatch '\[switch\]\$NoParallel') {
    Write-Fail '-NoParallel switch parameter not present in validate-governance.ps1'
}
Write-Pass '-NoParallel switch parameter present'

# Test 5: -ThrottleLimit parameter present with default 6
if ($validatorContent -notmatch '\[int\]\$ThrottleLimit\s*=\s*6') {
    Write-Fail '-ThrottleLimit parameter not present with default 6'
}
Write-Pass '-ThrottleLimit parameter present (default 6)'

# Test 6: Parallelism banner string in validator
if ($validatorContent -notmatch '\[validator-parallelism\]') {
    Write-Fail 'Parallelism banner string [validator-parallelism] not found in validator code'
}
Write-Pass 'Parallelism banner string [validator-parallelism] present'

# Test 7: ForEach-Object -Parallel construct present in validator
if ($validatorContent -notmatch 'ForEach-Object\s+-Parallel') {
    Write-Fail 'ForEach-Object -Parallel construct not present in validator code'
}
Write-Pass 'ForEach-Object -Parallel construct present in validator'

# Test 8: Set-ValidatorCacheEntry uses Invoke-WithFileLock
if ($sharedContent -notmatch 'function Set-ValidatorCacheEntry[\s\S]*?Invoke-WithFileLock') {
    Write-Fail 'Set-ValidatorCacheEntry does not invoke Invoke-WithFileLock'
}
Write-Pass 'Set-ValidatorCacheEntry wrapped in Invoke-WithFileLock'

# Functional tests via direct invocation

# Test 9: Invoke-WithFileLock acquires and releases lock (pre-existing helper, -Path param)
$lockTest = @"
. '$sharedGovernance'
`$lockDir = '$repoRoot' + '\.scratch\file-lock-test'
if (Test-Path -LiteralPath `$lockDir) { Remove-Item -Recurse -Force -LiteralPath `$lockDir }
`$null = New-Item -ItemType Directory -Path `$lockDir -Force
`$target = Join-Path `$lockDir 'shared.txt'
`$null = New-Item -ItemType File -Path `$target -Force
`$insideRan = `$false
Invoke-WithFileLock -Path `$target -ScriptBlock {
    `$script:insideRan = `$true
}
if (-not `$insideRan) { throw 'ScriptBlock did not execute inside lock' }
Write-Host 'SINGLE_LOCK_OK'
Remove-Item -Recurse -Force -LiteralPath `$lockDir
"@
$lockResult = pwsh -NoProfile -Command $lockTest 2>&1 | Out-String
if ($lockResult -notmatch 'SINGLE_LOCK_OK') {
    Write-Fail "Single-process lock acquire/release failed. Result:`n$lockResult"
}
Write-Pass 'Invoke-WithFileLock single-process acquire/release works'

# Test 10: Concurrent cache writes via Set-ValidatorCacheEntry preserve all entries
$concurrentTest = @"
. '$sharedGovernance'
`$pr = '$repoRoot' + '\.scratch\cache-concurrent-test'
if (Test-Path -LiteralPath `$pr) { Remove-Item -Recurse -Force -LiteralPath `$pr }
`$null = New-Item -ItemType Directory -Path `$pr -Force

# Spawn 8 concurrent processes, each writes a distinct cache key
`$writerScript = @'
param([string]`$ProjectRoot, [string]`$Key, [string]`$Shared)
. `$Shared
Set-ValidatorCacheEntry -ProjectRoot `$ProjectRoot -CacheKey `$Key -Errors @("err-`$Key") -ValidatorCodeHash 'SAMEHASH'
'@
`$writerPath = Join-Path `$pr 'writer.ps1'
Set-Content -LiteralPath `$writerPath -Value `$writerScript -Encoding UTF8

`$procs = @()
for (`$i = 0; `$i -lt 8; `$i++) {
    `$procs += Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-File', `$writerPath, '-ProjectRoot', `$pr, '-Key', ("key-{0:D2}" -f `$i), '-Shared', '$sharedGovernance') -PassThru -WindowStyle Hidden
}
`$procs | Wait-Process

`$cacheJson = Get-Content -LiteralPath (Join-Path `$pr '.specrew\.cache\validator-cache.json') -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 10
if (`$cacheJson.entries.Keys.Count -eq 8) {
    `$allPresent = `$true
    for (`$i = 0; `$i -lt 8; `$i++) {
        `$k = "key-{0:D2}" -f `$i
        if (-not `$cacheJson.entries.ContainsKey(`$k)) { `$allPresent = `$false; break }
    }
    if (`$allPresent) {
        Write-Host 'CONCURRENT_WRITES_OK'
    } else {
        Write-Host "MISSING_KEYS keys=`$(`$cacheJson.entries.Keys -join ',')"
    }
} else {
    Write-Host "WRONG_COUNT count=`$(`$cacheJson.entries.Keys.Count)"
}
Remove-Item -Recurse -Force -LiteralPath `$pr
"@
$concurrentResult = pwsh -NoProfile -Command $concurrentTest 2>&1 | Out-String
if ($concurrentResult -notmatch 'CONCURRENT_WRITES_OK') {
    Write-Fail "Concurrent cache writes lost entries. Result:`n$concurrentResult"
}
Write-Pass 'Concurrent cache writes (8 processes) preserve all entries via file lock'

# Test 11: -NoParallel switch falls back to serial (no parallelism banner)
$noParallelTest = @"
`$out = & '$validatorScript' -ProjectPath '$repoRoot' -IterationPath '$repoRoot\specs\034-validator-memoization\iterations\001' -NoParallel 2>&1 | Out-String
if (`$out -match '\[validator-parallelism\]') {
    Write-Host "BANNER_LEAKED `$out"
} else {
    Write-Host 'NOPARALLEL_SERIAL_OK'
}
"@
$noParResult = pwsh -NoProfile -Command $noParallelTest 2>&1 | Out-String
if ($noParResult -notmatch 'NOPARALLEL_SERIAL_OK') {
    Write-Fail "Single-target with -NoParallel emitted parallelism banner. Result:`n$noParResult"
}
Write-Pass '-NoParallel switch falls back to serial path'

# Test 12: ThrottleLimit parameter is wired through to ForEach-Object -Parallel
if ($validatorContent -notmatch 'ForEach-Object\s+-Parallel\s*\{[\s\S]*?\}\s*-ThrottleLimit\s+\$effectiveThrottle') {
    Write-Fail '-ThrottleLimit value not wired to ForEach-Object -Parallel'
}
Write-Pass 'ThrottleLimit parameter wired to ForEach-Object -Parallel'

Write-Host ''
Write-Host 'Validator parallelization integration: all assertions pass'
exit 0
