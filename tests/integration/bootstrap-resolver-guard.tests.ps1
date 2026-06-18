[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# F-174 iteration 011 (P1): the clean-install bootstrap-resolution guard.
#
# The bootstrap + handover providers deploy to the extension tree, where they have NO co-located
# scripts/internal/bootstrap sibling. They resolve the components via: co-located | project-local self-host
# source tree | SPECREW_MODULE_PATH | the newest INSTALLED Specrew module. The original fallback took the
# blindly-newest module - but not every Specrew version ships the bootstrap components in its FileList
# (0.34.0 did; 0.35.0/0.36.0 did NOT). So when a newer bootstrap-LESS module outranks the bootstrap-bearing
# one, "newest wins" computes a non-existent path, the dot-source throws, the top-level try swallows it, the
# hook exits 0 - and SILENTLY writes nothing. The self-host fallback also keeps the current dogfood tree from
# falling through to a stale env/module copy while the deployed .specify provider is selected.
#
# The guard: pick the newest module that ACTUALLY CONTAINS scripts/internal/bootstrap. This test locks:
#   (1) the SELECTION PREDICATE behaves - newest-with-bootstrap beats newer-without (and the OLD blind pipeline
#       would have mis-picked, demonstrating the guard's value);
#   (2) BOTH provider sources carry the project-local self-host fallback and Where-Object bootstrap-presence
#       filter (no silent revert to stale env / blind-newest).
#   (3) A deployed .specify-shaped provider in a self-host project resolves the project source tree even when
#       SPECREW_MODULE_PATH points at a bad tree and PSModulePath excludes any usable Specrew module.
# The live Get-Module path itself is not driven here (it reads the real PSModulePath); the FileList-completeness
# test is the companion guard that F-174 ALWAYS ships the bootstrap components so it can be the chosen module.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path

# --- Test 1: the selection predicate picks newest-WITH-bootstrap over a newer bootstrap-LESS module. ---
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('specrew-p1-' + [guid]::NewGuid().ToString('N'))
try {
    $base036 = Join-Path $tmp '0.36.0'   # newer, NO bootstrap (the 0.35/0.36 shape)
    $base034 = Join-Path $tmp '0.34.0'   # older, HAS bootstrap
    New-Item -ItemType Directory -Path $base036 -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $base034 'scripts/internal/bootstrap') -Force | Out-Null

    # Emulate the Get-Module -ListAvailable result (PSModuleInfo carries .Version + .ModuleBase).
    $fakeModules = @(
        [pscustomobject]@{ Version = [version]'0.36.0'; ModuleBase = $base036 }
        [pscustomobject]@{ Version = [version]'0.34.0'; ModuleBase = $base034 }
    )

    # The GUARDED pipeline (what the providers now run).
    $guarded = $fakeModules | Sort-Object Version -Descending |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.ModuleBase 'scripts/internal/bootstrap') } |
        Select-Object -First 1
    if ($null -eq $guarded) { Fail '1: guarded selection returned nothing (a bootstrap-bearing module was present)' }
    if ($guarded.Version -ne [version]'0.34.0') { Fail "1: guarded selection picked $($guarded.Version); expected 0.34.0 (newest WITH bootstrap)" }
    Write-Pass '1: guarded selection picks the newest module that CONTAINS scripts/internal/bootstrap (0.34.0), skipping bootstrap-less 0.36.0'

    # The OLD blind pipeline (what shipped before) would have mis-picked the bootstrap-less newest -> silent no-op.
    $blind = $fakeModules | Sort-Object Version -Descending | Select-Object -First 1
    if ($blind.Version -ne [version]'0.36.0') { Fail '1: (sanity) blind selection should pick 0.36.0' }
    if (Test-Path -LiteralPath (Join-Path $blind.ModuleBase 'scripts/internal/bootstrap')) { Fail '1: (sanity) the blind pick should NOT contain bootstrap' }
    Write-Pass '1: the OLD blind pipeline would have mis-picked bootstrap-less 0.36.0 (the bug the guard closes)'
}
finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}

# --- Test 2: BOTH provider sources carry the bootstrap-presence filter (no silent revert to blind-newest). ---
foreach ($rel in 'scripts/internal/specrew-bootstrap-provider.ps1', 'scripts/internal/specrew-handover-provider.ps1') {
    $src = Get-Content -LiteralPath (Join-Path $repoRoot $rel) -Raw
    if ($src -notmatch "\`$selfHostBdir\s*=\s*Join-Path\s+\`$root 'scripts/internal/bootstrap'") {
        Fail "2: $rel is missing the project-local self-host bootstrap fallback"
    }
    if ($src -notmatch 'Test-Path -LiteralPath \$selfHostBdir') {
        Fail "2: $rel does not prefer the project-local self-host fallback before ambient env/module resolution"
    }
    # The blind one-liner ('... | Sort-Object Version -Descending | Select-Object -First 1' with no Where) must be gone.
    if ($src -match 'Get-Module -ListAvailable Specrew \| Sort-Object Version -Descending \| Select-Object -First 1') {
        Fail "2: $rel still uses the BLIND newest-module pick (no bootstrap-presence filter) - the P1 guard regressed"
    }
    if ($src -notmatch "Where-Object \{ Test-Path -LiteralPath \(Join-Path \`$_\.ModuleBase 'scripts/internal/bootstrap'\)") {
        Fail "2: $rel is missing the Where-Object bootstrap-presence filter (the P1 guard)"
    }
    Write-Pass "2: $rel carries the self-host fallback and bootstrap-presence filter in its module fallback"
}

# --- Test 3: the deployed .specify provider resolves the self-host source tree before stale ambient fallback. ---
$tmp2 = Join-Path ([System.IO.Path]::GetTempPath()) ('specrew-selfhost-resolve-' + [guid]::NewGuid().ToString('N'))
$origModulePath = $env:SPECREW_MODULE_PATH
$origPSModulePath = $env:PSModulePath
try {
    $proj = Join-Path $tmp2 'proj'
    $deployedScripts = Join-Path $proj '.specify/extensions/specrew-speckit/scripts'
    $internal = Join-Path $proj 'scripts/internal'
    $scriptRoot = Join-Path $proj 'scripts'
    New-Item -ItemType Directory -Path $deployedScripts -Force | Out-Null
    New-Item -ItemType Directory -Path $internal -Force | Out-Null
    New-Item -ItemType Directory -Path $scriptRoot -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj 'specs/001-selfhost') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj 'extensions/specrew-speckit/scripts') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'hosts') -Destination (Join-Path $proj 'hosts') -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts/internal/bootstrap') -Destination (Join-Path $internal 'bootstrap') -Recurse -Force
    Get-ChildItem -LiteralPath (Join-Path $repoRoot 'scripts/internal') -Filter '*.ps1' -File |
        ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $internal $_.Name) -Force }
    foreach ($f in 'decisions-split.ps1', 'append-only-logs.ps1', 'psd1-sort.ps1', 'auto-detection.ps1') {
        Copy-Item -LiteralPath (Join-Path $repoRoot "scripts/$f") -Destination (Join-Path $scriptRoot $f) -Force
    }
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1') -Destination (Join-Path $proj 'extensions/specrew-speckit/scripts/shared-governance.ps1') -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts/internal/specrew-bootstrap-provider.ps1') -Destination (Join-Path $deployedScripts 'specrew-bootstrap-provider.ps1') -Force

    $env:SPECREW_MODULE_PATH = Join-Path $tmp2 'missing-dev-tree'
    $env:PSModulePath = (Join-Path $PSHOME 'Modules')
    $provider = Join-Path $deployedScripts 'specrew-bootstrap-provider.ps1'
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $provider --event-json '{"session_id":"selfhost-resolve","source":"startup","hook_event_name":"SessionStart"}' --project-root $proj 2>&1 | Out-String
    if ($out -match 'PROVIDER_FAILED') {
        Fail "3: deployed self-host bootstrap provider failed instead of resolving project-local source components:`n$out"
    }
    if ($out -notmatch 'MANDATORY FIRST ACTION') {
        Fail "3: deployed self-host bootstrap provider did not emit the visible orientation directive:`n$out"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $proj '.specrew/last-start-prompt.md'))) {
        Fail '3: deployed self-host bootstrap provider did not write last-start-prompt.md'
    }
    Write-Pass '3: deployed .specify bootstrap provider resolves project-local self-host source before stale env/module fallback'
}
finally {
    if ($null -eq $origModulePath) { Remove-Item Env:SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $origModulePath }
    $env:PSModulePath = $origPSModulePath
    if (Test-Path -LiteralPath $tmp2) { Remove-Item -LiteralPath $tmp2 -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Pass 'bootstrap-resolver-guard: P1 clean-install resolution guard holds'
exit 0
