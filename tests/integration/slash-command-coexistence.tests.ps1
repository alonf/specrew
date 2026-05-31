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

Write-Host ''
Write-Host '=== Slash-Command Namespace Coexistence Tests ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

Write-Host '--- Test 1: all skill subdirectory names use the specrew- prefix ---'
$subdirSkillNames = @(Get-ChildItem -LiteralPath $skillsRoot -Directory | Select-Object -ExpandProperty Name)
foreach ($dirName in $subdirSkillNames) {
    Assert-True -Condition $dirName.StartsWith('specrew-') -Message "Skill subdirectory '$dirName' carries specrew- prefix"
}

Write-Host ''
Write-Host '--- Test 2: specrew-review retains explicit boundary-safety wording ---'
$reviewSkillContent = Get-Content -LiteralPath (Join-Path $skillsRoot 'specrew-review\SKILL.md') -Raw
Assert-True -Condition ($reviewSkillContent -like '*does **not** bypass*' -or $reviewSkillContent -like '*human reviewer*') -Message 'specrew-review keeps boundary-safety wording'
Assert-True -Condition ($reviewSkillContent -notlike '*authorizes the boundary*') -Message 'specrew-review does not imply lifecycle approval'

Write-Host ''
Write-Host '--- Test 3: specrew-team retains coexistence-safe wording ---'
$teamSkillContent = Get-Content -LiteralPath (Join-Path $skillsRoot 'specrew-team\SKILL.md') -Raw
Assert-True -Condition ($teamSkillContent -like '*/speckit.*' -or $teamSkillContent -like '*does not collide*') -Message 'specrew-team documents coexistence with /speckit.*'

Write-Host ''
Write-Host '--- Test 4: dispatcher still contains whitelist enforcement for where/status/review/update/version ---'
$specrewContent = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\specrew.ps1') -Raw
foreach ($commandName in @('where', 'status', 'update', 'review', 'version')) {
    Assert-True -Condition ($specrewContent -like "*Assert-WhitelistedArguments -CommandName '$commandName'*") -Message "$commandName whitelist enforcement present"
}

Write-Host ''
Write-Host '--- Test 5: active runtime surfaces publish hyphenated commands only ---'
Assert-True -Condition ($specrewContent -notmatch '/specrew\.') -Message 'dispatcher help no longer publishes dot-form slash commands'

Write-Host ''
Write-Host '--- Test 6 (F-054 US2): before-implement surface surfaces /speckit.analyze as additive after complete tasks.md ---'
$beforeImplementSurfaces = @(
    (Join-Path $repoRoot 'extensions\specrew-speckit\commands\speckit.specrew-speckit.before-implement.md'),
    (Join-Path $repoRoot '.specify\extensions\specrew-speckit\commands\speckit.specrew-speckit.before-implement.md')
)
foreach ($surface in $beforeImplementSurfaces) {
    $surfaceName = [System.IO.Path]::GetFileName((Split-Path -Parent $surface)) + '/' + [System.IO.Path]::GetFileName($surface)
    Assert-True -Condition (Test-Path -LiteralPath $surface) -Message "before-implement surface exists ($surfaceName)"
    $content = Get-Content -LiteralPath $surface -Raw
    Assert-True -Condition ($content -like '*/speckit.analyze*') -Message "before-implement surfaces /speckit.analyze ($surfaceName)"
    Assert-True -Condition (($content -like '*spec.md*') -and ($content -like '*plan.md*') -and ($content -like '*tasks.md*')) -Message "before-implement names the spec.md/plan.md/tasks.md prerequisites ($surfaceName)"
    Assert-True -Condition ($content -match '(?i)additive' -or ($content -match '(?i)complements' -and $content -match '(?i)does not replace')) -Message "before-implement frames analyze as additive to governance ($surfaceName)"
    Assert-True -Condition ($content -match '(?i)return at the before-implement') -Message "before-implement redirects premature analyze back to the before-implement boundary ($surfaceName)"
    Assert-True -Condition ($content -match '(?i)complete[d]?\s+`?tasks\.md' -or $content -match '(?i)after\s+`?/?speckit\.tasks') -Message "before-implement gates analyze on a complete tasks.md after /speckit.tasks ($surfaceName)"
}

Write-Host ''
Write-Host '=== All coexistence tests passed ===' -ForegroundColor Green
Write-Host ''
