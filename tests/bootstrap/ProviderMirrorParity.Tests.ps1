$ErrorActionPreference = 'Stop'

# F-174: hook PROVIDER files that the dispatcher invokes from a downstream .specify/ exist in TWO tracked
# copies that MUST stay byte-identical:
#   - SOURCE (module) copy      : scripts/internal/<provider>.ps1
#   - DEPLOYABLE (extension) copy: extensions/specrew-speckit/scripts/<provider>.ps1
#                                  (what deploy-speckit-extension ships into a downstream .specify/, and which
#                                   Resolve-ProviderCommandPath resolves FIRST for a downstream project).
# A full-copy provider resolves its heavy components $PSScriptRoot-relative / from the module, so the file
# itself must be the CURRENT logic wherever it lands -> the two copies are meant to be BYTE-IDENTICAL.
#
# History (why this guard exists, and why it is now GENERIC):
#   - iter-6 updated ONLY the module copy of the BOOTSTRAP provider -> downstream shipped the stale iter-4
#     provider (no contract write); the iter-6 review-signoff was sent back for exactly this. The first guard
#     covered ONLY the bootstrap provider.
#   - iter-8 (T050) found the SAME class recur on the HANDOVER provider: the iter-5 floor/body-split rewrote
#     scripts/internal but NOT the extension mirror, so every downstream deploy shipped a provider that calls a
#     dropped `-Sections` param against the iter-5 HandoverStore -> the Stop handover failed OPEN silently
#     (exit 0, stderr-only WARN) on every host, so no rolling handover was ever written. ProviderMirrorParity
#     never caught it because it was hard-coded to the bootstrap provider alone.
# So this guard now asserts byte-identity for EVERY full-copy provider pair (auto-discovered), so a NEW
# provider cannot skew silently either. Line endings are normalized so a CRLF/LF difference (git autocrlf on
# checkout) is not a false divergence.
#
# EXCLUDED - wrapper providers whose extension copy is a thin DISPATCHER to the module engine BY DESIGN (the
# two copies are intentionally different, not a mirror). Each exclusion is documented with its reason; adding
# a provider here is a deliberate act, which is the right friction.

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$srcDir = Join-Path $repoRoot 'scripts/internal'
$extDir = Join-Path $repoRoot 'extensions/specrew-speckit/scripts'
# review-signoff P1-3: the THIRD (project-side) copy the downstream actually runs. The guard previously asserted
# only MODULE vs EXTENSION-SOURCE, leaving a skew of just this copy (e.g. the newly-added specrew-handover-provider.ps1)
# undetected. Assert it too, when present (the self-host repo carries this tree).
$specifyDir = Join-Path $repoRoot '.specify/extensions/specrew-speckit/scripts'

# Wrapper exclusions: the extension copy is a thin launcher that resolves + invokes the module engine, so it
# is SUPPOSED to differ from the scripts/internal engine. Document each with its reason.
$wrapperExclusions = @(
    'sync-boundary-state.ps1'   # extension copy = param/resolve/dispatch wrapper (Invoke-SpecrewBoundaryStateSync); the engine is the 1600+-line scripts/internal copy.
)

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# Auto-discover the full-copy mirror pairs: every extension provider that has a scripts/internal counterpart
# and is not a documented wrapper.
$pairs = @()
foreach ($ext in (Get-ChildItem -LiteralPath $extDir -Filter '*.ps1' -File | Sort-Object Name)) {
    if ($wrapperExclusions -contains $ext.Name) { continue }
    $src = Join-Path $srcDir $ext.Name
    if (Test-Path -LiteralPath $src) {
        $pairs += [pscustomobject]@{ Name = $ext.Name; Src = $src; Ext = $ext.FullName }
    }
}

Write-Host ("Discovered {0} full-copy provider mirror pair(s): {1}" -f $pairs.Count, (($pairs.Name) -join ', '))
Assert-True ($pairs.Count -ge 5) ('auto-discovery found the full-copy provider set (expect at least: ' +
    'deploy-refocus-hooks, refocus, specrew-bootstrap-provider, specrew-handover-provider, specrew-hook-dispatcher). ' +
    "Found $($pairs.Count) - if fewer, a provider lost its scripts/internal counterpart or was wrongly excluded.")

# The core guard: every full-copy pair is byte-identical (line-ending normalized).
$specifyChecked = 0
foreach ($p in $pairs) {
    $modText = (Get-Content -LiteralPath $p.Src -Raw) -replace "`r`n", "`n"
    $extText = (Get-Content -LiteralPath $p.Ext -Raw) -replace "`r`n", "`n"
    Assert-True ($modText -eq $extText) ("$($p.Name): MODULE + EXTENSION-SOURCE copies are byte-identical (mirror parity). " +
        "If this FAILS, re-sync: Copy-Item scripts/internal/$($p.Name) over extensions/specrew-speckit/scripts/$($p.Name) - " +
        'a change to one copy not mirrored to the other ships a stale provider downstream.')
    # review-signoff P1-3: also assert the project-side (.specify) copy when present — the third copy a downstream
    # actually executes; a skew here would ship a stale provider undetected by the module-vs-extension check alone.
    $specifyCopy = Join-Path $specifyDir $p.Name
    if (Test-Path -LiteralPath $specifyCopy) {
        $specText = (Get-Content -LiteralPath $specifyCopy -Raw) -replace "`r`n", "`n"
        Assert-True ($modText -eq $specText) ("$($p.Name): the .specify/ project-side copy is byte-identical to the module copy. " +
            "If this FAILS, re-sync the .specify copy too (Copy-Item scripts/internal/$($p.Name) over .specify/extensions/specrew-speckit/scripts/$($p.Name)).")
        $specifyChecked++
    }
}
Write-Host ("Asserted .specify/ third-copy parity for {0} provider(s)" -f $specifyChecked)

# Provider-specific sanity checks (on top of identity): the DEPLOYED copy carries the current behavior, not a
# stale stub. These catch a same-content-but-wrong-version regression that identity alone cannot.
$bootstrapExt = Join-Path $extDir 'specrew-bootstrap-provider.ps1'
$btext = (Get-Content -LiteralPath $bootstrapExt -Raw)
Assert-True ($btext -match 'Write-SpecrewLaunchContractArtifact') 'bootstrap provider carries the contract-writer (FR-023, not the iter-4 stub)'
Assert-True ($btext -match 'BEGIN SPECREW LAUNCH CONTRACT') 'bootstrap provider inlines the contract (FR-002 read-and-follow, T044)'

$handoverExt = Join-Path $extDir 'specrew-handover-provider.ps1'
$htext = (Get-Content -LiteralPath $handoverExt -Raw)
Assert-True ($htext -match 'Update-SpecrewRollingHandover') 'handover provider funnels into the core save orchestrator (iter-9.1 thin adapter, not a stale stub)'
Assert-True (-not ($htext.Contains('-Sections $sections'))) 'handover provider does NOT call the dropped -Sections param on the floor-writer (the exact T050 skew)'
# iter-9.1: the SAVE logic + hollow detection moved OUT of the provider INTO the core orchestrator.
$storeText = (Get-Content -LiteralPath (Join-Path $PSScriptRoot '../../scripts/internal/bootstrap/HandoverStore.ps1') -Raw)
Assert-True ($storeText -match 'function Update-SpecrewRollingHandover') 'core orchestrator Update-SpecrewRollingHandover lives in HandoverStore (the single save path)'
Assert-True ($storeText -match 'HOLLOW_HANDOVER') 'the core carries the hollow detection (moved from the provider)'

# F-174 iter-10 (Prop-145 P3): every provider the dispatcher launches + captures MUST declare UTF-8 output (the
# CHILD half of the round-trip; the dispatcher reads UTF-8 via StandardOutputEncoding). Without it the child's
# default OEM console codepage mangles non-ASCII (inlined handover dialogue / WARNs under a non-Latin home) to
# '?'. Guard the declaration so the fix cannot silently regress.
foreach ($pv in @('specrew-bootstrap-provider.ps1', 'specrew-handover-provider.ps1', 'refocus.ps1', 'specrew-hook-dispatcher.ps1')) {
    $pvText = (Get-Content -LiteralPath (Join-Path $extDir $pv) -Raw)
    Assert-True (($pvText -match 'SPECREW-UTF8-OUTPUT') -and ($pvText -match '\[Console\]::OutputEncoding')) "$pv declares UTF-8 output (Prop-145 P3 non-ASCII capture fix)"
}

Write-Host "`n=== ProviderMirrorParity.Tests.ps1: all full-copy provider mirrors in sync ===" -ForegroundColor Green
