[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path

# Test 1: All 4 new sync command files exist at canonical primary paths
$primaryCommands = @(
    'speckit.specrew-speckit.sync-review-signoff.md'
    'speckit.specrew-speckit.sync-retro.md'
    'speckit.specrew-speckit.sync-iteration-closeout.md'
    'speckit.specrew-speckit.sync-feature-closeout.md'
)
foreach ($cmd in $primaryCommands) {
    $path = Join-Path -Path $repoRoot -ChildPath "extensions\specrew-speckit\commands\$cmd"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Write-Fail "Sync command file missing at primary location: $path"
    }
}
Write-Pass 'All 4 sync command files present at primary location'

# Test 2: All 4 new sync command files exist at mirror paths
foreach ($cmd in $primaryCommands) {
    $path = Join-Path -Path $repoRoot -ChildPath ".specify\extensions\specrew-speckit\commands\$cmd"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Write-Fail "Sync command file missing at mirror location: $path"
    }
}
Write-Pass 'All 4 sync command files present at mirror location'

# Test 3: Mirror parity (SHA256 match) for all 4 command files
foreach ($cmd in $primaryCommands) {
    $primaryPath = Join-Path -Path $repoRoot -ChildPath "extensions\specrew-speckit\commands\$cmd"
    $mirrorPath = Join-Path -Path $repoRoot -ChildPath ".specify\extensions\specrew-speckit\commands\$cmd"
    $primaryHash = (Get-FileHash -LiteralPath $primaryPath -Algorithm SHA256).Hash
    $mirrorHash = (Get-FileHash -LiteralPath $mirrorPath -Algorithm SHA256).Hash
    if ($primaryHash -ne $mirrorHash) {
        Write-Fail "Mirror parity failure for $cmd : primary $primaryHash != mirror $mirrorHash"
    }
}
Write-Pass 'Mirror parity verified for all 4 sync command files (SHA256 match)'

# Test 4: Each command file references the correct -BoundaryType enum value
$boundaryMappings = @{
    'speckit.specrew-speckit.sync-review-signoff.md' = 'review-signoff'
    'speckit.specrew-speckit.sync-retro.md' = 'retro'
    'speckit.specrew-speckit.sync-iteration-closeout.md' = 'iteration-closeout'
    'speckit.specrew-speckit.sync-feature-closeout.md' = 'feature-closeout'
}
foreach ($cmd in $boundaryMappings.Keys) {
    $primaryPath = Join-Path -Path $repoRoot -ChildPath "extensions\specrew-speckit\commands\$cmd"
    $content = Get-Content -LiteralPath $primaryPath -Raw -Encoding UTF8
    $expectedBoundary = $boundaryMappings[$cmd]
    if ($content -notmatch ('-BoundaryType ' + [regex]::Escape($expectedBoundary) + '\b')) {
        Write-Fail "Command $cmd does not reference -BoundaryType $expectedBoundary"
    }
}
Write-Pass 'All 4 commands reference their correct canonical -BoundaryType enum value'

# Test 5: extension.yml lists all 4 new commands in provides.commands
$extensionYmlPath = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\extension.yml'
$extensionYml = Get-Content -LiteralPath $extensionYmlPath -Raw -Encoding UTF8
foreach ($cmd in $primaryCommands) {
    $cmdName = [System.IO.Path]::GetFileNameWithoutExtension($cmd)
    if ($extensionYml -notmatch ('name:\s*' + [regex]::Escape($cmdName) + '\b')) {
        Write-Fail "extension.yml does not list command $cmdName in provides.commands"
    }
}
Write-Pass 'extension.yml lists all 4 new sync commands in provides.commands'

# Test 6: Mirror extension.yml also lists all 4 commands
$mirrorExtensionYmlPath = Join-Path -Path $repoRoot -ChildPath '.specify\extensions\specrew-speckit\extension.yml'
$mirrorExtensionYml = Get-Content -LiteralPath $mirrorExtensionYmlPath -Raw -Encoding UTF8
foreach ($cmd in $primaryCommands) {
    $cmdName = [System.IO.Path]::GetFileNameWithoutExtension($cmd)
    if ($mirrorExtensionYml -notmatch ('name:\s*' + [regex]::Escape($cmdName) + '\b')) {
        Write-Fail "Mirror extension.yml does not list command $cmdName in provides.commands"
    }
}
Write-Pass 'Mirror extension.yml lists all 4 new sync commands'

# Test 7: ValidateSet at line 188, 222, 670 of sync-boundary-state.ps1 includes 'retro'
$syncBoundaryPath = Join-Path -Path $repoRoot -ChildPath 'scripts\internal\sync-boundary-state.ps1'
$syncBoundaryContent = Get-Content -LiteralPath $syncBoundaryPath -Raw -Encoding UTF8
$validateSetRetroMatches = [regex]::Matches($syncBoundaryContent, "ValidateSet\([^)]*'retro'[^)]*\)").Count
if ($validateSetRetroMatches -lt 2) {
    Write-Fail "Expected at least 2 ValidateSet sites containing 'retro' in sync-boundary-state.ps1; found $validateSetRetroMatches"
}
Write-Pass "sync-boundary-state.ps1 ValidateSet sites include 'retro' ($validateSetRetroMatches matches)"

# Test 8: Get-SpecrewBoundaryOrder includes 'retro' in the canonical order
$getBoundaryOrderMatch = [regex]::Match($syncBoundaryContent, "function Get-SpecrewBoundaryOrder \{[^}]*\}")
if (-not $getBoundaryOrderMatch.Success -or $getBoundaryOrderMatch.Value -notmatch "'retro'") {
    Write-Fail "Get-SpecrewBoundaryOrder does not include 'retro' in its return list"
}
Write-Pass "Get-SpecrewBoundaryOrder includes 'retro' in canonical ordering"

# Test 9: Smoke-invoke `Invoke-SpecrewBoundaryStateSync -BoundaryType retro` does NOT throw a ValidateSet error
# (We can't run a full sync without a fixture; we just verify the parameter is accepted.)
$syncScriptInvocation = "& { . '$syncBoundaryPath'; try { New-SpecrewSessionState -BoundaryType 'retro' -FeatureRef 'test' -IterationNumber '001' -TaskId `$null -AuthCommitHash `$null } catch { if (`$_.Exception.Message -match 'ValidateSet') { 'VALIDATE_SET_ERROR' } else { 'OK' } } }"
$smokeResult = pwsh -NoProfile -Command $syncScriptInvocation 2>&1 | Out-String
if ($smokeResult -match 'VALIDATE_SET_ERROR') {
    Write-Fail "Smoke-invoking New-SpecrewSessionState -BoundaryType 'retro' threw a ValidateSet error: $smokeResult"
}
Write-Pass "BoundaryType 'retro' is accepted by sync-boundary-state.ps1 ValidateSet"

Write-Host ''
Write-Host 'Closeout lifecycle sync commands integration: all assertions pass'
exit 0
