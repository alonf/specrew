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

function Install-CopilotCrewRuntime {
    <#
    .SYNOPSIS
    Deploy the Crew runtime to .squad/agents/<role>/charter.md from canonical .specrew/team/agents/<role>.md.
    Proposal 108 Slice 9 contract function.
    .DESCRIPTION
    Squad CLI reads from .squad/agents/<role>/charter.md as its native location. This function
    TRANSLATES the canonical .specrew/team/agents/<role>.md charters to that location.
    Squad's other state (config.json, team.md, ceremonies.md) is bootstrapped by 'squad init'
    or Initialize-SquadFallbackScaffold and is OUTSIDE this function's scope — only the per-role
    charter.md files (= the team identity) are translated here.
    .OUTPUTS
    pscustomobject @{ Actions[]; CrewRuntimePath; Notices[] }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [switch]$DryRun
    )

    $actions = New-Object System.Collections.Generic.List[hashtable]
    $notices = New-Object System.Collections.Generic.List[string]
    $squadAgentsRoot = Get-SpecrewHostAgentRoot -HostKind 'copilot' -ProjectPath $ProjectPath

    foreach ($role in (Get-SpecrewCanonicalAgentRoles -ProjectPath $ProjectPath)) {
        $roleDir = Join-Path $squadAgentsRoot $role
        if (-not (Test-Path -LiteralPath $roleDir -PathType Container) -and -not $DryRun) {
            New-Item -ItemType Directory -Path $roleDir -Force | Out-Null
        }

        $content = Get-SpecrewCanonicalCharterContent -ProjectPath $ProjectPath -RoleName $role
        if ([string]::IsNullOrWhiteSpace($content)) {
            $notices.Add("Skipping role '$role': no canonical charter at .specrew/team/agents/$role.md and no shipped baseline.") | Out-Null
            continue
        }

        $charterPath = Join-Path $roleDir 'charter.md'
        if (Test-SpecrewUserOwnedFile -Path $charterPath) {
            # PRED-BETA4-036: the user said so (`specrew team own <role>`). Kept as written, and not reported -
            # the disposition is persisted, so the notice does not return.
            $actions.Add(@{ Action = 'preserved-owned'; Path = $charterPath; Role = $role }) | Out-Null
            continue
        }
        if (-not (Test-SpecrewManagedFile -Path $charterPath)) {
            # PRED-BETA4-036 (the auditor's finding B): both remedies named here CLEAR the notice. The old advice,
            # "delete the sidecar to keep it without this notice", left the file unmarked and brought the notice
            # straight back as "no Specrew-managed marker", recommending the deletion of a file already gone.
            $why = if (Test-Path -LiteralPath ("{0}.specrew-managed" -f $charterPath) -PathType Leaf) { 'edited since Specrew wrote it' } else { 'no Specrew-managed marker' }
            $notices.Add("Preserving your charter '$charterPath' ($why). It stays as you wrote it. To keep it as yours and end this notice: specrew team own $role. To return it to the canonical charter (.specrew/team/agents/$role.md; your edit is discarded): specrew team resync $role.") | Out-Null
            $actions.Add(@{ Action = 'preserved'; Path = $charterPath; Role = $role }) | Out-Null
            continue
        }
        $charterExists = Test-Path -LiteralPath $charterPath -PathType Leaf
        if ($charterExists -and (Test-SpecrewCharterCurrent -Path $charterPath -CanonicalContent $content)) {
            # Specrew's, and current: the text before the directives block equals the canonical charter. Kept,
            # silently, without a rewrite (PRED-BETA4-034 kept init's composition; PRED-BETA4-036 checks it
            # against canonical first - a matching hash proves no user edit, not a current input).
            $actions.Add(@{ Action = 'preserved-managed'; Path = $charterPath; Role = $role }) | Out-Null
            continue
        }

        # Copilot consumes charter.md as the charter body verbatim (no frontmatter / comment header).
        # Use a sidecar marker file instead of an inline comment so Squad CLI parsing isn't affected.
        # A stale charter (canonical changed since it was written) is rewritten through the one shared writer,
        # which carries its directives block across and re-stamps the sidecar (the auditor's finding A).
        if ($DryRun) {
            $actions.Add(@{ Action = $(if ($charterExists) { 'would-update' } else { 'would-write' }); Path = $charterPath; Role = $role }) | Out-Null
        }
        else {
            Write-SpecrewCharterFromCanonical -Path $charterPath -CanonicalContent $content -DirectivesBlock (Get-SpecrewManagedDirectivesBlockText -Path $charterPath)
            $actions.Add(@{ Action = $(if ($charterExists) { 'updated' } else { 'written' }); Path = $charterPath; Role = $role }) | Out-Null
        }
    }

    return [pscustomobject]@{
        Actions          = $actions.ToArray()
        CrewRuntimePath  = $squadAgentsRoot
        Notices          = $notices.ToArray()
    }
}
