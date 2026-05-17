Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptRoot = $PSScriptRoot
$scriptsPath = Join-Path -Path $ScriptRoot -ChildPath 'scripts'
$internalScriptsPath = Join-Path -Path $scriptsPath -ChildPath 'internal'

. (Join-Path -Path $internalScriptsPath -ChildPath 'dashboard-renderer.ps1')

$script:SpecrewScriptMap = [ordered]@{
    'specrew'        = Join-Path -Path $scriptsPath -ChildPath 'specrew.ps1'
    'specrew-init'   = Join-Path -Path $scriptsPath -ChildPath 'specrew-init.ps1'
    'specrew-review' = Join-Path -Path $scriptsPath -ChildPath 'specrew-review.ps1'
    'specrew-start'  = Join-Path -Path $scriptsPath -ChildPath 'specrew-start.ps1'
    'specrew-team'   = Join-Path -Path $scriptsPath -ChildPath 'specrew-team.ps1'
    'specrew-update' = Join-Path -Path $scriptsPath -ChildPath 'specrew-update.ps1'
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

    $env:SPECREW_INVOKED_FROM_MODULE = '1'
    try {
        # `specrew start` on Linux/macOS launches `copilot` as a child process
        # that needs a direct parent/child relationship to the user's interactive
        # pwsh to keep its REPL alive (Copilot CLI v1.0.48 on Linux exits the
        # agent loop when launched through an intermediate `pwsh -File`
        # subprocess). Run the script in-process for this case so `& copilot`
        # inside the script becomes a direct child of the caller's pwsh.
        #
        # The user-facing command is typically `specrew start` (CommandName =
        # 'specrew', first argument = 'start'); the direct `specrew-start`
        # function form is also supported. Both forms route here.
        #
        # Other commands keep the subprocess for clean profile/policy isolation.
        $isStartCommand = (
            ($CommandName -eq 'specrew-start') -or
            ($CommandName -eq 'specrew' -and
             $forwardedArguments.Count -gt 0 -and
             "$($forwardedArguments[0])" -eq 'start')
        )
        $needsInProcessLaunch = $isStartCommand -and -not $IsWindows

        if ($needsInProcessLaunch) {
            & $scriptPath @forwardedArguments
        }
        else {
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $scriptPath @forwardedArguments
        }
    }
    finally {
        Remove-Item -LiteralPath 'env:SPECREW_INVOKED_FROM_MODULE' -ErrorAction SilentlyContinue
    }
}

function specrew {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew' -Arguments $Arguments
}

function specrew-init {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-init' -Arguments $Arguments
}

function specrew-review {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-review' -Arguments $Arguments
}

function specrew-start {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-start' -Arguments $Arguments
}

function specrew-team {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-team' -Arguments $Arguments
}

function specrew-update {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-update' -Arguments $Arguments
}

function specrew-where {
    [CmdletBinding()]
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][object[]]$Arguments)
    Invoke-SpecrewScript -CommandName 'specrew-where' -Arguments $Arguments
}

Export-ModuleMember -Function @(
    'specrew',
    'specrew-init',
    'specrew-start',
    'specrew-update',
    'specrew-review',
    'specrew-team',
    'specrew-where'
)
