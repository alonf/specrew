$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# INT-006 bridge (iteration 007): connect the design-workshop's reviewer choice to the navigator's
# authorization.
#
# The code-implementation lens already ASKS the human which continuous-co-review host should review the
# code and records the answer in the feature's `implementation-rules.yml` as `reviewer_preference`
# (mode / host / model / authorization_ref). But the async navigator authorizes from a DIFFERENT file --
# `.specrew/reviewer-hosts.json` (the T086 catalog) -- and nothing connected them. So the human's choice
# was captured in the manifest yet NEVER authorized the navigator, which then fail-opened silently
# (INT-006's "present available choices" half shipped as guidance; the authorization wiring did not). This
# deterministic bridge reads `reviewer_preference` and persists a HUMAN-SELECTED host into the navigator's
# catalog so the next checkpoint review actually fires.
#
# Provenance discipline (Proposal 190 hole stays closed): it authorizes ONLY on an explicit
# `mode = human-selected` + host -- the human's workshop selection IS the human authorization. It NEVER
# acts on `auto-select` or a missing choice (that would silently authorize a possibly-paid set, violating
# SEC-004); those degrade to the navigator's fail-open + the discoverable backstop instead.

function Read-ContinuousCoReviewWorkshopReviewerPreference {
    # Focused read of the `reviewer_preference:` block from a feature's implementation-rules.yml. The
    # manifest is a constrained-YAML subset; we only need this flat block (mode/host/model/effort/
    # source/authorization_ref/rationale), so a section scan is robust and needs no full manifest reader.
    param(
        [Parameter(Mandatory)]
        [string] $ManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) { return $null }

    $inReviewer = $false
    $pref = [ordered]@{}
    foreach ($line in (Get-Content -LiteralPath $ManifestPath -Encoding UTF8)) {
        if ($line -match '^reviewer_preference:\s*$') { $inReviewer = $true; continue }
        if (-not $inReviewer) { continue }
        if ($line -match '^\S') { break }   # a new top-level key ends the block
        if ($line -match '^\s{2}(?<k>[a-z_]+):\s*(?<v>.*)$') {
            $val = $Matches['v'].Trim()
            if ($val.Length -ge 2 -and $val.StartsWith('"') -and $val.EndsWith('"')) {
                $val = $val.Substring(1, $val.Length - 2)
            }
            if ($val -eq 'null' -or $val -eq '') { $val = $null }
            $pref[$Matches['k']] = $val
        }
    }

    if ($pref.Count -eq 0) { return $null }
    return [pscustomobject]$pref
}

function Sync-ContinuousCoReviewReviewerAuthorizationFromWorkshop {
    # Read the active feature's reviewer_preference and, if the HUMAN selected a host, persist it to
    # .specrew/reviewer-hosts.json (the navigator's authorization catalog). Idempotent + deterministic;
    # safe to call before every plan build (the caller only invokes it when the catalog is absent).
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [string] $FeatureRoot,

        [scriptblock] $CommandResolver
    )

    if ([string]::IsNullOrWhiteSpace($FeatureRoot)) {
        if (Get-Command -Name 'Get-ContinuousCoReviewNavigatorFeatureRoot' -ErrorAction SilentlyContinue) {
            $rel = Get-ContinuousCoReviewNavigatorFeatureRoot -RepoRoot $RepoRoot
            if (-not [string]::IsNullOrWhiteSpace($rel)) { $FeatureRoot = Join-Path $RepoRoot $rel }
        }
    }
    if ([string]::IsNullOrWhiteSpace($FeatureRoot) -or -not (Test-Path -LiteralPath $FeatureRoot)) {
        return [pscustomobject]@{ synced = $false; reason = 'no-feature-root' }
    }

    $manifestPath = Join-Path $FeatureRoot 'implementation-rules.yml'
    $pref = Read-ContinuousCoReviewWorkshopReviewerPreference -ManifestPath $manifestPath
    if ($null -eq $pref) { return [pscustomobject]@{ synced = $false; reason = 'no-reviewer-preference' } }

    $mode = [string] (Get-ContinuousCoReviewCatalogValue -Object $pref -Name 'mode')
    $reviewerHost = [string] (Get-ContinuousCoReviewCatalogValue -Object $pref -Name 'host')

    # ONLY a human-selected host authorizes. auto-select / undecided -> no write (never silently authorize).
    if ($mode -ne 'human-selected' -or [string]::IsNullOrWhiteSpace($reviewerHost)) {
        return [pscustomobject]@{ synced = $false; reason = ('not-human-selected:' + $mode) }
    }

    $model = [string] (Get-ContinuousCoReviewCatalogValue -Object $pref -Name 'model')
    $authRef = [string] (Get-ContinuousCoReviewCatalogValue -Object $pref -Name 'authorization_ref')
    if ([string]::IsNullOrWhiteSpace($authRef)) { $authRef = 'code-implementation-workshop' }

    # Build the navigator's own catalog (installed-detected) and flip the chosen host to AUTHORIZED, so the
    # persisted file is exactly the shape Get-ContinuousCoReviewReviewerHostCatalog -Configuration consumes.
    $config = New-ContinuousCoReviewDefaultReviewerHostConfig -CommandResolver $CommandResolver
    $matched = $false
    foreach ($entry in @($config.hosts)) {
        if ([string] $entry.host -eq $reviewerHost) {
            $entry.allowed = $true
            $entry.authorization_ref = $authRef
            $entry.model_source = 'human-entered'
            if (-not [string]::IsNullOrWhiteSpace($model)) { $entry.model = $model }
            $matched = $true
        }
    }
    if (-not $matched) { return [pscustomobject]@{ synced = $false; reason = ('unknown-host:' + $reviewerHost) } }

    $reviewerHostsPath = Join-Path $RepoRoot '.specrew/reviewer-hosts.json'
    $reviewerHostsDir = Split-Path -Parent $reviewerHostsPath
    if (-not (Test-Path -LiteralPath $reviewerHostsDir)) { New-Item -ItemType Directory -Path $reviewerHostsDir -Force | Out-Null }
    ($config | ConvertTo-Json -Depth 100) | Set-Content -LiteralPath $reviewerHostsPath -Encoding UTF8

    return [pscustomobject]@{ synced = $true; host = $reviewerHost; authorization_ref = $authRef }
}
