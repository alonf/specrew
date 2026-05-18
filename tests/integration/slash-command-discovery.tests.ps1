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
$skillsRoot = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\skills'

Write-Host ''
Write-Host '=== Slash-Command Discovery Validation Tests ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

# v1 command catalog
$v1Commands = @(
    [pscustomobject]@{ Command = 'where';   DirName = 'specrew-where';   SlashForm = '/specrew.where' },
    [pscustomobject]@{ Command = 'status';  DirName = 'specrew-status';  SlashForm = '/specrew.status' },
    [pscustomobject]@{ Command = 'update';  DirName = 'specrew-update';  SlashForm = '/specrew.update' },
    [pscustomobject]@{ Command = 'team';    DirName = 'specrew-team';    SlashForm = '/specrew.team' },
    [pscustomobject]@{ Command = 'review';  DirName = 'specrew-review';  SlashForm = '/specrew.review' },
    [pscustomobject]@{ Command = 'version'; DirName = 'specrew-version'; SlashForm = '/specrew.version' },
    [pscustomobject]@{ Command = 'help';    DirName = 'specrew-help';    SlashForm = '/specrew.help' }
)

# --- Test 1: All 7 skill SKILL.md files exist ---
Write-Host '--- Test 1: All 7 v1 SKILL.md files exist in skill subdirectories ---'
foreach ($entry in $v1Commands) {
    $path = Join-Path $skillsRoot "$($entry.DirName)\SKILL.md"
    Assert-True -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message "SKILL.md exists: $($entry.DirName)"
}

# --- Test 2: Each SKILL.md references its own slash-command form ---
Write-Host ''
Write-Host '--- Test 2: Each SKILL.md contains its own slash-command identifier ---'
foreach ($entry in $v1Commands) {
    $path = Join-Path $skillsRoot "$($entry.DirName)\SKILL.md"
    $content = Get-Content -LiteralPath $path -Raw
    $slashRef = $entry.SlashForm -replace '/', ''  # match without leading slash too
    # Accept either /specrew.X or specrew.X in the content
    $found = ($content -like "*$($entry.SlashForm)*") -or ($content -like "*$slashRef*")
    Assert-True -Condition $found -Message "SKILL.md for $($entry.DirName) references $($entry.SlashForm)"
}

# --- Test 3: specrew-help SKILL.md catalogs all 7 commands ---
Write-Host ''
Write-Host '--- Test 3: /specrew.help SKILL.md catalogs all v1 commands ---'
$helpSkillContent = Get-Content -LiteralPath (Join-Path $skillsRoot 'specrew-help\SKILL.md') -Raw
foreach ($entry in $v1Commands) {
    $found = ($helpSkillContent -like "*$($entry.SlashForm)*") -or ($helpSkillContent -like "*$($entry.Command)*")
    Assert-True -Condition $found -Message "/specrew.help SKILL.md references $($entry.Command)"
}

# --- Test 4: specrew-status SKILL.md identifies it as alias for /specrew.where ---
Write-Host ''
Write-Host '--- Test 4: /specrew.status SKILL.md identifies alias relationship ---'
$statusContent = Get-Content -LiteralPath (Join-Path $skillsRoot 'specrew-status\SKILL.md') -Raw
$isAlias = ($statusContent -like '*alias*') -or ($statusContent -like '*same as*') -or ($statusContent -like '*equivalent*') -or ($statusContent -like '*maps to*')
Assert-True -Condition $isAlias -Message '/specrew.status SKILL.md documents alias relationship'
Assert-Contains -Text $statusContent -Substring 'where' -Message '/specrew.status SKILL.md references /specrew.where'

# --- Test 5: skills/README.md documents all 7 commands ---
Write-Host ''
Write-Host '--- Test 5: skills/README.md documents all 7 v1 slash commands ---'
$readmePath = Join-Path $skillsRoot 'README.md'
Assert-True -Condition (Test-Path -LiteralPath $readmePath -PathType Leaf) -Message 'skills/README.md exists'
$readmeContent = Get-Content -LiteralPath $readmePath -Raw
foreach ($entry in $v1Commands) {
    Assert-Contains -Text $readmeContent -Substring $entry.Command -Message "skills/README.md documents $($entry.Command)"
}

# --- Test 6: /specrew.help SKILL.md points to /specrew.help as fallback surface ---
Write-Host ''
Write-Host '--- Test 6: /specrew.help SKILL.md establishes discovery fallback ---'
$helpContent = Get-Content -LiteralPath (Join-Path $skillsRoot 'specrew-help\SKILL.md') -Raw
Assert-Contains -Text $helpContent -Substring '/specrew.help' -Message '/specrew.help SKILL.md self-references /specrew.help as fallback'

# --- Test 7: quickstart.md validates discovery step is documented ---
Write-Host ''
Write-Host '--- Test 7: quickstart.md validates /specrew.help discovery step ---'
$quickstartPath = Join-Path $repoRoot 'specs\021-specrew-slash-commands\quickstart.md'
Assert-True -Condition (Test-Path -LiteralPath $quickstartPath -PathType Leaf) -Message 'quickstart.md exists'
$quickstartContent = Get-Content -LiteralPath $quickstartPath -Raw
Assert-Contains -Text $quickstartContent -Substring '/specrew.help' -Message 'quickstart.md references /specrew.help as discovery fallback'
Assert-Contains -Text $quickstartContent -Substring 'specrew-*' -Message 'quickstart.md references specrew-* deployed skill directories'

Write-Host ''
Write-Host '=== All discovery validation tests passed ===' -ForegroundColor Green
Write-Host ''
