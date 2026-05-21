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

function Invoke-Validator {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [switch]$ChangedOnly,
        [AllowNull()][string]$BaseBranch
    )

    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $validatorScriptPath, '-ProjectPath', $ProjectPath)
    if ($ChangedOnly) {
        $arguments += '-ChangedOnly'
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

        $output = @(& pwsh @arguments 2>&1)
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
        ExitCode = $exitCode
        Text     = ($output -join "`n")
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

$scopedWorkspace = New-Workspace -WorkspaceName 'scoped-iteration'
Initialize-GitWorkspace -WorkspaceRoot $scopedWorkspace
Touch-IterationForDiff -WorkspaceRoot $scopedWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $scopedWorkspace
$scopedResult = Invoke-Validator -ProjectPath $scopedWorkspace -ChangedOnly -BaseBranch 'main'
$scopedChecksPassed = $true
if (-not (Assert-True -Condition ($scopedResult.ExitCode -eq 0) -FailureMessage 'Changed-only validation should pass when only the touched iteration remains in scope.')) { $allChecksPassed = $false; $scopedChecksPassed = $false }
if (-not (Assert-Match -Text $scopedResult.Text -Pattern '\[validator\] \(1/1\) validating .*iterations[/\\]001' -FailureMessage 'Changed-only validation should still validate the touched iteration.')) { $allChecksPassed = $false; $scopedChecksPassed = $false }
if (-not (Assert-NotMatch -Text $scopedResult.Text -Pattern 'iterations\\002' -FailureMessage 'Changed-only validation should skip untouched iterations.')) { $allChecksPassed = $false; $scopedChecksPassed = $false }
if (-not (Assert-Match -Text $scopedResult.Text -Pattern '\[validator-timing\] mode=scoped elapsed_ms=\d+ iterations_validated=1 trigger_source=local' -FailureMessage 'Changed-only scoped iteration validation should emit scoped timing output.')) { $allChecksPassed = $false; $scopedChecksPassed = $false }
if ($scopedChecksPassed) {
    Write-Pass 'Changed-only mode validates only the touched iteration and skips untouched invalid iterations.'
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

$fullWorkspace = New-Workspace -WorkspaceName 'full-unscoped'
Initialize-GitWorkspace -WorkspaceRoot $fullWorkspace
Touch-IterationForDiff -WorkspaceRoot $fullWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $fullWorkspace
$fullResult = Invoke-Validator -ProjectPath $fullWorkspace
$fullChecksPassed = $true
if (-not (Assert-True -Condition ($fullResult.ExitCode -ne 0) -FailureMessage 'Unscoped validation should continue to validate every iteration.')) { $allChecksPassed = $false; $fullChecksPassed = $false }
if (-not (Assert-Match -Text $fullResult.Text -Pattern 'FAIL .*iterations[/\\]002' -FailureMessage 'Unscoped validation should report failures from untouched iterations.')) { $allChecksPassed = $false; $fullChecksPassed = $false }
if (-not (Assert-Match -Text $fullResult.Text -Pattern '\[validator-timing\] mode=unscoped elapsed_ms=\d+ iterations_validated=2 trigger_source=local' -FailureMessage 'Unscoped validation should emit unscoped timing output.')) { $allChecksPassed = $false; $fullChecksPassed = $false }
if ($fullChecksPassed) {
    Write-Pass 'Unscoped validation still evaluates all iterations.'
}

$fallbackWorkspace = New-Workspace -WorkspaceName 'fallback-unscoped'
Initialize-GitWorkspace -WorkspaceRoot $fallbackWorkspace
Touch-IterationForDiff -WorkspaceRoot $fallbackWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-UntouchedStateArtifact -WorkspaceRoot $fallbackWorkspace
$fallbackResult = Invoke-Validator -ProjectPath $fallbackWorkspace -ChangedOnly -BaseBranch 'missing-base'
$fallbackChecksPassed = $true
if (-not (Assert-True -Condition ($fallbackResult.ExitCode -ne 0) -FailureMessage 'Changed-only validation should fall back to unscoped validation when the diff base cannot be resolved.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-Match -Text $fallbackResult.Text -Pattern 'iterations[/\\]001' -FailureMessage 'Base-resolution fallback should validate the touched iteration through the unscoped path.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-Match -Text $fallbackResult.Text -Pattern 'iterations[/\\]002' -FailureMessage 'Base-resolution fallback should validate untouched iterations through the unscoped path.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-Match -Text $fallbackResult.Text -Pattern '\[validator\] -ChangedOnly fallback to full validation: base-ref-unresolved' -FailureMessage 'Base-resolution fallback should emit the expected fallback reason.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-Match -Text $fallbackResult.Text -Pattern '\[validator-timing\] mode=unscoped elapsed_ms=\d+ iterations_validated=2 trigger_source=local' -FailureMessage 'Base-resolution fallback should emit unscoped timing output.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if ($fallbackChecksPassed) {
    Write-Pass 'Changed-only mode falls back to full validation when the PR base ref cannot be resolved.'
}

if (-not $allChecksPassed) {
    exit 1
}

Write-Pass 'Changed-only governance validation covers scoped iterations, global-state fallback, and full-validation fallback.'
exit 0
