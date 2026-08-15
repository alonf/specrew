$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $repoRoot 'scripts/internal/review-engine-resolution.ps1')

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$resolutionSource = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/internal/review-engine-resolution.ps1') -Raw
Assert-True ($resolutionSource -notmatch 'Zionet') 'shipped runtime provenance does not disclose the maintainer employer'
Assert-True ($resolutionSource -match 'OneDrive - <Org>') 'the useful OneDrive provenance example remains generic'

function New-RuntimeFixture {
    param([string]$Root, [string]$Content = 'v1')
    New-Item -ItemType Directory -Path $Root -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $Root '_load.ps1'), "`$script:loaded = '$Content'", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $Root 'engine.ps1'), $Content, [Text.UTF8Encoding]::new($false))
}

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-review-engine-' + [guid]::NewGuid().ToString('N'))
try {
    $installed = Join-Path $scratch 'installed'
    $project = Join-Path $scratch 'project'
    New-RuntimeFixture -Root $installed
    New-Item -ItemType Directory -Path $project -Force | Out-Null

    $fallback = Resolve-SpecrewReviewEngineRoot -ProjectRoot $project -InstalledRuntimeRoot $installed
    Assert-True ($fallback.source -ceq 'installed') 'missing project runtime selects the installed engine explicitly'

    $projectRuntime = Join-Path $project 'scripts/internal/continuous-co-review'
    New-Item -ItemType Directory -Path (Split-Path -Parent $projectRuntime) -Force | Out-Null
    Copy-Item -LiteralPath $installed -Destination $projectRuntime -Recurse
    $hash = Get-SpecrewReviewRuntimeBundleSha256 -RuntimeRoot $projectRuntime
    $marker = [ordered]@{
        schema_version = '1.0'
        specrew_version = '0.40.0'
        runtime_bundle_sha256 = $hash
        source = 'test'
    }
    [IO.File]::WriteAllText((Join-Path $projectRuntime '.specrew-runtime.json'), ($marker | ConvertTo-Json), [Text.UTF8Encoding]::new($false))

    $matched = Resolve-SpecrewReviewEngineRoot -ProjectRoot $project -InstalledRuntimeRoot $installed
    Assert-True ($matched.source -ceq 'project-deployed') 'a hash-identical project runtime is the selected engine'
    Assert-True ($matched.bundle_sha256 -ceq $hash) 'selection reports the exact compared bundle hash'
    Assert-True (-not $marker.Contains('managed_files')) 'legacy schema 1.0 markers remain supported during upgrade'

    $markerWithoutSchema = [ordered]@{
        specrew_version = '0.40.0'
        runtime_bundle_sha256 = $hash
        source = 'test'
    }
    [IO.File]::WriteAllText((Join-Path $projectRuntime '.specrew-runtime.json'), ($markerWithoutSchema | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
    $missingSchemaMessage = ''
    try { Resolve-SpecrewReviewEngineRoot -ProjectRoot $project -InstalledRuntimeRoot $installed | Out-Null }
    catch { $missingSchemaMessage = $_.Exception.Message }
    Assert-True ($missingSchemaMessage -like 'review-engine-marker-invalid:*') 'a marker missing schema_version fails with the named marker contract error'
    [IO.File]::WriteAllText((Join-Path $projectRuntime '.specrew-runtime.json'), ($marker | ConvertTo-Json), [Text.UTF8Encoding]::new($false))

    $installedEngine = Join-Path $installed 'engine.ps1'
    $projectEngine = Join-Path $projectRuntime 'engine.ps1'
    [IO.File]::WriteAllText($installedEngine, "line-one`nline-two`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($projectEngine, "line-one`r`nline-two`r`n", [Text.UTF8Encoding]::new($true))
    $normalizedInstalledHash = Get-SpecrewReviewRuntimeBundleSha256 -RuntimeRoot $installed
    $managedFiles = @(Get-SpecrewReviewRuntimeManagedFileManifest -RuntimeRoot $projectRuntime)
    $normalizedProjectHash = Get-SpecrewReviewRuntimeBundleSha256 -RuntimeRoot $projectRuntime -ManagedFiles $managedFiles
    Assert-True ($normalizedInstalledHash -ceq $normalizedProjectHash) 'runtime identity ignores managed-text BOM and line-ending normalization'
    $marker['runtime_bundle_sha256'] = $normalizedProjectHash
    $marker['managed_files'] = @($managedFiles)
    [IO.File]::WriteAllText((Join-Path $projectRuntime '.specrew-runtime.json'), ($marker | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))

    [IO.File]::WriteAllText((Join-Path $projectRuntime 'retired-stale.ps1'), 'old managed file', [Text.UTF8Encoding]::new($false))
    $staleTolerant = Resolve-SpecrewReviewEngineRoot -ProjectRoot $project -InstalledRuntimeRoot $installed
    Assert-True ($staleTolerant.source -ceq 'project-deployed') 'a manifest-bound runtime ignores preserved obsolete files outside the current managed set'

    [IO.File]::WriteAllText((Join-Path $projectRuntime 'engine.ps1'), 'project-newer-or-older', [Text.UTF8Encoding]::new($false))
    $driftMessage = ''
    try { Resolve-SpecrewReviewEngineRoot -ProjectRoot $project -InstalledRuntimeRoot $installed | Out-Null }
    catch { $driftMessage = $_.Exception.Message }
    Assert-True ($driftMessage -like 'review-engine-project-runtime-drifted:*specrew update*') 'marker/content drift fails loudly with update guidance'

    [IO.File]::WriteAllText($projectEngine, [IO.File]::ReadAllText($installedEngine), [Text.UTF8Encoding]::new($false))
    $managedFiles = @(Get-SpecrewReviewRuntimeManagedFileManifest -RuntimeRoot $projectRuntime |
        Where-Object path -CNE 'retired-stale.ps1')
    $marker['managed_files'] = @(
        [pscustomobject]@{ path = '../outside.ps1'; sha256 = ('a' * 64) }
    )
    $marker['runtime_bundle_sha256'] = $normalizedInstalledHash
    [IO.File]::WriteAllText((Join-Path $projectRuntime '.specrew-runtime.json'), ($marker | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $unsafeMessage = ''
    try { Resolve-SpecrewReviewEngineRoot -ProjectRoot $project -InstalledRuntimeRoot $installed | Out-Null }
    catch { $unsafeMessage = $_.Exception.Message }
    Assert-True ($unsafeMessage -like 'review-runtime-managed-path-unsafe:*') 'an unsafe managed-file manifest fails closed'

    [IO.File]::WriteAllText($projectEngine, 'project-newer-or-older', [Text.UTF8Encoding]::new($false))
    Remove-Item -LiteralPath (Join-Path $projectRuntime '.specrew-runtime.json') -Force
    $mismatchMessage = ''
    try { Resolve-SpecrewReviewEngineRoot -ProjectRoot $project -InstalledRuntimeRoot $installed | Out-Null }
    catch { $mismatchMessage = $_.Exception.Message }
    Assert-True ($mismatchMessage -like 'review-engine-version-mismatch:*specrew update*') 'an unversioned mismatched engine cannot run silently'

    $deploySource = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1') -Raw
    Assert-True ($deploySource -match '\.specrew-runtime\.json') 'init/update writes the review runtime marker'
    Assert-True ($deploySource -match 'Get-SpecrewReviewRuntimeBundleSha256') 'the marker binds the deployed runtime bundle'
    Assert-True ($deploySource -match 'managed_files') 'init/update records explicit managed-file retirement provenance'
    Assert-True ($deploySource -match "\`$sourceVersion = 'unknown'") 'legacy update layouts can deploy without a colocated module manifest'
    Assert-True ($deploySource -match 'Assert-SpecrewReviewRuntimePathContained') 'retirement contains every path component before hashing or deleting'
    Assert-True ($deploySource -match 'preserved-uncontained-retired-runtime-file') 'an uncontained retirement target is preserved, never deleted'

    # DRIFT-198-I009-011 (blocking): lexical containment is not containment. A reparse-point
    # ANCESTOR passes the under-root test while Get-Item/hash/Delete follow it outside the project,
    # and the marker supplying the path AND its hash is editable in the target project.
    $containRoot = Join-Path $scratch 'contain/root'
    $outside = Join-Path $scratch 'contain/outside'
    New-Item -ItemType Directory -Path $containRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $outside -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $outside 'victim.txt'), 'external', [Text.UTF8Encoding]::new($false))

    $plain = Join-Path $containRoot 'real.txt'
    [IO.File]::WriteAllText($plain, 'inside', [Text.UTF8Encoding]::new($false))
    Assert-True ((Assert-SpecrewReviewRuntimePathContained -Path $plain -Root $containRoot) -ceq ([IO.Path]::GetFullPath($plain))) 'an ordinary contained path is accepted'

    $escapeMessage = ''
    try { Assert-SpecrewReviewRuntimePathContained -Path (Join-Path $containRoot '../outside/victim.txt') -Root $containRoot | Out-Null }
    catch { $escapeMessage = $_.Exception.Message }
    Assert-True ($escapeMessage -like 'review-runtime-managed-path-escapes-root:*') 'a lexical parent escape is refused'

    $linkCreated = $false
    try {
        New-Item -ItemType SymbolicLink -Path (Join-Path $containRoot 'sub') -Target $outside -ErrorAction Stop | Out-Null
        $linkCreated = $true
    }
    catch { Write-Host 'SKIP: symlink creation unavailable (needs privilege); ancestor-escape case not exercised here' -ForegroundColor Yellow }
    if ($linkCreated) {
        $viaAncestor = Join-Path $containRoot 'sub/victim.txt'
        $ancestorMessage = ''
        try { Assert-SpecrewReviewRuntimePathContained -Path $viaAncestor -Root $containRoot | Out-Null }
        catch { $ancestorMessage = $_.Exception.Message }
        Assert-True ($ancestorMessage -like 'review-runtime-managed-path-link-unsupported:*') 'a reparse-point ANCESTOR is refused before hashing or deleting'
        Assert-True ([IO.File]::Exists((Join-Path $outside 'victim.txt'))) 'the external file is untouched'
    }
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'All review-engine resolution tests passed.' -ForegroundColor Green
