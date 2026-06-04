[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 141 Iteration 4 — FR-025 / SC-006 / SC-015: the deterministic lens-applicability selector.
# The selector is a pure function of (decoupled sibling map, recorded answers); these are unit tests.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\lens-applicability.ps1')

$mapPath = Join-Path $repoRoot 'extensions\specrew-speckit\knowledge\design-lenses\applicability-map.json'
Assert-True (Test-Path -LiteralPath $mapPath) "the sibling applicability-map.json exists beside the catalog"
$map = Read-SpecrewLensApplicabilityMap -Path $mapPath
Assert-True ($null -ne $map -and @($map.always_on).Count -eq 3 -and @($map.questions).Count -eq 6) "map loads: 3 always-on foundational lenses + 6 questions"

# index.yml must stay PURE (decoupled): no gated_by / always_on fields leaked into the catalog index.
$indexRaw = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\knowledge\design-lenses\index.yml') -Raw -Encoding UTF8
Assert-True ($indexRaw -notmatch '(?im)gated_by|always_on') "index.yml stays pure (no gating fields; the map is decoupled)"

# All-no answers -> only the foundational always-on lenses, in map order.
$allNo = @{ ui = $false; security = $false; data = $false; integration = $false; ops = $false; perf = $false }
$selNo = @(Get-SpecrewApplicableLenses -Map $map -Answers $allNo)
Assert-True (($selNo -join ',') -eq 'architecture-core,component-design,requirements-nfr') "all-no -> exactly the 3 always-on lenses (SC-006), in order"

# Never hide an always-on lens, even when everything is 'no'.
foreach ($f in @('architecture-core', 'component-design', 'requirements-nfr')) {
    Assert-True ($selNo -contains $f) "always-on lens '$f' is never hidden"
}

# Specialized lenses are gated by their answer.
$some = @{ ui = $true; security = $true; data = $false; integration = $false; ops = $false; perf = $true }
$selSome = @(Get-SpecrewApplicableLenses -Map $map -Answers $some)
Assert-True ($selSome -contains 'ui-ux' -and $selSome -contains 'security-compliance' -and $selSome -contains 'observability-resilience') "yes answers select their gated lenses"
Assert-True (-not ($selSome -contains 'data-storage') -and -not ($selSome -contains 'integration-api') -and -not ($selSome -contains 'devops-operations')) "no answers exclude their gated lenses"
Assert-True ($selSome.Count -eq 6) "always-on (3) + 3 yes-gated = 6 selected"

# All-yes -> all 9 lenses.
$allYes = @{ ui = $true; security = $true; data = $true; integration = $true; ops = $true; perf = $true }
Assert-True (@(Get-SpecrewApplicableLenses -Map $map -Answers $allYes).Count -eq 9) "all-yes -> all 9 lenses"

# SC-015 determinism: identical answers yield the identical ordered set across runs.
$r1 = @(Get-SpecrewApplicableLenses -Map $map -Answers $some)
$r2 = @(Get-SpecrewApplicableLenses -Map $map -Answers $some)
Assert-True (($r1 -join '|') -eq ($r2 -join '|')) "SC-015: selection is deterministic (same answers -> identical set across runs)"

# Truthiness tolerance: string 'yes'/'true' answers behave like booleans.
$strAns = @{ ui = 'yes'; security = 'true'; data = 'no'; integration = $false; ops = $false; perf = $false }
Assert-True ((@(Get-SpecrewApplicableLenses -Map $map -Answers $strAns) -join ',') -eq (@(Get-SpecrewApplicableLenses -Map $map -Answers @{ ui = $true; security = $true; data = $false; integration = $false; ops = $false; perf = $false }) -join ',')) "string 'yes'/'true' answers match boolean answers"

# Graceful degradation (SC-006): absent map OR absent answers -> empty (none available), no error.
Assert-True (@(Get-SpecrewApplicableLenses -Map $null -Answers $allYes).Count -eq 0) "absent map -> none available (empty)"
Assert-True (@(Get-SpecrewApplicableLenses -Map $map -Answers $null).Count -eq 0) "absent answers -> none available (empty)"
Assert-True ($null -eq (Read-SpecrewLensApplicabilityMap -Path (Join-Path $repoRoot 'does-not-exist.json'))) "missing map file -> null (no throw)"

# Audit object records the per-lens include/exclude rationale.
$audit = Get-SpecrewLensSelection -Map $map -Answers $some
Assert-True (@($audit.selected).Count -eq 6) "audit selected count matches selector"
Assert-True (@($audit.included | Where-Object { $_.id -eq 'ui-ux' }).Count -eq 1) "audit marks a yes-gated lens included"
Assert-True (@($audit.excluded | Where-Object { $_.id -eq 'data-storage' -and $_.reason -match "data.*= no" }).Count -eq 1) "audit records why an excluded lens was excluded"

# T004 render (SC-006): section lists selected + not-selected; graceful degradation; markdownlint-safe.
$renderSome = Format-SpecrewApplicableLensesSection -Map $map -Answers $some
Assert-True ($renderSome -match '## Applicable Lenses') "render: section heading present"
Assert-True ($renderSome -match 'ui-ux' -and $renderSome -match 'security-compliance' -and $renderSome -match 'architecture-core') "render: selected lenses listed"
Assert-True ($renderSome -match 'Not selected:' -and $renderSome -match 'data-storage') "render: not-selected lenses listed with their reason"
Assert-True ($renderSome -notmatch '(?m)^\s*\+ ') "render: no '+'-at-line-start (markdownlint-safe prose)"
Assert-True ($renderSome -match '\*Not selected:' -and $renderSome -notmatch '_Not selected') "render: not-selected uses asterisk emphasis, not underscore (MD049-safe)"
$renderNone = Format-SpecrewApplicableLensesSection -Map $null -Answers $null
Assert-True ($renderNone -match '## Applicable Lenses' -and $renderNone -match 'None available') "render: absent map/answers -> none available (SC-006)"

# T002 questionnaire artifact: template emit with empty answers; no overwrite of a filled file.
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("lens-appl-{0}.json" -f ([System.Guid]::NewGuid().ToString('N')))
try {
    $p = New-SpecrewLensApplicabilityTemplate -Map $map -OutPath $tmp
    $doc = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-True (@($doc.questions).Count -eq 6 -and $doc.answers.ui -eq $false -and @($doc.selected).Count -eq 0) "template emit: 6 questions + answers default false + empty selected"
    Set-Content -LiteralPath $tmp -Value '{"answers":{"ui":true}}' -Encoding UTF8
    $null = New-SpecrewLensApplicabilityTemplate -Map $map -OutPath $tmp
    Assert-True ((Get-Content -LiteralPath $tmp -Raw) -match '"ui":\s*true') "template emit: does not overwrite an existing (filled) answers file"
}
finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }

# Iteration 5 T001 (FR-009) — Get-SpecrewLensDecisionPoints: pure extractor of a lens file's
# "## Design Decision Points" bullets, so the analysis can be genuinely informed (not just named).
$catalogDir = Join-Path $repoRoot 'extensions\specrew-speckit\knowledge\design-lenses'
$acPoints = @(Get-SpecrewLensDecisionPoints -LensId 'architecture-core' -CatalogDir $catalogDir)
Assert-True ($acPoints.Count -ge 3) "decision points: architecture-core yields its decision-point bullets"
Assert-True (($acPoints -join ' ') -match 'building blocks') "decision points: content extracted verbatim from the lens file"
$dsPoints = @(Get-SpecrewLensDecisionPoints -LensId 'data-storage' -CatalogDir $catalogDir)
Assert-True (@($dsPoints | Where-Object { $_ -match 'storage model fits:.*hybrid' }).Count -eq 1) "decision points: a wrapped multi-line bullet is folded into one point"
Assert-True (@(Get-SpecrewLensDecisionPoints -LensId 'no-such-lens' -CatalogDir $catalogDir).Count -eq 0) "decision points: missing lens file -> empty (graceful)"
Assert-True (@(Get-SpecrewLensDecisionPoints -LensId 'architecture-core' -CatalogDir (Join-Path $repoRoot 'does-not-exist')).Count -eq 0) "decision points: missing catalog dir -> empty (graceful)"
Assert-True (@(Get-SpecrewLensDecisionPoints -LensId '' -CatalogDir $catalogDir).Count -eq 0) "decision points: empty lens id -> empty (no throw)"

# Iteration 5 T002 (FR-009) — enriched render: each selected lens carries its decision points + an
# "Addressed:" coverage placeholder pointing into the option comparison.
$enriched = Format-SpecrewApplicableLensesSection -Map $map -Answers $some -CatalogDir $catalogDir
Assert-True ($enriched -match '(?m)^\s*- Decision points: ') "enriched render: each selected lens carries a Decision points line"
Assert-True ($enriched -match '(?m)^\s*- Addressed: <') "enriched render: each selected lens carries an Addressed: placeholder to fill"
Assert-True ($enriched -match 'ui-ux' -and $enriched -match '\*Not selected:') "enriched render: still lists selected + not-selected lenses"
Assert-True ($enriched -notmatch '_Not selected') "enriched render: asterisk emphasis, not underscore (MD049-safe)"
# Back-compat: without -CatalogDir the legacy name-list render is unchanged (no enrichment lines).
$legacy = Format-SpecrewApplicableLensesSection -Map $map -Answers $some
Assert-True ($legacy -notmatch 'Decision points:' -and $legacy -notmatch 'Addressed:') "render back-compat: no -CatalogDir -> legacy name-list (no enrichment)"

# Iteration 6 T001 (FR-025 / SC-018) — Get-SpecrewLensQuestionDepth: dial -> interaction depth.
$dials = @{ 'architect' = 10; 'ux-ui-specialist' = 7; 'product-manager' = 8; 'ai-researcher-project-manager' = 7 }
Assert-True ((Get-SpecrewLensQuestionDepth -ExpertiseDials $dials -Area 'perf') -eq 'expert-terse') "dial depth: perf -> architect dial 10 -> expert-terse"
Assert-True ((Get-SpecrewLensQuestionDepth -ExpertiseDials $dials -Area 'ui') -eq 'moderate') "dial depth: ui -> ux-ui dial 7 -> moderate"
Assert-True ((Get-SpecrewLensQuestionDepth -ExpertiseDials @{ 'ux-ui-specialist' = 2 } -Area 'ui') -eq 'guided-explain') "dial depth: ui -> ux-ui dial 2 -> guided-explain"
Assert-True ((Get-SpecrewLensQuestionDepth -ExpertiseDials $dials -Area 'whatever') -eq 'expert-terse') "dial depth: unknown area falls back to architect dial"
Assert-True ((Get-SpecrewLensQuestionDepth -ExpertiseDials @{} -Area 'ui') -eq 'moderate') "dial depth: absent dial -> fail-safe moderate"
Assert-True ((Get-SpecrewLensQuestionDepth -ExpertiseDials $null -Area 'perf') -eq 'moderate') "dial depth: null profile -> fail-safe moderate"

# Iteration 7 T001 (FR-009/FR-025, Amendment A4) — the per-lens workshop agenda generator + render.
$wsAgenda = @(Get-SpecrewLensWorkshopAgenda -LensId 'architecture-core' -CatalogDir $catalogDir)
Assert-True ($wsAgenda.Count -ge 3) "workshop agenda: architecture-core yields its decision-point prompts"
Assert-True ((($wsAgenda) -join '|') -eq ((@(Get-SpecrewLensDecisionPoints -LensId 'architecture-core' -CatalogDir $catalogDir)) -join '|')) "workshop agenda IS the lens decision points (reuses the extractor; no parallel bank)"
Assert-True (@(Get-SpecrewLensWorkshopAgenda -LensId 'no-such-lens' -CatalogDir $catalogDir).Count -eq 0) "workshop agenda: missing lens -> empty (graceful)"
$wsRender = Format-SpecrewLensWorkshopAgenda -SelectedLenses @('architecture-core', 'data-storage') -CatalogDir $catalogDir
Assert-True ($wsRender -match '## Workshop Agenda') "workshop agenda render: section heading"
Assert-True ($wsRender -match '(?m)^### data-storage') "workshop agenda render: per-lens heading"
Assert-True ($wsRender -match '(?m)^1\. ') "workshop agenda render: numbered discussion prompts"
Assert-True ($wsRender -match 'Decision / agreement:' -and $wsRender -match 'Depth used:' -and $wsRender -match 'Moved on:') "workshop agenda render: captures decision/agreement, depth, moved-on"
Assert-True ($wsRender -notmatch '(?m)^\s*\+ ') "workshop agenda render: no '+'-at-line-start (markdownlint-safe)"
Assert-True ((Format-SpecrewLensWorkshopAgenda -SelectedLenses @() -CatalogDir $catalogDir) -match 'None available') "workshop agenda render: no lenses -> None available (graceful)"

# Iteration 7 T004 (FR-009, Amendment A4) — the recorded workshop decisions surface for the design analysis.
$wsTmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ws-dec-{0}.json" -f ([System.Guid]::NewGuid().ToString('N')))
try {
    Set-Content -LiteralPath $wsTmp -Encoding UTF8 -Value (@{ selected = @('ui-ux', 'data-storage'); workshop = @{ 'ui-ux' = @{ decision = 'dark theme, high-contrast, DPI-aware'; depth = 'moderate' }; 'data-storage' = @{ decision = 'blob + metadata table'; depth = 'expert-terse' } } } | ConvertTo-Json -Depth 8)
    $wsDec = Format-SpecrewLensWorkshopDecisions -ArtifactPath $wsTmp
    Assert-True ($wsDec -match '## Lens Decisions') "workshop decisions render: section heading"
    Assert-True ($wsDec -match 'ui-ux.*dark theme') "workshop decisions render: surfaces the recorded ui-ux decision"
    Assert-True ($wsDec -match 'expert-terse') "workshop decisions render: surfaces the recorded depth"
    Assert-True ((Format-SpecrewLensWorkshopDecisions -ArtifactPath (Join-Path ([System.IO.Path]::GetTempPath()) 'no-such-ws-artifact.json')) -match 'None recorded') "workshop decisions render: absent artifact -> None recorded (graceful)"
}
finally { Remove-Item -LiteralPath $wsTmp -Force -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host "All lens-applicability selector tests passed." -ForegroundColor Green
exit 0
