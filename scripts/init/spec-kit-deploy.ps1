# Spec-Kit deployment helpers for specrew-init.ps1 (extracted via Proposal 108 Slice 4)
#
# Depends on: scripts/init/_utilities.ps1 (Invoke-NativeCommand*, Get-FirstNonEmptyOutputLine,
# Add-Action, Invoke-WithNativeCommandEncoding); shared-governance.ps1 (Write-Utf8FileAtomic).
#
# Functions:
#   - Get-SpecKitGitReference         normalize "0.8.4" → "v0.8.4"
#   - Get-SpecKitInstallArguments     build "uv tool install" argv
#   - Get-SpecKitInstallCommandText   render install command string for display
#   - Get-FirstNonEmptyOutputLine     first non-blank line of probe output
#   - Test-SpecifyReleaseAssetBlocker detect upstream Spec Kit release-asset 404
#   - Test-SpecifyExtensionAddAvailable probe "specify extension add --help"
#   - Test-SpecifyInitPreflight       dry-probe "specify init" + auto-repair stale specify
#   - Get-SpecifyInitPreflightResult  build preflight result object
#   - Invoke-SpecKitExtensionDeployment deploy specrew-speckit extension into project

Set-StrictMode -Version Latest

function Get-SpecKitGitReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $trimmedVersion = $Version.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmedVersion)) {
        throw 'Spec Kit version cannot be empty.'
    }

    if ($trimmedVersion.StartsWith('v', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $trimmedVersion
    }

    return ('v{0}' -f $trimmedVersion)
}

function Get-SpecKitInstallArguments {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [bool]$ForceInstall
    )

    $arguments = @('tool', 'install')
    if ($ForceInstall) {
        $arguments += '--force'
    }

    $arguments += @(
        'specify-cli',
        '--from',
        ('git+https://github.com/github/spec-kit.git@{0}' -f (Get-SpecKitGitReference -Version $Version))
    )

    return $arguments
}

function Get-SpecKitInstallCommandText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [bool]$ForceInstall
    )

    return ('uv {0}' -f ((Get-SpecKitInstallArguments -Version $Version -ForceInstall $ForceInstall) -join ' '))
}

function Get-FirstNonEmptyOutputLine {
    param(
        [AllowEmptyCollection()]
        [string[]]$OutputLines
    )

    return @($OutputLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)[0]
}

function Test-SpecifyReleaseAssetBlocker {
    param(
        [AllowEmptyCollection()]
        [string[]]$OutputLines
    )

    $combinedOutput = (@($OutputLines) -join [Environment]::NewLine)
    return $combinedOutput -match 'No matching release asset found for .+spec-kit-template-'
}

function Test-SpecifyExtensionAddAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    try {
        $probe = Invoke-NativeCommandForOutput -FilePath 'specify' -ArgumentList @('extension', 'add', '--help') -WorkingDirectory $WorkingDirectory
    }
    catch {
        return $false
    }

    if ($probe.ExitCode -ne 0) {
        return $false
    }

    $output = ($probe.Output -join [Environment]::NewLine)
    return $output -match 'specify extension add' -and $output -match 'Install an extension'
}

function Test-SpecifyInitPreflight {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory = $true)]
        [string]$SpecKitVersion
    )

    $probeDirectory = Join-Path $ProjectPath ('.specrew-specify-probe-{0}' -f [guid]::NewGuid().ToString('N'))
    New-Item -Path $probeDirectory -ItemType Directory -Force | Out-Null

    try {
        $probeResult = Invoke-NativeCommandForOutput -FilePath 'specify' -ArgumentList $ArgumentList -WorkingDirectory $probeDirectory
        if ($probeResult.ExitCode -eq 0) {
            return Get-SpecifyInitPreflightResult -Ready $true -Repaired $false -RepairOutcome $null -FailureMessage $null
        }

        $failureSummary = Get-FirstNonEmptyOutputLine -OutputLines $probeResult.Output
        if (-not (Test-SpecifyReleaseAssetBlocker -OutputLines $probeResult.Output)) {
            return Get-SpecifyInitPreflightResult -Ready $false -Repaired $false -RepairOutcome $null -FailureMessage ("Spec Kit preflight failed before Specrew touched your project: {0}" -f $(if ($failureSummary) { $failureSummary } else { 'specify init exited without any diagnostic output' }))
        }

        if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
            return Get-SpecifyInitPreflightResult -Ready $false -Repaired $false -RepairOutcome $null -FailureMessage ("Spec Kit preflight hit the upstream release-asset blocker ({0}). Install the official GitHub release with '{1}', then re-run specrew init." -f $failureSummary, (Get-SpecKitInstallCommandText -Version $SpecKitVersion -ForceInstall $true))
        }

        Write-Host ("[info] Detected Spec Kit release-asset blocker during preflight; reinstalling official Spec Kit {0} from GitHub." -f (Get-SpecKitGitReference -Version $SpecKitVersion)) -ForegroundColor Yellow
        $repairResult = Invoke-NativeCommandForOutput -FilePath 'uv' -ArgumentList (Get-SpecKitInstallArguments -Version $SpecKitVersion -ForceInstall $true) -WorkingDirectory $probeDirectory
        foreach ($line in @($repairResult.Output)) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-Host $line
            }
        }
        if ($repairResult.ExitCode -ne 0) {
            $repairFailureSummary = Get-FirstNonEmptyOutputLine -OutputLines $repairResult.Output
            return Get-SpecifyInitPreflightResult -Ready $false -Repaired $false -RepairOutcome $null -FailureMessage ("Spec Kit preflight hit the upstream release-asset blocker ({0}), and automatic repair failed{1}. Run '{2}' manually, then re-run specrew init." -f $failureSummary, $(if ($repairFailureSummary) { ": $repairFailureSummary" } else { '' }), (Get-SpecKitInstallCommandText -Version $SpecKitVersion -ForceInstall $true))
        }

        $retryResult = Invoke-NativeCommandForOutput -FilePath 'specify' -ArgumentList $ArgumentList -WorkingDirectory $probeDirectory
        if ($retryResult.ExitCode -eq 0) {
            return Get-SpecifyInitPreflightResult -Ready $true -Repaired $true -RepairOutcome ("reinstalled Spec Kit from official GitHub release {0}" -f (Get-SpecKitGitReference -Version $SpecKitVersion)) -FailureMessage $null
        }

        $retryFailureSummary = Get-FirstNonEmptyOutputLine -OutputLines $retryResult.Output
        return Get-SpecifyInitPreflightResult -Ready $false -Repaired $true -RepairOutcome ("reinstalled Spec Kit from official GitHub release {0}" -f (Get-SpecKitGitReference -Version $SpecKitVersion)) -FailureMessage ("Spec Kit was repaired to the official GitHub release, but `specify init` still failed in preflight: {0}" -f $(if ($retryFailureSummary) { $retryFailureSummary } else { 'specify init exited without any diagnostic output' }))
    }
    finally {
        if (Test-Path -LiteralPath $probeDirectory) {
            Remove-Item -LiteralPath $probeDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-SpecifyInitPreflightResult {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Ready,

        [Parameter(Mandatory = $true)]
        [bool]$Repaired,

        [AllowNull()]
        [string]$RepairOutcome,

        [AllowNull()]
        [string]$FailureMessage
    )

    return [pscustomobject]@{
        Ready          = $Ready
        Repaired       = $Repaired
        RepairOutcome  = $RepairOutcome
        FailureMessage = $FailureMessage
    }
}

function Invoke-SpecKitExtensionDeployment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$FallbackScriptPath,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    $targetExtensionRoot = Join-Path $ProjectPath '.specify\extensions\specrew-speckit'
    if (Test-Path -LiteralPath $targetExtensionRoot) {
        return [pscustomobject]@{
                Action = 'preserved'
                Path   = $targetExtensionRoot
            }
    }

    $extensionSourceRoot = Join-Path $RepoRoot 'extensions\specrew-speckit'
    if (Test-SpecifyExtensionAddAvailable -WorkingDirectory $ProjectPath) {
        if ($PreviewOnly) {
            Write-Host ("[dry-run] specify extension add --dev {0}" -f $extensionSourceRoot) -ForegroundColor Yellow
            return [pscustomobject]@{
                    Action = 'would-install-via-cli'
                    Path   = $targetExtensionRoot
                }
        }

        try {
            Invoke-NativeCommand -FilePath 'specify' -ArgumentList @('extension', 'add', '--dev', $extensionSourceRoot) -WorkingDirectory $ProjectPath
            return [pscustomobject]@{
                    Action = 'installed-via-cli'
                    Path   = $targetExtensionRoot
                }
        }
        catch {
            Write-Host '[info] specify extension add failed; falling back to manual Specrew extension deployment.' -ForegroundColor Yellow
        }
    }

    $null = @(
        & $FallbackScriptPath `
            -ProjectPath $ProjectPath `
            -DryRun:$PreviewOnly `
            -PassThru
    )

    return [pscustomobject]@{
        Action = $(if ($PreviewOnly) { 'would-install-manual-fallback' } else { 'installed-manual-fallback' })
        Path   = $targetExtensionRoot
    }
}

