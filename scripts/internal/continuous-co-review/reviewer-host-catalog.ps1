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
        @{ host = 'claude'; command = 'claude'; agentic_args = @('-p', '--permission-mode', 'bypassPermissions'); prompt_via_stdin = $true; model = 'opus-4.8-1m-context'; adapter_id = 'reviewer-host-adapter-claude-prompt'; rank = 85 }
        # codex runs with --dangerously-bypass-approvals-and-sandbox BY DESIGN: the worktree reviewer already runs in an
        # EPHEMERAL, isolated, read-only-source git-tree worktree (precisely the "externally sandboxed environment" that
        # flag is documented for). codex's INNER Windows restricted-token sandbox is therefore redundant AND fragile
        # here — it needs the unique per-run temp worktree registered as a trusted project (codex HANGS headlessly
        # waiting for that trust) plus its sandbox-setup helper resolvable next to the launcher. Bypassing removes BOTH
        # failure modes with zero per-run / per-machine config. (F-197 reviewer robustness; drift D-197-I009-009 / T102.
        # NOTE: reviewing UNTRUSTED third-party code should use the per-run trust-injection mode instead — see T102.)
        @{ host = 'codex'; command = 'codex'; agentic_args = @('exec', '--dangerously-bypass-approvals-and-sandbox', '--skip-git-repo-check'); prompt_via_stdin = $false; model = 'chatgpt'; adapter_id = 'reviewer-host-adapter-codex-exec'; rank = 85 }
        @{ host = 'copilot'; command = 'copilot'; agentic_args = @(); prompt_via_stdin = $false; model = 'gpt-5.5-or-claude-4.8'; adapter_id = 'reviewer-host-adapter-copilot-prompt'; rank = 80 }
        @{ host = 'cursor-agent'; command = 'cursor-agent'; agentic_args = @(); prompt_via_stdin = $false; model = 'configured-by-user'; adapter_id = 'reviewer-host-adapter-cursor-agent-prompt'; rank = 70 }
        # antigravity ships as `agy` (verified on the maintainer machine 2026-07-08). Headless mode is
        # --print; --dangerously-skip-permissions for the same reason as the codex bypass above (the
        # ephemeral read-only worktree IS the sandbox; headless permission prompts would hang);
        # --print-timeout raised above our review budget so OUR watchdog owns the kill. agy also has a
        # native `models` subcommand - the first real consumer for the model_probe seam (fast-follow,
        # DEFER-197-I010-002). Prompt transport (positional vs stdin) to confirm on the first
        # authenticated run.
        @{ host = 'antigravity'; command = 'agy'; agentic_args = @('--print', '--dangerously-skip-permissions', '--print-timeout', '30m'); prompt_via_stdin = $false; model = 'configured-by-user'; adapter_id = 'reviewer-host-adapter-antigravity-prompt'; rank = 65 }
    )
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
