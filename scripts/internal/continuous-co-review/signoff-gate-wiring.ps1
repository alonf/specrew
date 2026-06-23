$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T073 / FR-025 / SC-019 / SC-020: the OPT-IN boundary-sync wiring for the deterministic
# co-review signoff gate floor.
#
# The DECISION logic lives in review-signoff-evidence-gate.ps1 (loaded via _load.ps1). This
# file is the thin, testable SEAM that Invoke-SpecrewBoundaryStateSync calls so the 1500-line
# sync function stays free of gate logic:
#
#   1. Get-ContinuousCoReviewGateEnforcementEnabled - reads ONE opt-in scalar from
#      .specrew/config.yml (co_review_gate_enforcement), mirroring Get-SessionMode's
#      line-by-line read. Default OFF: a missing key, a missing file, or any non-true value
#      means the gate does not fire. Existing governed projects stay inert until they opt in.
#
#   2. Invoke-ContinuousCoReviewSignoffGateIfEnabled - the boundary-sync entry point. It is a
#      no-op for every boundary except review-signoff, and a no-op when enforcement is OFF.
#      When ON at review-signoff it dot-sources the gate module and calls
#      Assert-ContinuousCoReviewSignoffGate, whose throw (on a `block` decision) propagates
#      verbatim - fail-CLOSED refusal of signoff on un-reviewed state is the entire point.
#      Only a MISSING-gate-infrastructure failure (the _load.ps1 dot-source itself failing) is
#      re-wrapped as a clear error; a real block-refusal is NEVER disguised as infrastructure.
#
# This function emits NOTHING on the allow path. Assert-ContinuousCoReviewSignoffGate returns
# the decision object, but Invoke-SpecrewBoundaryStateSync returns a single result object that a
# downstream dispatcher serializes; a stray emission here would make that result a 2-element
# array and silently suppress the pending-verdict stop. The success path is voided here AND the
# call site pipes to Out-Null.

function Get-ContinuousCoReviewGateEnforcementEnabled {
    <#
    .SYNOPSIS
        Return $true only when co_review_gate_enforcement is explicitly enabled in
        .specrew/config.yml; $false for any other value, a missing key, or a missing file
        (FR-025 opt-in, default OFF).
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $configPath = Join-Path $ProjectRoot '.specrew/config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return $false
    }

    # Value grammar matches the sibling specrew_version reader in sync-boundary-state.ps1: strip an
    # optional single OR double quote, stop the value at a '#', and tolerate a trailing inline comment.
    # (The earlier `"?...[^"#]...` form silently dropped `true # comment` and `'true'` -> a governance
    # gate the operator believed was ON would stay OFF. 145 F1.)
    foreach ($line in Get-Content -LiteralPath $configPath -Encoding UTF8) {
        if ($line -match '^\s*co_review_gate_enforcement:\s*[''"]?(?<value>[^''"#]+?)[''"]?\s*(?:#.*)?$') {
            $value = $Matches['value'].Trim().ToLowerInvariant()
            return ($value -eq 'true' -or $value -eq 'on' -or $value -eq 'enabled')
        }
    }

    return $false
}

function Invoke-ContinuousCoReviewSignoffGateIfEnabled {
    <#
    .SYNOPSIS
        At the review-signoff boundary, and only when co_review_gate_enforcement is enabled,
        refuse signoff unless the current reviewed-state matches fresh, anchor-covered
        co-review evidence (FR-025). A no-op for any other boundary or when OFF.
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

    # The throw on a `block` decision propagates verbatim (fail-closed). The allow-path return
    # value is voided so it never leaks into the boundary-sync result pipeline.
    [void](Assert-ContinuousCoReviewSignoffGate -RepoRoot $ProjectRoot)
}
