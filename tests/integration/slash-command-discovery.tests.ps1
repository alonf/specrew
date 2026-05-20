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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$skillsRoot = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\skills'
$commands = @(
    [pscustomobject]@{ Dir = 'specrew-where'; Command = '/specrew-where' }
    [pscustomobject]@{ Dir = 'specrew-status'; Command = '/specrew-status' }
    [pscustomobject]@{ Dir = 'specrew-update'; Command = '/specrew-update' }
    [pscustomobject]@{ Dir = 'specrew-team'; Command = '/specrew-team' }
    [pscustomobject]@{ Dir = 'specrew-review'; Command = '/specrew-review' }
    [pscustomobject]@{ Dir = 'specrew-help'; Command = '/specrew-help' }
    [pscustomobject]@{ Dir = 'specrew-version'; Command = '/specrew-version' }
)

Write-Host ''
Write-Host '=== Slash-Command Discovery Validation Tests ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

Write-Host '--- Test 1: each SKILL.md begins with YAML frontmatter ---'
foreach ($entry in $commands) {
    $path = Join-Path $skillsRoot "$($entry.Dir)\SKILL.md"
    $content = Get-Content -LiteralPath $path -Raw
    Assert-True -Condition ($content.StartsWith("---`n") -or $content.StartsWith("---`r`n")) -Message "$($entry.Dir) starts with YAML frontmatter"
    Assert-True -Condition ($content -match "(?m)^name:\s+$([regex]::Escape($entry.Dir))\r?$") -Message "$($entry.Dir) frontmatter name matches directory"
    Assert-True -Condition ($content -match '(?m)^description:\s+\S+') -Message "$($entry.Dir) frontmatter has non-empty description"
}

Write-Host ''
Write-Host '--- Test 2: each SKILL.md references its own hyphenated slash-command form ---'
foreach ($entry in $commands) {
    $content = Get-Content -LiteralPath (Join-Path $skillsRoot "$($entry.Dir)\SKILL.md") -Raw
    Assert-True -Condition ($content -like "*$($entry.Command)*") -Message "$($entry.Dir) references $($entry.Command)"
    Assert-True -Condition ($content -notmatch '`/specrew\.') -Message "$($entry.Dir) does not use deprecated dot-form slash commands"
}

Write-Host ''
Write-Host '--- Test 3: specrew-help catalogs all seven hyphenated commands ---'
$helpContent = Get-Content -LiteralPath (Join-Path $skillsRoot 'specrew-help\SKILL.md') -Raw
foreach ($entry in $commands) {
    Assert-True -Condition ($helpContent -like "*$($entry.Command)*") -Message "specrew-help catalogs $($entry.Command)"
}

Write-Host ''
Write-Host '--- Test 4: specrew-status documents alias parity with specrew-where ---'
$statusContent = Get-Content -LiteralPath (Join-Path $skillsRoot 'specrew-status\SKILL.md') -Raw
Assert-True -Condition ($statusContent -like '*/specrew-where*') -Message 'specrew-status references /specrew-where'
Assert-True -Condition ($statusContent -like '*alias*' -or $statusContent -like '*identical output*') -Message 'specrew-status documents alias parity'

Write-Host ''
Write-Host '--- Test 5: skills README documents the three active roots and the hyphenated catalog ---'
$readmeContent = Get-Content -LiteralPath (Join-Path $skillsRoot 'README.md') -Raw
Assert-True -Condition ($readmeContent -like '*.claude/skills*' -or $readmeContent -like '*.claude\skills*') -Message 'skills README mentions .claude/skills'
Assert-True -Condition ($readmeContent -like '*.github/skills*' -or $readmeContent -like '*.github\skills*') -Message 'skills README mentions .github/skills'
Assert-True -Condition ($readmeContent -like '*.agents/skills*' -or $readmeContent -like '*.agents\skills*') -Message 'skills README mentions .agents/skills'
Assert-True -Condition ($readmeContent -like '*/specrew-help*') -Message 'skills README documents /specrew-help'

Write-Host ''
Write-Host '--- Test 6: Feature 024 quickstart documents the hyphenated discovery form ---'
$quickstartContent = Get-Content -LiteralPath (Join-Path $repoRoot 'specs\024-slash-command-multi-host-correctness\quickstart.md') -Raw
Assert-True -Condition ($quickstartContent -like '*/specrew-help*') -Message 'Feature 024 quickstart references /specrew-help'
Assert-True -Condition ($quickstartContent -like '*.claude/skills*' -or $quickstartContent -like '*.claude\skills*') -Message 'Feature 024 quickstart documents .claude/skills'
Assert-True -Condition ($quickstartContent -like '*.agents/skills*' -or $quickstartContent -like '*.agents\skills*') -Message 'Feature 024 quickstart documents .agents/skills'

Write-Host ''
Write-Host '=== All discovery validation tests passed ===' -ForegroundColor Green
Write-Host ''
