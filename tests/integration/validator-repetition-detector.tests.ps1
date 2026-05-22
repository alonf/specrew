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

# Test 1: Helpers present in shared-governance.ps1
$sharedContent = Get-Content -LiteralPath $sharedGovernance -Raw -Encoding UTF8
foreach ($fn in @('Get-SpecrewCommandLogPath', 'Add-SpecrewCommandInvocation', 'Get-SpecrewRecentCommandInvocations', 'Test-SpecrewCommandRepetition')) {
    if ($sharedContent -notmatch ('function ' + [regex]::Escape($fn) + '\b')) {
        Write-Fail "Helper $fn not found in shared-governance.ps1"
    }
}
Write-Pass 'All 4 repetition-detector helpers present in shared-governance.ps1'

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

# Test 4: Validator entry has repetition-warning string
$validatorContent = Get-Content -LiteralPath $validatorScript -Raw -Encoding UTF8
if ($validatorContent -notmatch '\[validator-repetition-warning\]') {
    Write-Fail 'validator-repetition-warning string not present in validator'
}
Write-Pass 'validator-repetition-warning string present in validator code'

# Functional tests

# Test 5: Add + Get round-trip
$rtTest = @"
. '$sharedGovernance'
`$pr = '$repoRoot' + '\.scratch\rep-rt-test'
if (Test-Path -LiteralPath `$pr) { Remove-Item -Recurse -Force -LiteralPath `$pr }
`$null = New-Item -ItemType Directory -Path `$pr -Force
Add-SpecrewCommandInvocation -ProjectRoot `$pr -Command 'v.ps1' -TargetHash 'AAA' -CodeHash 'BBB'
`$recent = Get-SpecrewRecentCommandInvocations -ProjectRoot `$pr -Last 5
if (`$recent.Count -eq 1 -and `$recent[0].target_hash -eq 'AAA' -and `$recent[0].code_hash -eq 'BBB') {
    Write-Host 'RT_OK'
}
Remove-Item -Recurse -Force -LiteralPath `$pr
"@
$rtResult = pwsh -NoProfile -Command $rtTest 2>&1 | Out-String
if ($rtResult -notmatch 'RT_OK') {
    Write-Fail "Add + Get round-trip failed. Result:`n$rtResult"
}
Write-Pass 'Add-SpecrewCommandInvocation + Get-SpecrewRecentCommandInvocations round-trip works'

# Test 6: FIFO eviction at 20 entries
$fifoTest = @"
. '$sharedGovernance'
`$pr = '$repoRoot' + '\.scratch\rep-fifo-test'
if (Test-Path -LiteralPath `$pr) { Remove-Item -Recurse -Force -LiteralPath `$pr }
`$null = New-Item -ItemType Directory -Path `$pr -Force
for (`$i = 0; `$i -lt 25; `$i++) {
    Add-SpecrewCommandInvocation -ProjectRoot `$pr -Command "cmd$`$i" -TargetHash ("T{0:D2}" -f `$i) -CodeHash 'C'
}
`$logContent = Get-Content -LiteralPath (Join-Path `$pr '.specrew\.cache\last-commands.log') -Encoding UTF8
if (`$logContent.Count -eq 20) {
    `$lastEntry = `$logContent[-1] | ConvertFrom-Json
    `$firstEntry = `$logContent[0] | ConvertFrom-Json
    if (`$lastEntry.target_hash -eq 'T24' -and `$firstEntry.target_hash -eq 'T05') {
        Write-Host 'FIFO_OK'
    } else {
        Write-Host "FIFO_FAIL first=`$(`$firstEntry.target_hash) last=`$(`$lastEntry.target_hash)"
    }
} else {
    Write-Host "WRONG_COUNT count=`$(`$logContent.Count)"
}
Remove-Item -Recurse -Force -LiteralPath `$pr
"@
$fifoResult = pwsh -NoProfile -Command $fifoTest 2>&1 | Out-String
if ($fifoResult -notmatch 'FIFO_OK') {
    Write-Fail "FIFO eviction did not produce expected 20-entry window. Result:`n$fifoResult"
}
Write-Pass 'FIFO eviction at 20 entries works (oldest 5 evicted after 25 adds)'

# Test 7: Test-SpecrewCommandRepetition counts consecutive matches correctly
$repTest = @"
. '$sharedGovernance'
`$pr = '$repoRoot' + '\.scratch\rep-count-test'
if (Test-Path -LiteralPath `$pr) { Remove-Item -Recurse -Force -LiteralPath `$pr }
`$null = New-Item -ItemType Directory -Path `$pr -Force
Add-SpecrewCommandInvocation -ProjectRoot `$pr -Command 'v' -TargetHash 'X' -CodeHash 'A'
Add-SpecrewCommandInvocation -ProjectRoot `$pr -Command 'v' -TargetHash 'X' -CodeHash 'A'
Add-SpecrewCommandInvocation -ProjectRoot `$pr -Command 'v' -TargetHash 'X' -CodeHash 'A'
`$count1 = Test-SpecrewCommandRepetition -ProjectRoot `$pr -TargetHash 'X' -CodeHash 'A'
Add-SpecrewCommandInvocation -ProjectRoot `$pr -Command 'v' -TargetHash 'Y' -CodeHash 'A'
`$count2 = Test-SpecrewCommandRepetition -ProjectRoot `$pr -TargetHash 'X' -CodeHash 'A'
if (`$count1 -eq 3 -and `$count2 -eq 0) {
    Write-Host 'COUNT_OK'
} else {
    Write-Host "COUNT_FAIL c1=`$count1 c2=`$count2"
}
Remove-Item -Recurse -Force -LiteralPath `$pr
"@
$repResult = pwsh -NoProfile -Command $repTest 2>&1 | Out-String
if ($repResult -notmatch 'COUNT_OK') {
    Write-Fail "Test-SpecrewCommandRepetition consecutive count incorrect. Result:`n$repResult"
}
Write-Pass 'Test-SpecrewCommandRepetition counts consecutive matches correctly; resets on mismatch'

# Test 8: Corrupt log handled gracefully (non-fatal per FR-005)
$corruptTest = @"
. '$sharedGovernance'
`$pr = '$repoRoot' + '\.scratch\rep-corrupt-test'
if (Test-Path -LiteralPath `$pr) { Remove-Item -Recurse -Force -LiteralPath `$pr }
`$null = New-Item -ItemType Directory -Path `$pr -Force
`$cacheDir = Join-Path `$pr '.specrew\.cache'
`$null = New-Item -ItemType Directory -Path `$cacheDir -Force
Set-Content -LiteralPath (Join-Path `$cacheDir 'last-commands.log') -Value 'not json at all!@#$' -Encoding UTF8
try {
    `$recent = Get-SpecrewRecentCommandInvocations -ProjectRoot `$pr -Last 5
    Add-SpecrewCommandInvocation -ProjectRoot `$pr -Command 'v' -TargetHash 'Z' -CodeHash 'B'
    Write-Host 'CORRUPT_HANDLED'
} catch {
    Write-Host "THREW `$(`$_.Exception.Message)"
}
Remove-Item -Recurse -Force -LiteralPath `$pr
"@
$corruptResult = pwsh -NoProfile -Command $corruptTest 2>&1 | Out-String
if ($corruptResult -notmatch 'CORRUPT_HANDLED') {
    Write-Fail "Corrupt log not handled gracefully. Result:`n$corruptResult"
}
Write-Pass 'Corrupt log file handled gracefully (Get returns empty; Add starts fresh)'

Write-Host ''
Write-Host 'Validator repetition detector integration: all assertions pass'
exit 0
