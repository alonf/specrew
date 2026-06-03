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

Write-Host ""
Write-Host "All lens-applicability selector tests passed." -ForegroundColor Green
exit 0
