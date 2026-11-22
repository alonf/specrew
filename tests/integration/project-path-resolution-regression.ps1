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

function Get-EntryPointCommand {
    # The child's command: .NET's current directory away from PowerShell's location, then the entry point.
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory
    )

    $escapedScriptPath = $ScriptPath.Replace("'", "''")
    $escapedDotNetRoot = $dotNetRoot.Replace("'", "''")
    $escapedWorkingDir = $WorkingDirectory.Replace("'", "''")
    return @"
`$ErrorActionPreference = 'Stop'
[Environment]::CurrentDirectory = '$escapedDotNetRoot'
Set-Location -Path '$escapedWorkingDir'
if ((Get-Location).Path -eq [Environment]::CurrentDirectory) {
    throw 'Regression setup failed: PowerShell location matches .NET CurrentDirectory.'
}
& '$escapedScriptPath' $Arguments
"@
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

    $command = Get-EntryPointCommand -ScriptPath $ScriptPath -Arguments $Arguments -WorkingDirectory $WorkingDirectory
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

function New-Sc001Fixture {
    # One copy of this repository as a collaborator's fresh checkout holds it, in its own git repository on the branch
    # of the feature the copied identity file names. Returns that feature, or $null when the identity names none.
    #
    # Feature 203, iteration 002 (the maintainer's "203 start test: fixture without its own claim, plus a case for the
    # claim decline", 01:50 local on 2026-11-22, relayed): `.squad/active-features.yml` is committed and holds the
    # claim on the fixture's own feature, with the developer's user@machine. Anyone else's start, CI's included, then
    # meets that claim and is declined, so the start case's result depended on who ran it. The fixture drops that one
    # claim through the claims helper; -ClaimedBy then records a claim by someone else, for the decline case.
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [AllowNull()][string]$ClaimedBy
    )

    $null = New-Item -Path $Root -ItemType Directory -Force

    # Only the files git does not ignore, tracked or not, as a fresh checkout (or the review preflight's layout) has
    # them: the working folders also hold the developer's ignored session state (last-start-prompt.md,
    # start-context.json, the authority, review and runtime stores), and a stale prompt there made `specrew start`
    # refuse, so the result depended on who ran it (feature 206, T015 for .specrew; T024 for every folder, bug list
    # items 22, 24 and 29).
    $fixtureItems = @('.specrew', '.specify', '.squad', '.github', 'specs')
    foreach ($relative in @(& git -C $repoRoot -c core.quotepath=off ls-files --cached --others --exclude-standard -- $fixtureItems)) {
        if ([string]::IsNullOrWhiteSpace($relative)) {
            continue
        }
        $copySource = Join-Path $repoRoot $relative
        if (-not (Test-Path -LiteralPath $copySource -PathType Leaf)) {
            continue
        }
        $copyTarget = Join-Path $Root $relative
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
        $targetPath = Join-Path $Root $relativePath
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
    $identityPath = Join-Path $Root '.squad\identity\now.md'
    # Round 1 F2: the identity path the fixture carries is relative, as a fresh checkout after T023 has it.
    Set-Sc001FixtureIdentityRelative -IdentityPath $identityPath -SourceRoot $repoRoot
    $feature = $null
    if (Test-Path -LiteralPath $identityPath -PathType Leaf) {
        $identityFeature = [regex]::Match((Get-Content -LiteralPath $identityPath -Raw -Encoding UTF8), '(?m)^session_state_feature:\s*"?(?<ref>\d{3}-[A-Za-z0-9._-]+)"?\s*$')
        if ($identityFeature.Success) { $feature = $identityFeature.Groups['ref'].Value }
    }
    if ($null -ne $feature) {
        Remove-FeatureClaim -ProjectRoot $Root -FeatureId $feature
        if (-not [string]::IsNullOrWhiteSpace($ClaimedBy)) {
            Add-FeatureClaim -ProjectRoot $Root -FeatureId $feature -ClaimedBy $ClaimedBy -BranchName $feature -NowUtc '2026-11-22T00:00:00Z'
        }
    }
    $branch = if ($null -ne $feature) { $feature } else { 'main' }
    $null = & git -C $Root init --quiet --initial-branch=$branch 2>&1
    $null = & git -C $Root add -A 2>&1
    $null = & git -C $Root -c user.name='SC-001 Fixture' -c user.email='sc001-fixture@example.invalid' -c commit.gpgsign=false commit --quiet -m 'SC-001 fixture' 2>&1
    $topLevel = [string](& git -C $Root rev-parse --show-toplevel 2>$null)
    $topLevelFull = if ([string]::IsNullOrWhiteSpace($topLevel)) { '' } else { [IO.Path]::GetFullPath($topLevel.Trim()).TrimEnd('\', '/') }
    if (-not [string]::Equals($topLevelFull, [IO.Path]::GetFullPath($Root).TrimEnd('\', '/'), [StringComparison]::OrdinalIgnoreCase)) {
        Write-Fail ("The fixture's git top level is '{0}', not the fixture '{1}': the run would not be isolated from the repository that holds it." -f $topLevel, $Root)
        exit 1
    }
    return $feature
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
# Outside the repository, so nothing the entry points do in the fixture can reach this repository (feature 206, T015).
# Round 1 F6: each run has its own folder, so two runs at once cannot delete each other's fixture.
$scratchRoot = Join-Path ([IO.Path]::GetTempPath()) ('specrew-project-path-resolution-regression-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
$dotNetRoot = Join-Path $scratchRoot 'dotnet-root'
$fixtureRoot = Join-Path $scratchRoot 'fixture-project'
$initFixtureRoot = Join-Path $scratchRoot 'init-project'
$declineFixtureRoot = Join-Path $scratchRoot 'claimed-project'
$declineHome = Join-Path $scratchRoot 'claimed-home'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -Path $dotNetRoot -ItemType Directory -Force
$null = New-Item -Path $initFixtureRoot -ItemType Directory -Force
$null = New-Item -Path $declineHome -ItemType Directory -Force

. (Join-Path $repoRoot 'scripts\internal\sync-boundary-state.ps1')
. (Join-Path $repoRoot 'scripts\internal\feature-claims.ps1')
$null = New-Sc001Fixture -Root $fixtureRoot
# The decline case's claimant is a constant no runner is, so the case means the same on every machine.
$declineClaimant = 'sc001-collaborator@sc001-fixture-machine'
$declineFeature = New-Sc001Fixture -Root $declineFixtureRoot -ClaimedBy $declineClaimant

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

# Feature 203, iteration 002 (the maintainer's ruling at 01:50 local on 2026-11-22, relayed): a feature claimed by
# someone else declines `specrew start`. The case asserts what the decline owns: the exit code, both lines, no session
# lock, and the other person's claim left byte for byte as it was. It does not assert that the start wrote nothing:
# today first-time setup and the skill catalog repair run before the claim check and write into the project and the
# home (docs/beta5-findings.md B5F-096; the reviewer session's ruling (a), 2026-11-22). The answer to "Continue anyway?"
# is 'n' on stdin, so the case does not depend on the runner's console; the child's home and profile point at a
# folder this script made, so those writes land there.
$declineLabel = 'specrew start --no-launch on a feature claimed by someone else'
if ($null -eq $declineFeature) {
    Write-Fail ("{0}: the copied identity file names no feature, so there is nothing to claim." -f $declineLabel)
    $allChecksPassed = $false
}
else {
    $declineLockPath = Join-Path $declineFixtureRoot '.specrew\active-sessions.yml'
    $declineClaimsPath = Get-FeatureClaimsPath -ProjectRoot $declineFixtureRoot
    $declineClaimsBefore = (Get-FileHash -LiteralPath $declineClaimsPath -Algorithm SHA256).Hash
    $priorHomeOverride = $env:SPECREW_USER_HOME_OVERRIDE
    $priorProfilePath = $env:SPECREW_USER_PROFILE_PATH
    $env:SPECREW_USER_HOME_OVERRIDE = $declineHome
    $env:SPECREW_USER_PROFILE_PATH = Join-Path $declineHome 'specrew-user-profile.yml'
    try {
        $command = Get-EntryPointCommand -ScriptPath (Join-Path $repoRoot 'scripts\specrew-start.ps1') -Arguments '-NoLaunch' -WorkingDirectory $declineFixtureRoot
        $declineOutput = @('n' | & pwsh -NoProfile -ExecutionPolicy Bypass -Command $command 2>&1)
        $declineExit = $LASTEXITCODE
    }
    finally {
        if ($null -eq $priorHomeOverride) { Remove-Item Env:\SPECREW_USER_HOME_OVERRIDE -ErrorAction SilentlyContinue } else { $env:SPECREW_USER_HOME_OVERRIDE = $priorHomeOverride }
        $env:SPECREW_USER_PROFILE_PATH = $priorProfilePath
    }
    $declineText = $declineOutput -join [Environment]::NewLine
    $declineProblems = [System.Collections.Generic.List[string]]::new()
    # The start script exits 2 on a decline; through `pwsh -Command` that reaches this script as 1.
    if ($declineExit -ne 1) { $declineProblems.Add(("exit code {0}, expected 1" -f $declineExit)) }
    $warnLine = 'WARN: Feature {0} is already claimed by {1} on branch {0} (last refresh ' -f $declineFeature, $declineClaimant
    if (-not $declineText.Contains($warnLine)) { $declineProblems.Add(("no line '{0}...)'" -f $warnLine)) }
    if (-not $declineText.Contains('Start declined; no active session lock was recorded.')) { $declineProblems.Add("no line 'Start declined; no active session lock was recorded.'") }
    if (Test-Path -LiteralPath $declineLockPath) { $declineProblems.Add(("a session lock was written: {0}" -f $declineLockPath)) }
    $declineClaimsAfter = if (Test-Path -LiteralPath $declineClaimsPath -PathType Leaf) { (Get-FileHash -LiteralPath $declineClaimsPath -Algorithm SHA256).Hash } else { '(missing)' }
    if ($declineClaimsAfter -ne $declineClaimsBefore) { $declineProblems.Add(("the claims file {0} changed: the other person's claim was rewritten or refreshed" -f $declineClaimsPath)) }
    if ($declineProblems.Count -gt 0) {
        Write-Fail ("{0}: {1}. Output:`n{2}" -f $declineLabel, ($declineProblems -join '; '), $declineText)
        $allChecksPassed = $false
    }
    else {
        Write-Pass ("{0} was declined with both lines, no session lock, and the claim left as it was." -f $declineLabel)
    }
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
