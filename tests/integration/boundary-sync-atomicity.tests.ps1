[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'

$scratchRoot = Join-Path $repoRoot '.scratch\boundary-sync-atomicity'
$projectRoot = Join-Path $scratchRoot 'project'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -ItemType Directory -Path $projectRoot -Force
$null = & git -C $projectRoot init --quiet 2>&1
$null = & git -C $projectRoot config user.email 'test@specrew.local' 2>&1
$null = & git -C $projectRoot config user.name 'Test User' 2>&1

foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', 'specs\020-session-state-durability\iterations\001')) {
    $null = New-Item -ItemType Directory -Path (Join-Path $projectRoot $relativeDirectory) -Force
}

[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/020-session-state-durability`"`n}", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m 'Seed repository' --quiet 2>&1
$null = & git -C $projectRoot branch -M main 2>&1
$null = & git -C $projectRoot checkout -b 020-session-state-durability 2>&1

$featureDirectory = Join-Path $projectRoot 'specs\020-session-state-durability'
$iterationDirectory = Join-Path $featureDirectory 'iterations\001'
$null = New-Item -ItemType Directory -Path $iterationDirectory -Force
[System.IO.File]::WriteAllText((Join-Path $featureDirectory 'spec.md'), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m 'Seed feature files' --quiet 2>&1

$syncResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $projectRoot,
    '-BoundaryType', 'plan',
    '-FeatureRef', '020-session-state-durability',
    '-IterationNumber', '001',
    '-AuthCommitHash', 'HEAD'
)
if ($syncResult.ExitCode -ne 0) {
    Write-Fail ("Boundary sync failed:`n{0}" -f ($syncResult.Output -join [Environment]::NewLine))
    exit 1
}

$authCommit = (@(& git -C $projectRoot rev-parse HEAD 2>&1))[0].ToString().Trim()

$promptPath = Join-Path $projectRoot '.specrew\last-start-prompt.md'
$contextPath = Join-Path $projectRoot '.specrew\start-context.json'
$identityPath = Join-Path $projectRoot '.squad\identity\now.md'
$decisionsPath = Join-Path $projectRoot '.squad\decisions.md'
foreach ($path in @($promptPath, $contextPath, $identityPath, $decisionsPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Write-Fail "Expected boundary-sync artifact missing: $path"
        exit 1
    }
}

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
if ($promptContent -notmatch 'session_state_boundary:\s*plan' -or $promptContent -notmatch 'session_state_feature:\s*020-session-state-durability') {
    Write-Fail 'Boundary sync did not stamp prompt frontmatter with the expected state.'
    exit 1
}

$context = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
if ($context.session_state.boundary_type -ne 'plan' -or $context.session_state.feature_ref -ne '020-session-state-durability' -or $context.session_state.auth_commit_hash -ne $authCommit) {
    Write-Fail 'Boundary sync did not stamp start-context.json with the expected state.'
    exit 1
}

$identityContent = Get-Content -LiteralPath $identityPath -Raw -Encoding UTF8
if ($identityContent -notmatch 'session_state_boundary:\s*plan' -or $identityContent -notmatch 'session_state_feature:\s*020-session-state-durability') {
    Write-Fail 'Boundary sync did not stamp identity/now.md with the expected state.'
    exit 1
}

$decisionsContent = Get-Content -LiteralPath $decisionsPath -Raw -Encoding UTF8
if ($decisionsContent -notmatch 'Boundary sync: plan' -or $decisionsContent -notmatch [regex]::Escape($authCommit) -or $decisionsContent -match 'Auth Commit Hash\*\*: HEAD') {
    Write-Fail 'Boundary sync did not record the decisions ledger entry.'
    exit 1
}

Write-Pass 'Boundary sync updated all four state files consistently'

$contextObject = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
$contextObject.session_state.boundary_type = 'clarify'
$contextObject | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $contextPath -Encoding UTF8

$staleResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $projectRoot, '-NoLaunch', '-RecoveryChoice', 'C')
$staleOutput = $staleResult.Output -join [Environment]::NewLine
if ($staleResult.ExitCode -ne 0) {
    Write-Fail 'specrew start should keep stale-state handling recoverable when boundary state files disagree.'
    exit 1
}
foreach ($pattern in @('Stale state detected', 'boundary mismatch', 're-anchor', 'create a new feature', 'manually fix state')) {
    if ($staleOutput -notmatch $pattern) {
        Write-Fail ("Stale-state output did not include expected pattern '{0}'." -f $pattern)
        exit 1
    }
}

Write-Pass 'Stale-state detection catches cross-file corruption after boundary sync'
exit 0
