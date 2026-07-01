$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T073 / FR-025 / SC-019 / SC-020: the boundary-sync wiring for the deterministic
# co-review signoff gate floor.
#
# The DECISION logic lives in review-signoff-evidence-gate.ps1 (loaded via _load.ps1). This
# file is the thin, testable SEAM that Invoke-SpecrewBoundaryStateSync calls so the 1500-line
# sync function stays free of gate logic:
#
#   1. Get-ContinuousCoReviewGateEnforcementEnabled - returns TRUE by default. The old opt-in
#      scalar made the review-signoff backstop inert in exactly the host-switch/compaction case
#      it is supposed to catch. A present co_review_gate_enforcement key is now informational:
#      false/off/disabled no longer bypass review-signoff.
#
#   2. Invoke-ContinuousCoReviewSignoffGateIfEnabled - the boundary-sync entry point. It is a
#      no-op for every boundary except review-signoff. At review-signoff it dot-sources the
#      gate module, writes durable gate-decision evidence, and throws on any `block` decision.
#      Only a MISSING-gate-infrastructure failure (the _load.ps1 dot-source itself failing) is
#      re-wrapped as a clear error; a real block-refusal is NEVER disguised as infrastructure.
#
# This function emits NOTHING on the allow path. Invoke-SpecrewBoundaryStateSync returns a
# single result object that a downstream dispatcher serializes; a stray emission here would make
# that result a 2-element array and silently suppress the pending-verdict stop.

function Get-ContinuousCoReviewGateEnforcementEnabled {
    <#
    .SYNOPSIS
        Return $true for the review-signoff hard gate. The old opt-in/off switch is retained
        only as a parsed compatibility surface and does not bypass review-signoff.
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $configPath = Join-Path $ProjectRoot '.specrew/config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return $true
    }

    # Value grammar matches the sibling specrew_version reader in sync-boundary-state.ps1: strip an
    # optional single OR double quote, stop the value at a '#', and tolerate a trailing inline comment.
    # (The earlier `"?...[^"#]...` form silently dropped `true # comment` and `'true'` -> a governance
    # gate the operator believed was ON would stay OFF. 145 F1.)
    foreach ($line in Get-Content -LiteralPath $configPath -Encoding UTF8) {
        if ($line -match '^\s*co_review_gate_enforcement:\s*[''"]?(?<value>[^''"#]+?)[''"]?\s*(?:#.*)?$') {
            return $true
        }
    }

    return $true
}

function Write-ContinuousCoReviewSignoffGateDecisionEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$BoundaryType,
        [Parameter(Mandatory = $true)]$Decision
    )

    $root = Join-Path $ProjectRoot '.specrew/review/signoff-gate'
    $historyRoot = Join-Path $root 'history'
    New-Item -ItemType Directory -Path $historyRoot -Force | Out-Null

    $recordedAt = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
    $record = [pscustomobject][ordered]@{
        schema_version = '1.0'
        boundary_type  = $BoundaryType
        recorded_at    = $recordedAt
        decision       = $Decision
    }
    $json = $record | ConvertTo-Json -Depth 100
    $latestPath = Join-Path $root 'latest.json'
    $historyPath = Join-Path $historyRoot ('{0}-{1}.json' -f ($recordedAt -replace '[:-]', ''), ([guid]::NewGuid().ToString('N').Substring(0, 8)))

    foreach ($path in @($latestPath, $historyPath)) {
        if (Get-Command -Name 'Write-SpecrewFileAtomic' -ErrorAction SilentlyContinue) {
            Write-SpecrewFileAtomic -Path $path -Content $json
        }
        else {
            [System.IO.File]::WriteAllText($path, $json, [System.Text.UTF8Encoding]::new($false))
        }
    }
}

function Get-ContinuousCoReviewTrunkName {
    <#
    .SYNOPSIS
        Return the trunk branch name from .specrew/config.yml (`co_review_trunk`), default 'main'.
        145 carry (T080): the gate's merge-base anchor resolves `<trunk>`/`origin/<trunk>`, so a
        non-`main` trunk (master/develop) otherwise fails CLOSED (anchor-unresolvable -> block).
        Making it configurable lets those repos opt into enforcement. Same value grammar as the
        enforcement reader (quote-strip + inline-comment tolerant).
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $configPath = Join-Path $ProjectRoot '.specrew/config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return 'main'
    }
    foreach ($line in Get-Content -LiteralPath $configPath -Encoding UTF8) {
        if ($line -match '^\s*co_review_trunk:\s*[''"]?(?<value>[^''"#]+?)[''"]?\s*(?:#.*)?$') {
            $value = $Matches['value'].Trim()
            if (-not [string]::IsNullOrWhiteSpace($value)) { return $value }
        }
    }
    return 'main'
}

function Invoke-ContinuousCoReviewSignoffGateIfEnabled {
    <#
    .SYNOPSIS
        At the review-signoff boundary, refuse signoff unless the current reviewed-state
        matches fresh, anchor-covered co-review evidence (FR-025). A no-op for any
        other boundary.
    .DESCRIPTION
        Lets the gate's block-refusal throw propagate (fail-closed). Wraps ONLY the gate-module
        dot-source failure in a clear infrastructure error so a missing gate is never silently
        swallowed AND a real refusal is never mislabeled as infrastructure.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$BoundaryType
    )

    if ($BoundaryType -ne 'review-signoff') {
        return
    }

    if (-not (Get-ContinuousCoReviewGateEnforcementEnabled -ProjectRoot $ProjectRoot)) {
        return
    }

    # Lazy-load the decision module (and its deps) only when the gate will actually fire.
    # A dot-source failure here is genuine missing infrastructure, not a co-review verdict.
    try {
        $gateLoaderPath = Join-Path $PSScriptRoot '_load.ps1'
        if (-not (Test-Path -LiteralPath $gateLoaderPath -PathType Leaf)) {
            throw "continuous-co-review gate loader not found at '$gateLoaderPath'."
        }
        . $gateLoaderPath
    }
    catch {
        throw ("[continuous-co-review-gate] review-signoff cannot be evaluated because the gate infrastructure failed to load: {0}" -f $_.Exception.Message)
    }

    # The throw on a `block` decision propagates verbatim (fail-closed). TrunkName is read from
    # config so non-`main`-trunk repos do not fail closed (145 carry T080). The decision is
    # persisted before either throw/allow so a failed signoff leaves inspectable evidence.
    $trunk = Get-ContinuousCoReviewTrunkName -ProjectRoot $ProjectRoot
    $decision = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $ProjectRoot -TrunkName $trunk
    Write-ContinuousCoReviewSignoffGateDecisionEvidence -ProjectRoot $ProjectRoot -BoundaryType $BoundaryType -Decision $decision
    if ($decision.decision -eq 'block') {
        throw "[continuous-co-review-gate] review-signoff refused ($($decision.reason)): $($decision.message)"
    }
}
