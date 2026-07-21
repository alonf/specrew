[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Copy-Surface {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Missing required source path '$SourcePath'."
    }

    $item = Get-Item -LiteralPath $SourcePath
    if ($item.PSIsContainer) {
        Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Recurse -Force
        return
    }

    $parent = Split-Path -Parent $DestinationPath
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }

    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
}

function Set-ExtensionVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleRoot,

        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $manifestPath = Join-Path $ModuleRoot 'extensions\specrew-speckit\extension.yml'
    $content = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8
    $updated = [regex]::Replace($content, '(?m)^(\s*version:\s*)"?(?<value>[^"\r\n]+)"?$', ('$1"{0}"' -f $Version))
    [System.IO.File]::WriteAllText($manifestPath, $updated, [System.Text.UTF8Encoding]::new($false))
}

function Install-TemplateSurface {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,

        [Parameter(Mandatory = $true)]
        [string]$TargetRoot
    )

    if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
        throw "Missing template source root '$SourceRoot'."
    }

    $files = @(Get-ChildItem -LiteralPath $SourceRoot -File -Recurse)
    foreach ($file in $files) {
        $relativePath = [System.IO.Path]::GetRelativePath($SourceRoot, $file.FullName)
        $destinationPath = Join-Path $TargetRoot $relativePath
        $parent = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $parent)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }

        Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force
    }
}

function Invoke-ModuleScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleRoot,

        [Parameter(Mandatory = $true)]
        [string]$ScriptRelativePath,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $scriptPath = Join-Path $ModuleRoot $ScriptRelativePath
    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = @($output | ForEach-Object { [string]$_ })
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$scratchRoot = Join-Path $repoRoot '.scratch\distribution-module-update'
$previousVersion = '0.17.9'
$currentVersion = '0.18.0'
$moduleParentRoot = Join-Path $scratchRoot 'module'
$previousModuleRoot = Join-Path $moduleParentRoot $previousVersion
$currentModuleRoot = Join-Path $moduleParentRoot $currentVersion
$projectRoot = Join-Path $scratchRoot 'project'
$sourceSnapshotRoot = Join-Path $scratchRoot 'source-snapshot'
$sourceArchivePath = Join-Path $scratchRoot 'source-snapshot.tar'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -ItemType Directory -Path $previousModuleRoot -Force
$null = New-Item -ItemType Directory -Path $currentModuleRoot -Force
$null = New-Item -ItemType Directory -Path $projectRoot -Force
$null = New-Item -ItemType Directory -Path $sourceSnapshotRoot -Force

# Use one immutable Git snapshot for both simulated module versions. Copying each top-level surface directly
# from the live checkout created an observed Test-Path/Get-Item race in the isolated honesty lane. `stash create`
# captures tracked working-tree edits without changing the index or worktree, so local pre-commit runs still test
# the developer's candidate while clean CI naturally falls back to HEAD.
[string]$sourceSnapshotRef = (& git -C $repoRoot -c user.name='Specrew Test' -c user.email='specrew-test@local' stash create 'distribution-module-update source snapshot' 2>$null | Select-Object -Last 1)
if ($LASTEXITCODE -ne 0) { throw 'Failed to resolve the immutable distribution source snapshot.' }
$sourceSnapshotRef = $sourceSnapshotRef.Trim()
if ([string]::IsNullOrWhiteSpace($sourceSnapshotRef)) { $sourceSnapshotRef = 'HEAD' }
& git -C $repoRoot archive --format=tar --output=$sourceArchivePath $sourceSnapshotRef
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $sourceArchivePath -PathType Leaf)) {
    throw 'Failed to create the immutable distribution source snapshot.'
}
& tar -xf $sourceArchivePath -C $sourceSnapshotRoot
if ($LASTEXITCODE -ne 0) { throw 'Failed to extract the immutable distribution source snapshot.' }
Remove-Item -LiteralPath $sourceArchivePath -Force

foreach ($moduleRoot in @($previousModuleRoot, $currentModuleRoot)) {
    foreach ($surface in @('scripts', 'extensions', '.specify', '.squad', '.github', 'templates', 'hosts')) {
        Copy-Surface -SourcePath (Join-Path $sourceSnapshotRoot $surface) -DestinationPath (Join-Path $moduleRoot $surface)
    }
    $contractsTargetParent = Join-Path $moduleRoot 'specs\197-continuous-co-review'
    $null = New-Item -ItemType Directory -Path $contractsTargetParent -Force
    Copy-Surface `
        -SourcePath (Join-Path $sourceSnapshotRoot 'specs\197-continuous-co-review\contracts') `
        -DestinationPath (Join-Path $contractsTargetParent 'contracts')
}

Set-ExtensionVersion -ModuleRoot $previousModuleRoot -Version $previousVersion
Set-ExtensionVersion -ModuleRoot $currentModuleRoot -Version $currentVersion

$moduleOnlyPath = Join-Path $currentModuleRoot 'templates\specify\templates\spec-template.md'
[System.IO.File]::WriteAllText($moduleOnlyPath, "CURRENT MODULE-ONLY TEMPLATE`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $previousModuleRoot 'templates\specify\templates\spec-template.md'), "PREVIOUS MODULE-ONLY TEMPLATE`n", [System.Text.UTF8Encoding]::new($false))

$userOnlyProjectRelativePath = '.specify\templates\plan-template.md'
$bothModifiedProjectRelativePath = '.squad\identity\now.md'

$bothModifiedPreviousSourcePath = Join-Path $previousModuleRoot 'templates\squad\identity\now.md'
$bothModifiedCurrentSourcePath = Join-Path $currentModuleRoot 'templates\squad\identity\now.md'
[System.IO.File]::WriteAllText($bothModifiedPreviousSourcePath, "PREVIOUS SHARED TEMPLATE`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($bothModifiedCurrentSourcePath, "CURRENT MODULE TEMPLATE`n", [System.Text.UTF8Encoding]::new($false))

$newTemplateCurrentSourcePath = Join-Path $currentModuleRoot 'templates\github\workflows\new-template.yml'
[System.IO.File]::WriteAllText($newTemplateCurrentSourcePath, "name: new-template`n", [System.Text.UTF8Encoding]::new($false))

$deletedTemplatePreviousSourcePath = Join-Path $previousModuleRoot 'templates\github\workflows\obsolete-template.yml'
[System.IO.File]::WriteAllText($deletedTemplatePreviousSourcePath, "name: obsolete-template`n", [System.Text.UTF8Encoding]::new($false))

$modifiedDeletedTemplatePreviousSourcePath = Join-Path $previousModuleRoot 'templates\github\workflows\modified-obsolete-template.yml'
[System.IO.File]::WriteAllText($modifiedDeletedTemplatePreviousSourcePath, "name: modified-obsolete-template`n", [System.Text.UTF8Encoding]::new($false))

Install-TemplateSurface -SourceRoot (Join-Path $previousModuleRoot 'templates\specify\templates') -TargetRoot (Join-Path $projectRoot '.specify\templates')
Install-TemplateSurface -SourceRoot (Join-Path $previousModuleRoot 'templates\squad') -TargetRoot (Join-Path $projectRoot '.squad')
Install-TemplateSurface -SourceRoot (Join-Path $previousModuleRoot 'templates\github\workflows') -TargetRoot (Join-Path $projectRoot '.github\workflows')
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot '.github\agents') -Force
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))

$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\config.yml'), @"
specrew_version: "$previousVersion"
speckit_version: "0.8.11"
squad_version: "0.9.4"
"@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))

$userOnlyTargetPath = Join-Path $projectRoot $userOnlyProjectRelativePath
[System.IO.File]::WriteAllText($userOnlyTargetPath, "USER CUSTOM PLAN TEMPLATE`n", [System.Text.UTF8Encoding]::new($false))

$bothModifiedTargetPath = Join-Path $projectRoot $bothModifiedProjectRelativePath
[System.IO.File]::WriteAllText($bothModifiedTargetPath, "USER CUSTOM IDENTITY TEMPLATE`n", [System.Text.UTF8Encoding]::new($false))

$modifiedDeletedTargetPath = Join-Path $projectRoot '.github\workflows\modified-obsolete-template.yml'
[System.IO.File]::WriteAllText($modifiedDeletedTargetPath, "name: user-modified-retired-template`n", [System.Text.UTF8Encoding]::new($false))

$consumerRefocusCatalogPath = Join-Path $projectRoot '.specify\extensions\specrew-speckit\refocus-scopes.json'
Remove-Item -LiteralPath $consumerRefocusCatalogPath -Force -ErrorAction SilentlyContinue

$consumerGuidancePath = Join-Path $projectRoot 'docs\user-guidance.md'
$null = New-Item -ItemType Directory -Path (Split-Path -Parent $consumerGuidancePath) -Force
[System.IO.File]::WriteAllText($consumerGuidancePath, "The project must run pytest before handoff.`n", [System.Text.UTF8Encoding]::new($false))
$consumerGuidanceBeforeHash = (Get-FileHash -LiteralPath $consumerGuidancePath -Algorithm SHA256).Hash

$updateResult = Invoke-ModuleScript `
    -ModuleRoot $currentModuleRoot `
    -ScriptRelativePath 'scripts\specrew-update.ps1' `
    -Arguments @('-ProjectPath', $projectRoot, '--specrew')

if ($updateResult.ExitCode -ne 0) {
    Write-Fail ("specrew update failed with exit code {0}. Output:`n{1}" -f $updateResult.ExitCode, ($updateResult.Output -join [Environment]::NewLine))
    exit 1
}

$moduleOnlyTargetPath = Join-Path $projectRoot '.specify\templates\spec-template.md'
$moduleOnlyContent = Get-Content -LiteralPath $moduleOnlyTargetPath -Raw -Encoding UTF8
if ($moduleOnlyContent -ne "CURRENT MODULE-ONLY TEMPLATE`n") {
    Write-Fail 'Module-only template did not refresh to the new module content.'
    exit 1
}
Write-Pass 'Module-only template changes refresh in place.'

$userOnlyContent = Get-Content -LiteralPath $userOnlyTargetPath -Raw -Encoding UTF8
if ($userOnlyContent -ne "USER CUSTOM PLAN TEMPLATE`n") {
    Write-Fail 'User-only template changes were not preserved.'
    exit 1
}
Write-Pass 'User-only template changes are preserved.'

$conflictedContent = Get-Content -LiteralPath $bothModifiedTargetPath -Raw -Encoding UTF8
foreach ($pattern in @(
        '<<<<<<< user-version \(preserved at: ',
        'USER CUSTOM IDENTITY TEMPLATE',
        '=======',
        'CURRENT MODULE TEMPLATE',
        '>>>>>>> module-version \(specrew_version: 0\.18\.0, source: templates/squad/identity/now\.md\)'
    )) {
    if ($conflictedContent -notmatch $pattern) {
        Write-Fail ("Conflict markers missing expected content '{0}'." -f $pattern)
        exit 1
    }
}
Write-Pass 'Both-modified templates are preserved with Git-style conflict markers.'

$artifactRoot = Join-Path $projectRoot '.specrew\template-conflicts'
$conflictArtifact = Get-ChildItem -LiteralPath $artifactRoot -Filter '*.conflict' -File | Select-Object -First 1
if ($null -eq $conflictArtifact) {
    Write-Fail 'Expected a .conflict artifact for the both-modified template.'
    exit 1
}

$artifactContent = Get-Content -LiteralPath $conflictArtifact.FullName -Raw -Encoding UTF8
if ($artifactContent -ne $conflictedContent) {
    Write-Fail '.conflict artifact content did not match the preserved target file.'
    exit 1
}
Write-Pass 'Conflict artifacts are generated alongside preserved conflicted files.'

$newTemplateTargetPath = Join-Path $projectRoot '.github\workflows\new-template.yml'
if (-not (Test-Path -LiteralPath $newTemplateTargetPath -PathType Leaf)) {
    Write-Fail 'New template addition was not copied into the project.'
    exit 1
}
Write-Pass 'New templates are added non-destructively.'

$cleanDeletedTargetPath = Join-Path $projectRoot '.github\workflows\obsolete-template.yml'
if (Test-Path -LiteralPath $cleanDeletedTargetPath) {
    Write-Fail 'Byte-identical retired template was preserved instead of removed.'
    exit 1
}
Write-Pass 'Byte-identical retired templates are removed by exact SHA-256 match.'

if (-not (Test-Path -LiteralPath $modifiedDeletedTargetPath -PathType Leaf)) {
    Write-Fail 'User-modified retired template was removed.'
    exit 1
}
$modifiedDeletedContent = Get-Content -LiteralPath $modifiedDeletedTargetPath -Raw -Encoding UTF8
if ($modifiedDeletedContent -ne "name: user-modified-retired-template`n") {
    Write-Fail 'User-modified retired template content was changed.'
    exit 1
}

$deletionArtifact = Get-ChildItem -LiteralPath $artifactRoot -Filter '*.deletion' -File | Where-Object {
    (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) -match 'modified-obsolete-template\.yml'
} | Select-Object -First 1
if ($null -eq $deletionArtifact) {
    Write-Fail 'Expected a .deletion artifact for the user-modified retired template.'
    exit 1
}

$deletionContent = Get-Content -LiteralPath $deletionArtifact.FullName -Raw -Encoding UTF8
if ($deletionContent -notmatch 'modified-obsolete-template\.yml' -or $deletionContent -notmatch 'pending-manual-review') {
    Write-Fail '.deletion artifact did not capture the expected removal metadata.'
    exit 1
}
$cleanDeletionArtifacts = @(Get-ChildItem -LiteralPath $artifactRoot -Filter '*.deletion' -File | Where-Object {
        (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) -match '(?<!modified-)obsolete-template\.yml'
    })
if ($cleanDeletionArtifacts.Count -ne 0) {
    Write-Fail 'Byte-identical retired template incorrectly produced a manual-review artifact.'
    exit 1
}
if (($updateResult.Output -join "`n") -notmatch 'WARNING:.*modified-obsolete-template\.yml.*preserv') {
    Write-Fail 'Update did not emit an explicit WARN naming the preserved retired template.'
    exit 1
}
Write-Pass 'User-modified retired templates are preserved with an explicit WARN and review artifact.'

$sourceRefocusCatalogPath = Join-Path $currentModuleRoot 'extensions\specrew-speckit\refocus-scopes.json'
if (-not (Test-Path -LiteralPath $consumerRefocusCatalogPath -PathType Leaf)) {
    Write-Fail 'Update did not sync refocus-scopes.json into the existing .specify tree.'
    exit 1
}
if ((Get-FileHash -LiteralPath $consumerRefocusCatalogPath -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $sourceRefocusCatalogPath -Algorithm SHA256).Hash) {
    Write-Fail 'Synced refocus-scopes.json does not match the current module source.'
    exit 1
}
Write-Pass 'Existing .specify trees receive the current refocus-scopes.json catalog.'

$consumerCheckerPath = Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts\test-consumer-assumptions.ps1'
if (-not (Test-Path -LiteralPath $consumerCheckerPath -PathType Leaf)) {
    Write-Fail 'Update did not deploy the consumer-assumption checker.'
    exit 1
}
$updateOutput = $updateResult.Output -join "`n"
if ($updateOutput -notmatch 'consumer-assumption-advisory' -or $updateOutput -notmatch 'Consumer assumption: docs/user-guidance.md:1') {
    Write-Fail 'Update did not execute and surface the consumer-assumption advisory after refresh.'
    exit 1
}
if ((Get-FileHash -LiteralPath $consumerGuidancePath -Algorithm SHA256).Hash -ne $consumerGuidanceBeforeHash) {
    Write-Fail 'Update consumer advisory rewrote the user-authored guidance file.'
    exit 1
}
Write-Pass 'Update executes the shipped advisory after managed refresh and preserves flagged user-authored files.'

$updatedConfig = Get-Content -LiteralPath (Join-Path $projectRoot '.specrew\config.yml') -Raw -Encoding UTF8
if ($updatedConfig -notmatch 'specrew_version:\s*"0\.18\.0"') {
    Write-Fail 'specrew update did not record the new Specrew version in config.yml.'
    exit 1
}
Write-Pass 'Project config records the refreshed Specrew version.'

$startResult = Invoke-ModuleScript `
    -ModuleRoot $currentModuleRoot `
    -ScriptRelativePath 'scripts\specrew-start.ps1' `
    -Arguments @('-ProjectPath', $projectRoot, '-NoLaunch', 'Review template conflicts')

if ($startResult.ExitCode -ne 0) {
    Write-Fail ("specrew start --no-launch failed with exit code {0}. Output:`n{1}" -f $startResult.ExitCode, ($startResult.Output -join [Environment]::NewLine))
    exit 1
}

$promptPath = Join-Path $projectRoot '.specrew\last-start-prompt.md'
$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
foreach ($pattern in @(
        '## ACTION REQUIRED: Unresolved Template Refresh Artifacts',
        '\.specrew\\template-conflicts\\',
        '\.conflict',
        '\.deletion',
        'accept-new',
        'manual-resolve'
    )) {
    if ($promptContent -notmatch $pattern) {
        Write-Fail ("specrew start prompt did not surface expected template-refresh guidance '{0}'." -f $pattern)
        exit 1
    }
}
Write-Pass 'specrew start surfaces unresolved template-refresh artifacts in the resume prompt.'

Write-Host ''
Write-Host 'Distribution module update tests passed.' -ForegroundColor Green
exit 0
