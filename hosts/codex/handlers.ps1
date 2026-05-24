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

function ConvertTo-CodexAgentDescription {
    param([string]$Charter, [string]$Role)
    return (Get-SpecrewCharterTagline -Charter $Charter -Role $Role)
}

function ConvertTo-CodexTomlString {
    # Minimal TOML triple-quoted string with backslash + triple-quote escaping
    param([string]$Value)
    $escaped = $Value -replace '\\', '\\\\'
    $escaped = $escaped -replace '"""', '\"\"\"'
    return ('"""{0}{1}{0}"""' -f [Environment]::NewLine, $escaped)
}

function Install-CodexCrewRuntime {
    <#
    .SYNOPSIS
    Deploy Specrew's Crew runtime to .codex/agents/<role>.toml from canonical .specrew/team/agents/<role>.md.
    Proposal 108 Slice 9 contract function.
    .DESCRIPTION
    Translates each canonical role-charter into Codex CLI's subagent file format:
    .codex/agents/<role>.toml with required `name`, `description`, `developer_instructions` fields.
    The charter markdown body becomes the developer_instructions multi-line TOML string.
    Reference: https://developers.openai.com/codex/subagents
    .OUTPUTS
    pscustomobject @{ Actions[]; CrewRuntimePath; Notices[] }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [switch]$DryRun
    )

    $actions = New-Object System.Collections.Generic.List[hashtable]
    $notices = New-Object System.Collections.Generic.List[string]
    $codexAgentsRoot = Get-SpecrewHostAgentRoot -HostKind 'codex' -ProjectPath $ProjectPath
    if (-not (Test-Path -LiteralPath $codexAgentsRoot -PathType Container) -and -not $DryRun) {
        New-Item -ItemType Directory -Path $codexAgentsRoot -Force | Out-Null
    }

    foreach ($role in (Get-SpecrewCanonicalAgentRoles -ProjectPath $ProjectPath)) {
        $content = Get-SpecrewCanonicalCharterContent -ProjectPath $ProjectPath -RoleName $role
        if ([string]::IsNullOrWhiteSpace($content)) {
            $notices.Add("Skipping role '$role': no canonical charter found.") | Out-Null
            continue
        }

        $description = ConvertTo-CodexAgentDescription -Charter $content -Role $role
        $developerInstructions = ConvertTo-CodexTomlString -Value $content
        # Codex TOML: name + description + developer_instructions required
        $tomlLines = @(
            ('# Specrew-managed: this Codex subagent file is generated from .specrew/team/agents/{0}.md' -f $role),
            ('# DO NOT EDIT HERE. Edit the canonical file at .specrew/team/agents/{0}.md instead.' -f $role),
            '',
            ('name = "{0}"' -f $role),
            ('description = "{0}"' -f ($description -replace '\\', '\\\\' -replace '"', '\"')),
            ('developer_instructions = {0}' -f $developerInstructions),
            ''
        )
        $toml = $tomlLines -join "`n"

        $target = Join-Path $codexAgentsRoot ("{0}.toml" -f $role)
        if (-not (Test-SpecrewManagedFile -Path $target)) {
            $notices.Add("Preserving user-edited file '$target' (no Specrew-managed marker; delete the file to re-sync from canonical).") | Out-Null
            $actions.Add(@{ Action = 'preserved'; Path = $target; Role = $role }) | Out-Null
            continue
        }
        if ($DryRun) {
            $actions.Add(@{ Action = 'would-write'; Path = $target; Role = $role }) | Out-Null
        }
        else {
            [System.IO.File]::WriteAllText($target, $toml, [System.Text.UTF8Encoding]::new($false))
            $actions.Add(@{ Action = 'written'; Path = $target; Role = $role }) | Out-Null
        }
    }

    return [pscustomobject]@{
        Actions          = $actions.ToArray()
        CrewRuntimePath  = $codexAgentsRoot
        Notices          = $notices.ToArray()
    }
}
