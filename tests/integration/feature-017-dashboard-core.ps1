[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        Write-Fail $Message
        exit 1
    }
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    Assert-True -Condition ($Text -match $Pattern) -Message $Message
}

function New-TestWorkspace {
    param(
        [Parameter(Mandatory = $true)][string]$FixtureName,
        [Parameter(Mandatory = $true)][string]$WorkspaceName
    )

    $source = Join-Path $fixtureRoot $FixtureName
    $destination = Join-Path $scratchRoot $WorkspaceName
    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Recurse -Force
    }

    $null = New-Item -ItemType Directory -Path $destination -Force
    foreach ($item in Get-ChildItem -LiteralPath $source -Force) {
        Copy-Item -LiteralPath $item.FullName -Destination $destination -Recurse -Force
    }

    return $destination
}

function Invoke-CommandScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Text     = ($output -join "`n")
        Lines    = @($output | ForEach-Object { [string]$_ })
    }
}

function Normalize-DashboardText {
    param([Parameter(Mandatory = $true)][string]$Text)

    return (($Text -replace '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', '<timestamp>') -replace '\r', '').Trim()
}

function Get-FileHashValue {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\feature-017-dashboard'
$scratchRoot = Join-Path $repoRoot '.scratch\feature-017-dashboard'
$entryScript = Join-Path $repoRoot 'scripts\specrew.ps1'
$whereScript = Join-Path $repoRoot 'scripts\specrew-where.ps1'
$reviewerScaffoldScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1'
$featureCloseoutScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-feature-closeout-dashboard.ps1'
$validatorScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

try {
    $null = New-Item -ItemType Directory -Path $scratchRoot -Force

    $healthyWorkspace = New-TestWorkspace -FixtureName 'healthy-repository' -WorkspaceName 'healthy'
    $healthyWhere = Invoke-CommandScript -ScriptPath $entryScript -ArgumentList @('where', '--project-path', $healthyWorkspace, '--no-color')
    Assert-True -Condition ($healthyWhere.ExitCode -eq 0) -Message 'Healthy fixture: specrew where should succeed.'
    foreach ($heading in @('ACTIVE WORK', 'VELOCITY', 'RECENT SHIPPED', 'ROADMAP', 'PROJECTION')) {
        Assert-Contains -Text $healthyWhere.Text -Pattern ([regex]::Escape($heading)) -Message "Healthy fixture: missing heading '$heading'."
    }
    Write-Pass 'Healthy fixture renders the canonical dashboard sections'

    $healthyStatus = Invoke-CommandScript -ScriptPath $entryScript -ArgumentList @('status', '--project-path', $healthyWorkspace, '--no-color')
    Assert-True -Condition ($healthyStatus.ExitCode -eq 0) -Message 'Healthy fixture: specrew status should succeed.'
    Assert-True -Condition ((Normalize-DashboardText -Text $healthyStatus.Text) -eq (Normalize-DashboardText -Text $healthyWhere.Text)) -Message 'Healthy fixture: specrew status should match specrew where exactly.'
    Write-Pass 'Status alias matches the canonical where output'

    $healthyDirect = Invoke-CommandScript -ScriptPath $whereScript -ArgumentList @('--project-path', $healthyWorkspace, '--no-color')
    Assert-True -Condition ($healthyDirect.ExitCode -eq 0) -Message 'Healthy fixture: dedicated script entry point should succeed.'
    Assert-True -Condition ((Normalize-DashboardText -Text $healthyDirect.Text) -eq (Normalize-DashboardText -Text $healthyWhere.Text)) -Message 'Healthy fixture: specrew-where.ps1 should match specrew where exactly.'
    Write-Pass 'Dedicated dashboard entry point matches the CLI dispatcher'

    $healthyCompact = Invoke-CommandScript -ScriptPath $entryScript -ArgumentList @('where', '--project-path', $healthyWorkspace, '--compact', '--no-color')
    Assert-True -Condition ($healthyCompact.ExitCode -eq 0) -Message 'Healthy fixture: compact dashboard should succeed.'
    Assert-True -Condition ($healthyCompact.Lines.Count -le 24) -Message 'Healthy fixture: compact dashboard exceeded the 24-line budget.'
    Write-Pass 'Compact mode stays within the 24-line budget'

    $healthyTeam = Invoke-CommandScript -ScriptPath $entryScript -ArgumentList @('where', '--project-path', $healthyWorkspace, '--team', '--no-color')
    Assert-True -Condition ($healthyTeam.ExitCode -eq 0) -Message 'Healthy fixture: --team fallback should succeed.'
    Assert-Contains -Text $healthyTeam.Text -Pattern 'Team mode is reserved' -Message 'Healthy fixture: --team did not explain the fallback.'
    Write-Pass 'Team fallback explains the limitation and still renders the dashboard'

    $sparseWorkspace = New-TestWorkspace -FixtureName 'sparse-repository' -WorkspaceName 'sparse'
    $sparseResult = Invoke-CommandScript -ScriptPath $entryScript -ArgumentList @('where', '--project-path', $sparseWorkspace, '--no-color')
    Assert-True -Condition ($sparseResult.ExitCode -eq 0) -Message 'Sparse fixture: dashboard should succeed.'
    Assert-Contains -Text $sparseResult.Text -Pattern 'confidence remains low until 4\+ iterations are available' -Message 'Sparse fixture: low-confidence warning missing.'
    Write-Pass 'Sparse history fixture emits reduced-confidence guidance'

    $malformedWorkspace = New-TestWorkspace -FixtureName 'malformed-repository' -WorkspaceName 'malformed'
    $malformedResult = Invoke-CommandScript -ScriptPath $entryScript -ArgumentList @('where', '--project-path', $malformedWorkspace, '--no-color')
    Assert-True -Condition ($malformedResult.ExitCode -eq 0) -Message 'Malformed fixture: dashboard should degrade gracefully instead of failing.'
    Assert-Contains -Text $malformedResult.Text -Pattern 'roadmap\.yml does not declare any phases|Ignoring roadmap content outside phases list' -Message 'Malformed fixture: roadmap warning missing.'
    Write-Pass 'Malformed roadmap fixture degrades with bounded warnings'

    $noRoadmapWorkspace = New-TestWorkspace -FixtureName 'no-roadmap-repository' -WorkspaceName 'no-roadmap'
    $noRoadmapResult = Invoke-CommandScript -ScriptPath $entryScript -ArgumentList @('where', '--project-path', $noRoadmapWorkspace, '--no-color')
    Assert-True -Condition ($noRoadmapResult.ExitCode -eq 0) -Message 'No-roadmap fixture: dashboard should succeed.'
    Assert-Contains -Text $noRoadmapResult.Text -Pattern 'No \.specrew/roadmap\.yml file found.*docs/roadmap-maintenance\.md' -Message 'No-roadmap fixture: setup guidance missing.'
    Write-Pass 'No-roadmap fixture preserves other sections and emits setup guidance'

    $closeoutWorkspace = New-TestWorkspace -FixtureName 'closeout-repository' -WorkspaceName 'closeout'
    $closeoutIterationDirectory = Join-Path $closeoutWorkspace 'specs\017-velocity-dashboard\iterations\002'
    $validatorMissing = Invoke-CommandScript -ScriptPath $validatorScript -ArgumentList @('-ProjectPath', $closeoutWorkspace, '-IterationPath', $closeoutIterationDirectory)
    Assert-True -Condition ($validatorMissing.ExitCode -eq 0) -Message 'Closeout fixture: validator should run without failing.'
    Assert-Contains -Text $validatorMissing.Text -Pattern "Closed iteration '017-velocity-dashboard 002' is missing dashboard\.md" -Message 'Closeout fixture: missing dashboard artifact warning for iteration 002 expected.'
    Assert-Contains -Text $validatorMissing.Text -Pattern "Closed feature '017-velocity-dashboard' is missing closeout-dashboard\.md" -Message 'Closeout fixture: missing feature closeout dashboard warning expected.'
    Assert-True -Condition ($validatorMissing.Text -notmatch "017-velocity-dashboard 001") -Message 'Closeout fixture: pre-rollout iteration should be grandfathered.'
    Write-Pass 'Validator grandfathering honors pre-rollout dashboard artifacts'

    $closeoutScaffold = Invoke-CommandScript -ScriptPath $reviewerScaffoldScript -ArgumentList @('-IterationDirectory', $closeoutIterationDirectory)
    Assert-True -Condition ($closeoutScaffold.ExitCode -eq 0) -Message 'Closeout fixture: reviewer artifact scaffold should succeed.'
    $iterationDashboardPath = Join-Path $closeoutIterationDirectory 'dashboard.md'
    Assert-True -Condition (Test-Path -LiteralPath $iterationDashboardPath -PathType Leaf) -Message 'Closeout fixture: iteration dashboard snapshot should be created.'
    $iterationDashboardText = Get-Content -LiteralPath $iterationDashboardPath -Raw -Encoding UTF8
    Assert-Contains -Text $iterationDashboardText -Pattern 'Historical snapshot captured during iteration closeout' -Message 'Closeout fixture: iteration snapshot should include historical notice.'
    $iterationHash = Get-FileHashValue -Path $iterationDashboardPath
    $closeoutScaffoldRepeat = Invoke-CommandScript -ScriptPath $reviewerScaffoldScript -ArgumentList @('-IterationDirectory', $closeoutIterationDirectory)
    Assert-True -Condition ($closeoutScaffoldRepeat.ExitCode -eq 0) -Message 'Closeout fixture: repeat reviewer scaffold should succeed.'
    $iterationHashRepeat = Get-FileHashValue -Path $iterationDashboardPath
    Assert-True -Condition ($iterationHash -eq $iterationHashRepeat) -Message 'Closeout fixture: iteration dashboard snapshot should remain immutable.'
    Write-Pass 'Iteration closeout scaffold writes and preserves the dashboard snapshot'

    $featureCloseout = Invoke-CommandScript -ScriptPath $featureCloseoutScript -ArgumentList @('-ProjectPath', $closeoutWorkspace, '-FeatureId', '017-velocity-dashboard')
    Assert-True -Condition ($featureCloseout.ExitCode -eq 0) -Message 'Closeout fixture: feature closeout dashboard scaffold should succeed.'
    $featureDashboardPath = Join-Path $closeoutWorkspace 'specs\017-velocity-dashboard\closeout-dashboard.md'
    Assert-True -Condition (Test-Path -LiteralPath $featureDashboardPath -PathType Leaf) -Message 'Closeout fixture: feature closeout dashboard snapshot should be created.'
    $featureDashboardText = Get-Content -LiteralPath $featureDashboardPath -Raw -Encoding UTF8
    Assert-Contains -Text $featureDashboardText -Pattern 'Historical snapshot captured during feature closeout' -Message 'Closeout fixture: feature snapshot should include historical notice.'
    $featureHash = Get-FileHashValue -Path $featureDashboardPath
    $featureCloseoutRepeat = Invoke-CommandScript -ScriptPath $featureCloseoutScript -ArgumentList @('-ProjectPath', $closeoutWorkspace, '-FeatureId', '017-velocity-dashboard')
    Assert-True -Condition ($featureCloseoutRepeat.ExitCode -eq 0) -Message 'Closeout fixture: repeat feature closeout scaffold should succeed.'
    $featureHashRepeat = Get-FileHashValue -Path $featureDashboardPath
    Assert-True -Condition ($featureHash -eq $featureHashRepeat) -Message 'Closeout fixture: feature closeout snapshot should remain immutable.'
    Write-Pass 'Feature closeout scaffold writes and preserves the dashboard snapshot'

    $validatorPost = Invoke-CommandScript -ScriptPath $validatorScript -ArgumentList @('-ProjectPath', $closeoutWorkspace, '-IterationPath', $closeoutIterationDirectory)
    Assert-True -Condition ($validatorPost.ExitCode -eq 0) -Message 'Closeout fixture: validator should run after snapshots are created.'
    Assert-True -Condition ($validatorPost.Text -notmatch 'missing-dashboard-artifact') -Message 'Closeout fixture: missing-dashboard warnings should clear after snapshots are generated.'
    Write-Pass 'Validator clears missing-dashboard warnings once snapshots exist'
}
finally {
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force
    }
}

Write-Pass 'Feature 017 dashboard integration coverage: command parity, compact mode, team fallback, sparse history, malformed roadmap, and no-roadmap guidance'
exit 0
