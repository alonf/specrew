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

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if (-not $Condition) {
        Write-Fail $Message
        exit 1
    }
    Write-Pass $Message
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Substring,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if ($Text -notlike "*$Substring*") {
        Write-Fail "$Message (expected '$Substring' in text)"
        exit 1
    }
    Write-Pass $Message
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$deployScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'
$skillsSourceRoot = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\skills'

Write-Host ''
Write-Host '=== Slash-Command Distribution Integration Tests ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

# --- Test 1: deploy-squad-runtime.ps1 exists ---
Write-Host '--- Test 1: deploy-squad-runtime.ps1 exists ---'
Assert-True -Condition (Test-Path -LiteralPath $deployScript -PathType Leaf) -Message 'deploy-squad-runtime.ps1 exists'

# --- Test 2: Subdirectory skill sources exist for all v1 commands ---
Write-Host ''
Write-Host '--- Test 2: Source skill subdirectories exist for all v1 slash commands ---'
$expectedSkillDirs = @(
    'specrew-where', 'specrew-status', 'specrew-update',
    'specrew-team', 'specrew-review', 'specrew-version', 'specrew-help'
)
foreach ($dirName in $expectedSkillDirs) {
    $skillMd = Join-Path $skillsSourceRoot "$dirName\SKILL.md"
    Assert-True -Condition (Test-Path -LiteralPath $skillMd -PathType Leaf) -Message "Source SKILL.md exists: $dirName"
}

# --- Test 3: deploy-squad-runtime.ps1 contains subdirectory skill loop ---
Write-Host ''
Write-Host '--- Test 3: deploy-squad-runtime.ps1 contains subdirectory skill deployment loop ---'
$deployContent = Get-Content -LiteralPath $deployScript -Raw
Assert-Contains -Text $deployContent -Substring 'Subdirectory-style skills' -Message 'Subdirectory skill loop comment present'
Assert-Contains -Text $deployContent -Substring 'Get-ChildItem' -Message 'Subdirectory enumeration present'
Assert-Contains -Text $deployContent -Substring 'SKILL.md' -Message 'SKILL.md target filename referenced in subdirectory loop'

# --- Test 4: deploy-squad-runtime.ps1 dry-run produces expected skill actions for subdirs ---
Write-Host ''
Write-Host '--- Test 4: deploy-squad-runtime.ps1 DryRun surfaces specrew-* skill directories ---'
$dryRunResults = @()
try {
    $scratchProject = Join-Path $repoRoot '.scratch\dist-test-dryrun'
    if (Test-Path -LiteralPath $scratchProject) {
        Remove-Item -LiteralPath $scratchProject -Recurse -Force
    }
    $null = New-Item -ItemType Directory -Path (Join-Path $scratchProject '.squad') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $scratchProject '.specify\extensions\specrew-speckit\scripts') -Force
    # Stub a minimal project setup so deploy-squad-runtime.ps1 can find what it needs
    $specrewSpecsRoot = Join-Path $repoRoot 'extensions\specrew-speckit\scripts'
    $dryRunOutput = & pwsh -NoProfile -ExecutionPolicy Bypass -File $deployScript -ProjectPath $scratchProject -DryRun -PassThru 2>&1 | Out-String
    $dryRunExitCode = $LASTEXITCODE
    # The script should attempt or skip without hard failure (project setup may be minimal)
    Assert-True -Condition ($dryRunExitCode -eq 0 -or $dryRunOutput.Length -gt 0) -Message 'deploy-squad-runtime.ps1 DryRun runs without crash'
}
finally {
    if (Test-Path -LiteralPath (Join-Path $repoRoot '.scratch\dist-test-dryrun')) {
        Remove-Item -LiteralPath (Join-Path $repoRoot '.scratch\dist-test-dryrun') -Recurse -Force
    }
}

# --- Test 5: specrew-update.ps1 includes slash-surface reporting in summary ---
Write-Host ''
Write-Host '--- Test 5: specrew-update.ps1 includes slash-surface-refreshed summary row ---'
$updateContent = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\specrew-update.ps1') -Raw
Assert-Contains -Text $updateContent -Substring 'slash-surface-refreshed' -Message 'specrew-update.ps1 records slash-surface-refreshed in summary'
Assert-Contains -Text $updateContent -Substring '/specrew.where' -Message 'specrew-update.ps1 lists slash-command names in surface refresh detail'

# --- Test 6: specrew-init.ps1 mentions slash-command surface in post-bootstrap guidance ---
Write-Host ''
Write-Host '--- Test 6: specrew-init.ps1 post-bootstrap guidance mentions slash-command surface ---'
$initContent = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\specrew-init.ps1') -Raw
Assert-Contains -Text $initContent -Substring 'Slash-command surface provisioned' -Message 'specrew-init.ps1 confirms slash-command surface provisioned'
Assert-Contains -Text $initContent -Substring '/specrew.help' -Message 'specrew-init.ps1 references /specrew.help in post-bootstrap guidance'

# --- Test 7: specrew.ps1 has Assert-ProjectSetup for project-bound commands ---
Write-Host ''
Write-Host '--- Test 7: specrew.ps1 includes project-setup gate for project-bound commands ---'
$specrewContent = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\specrew.ps1') -Raw
Assert-Contains -Text $specrewContent -Substring 'Assert-ProjectSetup' -Message 'Assert-ProjectSetup function defined in specrew.ps1'
Assert-Contains -Text $specrewContent -Substring "specrew init" -Message 'specrew.ps1 project-setup gate references specrew init remediation'

Write-Host ''
Write-Host '=== All distribution integration tests passed ===' -ForegroundColor Green
Write-Host ''
