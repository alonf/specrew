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

function Invoke-EntryPoint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$Arguments,

        [AllowNull()]
        [string]$WorkingDirectory,

        [int]$ExpectedExitCode = 0,

        [AllowNull()]
        [string]$OutputPattern
    )

    if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        $WorkingDirectory = $repoRoot
    }

    $escapedScriptPath = $ScriptPath.Replace("'", "''")
    $escapedDotNetRoot = $dotNetRoot.Replace("'", "''")
    $escapedWorkingDir = $WorkingDirectory.Replace("'", "''")
    $command = @"
`$ErrorActionPreference = 'Stop'
[Environment]::CurrentDirectory = '$escapedDotNetRoot'
Set-Location -Path '$escapedWorkingDir'
if ((Get-Location).Path -eq [Environment]::CurrentDirectory) {
    throw 'Regression setup failed: PowerShell location matches .NET CurrentDirectory.'
}
& '$escapedScriptPath' $Arguments
"@

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -Command $command 2>&1)
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne $ExpectedExitCode) {
        Write-Fail ("{0} exited with code {1}. Output:`n{2}" -f $Label, $exitCode, ($output -join [Environment]::NewLine))
        $script:allChecksPassed = $false
        return
    }

    $outputText = $output -join [Environment]::NewLine
    if (-not [string]::IsNullOrWhiteSpace($OutputPattern) -and ($outputText -notmatch $OutputPattern)) {
        Write-Fail ("{0} did not emit expected output pattern '{1}'. Output:`n{2}" -f $Label, $OutputPattern, $outputText)
        $script:allChecksPassed = $false
        return
    }

    Write-Pass ("{0} resolved against PowerShell working directory." -f $Label)
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$scratchRoot = Join-Path $repoRoot '.scratch\project-path-resolution-regression'
$dotNetRoot = Join-Path $scratchRoot 'dotnet-root'
$fixtureRoot = Join-Path $scratchRoot 'fixture-project'
$initFixtureRoot = Join-Path $scratchRoot 'init-project'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -Path $dotNetRoot -ItemType Directory -Force
$null = New-Item -Path $fixtureRoot -ItemType Directory -Force
$null = New-Item -Path $initFixtureRoot -ItemType Directory -Force

$fixtureItems = @('.specrew', '.specify', '.squad', '.github', 'specs')
foreach ($item in $fixtureItems) {
    $source = Join-Path $repoRoot $item
    if (Test-Path -LiteralPath $source) {
        Copy-Item -LiteralPath $source -Destination $fixtureRoot -Recurse -Force
    }
}

$requiredFixturePaths = @(
    '.specrew\config.yml',
    '.specify',
    '.squad',
    '.github\agents\squad.agent.md'
)
foreach ($relativePath in $requiredFixturePaths) {
    $targetPath = Join-Path $fixtureRoot $relativePath
    if (Test-Path -LiteralPath $targetPath) {
        continue
    }

    $parent = Split-Path -Parent $targetPath
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -Path $parent -ItemType Directory -Force | Out-Null
    }

    if ($relativePath -like '*.md' -or $relativePath -like '*.yml') {
        New-Item -Path $targetPath -ItemType File -Force | Out-Null
    }
    else {
        New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
    }
}

$allChecksPassed = $true

$entryPointCases = @(
    @{
        Label = 'specrew start --no-launch (default path)'
        ScriptPath = Join-Path $repoRoot 'scripts\specrew-start.ps1'
        Arguments = '-NoLaunch'
        WorkingDirectory = $fixtureRoot
        ExpectedExitCode = 0
        OutputPattern = [regex]::Escape($fixtureRoot)
    }
    @{
        Label = 'specrew init --dry-run (default path)'
        ScriptPath = Join-Path $repoRoot 'scripts\specrew-init.ps1'
        Arguments = '-DryRun'
        WorkingDirectory = $initFixtureRoot
        ExpectedExitCode = 0
        OutputPattern = [regex]::Escape($initFixtureRoot)
    }
    @{
        Label = 'specrew update --info (default path)'
        ScriptPath = Join-Path $repoRoot 'scripts\specrew-update.ps1'
        Arguments = '-InfoMode'
        ExpectedExitCode = 0
        OutputPattern = [regex]::Escape("Version info for $repoRoot")
    }
    @{
        Label = 'specrew team list (-ProjectPath .)'
        ScriptPath = Join-Path $repoRoot 'scripts\specrew-team.ps1'
        Arguments = "list -ProjectPath '.'"
        ExpectedExitCode = 0
        OutputPattern = 'Squad Team Members'
    }
    @{
        Label = 'specrew review (-ProjectPath .)'
        ScriptPath = Join-Path $repoRoot 'scripts\specrew-review.ps1'
        Arguments = "-ProjectPath '.' -FeatureId '001-specrew-product' -IterationNumber '012' -Json"
        ExpectedExitCode = 0
        OutputPattern = '"feature"'
    }
)

foreach ($case in $entryPointCases) {
    if (-not (Test-Path -LiteralPath $case.ScriptPath -PathType Leaf)) {
        Write-Fail ("Missing required entry-point script for regression coverage: {0}" -f $case.ScriptPath)
        $allChecksPassed = $false
        continue
    }

    Invoke-EntryPoint @case
}

$scanTargets = @(
    (Join-Path $repoRoot 'scripts\specrew-start.ps1'),
    (Join-Path $repoRoot 'scripts\specrew-update.ps1'),
    (Join-Path $repoRoot 'scripts\specrew-init.ps1'),
    (Join-Path $repoRoot 'scripts\specrew-team.ps1'),
    (Join-Path $repoRoot 'scripts\specrew-review.ps1'),
    (Join-Path $repoRoot 'tests\manual\copilot-squad-smoke.ps1'),
    (Join-Path $repoRoot 'tests\manual\copilot-squad-confidence-lane.ps1'),
    (Join-Path $repoRoot 'tests\support\process-quality-scorer.ps1'),
    (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\brownfield-merge.ps1'),
    (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-speckit-extension.ps1'),
    (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'),
    (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\drift-diff.ps1'),
    (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\resolve-quality-profile.ps1'),
    (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\run-hardening-gate.ps1'),
    (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\run-mechanical-checks.ps1'),
    (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-governance.ps1'),
    (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-iteration-plan.ps1'),
    (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'),
    (Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\brownfield-merge.ps1'),
    (Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\deploy-speckit-extension.ps1'),
    (Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'),
    (Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\drift-diff.ps1'),
    (Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\resolve-quality-profile.ps1'),
    (Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\run-hardening-gate.ps1'),
    (Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\run-mechanical-checks.ps1'),
    (Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\scaffold-governance.ps1'),
    (Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\scaffold-iteration-plan.ps1'),
    (Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\validate-governance.ps1')
)

$antiPattern = '\[System\.IO\.Path\]::GetFullPath\(\s*\$(ProjectPath|FeaturePath|SpecPath|IterationPath|DispositionPath)\s*\)'
$findings = New-Object System.Collections.Generic.List[string]

foreach ($target in $scanTargets) {
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        Write-Fail ("Static scan missing expected file: {0}" -f $target)
        $allChecksPassed = $false
        continue
    }

    foreach ($match in @(Select-String -LiteralPath $target -Pattern $antiPattern)) {
        $findings.Add(("{0}:{1} {2}" -f $match.Path, $match.LineNumber, $match.Line.Trim()))
    }
}

if ($findings.Count -gt 0) {
    Write-Fail 'Static scan detected raw GetFullPath usage for user-supplied paths. Replace with Resolve-ProjectPath.'
    foreach ($finding in $findings) {
        Write-Host ("  - {0}" -f $finding) -ForegroundColor Red
    }
    $allChecksPassed = $false
}
else {
    Write-Pass 'Static scan found no raw GetFullPath usage for audited path parameters.'
}

if (-not $allChecksPassed) {
    exit 1
}

Write-Pass 'Project path resolution regression checks passed.'
exit 0
