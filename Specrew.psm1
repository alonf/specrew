Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptRoot = $PSScriptRoot
$scriptsPath = Join-Path -Path $ScriptRoot -ChildPath 'scripts'
$internalScriptsPath = Join-Path -Path $scriptsPath -ChildPath 'internal'

# F-044 iter-006 T001: announce this Specrew tree to child PowerShell processes
# so agent-spawned shells (e.g., `powershell -File .specify/.../sync-boundary-state.ps1`)
# dispatch here instead of a stale PSGallery install. Env vars inherit across child
# processes automatically.
$env:SPECREW_MODULE_PATH = $ScriptRoot

. (Join-Path -Path $internalScriptsPath -ChildPath 'dashboard-renderer.ps1')

$script:SpecrewScriptMap = [ordered]@{
    'specrew'        = Join-Path -Path $scriptsPath -ChildPath 'specrew.ps1'
    'specrew-init'   = Join-Path -Path $scriptsPath -ChildPath 'specrew-init.ps1'
    'specrew-review' = Join-Path -Path $scriptsPath -ChildPath 'specrew-review.ps1'
    'specrew-start'  = Join-Path -Path $scriptsPath -ChildPath 'specrew-start.ps1'
    'specrew-team'   = Join-Path -Path $scriptsPath -ChildPath 'specrew-team.ps1'
    'specrew-update' = Join-Path -Path $scriptsPath -ChildPath 'specrew-update.ps1'
    'specrew-version' = Join-Path -Path $scriptsPath -ChildPath 'specrew-version.ps1'
    'specrew-where'  = Join-Path -Path $scriptsPath -ChildPath 'specrew-where.ps1'
}

function Invoke-SpecrewScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,

        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Arguments
    )

    $scriptPath = $script:SpecrewScriptMap[$CommandName]
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        throw "Missing Specrew script '$scriptPath'."
    }

    $forwardedArguments = @($Arguments)
    if ($forwardedArguments.Count -eq 1 -and $forwardedArguments[0] -is [System.Array]) {
        $forwardedArguments = @($forwardedArguments[0])
    }

    # On Linux/macOS, `specrew start` needs a special launch path because
    # PowerShell on Linux strips TTY from native command children when invoked
    # from a script body (empirically verified: even nano's TUI fails to
    # render when launched via `& nano` inside a .ps1). PowerShell FUNCTION
    # bodies, however, do preserve TTY. So for `specrew start` on Linux/macOS:
    #
    # 1. The script (specrew-start.ps1) does all prep work but writes the
    #    final `copilot` launch args to a deferred-launch file instead of
    #    invoking copilot itself.
    # 2. After the script returns, THIS function (Invoke-SpecrewScript) reads
    #    the deferred-launch file and invokes `& copilot @args` from its own
    #    body — function context, TTY preserved → Copilot TUI renders.
    #
    # The user-facing command is typically `specrew start` (CommandName =
    # 'specrew', first argument = 'start'); the direct `specrew-start`
    # function form is also supported. Both forms route here.
    $isStartCommand = (
        ($CommandName -eq 'specrew-start') -or
        ($CommandName -eq 'specrew' -and
         $forwardedArguments.Count -gt 0 -and
         "$($forwardedArguments[0])" -eq 'start')
    )
    $needsDeferredLaunch = $isStartCommand -and -not $IsWindows

    $deferredLaunchFile = $null
    if ($needsDeferredLaunch) {
        $deferredLaunchFile = [System.IO.Path]::Combine(
            [System.IO.Path]::GetTempPath(),
            "specrew-deferred-launch-$([guid]::NewGuid().ToString()).json"
        )
        $env:SPECREW_DEFERRED_LAUNCH_FILE = $deferredLaunchFile
    }

    $env:SPECREW_INVOKED_FROM_MODULE = '1'
    try {
        if ($needsDeferredLaunch) {
            # In-process invocation so the script can write the deferred-launch
            # file to a location this function can read after the script returns.
            & $scriptPath @forwardedArguments
        }
        else {
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $scriptPath @forwardedArguments
        }

        # After the script returns, check for a deferred launch request.
        if ($needsDeferredLaunch -and (Test-Path -LiteralPath $deferredLaunchFile -PathType Leaf)) {
            try {
                $launchInfo = Get-Content -LiteralPath $deferredLaunchFile -Raw -Encoding UTF8 | ConvertFrom-Json
                $copilotPath = [string]$launchInfo.CopilotPath
                $copilotArgs = @($launchInfo.CopilotArgs)
                $workingDirectory = [string]$launchInfo.WorkingDirectory

                Push-Location -LiteralPath $workingDirectory
                try {
                    # Function-body invocation: PowerShell on Linux preserves
                    # TTY for native command children when called from a
                    # function body (vs a script body which strips it).
                    & $copilotPath @copilotArgs
                }
                finally {
                    Pop-Location
                }
            }
            finally {
                Remove-Item -LiteralPath $deferredLaunchFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
    finally {
        Remove-Item -LiteralPath 'env:SPECREW_INVOKED_FROM_MODULE' -ErrorAction SilentlyContinue
        if ($needsDeferredLaunch) {
            Remove-Item -LiteralPath 'env:SPECREW_DEFERRED_LAUNCH_FILE' -ErrorAction SilentlyContinue
        }
    }
}

# Functions use PowerShell's approved Verb-Noun naming convention so
# `Import-Module Specrew.psd1` does NOT emit the "unapproved verbs" warning.
# The CLI-friendly names users actually type (`specrew`, `specrew-start`,
# `specrew-init`, etc.) are exposed as aliases below — aliases don't trigger
# the verb-check warning, so users keep their muscle memory.

function Invoke-Specrew {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew' -Arguments $Arguments
}

function Initialize-Specrew {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-init' -Arguments $Arguments
}

function Show-SpecrewReview {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-review' -Arguments $Arguments
}

function Start-Specrew {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-start' -Arguments $Arguments
}

function Invoke-SpecrewTeam {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-team' -Arguments $Arguments
}

function Update-Specrew {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-update' -Arguments $Arguments
}

function Show-SpecrewVersion {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-version' -Arguments $Arguments
}

function Show-SpecrewStatus {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-where' -Arguments $Arguments
}

# CLI-friendly aliases so users continue typing the names they already know.
# These don't trigger the unapproved-verb warning that the function names did.
Set-Alias -Name 'specrew'         -Value 'Invoke-Specrew'        -Force
Set-Alias -Name 'specrew-init'    -Value 'Initialize-Specrew'    -Force
Set-Alias -Name 'specrew-review'  -Value 'Show-SpecrewReview'    -Force
Set-Alias -Name 'specrew-start'   -Value 'Start-Specrew'         -Force
Set-Alias -Name 'specrew-team'    -Value 'Invoke-SpecrewTeam'    -Force
Set-Alias -Name 'specrew-update'  -Value 'Update-Specrew'        -Force
Set-Alias -Name 'specrew-version' -Value 'Show-SpecrewVersion'   -Force
Set-Alias -Name 'specrew-where'   -Value 'Show-SpecrewStatus'    -Force

Export-ModuleMember `
    -Function @(
        'Invoke-Specrew',
        'Initialize-Specrew',
        'Start-Specrew',
        'Update-Specrew',
        'Show-SpecrewVersion',
        'Show-SpecrewReview',
        'Invoke-SpecrewTeam',
        'Show-SpecrewStatus'
    ) `
    -Alias @(
        'specrew',
        'specrew-init',
        'specrew-start',
        'specrew-update',
        'specrew-version',
        'specrew-review',
        'specrew-team',
        'specrew-where'
    )
