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
        Output   = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function New-MinimalProject {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
    $null = & git -C $ProjectRoot init --quiet 2>&1
    $null = & git -C $ProjectRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $ProjectRoot config user.name 'Test User' 2>&1

    foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', 'specs\022-hotfix-schema-tests\iterations\001')) {
        $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot $relativeDirectory) -Force
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/022-hotfix-schema-tests`"`n}", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'specs\022-hotfix-schema-tests\spec.md'), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))

    $null = & git -C $ProjectRoot add -A 2>&1
    $null = & git -C $ProjectRoot commit -m 'Seed project' --quiet 2>&1
    $null = & git -C $ProjectRoot branch -M main 2>&1
    $null = & git -C $ProjectRoot checkout -b 022-hotfix-schema-tests 2>&1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$closeoutScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-feature-closeout-dashboard.ps1'
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'

$scratchRoot = Join-Path $repoRoot '.scratch\closeout-identity-schema-parity'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$projectRoot = Join-Path $scratchRoot 'project'
New-MinimalProject -ProjectRoot $projectRoot

$closeoutResult = Invoke-TestScript -ScriptPath $closeoutScript -ArgumentList @('-ProjectPath', $projectRoot, '-FeatureId', '022-hotfix-schema-tests')
if ($closeoutResult.ExitCode -ne 0) {
    Write-Fail ("Feature closeout scaffold failed:`n{0}" -f ($closeoutResult.Output -join [Environment]::NewLine))
    exit 1
}

$identityPath = Join-Path $projectRoot '.squad\identity\now.md'
if (-not (Test-Path -LiteralPath $identityPath -PathType Leaf)) {
    Write-Fail "Closeout identity file was not created: $identityPath"
    exit 1
}

$identityContent = Get-Content -LiteralPath $identityPath -Raw -Encoding UTF8
foreach ($pattern in @(
        'focus_area:\s*"No active feature"',
        'active_issues:\s*"\[\]"',
        'session_state_active:\s*false',
        'session_state_boundary:\s*feature-closeout',
        'session_state_feature:\s*022-hotfix-schema-tests',
        'session_state_feature_path:\s*".*specs\\022-hotfix-schema-tests"',
        'session_state_auth_commit:\s*[0-9a-f]{40}',
        '# What We''re Focused On',
        'No active feature\. Last completed: Feature 022'
    )) {
    if ($identityContent -notmatch $pattern) {
        Write-Fail "Closeout identity output is missing expected content: $pattern"
        exit 1
    }
}

Write-Pass 'Closeout identity file preserves both machine-readable and human-readable state'

$startResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $projectRoot, '-NoLaunch')
if ($startResult.ExitCode -ne 0) {
    Write-Fail ("specrew start should accept closeout identity state without a special parser path:`n{0}" -f ($startResult.Output -join [Environment]::NewLine))
    exit 1
}

$contextPath = Join-Path $projectRoot '.specrew\start-context.json'
$context = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
if (-not $context.session_state -or $context.session_state.boundary_type -ne 'feature-closeout' -or $context.session_state.feature_ref -ne '022-hotfix-schema-tests' -or $context.session_state.active) {
    Write-Fail 'specrew start did not preserve the closeout session-state contract through the shared parser path.'
    exit 1
}

Write-Pass 'specrew start reuses the shared parser for closeout identity state'
exit 0
