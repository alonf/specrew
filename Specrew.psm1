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

    & pwsh -NoProfile -ExecutionPolicy Bypass -File $scriptPath @forwardedArguments
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
