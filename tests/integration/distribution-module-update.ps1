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

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -ItemType Directory -Path $previousModuleRoot -Force
$null = New-Item -ItemType Directory -Path $currentModuleRoot -Force
$null = New-Item -ItemType Directory -Path $projectRoot -Force

foreach ($moduleRoot in @($previousModuleRoot, $currentModuleRoot)) {
    foreach ($surface in @('scripts', 'extensions', '.specify', '.squad', '.github')) {
        Copy-Surface -SourcePath (Join-Path $repoRoot $surface) -DestinationPath (Join-Path $moduleRoot $surface)
    }
}

Set-ExtensionVersion -ModuleRoot $previousModuleRoot -Version $previousVersion
Set-ExtensionVersion -ModuleRoot $currentModuleRoot -Version $currentVersion

$moduleOnlyPath = Join-Path $currentModuleRoot '.specify\templates\spec-template.md'
[System.IO.File]::WriteAllText($moduleOnlyPath, "CURRENT MODULE-ONLY TEMPLATE`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $previousModuleRoot '.specify\templates\spec-template.md'), "PREVIOUS MODULE-ONLY TEMPLATE`n", [System.Text.UTF8Encoding]::new($false))

$userOnlyProjectRelativePath = '.specify\templates\plan-template.md'
$bothModifiedProjectRelativePath = '.squad\identity\now.md'

$bothModifiedPreviousSourcePath = Join-Path $previousModuleRoot '.squad\templates\identity\now.md'
$bothModifiedCurrentSourcePath = Join-Path $currentModuleRoot '.squad\templates\identity\now.md'
[System.IO.File]::WriteAllText($bothModifiedPreviousSourcePath, "PREVIOUS SHARED TEMPLATE`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($bothModifiedCurrentSourcePath, "CURRENT MODULE TEMPLATE`n", [System.Text.UTF8Encoding]::new($false))

$newTemplateCurrentSourcePath = Join-Path $currentModuleRoot '.github\workflows\new-template.yml'
[System.IO.File]::WriteAllText($newTemplateCurrentSourcePath, "name: new-template`n", [System.Text.UTF8Encoding]::new($false))

$deletedTemplatePreviousSourcePath = Join-Path $previousModuleRoot '.github\workflows\obsolete-template.yml'
[System.IO.File]::WriteAllText($deletedTemplatePreviousSourcePath, "name: obsolete-template`n", [System.Text.UTF8Encoding]::new($false))

Install-TemplateSurface -SourceRoot (Join-Path $previousModuleRoot '.specify\templates') -TargetRoot (Join-Path $projectRoot '.specify\templates')
Install-TemplateSurface -SourceRoot (Join-Path $previousModuleRoot '.squad\templates') -TargetRoot (Join-Path $projectRoot '.squad')
Install-TemplateSurface -SourceRoot (Join-Path $previousModuleRoot '.github\workflows') -TargetRoot (Join-Path $projectRoot '.github\workflows')
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
        '>>>>>>> module-version \(specrew_version: 0\.18\.0, source: \.squad/templates/identity/now\.md\)'
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

$deletionArtifact = Get-ChildItem -LiteralPath $artifactRoot -Filter '*.deletion' -File | Select-Object -First 1
if ($null -eq $deletionArtifact) {
    Write-Fail 'Expected a .deletion artifact for removed templates.'
    exit 1
}

$deletionContent = Get-Content -LiteralPath $deletionArtifact.FullName -Raw -Encoding UTF8
if ($deletionContent -notmatch 'obsolete-template\.yml' -or $deletionContent -notmatch 'pending-manual-review') {
    Write-Fail '.deletion artifact did not capture the expected removal metadata.'
    exit 1
}
Write-Pass 'Template deletions are flagged for manual review.'

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
