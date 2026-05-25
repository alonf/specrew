# Dependency-install + validation helpers for specrew-init.ps1 (extracted via Proposal 108 Slice 5)
#
# Depends on: scripts/init/_utilities.ps1 (Invoke-NativeCommand*, Add-Action,
# Invoke-WithNativeCommandEncoding); scripts/init/spec-kit-deploy.ps1 (Get-SpecKitInstallArguments
# called from Install-MissingDependency on the Spec Kit branch).
#
# Functions:
#   - Install-MissingDependency           install Spec Kit (uv) or Squad CLI (npm)
#   - Invoke-VersionValidation            shell out to extensions/specrew-speckit/scripts/validate-versions.ps1
#   - Get-DependencyValidationIssue       translate validator results to issue list
#   - Resolve-DependencyValidationIssue   resolve issues + log actions
#
# Squad coupling: Install-MissingDependency hardcodes `npm install -g @bradygaster/squad-cli`
# for the Squad branch. This is the Squad-only deployment path; moves to hosts/copilot/handlers.ps1
# as part of Install-CopilotHostRuntime when Proposal 024 Slice 3 ships. Allow-listed in the
# host-coupling firewall test for now via specrew-init.ps1 wholesale entry.

Set-StrictMode -Version Latest

function Install-MissingDependency {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Dependency,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    switch ($Dependency.Platform) {
        'Spec Kit' {
            if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
                throw "Spec Kit is missing and 'uv' is not available to install it."
            }

            $command = 'uv'
            $arguments = Get-SpecKitInstallArguments -Version $Dependency.MinimumVersion -ForceInstall $false
        }
        'Squad' {
            if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
                throw "Squad is missing and 'npm' is not available to install it."
            }

            $command = 'npm'
            $arguments = @('install', '-g', ('@bradygaster/squad-cli@{0}' -f $Dependency.MinimumVersion))
        }
        default {
            throw "Unsupported dependency platform '$($Dependency.Platform)'."
        }
    }

    if ($PreviewOnly) {
        Write-Host ("[dry-run] {0} {1}" -f $command, ($arguments -join ' ')) -ForegroundColor Yellow
        return
    }

    & $command @arguments
    if ((Get-NativeExitCode) -ne 0) {
        throw ("Failed to install {0}." -f $Dependency.Platform)
    }
}

function Invoke-VersionValidation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$MinimumSpecKitVersion,

        [Parameter(Mandatory = $true)]
        [string]$MinimumSquadVersion
    )

    try {
        return @(& $ScriptPath -MinimumSpecKitVersion $MinimumSpecKitVersion -MinimumSquadVersion $MinimumSquadVersion -PassThru)
    }
    catch {
        Write-Error ("Dependency validation failed unexpectedly. Re-run '{0}' directly for details. {1}" -f $ScriptPath, $_.Exception.Message)
        exit 4
    }
}

function Get-DependencyValidationIssue {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Results,

        [Parameter(Mandatory = $true)]
        [bool]$IncludeMissing,

        [Parameter(Mandatory = $true)]
        [bool]$AfterInstallAttempt
    )

    $failures = [System.Collections.ArrayList]::new()

    if ($IncludeMissing) {
        foreach ($dependency in @($Results | Where-Object { -not $_.IsInstalled })) {
            $message = if ($AfterInstallAttempt) {
                "{0} is still not installed after the installation attempt. Run '{1}' to install it, then re-run specrew init." -f $dependency.Platform, $dependency.SuggestedInstall
            }
            else {
                "{0} is not installed. Run '{1}'." -f $dependency.Platform, $dependency.SuggestedInstall
            }

            $null = $failures.Add([pscustomobject]@{
                    ExitCode = 4
                    Message  = $message
                    Outcome  = ("{0}: missing ({1})" -f $dependency.Platform, $dependency.SuggestedInstall)
                })
        }
    }

    foreach ($dependency in @($Results | Where-Object { $_.IsInstalled -and -not $_.IsOperational })) {
        $failureDetail = if ($dependency.ProbeError) { $dependency.ProbeError } elseif ($dependency.ValidationError) { $dependency.ValidationError } else { 'the command did not complete successfully' }
        $message = "{0} is installed but the '{1}' command is not healthy ({2}). Run '{3}' to repair it, then re-run specrew init." -f $dependency.Platform, $dependency.CommandName, $failureDetail, $dependency.SuggestedRepair

        $null = $failures.Add([pscustomobject]@{
                ExitCode = 1
                Message  = $message
                Outcome  = ("{0}: requires repair ({1})" -f $dependency.Platform, $dependency.SuggestedRepair)
            })
    }

    foreach ($dependency in @($Results | Where-Object { $_.IsInstalled -and -not $_.IsCompatible })) {
        $message = "Specrew requires {0} >= {1} but found {2}. Run '{3}' to upgrade." -f $dependency.Platform, $dependency.MinimumVersion, $dependency.Version, $dependency.SuggestedUpgrade

        $null = $failures.Add([pscustomobject]@{
                ExitCode = 1
                Message  = $message
                Outcome  = ("{0}: requires upgrade ({1})" -f $dependency.Platform, $dependency.SuggestedUpgrade)
            })
    }

    return @($failures)
}

function Resolve-DependencyValidationIssue {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Results,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly,

        [Parameter(Mandatory = $true)]
        [bool]$IncludeMissing,

        [Parameter(Mandatory = $true)]
        [bool]$AfterInstallAttempt
    )

    $failures = @(Get-DependencyValidationIssue -Results $Results -IncludeMissing $IncludeMissing -AfterInstallAttempt $AfterInstallAttempt)
    if ($failures.Count -eq 0) {
        return 0
    }

    foreach ($failure in $failures) {
        if ($PreviewOnly) {
            Write-Warning ("[dry-run] {0}" -f $failure.Message)
            Add-Action -Actions $Actions -Step 'dependency' -Outcome $failure.Outcome
            continue
        }

        Write-Error $failure.Message -ErrorAction Continue
    }

    if ($failures.ExitCode -contains 4) {
        return 4
    }

    return 1
}

