# specrew-test-home: not-a-writer - runs init -DryRun and update -InfoMode only, which stop before the deploy step (census 2026-11-11, docs/beta5-findings.md B5F-039)
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 206, iteration 002 (T024): iteration 001 made this script refuse to run after supervised runs 3 and 4 wrote
# into the repository that holds it (bug list items 23, 24 and 25). T023 keeps `specrew start` inside -ProjectPath,
# T025 runs init's Squad probe in a temp folder, and this script's fixture is what a fresh checkout holds.

# `specrew start` writes the user profile when it is missing (scripts/specrew-start.ps1). This script points
# that write at a temp file itself, so it never writes the real home folder and never relies on the shell
# that runs it (maintainer ruling 2026-11-12, feature 206 T015).
$env:SPECREW_USER_PROFILE_PATH = Join-Path ([IO.Path]::GetTempPath()) ('specrew-test-profile-' + [guid]::NewGuid().ToString('N') + '.yml')

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Set-Sc001FixtureIdentityRelative {
    # Feature 206, round 1 F2: the copied identity file may hold the absolute feature path of the machine that wrote
    # it, which exists only there. Write it relative to the project, as T023 makes the boundary sync write it, or
    # (none) when it points outside the repository the fixture was copied from.
    param(
        [Parameter(Mandatory = $true)][string]$IdentityPath,
        [Parameter(Mandatory = $true)][string]$SourceRoot
    )

    if (-not (Test-Path -LiteralPath $IdentityPath -PathType Leaf)) { return }
    $text = [IO.File]::ReadAllText($IdentityPath)
    $line = [regex]::Match($text, '(?m)^session_state_feature_path:[ \t]*(?<value>[^\r\n]*?)[ \t]*(?=\r?$)')
    if (-not $line.Success) { return }
    $value = $line.Groups['value'].Value.Trim().Trim('"')
    if ([string]::IsNullOrWhiteSpace($value) -or $value -eq '(none)' -or (Get-SpecrewPathRootKind -Path $value) -eq 'relative') { return }
    $relative = ConvertTo-SpecrewIdentityFeaturePath -ProjectRoot $SourceRoot -FeaturePath $value
    $text = $text.Substring(0, $line.Index) + ('session_state_feature_path: {0}' -f $relative) + $text.Substring($line.Index + $line.Length)
    [IO.File]::WriteAllText($IdentityPath, $text, [Text.UTF8Encoding]::new($false))
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
# Outside the repository, so nothing the entry points do in the fixture can reach this repository (feature 206, T015).
# Round 1 F6: each run has its own folder, so two runs at once cannot delete each other's fixture.
$scratchRoot = Join-Path ([IO.Path]::GetTempPath()) ('specrew-project-path-resolution-regression-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
$dotNetRoot = Join-Path $scratchRoot 'dotnet-root'
$fixtureRoot = Join-Path $scratchRoot 'fixture-project'
$initFixtureRoot = Join-Path $scratchRoot 'init-project'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -Path $dotNetRoot -ItemType Directory -Force
$null = New-Item -Path $fixtureRoot -ItemType Directory -Force
$null = New-Item -Path $initFixtureRoot -ItemType Directory -Force

# Only the files git does not ignore, tracked or not, as a fresh checkout (or the review preflight's layout) has them:
# the working folders also hold the developer's ignored session state (last-start-prompt.md, start-context.json, the
# authority, review and runtime stores), and a stale prompt there made `specrew start` refuse, so the result depended
# on who ran it (feature 206, T015 for .specrew; T024 for every folder, bug list items 22, 24 and 29).
$fixtureItems = @('.specrew', '.specify', '.squad', '.github', 'specs')
foreach ($relative in @(& git -C $repoRoot -c core.quotepath=off ls-files --cached --others --exclude-standard -- $fixtureItems)) {
    if ([string]::IsNullOrWhiteSpace($relative)) {
        continue
    }
    $copySource = Join-Path $repoRoot $relative
    if (-not (Test-Path -LiteralPath $copySource -PathType Leaf)) {
        continue
    }
    $copyTarget = Join-Path $fixtureRoot $relative
    $null = New-Item -Path (Split-Path -Parent $copyTarget) -ItemType Directory -Force
    Copy-Item -LiteralPath $copySource -Destination $copyTarget -Force
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

# The fixture is its own git repository. Without one, git inside it resolved to the repository that holds it, and
# `specrew start` re-anchored to that repository's feature and wrote its real state.md (feature 206, T015).
# A fresh checkout of a feature has that feature's branch checked out (T024): name the fixture's branch after the
# feature the copied identity file names, so the start case meets a governed project as a collaborator receives it.
$fixtureIdentityPath = Join-Path $fixtureRoot '.squad\identity\now.md'
# Round 1 F2: the identity path the fixture carries is relative, as a fresh checkout after T023 has it.
. (Join-Path $repoRoot 'scripts\internal\sync-boundary-state.ps1')
Set-Sc001FixtureIdentityRelative -IdentityPath $fixtureIdentityPath -SourceRoot $repoRoot
$fixtureBranch = 'main'
if (Test-Path -LiteralPath $fixtureIdentityPath -PathType Leaf) {
    $identityFeature = [regex]::Match((Get-Content -LiteralPath $fixtureIdentityPath -Raw -Encoding UTF8), '(?m)^session_state_feature:\s*"?(?<ref>\d{3}-[A-Za-z0-9._-]+)"?\s*$')
    if ($identityFeature.Success) { $fixtureBranch = $identityFeature.Groups['ref'].Value }
}
$null = & git -C $fixtureRoot init --quiet --initial-branch=$fixtureBranch 2>&1
$null = & git -C $fixtureRoot add -A 2>&1
$null = & git -C $fixtureRoot -c user.name='SC-001 Fixture' -c user.email='sc001-fixture@example.invalid' -c commit.gpgsign=false commit --quiet -m 'SC-001 fixture' 2>&1
$fixtureTopLevel = [string](& git -C $fixtureRoot rev-parse --show-toplevel 2>$null)
$fixtureTopLevelFull = if ([string]::IsNullOrWhiteSpace($fixtureTopLevel)) { '' } else { [IO.Path]::GetFullPath($fixtureTopLevel.Trim()).TrimEnd('\', '/') }
if (-not [string]::Equals($fixtureTopLevelFull, [IO.Path]::GetFullPath($fixtureRoot).TrimEnd('\', '/'), [StringComparison]::OrdinalIgnoreCase)) {
    Write-Fail ("The fixture's git top level is '{0}', not the fixture '{1}': the run would not be isolated from the repository that holds it." -f $fixtureTopLevel, $fixtureRoot)
    exit 1
}

$allChecksPassed = $true

$entryPointCases = @(
    @{
        Label = 'specrew start --no-launch (default path)'
        ScriptPath = Join-Path $repoRoot 'scripts\specrew-start.ps1'
        # A fresh copy of a governed project has features but no session files. Since feature 206 T022 that is a
        # first start, so the case passes no recovery choice: it is SC-001's fresh checkout starting with no console.
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
        # Round 1 F9: run in the fixture, not in the repository that holds this script.
        WorkingDirectory = $fixtureRoot
        OutputPattern = [regex]::Escape("Version info for $fixtureRoot")
    }
    @{
        Label = 'specrew team list (-ProjectPath .)'
        ScriptPath = Join-Path $repoRoot 'scripts\specrew-team.ps1'
        Arguments = "list -ProjectPath '.'"
        # Round 1 F9: run in the fixture, not in the repository that holds this script.
        WorkingDirectory = $fixtureRoot
        ExpectedExitCode = 0
        OutputPattern = 'Squad Team Members'
    }
    @{
        Label = 'specrew review (-ProjectPath .)'
        ScriptPath = Join-Path $repoRoot 'scripts\specrew-review.ps1'
        Arguments = "-ProjectPath '.' -FeatureId '001-specrew-product' -IterationNumber '012' -Json"
        # Round 1 F9: run in the fixture, not in the repository that holds this script.
        WorkingDirectory = $fixtureRoot
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

# The fixtures and the profile file are this script's own temp folders; removed by their exact paths (T024).
if ((Split-Path -Leaf $scratchRoot) -like 'specrew-project-path-resolution-regression-*' -and (Test-Path -LiteralPath $scratchRoot)) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
}
if ((Split-Path -Leaf $env:SPECREW_USER_PROFILE_PATH) -like 'specrew-test-profile-*') {
    Remove-Item -LiteralPath $env:SPECREW_USER_PROFILE_PATH -Force -ErrorAction SilentlyContinue
}

if (-not $allChecksPassed) {
    exit 1
}

Write-Pass 'Project path resolution regression checks passed.'
exit 0
