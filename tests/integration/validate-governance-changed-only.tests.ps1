[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

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
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if (-not $Condition) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Assert-Match {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if ($Text -notmatch $Pattern) {
        Write-Fail ("{0}`nObserved output:`n{1}" -f $FailureMessage, $Text)
        return $false
    }

    return $true
}

function Assert-NotMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if ($Text -match $Pattern) {
        Write-Fail ("{0}`nObserved output:`n{1}" -f $FailureMessage, $Text)
        return $false
    }

    return $true
}

function Assert-FirstLineMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    $firstLine = @(
        ($Text -split "\r?\n") |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -First 1
    )[0]

    if ([string]::IsNullOrWhiteSpace($firstLine) -or $firstLine -notmatch $Pattern) {
        Write-Fail ("{0}`nFirst output line:`n{1}`nObserved output:`n{2}" -f $FailureMessage, $firstLine, $Text)
        return $false
    }

    return $true
}

function Set-ContentUtf8 {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Reset-ScratchRoot {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            return
        }
        catch {
            if ($attempt -ge 4) {
                throw
            }

            Start-Sleep -Seconds 2
        }
    }
}

function New-Workspace {
    param([Parameter(Mandatory = $true)][string]$WorkspaceName)

    $workspaceRoot = Join-Path $scratchRoot $WorkspaceName
    if (Test-Path -LiteralPath $workspaceRoot) {
        Set-Location $repoRoot
        for ($attempt = 1; $attempt -le 5; $attempt++) {
            try {
                Remove-Item -LiteralPath $workspaceRoot -Recurse -Force
                break
            }
            catch {
                if ($attempt -eq 5) {
                    throw
                }

                Start-Sleep -Milliseconds 200
            }
        }
    }

    $null = New-Item -ItemType Directory -Path $workspaceRoot -Force

    foreach ($item in @('.specrew', '.squad', '.github', '.specify')) {
        $source = Join-Path $repoRoot $item
        if (Test-Path -LiteralPath $source) {
            $destination = Join-Path $workspaceRoot $item
            Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
        }
    }

    $featureDestination = Join-Path $workspaceRoot 'specs\013-validator-hardening'
    $featureParent = Split-Path -Parent $featureDestination
    if (-not (Test-Path -LiteralPath $featureParent)) {
        $null = New-Item -ItemType Directory -Path $featureParent -Force
    }
    Copy-Item -LiteralPath $featureSource -Destination $featureParent -Recurse -Force

    return $workspaceRoot
}

function Initialize-GitWorkspace {
    param([Parameter(Mandatory = $true)][string]$WorkspaceRoot)

    $remoteRoot = Join-Path $WorkspaceRoot '.git-remote'
    $null = & git -C $WorkspaceRoot init --quiet 2>&1
    $null = & git -C $WorkspaceRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $WorkspaceRoot config user.name 'Test User' 2>&1
    $null = & git -C $WorkspaceRoot add -A 2>&1
    $null = & git -C $WorkspaceRoot commit -m 'Seed validator fixture' --quiet 2>&1
    $null = & git -C $WorkspaceRoot branch -M main 2>&1
    Add-Content -LiteralPath (Join-Path $WorkspaceRoot '.git\info\exclude') -Value ([Environment]::NewLine + '.git-remote/' + [Environment]::NewLine)
    $null = New-Item -ItemType Directory -Path $remoteRoot -Force
    $null = & git -C $remoteRoot init --bare --quiet 2>&1
    $null = & git -C $WorkspaceRoot remote add origin $remoteRoot 2>&1
    $null = & git -C $WorkspaceRoot push -u origin main 2>&1
    $null = & git -C $WorkspaceRoot checkout -b feature-026 2>&1
}

function Commit-Workspace {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $null = & git -C $WorkspaceRoot add -A 2>&1
    $null = & git -C $WorkspaceRoot commit -m $Message --quiet 2>&1
}

function Touch-IterationForDiff {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$RelativeIterationFile
    )

    Touch-RelativeFileForDiff -WorkspaceRoot $WorkspaceRoot -RelativePath $RelativeIterationFile
}

function Touch-RelativeFileForDiff {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $targetPath = Join-Path $WorkspaceRoot $RelativePath
    $content = Get-Content -LiteralPath $targetPath -Raw -Encoding UTF8
    Set-ContentUtf8 -Path $targetPath -Content ($content.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + '<!-- changed-only fixture touch -->' + [Environment]::NewLine)
    Commit-Workspace -WorkspaceRoot $WorkspaceRoot -Message "Touch $RelativePath"
}

function Remove-UntouchedStateArtifact {
    param([Parameter(Mandatory = $true)][string]$WorkspaceRoot)

    $statePath = Join-Path $WorkspaceRoot 'specs\013-validator-hardening\iterations\002\state.md'
    if (Test-Path -LiteralPath $statePath) {
        Remove-Item -LiteralPath $statePath -Force
    }
}

function Remove-OriginRemote {
    param([Parameter(Mandatory = $true)][string]$WorkspaceRoot)

    $null = & git -C $WorkspaceRoot remote remove origin 2>&1
}

function Remove-OriginHeadTrackingRef {
    param([Parameter(Mandatory = $true)][string]$WorkspaceRoot)

    $null = & git -C $WorkspaceRoot update-ref -d refs/remotes/origin/HEAD 2>&1
}

function Checkout-MainBranch {
    param([Parameter(Mandatory = $true)][string]$WorkspaceRoot)

    $null = & git -C $WorkspaceRoot checkout main 2>&1
}

function Checkout-DetachedHead {
    param([Parameter(Mandatory = $true)][string]$WorkspaceRoot)

    $null = & git -C $WorkspaceRoot checkout --detach HEAD 2>&1
}

function Invoke-Validator {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [switch]$ChangedOnly,
        [switch]$FullRun,
        [AllowNull()][string]$BaseBranch
    )

    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $validatorScriptPath, '-ProjectPath', $ProjectPath)
    if ($ChangedOnly) {
        $arguments += '-ChangedOnly'
    }
    if ($FullRun) {
        $arguments += '-FullRun'
    }

    $previousBaseRef = $env:GITHUB_BASE_REF
    $previousVerbose = $env:SPECREW_VALIDATOR_VERBOSE
    try {
        if ([string]::IsNullOrWhiteSpace($BaseBranch)) {
            Remove-Item Env:GITHUB_BASE_REF -ErrorAction SilentlyContinue
        }
        else {
            $env:GITHUB_BASE_REF = $BaseBranch
        }

        $env:SPECREW_VALIDATOR_VERBOSE = '1'

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $output = @(& pwsh @arguments 2>&1)
        $stopwatch.Stop()
        $exitCode = $LASTEXITCODE
    }
    finally {
        if ($null -eq $previousBaseRef) {
            Remove-Item Env:GITHUB_BASE_REF -ErrorAction SilentlyContinue
        }
        else {
            $env:GITHUB_BASE_REF = $previousBaseRef
        }

        if ($null -eq $previousVerbose) {
            Remove-Item Env:SPECREW_VALIDATOR_VERBOSE -ErrorAction SilentlyContinue
        }
        else {
            $env:SPECREW_VALIDATOR_VERBOSE = $previousVerbose
        }
    }

    return [pscustomobject]@{
        ExitCode  = $exitCode
        Text      = ($output -join "`n")
        ElapsedMs = [int]$stopwatch.ElapsedMilliseconds
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validatorScriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$featureSource = Join-Path $repoRoot 'specs\013-validator-hardening'
$scratchRoot = Join-Path $repoRoot '.scratch\validate-governance-changed-only'

foreach ($requiredPath in @($validatorScriptPath, $featureSource)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing changed-only validator dependency: $requiredPath"
        exit 1
    }
}

if (Test-Path -LiteralPath $scratchRoot) {
    Reset-ScratchRoot -Path $scratchRoot
}

$allChecksPassed = $true

$explicitChangedOnlyWorkspace = New-Workspace -WorkspaceName 'explicit-changed-only'
Initialize-GitWorkspace -WorkspaceRoot $explicitChangedOnlyWorkspace
Touch-IterationForDiff -WorkspaceRoot $explicitChangedOnlyWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $explicitChangedOnlyWorkspace
$explicitChangedOnlyResult = Invoke-Validator -ProjectPath $explicitChangedOnlyWorkspace -ChangedOnly -BaseBranch 'main'
$explicitChangedOnlyChecksPassed = $true
if (-not (Assert-True -Condition ($explicitChangedOnlyResult.ExitCode -eq 0) -FailureMessage 'Explicit -ChangedOnly validation should pass when only the touched iteration remains in scope.')) { $allChecksPassed = $false; $explicitChangedOnlyChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $explicitChangedOnlyResult.Text -Pattern '^\[validator-scope\] changed-only to origin/main\.\.\.HEAD \(1 iterations, 1 files in diff\)$' -FailureMessage 'Explicit -ChangedOnly runs should emit the changed-only scope banner as the first informational line.')) { $allChecksPassed = $false; $explicitChangedOnlyChecksPassed = $false }
if (-not (Assert-Match -Text $explicitChangedOnlyResult.Text -Pattern '\[validator\] \(1/1\) validating .*iterations[/\\]001' -FailureMessage 'Explicit -ChangedOnly validation should still validate the touched iteration.')) { $allChecksPassed = $false; $explicitChangedOnlyChecksPassed = $false }
if (-not (Assert-NotMatch -Text $explicitChangedOnlyResult.Text -Pattern 'iterations\\002' -FailureMessage 'Explicit -ChangedOnly validation should skip untouched iterations.')) { $allChecksPassed = $false; $explicitChangedOnlyChecksPassed = $false }
if (-not (Assert-Match -Text $explicitChangedOnlyResult.Text -Pattern '\[validator-timing\] mode=scoped elapsed_ms=\d+ iterations_validated=1 trigger_source=local' -FailureMessage 'Explicit -ChangedOnly validation should emit scoped timing output.')) { $allChecksPassed = $false; $explicitChangedOnlyChecksPassed = $false }
if ($explicitChangedOnlyChecksPassed) {
    Write-Pass 'Explicit -ChangedOnly still validates only the touched iteration and emits the changed-only scope banner.'
}

$autoScopedWorkspace = New-Workspace -WorkspaceName 'auto-scoped-feature-branch'
Initialize-GitWorkspace -WorkspaceRoot $autoScopedWorkspace
Touch-IterationForDiff -WorkspaceRoot $autoScopedWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $autoScopedWorkspace
$autoScopedResult = Invoke-Validator -ProjectPath $autoScopedWorkspace
$autoScopedChecksPassed = $true
if (-not (Assert-True -Condition ($autoScopedResult.ExitCode -eq 0) -FailureMessage 'Feature-branch validation with no flags should auto-scope and pass when only the touched iteration remains in scope.')) { $allChecksPassed = $false; $autoScopedChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $autoScopedResult.Text -Pattern '^\[validator-scope\] auto-scoped to origin/main\.\.\.HEAD \(1 iterations, 1 files in diff\)$' -FailureMessage 'Feature-branch validation with no flags should emit the auto-scoped banner as the first informational line.')) { $allChecksPassed = $false; $autoScopedChecksPassed = $false }
if (-not (Assert-NotMatch -Text $autoScopedResult.Text -Pattern 'iterations\\002' -FailureMessage 'Auto-scoped validation should skip untouched iterations.')) { $allChecksPassed = $false; $autoScopedChecksPassed = $false }
if (-not (Assert-Match -Text $autoScopedResult.Text -Pattern '\[validator-timing\] mode=scoped elapsed_ms=\d+ iterations_validated=1 trigger_source=local' -FailureMessage 'Auto-scoped validation should emit scoped timing output.')) { $allChecksPassed = $false; $autoScopedChecksPassed = $false }
if ($autoScopedChecksPassed) {
    Write-Pass 'Feature-branch validation with no flags auto-scopes and emits the banner first.'
}

$originHeadFallbackWorkspace = New-Workspace -WorkspaceName 'missing-origin-head'
Initialize-GitWorkspace -WorkspaceRoot $originHeadFallbackWorkspace
Touch-IterationForDiff -WorkspaceRoot $originHeadFallbackWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $originHeadFallbackWorkspace
Remove-OriginHeadTrackingRef -WorkspaceRoot $originHeadFallbackWorkspace
$originHeadFallbackResult = Invoke-Validator -ProjectPath $originHeadFallbackWorkspace
$originHeadFallbackChecksPassed = $true
if (-not (Assert-True -Condition ($originHeadFallbackResult.ExitCode -eq 0) -FailureMessage 'Auto-scoped validation should fall back from missing origin/HEAD to origin/main and still pass.')) { $allChecksPassed = $false; $originHeadFallbackChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $originHeadFallbackResult.Text -Pattern '^\[validator-scope\] auto-scoped to origin/main\.\.\.HEAD \(1 iterations, 1 files in diff\)$' -FailureMessage 'Auto-scoped validation should still resolve origin/main when origin/HEAD is absent.')) { $allChecksPassed = $false; $originHeadFallbackChecksPassed = $false }
if ($originHeadFallbackChecksPassed) {
    Write-Pass 'Auto-scoped validation falls back from missing origin/HEAD to origin/main.'
}

$fullRunWorkspace = New-Workspace -WorkspaceName 'full-run-override'
Initialize-GitWorkspace -WorkspaceRoot $fullRunWorkspace
Touch-IterationForDiff -WorkspaceRoot $fullRunWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $fullRunWorkspace
$fullRunResult = Invoke-Validator -ProjectPath $fullRunWorkspace -FullRun
$fullRunChecksPassed = $true
if (-not (Assert-True -Condition ($fullRunResult.ExitCode -ne 0) -FailureMessage '-FullRun should bypass auto-scope and continue to validate untouched invalid iterations.')) { $allChecksPassed = $false; $fullRunChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $fullRunResult.Text -Pattern '^\[validator-scope\] full-repo \(-FullRun override; 2 iterations\)$' -FailureMessage '-FullRun should emit the full-repo override banner as the first informational line.')) { $allChecksPassed = $false; $fullRunChecksPassed = $false }
if (-not (Assert-Match -Text $fullRunResult.Text -Pattern 'FAIL .*iterations[/\\]002' -FailureMessage '-FullRun should still report untouched iteration failures.')) { $allChecksPassed = $false; $fullRunChecksPassed = $false }
if (-not (Assert-Match -Text $fullRunResult.Text -Pattern '\[validator-timing\] mode=unscoped elapsed_ms=\d+ iterations_validated=2 trigger_source=local' -FailureMessage '-FullRun should emit unscoped timing output.')) { $allChecksPassed = $false; $fullRunChecksPassed = $false }
if ($fullRunChecksPassed) {
    Write-Pass '-FullRun bypasses auto-scope and emits the expected full-repo banner.'
}

$conflictingFlagsWorkspace = New-Workspace -WorkspaceName 'conflicting-flags'
Initialize-GitWorkspace -WorkspaceRoot $conflictingFlagsWorkspace
$conflictingFlagsResult = Invoke-Validator -ProjectPath $conflictingFlagsWorkspace -ChangedOnly -FullRun
$conflictingFlagsChecksPassed = $true
if (-not (Assert-True -Condition ($conflictingFlagsResult.ExitCode -ne 0) -FailureMessage 'Passing both -ChangedOnly and -FullRun should fail fast.')) { $allChecksPassed = $false; $conflictingFlagsChecksPassed = $false }
if (-not (Assert-Match -Text $conflictingFlagsResult.Text -Pattern '-FullRun and -ChangedOnly are mutually exclusive' -FailureMessage 'Conflicting flag validation should explain the invalid combination clearly.')) { $allChecksPassed = $false; $conflictingFlagsChecksPassed = $false }
if ($conflictingFlagsChecksPassed) {
    Write-Pass 'Conflicting -ChangedOnly and -FullRun flags fail fast with a clear error.'
}

$mainWorkspace = New-Workspace -WorkspaceName 'main-default-full-repo'
Initialize-GitWorkspace -WorkspaceRoot $mainWorkspace
Checkout-MainBranch -WorkspaceRoot $mainWorkspace
Remove-UntouchedStateArtifact -WorkspaceRoot $mainWorkspace
$mainResult = Invoke-Validator -ProjectPath $mainWorkspace
$mainChecksPassed = $true
if (-not (Assert-True -Condition ($mainResult.ExitCode -ne 0) -FailureMessage 'Main-branch validation with no flags should stay full-repo and surface untouched iteration failures.')) { $allChecksPassed = $false; $mainChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $mainResult.Text -Pattern '^\[validator-scope\] full-repo \(on main; 2 iterations\)$' -FailureMessage 'Main-branch validation should emit the on-main full-repo banner first.')) { $allChecksPassed = $false; $mainChecksPassed = $false }
if (-not (Assert-Match -Text $mainResult.Text -Pattern 'FAIL .*iterations[/\\]002' -FailureMessage 'Main-branch validation should still report untouched iteration failures.')) { $allChecksPassed = $false; $mainChecksPassed = $false }
if ($mainChecksPassed) {
    Write-Pass 'Main-branch validation remains full-repo by default.'
}

$sessionStateWorkspace = New-Workspace -WorkspaceName 'session-state-only'
Initialize-GitWorkspace -WorkspaceRoot $sessionStateWorkspace
Touch-RelativeFileForDiff -WorkspaceRoot $sessionStateWorkspace -RelativePath '.specrew\last-start-prompt.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $sessionStateWorkspace
$sessionStateResult = Invoke-Validator -ProjectPath $sessionStateWorkspace -ChangedOnly -BaseBranch 'main'
$sessionStateChecksPassed = $true
if (-not (Assert-True -Condition ($sessionStateResult.ExitCode -eq 0) -FailureMessage 'Changed-only validation should stay scoped when only .specrew\last-start-prompt.md changes.')) { $allChecksPassed = $false; $sessionStateChecksPassed = $false }
if (-not (Assert-NotMatch -Text $sessionStateResult.Text -Pattern '\[validator\] -ChangedOnly fallback to full validation:' -FailureMessage 'Session-state prompt changes should not trigger full-validation fallback.')) { $allChecksPassed = $false; $sessionStateChecksPassed = $false }
if (-not (Assert-Match -Text $sessionStateResult.Text -Pattern '\[validator-timing\] mode=scoped elapsed_ms=\d+ iterations_validated=0 trigger_source=local' -FailureMessage 'Session-state prompt changes should emit scoped timing output with zero validated iterations.')) { $allChecksPassed = $false; $sessionStateChecksPassed = $false }
if ($sessionStateChecksPassed) {
    Write-Pass 'Session-state prompt changes stay scoped and do not trigger full-validation fallback.'
}

$identityNowWorkspace = New-Workspace -WorkspaceName 'identity-now-only'
Initialize-GitWorkspace -WorkspaceRoot $identityNowWorkspace
Touch-RelativeFileForDiff -WorkspaceRoot $identityNowWorkspace -RelativePath '.squad\identity\now.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $identityNowWorkspace
$identityNowResult = Invoke-Validator -ProjectPath $identityNowWorkspace -ChangedOnly -BaseBranch 'main'
$identityNowChecksPassed = $true
if (-not (Assert-True -Condition ($identityNowResult.ExitCode -eq 0) -FailureMessage 'Changed-only validation should stay scoped when only .squad\identity\now.md changes.')) { $allChecksPassed = $false; $identityNowChecksPassed = $false }
if (-not (Assert-NotMatch -Text $identityNowResult.Text -Pattern '\[validator\] -ChangedOnly fallback to full validation:' -FailureMessage '.squad\identity\now.md changes should not trigger full-validation fallback.')) { $allChecksPassed = $false; $identityNowChecksPassed = $false }
if (-not (Assert-Match -Text $identityNowResult.Text -Pattern '\[validator-timing\] mode=scoped elapsed_ms=\d+ iterations_validated=0 trigger_source=local' -FailureMessage '.squad\identity\now.md changes should emit scoped timing output with zero validated iterations.')) { $allChecksPassed = $false; $identityNowChecksPassed = $false }
if ($identityNowChecksPassed) {
    Write-Pass '.squad\identity\now.md changes stay scoped and do not trigger full-validation fallback.'
}

$configWorkspace = New-Workspace -WorkspaceName 'config-global-state'
Initialize-GitWorkspace -WorkspaceRoot $configWorkspace
Touch-RelativeFileForDiff -WorkspaceRoot $configWorkspace -RelativePath '.specrew\config.yml'
Remove-UntouchedStateArtifact -WorkspaceRoot $configWorkspace
$configResult = Invoke-Validator -ProjectPath $configWorkspace -ChangedOnly -BaseBranch 'main'
$configChecksPassed = $true
if (-not (Assert-True -Condition ($configResult.ExitCode -ne 0) -FailureMessage 'Changed-only validation should fall back to unscoped validation when .specrew\config.yml changes.')) { $allChecksPassed = $false; $configChecksPassed = $false }
if (-not (Assert-Match -Text $configResult.Text -Pattern 'FAIL .*iterations[/\\]002' -FailureMessage '.specrew\config.yml changes should still validate untouched iterations and surface their failures.')) { $allChecksPassed = $false; $configChecksPassed = $false }
if (-not (Assert-Match -Text $configResult.Text -Pattern '\[validator\] -ChangedOnly fallback to full validation: global-state-changed' -FailureMessage '.specrew\config.yml changes should emit the expected full-validation fallback reason.')) { $allChecksPassed = $false; $configChecksPassed = $false }
if (-not (Assert-Match -Text $configResult.Text -Pattern '\[validator-timing\] mode=unscoped elapsed_ms=\d+ iterations_validated=2 trigger_source=local' -FailureMessage '.specrew\config.yml changes should emit unscoped timing output.')) { $allChecksPassed = $false; $configChecksPassed = $false }
if ($configChecksPassed) {
    Write-Pass '.specrew\config.yml changes force unscoped validation so untouched iteration failures still surface.'
}

$wisdomWorkspace = New-Workspace -WorkspaceName 'wisdom-global-state'
Initialize-GitWorkspace -WorkspaceRoot $wisdomWorkspace
Touch-RelativeFileForDiff -WorkspaceRoot $wisdomWorkspace -RelativePath '.squad\identity\wisdom.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $wisdomWorkspace
$wisdomResult = Invoke-Validator -ProjectPath $wisdomWorkspace -ChangedOnly -BaseBranch 'main'
$wisdomChecksPassed = $true
if (-not (Assert-True -Condition ($wisdomResult.ExitCode -ne 0) -FailureMessage 'Changed-only validation should fall back to unscoped validation when .squad\identity\wisdom.md changes.')) { $allChecksPassed = $false; $wisdomChecksPassed = $false }
if (-not (Assert-Match -Text $wisdomResult.Text -Pattern 'FAIL .*iterations[/\\]002' -FailureMessage '.squad\identity\wisdom.md changes should still validate untouched iterations and surface their failures.')) { $allChecksPassed = $false; $wisdomChecksPassed = $false }
if (-not (Assert-Match -Text $wisdomResult.Text -Pattern '\[validator\] -ChangedOnly fallback to full validation: global-state-changed' -FailureMessage '.squad\identity\wisdom.md changes should emit the expected full-validation fallback reason.')) { $allChecksPassed = $false; $wisdomChecksPassed = $false }
if (-not (Assert-Match -Text $wisdomResult.Text -Pattern '\[validator-timing\] mode=unscoped elapsed_ms=\d+ iterations_validated=2 trigger_source=local' -FailureMessage '.squad\identity\wisdom.md changes should emit unscoped timing output.')) { $allChecksPassed = $false; $wisdomChecksPassed = $false }
if ($wisdomChecksPassed) {
    Write-Pass '.squad\identity\wisdom.md changes force unscoped validation so untouched iteration failures still surface.'
}

$noRemoteWorkspace = New-Workspace -WorkspaceName 'no-remote-default-full-repo'
Initialize-GitWorkspace -WorkspaceRoot $noRemoteWorkspace
Touch-IterationForDiff -WorkspaceRoot $noRemoteWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $noRemoteWorkspace
Remove-OriginRemote -WorkspaceRoot $noRemoteWorkspace
$noRemoteResult = Invoke-Validator -ProjectPath $noRemoteWorkspace
$noRemoteChecksPassed = $true
if (-not (Assert-True -Condition ($noRemoteResult.ExitCode -ne 0) -FailureMessage 'Feature-branch validation with no remote should fall back to full-repo validation.')) { $allChecksPassed = $false; $noRemoteChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $noRemoteResult.Text -Pattern '^\[validator-scope\] full-repo \(base-undetectable; 2 iterations\)$' -FailureMessage 'No-remote validation should emit the base-undetectable banner first.')) { $allChecksPassed = $false; $noRemoteChecksPassed = $false }
if (-not (Assert-Match -Text $noRemoteResult.Text -Pattern 'FAIL .*iterations[/\\]002' -FailureMessage 'No-remote validation should still report untouched iteration failures through the full-repo path.')) { $allChecksPassed = $false; $noRemoteChecksPassed = $false }
if (-not (Assert-Match -Text $noRemoteResult.Text -Pattern '\[validator\] Auto-scope fallback to full validation: base-ref-undetectable' -FailureMessage 'No-remote validation should emit the verbose auto-scope fallback reason.')) { $allChecksPassed = $false; $noRemoteChecksPassed = $false }
if ($noRemoteChecksPassed) {
    Write-Pass 'No-remote validation falls back to full-repo with the base-undetectable banner.'
}

$detachedWorkspace = New-Workspace -WorkspaceName 'detached-head-default-full-repo'
Initialize-GitWorkspace -WorkspaceRoot $detachedWorkspace
Touch-IterationForDiff -WorkspaceRoot $detachedWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $detachedWorkspace
Remove-OriginRemote -WorkspaceRoot $detachedWorkspace
Checkout-DetachedHead -WorkspaceRoot $detachedWorkspace
$detachedResult = Invoke-Validator -ProjectPath $detachedWorkspace
$detachedChecksPassed = $true
if (-not (Assert-True -Condition ($detachedResult.ExitCode -ne 0) -FailureMessage 'Detached-HEAD validation without a detectable base should fall back to full-repo validation.')) { $allChecksPassed = $false; $detachedChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $detachedResult.Text -Pattern '^\[validator-scope\] full-repo \(base-undetectable; 2 iterations\)$' -FailureMessage 'Detached-HEAD validation without a detectable base should emit the base-undetectable banner first.')) { $allChecksPassed = $false; $detachedChecksPassed = $false }
if ($detachedChecksPassed) {
    Write-Pass 'Detached-HEAD validation without a detectable base falls back to full-repo with the base-undetectable banner.'
}

$fallbackWorkspace = New-Workspace -WorkspaceName 'fallback-unscoped'
Initialize-GitWorkspace -WorkspaceRoot $fallbackWorkspace
Touch-IterationForDiff -WorkspaceRoot $fallbackWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $fallbackWorkspace
Remove-OriginRemote -WorkspaceRoot $fallbackWorkspace
$fallbackResult = Invoke-Validator -ProjectPath $fallbackWorkspace -ChangedOnly
$fallbackChecksPassed = $true
if (-not (Assert-True -Condition ($fallbackResult.ExitCode -ne 0) -FailureMessage 'Changed-only validation should fall back to unscoped validation when the diff base cannot be resolved.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $fallbackResult.Text -Pattern '^\[validator-scope\] full-repo \(base-undetectable; 2 iterations\)$' -FailureMessage 'Explicit -ChangedOnly fallback should emit the base-undetectable full-repo banner first when the base cannot be resolved.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-Match -Text $fallbackResult.Text -Pattern 'iterations[/\\]001' -FailureMessage 'Base-resolution fallback should validate the touched iteration through the unscoped path.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-Match -Text $fallbackResult.Text -Pattern 'iterations[/\\]002' -FailureMessage 'Base-resolution fallback should validate untouched iterations through the unscoped path.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-Match -Text $fallbackResult.Text -Pattern '\[validator\] -ChangedOnly fallback to full validation: base-ref-undetectable' -FailureMessage 'Base-resolution fallback should emit the expected verbose fallback reason.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-Match -Text $fallbackResult.Text -Pattern '\[validator-timing\] mode=unscoped elapsed_ms=\d+ iterations_validated=2 trigger_source=local' -FailureMessage 'Base-resolution fallback should emit unscoped timing output.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if ($fallbackChecksPassed) {
    Write-Pass 'Changed-only mode falls back to full validation with a base-undetectable banner when the PR base ref cannot be resolved.'
}

if (-not $allChecksPassed) {
    exit 1
}

Write-Pass 'Changed-only governance validation covers scoped iterations, global-state fallback, and full-validation fallback.'
exit 0
