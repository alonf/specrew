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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$deployScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'
$scratchProject = Join-Path $repoRoot '.scratch\slash-command-frontmatter'
$commands = @('specrew-where', 'specrew-status', 'specrew-update', 'specrew-team', 'specrew-review', 'specrew-help', 'specrew-version')

Write-Host ''
Write-Host '=== Slash-Command Frontmatter Validation Tests ===' -ForegroundColor Cyan
Write-Host ''

try {
    New-ScratchProject -Path $scratchProject
    & $deployScript -ProjectPath $scratchProject | Out-Null

    foreach ($command in $commands) {
        $skillPath = Join-Path $scratchProject ".github\skills\$command\SKILL.md"
        $content = Get-Content -LiteralPath $skillPath -Raw
        Assert-True -Condition ($content -match '^---\r?\nname:\s+' + [regex]::Escape($command) + '\r?\ndescription:\s+.+\r?\n---') -Message "$command has valid YAML frontmatter block"
        Assert-True -Condition ($content -match '(?m)^description:\s+\S+') -Message "$command description is non-empty"
    }
}
finally {
    if (Test-Path -LiteralPath $scratchProject) { Remove-Item -LiteralPath $scratchProject -Recurse -Force }
}

Write-Host ''
Write-Host '=== All frontmatter validation tests passed ===' -ForegroundColor Green
Write-Host ''
