# Devin host package — handler implementations
#
# Per hosts/_contract.md, exposes the 5 contract functions:
#   - New-DevinLaunchInvocation
#   - ConvertTo-DevinFlag
#   - Test-DevinRuntimeInstalled
#   - Get-DevinSignals
#   - Install-DevinCrewRuntime
#
# Feature 200 task split note: this file is created in T007 to satisfy FR-005 ("hosts/devin/
# MUST contain ... all five existing contract-handler implementations ... package validation
# MUST work") and the FileList generator (update-host-package-filelist.ps1), which requires all
# three contract files for EVERY package. The handler BEHAVIOR (FR-007 launch/flag mapping and
# FR-008 nested Crew runtime) and its argv/parity tests are T010. The implementations here are
# functional, not stubs: launch uses a positional prompt, permission modes map normal->auto /
# autopilot->smart / allow-all->dangerous with dangerous precedence + an explicit notice (FR-007),
# and Crew runtime deploys nested .devin/agents/<name>/AGENT.md (FR-008).
#
# Devin launch shape (FR-007, verified against the pinned CLI `devin 2026.7.23 (3bd47f77)`):
# `devin [OPTIONS] [-- <PROMPT>...]` — interactive launch with the bootstrap prompt POSITIONAL after
# a `--` option-terminator. There is NO --cwd flag; Devin operates on the process working directory
# (set by the launcher via Start-Process -WorkingDirectory). `devin -p` is reserved for bounded
# smoke/canary automation and is NOT used for the normal governed session.
#
# Bootstrap-prompt delivery (design call): the prompt is passed POSITIONALLY (after `--`) to match
# the established claude/codex positional-prompt convention, keeping the launch shape uniform across
# hosts. Devin's `--prompt-file <FILE>` is the documented fallback should bootstrap-prompt length
# become a launch problem (Specrew bootstrap payloads can run tens of KB); switching to it is a
# folder-only, in-package change to New-DevinLaunchInvocation and is deferred until measured need.

Set-StrictMode -Version Latest

function ConvertTo-DevinFlag {
    <#
    .SYNOPSIS
    Translate a Specrew-side flag to Devin CLI permission-mode flag(s) (FR-007).
    .DESCRIPTION
    Devin exposes three permission modes: auto (normal), smart (autopilot), and dangerous
    (allow-all). normal -> auto is the implicit default and is applied by the launch builder, not
    here. This maps the two opt-in Specrew flags plus --remote (which Devin has no equivalent for).
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
                Notice          = 'Devin CLI does not expose a remote-control flag today; continuing launch without remote-control wiring.'
                SuppressWarning = $false
            }
        }
        '--allow-all' {
            return [pscustomobject]@{
                Args            = @('--permission-mode', 'dangerous')
                Notice          = "Translated --allow-all to Devin's 'dangerous' permission mode."
                SuppressWarning = $true
            }
        }
        '--autopilot' {
            return [pscustomobject]@{
                Args            = @('--permission-mode', 'smart')
                Notice          = "Translated --autopilot to Devin's 'smart' permission mode."
                SuppressWarning = $true
            }
        }
    }
}

function New-DevinLaunchInvocation {
    <#
    .SYNOPSIS
    Build the Devin CLI interactive launch invocation (FR-007).
    .DESCRIPTION
    Interactive launch with the bootstrap prompt as positional input. Permission modes map
    normal->auto / autopilot->smart / allow-all->dangerous. 'dangerous' takes PRECEDENCE over
    'smart' when both are requested, and the precedence is surfaced as an explicit notice.
    .OUTPUTS
    pscustomobject @{ Binary; Args[]; Notices[]; HostKind = 'devin' }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Prompt,
        [Parameter(Mandatory = $true)][string]$Agent,    # ignored; Devin has no --agent flag
        [bool]$AllowAll = $false,
        [bool]$UseAutopilot = $false,
        [bool]$UseRemote = $false
    )

    $hostCmd = Get-Command 'devin' -ErrorAction SilentlyContinue
    $resolvedBinary = if ($null -ne $hostCmd) { $hostCmd.Source } else { 'devin' }

    $argList = New-Object System.Collections.Generic.List[string]
    $notices = New-Object System.Collections.Generic.List[string]

    # Devin has NO --cwd flag (verified `devin --help`, build 2026.7.23). Devin operates on the
    # process working directory; the launcher in scripts/specrew-start.ps1 sets that via
    # Start-Process -WorkingDirectory $ResolvedProjectPath. $ProjectPath is therefore accepted
    # (Invoke-HostHandler splats it by name) but NOT injected as an argument — same as $Agent.

    # Permission-mode selection with dangerous precedence (FR-007).
    if ($AllowAll) {
        $t = ConvertTo-DevinFlag -SpecrewFlag '--allow-all'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
        if ($UseAutopilot) {
            $notices.Add("Both --allow-all and --autopilot were requested; Devin's 'dangerous' mode takes precedence over 'smart'.") | Out-Null
        }
    }
    elseif ($UseAutopilot) {
        $t = ConvertTo-DevinFlag -SpecrewFlag '--autopilot'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }
    else {
        # normal -> auto (the implicit default permission mode).
        $argList.Add('--permission-mode') | Out-Null
        $argList.Add('auto') | Out-Null
    }

    if ($UseRemote) {
        $t = ConvertTo-DevinFlag -SpecrewFlag '--remote'
        # Devin has no remote-control wiring; surface the notice but inject no args.
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }

    # Verified launch shape `devin [OPTIONS] [-- <PROMPT>...]` (build 2026.7.23): the bootstrap
    # prompt is POSITIONAL after a `--` separator that ends option parsing. `--` starts with `-`,
    # so the manual-command quoter in specrew-start.ps1 leaves it unquoted and it survives
    # copy-paste intact. `devin -p` headless is reserved for bounded smoke/canary only (FR-007).
    $argList.Add('--') | Out-Null
    $argList.Add($Prompt) | Out-Null

    return [pscustomobject]@{
        Binary   = $resolvedBinary
        Args     = $argList.ToArray()
        Notices  = $notices.ToArray()
        HostKind = 'devin'
    }
}

function Test-DevinRuntimeInstalled {
    <#
    .SYNOPSIS
    Devin's Crew runtime is .devin/agents/<name>/AGENT.md per-agent subdirectories (FR-008).
    .OUTPUTS
    bool
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $agentsDir = Join-Path $ProjectPath '.devin\agents'
    if (-not (Test-Path -LiteralPath $agentsDir -PathType Container)) {
        return $false
    }
    $agentManifests = Get-ChildItem -Path $agentsDir -Recurse -Filter 'AGENT.md' -ErrorAction SilentlyContinue
    return ([bool]$agentManifests) -and ($agentManifests.Count -gt 0)
}

function Get-DevinSignals {
    <#
    .SYNOPSIS
    Detect Devin-set environment variables that indicate we are running INSIDE Devin.
    .OUTPUTS
    string[] — names of env vars that are set
    #>
    $signals = @()
    foreach ($variableName in @('DEVIN_PROJECT_DIR', 'DEVIN_SESSION_ID', 'DEVIN_CLI')) {
        $value = [Environment]::GetEnvironmentVariable($variableName)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $signals += $variableName
        }
    }
    return $signals
}

function ConvertTo-DevinAgentDescription {
    param([string]$Charter, [string]$Role)
    return (Get-SpecrewCharterTagline -Charter $Charter -Role $Role)
}

function Install-DevinCrewRuntime {
    <#
    .SYNOPSIS
    Deploy Specrew's Crew runtime to .devin/agents/<role>/AGENT.md from canonical
    .specrew/team/agents/<role>.md (FR-008). Proposal 108 Slice 9 contract function.
    .DESCRIPTION
    Unlike Claude's flat .claude/agents/<role>.md, Devin uses a NESTED per-agent subdirectory:
    .devin/agents/<role>/AGENT.md. The canonical charter body becomes the AGENT.md system prompt
    with a Specrew-managed marker so user-edited files are preserved. Canonical team files are
    never modified.
    .OUTPUTS
    pscustomobject @{ Actions[]; CrewRuntimePath; Notices[] }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [switch]$DryRun
    )

    $actions = New-Object System.Collections.Generic.List[hashtable]
    $notices = New-Object System.Collections.Generic.List[string]
    $devinAgentsRoot = Get-SpecrewHostAgentRoot -HostKind 'devin' -ProjectPath $ProjectPath
    if (-not (Test-Path -LiteralPath $devinAgentsRoot -PathType Container) -and -not $DryRun) {
        New-Item -ItemType Directory -Path $devinAgentsRoot -Force | Out-Null
    }

    foreach ($role in (Get-SpecrewCanonicalAgentRoles -ProjectPath $ProjectPath)) {
        $content = Get-SpecrewCanonicalCharterContent -ProjectPath $ProjectPath -RoleName $role
        if ([string]::IsNullOrWhiteSpace($content)) {
            $notices.Add("Skipping role '$role': no canonical charter found.") | Out-Null
            continue
        }

        $description = ConvertTo-DevinAgentDescription -Charter $content -Role $role
        $headerLines = @(
            ('# {0}' -f $role),
            '',
            ('> {0}' -f $description),
            '',
            ('<!-- Specrew-managed: this Devin AGENT.md is generated from .specrew/team/agents/{0}.md -->' -f $role),
            ('<!-- DO NOT EDIT HERE. Edit the canonical file at .specrew/team/agents/{0}.md instead. -->' -f $role),
            ''
        )
        $header = $headerLines -join "`n"

        $roleDir = Join-Path $devinAgentsRoot $role
        $target = Join-Path $roleDir 'AGENT.md'
        if (-not (Test-SpecrewManagedFile -Path $target)) {
            $notices.Add("Preserving user-edited file '$target' (no Specrew-managed marker; delete the file to re-sync from canonical).") | Out-Null
            $actions.Add(@{ Action = 'preserved'; Path = $target; Role = $role }) | Out-Null
            continue
        }
        $finalContent = $header + $content

        if ($DryRun) {
            $actions.Add(@{ Action = 'would-write'; Path = $target; Role = $role }) | Out-Null
        }
        else {
            if (-not (Test-Path -LiteralPath $roleDir -PathType Container)) {
                New-Item -ItemType Directory -Path $roleDir -Force | Out-Null
            }
            [System.IO.File]::WriteAllText($target, $finalContent, [System.Text.UTF8Encoding]::new($false))
            $actions.Add(@{ Action = 'written'; Path = $target; Role = $role }) | Out-Null
        }
    }

    return [pscustomobject]@{
        Actions          = $actions.ToArray()
        CrewRuntimePath  = $devinAgentsRoot
        Notices          = $notices.ToArray()
    }
}
