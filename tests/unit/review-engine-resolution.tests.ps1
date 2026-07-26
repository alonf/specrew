$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $repoRoot 'scripts/internal/review-engine-resolution.ps1')

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

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

    $installedEngine = Join-Path $installed 'engine.ps1'
    $projectEngine = Join-Path $projectRuntime 'engine.ps1'
    [IO.File]::WriteAllText($installedEngine, "line-one`nline-two`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($projectEngine, "line-one`r`nline-two`r`n", [Text.UTF8Encoding]::new($true))
    $normalizedInstalledHash = Get-SpecrewReviewRuntimeBundleSha256 -RuntimeRoot $installed
    $normalizedProjectHash = Get-SpecrewReviewRuntimeBundleSha256 -RuntimeRoot $projectRuntime
    Assert-True ($normalizedInstalledHash -ceq $normalizedProjectHash) 'runtime identity ignores managed-text BOM and line-ending normalization'
    $marker['runtime_bundle_sha256'] = $normalizedProjectHash
    [IO.File]::WriteAllText((Join-Path $projectRuntime '.specrew-runtime.json'), ($marker | ConvertTo-Json), [Text.UTF8Encoding]::new($false))

    [IO.File]::WriteAllText((Join-Path $projectRuntime 'engine.ps1'), 'project-newer-or-older', [Text.UTF8Encoding]::new($false))
    $driftMessage = ''
    try { Resolve-SpecrewReviewEngineRoot -ProjectRoot $project -InstalledRuntimeRoot $installed | Out-Null }
    catch { $driftMessage = $_.Exception.Message }
    Assert-True ($driftMessage -like 'review-engine-project-runtime-drifted:*specrew update*') 'marker/content drift fails loudly with update guidance'

    Remove-Item -LiteralPath (Join-Path $projectRuntime '.specrew-runtime.json') -Force
    $mismatchMessage = ''
    try { Resolve-SpecrewReviewEngineRoot -ProjectRoot $project -InstalledRuntimeRoot $installed | Out-Null }
    catch { $mismatchMessage = $_.Exception.Message }
    Assert-True ($mismatchMessage -like 'review-engine-version-mismatch:*specrew update*') 'an unversioned mismatched engine cannot run silently'

    $deploySource = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1') -Raw
    Assert-True ($deploySource -match '\.specrew-runtime\.json') 'init/update writes the review runtime marker'
    Assert-True ($deploySource -match 'Get-SpecrewReviewRuntimeBundleSha256') 'the marker binds the deployed runtime bundle'
    Assert-True ($deploySource -match "\`$sourceVersion = 'unknown'") 'legacy update layouts can deploy without a colocated module manifest'
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'All review-engine resolution tests passed.' -ForegroundColor Green
