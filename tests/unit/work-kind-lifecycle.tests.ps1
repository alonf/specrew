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
    # lifecycle_template is relative to the EXTENSION root (where the catalog lives), NOT the repo root.
    $extRoot = Join-Path $repoRoot 'extensions/specrew-speckit'
    $tmplAbs = Join-Path $extRoot ([string]$entry['lifecycle_template'])
    if (-not (Test-Path -LiteralPath $tmplAbs -PathType Leaf)) {
        Write-Fail ("kind '{0}' lifecycle_template '{1}' does not exist under the extension tree" -f $k, $entry['lifecycle_template'])
    }
}
Write-Pass "SC-016: all 4 work kinds declare a lifecycle_template pointing to a real template file in the extension tree."

# --- helper: build a throwaway project in the REAL DEPLOYED shape (the extension deploys to
#     .specify/extensions/specrew-speckit/, templates + catalog ride WITH it) — F1 regression fixture ---
$srcExt = Join-Path $repoRoot 'extensions/specrew-speckit'
function New-LifecycleFixture {
    param([string]$Kind, [switch]$OmitTemplates, [switch]$WithRefocus)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("wk-lc-" + [System.IO.Path]::GetRandomFileName())
    $deployExt = Join-Path $dir '.specify/extensions/specrew-speckit'
    New-Item -ItemType Directory -Force (Join-Path $dir '.specrew') | Out-Null
    New-Item -ItemType Directory -Force (Join-Path $deployExt 'knowledge') | Out-Null
    "work_kind: $Kind`nschema_version: `"1.0`"" | Set-Content -LiteralPath (Join-Path $dir '.specrew/work-kind.yml') -Encoding UTF8
    Copy-Item -LiteralPath (Join-Path $srcExt 'knowledge/work-kinds.yml') -Destination (Join-Path $deployExt 'knowledge/work-kinds.yml')
    if (-not $OmitTemplates) {
        $destLc = Join-Path $deployExt 'templates/lifecycle'
        New-Item -ItemType Directory -Force $destLc | Out-Null
        foreach ($t in (Get-ChildItem -LiteralPath (Join-Path $srcExt 'templates/lifecycle') -Filter '*.md' -File)) {
            Copy-Item -LiteralPath $t.FullName -Destination (Join-Path $destLc $t.Name)
        }
    }
    if ($WithRefocus) {
        # add the deployed refocus assets so the refocus (session-start) surface can run end-to-end
        New-Item -ItemType Directory -Force (Join-Path $deployExt 'refocus') | Out-Null
        New-Item -ItemType Directory -Force (Join-Path $deployExt 'scripts') | Out-Null
        Copy-Item -LiteralPath (Join-Path $srcExt 'refocus-scopes.json') -Destination (Join-Path $deployExt 'refocus-scopes.json')
        foreach ($d in (Get-ChildItem -LiteralPath (Join-Path $srcExt 'refocus') -Filter '*.md' -File)) {
            Copy-Item -LiteralPath $d.FullName -Destination (Join-Path $deployExt "refocus/$($d.Name)")
        }
        Copy-Item -LiteralPath (Join-Path $srcExt 'scripts/work-kind-common.ps1') -Destination (Join-Path $deployExt 'scripts/work-kind-common.ps1')
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

# --- 6) LIVE INTAKE/START SURFACE: the REFOCUS engine surfaces the lifecycle contract at session-start,
#        BEFORE work begins. (DF-009 fired at intake; the validator runs too late — a work item can start
#        with the agent improvising before the validator ever runs. Tested in the real DEPLOYED shape.) ---
$proj = New-LifecycleFixture -Kind 'docs-only' -WithRefocus
try {
    $savedMp = $env:SPECREW_MODULE_PATH; $env:SPECREW_MODULE_PATH = $null
    Push-Location $proj
    $out = (& pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'scripts/internal/refocus.ps1') 2>&1 | Out-String)
    Pop-Location
    $env:SPECREW_MODULE_PATH = $savedMp
    if ($out -notmatch '(?i)work-kind lifecycle' -or $out -notmatch 'docs-only-lifecycle\.md') {
        Write-Fail ("the refocus (session-start) surface must show the docs-only lifecycle contract; got:`n{0}" -f ($out.Substring(0, [Math]::Min(500, $out.Length))))
    }
}
finally { if ((Get-Location).Path -ne $repoRoot) { Set-Location $repoRoot }; Remove-Item -Recurse -Force $proj -ErrorAction SilentlyContinue }
Write-Pass "SC-016: the REFOCUS (intake/start) surface surfaces the resolved lifecycle contract at session-start in the real DEPLOYED shape — the surface that actually causes DF-009, not the too-late validator."

Write-Host "`nWork-kind lifecycle operationalization (FR-023 / SC-016): all assertions pass" -ForegroundColor Green
