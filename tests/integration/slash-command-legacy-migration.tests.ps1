[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { Write-Fail $Message; exit 1 }
    Write-Pass $Message
}

function New-ScratchProject {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Recurse -Force }
    $null = New-Item -ItemType Directory -Path (Join-Path $Path '.squad\casting') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $Path '.github\agents') -Force
    [System.IO.File]::WriteAllText((Join-Path $Path '.squad\team.md'), "# Squad Team`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $Path '.squad\ceremonies.md'), "# Ceremonies`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $Path '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
}

function New-LegacyManagedSkill {
    param([string]$Path, [string]$DirectoryName, [string]$LegacyCommand)
    $skillDir = Join-Path $Path ".copilot\skills\$DirectoryName"
    $null = New-Item -ItemType Directory -Path $skillDir -Force
    $content = @(
        "# $DirectoryName"
        ''
        '**Type**: Operational Skill'
        '**Schema**: v1'
        '**Status**: Active'
        ('**Namespace**: ' + [char]96 + '/specrew' + [char]96)
        ('**Canonical command**: ' + [char]96 + $LegacyCommand + [char]96)
        ''
    ) -join "`n"
    [System.IO.File]::WriteAllText((Join-Path $skillDir 'SKILL.md'), $content, [System.Text.UTF8Encoding]::new($false))
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$deployScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'
$scratchProject = Join-Path $repoRoot '.scratch\slash-command-legacy-migration'

Write-Host ''
Write-Host '=== Slash-Command Legacy Migration Tests ===' -ForegroundColor Cyan
Write-Host ''

try {
    New-ScratchProject -Path $scratchProject
    New-LegacyManagedSkill -Path $scratchProject -DirectoryName 'specrew-where' -LegacyCommand '/specrew.where'

    $unmanagedDir = Join-Path $scratchProject '.copilot\skills\specrew-custom'
    $null = New-Item -ItemType Directory -Path $unmanagedDir -Force
    [System.IO.File]::WriteAllText((Join-Path $unmanagedDir 'SKILL.md'), "# specrew-custom`nuser content`n", [System.Text.UTF8Encoding]::new($false))

    $otherDir = Join-Path $scratchProject '.copilot\skills\other-skill'
    $null = New-Item -ItemType Directory -Path $otherDir -Force
    [System.IO.File]::WriteAllText((Join-Path $otherDir 'SKILL.md'), "# other-skill`n", [System.Text.UTF8Encoding]::new($false))

    & $deployScript -ProjectPath $scratchProject | Out-Null

    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $scratchProject '.copilot\skills\specrew-where'))) -Message 'managed legacy specrew-where directory is removed'
    Assert-True -Condition (Test-Path -LiteralPath $unmanagedDir -PathType Container) -Message 'unmanaged specrew-custom directory is preserved'
    Assert-True -Condition (Test-Path -LiteralPath $otherDir -PathType Container) -Message 'non-specrew legacy content is preserved'
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $scratchProject '.claude\skills\specrew-where\SKILL.md') -PathType Leaf) -Message 'active replacement skill is deployed after migration'

    & $deployScript -ProjectPath $scratchProject | Out-Null
    Assert-True -Condition (Test-Path -LiteralPath $unmanagedDir -PathType Container) -Message 'idempotent rerun preserves unmanaged specrew-custom directory'
}
finally {
    if (Test-Path -LiteralPath $scratchProject) { Remove-Item -LiteralPath $scratchProject -Recurse -Force }
}

Write-Host ''
Write-Host '=== All legacy migration tests passed ===' -ForegroundColor Green
Write-Host ''
