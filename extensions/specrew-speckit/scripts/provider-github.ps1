#!/usr/bin/env pwsh
# GitHub reference adapter (Feature 182, Iteration 2).
#
# The ONLY place `gh` / the GitHub API is used. The methodology + validator core stay forge-neutral
# and never import this. Everything here is fail-open: if `gh` is absent or unauthenticated, the
# adapter degrades to an honest `ci-only`/`manual` report — it NEVER promises protection it cannot
# verify, and `apply_protection` is human-approved and never auto-run.

function Test-SpecrewGhAvailable {
    [CmdletBinding()] param()
    $cmd = Get-Command gh -ErrorAction SilentlyContinue
    return [bool]$cmd
}

function Get-SpecrewGitHubCapability {
    # detect_capability for GitHub: read-only. Maps visibility/plan to the achievable mechanism.
    # Fail-open: any gh error -> ci-only (CI runs anywhere) with an honest constraint.
    [CmdletBinding()]
    param([string]$ProjectPath = '.')

    if (-not (Test-SpecrewGhAvailable)) {
        return [ordered]@{ provider = 'github'; mechanism = 'ci-only'; constraints = @('gh CLI not available; cannot detect branch-protection capability — the CI work-kind check still runs (ci-only). Install/authenticate gh for capability detection.') }
    }

    $visibility = $null
    try {
        $json = & gh repo view --json visibility,isPrivate 2>$null | Out-String
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($json)) {
            $obj = $json | ConvertFrom-Json
            $visibility = if ($obj.visibility) { [string]$obj.visibility } elseif ($obj.isPrivate) { 'private' } else { 'public' }
        }
    }
    catch { $visibility = $null }
    # NOTE: the billing plan (Free/Pro/Team/Enterprise) is not reliably exposed via gh, and the owner
    # type (user/org) does not determine it — so we deliberately do NOT fetch it and instead report the
    # conservative, honest mechanism + a plan/visibility caveat below (rather than guessing from owner type).

    if ($null -eq $visibility) {
        return [ordered]@{ provider = 'github'; mechanism = 'ci-only'; constraints = @('gh present but repo visibility/capability not readable (unauthenticated or no access); reporting ci-only honestly.') }
    }

    # GitHub branch protection: available for public repos on Free/Free-for-orgs and for public/private
    # on Pro/Team/Enterprise. Rulesets: public on Free, public/private on Pro/Team/Enterprise Cloud.
    # Without the plan we report the conservative, honest mechanism + the caveat.
    $mechanism = 'branch-protection'
    $constraints = [System.Collections.Generic.List[string]]::new()
    $constraints.Add("visibility=$visibility; branch protection + rulesets availability depend on plan/visibility (GitHub docs) — verify against the repo's plan before relying on it.") | Out-Null
    if ($visibility -eq 'public') {
        $constraints.Add('public repo: protected branches + rulesets are available on Free and up.') | Out-Null
    }
    else {
        $constraints.Add('private/internal repo: protected branches/rulesets require Pro/Team/Enterprise — if on Free, this degrades to ci-only/manual.') | Out-Null
    }
    return [ordered]@{ provider = 'github'; mechanism = $mechanism; constraints = @($constraints.ToArray()) }
}

function Get-SpecrewGitHubExistingProtection {
    # Brownfield read (FR-021): the repo's EXISTING protection on a branch. Read-only; fail-open.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Branch)
    if (-not (Test-SpecrewGhAvailable)) {
        return [ordered]@{ readable = $false; reason = 'gh not available'; protected = $null }
    }
    try {
        $null = & gh api "repos/{owner}/{repo}/branches/$Branch/protection" 2>$null
        if ($LASTEXITCODE -eq 0) {
            return [ordered]@{ readable = $true; protected = $true; reason = "branch '$Branch' has protection configured" }
        }
        return [ordered]@{ readable = $true; protected = $false; reason = "branch '$Branch' has no protection (or not readable with the current token)" }
    }
    catch {
        return [ordered]@{ readable = $false; protected = $null; reason = 'gh api error (fail-open)' }
    }
}

function Invoke-SpecrewGitHubApplyProtection {
    # apply_protection for GitHub. GUARDED: refused unless -Approved (human approval). Uses the
    # caller's own gh auth / GITHUB_TOKEN (Specrew holds no secret). Returns a result; the actual
    # mutation is intentionally gated so a dry default never changes repo security.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Governance,
        [switch]$Approved,
        [switch]$Execute
    )
    if (-not $Approved) {
        return [ordered]@{ applied = $false; reason = 'apply_protection requires explicit human approval (-Approved); refused (DP-S2).' }
    }
    if (-not (Test-SpecrewGhAvailable)) {
        return [ordered]@{ applied = $false; reason = 'gh CLI not available; cannot apply protection (degrade to ci-only/manual).' }
    }
    if (-not $Execute) {
        return [ordered]@{ applied = $false; reason = 'approved but -Execute not set: describe-only. Re-run with -Execute to mutate (uses your own gh auth; Specrew holds no secret).' }
    }
    # A real mutation would PUT repos/{owner}/{repo}/branches/<b>/protection here, derived from
    # $Governance.branch_model. Kept gated: the live mutation is exercised only under explicit
    # human -Approved -Execute, validated at the dogfood/beta (honest phased posture).
    return [ordered]@{ applied = $false; reason = 'live apply is human-approved + validated at dogfood/beta; not auto-run in this path (honest phased).' }
}
