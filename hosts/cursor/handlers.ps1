# Cursor host package — handler implementations (F-050)
#
# Per hosts/_contract.md, exposes the 5 contract functions:
#   - New-CursorLaunchInvocation
#   - ConvertTo-CursorFlag
#   - Test-CursorRuntimeInstalled
#   - Get-CursorSignals
#   - Install-CursorCrewRuntime
#
# Cursor's standalone Agent CLI is `cursor-agent` (RESOLVED F-050 clarify 2026-05-28
# via `cursor-agent --help` / `--version` on the implementation machine; v2026.05.28).
#
# Launch shape (verified from `cursor-agent --help`):
#   `cursor-agent "<prompt>" --workspace <path>`  (interactive Agent mode, matches the
#   claude/codex/antigravity interactive-launch convention used by `specrew start`).
# Relevant flags:
#   prompt (positional)  Initial prompt for the agent
#   --workspace <path>   Workspace directory (defaults to cwd)
#   -f, --force          Force-allow commands unless explicitly denied (alias --yolo)
#   --trust              Trust workspace without prompting (ONLY works with --print/headless)
#   -p, --print          Non-interactive scripting mode (NOT used by specrew start, which is interactive)
#   --mode plan          Read-only/planning mode
# Non-interactive support is confirmed (FR-011 → Status=supported), but `specrew start`
# launches the INTERACTIVE agent so the developer can drive the lifecycle, hence no --print.

Set-StrictMode -Version Latest

function New-CursorLaunchInvocation {
    <#
    .SYNOPSIS
    Build the Cursor CLI launch invocation per F-050.
    .OUTPUTS
    pscustomobject @{ Binary; Args[]; Notices[]; HostKind = 'cursor' }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Prompt,
        [Parameter(Mandatory = $true)][string]$Agent,    # ignored; Cursor has no --agent flag
        [bool]$AllowAll = $false,
        [bool]$UseAutopilot = $false,
        [bool]$UseRemote = $false
    )

    $hostCmd = Get-Command 'cursor-agent' -ErrorAction SilentlyContinue
    $resolvedBinary = if ($null -ne $hostCmd) { $hostCmd.Source } else { 'cursor-agent' }

    $argList = New-Object System.Collections.Generic.List[string]
    $notices = New-Object System.Collections.Generic.List[string]

    # Interactive launch shape: `cursor-agent "<prompt>" --workspace <path>`
    $argList.Add($Prompt) | Out-Null
    $argList.Add('--workspace') | Out-Null
    $argList.Add($ProjectPath) | Out-Null

    if ($AllowAll) {
        $t = ConvertTo-CursorFlag -SpecrewFlag '--allow-all'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }
    if ($UseAutopilot) {
        $t = ConvertTo-CursorFlag -SpecrewFlag '--autopilot'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }
    if ($UseRemote) {
        $t = ConvertTo-CursorFlag -SpecrewFlag '--remote'
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }

    return [pscustomobject]@{
        Binary   = $resolvedBinary
        Args     = $argList.ToArray()
        Notices  = $notices.ToArray()
        HostKind = 'cursor'
    }
}

function ConvertTo-CursorFlag {
    <#
    .SYNOPSIS
    Translate a Specrew-side flag to Cursor CLI flag(s).
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
                Notice          = 'Cursor CLI does not expose a remote-control flag today; continuing launch without remote-control wiring.'
                SuppressWarning = $false
            }
        }
        '--allow-all' {
            return [pscustomobject]@{
                Args            = @('--force')
                Notice          = "Translated --allow-all to Cursor's --force (run-everything: force-allow commands unless explicitly denied; verified from cursor-agent --help)."
                SuppressWarning = $true
            }
        }
        '--autopilot' {
            return [pscustomobject]@{
                Args            = @()
                Notice          = "Cursor's run-everything equivalent is --force, already mapped from --allow-all. --autopilot is a no-op when --allow-all is also set."
                SuppressWarning = $true
            }
        }
    }
}

function Test-CursorRuntimeInstalled {
    <#
    .SYNOPSIS
    Cursor's Crew runtime convention is .cursor/rules/ (.mdc Project Rules).
    Detects whether the Crew runtime has been deployed (mirrors codex/antigravity contract:
    this checks the per-host AgentDir, NOT the binary on PATH — Test-SpecrewHostAvailable
    probes PATH).
    .OUTPUTS
    bool
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $rulesDir = Join-Path $ProjectPath '.cursor\rules'
    if (-not (Test-Path -LiteralPath $rulesDir -PathType Container)) {
        return $false
    }
    $ruleFiles = @(Get-ChildItem -Path $rulesDir -Filter '*.mdc' -ErrorAction SilentlyContinue)
    return ($ruleFiles.Count -gt 0)
}

function Get-CursorSignals {
    <#
    .SYNOPSIS
    Detect Cursor-set environment variables (names set when running INSIDE Cursor's agent).
    .DESCRIPTION
    Confidence: medium — the exact env-var set Cursor exports inside cursor-agent is not
    fully documented. CURSOR_API_KEY is documented (cursor-agent --help auth); CURSOR_AGENT
    and CURSOR_TRACE_ID are observed. Adjust as Cursor's runtime surface is confirmed.
    .OUTPUTS
    string[] — names of env vars that are set
    #>
    $signals = @()
    foreach ($variableName in @('CURSOR_AGENT', 'CURSOR_TRACE_ID', 'CURSOR_API_KEY')) {
        $value = [Environment]::GetEnvironmentVariable($variableName)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $signals += $variableName
        }
    }
    return $signals
}

function ConvertTo-CursorAgentDescription {
    param([string]$Charter, [string]$Role)
    return (Get-SpecrewCharterTagline -Charter $Charter -Role $Role)
}

function Install-CursorCrewRuntime {
    <#
    .SYNOPSIS
    Deploy Specrew's Crew runtime to .cursor/rules/<role>.mdc from canonical .specrew/team/agents/<role>.md.
    Proposal 108 Slice 9 contract function (F-050 Cursor implementation).
    .DESCRIPTION
    Cursor reads .cursor/rules/*.mdc Project Rules (auto-attached context — Cursor has no
    slash-command surface). Each canonical role-charter becomes an .mdc file with MDC YAML
    front-matter (description + alwaysApply) followed by the charter body.
    Reference: Cursor Project Rules (https://cursor.com/docs/context/rules).

    Confidence: medium — MDC front-matter shape (description/globs/alwaysApply) verified against
    Cursor's documented rules format; smoke-test on first real use and adjust.
    .OUTPUTS
    pscustomobject @{ Actions[]; CrewRuntimePath; Notices[] }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [switch]$DryRun
    )

    $actions = New-Object System.Collections.Generic.List[hashtable]
    $notices = New-Object System.Collections.Generic.List[string]
    $cursorRulesRoot = Get-SpecrewHostAgentRoot -HostKind 'cursor' -ProjectPath $ProjectPath
    if (-not (Test-Path -LiteralPath $cursorRulesRoot -PathType Container) -and -not $DryRun) {
        New-Item -ItemType Directory -Path $cursorRulesRoot -Force | Out-Null
    }

    foreach ($role in (Get-SpecrewCanonicalAgentRoles -ProjectPath $ProjectPath)) {
        $content = Get-SpecrewCanonicalCharterContent -ProjectPath $ProjectPath -RoleName $role
        if ([string]::IsNullOrWhiteSpace($content)) {
            $notices.Add("Skipping role '$role': no canonical charter found.") | Out-Null
            continue
        }

        $description = ConvertTo-CursorAgentDescription -Charter $content -Role $role
        $frontmatterLines = @(
            '---',
            ('description: {0}' -f ($description -replace '"', '\"')),
            'alwaysApply: false',
            ('# Specrew-managed: this Cursor rule is generated from .specrew/team/agents/{0}.md' -f $role),
            ('# DO NOT EDIT HERE. Edit the canonical file at .specrew/team/agents/{0}.md instead.' -f $role),
            '---',
            ''
        )
        $frontmatter = $frontmatterLines -join "`n"

        $target = Join-Path $cursorRulesRoot ("{0}.mdc" -f $role)
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
        CrewRuntimePath  = $cursorRulesRoot
        Notices          = $notices.ToArray()
    }
}
