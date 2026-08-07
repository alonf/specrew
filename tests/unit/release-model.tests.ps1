[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Invoke-TestGit {
    param([string]$RepoRoot, [string[]]$Arguments)
    $output = @(& git -C $RepoRoot @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return @($output | ForEach-Object { [string]$_ })
}

function New-ReleaseModelRepository {
    param([string]$Path, [AllowNull()][string]$RemoteUrl, [AllowNull()][string]$GovernanceContent)

    $null = New-Item -ItemType Directory -Path $Path -Force
    Invoke-TestGit -RepoRoot $Path -Arguments @('init', '--quiet') | Out-Null
    if (-not [string]::IsNullOrWhiteSpace($RemoteUrl)) {
        Invoke-TestGit -RepoRoot $Path -Arguments @('remote', 'add', 'origin', $RemoteUrl) | Out-Null
    }
    if (-not [string]::IsNullOrWhiteSpace($GovernanceContent)) {
        $governanceDirectory = Join-Path $Path '.specrew'
        $null = New-Item -ItemType Directory -Path $governanceDirectory -Force
        [System.IO.File]::WriteAllText(
            (Join-Path $governanceDirectory 'repository-governance.yml'),
            $GovernanceContent,
            [System.Text.UTF8Encoding]::new($false)
        )
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
. $sharedGovernancePath

$scratch = Join-Path $repoRoot '.scratch\release-model-tests'
if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
$null = New-Item -ItemType Directory -Path $scratch -Force

try {
    $localPath = Join-Path $scratch 'local-only'
    New-ReleaseModelRepository -Path $localPath
    $local = Resolve-SpecrewReleaseModel -ProjectRoot $localPath
    $localGuidance = Format-SpecrewFeatureCloseoutReleaseGuidance -ProjectRoot $localPath
    Assert-True ($local.Model -eq 'local-only' -and $local.Provenance -eq 'inferred' -and $local.Source -eq 'no-remote') 'No-remote repository resolves to inferred local-only'
    Assert-True ($localGuidance -match 'local-only' -and $localGuidance -match 'N/A:' -and $localGuidance -notmatch '(?i)registry|beta-before-stable|prerelease|stable promotion') 'Local-only closeout names N/A delivery without registry or staged-release teaching'

    $pushPath = Join-Path $scratch 'push-only'
    New-ReleaseModelRepository -Path $pushPath -RemoteUrl 'ssh://example.invalid/team/project.git'
    $push = Resolve-SpecrewReleaseModel -ProjectRoot $pushPath
    $pushGuidance = Format-SpecrewFeatureCloseoutReleaseGuidance -ProjectRoot $pushPath
    Assert-True ($push.Model -eq 'push-only' -and $push.Source -eq 'remote') 'Unrecognized remote without forge configuration resolves to push-only'
    Assert-True ($pushGuidance -match 'push the reviewed commit' -and $pushGuidance -match 'PR/MR review and release publication do not apply') 'Push-only closeout includes push and names inapplicable PR/release steps'

    $forgePath = Join-Path $scratch 'pr-flow'
    New-ReleaseModelRepository -Path $forgePath -RemoteUrl 'https://github.com/example/project.git'
    $forge = Resolve-SpecrewReleaseModel -ProjectRoot $forgePath
    $forgeGuidance = Format-SpecrewFeatureCloseoutReleaseGuidance -ProjectRoot $forgePath
    Assert-True ($forge.Model -eq 'pr-flow' -and $forge.Source -eq 'forge') 'Known forge remote resolves to PR flow'
    Assert-True ($forgeGuidance -match 'open the forge review' -and $forgeGuidance -match 'release publication.*do not apply') 'PR-flow closeout includes forge review and names publication N/A'

    $providerPath = Join-Path $scratch 'provider-pr-flow'
    New-ReleaseModelRepository -Path $providerPath -GovernanceContent "repository_governance:`n  provider: custom-forge`n"
    $provider = Resolve-SpecrewReleaseModel -ProjectRoot $providerPath
    Assert-True ($provider.Model -eq 'pr-flow' -and $provider.Source -eq 'forge') 'Recorded forge provider resolves to PR flow without assuming a named forge'

    $publishPath = Join-Path $scratch 'publish-target'
    New-ReleaseModelRepository -Path $publishPath -GovernanceContent "release_model: beta-stable`nrelease_model_provenance: recorded`npublish_target: 'Example Registry'`n"
    $publish = Resolve-SpecrewReleaseModel -ProjectRoot $publishPath
    $publishGuidance = Format-SpecrewFeatureCloseoutReleaseGuidance -ProjectRoot $publishPath
    Assert-True ($publish.Model -eq 'beta-stable' -and $publish.PublishTarget -eq 'Example Registry') 'Recorded publish target resolves to beta-stable'
    Assert-True ($publishGuidance -match 'Example Registry' -and $publishGuidance -match 'publish a prerelease' -and $publishGuidance -match 'publish stable only after PASS') 'Publish-target closeout renders the full prerelease-to-stable chain'

    $recordPath = Join-Path $scratch 'record-once'
    New-ReleaseModelRepository -Path $recordPath
    $firstRecord = Initialize-SpecrewReleaseModelRecord -ProjectRoot $recordPath
    $recordFile = Join-Path $recordPath '.specrew\repository-governance.yml'
    $firstContent = Get-Content -LiteralPath $recordFile -Raw -Encoding UTF8
    $secondRecord = Initialize-SpecrewReleaseModelRecord -ProjectRoot $recordPath -RequestedModel pr-flow
    $secondContent = Get-Content -LiteralPath $recordFile -Raw -Encoding UTF8
    Assert-True ($firstRecord.Action -eq 'recorded' -and $firstRecord.Record.Model -eq 'local-only' -and $firstRecord.Record.Provenance -eq 'inferred') 'Init records the inferred default when no explicit model is supplied'
    Assert-True ($secondRecord.Action -eq 'preserved' -and $firstContent -ceq $secondContent -and $secondRecord.Record.Model -eq 'local-only') 'Init records the release-model selection once and preserves it thereafter'

    $explicitPath = Join-Path $scratch 'explicit-publish'
    New-ReleaseModelRepository -Path $explicitPath
    $explicit = Initialize-SpecrewReleaseModelRecord -ProjectRoot $explicitPath -RequestedModel beta-stable -PublishTarget 'Example "Quoted" Registry'
    $explicitResolved = Resolve-SpecrewReleaseModel -ProjectRoot $explicitPath
    Assert-True ($explicit.Action -eq 'recorded' -and $explicitResolved.Model -eq 'beta-stable' -and $explicitResolved.PublishTarget -eq 'Example "Quoted" Registry') 'Explicit publish target is recorded as a beta-stable model with YAML-safe quoting'

    $missingTargetFailed = $false
    try { Resolve-SpecrewReleaseModel -ProjectRoot $localPath -RequestedModel beta-stable | Out-Null } catch { $missingTargetFailed = $_.Exception.Message -match 'requires -PublishTarget' }
    Assert-True $missingTargetFailed 'Explicit beta-stable selection without a publish target fails closed'

    $invalidPath = Join-Path $scratch 'invalid-record'
    New-ReleaseModelRepository -Path $invalidPath -GovernanceContent "release_model: surprise`nrelease_model_provenance: recorded`npublish_target: null`n"
    $invalidFailed = $false
    try { Resolve-SpecrewReleaseModel -ProjectRoot $invalidPath | Out-Null } catch { $invalidFailed = $_.Exception.Message -match 'Unsupported release_model' }
    Assert-True $invalidFailed 'Invalid recorded release model fails closed'

    $previewPath = Join-Path $scratch 'preview'
    New-ReleaseModelRepository -Path $previewPath
    $preview = Initialize-SpecrewReleaseModelRecord -ProjectRoot $previewPath -PreviewOnly
    Assert-True ($preview.Action -eq 'would-record' -and -not (Test-Path -LiteralPath (Join-Path $previewPath '.specrew\repository-governance.yml'))) 'Dry-run resolves but does not write a release-model record'

    $schemaPath = Join-Path $repoRoot 'extensions\specrew-speckit\knowledge\repository-governance.schema.json'
    $schema = Get-Content -LiteralPath $schemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($schema.properties.release_model.enum.Count -eq 4 -and $schema.properties.release_model_provenance.enum.Count -eq 2) 'Repository-governance schema publishes the closed model and provenance sets'
    $validPublishJson = '{"release_model":"beta-stable","release_model_provenance":"recorded","publish_target":"Example Registry"}'
    $invalidPublishJson = '{"release_model":"beta-stable","release_model_provenance":"recorded","publish_target":null}'
    Assert-True ($validPublishJson | Test-Json -SchemaFile $schemaPath) 'Schema accepts beta-stable with a non-empty publish target'
    Assert-True (-not ($invalidPublishJson | Test-Json -SchemaFile $schemaPath -ErrorAction SilentlyContinue)) 'Schema rejects beta-stable without a usable publish target'

    $initText = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\specrew-init.ps1') -Raw -Encoding UTF8
    $launchText = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\internal\launch-contract.ps1') -Raw -Encoding UTF8
    $lifecycleText = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\templates\lifecycle\software-feature-lifecycle.md') -Raw -Encoding UTF8
    Assert-True ($initText -match 'Initialize-SpecrewReleaseModelRecord' -and $initText -match '\-\-release-model' -and $initText -match '\-\-publish-target') 'Production init exposes and records the release-model selection'
    Assert-True ($launchText -match 'Format-SpecrewFeatureCloseoutReleaseGuidance' -and $launchText -match '## Resolved Feature-Closeout Delivery') 'Production launch contract renders the resolved closeout block'
    Assert-True ($lifecycleText -notmatch 'Produces a release:\s*yes' -and $lifecycleText -match 'release_model') 'Lifecycle teaching is release-model-aware instead of unconditionally release-producing'

    $mirrorPairs = @(
        @('scripts\shared-governance.ps1', 'scripts\shared-governance.ps1'),
        @('knowledge\repository-governance.schema.json', 'knowledge\repository-governance.schema.json'),
        @('templates\lifecycle\software-feature-lifecycle.md', 'templates\lifecycle\software-feature-lifecycle.md'),
        @('refocus\feature-closeout.md', 'refocus\feature-closeout.md'),
        @('prompts\coordinator-response.md', 'prompts\coordinator-response.md'),
        @('prompts\coordinator-decision-guidance.md', 'prompts\coordinator-decision-guidance.md'),
        @('squad-templates\coordinator\specrew-governance.md', 'squad-templates\coordinator\specrew-governance.md')
    )
    foreach ($pair in $mirrorPairs) {
        $sourcePath = Join-Path (Join-Path $repoRoot 'extensions\specrew-speckit') $pair[0]
        $deployedPath = Join-Path (Join-Path $repoRoot '.specify\extensions\specrew-speckit') $pair[1]
        Assert-True ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $deployedPath -Algorithm SHA256).Hash) "Release-model surface mirror is byte-identical: $($pair[0])"
    }
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
}

Write-Host 'All release-model resolver and closeout teaching tests passed.' -ForegroundColor Green
