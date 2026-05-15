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

function Normalize-ExpectedText {
    param([Parameter(Mandatory = $true)][string]$Text)

    return (($Text -replace 'Today: \d{4}-\d{2}-\d{2}', 'Today: <today>') -replace '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', '<timestamp>' -replace '\r', '').Trim()
}

function Get-FileHashValue {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Copy-WorkspaceRendererSupport {
    param([Parameter(Mandatory = $true)][string]$Workspace)

    $workspaceRenderer = Join-Path $Workspace 'scripts\internal\dashboard-renderer.ps1'
    $workspaceShared = Join-Path $Workspace 'extensions\specrew-speckit\scripts\shared-governance.ps1'
    $workspaceRendererDir = Split-Path -Parent $workspaceRenderer
    $workspaceSharedDir = Split-Path -Parent $workspaceShared
    $null = New-Item -ItemType Directory -Path $workspaceRendererDir -Force
    $null = New-Item -ItemType Directory -Path $workspaceSharedDir -Force
    Copy-Item -LiteralPath $rendererPath -Destination $workspaceRenderer -Force
    Copy-Item -LiteralPath $sharedGovernancePath -Destination $workspaceShared -Force
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\feature-018-dashboard'
$scratchRoot = Join-Path $repoRoot '.scratch\feature-018-dashboard'
$entryScript = Join-Path $repoRoot 'scripts\specrew.ps1'
$rendererPath = Join-Path $repoRoot 'scripts\internal\dashboard-renderer.ps1'
$reviewerScaffoldScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1'
$featureCloseoutScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-feature-closeout-dashboard.ps1'
$validatorScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'

. $rendererPath

$richOverride = @{
    IsWindows               = $false
    OutputRedirected        = $false
    Term                    = 'xterm-256color'
    ConsoleEncodingName     = 'utf-8'
    Lang                    = 'en_US.UTF-8'
    SupportsVirtualTerminal = $true
}

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

try {
    $null = New-Item -ItemType Directory -Path $scratchRoot -Force

    $richWorkspace = New-TestWorkspace -FixtureName 'rich-capable-repository' -WorkspaceName 'rich-capable-repository'
    $richSnapshot = Get-SpecrewDashboardSnapshot -ProjectRoot $richWorkspace -CapabilityOverrides $richOverride
    $richActual = Normalize-ExpectedText -Text ((ConvertTo-SpecrewDashboardLines -Snapshot $richSnapshot) -join "`n")
    $richExpected = Normalize-ExpectedText -Text (Get-Content -LiteralPath (Join-Path $fixtureRoot 'rich-capable-expected.txt') -Raw -Encoding UTF8)
    Assert-True -Condition ($richActual -eq $richExpected) -Message 'Rich-capable replay should match the expected rich dashboard contract.'
    Write-Pass 'Rich-capable replay matches the expected Unicode-rich dashboard contract'

    $monoWorkspace = New-TestWorkspace -FixtureName 'monochrome-repository' -WorkspaceName 'monochrome-repository'
    $monoResult = Invoke-CommandScript -ScriptPath $entryScript -ArgumentList @('where', '--project-path', $monoWorkspace, '--ASCII')
    Assert-True -Condition ($monoResult.ExitCode -eq 0) -Message 'Monochrome fallback replay should succeed.'
    $monoActual = Normalize-ExpectedText -Text $monoResult.Text
    $monoExpected = Normalize-ExpectedText -Text (Get-Content -LiteralPath (Join-Path $fixtureRoot 'monochrome-expected.txt') -Raw -Encoding UTF8)
    Assert-True -Condition ($monoActual -eq $monoExpected) -Message 'Monochrome fallback replay should match the expected ASCII-safe contract.'
    Assert-True -Condition ($monoResult.Text -notmatch ([char]27 + '\[[0-9;]*[A-Za-z]')) -Message 'Monochrome fallback output should remain ANSI-free.'
    Assert-True -Condition ($monoResult.Text -notmatch '[▁▂▃▄▅▆▇█]') -Message 'The monochrome fallback should not emit the rich sparkline glyph set.'
    Write-Pass 'Monochrome replay stays semantically stable and ANSI-free'

    $closeoutWorkspace = New-TestWorkspace -FixtureName 'closeout-repository' -WorkspaceName 'closeout-repository'
    Copy-WorkspaceRendererSupport -Workspace $closeoutWorkspace
    $iterationDirectory = Join-Path $closeoutWorkspace 'specs\018-velocity-dashboard-visual-richness\iterations\001'

    $iterationScaffold = Invoke-CommandScript -ScriptPath $reviewerScaffoldScript -ArgumentList @('-IterationDirectory', $iterationDirectory)
    Assert-True -Condition ($iterationScaffold.ExitCode -eq 0) -Message 'Iteration closeout scaffold should succeed for Feature 018.'
    $iterationDashboardPath = Join-Path $iterationDirectory 'dashboard.md'
    Assert-True -Condition (Test-Path -LiteralPath $iterationDashboardPath -PathType Leaf) -Message 'Iteration closeout scaffold should create dashboard.md.'
    $iterationDashboardText = Get-Content -LiteralPath $iterationDashboardPath -Raw -Encoding UTF8
    Assert-True -Condition ($iterationDashboardText -notmatch ([char]27 + '\[[0-9;]*[A-Za-z]')) -Message 'Iteration dashboard artifacts should strip ANSI.'
    Assert-True -Condition ($iterationDashboardText -match '✓|ℹ') -Message 'Iteration dashboard artifacts should preserve Unicode glyphs.'
    $iterationHash = Get-FileHashValue -Path $iterationDashboardPath
    $iterationScaffoldRepeat = Invoke-CommandScript -ScriptPath $reviewerScaffoldScript -ArgumentList @('-IterationDirectory', $iterationDirectory)
    Assert-True -Condition ($iterationScaffoldRepeat.ExitCode -eq 0) -Message 'Repeat iteration closeout scaffold should succeed.'
    Assert-True -Condition ($iterationHash -eq (Get-FileHashValue -Path $iterationDashboardPath)) -Message 'Iteration dashboard artifacts should remain immutable on repeat.'

    $featureScaffold = Invoke-CommandScript -ScriptPath $featureCloseoutScript -ArgumentList @('-ProjectPath', $closeoutWorkspace, '-FeatureId', '018-velocity-dashboard-visual-richness')
    Assert-True -Condition ($featureScaffold.ExitCode -eq 0) -Message 'Feature closeout scaffold should succeed for Feature 018.'
    $featureDashboardPath = Join-Path $closeoutWorkspace 'specs\018-velocity-dashboard-visual-richness\closeout-dashboard.md'
    Assert-True -Condition (Test-Path -LiteralPath $featureDashboardPath -PathType Leaf) -Message 'Feature closeout scaffold should create closeout-dashboard.md.'
    $featureDashboardText = Get-Content -LiteralPath $featureDashboardPath -Raw -Encoding UTF8
    Assert-True -Condition ($featureDashboardText -notmatch ([char]27 + '\[[0-9;]*[A-Za-z]')) -Message 'Feature closeout artifacts should strip ANSI.'
    Assert-True -Condition ($featureDashboardText -match '✓|ℹ') -Message 'Feature closeout artifacts should preserve Unicode glyphs.'
    $featureHash = Get-FileHashValue -Path $featureDashboardPath
    $featureScaffoldRepeat = Invoke-CommandScript -ScriptPath $featureCloseoutScript -ArgumentList @('-ProjectPath', $closeoutWorkspace, '-FeatureId', '018-velocity-dashboard-visual-richness')
    Assert-True -Condition ($featureScaffoldRepeat.ExitCode -eq 0) -Message 'Repeat feature closeout scaffold should succeed.'
    Assert-True -Condition ($featureHash -eq (Get-FileHashValue -Path $featureDashboardPath)) -Message 'Feature closeout dashboard should remain immutable on repeat.'

    Write-Pass 'Closeout scaffolds preserve artifact parity and Unicode-safe snapshot encoding'
}
finally {
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force
    }
}

Write-Pass 'Feature 018 integration coverage: rich replay, monochrome fallback, closeout artifact parity, and Unicode-preserving snapshot encoding'
exit 0
