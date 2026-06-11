#!/usr/bin/env pwsh
# ProviderAdapter contract + dispatch (Feature 182).
#
# The ONLY forge-specific seam. The methodology, the work-kind declaration, and the CI validator
# core import NO forge assumption; they go through this contract. v1 ships:
#   - generic / unknown : always-present fallback (ci-only/manual; git-diff read_pr_context)
#   - github            : reference adapter. This forge-NEUTRAL core keeps only a placeholder for
#                         github (FR-014: the core imports no forge adapter); the real github
#                         capability detection + guarded apply live in the github adapter
#                         (provider-github.ps1), reached via the capability-detector orchestrator —
#                         never through this core dispatch (which is why the core never imports it).
#   - synthesized       : generated on the fly for another forge; READ-ONLY until a human verifies it
#
# Contract operations:
#   Invoke-SpecrewDetectCapability   -> { provider, mechanism, constraints }   (read-only, always safe)
#   Invoke-SpecrewDescribeProtection -> human-readable plan                     (read-only, always safe)
#   Invoke-SpecrewApplyProtection    -> result                                  (GUARDED: human-approved;
#                                        refused for read-only/unverified adapters)
#   Get-SpecrewPrContext             -> { changed_files, target_branch, source_branch, merge_state }
#                                        (forge-NEUTRAL git-diff fallback; works with no adapter)

$script:WorkKindCommonPath = Join-Path $PSScriptRoot 'work-kind-common.ps1'
if (Test-Path -LiteralPath $script:WorkKindCommonPath) { . $script:WorkKindCommonPath }

function Resolve-SpecrewProviderAdapter {
    # Resolve a provider adapter descriptor (a pure in-memory constructor — no state change).
    # `read_only` is true for the generic fallback and for a synthesized adapter that a human has not
    # yet verified (DP-S3 safety guardrail).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Provider,
        [switch]$Synthesized,
        [switch]$Verified
    )
    $p = $Provider.Trim().ToLowerInvariant()
    $readOnly = $true
    switch ($p) {
        'github' { $readOnly = $false }            # reference adapter: not read-only (the github adapter carries the guarded apply)
        { $_ -in @('generic', 'unknown', '') } { $p = 'generic'; $readOnly = $true }
        default {
            # any other forge id is treated as a synthesized adapter
            $readOnly = -not ($Synthesized -and $Verified)
        }
    }
    if ($Synthesized) { $readOnly = -not $Verified }
    return [ordered]@{
        provider     = $p
        synthesized  = [bool]$Synthesized
        verified     = [bool]$Verified
        read_only    = [bool]$readOnly
    }
}

function Get-SpecrewPrContext {
    # Forge-NEUTRAL read_pr_context fallback: the changed-file set via `git diff`, plus branch
    # info. Works with NO adapter. Fail-open: returns an empty changed-file set on any git error.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$BaseRef,
        [string]$HeadRef = 'HEAD'
    )
    $changed = @()
    $targetBranch = $null
    $sourceBranch = $null
    try {
        $diff = & git -C $ProjectPath diff --name-only "$BaseRef...$HeadRef" 2>$null
        if ($LASTEXITCODE -eq 0 -and $diff) {
            $changed = @($diff | Where-Object { $_ -and $_.Trim().Length -gt 0 } | ForEach-Object { ($_ -replace '\\', '/').Trim() })
        }
    }
    catch { $changed = @() }
    try {
        $sourceBranch = (& git -C $ProjectPath rev-parse --abbrev-ref $HeadRef 2>$null | Select-Object -First 1)
        $targetBranch = ($BaseRef -replace '^origin/', '')
    }
    catch {
        # Fail-open: branch info is best-effort; the changed-file set is what the validator needs.
        $sourceBranch = $null
    }
    return [ordered]@{
        changed_files = @($changed)
        target_branch = $targetBranch
        source_branch = $sourceBranch
        merge_state   = 'unknown'   # forge-specific; enriched by a real adapter in iteration 2
    }
}

function Invoke-SpecrewDetectCapability {
    # Read-only, always safe. The generic adapter reports ci-only/manual. This is the FORGE-NEUTRAL
    # contract surface: for github it returns a neutral placeholder because the core imports no forge
    # adapter (FR-014). Real github capability detection lives in the github adapter and is reached
    # through the capability-detector orchestrator, never through this core dispatch.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Adapter,
        [string]$ProjectPath = '.'
    )
    $provider = [string]$Adapter['provider']
    switch ($provider) {
        'github' {
            return [ordered]@{
                provider    = 'github'
                mechanism   = 'ci-only'
                constraints = @('forge-neutral core: ci-only is the honest answer the core gives without importing a forge adapter (FR-014); for real GitHub capability (branch-protection/rulesets) use the github adapter via the capability detector.')
            }
        }
        default {
            # generic / unknown / synthesized-read-only
            $genericPath = Join-Path $PSScriptRoot 'provider-generic.ps1'
            if (Test-Path -LiteralPath $genericPath) {
                . $genericPath
                return (Get-SpecrewGenericCapability -ProjectPath $ProjectPath -Provider $provider)
            }
            return [ordered]@{ provider = $provider; mechanism = 'manual'; constraints = @('no adapter available; manual enforcement') }
        }
    }
}

function Invoke-SpecrewDescribeProtection {
    # Read-only, always safe: a human-readable plan describing what protection the captured
    # governance asks for. Never mutates anything.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Adapter,
        [Parameter(Mandatory = $true)]$Governance
    )
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("[describe-protection] provider=$($Adapter['provider']) (read-only plan)") | Out-Null
    $bm = $Governance['branch_model']
    if ($null -ne $bm) {
        $lines.Add("  branch model: $($bm['style']); release-truth branch: $($bm['release_truth_branch'])") | Out-Null
        foreach ($b in @($bm['branches'])) {
            if ($null -eq $b) { continue }
            $checks = @($b['required_checks']) -join ', '
            $lines.Add("  protect '$($b['name'])' (role=$($b['role'])): PR-required=$($b['require_pull_request']); checks=[$checks]; force-push=$($b['allow_force_pushes']); deletions=$($b['allow_deletions'])") | Out-Null
        }
    }
    $lines.Add("  apply? describe-only by default — apply_protection requires explicit human approval") | Out-Null
    return ($lines -join [Environment]::NewLine)
}

function Invoke-SpecrewApplyProtection {
    # GUARDED privileged action. Refuses unless: the human explicitly approved (-Approved) AND the
    # adapter is not read-only (a generic fallback or an unverified synthesized adapter is always
    # refused). Specrew holds no secret; a real apply uses the caller's own forge token (iteration 2).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Adapter,
        [Parameter(Mandatory = $true)]$Governance,
        [switch]$Approved
    )
    if ([bool]$Adapter['read_only']) {
        return [ordered]@{ applied = $false; reason = "adapter '$($Adapter['provider'])' is read-only (generic fallback or unverified synthesized adapter); apply_protection refused (DP-S2/S3)" }
    }
    if (-not $Approved) {
        return [ordered]@{ applied = $false; reason = 'apply_protection requires explicit human approval (-Approved); refused (DP-S2)' }
    }
    # Approved + a non-read-only (github/verified) adapter: this forge-neutral core performs NO
    # mutation by design (it imports no forge adapter, FR-014). The real guarded apply lives in the
    # github adapter (Invoke-SpecrewGitHubApplyProtection), human-approved + -Execute-gated.
    return [ordered]@{ applied = $false; reason = "apply_protection is not performed by the forge-neutral core; route through the forge adapter's guarded apply (human-approved + -Execute-gated). No mutation performed here (honest, not over-claimed)." }
}
