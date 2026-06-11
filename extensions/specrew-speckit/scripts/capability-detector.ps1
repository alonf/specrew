#!/usr/bin/env pwsh
# Capability Detector + Brownfield Detection (Feature 182, Iteration 2).
#
# Orchestrates the ProviderAdapter's read-only `detect_capability` into an HONEST report (FR-012):
# the achievable mechanism (branch-protection | rulesets | ci-only | manual) with constraints,
# describe-only by default. Plus brownfield detection (FR-021): the repo's EXISTING CI/CD +
# protection posture, with an adapt-or-change recommendation — never a silent overwrite.

$script:CapDetectorRoot = $PSScriptRoot
. (Join-Path $script:CapDetectorRoot 'work-kind-common.ps1')
. (Join-Path $script:CapDetectorRoot 'provider-adapter.ps1')
. (Join-Path $script:CapDetectorRoot 'provider-generic.ps1')

function Resolve-SpecrewGovernanceProvider {
    # Read the provider from .specrew/repository-governance.yml (best-effort), else default 'generic'.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $govPath = Join-Path $ProjectPath '.specrew/repository-governance.yml'
    if (Test-Path -LiteralPath $govPath) {
        foreach ($line in (Get-Content -LiteralPath $govPath -Encoding UTF8)) {
            if ($line -match '^\s{2}provider:\s*(?<v>\S+)') { return (ConvertFrom-SpecrewWorkKindScalar -Raw $Matches['v']) }
        }
    }
    return 'generic'
}

function Invoke-SpecrewCapabilityDetection {
    # FR-012: honest capability report. github -> the GitHub adapter (gh, fail-open); anything else ->
    # the generic fallback (ci-only/manual) or an offer to synthesize a read-only adapter.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ProjectPath, [string]$Provider)
    if ([string]::IsNullOrWhiteSpace($Provider)) { $Provider = Resolve-SpecrewGovernanceProvider -ProjectPath $ProjectPath }
    $p = $Provider.Trim().ToLowerInvariant()

    if ($p -eq 'github') {
        $ghPath = Join-Path $script:CapDetectorRoot 'provider-github.ps1'
        if (Test-Path -LiteralPath $ghPath) {
            . $ghPath
            $cap = Get-SpecrewGitHubCapability -ProjectPath $ProjectPath
            $cap['describe_only_default'] = $true
            return $cap
        }
    }
    if ($p -in @('generic', 'unknown', '')) {
        $cap = Get-SpecrewGenericCapability -ProjectPath $ProjectPath -Provider 'generic'
        $cap['describe_only_default'] = $true
        return $cap
    }
    # An unrecognized forge: no shipped adapter — offer synthesis (read-only), report manual until then.
    return [ordered]@{
        provider              = $p
        mechanism             = 'manual'
        constraints           = @("no shipped adapter for forge '$p'; synthesize a READ-ONLY adapter (apply stays human-approved) — until then enforcement is manual + the provider-neutral CI check.")
        describe_only_default = $true
    }
}

function Invoke-SpecrewBrownfieldDetection {
    # FR-021: detect the EXISTING CI/CD + branch protection + review posture, and recommend
    # ADAPT (slot the work-kind check into the existing CI) vs CHANGE (recommended posture).
    # Read-only; never overwrites.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ProjectPath, [string]$ReleaseTruthBranch = 'main', [string]$Provider)
    if ([string]::IsNullOrWhiteSpace($Provider)) { $Provider = Resolve-SpecrewGovernanceProvider -ProjectPath $ProjectPath }

    # existing CI?
    $ciSignals = @('.github/workflows', '.gitlab-ci.yml', 'azure-pipelines.yml', '.azuredevops', '.circleci', 'Jenkinsfile', '.drone.yml', 'bitbucket-pipelines.yml')
    $ciFound = @()
    foreach ($s in $ciSignals) { if (Test-Path -LiteralPath (Join-Path $ProjectPath $s)) { $ciFound += $s } }

    # existing protection (GitHub only, read-only)?
    $protection = [ordered]@{ readable = $false; protected = $null; reason = 'not checked (non-github or gh unavailable)' }
    if ($Provider -eq 'github') {
        $ghPath = Join-Path $script:CapDetectorRoot 'provider-github.ps1'
        if (Test-Path -LiteralPath $ghPath) { . $ghPath; $protection = Get-SpecrewGitHubExistingProtection -Branch $ReleaseTruthBranch }
    }

    $hasCi = $ciFound.Count -gt 0
    $recommendation = if ($hasCi) {
        'ADAPT: slot the work-kind validator into your existing CI lane(s); record the existing posture in .specrew/repository-governance.yml.'
    }
    else {
        'CHANGE: no CI detected — add the provider-neutral work-kind check (and, where the forge supports it, protect the release-truth branch).'
    }
    return [ordered]@{
        ci_detected          = $hasCi
        ci_signals           = @($ciFound)
        protection           = $protection
        recommendation       = $recommendation
        never_overwrite_note = 'Specrew reports the detected posture and recommends; it never overwrites an existing setup.'
    }
}

function Format-SpecrewCapabilityReport {
    # The ui-ux surface: honest mechanism + constraints; describe-only by default.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)]$Capability)
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("[capability] provider=$($Capability.provider)  mechanism=$($Capability.mechanism)") | Out-Null
    foreach ($c in @($Capability.constraints)) { $lines.Add("  - $c") | Out-Null }
    if ([bool]$Capability['describe_only_default']) { $lines.Add('  apply? describe-only by default — apply_protection requires explicit human approval.') | Out-Null }
    return ($lines -join [Environment]::NewLine)
}
