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
# Launch shape (verified 2026-05-24 from `agy --help` in user dogfood):
#   `agy -i '<prompt>' --add-dir '<path>' [--dangerously-skip-permissions]`
# The earlier antigravity-followup spec FR-005 shape (`-p ... --output-format json --cwd`)
# was wrong: agy CLI rejects `-output-format` and `--cwd`. Actual flag set per the
# user's `agy --help` output:
#   --add-dir       Add a directory to the workspace (repeatable)
#   -i              Short alias for --prompt-interactive
#   -p              Short alias for --print (non-interactive; not used by specrew start)
#   --dangerously-skip-permissions   Auto-approve all tool permission requests
# Interactive shape (`-i`) matches Claude's launch convention and is what specrew start expects.

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

    # Interactive launch shape (verified from agy --help): `agy -i '<prompt>' --add-dir '<path>'`
    $argList.Add('-i') | Out-Null
    $argList.Add($Prompt) | Out-Null
    $argList.Add('--add-dir') | Out-Null
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
                Args            = @('--dangerously-skip-permissions')
                Notice          = "Translated --allow-all to Antigravity's --dangerously-skip-permissions flag (matches Claude's convention; verified from agy --help)."
                SuppressWarning = $true
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
    $agentFiles = Get-ChildItem -Path $agentsDir -Filter '*.md' -ErrorAction SilentlyContinue
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

function ConvertTo-AntigravityAgentDescription {
    param([string]$Charter, [string]$Role)
    return (Get-SpecrewCharterTagline -Charter $Charter -Role $Role)
}

function Install-AntigravityCrewRuntime {
    <#
    .SYNOPSIS
    Deploy Specrew's Crew runtime to .agents/agents/<role>.md from canonical .specrew/team/agents/<role>.md.
    Proposal 108 Slice 9 contract function.
    .DESCRIPTION
    Antigravity inherits Gemini CLI's subagent file format: .agents/agents/<role>.md with YAML frontmatter
    (name, description required; tools optional with wildcard support). Translates each canonical role-charter
    accordingly. Reference: https://geminicli.com/docs/core/subagents/

    Confidence: medium — Antigravity is still preview-grade as of 2026-05-24 and the public-spec coverage
    of the agent-file format is thinner than Claude/Codex. Smoke-test the result on first use and adjust.
    .OUTPUTS
    pscustomobject @{ Actions[]; CrewRuntimePath; Notices[] }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [switch]$DryRun
    )

    $actions = New-Object System.Collections.Generic.List[hashtable]
    $notices = New-Object System.Collections.Generic.List[string]
    $antigravityAgentsRoot = Get-SpecrewHostAgentRoot -HostKind 'antigravity' -ProjectPath $ProjectPath
    if (-not (Test-Path -LiteralPath $antigravityAgentsRoot -PathType Container) -and -not $DryRun) {
        New-Item -ItemType Directory -Path $antigravityAgentsRoot -Force | Out-Null
    }

    foreach ($role in (Get-SpecrewCanonicalAgentRoles -ProjectPath $ProjectPath)) {
        $content = Get-SpecrewCanonicalCharterContent -ProjectPath $ProjectPath -RoleName $role
        if ([string]::IsNullOrWhiteSpace($content)) {
            $notices.Add("Skipping role '$role': no canonical charter found.") | Out-Null
            continue
        }

        $description = ConvertTo-AntigravityAgentDescription -Charter $content -Role $role
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

        $target = Join-Path $antigravityAgentsRoot ("{0}.md" -f $role)
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
        CrewRuntimePath  = $antigravityAgentsRoot
        Notices          = $notices.ToArray()
    }
}
