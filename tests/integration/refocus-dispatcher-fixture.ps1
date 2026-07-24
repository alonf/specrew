# Shared governed-project fixture for the REAL specrew-hook-dispatcher.ps1 + REAL refocus engine.
# EXTRACTED (maintainer 2026-07-12) from refocus-dispatcher.tests.ps1's New-ScratchProject so the
# reviewer-hook-suppression paired test can REUSE the SAME governed fixture instead of creating a second
# substitute. A SessionStart source=compact through this fixture produces the positive refocus marker
# '[specrew-refocus] trigger=b1 scope=general+boundary.implement' on stdout; the SPECREW_REFOCUS_DISABLE
# kill switch silences it before any parsing. Both properties are what the paired test asserts.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-RefocusDispatcherFixture {
    # Build a governed scratch project at $ProjectRoot that drives the real dispatcher + real refocus engine.
    # Returns the dispatcher path, project root, the derived codex host binding, the positive marker regex, and
    # the SessionStart/compact event JSON. Idempotent: removes and rebuilds $ProjectRoot.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$RepoRoot
    )
    if (Test-Path -LiteralPath $ProjectRoot) { Remove-Item -LiteralPath $ProjectRoot -Recurse -Force }
    $scriptsDir = Join-Path $ProjectRoot '.specify\extensions\specrew-speckit\scripts'
    $refocusDir = Join-Path $ProjectRoot '.specify\extensions\specrew-speckit\refocus'
    New-Item -ItemType Directory -Path (Join-Path $ProjectRoot '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $refocusDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'scripts\internal\specrew-hook-dispatcher.ps1') -Destination $scriptsDir -Force
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'scripts\internal\refocus.ps1') -Destination $scriptsDir -Force
    Copy-Item -Path (Join-Path $RepoRoot 'extensions\specrew-speckit\refocus\*.md') -Destination $refocusDir -Force
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'extensions\specrew-speckit\refocus-scopes.json') -Destination (Join-Path $ProjectRoot '.specify\extensions\specrew-speckit') -Force
    $catalogPath = Join-Path $ProjectRoot '.specify\extensions\specrew-speckit\refocus-scopes.json'
    $catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
    # Keep ONLY the refocus provider (as refocus-dispatcher.tests.ps1 does) so bootstrap fallback cannot obscure
    # the breaker-suppression / marker assertions.
    $catalog.providers = @($catalog.providers | Where-Object { [string]$_.id -eq 'refocus' })
    [System.IO.File]::WriteAllText($catalogPath, ($catalog | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
    $startContext = @{ session_state = @{ boundary_type = 'implement'; feature_ref = 'dispatcher-fixture' } } | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\start-context.json'), $startContext, [System.Text.UTF8Encoding]::new($false))

    # Derive the codex host's dispatcher binding the same way Invoke-Dispatcher does (from the host manifest), so
    # the SessionStart routing/output shaping matches production.
    $hostBinding = ''
    $manifestPath = Join-Path $RepoRoot 'hosts\codex\host.psd1'
    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        try {
            $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
            $runtime = $manifest.RefocusHookBindings.DispatcherRuntime
            if ($null -ne $runtime) { $hostBinding = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($runtime | ConvertTo-Json -Depth 8 -Compress))) }
        }
        catch { $hostBinding = '' }
    }

    return [pscustomobject]@{
        dispatcher    = (Join-Path $scriptsDir 'specrew-hook-dispatcher.ps1')
        project_root  = $ProjectRoot
        host_binding  = $hostBinding
        marker_regex  = '\[specrew-refocus\] trigger=b1'
        event_compact = '{"session_id":"sess-abc-123","source":"compact"}'
    }
}
