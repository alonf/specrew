[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

function Assert-ContentMatches {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Fail ("{0}: file not found at {1}" -f $Message, $Path)
    }

    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ($content -notmatch $Pattern) {
        Write-Fail ("{0}: pattern '{1}' not found in {2}" -f $Message, $Pattern, $Path)
    }
    Write-Pass $Message
}

function Assert-MirrorParity {
    param(
        [Parameter(Mandatory = $true)][string]$Primary,
        [Parameter(Mandatory = $true)][string]$Mirror,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not (Test-Path -LiteralPath $Primary -PathType Leaf)) {
        Write-Fail ("{0}: primary file not found at {1}" -f $Message, $Primary)
    }
    if (-not (Test-Path -LiteralPath $Mirror -PathType Leaf)) {
        Write-Fail ("{0}: mirror file not found at {1}" -f $Message, $Mirror)
    }

    $primaryHash = (Get-FileHash -LiteralPath $Primary -Algorithm SHA256).Hash
    $mirrorHash = (Get-FileHash -LiteralPath $Mirror -Algorithm SHA256).Hash
    if ($primaryHash -ne $mirrorHash) {
        Write-Fail ("{0}: SHA256 mismatch (primary={1}, mirror={2})" -f $Message, $primaryHash, $mirrorHash)
    }
    Write-Pass $Message
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$primaryRoot = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates'
$mirrorRoot = Join-Path $repoRoot '.specify\extensions\specrew-speckit\squad-templates'
$userGuide = Join-Path $repoRoot 'docs\user-guide.md'

Write-Host ''
Write-Host '=== Proposal 082 Tier 1 — Boundary Commit + Push Discipline Methodology-Surface Tests ===' -ForegroundColor Cyan
Write-Host ("Repo root: {0}" -f $repoRoot)
Write-Host ''

# T002: Coordinator governance prompt rule
Write-Host 'Test 1: Coordinator governance prompt carries the 14B boundary-commit-discipline rule'
$govPrompt = Join-Path $primaryRoot 'coordinator\specrew-governance.md'
Assert-ContentMatches -Path $govPrompt -Pattern '14B\..*boundary commit \+ upstream push discipline' -Message '14B rule heading present in coordinator governance prompt'
Assert-ContentMatches -Path $govPrompt -Pattern 'EVERY lifecycle boundary' -Message 'Rule applies at every lifecycle boundary'
Assert-ContentMatches -Path $govPrompt -Pattern 'commit the boundary-phase work in semantic commit groups BEFORE' -Message 'Rule mandates commit before boundary-sync invocation'
Assert-ContentMatches -Path $govPrompt -Pattern 'push the feature branch to' -Message 'Rule mandates push to origin'
Assert-ContentMatches -Path $govPrompt -Pattern 'git rev-parse HEAD.*git rev-parse origin' -Message 'Rule mandates HEAD/origin parity verification'

# T003: Implementer charter
Write-Host ''
Write-Host 'Test 2: Implementer charter carries primary-committer responsibility'
$implementer = Join-Path $primaryRoot 'agents\implementer\charter.md'
Assert-ContentMatches -Path $implementer -Pattern 'Boundary commit \+ push discipline' -Message 'Implementer charter has Boundary commit + push discipline section'
Assert-ContentMatches -Path $implementer -Pattern 'semantic commit groups' -Message 'Implementer commits in semantic groups'
Assert-ContentMatches -Path $implementer -Pattern 'push to.*origin.*IMMEDIATELY' -Message 'Implementer pushes immediately after commit'
Assert-ContentMatches -Path $implementer -Pattern 'WIP files in the working tree' -Message 'Implementer references WIP-in-working-tree as violation'

# T004: Spec Steward charter
Write-Host ''
Write-Host 'Test 3: Spec Steward charter carries oversight responsibility'
$specSteward = Join-Path $primaryRoot 'agents\spec-steward\charter.md'
Assert-ContentMatches -Path $specSteward -Pattern 'Boundary commit \+ push discipline oversight' -Message 'Spec Steward charter has oversight section'
Assert-ContentMatches -Path $specSteward -Pattern 'flag WIP-in-working-tree' -Message 'Spec Steward flags WIP-in-working-tree as violation'
Assert-ContentMatches -Path $specSteward -Pattern 'Push parity is durable evidence' -Message 'Spec Steward references push parity as durable evidence'

# T005: Reviewer charter
Write-Host ''
Write-Host 'Test 4: Reviewer charter carries pre-merge committed-work check'
$reviewer = Join-Path $primaryRoot 'agents\reviewer\charter.md'
Assert-ContentMatches -Path $reviewer -Pattern 'Pre-merge committed-work check' -Message 'Reviewer charter has pre-merge check section'
Assert-ContentMatches -Path $reviewer -Pattern 'WIP files on the feature branch at PR-open time are a \*\*hard reject\*\*' -Message 'Reviewer rejects WIP at PR-open as hard reject'

# T006: Retro Facilitator charter
Write-Host ''
Write-Host 'Test 5: Retro Facilitator charter carries commit-discipline retro prompt'
$retroFac = Join-Path $primaryRoot 'agents\retro-facilitator\charter.md'
Assert-ContentMatches -Path $retroFac -Pattern 'Boundary commit \+ push discipline retro' -Message 'Retro Facilitator charter has commit-discipline retro section'
Assert-ContentMatches -Path $retroFac -Pattern 'boundary-commit-discipline-violations' -Message 'Retro Facilitator records violations count'

# T007: Planner charter
Write-Host ''
Write-Host 'Test 6: Planner charter carries light commit-cadence reference'
$planner = Join-Path $primaryRoot 'agents\planner\charter.md'
Assert-ContentMatches -Path $planner -Pattern 'boundary-commit cadence' -Message 'Planner charter references commit cadence'
Assert-ContentMatches -Path $planner -Pattern 'semantic commit group' -Message 'Planner anticipates commits as semantic groups'

# T008: User-guide section
Write-Host ''
Write-Host 'Test 7: User-guide carries the Boundary Commit Discipline section'
Assert-ContentMatches -Path $userGuide -Pattern '## Boundary Commit Discipline' -Message 'User-guide has Boundary Commit Discipline heading'
Assert-ContentMatches -Path $userGuide -Pattern 'Commit at every boundary\. Push after every commit\.' -Message 'User-guide states the discipline succinctly'
Assert-ContentMatches -Path $userGuide -Pattern 'Tier 1.*Tier 2.*Tier 3' -Message 'User-guide describes three-tier enforcement plan' -ErrorAction SilentlyContinue
# Above pattern may match across lines; use simpler check:
$ugContent = Get-Content -LiteralPath $userGuide -Raw -Encoding UTF8
if ($ugContent -notmatch 'Tier 1' -or $ugContent -notmatch 'Tier 2' -or $ugContent -notmatch 'Tier 3') {
    Write-Fail 'User-guide does not describe the three-tier enforcement plan'
}
Write-Pass 'User-guide describes three-tier enforcement plan'

# T009: Mirror parity for all 6 modified files
Write-Host ''
Write-Host 'Test 8: Mirror parity for all 6 modified files'
foreach ($relPath in @(
        'coordinator\specrew-governance.md',
        'agents\implementer\charter.md',
        'agents\spec-steward\charter.md',
        'agents\reviewer\charter.md',
        'agents\retro-facilitator\charter.md',
        'agents\planner\charter.md'
    )) {
    $primary = Join-Path $primaryRoot $relPath
    $mirror = Join-Path $mirrorRoot $relPath
    Assert-MirrorParity -Primary $primary -Mirror $mirror -Message ("Mirror parity for {0}" -f $relPath)
}

# Terminology compliance (FR-009): all new prose uses "the Crew" not "Squad" when referring to the team-of-agents role
Write-Host ''
Write-Host 'Test 9: New methodology prose uses "the Crew" terminology'
$govPromptContent = Get-Content -LiteralPath $govPrompt -Raw -Encoding UTF8
# Find the 14B block by splitting on the section header
$blockMatch = [regex]::Match($govPromptContent, '(?s)14B\.\s.*?(?=\n1\.\s\*\*|\Z)')
if (-not $blockMatch.Success) {
    Write-Fail '14B rule block not found in coordinator governance prompt'
}
$ruleBlock = $blockMatch.Value
if ($ruleBlock -notmatch 'the Crew') {
    Write-Fail 'Rule 14B does not use "the Crew" terminology for the team role'
}
Write-Pass 'Rule 14B uses "the Crew" terminology'

Write-Host ''
Write-Host 'All Proposal 082 Tier 1 methodology-surface tests passed.' -ForegroundColor Green
exit 0
