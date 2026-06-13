[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 182 — PR #2604 review-response (Codex P1 deployed-shape resolution).
#
# The work-kind validator + its CI workflow ship to a downstream project under
# `<proj>/.specify/extensions/specrew-speckit/...` (a real `specrew init` deploy). The bundled
# workflow template is copied VERBATIM into that project, where there is NO root `extensions/` tree —
# only the `.specify` copy. These tests prove resolution in that DEPLOYED shape:
#   1. the validator loads its catalog from `.specify/extensions/...` (proven by BEHAVIOR, not file-presence);
#   2. fail-open stays honest when NO catalog exists anywhere (advisory-warn, never a crash/spurious block,
#      and the warning NAMES the deployed `.specify` candidate);
#   3. the workflow's validator-path resolution works without a root `extensions/` and PREFERS `.specify`.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
$srcScripts = Join-Path $repoRoot 'extensions' 'specrew-speckit' 'scripts'
$srcCatalog = Join-Path $repoRoot 'extensions' 'specrew-speckit' 'knowledge' 'work-kinds.yml'

# --- helper: build a project in the REAL DEPLOYED shape — ONLY `.specify/extensions/specrew-speckit`,
#     NO root `extensions/` (unless -WithRootSource). The validator + its dot-source deps + the catalog
#     ride together under `.specify`, exactly as the PSGallery FileList installs them. ---
function New-DeployedFixture {
    param([switch]$OmitCatalog, [switch]$WithRootSource)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("wk-deployed-" + [Guid]::NewGuid().ToString('N'))
    $deployScripts = Join-Path $dir '.specify/extensions/specrew-speckit/scripts'
    $deployKnowledge = Join-Path $dir '.specify/extensions/specrew-speckit/knowledge'
    $null = New-Item -ItemType Directory -Force $deployScripts
    $null = New-Item -ItemType Directory -Force $deployKnowledge
    $null = New-Item -ItemType Directory -Force (Join-Path $dir '.specrew')
    foreach ($s in @('work-kind-validator.ps1', 'work-kind-common.ps1', 'provider-adapter.ps1', 'provider-generic.ps1')) {
        $src = Join-Path $srcScripts $s
        if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination (Join-Path $deployScripts $s) }
    }
    if (-not $OmitCatalog) {
        Copy-Item -LiteralPath $srcCatalog -Destination (Join-Path $deployKnowledge 'work-kinds.yml')
    }
    if ($WithRootSource) {
        # a hybrid tree (Specrew's own repo has both); used to prove the preference order
        $rootKnowledge = Join-Path $dir 'extensions/specrew-speckit/knowledge'
        $null = New-Item -ItemType Directory -Force $rootKnowledge
        Copy-Item -LiteralPath $srcCatalog -Destination (Join-Path $rootKnowledge 'work-kinds.yml')
    }
    return $dir
}

function Get-DeployedValidator { param([string]$Dir) Join-Path $Dir '.specify/extensions/specrew-speckit/scripts/work-kind-validator.ps1' }
function Set-Decl { param([string]$Dir, [string]$Kind) Set-Content -LiteralPath (Join-Path $Dir '.specrew/work-kind.yml') -Value "work_kind: $Kind`nschema_version: `"1.0`"" -Encoding UTF8 }

# === 1) the DEPLOYED validator loads the catalog from .specify/extensions/... (BEHAVIORAL proof) ===
# Dot-source the DEPLOYED copy (its $PSScriptRoot is the fixture's .specify scripts dir). With NO root
# `extensions/`, the only catalog is under `.specify`. A docs-only declaration touching a runtime `.ps1`
# can ONLY produce a changed-file-scope FAIL if the docs-only scope was actually read from that catalog —
# so the verdict is the proof the catalog loaded (file-presence alone would never exercise the scope).
$fx = New-DeployedFixture
try {
    Set-Decl -Dir $fx -Kind 'docs-only'
    . (Get-DeployedValidator -Dir $fx)
    $r = Invoke-SpecrewWorkKindValidation -ProjectPath $fx -ChangedFiles @('docs/x.md', 'src/app.ps1') -Branch 'docs/x' -Mode advisory
    Assert-True ($r.verdict -eq 'advisory-fail') "deployed: docs-only touching a runtime .ps1 -> advisory-fail (catalog loaded from .specify); got $($r.verdict)"
    $scope = @($r.findings | Where-Object { $_.check -eq 'changed-file-scope' })
    Assert-True ($scope.Count -eq 1) 'deployed: exactly one changed-file-scope finding (the docs-only allowed_scope was read from the .specify catalog)'
    Assert-True ($scope[0].message -match 'src/app\.ps1' -and $scope[0].message -match 'docs-only allows') 'deployed: the finding NAMES the offending .ps1 + the allowed scope (catalog content was used)'
    Assert-True (@($r.findings | Where-Object { $_.check -eq 'catalog' }).Count -eq 0) 'deployed: NO catalog-not-found warn — the .specify catalog resolved'
}
finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }

# === 2) fail-open stays HONEST when NO catalog exists anywhere ===
# Deployed scripts present, but the knowledge/work-kinds.yml omitted (beside-script, .specify, and source
# candidates all absent). Must degrade to advisory-warn — never a crash, never a spurious fail/block —
# and the warning must NAME the deployed .specify candidate (the real install location), not the
# source-tree path that only exists in Specrew's own repo.
$fxNoCat = New-DeployedFixture -OmitCatalog
try {
    Set-Decl -Dir $fxNoCat -Kind 'docs-only'
    . (Get-DeployedValidator -Dir $fxNoCat)
    $r = Invoke-SpecrewWorkKindValidation -ProjectPath $fxNoCat -ChangedFiles @('src/app.ps1') -Branch 'docs/x' -Mode advisory
    Assert-True ($r.verdict -eq 'advisory-warn') "deployed fail-open: no catalog anywhere -> advisory-warn; got $($r.verdict)"
    $cat = @($r.findings | Where-Object { $_.check -eq 'catalog' })
    Assert-True ($cat.Count -eq 1) 'deployed fail-open: exactly one catalog finding (the missing catalog is surfaced, not silently skipped)'
    # normalize separators: Join-Path renders the platform separator (\ on Windows, / on POSIX)
    Assert-True (($cat[0].message -replace '\\', '/') -match '\.specify/extensions/specrew-speckit/knowledge/work-kinds\.yml') 'deployed fail-open: the warn NAMES the deployed .specify candidate (not the source-tree path)'

    # honest even in BLOCKING mode: a missing catalog never escalates to a block (fail-open guarantee)
    $rb = Invoke-SpecrewWorkKindValidation -ProjectPath $fxNoCat -ChangedFiles @('src/app.ps1') -Branch 'docs/x' -Mode blocking
    Assert-True ($rb.verdict -eq 'advisory-warn') "deployed fail-open: missing catalog stays advisory-warn even in blocking mode (never a spurious block); got $($rb.verdict)"
}
finally { Remove-Item -Recurse -Force $fxNoCat -ErrorAction SilentlyContinue }

# === 3) the workflow's validator-path resolution: deployed-only works, and .specify is PREFERRED ===
# Replicate the workflow template's candidate ordering (the YAML run-block can't be executed here) and
# assert selection across the three shapes, then assert the actual YAML carries that contract.
function Select-WorkflowValidator {
    param([string]$Root)
    $cands = @(
        (Join-Path $Root '.specify/extensions/specrew-speckit/scripts/work-kind-validator.ps1'),
        (Join-Path $Root 'extensions/specrew-speckit/scripts/work-kind-validator.ps1')
    )
    return @($cands | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1)
}

function New-ResolutionFixture {
    param([switch]$Deployed, [switch]$Source)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("wk-res-" + [Guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Force $dir
    if ($Deployed) {
        $p = Join-Path $dir '.specify/extensions/specrew-speckit/scripts'
        $null = New-Item -ItemType Directory -Force $p
        Set-Content -LiteralPath (Join-Path $p 'work-kind-validator.ps1') -Value '# stub' -Encoding UTF8
    }
    if ($Source) {
        $p = Join-Path $dir 'extensions/specrew-speckit/scripts'
        $null = New-Item -ItemType Directory -Force $p
        Set-Content -LiteralPath (Join-Path $p 'work-kind-validator.ps1') -Value '# stub' -Encoding UTF8
    }
    return $dir
}

# (a) deployed-only (no root extensions/) -> resolves the .specify validator
$d = New-ResolutionFixture -Deployed
try {
    $sel = Select-WorkflowValidator -Root $d
    Assert-True ($sel -and ($sel -replace '\\', '/') -match '\.specify/extensions/specrew-speckit/scripts/work-kind-validator\.ps1') "workflow resolution: deployed-only (no root extensions/) resolves the .specify validator; got '$sel'"
}
finally { Remove-Item -Recurse -Force $d -ErrorAction SilentlyContinue }

# (b) both present -> PREFERS .specify
$d = New-ResolutionFixture -Deployed -Source
try {
    $sel = Select-WorkflowValidator -Root $d
    Assert-True ($sel -and ($sel -replace '\\', '/') -match '\.specify/extensions/specrew-speckit/scripts/work-kind-validator\.ps1') "workflow resolution: both shapes present -> prefers the deployed .specify validator; got '$sel'"
}
finally { Remove-Item -Recurse -Force $d -ErrorAction SilentlyContinue }

# (c) source-only -> resolves the source-tree validator (Specrew's own repo)
$d = New-ResolutionFixture -Source
try {
    $sel = Select-WorkflowValidator -Root $d
    Assert-True ($sel -and ($sel -replace '\\', '/') -match '(^|/)extensions/specrew-speckit/scripts/work-kind-validator\.ps1') "workflow resolution: source-only resolves the source-tree validator; got '$sel'"
}
finally { Remove-Item -Recurse -Force $d -ErrorAction SilentlyContinue }

# (d) neither -> nothing (honest advisory skip)
$d = New-ResolutionFixture
try {
    $sel = Select-WorkflowValidator -Root $d
    Assert-True ([string]::IsNullOrEmpty($sel)) "workflow resolution: neither shape present -> no validator (the workflow then exits 0, advisory not blocking); got '$sel'"
}
finally { Remove-Item -Recurse -Force $d -ErrorAction SilentlyContinue }

Write-Pass 'workflow resolution: deployed-only works, .specify is preferred, source-only works, neither -> honest skip.'

# (e) the actual workflow YAML carries the resolution contract (guards the artifact against regression)
$wf = Get-Content -LiteralPath (Join-Path $repoRoot 'templates/github/workflows/specrew-work-kind.yml') -Raw
$deployedTok = "'./.specify/extensions/specrew-speckit/scripts/work-kind-validator.ps1'"
$sourceTok = "'./extensions/specrew-speckit/scripts/work-kind-validator.ps1'"
$iDep = $wf.IndexOf($deployedTok)
$iSrc = $wf.IndexOf($sourceTok)
Assert-True ($iDep -ge 0) 'workflow YAML: lists the deployed .specify validator candidate'
Assert-True ($iSrc -ge 0) 'workflow YAML: lists the source-tree validator candidate'
Assert-True ($iDep -lt $iSrc) 'workflow YAML: the .specify candidate appears FIRST (prefers deployed)'
Assert-True ($wf -match 'Select-Object -First 1') 'workflow YAML: first-existing-wins selection'
Assert-True ($wf -match '(?m)exit 0') 'workflow YAML: honest advisory skip (exit 0) when neither path exists'

Write-Host "`nAll work-kind deployed-shape resolution assertions passed (Codex P1 #1 + #2)." -ForegroundColor Green
