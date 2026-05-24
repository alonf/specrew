# Copilot host package — handler implementations
#
# Per hosts/_contract.md, exposes the 4 contract functions:
#   - New-CopilotLaunchInvocation
#   - ConvertTo-CopilotFlag
#   - Test-CopilotRuntimeInstalled
#   - Get-CopilotSignals
#
# Extracted Phase B from:
#   - scripts/specrew-start.ps1 Get-SpecrewHostLaunchInvocation (Copilot arm)
#   - scripts/internal/host-flag-translation.ps1 Get-HostFlagTranslation (Copilot arms)
#   - scripts/internal/host-runtime-inventory.ps1 Test-CopilotRuntimeInstalled
#   - scripts/specrew-init.ps1 Get-CopilotSignals
#
# Behavior IDENTICAL to the extracted source. Legacy functions remain as
# thin shims during Phase B; final cleanup removes shims in a later phase.

Set-StrictMode -Version Latest

function New-CopilotLaunchInvocation {
    <#
    .SYNOPSIS
    Build the Copilot CLI launch invocation per F-040 research.md Task 1.
    .OUTPUTS
    pscustomobject @{ Binary; Args[]; Notices[]; HostKind = 'copilot' }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Prompt,
        [Parameter(Mandatory = $true)][string]$Agent,
        [bool]$AllowAll = $false,
        [bool]$UseAutopilot = $false,
        [bool]$UseRemote = $false
    )

    $hostCmd = Get-Command 'copilot' -ErrorAction SilentlyContinue
    $resolvedBinary = if ($null -ne $hostCmd) { $hostCmd.Source } else { 'copilot' }

    $argList = New-Object System.Collections.Generic.List[string]
    $notices = New-Object System.Collections.Generic.List[string]

    $argList.Add('--agent') | Out-Null
    $argList.Add($Agent) | Out-Null
    if ($UseAutopilot) {
        $t = ConvertTo-CopilotFlag -SpecrewFlag '--autopilot'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
    }
    $argList.Add('--add-dir') | Out-Null
    $argList.Add($ProjectPath) | Out-Null
    $argList.Add('-i') | Out-Null
    $argList.Add($Prompt) | Out-Null
    if ($AllowAll) {
        $t = ConvertTo-CopilotFlag -SpecrewFlag '--allow-all'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
    }
    if ($UseRemote) {
        $t = ConvertTo-CopilotFlag -SpecrewFlag '--remote'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
    }

    return [pscustomobject]@{
        Binary   = $resolvedBinary
        Args     = $argList.ToArray()
        Notices  = $notices.ToArray()
        HostKind = 'copilot'
    }
}

function ConvertTo-CopilotFlag {
    <#
    .SYNOPSIS
    Translate a Specrew-side flag to Copilot CLI flag(s).
    .OUTPUTS
    pscustomobject @{ Args[]; Notice; SuppressWarning }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('--remote', '--allow-all', '--autopilot')]
        [string]$SpecrewFlag
    )

    switch ($SpecrewFlag) {
        '--remote'     { return [pscustomobject]@{ Args = @('--remote');     Notice = ''; SuppressWarning = $true } }
        '--allow-all'  { return [pscustomobject]@{ Args = @('--allow-all');  Notice = ''; SuppressWarning = $true } }
        '--autopilot'  { return [pscustomobject]@{ Args = @('--autopilot'); Notice = ''; SuppressWarning = $true } }
    }
}

function Test-CopilotRuntimeInstalled {
    <#
    .SYNOPSIS
    Copilot's Crew runtime is Squad. Detect via .squad/ directory.
    .OUTPUTS
    bool
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $squadDir = Join-Path $ProjectPath '.squad'
    return [bool](Test-Path -LiteralPath $squadDir -PathType Container)
}

function Get-CopilotSignals {
    <#
    .SYNOPSIS
    Detect Copilot-set environment variables (run-time host context).
    .OUTPUTS
    string[] — names of env vars that are set
    #>
    $signals = @()
    foreach ($variableName in @('COPILOT_CLI', 'COPILOT_AGENT_SESSION_ID', 'COPILOT_CLI_BINARY_VERSION')) {
        $value = [Environment]::GetEnvironmentVariable($variableName)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $signals += $variableName
        }
    }
    return $signals
}
