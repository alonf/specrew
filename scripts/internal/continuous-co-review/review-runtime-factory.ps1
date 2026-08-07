$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function New-ReviewUnavailableProductionRuntimePort {
    param([string]$Reason = 'production-runtime-unsupported-platform')
    $preflight = { param($invocation) [pscustomobject]@{ ok = $false; reason = $Reason } }.GetNewClosure()
    $invoke = { param($harness, $invocation, $onStarted, $environment) throw $Reason }.GetNewClosure()
    $recover = { param($receipt) [pscustomobject]@{ termination_verified = $false; containment = 'unknown'; process_tree_live = $null; failure_reason = $Reason } }.GetNewClosure()
    return [pscustomobject]@{ id = 'unavailable-runtime'; platform = 'unknown'; containment = 'unknown'; preflight = $preflight; invoke = $invoke; recover = $recover }
}

function New-ReviewProductionRuntimePort {
    [CmdletBinding()]
    param([ValidateRange(1, 7200)][int]$TimeoutSeconds = 900)
    if ($IsWindows) { return New-ReviewWindowsRuntimePort -TimeoutSeconds $TimeoutSeconds }
    if ($IsLinux) { return New-ReviewLinuxRuntimePort -TimeoutSeconds $TimeoutSeconds }
    if ($IsMacOS) { return New-ReviewMacOSRuntimePort -TimeoutSeconds $TimeoutSeconds }
    return New-ReviewUnavailableProductionRuntimePort
}
