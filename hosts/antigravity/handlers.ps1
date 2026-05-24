# Antigravity host package — handler implementations
#
# Per hosts/_contract.md, exposes the 4 contract functions:
#   - New-AntigravityLaunchInvocation
#   - ConvertTo-AntigravityFlag
#   - Test-AntigravityRuntimeInstalled
#   - Get-AntigravitySignals
#
# Status: PROMOTED from deferred to supported via this Phase B extraction
# (per user directive 2026-05-24 Q3: antigravity-followup slice folds into refactor).
#
# Launch shape (per antigravity-followup spec FR-005): `agy -p '<prompt>' --output-format json [--cwd <path>]`
# Hands-on confirmation pending; flag set is canonical per Antigravity public docs.

Set-StrictMode -Version Latest

function New-AntigravityLaunchInvocation {
    <#
    .SYNOPSIS
    Build the Antigravity CLI launch invocation per F-040 + antigravity-followup spec.
    .OUTPUTS
    pscustomobject @{ Binary; Args[]; Notices[]; HostKind = 'antigravity' }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Prompt,
        [Parameter(Mandatory = $true)][string]$Agent,    # ignored; Antigravity has no --agent flag
        [bool]$AllowAll = $false,
        [bool]$UseAutopilot = $false,
        [bool]$UseRemote = $false
    )

    $hostCmd = Get-Command 'agy' -ErrorAction SilentlyContinue
    $resolvedBinary = if ($null -ne $hostCmd) { $hostCmd.Source } else { 'agy' }

    $argList = New-Object System.Collections.Generic.List[string]
    $notices = New-Object System.Collections.Generic.List[string]

    # Per antigravity-followup spec FR-005: `agy -p '<prompt>' --output-format json [--cwd <path>]`
    $argList.Add('-p') | Out-Null
    $argList.Add($Prompt) | Out-Null
    $argList.Add('--output-format') | Out-Null
    $argList.Add('json') | Out-Null
    $argList.Add('--cwd') | Out-Null
    $argList.Add($ProjectPath) | Out-Null

    if ($AllowAll) {
        $t = ConvertTo-AntigravityFlag -SpecrewFlag '--allow-all'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }
    if ($UseAutopilot) {
        $t = ConvertTo-AntigravityFlag -SpecrewFlag '--autopilot'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }
    if ($UseRemote) {
        $t = ConvertTo-AntigravityFlag -SpecrewFlag '--remote'
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }

    return [pscustomobject]@{
        Binary   = $resolvedBinary
        Args     = $argList.ToArray()
        Notices  = $notices.ToArray()
        HostKind = 'antigravity'
    }
}

function ConvertTo-AntigravityFlag {
    <#
    .SYNOPSIS
    Translate a Specrew-side flag to Antigravity CLI flag(s).
    Translations are UNVERIFIED for Antigravity (no verified remote/allow-all/autopilot equivalents);
    each arm warns rather than silently dropping.
    .OUTPUTS
    pscustomobject @{ Args[]; Notice; SuppressWarning }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('--remote', '--allow-all', '--autopilot')]
        [string]$SpecrewFlag
    )

    switch ($SpecrewFlag) {
        '--remote' {
            return [pscustomobject]@{
                Args            = @()
                Notice          = 'Antigravity CLI does not expose a verified remote-control flag today; continuing launch without remote-control wiring.'
                SuppressWarning = $false
            }
        }
        '--allow-all' {
            return [pscustomobject]@{
                Args            = @()
                Notice          = 'Antigravity --allow-all mapping is unverified; launching without a host-side permission-bypass flag. Use ANTIGRAVITY_API_KEY env var for headless authentication.'
                SuppressWarning = $false
            }
        }
        '--autopilot' {
            return [pscustomobject]@{
                Args            = @()
                Notice          = "Antigravity has no verified autopilot equivalent; for unattended runs, use Specrew's --autonomous flag for lifecycle boundary control."
                SuppressWarning = $false
            }
        }
    }
}

function Test-AntigravityRuntimeInstalled {
    <#
    .SYNOPSIS
    Antigravity's Crew runtime convention is .agents/agents/ (per antigravity-followup spec).
    Pending Proposal 024 Slice 3 deploy logic; F-043 only detects.
    .OUTPUTS
    bool
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $agentsDir = Join-Path $ProjectPath '.agents\agents'
    if (-not (Test-Path -LiteralPath $agentsDir -PathType Container)) {
        return $false
    }
    $agentFiles = Get-ChildItem -Path $agentsDir -ErrorAction SilentlyContinue
    return ([bool]$agentFiles) -and ($agentFiles.Count -gt 0)
}

function Get-AntigravitySignals {
    <#
    .SYNOPSIS
    Detect Antigravity-set environment variables. Includes Gemini-deadline-relevant vars.
    .OUTPUTS
    string[] — names of env vars that are set
    #>
    $signals = @()
    foreach ($variableName in @('ANTIGRAVITY_API_KEY', 'ANTIGRAVITY_SESSION_ID', 'GOOGLE_AI_SUBSCRIPTION_TIER')) {
        $value = [Environment]::GetEnvironmentVariable($variableName)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $signals += $variableName
        }
    }
    return $signals
}
