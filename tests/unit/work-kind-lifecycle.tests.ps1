[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 182 iteration 004 (T404, FR-023 / SC-016): work-kind -> lifecycle-template operationalization.
#
# SC-016 must prove RUNTIME RESOLUTION, not file presence: a declared work_kind in .specrew/work-kind.yml
# resolves THROUGH the catalog to its <kind>-lifecycle.md, the template is actually resolvable, and a
# surface renders the lifecycle contract. (File presence alone is explicitly NOT enough.)

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/work-kind-common.ps1')

$kinds = @('software-feature', 'bug-bash', 'docs-only', 'devops')
$catalogPath = Join-Path $repoRoot 'extensions/specrew-speckit/knowledge/work-kinds.yml'

# --- 1) catalog: every kind declares a lifecycle_template pointing to a real template file ---
$catalog = ConvertFrom-SpecrewWorkKindCatalog -Text (Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8)
foreach ($k in $kinds) {
    $entry = @($catalog.work_kinds) | Where-Object { [string]$_.id -eq $k } | Select-Object -First 1
    if ($null -eq $entry) { Write-Fail "catalog missing kind '$k'" }
    if (-not $entry.Contains('lifecycle_template') -or [string]::IsNullOrWhiteSpace([string]$entry['lifecycle_template'])) {
        Write-Fail "kind '$k' has no lifecycle_template field (FR-023)"
    }
    $tmplAbs = Join-Path $repoRoot ([string]$entry['lifecycle_template'])
    if (-not (Test-Path -LiteralPath $tmplAbs -PathType Leaf)) {
        Write-Fail ("kind '{0}' lifecycle_template '{1}' does not exist on disk" -f $k, $entry['lifecycle_template'])
    }
}
Write-Pass "SC-016: all 4 work kinds declare a lifecycle_template pointing to an existing template file."

# --- helper: build a throwaway project (CI-lane layout) with a declaration + catalog + templates ---
function New-LifecycleFixture {
    param([string]$Kind, [switch]$OmitTemplates)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("wk-lc-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Force (Join-Path $dir '.specrew') | Out-Null
    New-Item -ItemType Directory -Force (Join-Path $dir 'extensions/specrew-speckit/knowledge') | Out-Null
    "work_kind: $Kind`nschema_version: `"1.0`"" | Set-Content -LiteralPath (Join-Path $dir '.specrew/work-kind.yml') -Encoding UTF8
    Copy-Item -LiteralPath $catalogPath -Destination (Join-Path $dir 'extensions/specrew-speckit/knowledge/work-kinds.yml')
    if (-not $OmitTemplates) {
        $destLc = Join-Path $dir 'templates/lifecycle'
        New-Item -ItemType Directory -Force $destLc | Out-Null
        foreach ($t in (Get-ChildItem -LiteralPath (Join-Path $repoRoot 'templates/lifecycle') -Filter '*.md' -File)) {
            Copy-Item -LiteralPath $t.FullName -Destination (Join-Path $destLc $t.Name)
        }
    }
    return $dir
}

# --- 2) RUNTIME RESOLUTION: each kind resolves work_kind -> the correct template, present + resolvable ---
foreach ($k in $kinds) {
    $fixture = New-LifecycleFixture -Kind $k
    try {
        # neutralize SPECREW_MODULE_PATH so resolution is proven from the PROJECT, not the dev module
        $savedMp = $env:SPECREW_MODULE_PATH; $env:SPECREW_MODULE_PATH = $null
        $r = Get-SpecrewWorkKindLifecycle -ProjectRoot $fixture
        $env:SPECREW_MODULE_PATH = $savedMp
        if (-not $r.Declared) { Write-Fail "kind '$k': resolver did not see the declaration" }
        if ($r.Kind -ne $k) { Write-Fail ("kind '{0}': resolver returned Kind '{1}'" -f $k, $r.Kind) }
        $expected = "templates/lifecycle/$k-lifecycle.md"
        if ($r.LifecycleTemplate -ne $expected) { Write-Fail ("kind '{0}': resolved template '{1}' != '{2}'" -f $k, $r.LifecycleTemplate, $expected) }
        if (-not $r.Exists) { Write-Fail ("kind '{0}': template declared but NOT resolvable ({1}) — SC-016 needs runtime resolution, not just a catalog field" -f $k, $r.Reason) }
    }
    finally { Remove-Item -Recurse -Force $fixture -ErrorAction SilentlyContinue }
}
Write-Pass "SC-016: all 4 work kinds resolve from .specrew/work-kind.yml + catalog to a RESOLVABLE <kind>-lifecycle.md (runtime resolution, not file-presence)."

# --- 3) NOT file-presence: a declared kind whose template is NOT deployed resolves Declared but Exists=false ---
$missing = New-LifecycleFixture -Kind 'docs-only' -OmitTemplates
try {
    $savedMp = $env:SPECREW_MODULE_PATH; $env:SPECREW_MODULE_PATH = $null
    $r = Get-SpecrewWorkKindLifecycle -ProjectRoot $missing
    $env:SPECREW_MODULE_PATH = $savedMp
    if (-not $r.Declared) { Write-Fail "missing-template fixture: should still see the declaration" }
    if ($r.Exists) { Write-Fail "missing-template fixture: resolver claims Exists=true with NO template deployed — that is the file-presence failure SC-016 forbids" }
    if ($r.Reason -notmatch 'not-resolvable') { Write-Fail "missing-template fixture: expected a not-resolvable reason, got '$($r.Reason)'" }
}
finally { Remove-Item -Recurse -Force $missing -ErrorAction SilentlyContinue }
Write-Pass "SC-016: a declared kind with no deployed template resolves Declared=true but Exists=false (proves resolution checks deployment, not just the catalog field)."

# --- 4) SURFACE: the intake/start/refocus surface renders the resolved lifecycle contract ---
$fixture = New-LifecycleFixture -Kind 'docs-only'
try {
    $surface = Get-SpecrewWorkKindLifecycleSurface -ProjectRoot $fixture
    if ([string]::IsNullOrWhiteSpace($surface)) { Write-Fail "surface: returned nothing for a declared work_kind" }
    if ($surface -notmatch 'docs-only' -or $surface -notmatch 'docs-only-lifecycle\.md') {
        Write-Fail "surface: must name the kind + its lifecycle contract; got: $surface"
    }
}
finally { Remove-Item -Recurse -Force $fixture -ErrorAction SilentlyContinue }
Write-Pass "SC-016: the lifecycle surface renders 'work kind -> lifecycle contract' for the selected kind (the crew is pointed to its lifecycle, not improvised ceremony)."

# --- 5) no declaration -> surface is silent (no false pointer) ---
$bare = Join-Path ([System.IO.Path]::GetTempPath()) ("wk-bare-" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force $bare | Out-Null
try {
    $s = Get-SpecrewWorkKindLifecycleSurface -ProjectRoot $bare
    if ($null -ne $s) { Write-Fail "no-declaration: surface should be silent, got: $s" }
}
finally { Remove-Item -Recurse -Force $bare -ErrorAction SilentlyContinue }
Write-Pass "SC-016: no work-kind declared -> the surface is silent (no false lifecycle pointer)."

# --- 6) LIVE SURFACE: the work-kind VALIDATOR (the intake/CI runtime surface) carries the lifecycle pointer ---
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/work-kind-validator.ps1')
$proj = New-LifecycleFixture -Kind 'docs-only'
try {
    Push-Location $proj
    git init -q 2>$null; git config user.email t@t.t 2>$null; git config user.name t 2>$null
    'doc' | Set-Content -LiteralPath (Join-Path $proj 'README.md') -Encoding UTF8
    git add -A 2>$null; git commit -qm base 2>$null
    "# more`ndocs" | Set-Content -LiteralPath (Join-Path $proj 'README.md') -Encoding UTF8
    git add -A 2>$null; git commit -qm change 2>$null
    Pop-Location
    $savedMp = $env:SPECREW_MODULE_PATH; $env:SPECREW_MODULE_PATH = $null
    $res = Invoke-SpecrewWorkKindValidation -ProjectPath $proj -BaseRef HEAD~1 -HeadRef HEAD -Mode advisory
    $env:SPECREW_MODULE_PATH = $savedMp
    if (-not $res.Contains('lifecycle')) { Write-Fail "validator result has no 'lifecycle' field (FR-023 surface wiring missing)" }
    if ([string]::IsNullOrWhiteSpace([string]$res.lifecycle) -or [string]$res.lifecycle -notmatch 'docs-only-lifecycle\.md') {
        Write-Fail ("validator 'lifecycle' surface must point to docs-only-lifecycle.md; got: {0}" -f $res.lifecycle)
    }
}
finally { if ((Get-Location).Path -ne $repoRoot) { Set-Location $repoRoot }; Remove-Item -Recurse -Force $proj -ErrorAction SilentlyContinue }
Write-Pass "SC-016: the live work-kind validator (intake/CI runtime surface) carries the resolved lifecycle contract pointer (DF-009 fixed)."

Write-Host "`nWork-kind lifecycle operationalization (FR-023 / SC-016): all assertions pass" -ForegroundColor Green
