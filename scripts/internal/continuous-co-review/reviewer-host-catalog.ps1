$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ContinuousCoReviewCatalogValue {
    param(
        [AllowNull()]
        $Object,

        [Parameter(Mandatory)]
        [string] $Name,

        [AllowNull()]
        $DefaultValue = $null
    )

    if ($null -eq $Object) {
        return $DefaultValue
    }

    if (Test-ReviewerContractPropertyExists -Object $Object -Name $Name) {
        $value = Get-ReviewerContractPropertyValue -Object $Object -Name $Name
        if ($null -ne $value) {
            return $value
        }
    }

    return $DefaultValue
}

function Test-ContinuousCoReviewReviewerHostInstalled {
    param(
        [Parameter(Mandatory)]
        [string] $CommandName,

        [scriptblock] $CommandResolver
    )

    if ($CommandResolver) {
        return [bool] (& $CommandResolver -CommandName $CommandName)
    }

    return ($null -ne (Get-Command -Name $CommandName -ErrorAction SilentlyContinue))
}

function Get-ContinuousCoReviewReviewerHostRows {
    # The canonical reviewer-host catalog (DATA, the ONE place a host is defined). Each row carries the host's
    # identity + review-class rank AND its AGENTIC invocation for the worktree reviewer: the executable (`command`),
    # the headless-run args (`agentic_args`), and how the slim prompt is passed (`prompt_via_stdin`). Adding or
    # changing a reviewer host is a ROW edit here - never an edit to the invocation core (worktree-reviewer.ps1).
    # Hosts with an empty agentic_args have no headless agentic CLI yet (the worktree model needs one); they remain
    # selectable/authorizable but are not agentically invokable until their command is filled in.
    return @(
        # Keep OAuth/keychain authentication while loading no user/project/local settings, memories, hooks,
        # skills, or MCPs. The reviewer receives read-only inspection tools plus Write solely for the external
        # candidate path; it cannot run repository commands that generate files inside the frozen snapshot.
        @{ host = 'claude'; command = 'claude'; agentic_args = @('-p', '--no-session-persistence', '--setting-sources', '', '--disable-slash-commands', '--no-chrome', '--strict-mcp-config', '--mcp-config', '{"mcpServers":{}}', '--tools', 'Read,Glob,Grep,Write', '--permission-mode', 'bypassPermissions'); prompt_via_stdin = $true; model = 'opus-4.8-1m-context'; adapter_id = 'reviewer-host-adapter-claude-prompt'; rank = 85; default_timeout_seconds = 600; production_harness_id = 'claude-code-file-primary'; production_constructor = 'New-ReviewClaudeFilePrimaryHarnessPort'; result_transport = 'file-primary'; candidate_contract_version = '1.0' }
        # codex runs with --dangerously-bypass-approvals-and-sandbox BY DESIGN: the worktree reviewer already runs in an
        # EPHEMERAL, isolated, read-only-source git-tree worktree (precisely the "externally sandboxed environment" that
        # flag is documented for). codex's INNER Windows restricted-token sandbox is therefore redundant AND fragile
        # here — it needs the unique per-run temp worktree registered as a trusted project (codex HANGS headlessly
        # waiting for that trust) plus its sandbox-setup helper resolvable next to the launcher. Bypassing removes BOTH
        # failure modes with zero per-run / per-machine config. (F-197 reviewer robustness; drift D-197-I009-009 / T102.
        # NOTE: reviewing UNTRUSTED third-party code should use the per-run trust-injection mode instead — see T102.)
        @{ host = 'codex'; command = 'codex'; agentic_args = @('exec', '--dangerously-bypass-approvals-and-sandbox', '--skip-git-repo-check'); prompt_via_stdin = $false; model = 'chatgpt'; adapter_id = 'reviewer-host-adapter-codex-exec'; rank = 85; default_timeout_seconds = 600; production_harness_id = 'codex-cli-file-primary'; production_constructor = 'New-ReviewCodexFilePrimaryHarnessPort'; result_transport = 'file-primary'; candidate_contract_version = '1.0' }
        # copilot headless vector probe-validated live 2026-07-10 (F-198 iteration 001; scratch
        # probe answered in 6s and exited): `-p <prompt>` is non-interactive exit-after-completion,
        # --allow-all-tools is REQUIRED for non-interactive mode, --allow-all-paths lets the
        # reviewer browse its disposable worktree (the ephemeral read-only worktree IS the sandbox,
        # same doctrine as the codex bypass above), --no-ask-user keeps it autonomous (no ask_user
        # stalls headless), --no-custom-instructions keeps stray instruction files out of the
        # composed-prompt contract. The invocation core appends the prompt last, directly after -p.
        @{ host = 'copilot'; command = 'copilot'; agentic_args = @('--allow-all-tools', '--allow-all-paths', '--no-ask-user', '--no-custom-instructions', '--no-color', '--log-level', 'none', '-p'); prompt_via_stdin = $false; model = 'gpt-5.5-or-claude-4.8'; adapter_id = 'reviewer-host-adapter-copilot-prompt'; rank = 80; default_timeout_seconds = 300; production_harness_id = 'copilot-cli-file-primary'; production_constructor = 'New-ReviewCopilotFilePrimaryHarnessPort'; result_transport = 'file-primary'; candidate_contract_version = '1.0' }
        # Cursor's installed help confirms --print is non-interactive, --trust suppresses the headless workspace
        # trust prompt, and --force prevents tool-approval stalls. The common contract appends the prompt last.
        @{ host = 'cursor-agent'; command = 'cursor-agent'; agentic_args = @('--print', '--trust', '--force'); prompt_via_stdin = $false; model = 'configured-by-user'; adapter_id = 'reviewer-host-adapter-cursor-agent-prompt'; rank = 70; production_harness_id = 'cursor-agent-file-primary'; production_constructor = 'New-ReviewCursorAgentFilePrimaryHarnessPort'; result_transport = 'file-primary'; candidate_contract_version = '1.0' }
        # antigravity ships as `agy` (verified live on the maintainer machine 2026-07-08). The WORKING
        # headless vector is probe-validated and ORDER-SENSITIVE: flags BEFORE --print, prompt
        # POSITIONAL directly after it (the invocation core appends the prompt last):
        #   agy --dangerously-skip-permissions --print-timeout 9m --print "<prompt>"
        # Any flag AFTER --print is swallowed into the prompt (probe: the model answered an essay about
        # the flag text; --print-timeout placed after --print hangs). skip-permissions for the same
        # reason as the codex bypass above (the ephemeral read-only worktree IS the sandbox; headless
        # permission prompts would hang). --print-timeout 9m lifts agy's 5m internal default above our
        # review budget so OUR watchdog owns the kill (agy's default truncated a real 310s review to a
        # partial-harvest salvage). agy's native `models` subcommand is the first real consumer for the
        # model_probe seam (DEFER-197-I010-002).
        @{ host = 'antigravity'; command = 'agy'; agentic_args = @('--dangerously-skip-permissions', '--print-timeout', '15m', '--print'); prompt_via_stdin = $false; model = 'configured-by-user'; adapter_id = 'reviewer-host-adapter-antigravity-prompt'; rank = 65; default_timeout_seconds = 900; production_harness_id = 'antigravity-file-primary'; production_constructor = 'New-ReviewAntigravityFilePrimaryHarnessPort'; result_transport = 'file-primary'; candidate_contract_version = '1.0' }
    )
}

function Get-ContinuousCoReviewProductionHarnessDefinition {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$HostName)

    $needle = $HostName.ToLowerInvariant()
    $row = @(Get-ContinuousCoReviewReviewerHostRows) | Where-Object { $_.host -ceq $needle } | Select-Object -First 1
    if ($null -eq $row) { return $null }
    foreach ($required in @('production_harness_id', 'production_constructor', 'result_transport', 'candidate_contract_version')) {
        if (-not $row.Contains($required)) { return $null }
    }
    if ([string]$row.result_transport -cne 'file-primary' -or [string]$row.candidate_contract_version -cne '1.0') { return $null }
    $defaultTimeout = Get-ContinuousCoReviewHostDefaultTimeoutSeconds -HostName $needle
    if ($null -eq $defaultTimeout) { $defaultTimeout = 600 }
    return [pscustomobject][ordered]@{
        host = [string]$row.host
        harness_id = [string]$row.production_harness_id
        constructor = [string]$row.production_constructor
        command = [string]$row.command
        pre_arguments = @($row.agentic_args)
        prompt_transport = $(if ([bool]$row.prompt_via_stdin) { 'stdin' } else { 'argument' })
        result_transport = [string]$row.result_transport
        candidate_contract_version = [string]$row.candidate_contract_version
        default_timeout_seconds = [int]$defaultTimeout
    }
}

function Get-ContinuousCoReviewHostDefaultTimeoutSeconds {
    # F-198 FR-022: the per-host review budget from the catalog row (data, the one harness
    # seam). Values are field-measured (F-198 iteration 001: copilot 61-82s observed -> 300;
    # codex 240-410s -> 600; claude 600 and antigravity 900 per the maintainer clarify).
    # Returns $null when the row is absent or carries no value - the tolerant-reader contract:
    # callers fall through to the 600-second floor, never throw.
    param([Parameter(Mandatory)][string]$HostName)
    $needle = ([string]$HostName).ToLowerInvariant()
    $row = @(Get-ContinuousCoReviewReviewerHostRows) | Where-Object { $_.host -eq $needle } | Select-Object -First 1
    if ($null -eq $row) { return $null }
    if (-not $row.Contains('default_timeout_seconds')) { return $null }
    $value = 0
    if ([int]::TryParse([string]$row['default_timeout_seconds'], [ref]$value) -and $value -gt 0) { return $value }
    return $null
}

function Get-ContinuousCoReviewNavigatorTimeoutSeconds {
    # Shared by the navigator and the public campaign door. Explicit flags are handled by callers;
    # this function owns the remaining config -> host catalog -> 600-second floor chain so the two
    # execution paths cannot silently diverge. The config read fails closed at the authority timing
    # ceiling that also validates invocation parameters.
    param([Parameter(Mandatory)][string]$RepoRoot, [int]$Default = 600, [AllowNull()][string]$HostName)
    $maxTimeoutSeconds = [int](Get-ReviewAuthorityTimingLimits).max_invocation_timeout_seconds
    $configPath = Join-Path $RepoRoot '.specrew/config.yml'
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        $configLines = @()
        try {
            $configLines = @(Get-Content -LiteralPath $configPath -Encoding UTF8)
        }
        catch { $null = $_ }
        foreach ($line in $configLines) {
            if ($line -match '^\s*co_review_timeout_seconds:\s*[''"]?(?<value>[^''"#]+?)[''"]?\s*(?:#.*)?$') {
                $parsed = 0
                if ([int]::TryParse(($Matches['value'].Trim()), [ref]$parsed) -and $parsed -gt 0) {
                    if ($parsed -gt $maxTimeoutSeconds) {
                        throw ('co-review-timeout-exceeds-maximum:{0}:{1}' -f $parsed, $maxTimeoutSeconds)
                    }
                    return $parsed
                }
            }
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($HostName)) {
        $catalogValue = Get-ContinuousCoReviewHostDefaultTimeoutSeconds -HostName $HostName
        if ($null -ne $catalogValue -and [int]$catalogValue -gt 0) { return [int]$catalogValue }
    }
    return $Default
}

function Get-ContinuousCoReviewHostAgenticCommand {
    # The agentic invocation for a reviewer host, looked up from the catalog DATA above (host-NEUTRAL: the invocation
    # core calls this instead of switching on host names). Returns @{ file; pre_args; prompt_via_stdin } or $null
    # (host not in the catalog, or no agentic command defined). Adding a host's command is a catalog-row edit.
    param([Parameter(Mandatory)][string]$HostName)
    $needle = ([string]$HostName).ToLowerInvariant()
    $row = @(Get-ContinuousCoReviewReviewerHostRows) | Where-Object { $_.host -eq $needle } | Select-Object -First 1
    if ($null -eq $row -or @($row.agentic_args).Count -eq 0) { return $null }
    return [pscustomobject]@{ file = [string]$row.command; pre_args = @($row.agentic_args); prompt_via_stdin = [bool]$row.prompt_via_stdin }
}

function New-ContinuousCoReviewDefaultReviewerHostConfig {
    param(
        [scriptblock] $CommandResolver
    )

    $hostRows = Get-ContinuousCoReviewReviewerHostRows

    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        hosts          = @(
            foreach ($row in $hostRows) {
                [pscustomobject][ordered]@{
                    host              = $row.host
                    model             = $row.model
                    adapter_id        = $row.adapter_id
                    allowed           = $false
                    installed         = (Test-ContinuousCoReviewReviewerHostInstalled -CommandName $row.command -CommandResolver $CommandResolver)
                    review_class_rank = [int] $row.rank
                    model_source      = 'human-entered'
                    cost_class        = 'non-default'
                    authorization_ref = $null
                    fallback_allowed  = $false
                }
            }
        )
    }
}

function ConvertTo-ContinuousCoReviewReviewerHostCatalogEntry {
    param(
        [Parameter(Mandatory)]
        $Entry
    )

    $adapterId = [string] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'adapter_id')
    if ($adapterId -notmatch '^reviewer-host-adapter-[a-z0-9-]+$') {
        throw "Reviewer host catalog entry uses an invalid adapter id '$adapterId'."
    }

    return [pscustomobject][ordered]@{
        host              = [string] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'host')
        model             = [string] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'model')
        adapter_id        = $adapterId
        allowed           = [bool] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'allowed' -DefaultValue $false)
        installed         = [bool] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'installed' -DefaultValue $false)
        review_class_rank = [int] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'review_class_rank' -DefaultValue 0)
        model_source      = [string] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'model_source' -DefaultValue 'human-entered')
        cost_class        = [string] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'cost_class' -DefaultValue 'non-default')
        authorization_ref = Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'authorization_ref'
        fallback_allowed  = [bool] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'fallback_allowed' -DefaultValue $false)
    }
}

function Get-ContinuousCoReviewReviewerHostCatalog {
    param(
        [AllowNull()]
        $Configuration,

        [scriptblock] $CommandResolver
    )

    $resolvedConfiguration = if ($null -eq $Configuration) {
        New-ContinuousCoReviewDefaultReviewerHostConfig -CommandResolver $CommandResolver
    }
    else {
        $Configuration
    }

    $hosts = @(
        foreach ($entry in @($resolvedConfiguration.hosts)) {
            ConvertTo-ContinuousCoReviewReviewerHostCatalogEntry -Entry $entry
        }
    )

    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        hosts          = @($hosts)
    }
}
