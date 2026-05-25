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
$scratchRoot = Join-Path $repoRoot '.scratch\prose-alias-sync'
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

# Seeding start-context.json
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
}
[System.IO.File]::WriteAllText($contextPath, ($seededContext | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m 'Seed start-context.json' --quiet 2>&1

# Scenario 1: Prose alias mapping 'implement' -> 'review-signoff'
$syncResult1 = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $projectRoot,
    '-BoundaryType', 'implement',
    '-FeatureRef', '046-046-bug-bash',
    '-IterationNumber', '001',
    '-AuthCommitHash', 'HEAD'
)

if ($syncResult1.ExitCode -ne 0) {
    Write-Fail ("Prose alias 'implement' sync failed:`n{0}" -f ($syncResult1.Output -join [Environment]::NewLine))
    exit 1
}

$context1 = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
if ($context1.session_state.boundary_type -ne 'review-signoff') {
    Write-Fail ("Expected alias 'implement' to map to canonical 'review-signoff', found '{0}'" -f $context1.session_state.boundary_type)
    exit 1
}
Write-Pass "Scenario 1: Alias 'implement' successfully maps to canonical 'review-signoff'."

# Scenario 2: Prose alias mapping 'closeout' -> 'iteration-closeout'
# Seed start-context back to retro for sequencing
$context1.session_state.boundary_type = 'retro'
[System.IO.File]::WriteAllText($contextPath, ($context1 | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m 'Reset context' --quiet 2>&1

$syncResult2 = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $projectRoot,
    '-BoundaryType', 'closeout',
    '-FeatureRef', '046-046-bug-bash',
    '-IterationNumber', '001',
    '-AuthCommitHash', 'HEAD'
)

if ($syncResult2.ExitCode -ne 0) {
    Write-Fail ("Prose alias 'closeout' sync failed:`n{0}" -f ($syncResult2.Output -join [Environment]::NewLine))
    exit 1
}

$context2 = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
if ($context2.session_state.boundary_type -ne 'iteration-closeout') {
    Write-Fail ("Expected alias 'closeout' to map to canonical 'iteration-closeout', found '{0}'" -f $context2.session_state.boundary_type)
    exit 1
}
Write-Pass "Scenario 2: Alias 'closeout' successfully maps to canonical 'iteration-closeout'."


# Scenario 3: Unrecognized boundary with did-you-mean suggestion
$syncResult3 = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $projectRoot,
    '-BoundaryType', 'implem',
    '-FeatureRef', '046-046-bug-bash',
    '-IterationNumber', '001',
    '-AuthCommitHash', 'HEAD'
)

$output3 = $syncResult3.Output -join [Environment]::NewLine
if ($syncResult3.ExitCode -eq 0 -or $output3 -notmatch "Unrecognized boundary type" -or $output3 -notmatch "Did you mean") {
    Write-Fail "Sync with invalid boundary did not produce the expected suggestion error. Output:`n$output3"
    exit 1
}

Write-Pass "Scenario 3: Unrecognized boundary throws descriptive suggestion error."
exit 0
