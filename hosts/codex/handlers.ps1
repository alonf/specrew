# Codex host package — handler implementations
#
# Per hosts/_contract.md, exposes the 4 contract functions:
#   - New-CodexLaunchInvocation
#   - ConvertTo-CodexFlag
#   - Test-CodexRuntimeInstalled
#   - Get-CodexSignals
#
# Extracted Phase B from:
#   - scripts/specrew-start.ps1 Get-SpecrewHostLaunchInvocation (Codex arm)
#   - scripts/internal/host-flag-translation.ps1 Get-HostFlagTranslation (Codex arms)
#   - scripts/internal/host-runtime-inventory.ps1 Test-CodexRuntimeInstalled
#
# Behavior IDENTICAL to the extracted source.
#
# Codex launch shape (verified 2026-05-23 real-launch test + 2026-05-24 deep review):
# interactive REPL uses positional prompt (`codex "<prompt>" --cd <path>`). `codex exec`
# is the batch / non-interactive subcommand and is NOT used by F-040.
#
# Codex flag note (verified 2026-05-24 via `codex --help`): `--full-auto` is deprecated
# AND is `codex exec`-only. The full-equivalent of Claude's --dangerously-skip-permissions
# is `--dangerously-bypass-approvals-and-sandbox` (long form of `--yolo`).

Set-StrictMode -Version Latest

function New-CodexLaunchInvocation {
    <#
    .SYNOPSIS
    Build the Codex CLI launch invocation per F-040 research.md Task 1.
    .OUTPUTS
    pscustomobject @{ Binary; Args[]; Notices[]; HostKind = 'codex' }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Prompt,
        [Parameter(Mandatory = $true)][string]$Agent,    # ignored; Codex has no --agent flag
        [bool]$AllowAll = $false,
        [bool]$UseAutopilot = $false,
        [bool]$UseRemote = $false
    )

    $hostCmd = Get-Command 'codex' -ErrorAction SilentlyContinue
    $resolvedBinary = if ($null -ne $hostCmd) { $hostCmd.Source } else { 'codex' }

    $argList = New-Object System.Collections.Generic.List[string]
    $notices = New-Object System.Collections.Generic.List[string]

    $argList.Add('--cd') | Out-Null
    $argList.Add($ProjectPath) | Out-Null

    if ($AllowAll) {
        $t = ConvertTo-CodexFlag -SpecrewFlag '--allow-all'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }
    if ($UseAutopilot) {
        $t = ConvertTo-CodexFlag -SpecrewFlag '--autopilot'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }
    if ($UseRemote) {
        $t = ConvertTo-CodexFlag -SpecrewFlag '--remote'
        # Codex has no remote-control wiring; surface notice but inject no args
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }

    # Positional prompt is LAST (interactive launch; not `codex exec`)
    $argList.Add($Prompt) | Out-Null

    return [pscustomobject]@{
        Binary   = $resolvedBinary
        Args     = $argList.ToArray()
        Notices  = $notices.ToArray()
        HostKind = 'codex'
    }
}

function ConvertTo-CodexFlag {
    <#
    .SYNOPSIS
    Translate a Specrew-side flag to Codex CLI flag(s).
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
                Notice          = 'Codex CLI does not expose a remote-control flag today; continuing launch without remote-control wiring.'
                SuppressWarning = $false
            }
        }
        '--allow-all' {
            return [pscustomobject]@{
                Args            = @('--dangerously-bypass-approvals-and-sandbox')
                Notice          = "Translated --allow-all to Codex's --dangerously-bypass-approvals-and-sandbox flag (full equivalent of Claude's --dangerously-skip-permissions)."
                SuppressWarning = $true
            }
        }
        '--autopilot' {
            return [pscustomobject]@{
                Args            = @()
                Notice          = "Codex's autopilot equivalent is --dangerously-bypass-approvals-and-sandbox, which is already mapped from --allow-all. --autopilot is a no-op when --allow-all is also set."
                SuppressWarning = $true
            }
        }
    }
}

function Test-CodexRuntimeInstalled {
    <#
    .SYNOPSIS
    Codex's Crew runtime is .codex/agents/ TOML files (Proposal 024 Slice 3).
    F-043 only detects; does not deploy.
    .OUTPUTS
    bool
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $agentsDir = Join-Path $ProjectPath '.codex\agents'
    if (-not (Test-Path -LiteralPath $agentsDir -PathType Container)) {
        return $false
    }
    $tomlFiles = Get-ChildItem -Path $agentsDir -Filter '*.toml' -ErrorAction SilentlyContinue
    return ([bool]$tomlFiles) -and ($tomlFiles.Count -gt 0)
}

function Get-CodexSignals {
    <#
    .SYNOPSIS
    Detect Codex-set environment variables.
    .OUTPUTS
    string[] — names of env vars that are set
    #>
    $signals = @()
    foreach ($variableName in @('CODEX_SESSION_ID', 'OPENAI_CODEX_CLI', 'CODEX_API_KEY')) {
        $value = [Environment]::GetEnvironmentVariable($variableName)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $signals += $variableName
        }
    }
    return $signals
}
