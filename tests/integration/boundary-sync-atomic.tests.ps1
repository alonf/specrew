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
$env:SPECREW_MODULE_PATH = $repoRoot
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\boundary-sync-atomic'
$projectRoot = Join-Path $scratchRoot 'project'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $projectRoot -Force
$null = & git -C $projectRoot init --quiet 2>&1
$null = & git -C $projectRoot config user.email 'test@specrew.local' 2>&1
$null = & git -C $projectRoot config user.name 'Test User' 2>&1

foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', 'specs\046-046-bug-bash\iterations\001')) {
    $null = New-Item -ItemType Directory -Path (Join-Path $projectRoot $relativeDirectory) -Force
}

[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/046-046-bug-bash`"`n}", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'specs\046-046-bug-bash\spec.md'), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m 'Seed repository' --quiet 2>&1
$null = & git -C $projectRoot branch -M main 2>&1
$null = & git -C $projectRoot checkout -b 046-046-bug-bash 2>&1

$contextPath = Join-Path $projectRoot '.specrew\start-context.json'

# Let's seed start-context.json with boundary_enforcement schema v2
$seededContext = [ordered]@{
    schema = 'v2'
    feature_path = Join-Path $projectRoot 'specs\046-046-bug-bash'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    session_state = [ordered]@{
        active           = $true
        boundary_type    = 'before-implement'
        feature_ref      = '046-046-bug-bash'
        feature_path     = Join-Path $projectRoot 'specs\046-046-bug-bash'
        iteration_number = '001'
        task_id          = $null
        auth_commit_hash = 'SEEDHASH'
        recorded_at      = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    }
    boundary_enforcement = [ordered]@{
        enabled = $true
        last_authorized_boundary = 'before-implement'
        pending_next_boundary = $null
        verdict_history = @(
            [ordered]@{
                from_boundary = 'tasks'
                to_boundary = 'before-implement'
                verdict_text = 'approved for before-implement'
                authorizing_human = 'Test User'
                recorded_at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
                auth_commit_hash = 'SEEDHASH'
            }
        )
        bypass_history = @()
    }
}
[System.IO.File]::WriteAllText($contextPath, ($seededContext | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))

# Commit the context file
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m 'Seed start-context.json' --quiet 2>&1
$authCommit = (@(& git -C $projectRoot rev-parse HEAD 2>&1))[0].ToString().Trim()

# Run the boundary sync helper to sync to 'review-signoff'
$syncResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $projectRoot,
    '-BoundaryType', 'review-signoff',
    '-FeatureRef', '046-046-bug-bash',
    '-IterationNumber', '001',
    '-AuthCommitHash', $authCommit
)

if ($syncResult.ExitCode -ne 0) {
    Write-Fail ("Boundary sync to review-signoff failed:`n{0}" -f ($syncResult.Output -join [Environment]::NewLine))
    exit 1
}

# Verify both session_state and boundary_enforcement advanced in start-context.json
$context = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12

if ($context.session_state.boundary_type -ne 'review-signoff') {
    Write-Fail ("Cursor in session_state.boundary_type did not advance. Expected 'review-signoff', found '{0}'" -f $context.session_state.boundary_type)
    exit 1
}

if ($context.boundary_enforcement.last_authorized_boundary -ne 'review-signoff') {
    Write-Fail ("Audit trail in last_authorized_boundary did not advance. Expected 'review-signoff', found '{0}'" -f $context.boundary_enforcement.last_authorized_boundary)
    exit 1
}

$history = @($context.boundary_enforcement.verdict_history)
if ($history.Count -ne 2) {
    Write-Fail ("verdict_history did not append the new transition. Expected length 2, found {0}" -f $history.Count)
    exit 1
}

$newVerdict = $history[1]
if ($newVerdict.from_boundary -ne 'before-implement' -or $newVerdict.to_boundary -ne 'review-signoff') {
    Write-Fail ("verdict_history entry has incorrect transition boundaries. Found '{0}' -> '{1}'" -f $newVerdict.from_boundary, $newVerdict.to_boundary)
    exit 1
}

if ([string]::IsNullOrWhiteSpace($newVerdict.authorizing_human)) {
    Write-Fail "verdict_history entry is missing authorizing_human."
    exit 1
}

if ($newVerdict.auth_commit_hash -ne $authCommit) {
    Write-Fail ("verdict_history entry has wrong auth_commit_hash. Expected '{0}', found '{1}'" -f $authCommit, $newVerdict.auth_commit_hash)
    exit 1
}

Write-Pass 'Boundary sync atomically advanced cursor, last_authorized_boundary, and appended to verdict_history'
exit 0
