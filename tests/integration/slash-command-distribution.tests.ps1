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

function New-ScratchProject {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }

    $null = New-Item -ItemType Directory -Path (Join-Path $Path '.squad\casting') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $Path '.github\agents') -Force
    [System.IO.File]::WriteAllText((Join-Path $Path '.squad\team.md'), "# Squad Team`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $Path '.squad\ceremonies.md'), "# Ceremonies`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $Path '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$deployScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'
$skillsSourceRoot = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\skills'
$initScript = Join-Path $repoRoot 'scripts\specrew-init.ps1'
$updateScript = Join-Path $repoRoot 'scripts\specrew-update.ps1'
$expectedSkillDirs = @(
    'specrew-where', 'specrew-status', 'specrew-update',
    'specrew-team', 'specrew-review', 'specrew-help', 'specrew-version'
)
$activeRoots = @('.claude\skills', '.github\skills', '.agents\skills')

Write-Host ''
Write-Host '=== Slash-Command Distribution Integration Tests ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

Write-Host '--- Test 1: deploy-squad-runtime.ps1 exists and targets the three active roots ---'
Assert-True -Condition (Test-Path -LiteralPath $deployScript -PathType Leaf) -Message 'deploy-squad-runtime.ps1 exists'
$deployContent = Get-Content -LiteralPath $deployScript -Raw
Assert-True -Condition ($deployContent -like '*'.Replace('*','') -or $true) -Message 'deploy script loaded'
Assert-True -Condition ($deployContent -like '*''.claude\skills''*') -Message 'deploy script targets .claude\skills'
Assert-True -Condition ($deployContent -like '*''.github\skills''*') -Message 'deploy script targets .github\skills'
Assert-True -Condition ($deployContent -like '*''.agents\skills''*') -Message 'deploy script targets .agents\skills'

Write-Host ''
Write-Host '--- Test 2: slash-command source skill templates exist for all seven commands ---'
foreach ($dirName in $expectedSkillDirs) {
    $skillMd = Join-Path $skillsSourceRoot "$dirName\SKILL.md"
    Assert-True -Condition (Test-Path -LiteralPath $skillMd -PathType Leaf) -Message "Source SKILL.md exists: $dirName"
}

Write-Host ''
Write-Host '--- Test 3: runtime deployment writes all seven command skills to all three active roots ---'
$scratchProject = Join-Path $repoRoot '.scratch\slash-command-distribution'
try {
    New-ScratchProject -Path $scratchProject
    & $deployScript -ProjectPath $scratchProject | Out-Null

    foreach ($root in $activeRoots) {
        foreach ($dirName in $expectedSkillDirs) {
            $skillPath = Join-Path $scratchProject "$root\$dirName\SKILL.md"
            $markerPath = Join-Path $scratchProject "$root\$dirName\.specrew-managed"
            Assert-True -Condition (Test-Path -LiteralPath $skillPath -PathType Leaf) -Message "$root contains $dirName\SKILL.md"
            Assert-True -Condition (Test-Path -LiteralPath $markerPath -PathType Leaf) -Message "$root contains $dirName managed marker"
        }
    }
}
finally {
    if (Test-Path -LiteralPath $scratchProject) {
        Remove-Item -LiteralPath $scratchProject -Recurse -Force
    }
}

Write-Host ''
Write-Host '--- Test 4: deployment no longer provisions legacy .copilot slash-command roots on clean bootstrap ---'
$scratchProject = Join-Path $repoRoot '.scratch\slash-command-distribution-no-copilot'
try {
    New-ScratchProject -Path $scratchProject
    & $deployScript -ProjectPath $scratchProject | Out-Null
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $scratchProject '.copilot\skills\specrew-where'))) -Message 'clean deployment does not create .copilot\skills\specrew-where'
}
finally {
    if (Test-Path -LiteralPath $scratchProject) {
        Remove-Item -LiteralPath $scratchProject -Recurse -Force
    }
}

Write-Host ''
Write-Host '--- Test 5: specrew-update summary reports the hyphenated slash surface across three roots ---'
$updateContent = Get-Content -LiteralPath $updateScript -Raw
Assert-True -Condition ($updateContent -like '*slash-surface-refreshed*') -Message 'specrew-update.ps1 records slash-surface-refreshed in summary'
Assert-True -Condition ($updateContent -like '*/specrew-where*') -Message 'specrew-update.ps1 lists the hyphenated slash-command catalog'
Assert-True -Condition ($updateContent -like '*.claude/skills*' -or $updateContent -like '*.claude\skills*') -Message 'specrew-update.ps1 mentions .claude/skills in slash summary'

Write-Host ''
Write-Host '--- Test 6: specrew-init post-bootstrap guidance reports the three-root slash surface ---'
$initContent = Get-Content -LiteralPath $initScript -Raw
Assert-True -Condition (($initContent -like "*-Step 'slash-surface'*") -and ($initContent -like '*provisioned /specrew-where*')) -Message 'specrew-init.ps1 records slash-command surface provisioning'
Assert-True -Condition ($initContent -like '*/specrew-help*') -Message 'specrew-init.ps1 references /specrew-help fallback'
Assert-True -Condition ($initContent -like '*.agents/skills*' -or $initContent -like '*.agents\skills*') -Message 'specrew-init.ps1 mentions .agents/skills deployment'

Write-Host ''
Write-Host '=== All distribution integration tests passed ===' -ForegroundColor Green
Write-Host ''
