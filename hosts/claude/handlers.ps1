# Claude host package — handler implementations
#
# Per hosts/_contract.md, exposes the 4 contract functions:
#   - New-ClaudeLaunchInvocation
#   - ConvertTo-ClaudeFlag
#   - Test-ClaudeRuntimeInstalled
#   - Get-ClaudeSignals
#
# Extracted Phase B from:
#   - scripts/specrew-start.ps1 Get-SpecrewHostLaunchInvocation (Claude arm)
#   - scripts/internal/host-flag-translation.ps1 Get-HostFlagTranslation (Claude arms)
#   - scripts/internal/host-runtime-inventory.ps1 Test-ClaudeRuntimeInstalled
#
# Behavior IDENTICAL to the extracted source.
#
# Claude launch shape (verified 2026-05-23 real-launch test): interactive REPL
# uses positional prompt (`claude "<prompt>" --add-dir <path>`). The `-p` / `--print`
# flag is one-shot headless mode and would NOT give the user an interactive Crew session.

Set-StrictMode -Version Latest

function New-ClaudeLaunchInvocation {
    <#
    .SYNOPSIS
    Build the Claude CLI launch invocation per F-040 research.md Task 1.
    .OUTPUTS
    pscustomobject @{ Binary; Args[]; Notices[]; HostKind = 'claude' }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Prompt,
        [Parameter(Mandatory = $true)][string]$Agent,    # ignored; Claude has no --agent flag
        [bool]$AllowAll = $false,
        [bool]$UseAutopilot = $false,
        [bool]$UseRemote = $false
    )

    $hostCmd = Get-Command 'claude' -ErrorAction SilentlyContinue
    $resolvedBinary = if ($null -ne $hostCmd) { $hostCmd.Source } else { 'claude' }

    $argList = New-Object System.Collections.Generic.List[string]
    $notices = New-Object System.Collections.Generic.List[string]

    $argList.Add('--add-dir') | Out-Null
    $argList.Add($ProjectPath) | Out-Null

    if ($AllowAll) {
        $t = ConvertTo-ClaudeFlag -SpecrewFlag '--allow-all'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }
    if ($UseAutopilot) {
        $t = ConvertTo-ClaudeFlag -SpecrewFlag '--autopilot'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }
    if ($UseRemote) {
        $t = ConvertTo-ClaudeFlag -SpecrewFlag '--remote'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }

    # Positional prompt is LAST (interactive launch; not -p / --print)
    $argList.Add($Prompt) | Out-Null

    return [pscustomobject]@{
        Binary   = $resolvedBinary
        Args     = $argList.ToArray()
        Notices  = $notices.ToArray()
        HostKind = 'claude'
    }
}

function ConvertTo-ClaudeFlag {
    <#
    .SYNOPSIS
    Translate a Specrew-side flag to Claude CLI flag(s).
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
                Args            = @('--remote-control')
                Notice          = "Translated --remote to Claude's --remote-control flag."
                SuppressWarning = $true
            }
        }
        '--allow-all' {
            return [pscustomobject]@{
                Args            = @('--dangerously-skip-permissions')
                Notice          = "Translated --allow-all to Claude's --dangerously-skip-permissions flag."
                SuppressWarning = $true
            }
        }
        '--autopilot' {
            return [pscustomobject]@{
                Args            = @()
                Notice          = "Claude Code has no direct equivalent of Copilot's --autopilot. For unattended runs use --autonomous (Specrew's own flag for lifecycle boundary control)."
                SuppressWarning = $false
            }
        }
    }
}

function Test-ClaudeRuntimeInstalled {
    <#
    .SYNOPSIS
    Claude's Crew runtime is .claude/agents/ subagent files (Proposal 024 Slice 3).
    F-043 only detects; does not deploy.
    .OUTPUTS
    bool
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $agentsDir = Join-Path $ProjectPath '.claude\agents'
    if (-not (Test-Path -LiteralPath $agentsDir -PathType Container)) {
        return $false
    }
    $subagentFiles = Get-ChildItem -Path $agentsDir -Filter '*.md' -ErrorAction SilentlyContinue
    return ([bool]$subagentFiles) -and ($subagentFiles.Count -gt 0)
}

function Get-ClaudeSignals {
    <#
    .SYNOPSIS
    Detect Claude-set environment variables.
    .OUTPUTS
    string[] — names of env vars that are set
    #>
    $signals = @()
    foreach ($variableName in @('CLAUDECODE', 'CLAUDE_CODE_SESSION_ID', 'CLAUDE_PROJECT_DIR')) {
        $value = [Environment]::GetEnvironmentVariable($variableName)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $signals += $variableName
        }
    }
    return $signals
}

function ConvertTo-ClaudeAgentDescription {
    param([string]$Charter, [string]$Role)
    return (Get-SpecrewCharterTagline -Charter $Charter -Role $Role)
}

function Install-ClaudeCrewRuntime {
    <#
    .SYNOPSIS
    Deploy Specrew's Crew runtime to .claude/agents/<role>.md from canonical .specrew/team/agents/<role>.md.
    Proposal 108 Slice 9 contract function.
    .DESCRIPTION
    Translates each canonical role-charter (host-neutral markdown) into Claude Code's
    subagent file format: .claude/agents/<role>.md with YAML frontmatter declaring
    `name:` and `description:` (required by Claude Code), followed by the charter body
    as the subagent's system prompt.
    Reference: https://docs.anthropic.com/en/docs/claude-code/sub-agents
    .OUTPUTS
    pscustomobject @{ Actions[]; CrewRuntimePath; Notices[] }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [switch]$DryRun
    )

    $actions = New-Object System.Collections.Generic.List[hashtable]
    $notices = New-Object System.Collections.Generic.List[string]
    $claudeAgentsRoot = Get-SpecrewHostAgentRoot -HostKind 'claude' -ProjectPath $ProjectPath
    if (-not (Test-Path -LiteralPath $claudeAgentsRoot -PathType Container) -and -not $DryRun) {
        New-Item -ItemType Directory -Path $claudeAgentsRoot -Force | Out-Null
    }

    foreach ($role in (Get-SpecrewCanonicalAgentRoles -ProjectPath $ProjectPath)) {
        $content = Get-SpecrewCanonicalCharterContent -ProjectPath $ProjectPath -RoleName $role
        if ([string]::IsNullOrWhiteSpace($content)) {
            $notices.Add("Skipping role '$role': no canonical charter found.") | Out-Null
            continue
        }

        $description = ConvertTo-ClaudeAgentDescription -Charter $content -Role $role
        $frontmatterLines = @(
            '---',
            ('name: {0}' -f $role),
            ('description: {0}' -f ($description -replace '"', '\"')),
            'tools: "*"',
            ('# Specrew-managed: this subagent file is generated from .specrew/team/agents/{0}.md' -f $role),
            ('# DO NOT EDIT HERE. Edit the canonical file at .specrew/team/agents/{0}.md instead.' -f $role),
            '---',
            ''
        )
        $frontmatter = $frontmatterLines -join "`n"

        $target = Join-Path $claudeAgentsRoot ("{0}.md" -f $role)
        if (-not (Test-SpecrewManagedFile -Path $target)) {
            $notices.Add("Preserving user-edited file '$target' (no Specrew-managed marker; delete the file to re-sync from canonical).") | Out-Null
            $actions.Add(@{ Action = 'preserved'; Path = $target; Role = $role }) | Out-Null
            continue
        }
        $finalContent = $frontmatter + $content

        if ($DryRun) {
            $actions.Add(@{ Action = 'would-write'; Path = $target; Role = $role }) | Out-Null
        }
        else {
            [System.IO.File]::WriteAllText($target, $finalContent, [System.Text.UTF8Encoding]::new($false))
            $actions.Add(@{ Action = 'written'; Path = $target; Role = $role }) | Out-Null
        }
    }

    return [pscustomobject]@{
        Actions          = $actions.ToArray()
        CrewRuntimePath  = $claudeAgentsRoot
        Notices          = $notices.ToArray()
    }
}
