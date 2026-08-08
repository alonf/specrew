$ErrorActionPreference = 'Stop'

# Pre-tag slice #2 smalls (testbeta3 re-test, maintainer-priced at <=~1 SP together):
#   (a) the trust-hardening handoff check recognized ONLY the legacy === SPECREW HANDOFF === block,
#       WARNing at every boundary stop on hosts where Rule 46 forbids duplicating that block —
#       the six-section packet IS the primary stop contract and must count as handoff evidence.
#   (b) resolve-quality-profile.ps1 left the feature UNBOUND when called without -FeaturePath/-SpecPath:
#       it never consulted .specify/feature.json (the canonical resolver every other script uses),
#       so a bare invocation resolved a feature-blind profile.
#   (c) scaffold-iteration-artifacts.ps1 emitted the quality/ subtree only behind Phase-2/contract
#       gating, while the launch-contract quick-reference claims the scaffold "already carries" a
#       ready hardening-gate.md — consumers trusted the claim and met a missing file.
#
# Run standalone:
#   pwsh -NoProfile -File tests/unit/pretag-slice2-smalls.tests.ps1

$script:Red = 0
$script:Hard = 0
function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Red { param([string]$m) Write-Host "RED: $m" -ForegroundColor Yellow; $script:Red++ }
function Write-Inconclusive { param([string]$m) Write-Host "INCONCLUSIVE (fixture defect, NOT a pass): $m" -ForegroundColor Magenta; $script:Hard++ }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')

# ---------------------------------------------------------------------------------------------
# (a) The six-section packet is handoff evidence; the legacy block stays recognized.
# ---------------------------------------------------------------------------------------------
$packetText = @'
## What I Just Did

Wrote the spec and committed it.

## Why I Stopped

The specify boundary needs your verdict.

## What Needs Your Review

The spec at file:///tmp/spec.md.

## What Happens Next

Planning follows on approval.

## Discussion Prompts

None.

## What I Need From You

approve as-is, approve with instructions, send back, or discuss.
'@
$legacyText = "=== SPECREW HANDOFF ===`nSTOPPED AT: specify`n=== END SPECREW HANDOFF ==="

$packetEvent = [pscustomobject]@{ response_text = $packetText }
if (Test-SpecrewHandoffBlockPresent -CommitMessage '' -SessionMetadata $packetEvent) {
    Write-Pass '(a) the six-section packet counts as handoff evidence — no WARN demands the block Rule 46 forbids'
}
else {
    Write-Red '(a) the six-section packet is NOT recognized as handoff evidence — the trust-hardening check demands the legacy block Rule 46 forbids on packet hosts'
}
if (Test-SpecrewHandoffBlockPresent -CommitMessage '' -SessionMetadata ([pscustomobject]@{ response_text = $legacyText })) {
    Write-Pass '(a) the legacy handoff block stays recognized (transitional hosts unaffected)'
}
else {
    Write-Red '(a) the legacy handoff block stopped being recognized — a regression, not the fix'
}
if (-not (Test-SpecrewHandoffBlockPresent -CommitMessage 'ordinary commit message' -SessionMetadata ([pscustomobject]@{ response_text = 'just prose, no packet' }))) {
    Write-Pass '(a) plain prose is still NOT handoff evidence — the check did not go vacuous'
}
else {
    Write-Red '(a) plain prose passes the handoff check — the recognizer went vacuous'
}

# ---------------------------------------------------------------------------------------------
# Scratch project shared by (b) and (c).
# ---------------------------------------------------------------------------------------------
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("slice2-" + [guid]::NewGuid().ToString('N'))
$proj = Join-Path $scratch 'p'
$featureDir = Join-Path $proj 'specs\001-demo'
try {
    New-Item -ItemType Directory -Path (Join-Path $proj '.specify') -Force | Out-Null
    New-Item -ItemType Directory -Path $featureDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $featureDir 'spec.md') -Value "# Feature Specification: Demo`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureDir 'plan.md') -Value "# Plan`n`nMinimal plan, no Phase-2 markers and no Required Quality Gates table." -Encoding UTF8
    [System.IO.File]::WriteAllText((Join-Path $proj '.specify\feature.json'), '{"feature_directory":"specs/001-demo"}', [System.Text.UTF8Encoding]::new($false))

    # -- (b) bare invocation binds the feature via feature.json.
    $resolverOut = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\resolve-quality-profile.ps1') -ProjectPath $proj -OutputFormat Json 2>&1) -join "`n")
    $resolverJson = $null
    try { $resolverJson = $resolverOut | ConvertFrom-Json } catch { $resolverJson = $null }
    if ($null -eq $resolverJson) {
        Write-Inconclusive ("(b) the resolver emitted no parseable JSON — nothing measured. Head: {0}" -f (($resolverOut -replace '\s+', ' ').Trim().Substring(0, [Math]::Min(200, $resolverOut.Length))))
    }
    elseif (-not [string]::IsNullOrWhiteSpace([string]$resolverJson.feature_path) -and ([string]$resolverJson.feature_path) -like '*001-demo*') {
        Write-Pass '(b) a bare resolver invocation binds the active feature from .specify/feature.json'
    }
    else {
        Write-Red ("(b) a bare resolver invocation leaves the feature UNBOUND (feature_path: {0}) — the profile resolves feature-blind" -f $(if ([string]::IsNullOrWhiteSpace([string]$resolverJson.feature_path)) { '(null)' } else { [string]$resolverJson.feature_path }))
    }

    # -- (c) the iteration scaffold emits the quality/ subtree its quick-reference claims.
    $scaffoldOut = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-iteration-artifacts.ps1') -SpecDirectory $featureDir -IterationNumber '001' 2>&1) -join "`n")
    $scaffoldExit = $LASTEXITCODE
    $iterDir = Join-Path $featureDir 'iterations\001'
    if ($scaffoldExit -ne 0 -or -not (Test-Path -LiteralPath $iterDir -PathType Container)) {
        Write-Inconclusive ("(c) the scaffolder did not produce the iteration directory (exit {0}) — nothing measured. Head: {1}" -f $scaffoldExit, (($scaffoldOut -replace '\s+', ' ').Trim().Substring(0, [Math]::Min(200, $scaffoldOut.Length))))
    }
    else {
        $gatePath = Join-Path $iterDir 'quality\hardening-gate.md'
        $missing = @(@(
                @{ Name = 'quality/hardening-gate.md'; Path = $gatePath }
                @{ Name = 'quality/quality-evidence.md'; Path = (Join-Path $iterDir 'quality\quality-evidence.md') }
                @{ Name = 'quality/mechanical-findings.json'; Path = (Join-Path $iterDir 'quality\mechanical-findings.json') }
                @{ Name = 'quality/lenses/'; Path = (Join-Path $iterDir 'quality\lenses') }
            ) | Where-Object { -not (Test-Path -LiteralPath $_.Path) })
        if ($missing.Count -eq 0) {
            # The gate's DEFAULT verdict is `blocked` with placeholder rows — deliberately: a gate
            # defaulting to ready would wave hardening through unreviewed. The launch-contract text
            # that claimed ready-by-default was the wrong side of that mismatch and is corrected;
            # this asserts the canonical gate metadata is present, not the over-claimed value.
            $gateSchema = (Get-Content -LiteralPath $gatePath -Raw) -match '\*\*Overall Verdict\*\*:'
            if ($gateSchema) {
                Write-Pass '(c) the scaffold emits the claimed quality/ subtree with the canonical gate metadata on a plain plan'
            }
            else {
                Write-Red '(c) quality/hardening-gate.md exists but does not carry the canonical Overall Verdict metadata'
            }
        }
        else {
            Write-Red ("(c) the scaffold omits the quality/ subtree its quick-reference claims: missing {0}" -f (($missing | ForEach-Object { $_.Name }) -join ', '))
        }
    }
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($script:Hard -gt 0) {
    Write-Host "=== pretag-slice2-smalls: $($script:Hard) INCONCLUSIVE ===" -ForegroundColor Magenta
    exit 2
}
if ($script:Red -gt 0) {
    Write-Host "=== pretag-slice2-smalls: $($script:Red) RED assertion(s) ===" -ForegroundColor Yellow
    exit 1
}
Write-Host '=== pretag-slice2-smalls: packet evidence recognized; feature bound; claimed scaffold emitted ===' -ForegroundColor Green
exit 0
