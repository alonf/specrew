# continuous-co-review-update-resync.tests.ps1
#
# Fix 3 (iter-007 deploy/shadowing): a project's deployed Stop hook runs the PROJECT's OWN copy of the navigator
# internals (the provider resolution ladder prefers ProjectRoot over the installed module), so a co-review
# SOURCE fix stays INERT in a project until that in-project copy is refreshed. `specrew update` re-runs
# deploy-squad-runtime.ps1, whose Copy-ManagedDirectory OVERWRITES the in-project tree on content-diff (the CCR
# tree was added to that copy set in 0.39.0). THIS test pins the re-sync guarantee: a STALE in-project navigator
# file is refreshed to the source, and a source file ABSENT from the stale project is added.
#
# KNOWN REMAINING GAP (filed, NOT a code fix here): the contained re-sync only helps once 0.39.0 is PUBLISHED to
# PSGallery - 0.38.0 is the latest published, so for a downstream `Update-Module` user the deploy script itself
# still lacks the CCR copy block and the fix is inert. The resolution-ladder change (prefer module over the
# stale project copy, so a module-only bump takes effect without `specrew update`) is the bigger call - flagged,
# not rushed (project-copy-wins is plausibly deliberate version-pinning). See the iter-007 memory.

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
$deployScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'
if (-not (Test-Path -LiteralPath $deployScript)) { throw "deploy-squad-runtime.ps1 not found: $deployScript" }

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

# The deploy script has a main block; extract just the copy functions via AST (no main-block execution).
function Get-NamedFunctionTexts {
    param([string]$Path, [string[]]$Names)
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$t, [ref]$e)
    $texts = @()
    foreach ($n in $Names) {
        $fn = $ast.FindAll({ param($x) ($x -is [System.Management.Automation.Language.FunctionDefinitionAst]) -and $x.Name -eq $n }, $true) | Select-Object -First 1
        if (-not $fn) { throw "function '$n' not found in $Path" }
        $texts += $fn.Extent.Text
    }
    return $texts
}
# dot-source each extracted function at SCRIPT scope so it is callable below (not trapped in a helper's scope).
foreach ($fnText in (Get-NamedFunctionTexts -Path $deployScript -Names @('Add-DeploymentAction', 'Ensure-Directory', 'Set-ManagedFile', 'Copy-ManagedDirectory'))) {
    . ([scriptblock]::Create($fnText))
}

$sandbox = Join-Path $env:TEMP ("ccr-resync-" + [guid]::NewGuid().ToString('N'))
$src = Join-Path $sandbox 'src'; $dst = Join-Path $sandbox 'dst'
New-Item -ItemType Directory -Path $src, $dst -Force | Out-Null
try {
    # source = the current (e.g. 0.39.0) content; target = a STALE in-project copy of the same file, plus a
    # brand-new source file that the stale project does not have at all (e.g. the iter-007 bridge).
    Set-Content -LiteralPath (Join-Path $src 'continuous-co-review-navigator.ps1') -Value "function Get-Nav { 'CURRENT source reader' }" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $src 'reviewer-authorization-sync.ps1') -Value "# bridge file added by a newer Specrew" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $dst 'continuous-co-review-navigator.ps1') -Value "function Get-Nav { 'STALE init-time copy' }" -Encoding UTF8

    $actions = [System.Collections.ArrayList]::new()
    Copy-ManagedDirectory -SourcePath $src -TargetPath $dst -Actions $actions

    $navAfter = Get-Content -LiteralPath (Join-Path $dst 'continuous-co-review-navigator.ps1') -Raw
    Assert-True ($navAfter -match 'CURRENT source reader') 'specrew update / deploy REFRESHES a stale in-project navigator file to the source'
    Assert-True (-not ($navAfter -match 'STALE init-time copy')) 'the stale content is gone (overwritten, not preserved)'
    Assert-True (Test-Path -LiteralPath (Join-Path $dst 'reviewer-authorization-sync.ps1')) 'a source file ABSENT from the stale project is added by the re-sync (the iter-007 bridge would land)'
}
finally { Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue }
Write-Host "`n=== continuous-co-review-update-resync.tests.ps1: all assertions passed ===" -ForegroundColor Green
