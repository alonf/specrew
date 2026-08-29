# Iteration 002, T015 (FR-024, SC-011): the withhold discipline, stated once and mirrored everywhere.
#
# TB-1 half 2, the composition defect: the safety rule ("always render the four verdict options") is what
# produced the unsafe act - a packet offering a verdict for a crossing whose stage had produced nothing.
# The counter-discipline already shipped in ONE place (the conformance provider's evidence-absent block),
# while the gate-stop skill, Rule 53, refocus/general.md and lifecycle-discipline.md all said the opposite.
# The discipline was already inconsistent; this suite pins it as ONE statement in every copy, plus the
# machinery half - the post-capture writer withholds the artifact the same way its sync-side twin does.
#
# Mutations that turn this file red: remove the withhold branch from any skill copy (case 1); remove the
# FR-024 paragraph from Rule 53 (2); restore "numbered verdict options" in either refocus copy or the
# discipline table (3, 4); remove the evidence guard from Sync-SpecrewPendingVerdictArtifactAfterAuthorization
# (5 - the artifact is re-minted with an approval phrase for an empty stage).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
Get-ChildItem (Join-Path $repoRoot 'scripts\internal\bootstrap\*.ps1') | ForEach-Object { . $_.FullName }
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

# ---------------------------------------------------------------------------------------------------
Write-Host 'Case 1: every gate-stop skill copy carries the withhold branch, before the options block'
$skillCopies = @(
    '.claude\skills\specrew-gate-stop\SKILL.md',
    'extensions\specrew-speckit\squad-templates\skills\gate-stop.md',
    '.specify\extensions\specrew-speckit\squad-templates\skills\gate-stop.md'
)
foreach ($relative in $skillCopies) {
    $path = Join-Path $repoRoot $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Write-Fail ("missing skill copy: {0}" -f $relative); continue }
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $hasWithhold = $text -match 'I am not offering a verdict here'
    $hasWhy = $text -match 'indistinguishable in the ledger from an approval of real work'
    $ordered = $text -match '(?s)I am not offering a verdict here.*What would you like to do\? Type one of these'
    $keepsFour = ($text -match 'approved for <to>') -and ($text -match 'changes needed:') -and ($text -match 'discuss prompt')
    Assert-True ($hasWithhold -and $hasWhy -and $ordered -and $keepsFour) ("{0}: withholds for an empty stage, says why, decides before offering, and still keeps the four typed responses" -f $relative)
}
$hashes = @($skillCopies | ForEach-Object { (Get-FileHash -LiteralPath (Join-Path $repoRoot $_) -Algorithm SHA256).Hash })
Assert-True (@($hashes | Select-Object -Unique).Count -eq 1) 'the three skill copies are byte-identical - one discipline, not three'

Write-Host 'Case 2: Rule 53 in the launch contract carries the same decision, before its options block'
$contract = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\internal\launch-contract.ps1') -Raw -Encoding UTF8
Assert-True ($contract -match 'A verdict is offered only for a crossing that has something to approve') 'Rule 53 states that a verdict is offered only for a stage with something to approve'
Assert-True ($contract -match '(?s)A verdict is offered only for a crossing that has something to approve.*OTHERWISE, immediately AFTER you emit the human re-entry packet') 'Rule 53 decides whether a verdict may be offered BEFORE it renders the options'
Assert-True ($contract -match 'indistinguishable in the ledger from an approval of real work') 'Rule 53 gives the same reason the machinery gives'

Write-Host 'Case 3: no copy still says "numbered verdict options"'
$discipline = @(
    'extensions\specrew-speckit\refocus\general.md',
    '.specify\extensions\specrew-speckit\refocus\general.md',
    'docs\methodology\lifecycle-discipline.md'
)
foreach ($relative in $discipline) {
    $text = Get-Content -LiteralPath (Join-Path $repoRoot $relative) -Raw -Encoding UTF8
    Assert-True ($text -notmatch 'numbered verdict options') ("{0}: no longer instructs numbered verdict options (it contradicted Rule 53 on its own)" -f $relative)
}
foreach ($relative in @('extensions\specrew-speckit\refocus\general.md', '.specify\extensions\specrew-speckit\refocus\general.md')) {
    $text = Get-Content -LiteralPath (Join-Path $repoRoot $relative) -Raw -Encoding UTF8
    Assert-True ($text -match 'offers NO options and NO marker') ("{0}: carries the withhold clause" -f $relative)
}
$lifecycle = Get-Content -LiteralPath (Join-Path $repoRoot 'docs\methodology\lifecycle-discipline.md') -Raw -Encoding UTF8
Assert-True ($lifecycle -match 'owes artifacts it has not produced.*NO verdict options and NO marker') 'the discipline table has a row for the stage that owes artifacts'

Write-Host 'Case 4: the refocus copies stay byte-identical'
$refocusHashes = @(@('extensions\specrew-speckit\refocus\general.md', '.specify\extensions\specrew-speckit\refocus\general.md') | ForEach-Object { (Get-FileHash -LiteralPath (Join-Path $repoRoot $_) -Algorithm SHA256).Hash })
Assert-True (@($refocusHashes | Select-Object -Unique).Count -eq 1) 'both refocus copies carry the same text'

# ---------------------------------------------------------------------------------------------------
Write-Host 'Case 5 (the machinery half): the post-capture writer withholds the artifact for an empty stage'
function New-WithholdFixture {
    param([switch]$WithReview, [string]$Crossing = 'before-implement->review-signoff')
    $root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("withhold-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $feature = [System.IO.Path]::GetFullPath((Join-Path $root (Join-Path 'specs' '001-feat')))
    $iter = [System.IO.Path]::GetFullPath((Join-Path $feature (Join-Path 'iterations' '001')))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $iter 'quality') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Value "# Iteration Plan: 001`n`n**Status**: executing" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'state.md') -Value "# Iteration State: 001`n`n**Current Phase**: before-implement" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'quality/hardening-gate.md') -Value "# Hardening Gate`n`n**Overall Verdict**: ready" -Encoding UTF8
    if ($WithReview) { Set-Content -LiteralPath (Join-Path $iter 'review.md') -Value "# Review`n`n**Overall Verdict**: accepted" -Encoding UTF8 }
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root add -A
    & git -C $root commit -q -m fixture
    $head = ([string](& git -C $root rev-parse HEAD)).Trim()
    $crossingFrom = ($Crossing -split '->')[0]
    $crossingTo = ($Crossing -split '->')[1]
    $ctx = [ordered]@{
        schema = 'v2'
        feature_path = $feature
        session_state = [ordered]@{ active = $true; boundary_type = $crossingTo; feature_ref = '001-feat'; host = 'claude'; iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-08-29T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = $crossingFrom; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    # The SCOPED crossing is what makes stage evidence CHECKABLE (an unscoped record is unverifiable by
    # shape). T014's mint gate now refuses to open a crossing whose stage owes artifacts - correctly - so
    # the record is written directly here, the shape of a pre-gate or hand-edited record, exactly as the
    # capture-containment suite does. That keeps the WRITER-side withhold tested as defense in depth.
    $tree = Get-SpecrewGitArtifactStateId -ProjectRoot $root -BoundaryCommitHash $head
    $scope = New-SpecrewPendingCrossingScope -LastAuthorizedBoundary $crossingFrom -WorkingBoundary $crossingTo -BoundaryCommitHash $head -ArtifactStateId $tree -RecordedAt '2026-08-29T00:00:01Z' -ExistingScope $null
    $st = Get-SpecrewBoundaryEnforcementState -ProjectRoot $root
    $upd = [ordered]@{ enabled = $true; last_authorized_boundary = $crossingFrom; pending_next_boundary = [string]$scope['to_boundary']; pending_crossing = $scope; verdict_history = @(); correction_history = @(); bypass_history = @() }
    Set-SpecrewBoundaryEnforcementState -ProjectRoot $root -BoundaryEnforcement $upd -Context $st.Context | Out-Null
    return [pscustomobject]@{ Root = $root; Head = $head; Artifact = (Join-Path $root '.specrew/runtime/pending-verdict-stop.md') }
}
function Write-PendingArtifact {
    param([string]$Path, [string]$Boundary, [string]$Approval)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    [System.IO.File]::WriteAllText($Path, (@('# Specrew Pending Verdict Stop', '', ("Boundary to ask for: {0}" -f $Boundary), ("Human approval phrase: {0}" -f $Approval), 'Marker last line exactly:', ("<!-- SPECREW-VERDICT-BOUNDARY: {0} -->" -f $Boundary)) -join "`n"), [System.Text.UTF8Encoding]::new($false))
}

# 5a: review.md absent - the crossing is pending, the stage owes it, the artifact must be withheld.
$w1 = New-WithholdFixture
Write-PendingArtifact -Path $w1.Artifact -Boundary 'before-implement -> review-signoff' -Approval 'approved for review-signoff'
$pv1 = Get-SpecrewPendingVerdictState -ProjectRoot $w1.Root
Assert-True ([bool]$pv1.HasPendingVerdict -and [bool]$pv1.StageEvidenceAbsent -and -not [bool]$pv1.StageEvidenceUnverifiable) 'the fixture is the real shape: pending, evidence CHECKED and absent'
Sync-SpecrewPendingVerdictArtifactAfterAuthorization -ProjectRoot $w1.Root -NowUtc '2026-08-29T00:00:02Z'
Assert-True (-not (Test-Path -LiteralPath $w1.Artifact -PathType Leaf)) 'the post-capture writer WITHHOLDS the artifact: no approval phrase and no marker for an empty stage'
$journal1 = Join-Path $w1.Root '.specrew/runtime/handover-journal.jsonl'
$withheld = @(Get-Content -LiteralPath $journal1 -Encoding UTF8 -ErrorAction SilentlyContinue | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.event -eq 'pending-verdict-artifact-withheld-stage-evidence-absent' })
Assert-True ($withheld.Count -eq 1 -and (@($withheld[0].missing) -contains 'review.md')) 'the withhold is journaled, naming review.md'

# 5b: the same fixture WITH review.md - the artifact is written, with its marker.
# before-implement owes plan.md + quality/hardening-gate.md, which this fixture HAS - review-signoff also
# owes a completed campaign result, which a fixture cannot produce and which is not what this case measures.
$w2 = New-WithholdFixture -Crossing 'tasks->before-implement'
Sync-SpecrewPendingVerdictArtifactAfterAuthorization -ProjectRoot $w2.Root -NowUtc '2026-08-29T00:00:02Z'
Assert-True (Test-Path -LiteralPath $w2.Artifact -PathType Leaf) 'with the owed artifact present, the writer produces the pending-verdict artifact'
$content2 = Get-Content -LiteralPath $w2.Artifact -Raw -Encoding UTF8
Assert-True ($content2 -match 'Human approval phrase: approved for before-implement' -and $content2 -match 'SPECREW-VERDICT-BOUNDARY: tasks -> before-implement') 'and it carries the approval phrase and the marker for a stage that has something to approve'

foreach ($f in @($w1, $w2)) { try { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
if ($script:failCount -gt 0) { throw ("withhold-discipline: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'withhold-discipline: all assertions passed' -ForegroundColor Green
