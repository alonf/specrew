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
$initScript = Join-Path $repoRoot 'scripts\specrew-init.ps1'
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$taskProgressHelperPath = Join-Path $repoRoot 'scripts\internal\task-progress.ps1'
. $taskProgressHelperPath

$scratchRoot = Join-Path $repoRoot '.scratch\task-progress-tracking'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$projectRoot = Join-Path $scratchRoot 'project'
$featureRoot = Join-Path $projectRoot 'specs\020-session-state-durability'
$iterationRoot = Join-Path $featureRoot 'iterations\002'
$null = New-Item -ItemType Directory -Path $projectRoot -Force
$null = & git -C $projectRoot init --quiet 2>&1
$null = & git -C $projectRoot config user.email 'test@specrew.local' 2>&1
$null = & git -C $projectRoot config user.name 'Test User' 2>&1

$initResult = Invoke-TestScript -ScriptPath $initScript -ArgumentList @('-ProjectPath', $projectRoot, '-Force', '-NoAgents', '-SkipUpdateCheck')
if ($initResult.ExitCode -ne 0) {
    Write-Fail ("Bootstrap failed:`n{0}" -f ($initResult.Output -join [Environment]::NewLine))
    exit 1
}

$null = New-Item -ItemType Directory -Path $iterationRoot -Force
Copy-Item -LiteralPath (Join-Path $repoRoot 'specs\020-session-state-durability\iterations\002\plan.md') -Destination (Join-Path $iterationRoot 'plan.md') -Force
Copy-Item -LiteralPath (Join-Path $repoRoot 'specs\020-session-state-durability\tasks.md') -Destination (Join-Path $featureRoot 'tasks.md') -Force
[System.IO.File]::WriteAllText((Join-Path $featureRoot 'spec.md'), "# Feature 020`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/020-session-state-durability`"`n}", [System.Text.UTF8Encoding]::new($false))

$progressResult = Set-TaskStatus -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' -TaskId 'I2-T001' -Status 'in-progress'
if ([string]::IsNullOrWhiteSpace([string]$progressResult.StartedAt)) {
    Write-Fail 'In-progress transition did not record started_at.'
    exit 1
}
Write-Pass 'In-progress transition records started_at'

$completeResult = Set-TaskComplete -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' -TaskId 'I2-T001'
if ([string]::IsNullOrWhiteSpace([string]$completeResult.CompletedAt)) {
    Write-Fail 'Complete transition did not record completed_at.'
    exit 1
}
Write-Pass 'Complete transition records completed_at'

$blockedWithoutReasonFailed = $false
try {
    Set-TaskStatus -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' -TaskId 'I2-T002' -Status 'blocked' | Out-Null
}
catch {
    $blockedWithoutReasonFailed = $true
}

if (-not $blockedWithoutReasonFailed) {
    Write-Fail 'Blocked transition should require a blocked_reason.'
    exit 1
}
Write-Pass 'Blocked transition requires blocked_reason'

$blockedResult = Set-TaskBlocked -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' -TaskId 'I2-T002' -Reason 'Waiting for approval'
if ($blockedResult.BlockedReason -ne 'Waiting for approval') {
    Write-Fail 'Blocked transition did not persist blocked_reason.'
    exit 1
}
Write-Pass 'Blocked transition persists blocked_reason'

[System.IO.File]::WriteAllText((Join-Path $featureRoot 'tasks.md'), "# Regenerated task list`n", [System.Text.UTF8Encoding]::new($false))
$summary = Get-TaskProgressSummary -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002'
if (@($summary.Complete | Where-Object { $_.id -eq 'I2-T001' }).Count -ne 1) {
    Write-Fail 'Task progress did not survive tasks.md regeneration.'
    exit 1
}
Write-Pass 'Task progress survives tasks.md regeneration'

$validatorSummaryPath = Join-Path $projectRoot '.specrew\last-validator-summary.json'
[System.IO.File]::WriteAllText($validatorSummaryPath, @'
{
  "recorded_at": "2026-05-18T00:00:00Z",
  "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File .\\extensions\\specrew-speckit\\scripts\\validate-governance.ps1 -ProjectPath . -IterationPath .\\specs\\020-session-state-durability\\iterations\\002",
  "warnings": {
    "total": 1,
    "soft": 1,
    "medium": 0,
    "hard": 0
  }
}
'@, [System.Text.UTF8Encoding]::new($false))
Set-TaskStatus -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' -TaskId 'I2-T003' -Status 'in-progress' | Out-Null

$startResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $projectRoot, '-NoLaunch', '-SkipUpdateCheck')
if ($startResult.ExitCode -ne 0) {
    Write-Fail ("Start command failed:`n{0}" -f ($startResult.Output -join [Environment]::NewLine))
    exit 1
}

$promptContent = Get-Content -LiteralPath (Join-Path $projectRoot '.specrew\last-start-prompt.md') -Raw -Encoding UTF8
foreach ($pattern in @('## Welcome Back Snapshot', 'I2-T003', 'Task progress: 1 complete, 1 in-progress', 'Validator state: 1 warnings: 1 soft, 0 medium, 0 hard', 'Suggested Next Actions')) {
    if ($promptContent -notmatch [regex]::Escape($pattern)) {
        Write-Fail ("Welcome-back prompt is missing expected pattern '{0}'." -f $pattern)
        exit 1
    }
}
Write-Pass 'Welcome-back prompt includes task progress and validator summary'

exit 0
