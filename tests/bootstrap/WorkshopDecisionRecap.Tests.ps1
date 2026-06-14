$ErrorActionPreference = 'Stop'

# F-174 iteration 011 (T008, DF-1, FR-002 / FR-022): the pointer-mode DECISION RECAP. The iteration-010
# multi-host dogfood found pointer/terse hosts (codex) echoed the design-workshop lens NAMES on resume while
# the real decisions sat unread in the records. This proves the fix end-to-end:
#   - Get-SpecrewLensDecisionSummary extracts a record's '## Decision N - <title>' headings into one line;
#   - Get-SpecrewWorkshopProgress surfaces a `done_decisions` recap per done lens that has a record;
#   - the bootstrap in-flight directive renders the DECISIONS (+ a SYNTHESIZE instruction) instead of bare
#     lens names, and falls back to names when no decision record parses.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
. (Join-Path $repoRoot 'scripts/internal/bootstrap/ProjectMetadataAccessor.ps1')

# Extract Format-BootstrapDirective from the provider (its top-level body must not run), as pending-verdict-surface does.
# It now depends on Limit-SpecrewInlineBlock (the F-174 P2 delivery-cap bound), so extract that too.
$provSrc = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/internal/specrew-bootstrap-provider.ps1') -Raw
foreach ($fn in 'Limit-SpecrewInlineBlock', 'Format-BootstrapDirective') {
    $fnMatch = [regex]::Match($provSrc, "(?s)^function $fn \{.*?\n\}", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if (-not $fnMatch.Success) { throw "FAIL: could not extract $fn from the provider" }
    . ([scriptblock]::Create($fnMatch.Value))
}

$cases = @()
try {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t008-" + [guid]::NewGuid().ToString('N')); $cases += $tmp
    $wdir = Join-Path $tmp 'specs/001-feat/workshop'
    New-Item -ItemType Directory -Path $wdir -Force | Out-Null

    # === 1. Get-SpecrewLensDecisionSummary extracts + joins the decision TITLES (not the Chosen body). ===
    $recArch = Join-Path $wdir 'architecture-core.md'
    Set-Content -LiteralPath $recArch -Encoding UTF8 -Value @"
# Architecture Core Workshop Record

**Lens**: architecture-core

## Decision 1 - launcher preface + hook bootstrap
**Chosen: Option 2.** body prose here.

## Decision 2 - handover-first two-stage classification
body.

## Decision 3 - advisory concurrency, no locks
body.
"@
    $s = Get-SpecrewLensDecisionSummary -RecordPath $recArch
    Assert-True ($s -like '*launcher preface + hook bootstrap*') '1: summary carries decision 1 title'
    Assert-True ($s -like '*handover-first two-stage classification*') '1: summary carries decision 2 title'
    Assert-True ($s -like '*advisory concurrency, no locks*') '1: summary carries decision 3 title'
    Assert-True ($s -notlike '*Chosen*' -and $s -notlike '*body*') '1: summary is the decision TITLES only (not the Chosen/body prose)'

    # === 2. Bounding: more than MaxDecisions titles -> a "(+N more)" tail. ===
    $recData = Join-Path $wdir 'data-storage.md'
    Set-Content -LiteralPath $recData -Encoding UTF8 -Value "# Data Storage`n`n## Decision 1 - a`n## Decision 2 - b`n## Decision 3 - c`n## Decision 4 - d`n## Decision 5 - e`n## Decision 6 - f`n"
    $sMany = Get-SpecrewLensDecisionSummary -RecordPath $recData -MaxDecisions 4
    Assert-True ($sMany -like '*(+2 more)*') '2: more than MaxDecisions decisions -> (+2 more)'
    Assert-True ($sMany -like 'a; b; c; d*') '2: the first MaxDecisions titles are joined in order'

    # === 2b. (review-signoff P5-1) em-dash separator + an internal hyphen in the title -> FULL title captured. ===
    $recDash = Join-Path $tmp 'dash-record.md'   # OUTSIDE workshop/ so it is not counted a done lens
    $dashBody = "# Integration API`n`n## Decision 3 $([char]0x2014) Atomic write-replace (cross-platform safe)`n`n## Decision 4: colon-separated title here`n"
    Set-Content -LiteralPath $recDash -Value $dashBody -Encoding UTF8
    $sDash = Get-SpecrewLensDecisionSummary -RecordPath $recDash
    Assert-True ($sDash -like '*Atomic write-replace (cross-platform safe)*') '2b: an em-dash heading captures the FULL title incl. the internal hyphen (not truncated at write-)'
    Assert-True ($sDash -like '*colon-separated title here*') '2b: a colon-separated decision heading also captures its full title'

    # === 3. No decision headings / a missing file -> $null (fail-open; caller falls back to the name). ===
    $recNone = Join-Path $tmp 'norecord.md'   # OUTSIDE workshop/ so it is not counted a done lens
    Set-Content -LiteralPath $recNone -Encoding UTF8 -Value "# UI UX`n`nsome prose, no decision headings.`n"
    Assert-True ($null -eq (Get-SpecrewLensDecisionSummary -RecordPath $recNone)) '3: a record with no ## Decision headings -> $null'
    Assert-True ($null -eq (Get-SpecrewLensDecisionSummary -RecordPath (Join-Path $wdir 'missing.md'))) '3: a missing record -> $null (fail-open)'

    # === 4. Get-SpecrewWorkshopProgress surfaces done_decisions for done lenses that have records. ===
    $la = [ordered]@{
        selected = @('architecture-core', 'data-storage', 'ui-ux')
        workshop = [ordered]@{
            'architecture-core' = @{ moved_on = $true }
            'data-storage'      = @{ moved_on = $true }
            'ui-ux'             = @{ moved_on = $false }
        }
    }
    Set-Content -LiteralPath (Join-Path $tmp 'specs/001-feat/lens-applicability.json') -Encoding UTF8 -Value ($la | ConvertTo-Json -Depth 6)
    Set-Content -LiteralPath (Join-Path $tmp 'specs/001-feat/spec.md') -Encoding UTF8 -Value "# spec"
    $wp = Get-SpecrewWorkshopProgress -ProjectRoot $tmp -FeatureRef '001-feat'
    $dd = @($wp.done_decisions)
    Assert-True ($dd.Count -eq 2) "4: done_decisions has the 2 done lenses with records (got $($dd.Count))"
    $arch = @($dd | Where-Object { $_.lens -eq 'architecture-core' })
    Assert-True ($arch.Count -eq 1 -and ($arch[0].summary -like '*launcher preface*')) '4: architecture-core decision summary surfaced'
    Assert-True (@($wp.remaining) -contains 'ui-ux') '4: ui-ux (selected, not done, no record) stays in remaining'

    # === 5. The bootstrap directive renders the DECISIONS + the SYNTHESIZE instruction (not bare names). ===
    $result = [pscustomobject]@{ directive = [pscustomobject]@{ mode = 'resume'; required_reads = @('.specrew/last-start-prompt.md', '.specrew/start-context.json'); validation_findings = @() } }
    $inflight = [pscustomobject]@{ in_flight = $true; feature_ref = '001-feat'; spec_exists = $true; spec_path = 'specs/001-feat/spec.md';
        done = @('architecture-core', 'data-storage'); done_decisions = @($dd); remaining = @('ui-ux'); has_applicability = $true }
    $dir = Format-BootstrapDirective -Result $result -ContractBody '' -InFlight $inflight -PendingVerdict $null
    Assert-True ($dir -match 'DECISIONS recorded so far') '5: the directive renders the DECISIONS block (not just lens names)'
    Assert-True ($dir -match 'SYNTHESIZE these into') '5: the directive instructs the agent to synthesize the recap'
    Assert-True ($dir -match 'architecture-core: .*launcher preface') '5: each done lens renders its decision summary'
    Assert-True ($dir -match '1-2 sentence SYNTHESIS of what we have decided so far') '5: the welcome-back instruction asks for a decisions synthesis'

    # === 6. Fallback: done lenses but NO parseable decisions -> the bare-names line (behavior preserved). ===
    $inflightBare = [pscustomobject]@{ in_flight = $true; feature_ref = '001-feat'; spec_exists = $true; spec_path = 'specs/001-feat/spec.md';
        done = @('architecture-core'); done_decisions = @(); remaining = @(); has_applicability = $true }
    $dirBare = Format-BootstrapDirective -Result $result -ContractBody '' -InFlight $inflightBare -PendingVerdict $null
    Assert-True ($dirBare -match 'lenses already DONE') '6: with no done_decisions, the directive falls back to the bare-names line'
    Assert-True ($dirBare -notmatch 'DECISIONS recorded so far') '6: the DECISIONS block is absent when there are no decision records'

    Write-Host "`n=== WorkshopDecisionRecap.Tests.ps1: all assertions passed (decision extraction + done_decisions + directive recap + synthesis + names fallback) ===" -ForegroundColor Green
}
finally {
    foreach ($t in $cases) { Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue }
}
