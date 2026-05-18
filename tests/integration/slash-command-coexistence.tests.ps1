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

function Assert-NotContains {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Substring,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if ($Text -like "*$Substring*") {
        Write-Fail "$Message (unexpected '$Substring' in text)"
        exit 1
    }
    Write-Pass $Message
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$skillsRoot = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\skills'

Write-Host ''
Write-Host '=== Slash-Command Namespace Coexistence Tests ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

# --- Test 1: /specrew.* skill names do not collide with /speckit.* names ---
Write-Host '--- Test 1: /specrew.* skill directory names do not collide with /speckit.* names ---'
# Spec Kit uses flat .md files in skills/ root (e.g. capacity-planning.md)
# Specrew uses subdirectories (e.g. specrew-where/SKILL.md)
# Check that none of the flat .md files match a specrew-* subdirectory name (after trimming .md)
$flatSkillNames = @(
    Get-ChildItem -LiteralPath $skillsRoot -Filter '*.md' -File |
    Where-Object { $_.Name -ne 'README.md' } |
    Select-Object -ExpandProperty BaseName
)
$subdirSkillNames = @(
    Get-ChildItem -LiteralPath $skillsRoot -Directory |
    Select-Object -ExpandProperty Name
)

foreach ($subdirName in $subdirSkillNames) {
    Assert-True -Condition ($flatSkillNames -notcontains $subdirName) -Message "Subdirectory skill '$subdirName' does not collide with flat skill of same name"
}

# --- Test 2: All specrew-* subdirectory skill names carry the specrew- prefix ---
Write-Host ''
Write-Host '--- Test 2: All skill subdirectory names are prefixed with specrew- ---'
foreach ($dirName in $subdirSkillNames) {
    Assert-True -Condition $dirName.StartsWith('specrew-') -Message "Skill subdirectory '$dirName' carries specrew- prefix"
}

# --- Test 3: specrew-review SKILL.md carries explicit boundary-safety wording ---
Write-Host ''
Write-Host '--- Test 3: /specrew.review SKILL.md carries explicit boundary-safety wording ---'
$reviewSkillContent = Get-Content -LiteralPath (Join-Path $skillsRoot 'specrew-review\SKILL.md') -Raw
$hasBoundarySafety = ($reviewSkillContent -like '*boundary*') -or ($reviewSkillContent -like '*does not.*approve*') -or ($reviewSkillContent -like '*not.*authorize*') -or ($reviewSkillContent -like '*human.*review*')
Assert-True -Condition $hasBoundarySafety -Message '/specrew.review SKILL.md has boundary-safety wording'

# --- Test 4: specrew-review SKILL.md does not claim approval authority ---
Write-Host ''
Write-Host '--- Test 4: /specrew.review SKILL.md does not imply lifecycle approval ---'
# We check that the skill does NOT assert "this approves" or "this authorizes" lifecycle advance
Assert-NotContains -Text $reviewSkillContent -Substring 'approves the lifecycle' -Message '/specrew.review does not assert it approves the lifecycle'
Assert-NotContains -Text $reviewSkillContent -Substring 'authorizes the boundary' -Message '/specrew.review does not assert it authorizes the boundary'

# --- Test 5: specrew-review.ps1 does not contain boundary-bypass patterns ---
Write-Host ''
Write-Host '--- Test 5: specrew-review.ps1 does not contain lifecycle-boundary bypass patterns ---'
$reviewScriptPath = Join-Path $repoRoot 'scripts\specrew-review.ps1'
Assert-True -Condition (Test-Path -LiteralPath $reviewScriptPath -PathType Leaf) -Message 'specrew-review.ps1 exists'
$reviewScriptContent = Get-Content -LiteralPath $reviewScriptPath -Raw
# The boundary bypass patterns to guard against: automatic ledger writes without human input
$hasBypass = $reviewScriptContent -like '*Add-InteractionModelAuthorizationEntry*'
Assert-True -Condition (-not $hasBypass) -Message 'specrew-review.ps1 does not auto-write lifecycle authorization entries'

# --- Test 6: /specrew.team SKILL.md carries coexistence-safe wording ---
Write-Host ''
Write-Host '--- Test 6: /specrew.team SKILL.md carries coexistence-safe wording ---'
$teamSkillContent = Get-Content -LiteralPath (Join-Path $skillsRoot 'specrew-team\SKILL.md') -Raw
$hasCoexistence = ($teamSkillContent -like '*coexist*') -or ($teamSkillContent -like '*squad*') -or ($teamSkillContent -like '*agent*')
Assert-True -Condition $hasCoexistence -Message '/specrew.team SKILL.md references Squad agent coexistence context'

# --- Test 7: routing contract enforces namespace-collision explicit failure ---
Write-Host ''
Write-Host '--- Test 7: Routing contract requires explicit failure on namespace collision ---'
$routingContractPath = Join-Path $repoRoot 'specs\021-specrew-slash-commands\contracts\slash-command-routing.md'
$routingContent = Get-Content -LiteralPath $routingContractPath -Raw
Assert-Contains -Text $routingContent -Substring 'Namespace collision' -Message 'Routing contract documents namespace-collision failure mode'
Assert-Contains -Text $routingContent -Substring 'silently remap' -Message 'Routing contract prohibits silent namespace remapping'

# --- Test 8: specrew.ps1 does not share case-insensitive variable names across switch branches ---
Write-Host ''
Write-Host '--- Test 8: specrew.ps1 has no case-insensitive PowerShell variable collisions ---'
$specrewContent = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\specrew.ps1') -Raw
# The governance rule is that $whereScript and $reviewScript etc. are distinct lower-case names
# Check that the 'where' and 'status' cases do not use the same variable name for different paths
# (they intentionally use the same $whereScript — that IS the alias parity; there should be no "$wherescript" casing variation)
$whereScriptOccurrences = ([regex]::Matches($specrewContent, '\$whereScript', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
$whereScriptExactOccurrences = ([regex]::Matches($specrewContent, '\$whereScript')).Count
Assert-True -Condition ($whereScriptOccurrences -eq $whereScriptExactOccurrences) -Message 'No case-inconsistency in $whereScript variable references'

Write-Host ''
Write-Host '=== All coexistence tests passed ===' -ForegroundColor Green
Write-Host ''
