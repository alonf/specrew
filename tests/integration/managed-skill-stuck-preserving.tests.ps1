[CmdletBinding()]
param()

# Feature 161 (Proposal 161) — managed-skill "stuck preserving" deploy-level repro.
#
# Feature 160 fixed and unit-tested the classifier (managed-runtime-sidecar.tests.ps1,
# AST-extracted functions). This harness closes the proposal's remaining Tier 0 ask:
# execute the REAL deploy-squad-runtime.ps1 end-to-end against an isolated scratch
# project and observe the composed behavior (definition lookup -> classification ->
# legacy removal/preserve -> active-root overwrite + marker rewrite).
#
# Scenarios (legacy root = .copilot/skills):
#   S1  marker-present canonical dir            -> removed-legacy-managed-skill
#   S2  user-authored dir, NO marker            -> preserved + byte-identical (no-loss invariant)
#   S2b non-catalog specrew-* dir               -> preserved via the no-definition path
#   S3  current-canonical, NO marker (slash)    -> removed (F-160 regression guard, deploy level)
#   S3g current-canonical, NO marker (generic)  -> removed (F-160 regression guard, deploy level)
#   S4  STALE older-canonical, NO marker (slash)   -> PROBE: outcome captured, not pre-asserted
#   S4g STALE older-canonical, NO marker (generic) -> PROBE: outcome captured, not pre-asserted
#   S5  second consecutive deploy run           -> idempotent: active surfaces preserved, stable end-state
#   S6  active roots after deploy               -> SKILL.md + .specrew-managed in all four roots
#   S7  REAL-HISTORICAL generic content, NO marker -> PROBE: the reachable upgrade-path artifact.
#       Provenance: commits 29a130b2 (F-021, 2026-05-18) through 534b7430 (F-024, 2026-05-20)
#       deployed generic skills into .copilot/skills with NO sidecar marker and NO front matter;
#       generic template content later drifted (e.g. 7f6536b2). The fixture embeds the genuine
#       3816929c-era specrew-capacity-planning head, so it exercises the generic-kind
#       exact-equality fallback (content -eq LegacyContent) on real upgrade-path content.
#
# S4/S4g are NEUTRAL PROBES (test-integrity lens): they record the observed outcome for
# the T005 verdict instead of asserting an expectation. If a CONFIRMED fix lands they are
# promoted to regression assertions (T007).
#
# Determinism (SC-001): the harness emits a stable OUTCOME-SUMMARY block; two consecutive
# full runs must produce identical summaries. Zero writes outside the temp sandbox.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "INFO: $Message" -ForegroundColor Cyan }
function Write-Probe { param([string]$Message) Write-Host "PROBE: $Message" -ForegroundColor Yellow }

$script:Failures = New-Object System.Collections.Generic.List[string]
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Pass $Message } else { $script:Failures.Add($Message) | Out-Null; Write-Host "FAIL: $Message" -ForegroundColor Red }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
$deployScript = Join-Path $repoRoot 'extensions' 'specrew-speckit' 'scripts' 'deploy-squad-runtime.ps1'
$skillsTemplateRoot = Join-Path $repoRoot 'extensions' 'specrew-speckit' 'squad-templates' 'skills'
foreach ($p in @($deployScript, $skillsTemplateRoot)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "Required path not found: $p" }
}

# Canonical content read the same way the deploy script reads it.
$slashName = 'specrew-status'   # S4 probe (slash kind)
$slashRemovedName = 'specrew-version' # S3 (slash kind)
$slashMarkerName = 'specrew-help'     # S1 (marker present)
$slashUserName = 'specrew-team'       # S2 (user-authored content under a catalog name)
$genericRemovedName = 'specrew-iteration-resume'  # S3g
$genericStaleName = 'specrew-drift-check'         # S4g
# S7 uses 'specrew-capacity-planning' to match the real historical artifact's identity.

function Get-CanonicalSkillContent {
    param([string]$Directory)
    if ($Directory -like 'specrew-*') {
        $slashPath = Join-Path (Join-Path $skillsTemplateRoot $Directory) 'SKILL.md'
        if (Test-Path -LiteralPath $slashPath -PathType Leaf) {
            return Get-Content -LiteralPath $slashPath -Raw
        }
        $genericPath = Join-Path $skillsTemplateRoot ($Directory -replace '^specrew-', '')
        $genericPath = "$genericPath.md"
        if (Test-Path -LiteralPath $genericPath -PathType Leaf) {
            return Get-Content -LiteralPath $genericPath -Raw
        }
    }
    throw "No canonical template found for '$Directory'."
}

function Get-MarkerContent {
    param([string]$Directory)
    # Mirrors Get-ManagedSkillMarkerContent; the classifier only tests marker EXISTENCE,
    # but the fixture stays faithful to the real sidecar shape.
    return @(
        'schema: v1'
        'owner: specrew'
        'kind: project-skill'
        ('directory: {0}' -f $Directory)
    ) -join [Environment]::NewLine
}

$sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-stuck-preserving-" + [System.Guid]::NewGuid().ToString('N'))
$project = Join-Path $sandbox 'project'
$legacyRoot = Join-Path $project '.copilot\skills'

function New-LegacySkillDir {
    param([string]$Name, [string]$SkillContent, [switch]$WithMarker)
    $dir = Join-Path $legacyRoot $Name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $dir 'SKILL.md'), $SkillContent, [System.Text.UTF8Encoding]::new($false))
    if ($WithMarker) {
        [System.IO.File]::WriteAllText((Join-Path $dir '.specrew-managed'), (Get-MarkerContent -Directory $Name), [System.Text.UTF8Encoding]::new($false))
    }
    return $dir
}

function Get-LegacyAction {
    param([object[]]$Actions, [string]$DirName)
    $dirPath = Join-Path $legacyRoot $DirName
    return @($Actions | Where-Object { $_.Path -eq $dirPath -and $_.Action -like '*legacy*skill*' }) | Select-Object -First 1
}

$summary = New-Object System.Collections.Generic.List[string]

try {
    New-Item -ItemType Directory -Path (Join-Path $project '.squad') -Force | Out-Null

    # --- Seed legacy fixtures -------------------------------------------------
    $slashCanonical = Get-CanonicalSkillContent -Directory $slashName
    $slashRemovedCanonical = Get-CanonicalSkillContent -Directory $slashRemovedName
    $slashMarkerCanonical = Get-CanonicalSkillContent -Directory $slashMarkerName
    $genericRemovedCanonical = Get-CanonicalSkillContent -Directory $genericRemovedName
    $genericStaleCanonical = Get-CanonicalSkillContent -Directory $genericStaleName

    Assert-True ($slashCanonical.TrimStart().StartsWith('---')) "Reachability precondition: slash canonical content starts with front matter"
    Assert-True ($genericStaleCanonical.TrimStart().StartsWith('---')) "Reachability precondition: generic canonical content starts with front matter"

    # Stale older-canonical: front-matter-leading content that no longer exactly matches
    # the current canonical (simulates a previous Specrew release's canonical text).
    $staleSuffix = [Environment]::NewLine + 'Body line that shipped in a previous Specrew release.' + [Environment]::NewLine
    $slashStale = $slashCanonical + $staleSuffix
    $genericStale = $genericStaleCanonical + $staleSuffix

    $userAuthored = "---`nname: my-custom-team-skill`ndescription: hand authored by the user`n---`n# My Team Skill`n`nUser wrote this; do not delete.`n"

    # S7: genuine F-021..F-024-era generic content (head of 3816929c
    # capacity-planning.md; truncation does not change the classification path:
    # no marker, not exact-equal to current canonical, no leading front matter,
    # generic-kind equality vs CURRENT LegacyContent fails).
    $historicalGeneric = @(
        '# specrew-capacity-planning'
        ''
        '**Type**: Planning Skill  '
        '**Schema**: v1  '
        '**Status**: Active planning method'
        ''
        '## Purpose'
        ''
        'Analyze in-scope requirements, produce a taskable effort model, and make overcommit visible before the plan is approved.'
        ''
        '## When to Use'
        ''
        '- During the Planning ceremony'
        '- When re-planning after needs-rework or abandonment'
        '- For deferral and what-if sequencing decisions'
    ) -join "`n"

    $null = New-LegacySkillDir -Name $slashMarkerName -SkillContent $slashMarkerCanonical -WithMarker  # S1
    $s2Dir = New-LegacySkillDir -Name $slashUserName -SkillContent $userAuthored                        # S2
    $s2bDir = New-LegacySkillDir -Name 'specrew-mycustom' -SkillContent $userAuthored                   # S2b (no catalog definition)
    $null = New-LegacySkillDir -Name $slashRemovedName -SkillContent $slashRemovedCanonical             # S3
    $null = New-LegacySkillDir -Name $genericRemovedName -SkillContent $genericRemovedCanonical         # S3g
    $s4Dir = New-LegacySkillDir -Name $slashName -SkillContent $slashStale                              # S4
    $s4gDir = New-LegacySkillDir -Name $genericStaleName -SkillContent $genericStale                    # S4g
    $s7Dir = New-LegacySkillDir -Name 'specrew-capacity-planning' -SkillContent $historicalGeneric      # S7

    $s2ContentBefore = Get-Content -LiteralPath (Join-Path $s2Dir 'SKILL.md') -Raw

    # --- Run 1: the real deploy ----------------------------------------------
    Write-Info "Run 1: executing real deploy against scratch project $project"
    $actions1 = @(& $deployScript -ProjectPath $project -PassThru)
    Assert-True ($actions1.Count -gt 0) "Run 1 produced a deployment-action record"

    # S1 marker-present -> removed
    $s1Action = Get-LegacyAction -Actions $actions1 -DirName $slashMarkerName
    Assert-True ($null -ne $s1Action -and $s1Action.Action -eq 'removed-legacy-managed-skill') `
        "S1: marker-present canonical legacy dir is removed (provenance wins)"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $legacyRoot $slashMarkerName))) "S1: directory is gone from disk"
    $summary.Add("S1=removed") | Out-Null

    # S2 user-authored -> preserved + byte-identical (no-loss invariant)
    $s2Action = Get-LegacyAction -Actions $actions1 -DirName $slashUserName
    Assert-True ($null -ne $s2Action -and $s2Action.Action -eq 'preserved-legacy-unmanaged-skill') `
        "S2: user-authored legacy dir (no marker) is preserved"
    $s2ContentAfter = Get-Content -LiteralPath (Join-Path $s2Dir 'SKILL.md') -Raw
    Assert-True ([System.String]::Equals($s2ContentBefore, $s2ContentAfter, [System.StringComparison]::Ordinal)) `
        "S2: user-authored SKILL.md is byte-identical after deploy (no-loss invariant)"
    $summary.Add("S2=preserved-byte-identical") | Out-Null

    # S2b non-catalog dir -> preserved via no-definition path
    $s2bAction = Get-LegacyAction -Actions $actions1 -DirName 'specrew-mycustom'
    Assert-True ($null -ne $s2bAction -and $s2bAction.Action -eq 'preserved-legacy-unmanaged-skill') `
        "S2b: non-catalog specrew-* dir is preserved (no-definition path)"
    Assert-True (Test-Path -LiteralPath (Join-Path $s2bDir 'SKILL.md')) "S2b: directory still on disk"
    $summary.Add("S2b=preserved") | Out-Null

    # S3 / S3g current-canonical without marker -> removed (F-160 deploy-level guard)
    $s3Action = Get-LegacyAction -Actions $actions1 -DirName $slashRemovedName
    Assert-True ($null -ne $s3Action -and $s3Action.Action -eq 'removed-legacy-managed-skill') `
        "S3 (slash): current-canonical content without marker is removed (F-160 fix holds at deploy level)"
    $s3gAction = Get-LegacyAction -Actions $actions1 -DirName $genericRemovedName
    Assert-True ($null -ne $s3gAction -and $s3gAction.Action -eq 'removed-legacy-managed-skill') `
        "S3g (generic): current-canonical content without marker is removed (F-160 fix holds at deploy level)"
    $summary.Add("S3=removed") | Out-Null
    $summary.Add("S3g=removed") | Out-Null

    # S4 / S4g stale older-canonical without marker -> NEUTRAL PROBE
    $s4Action = Get-LegacyAction -Actions $actions1 -DirName $slashName
    $s4Outcome = if ($null -ne $s4Action) { $s4Action.Action } else { 'no-action-recorded' }
    Write-Probe "S4 (slash): stale older-canonical, no marker -> observed outcome '$s4Outcome' (classification rule: marker absent; exact-match vs current canonical fails; leading '---' front-matter heuristic at deploy-squad-runtime.ps1::Test-IsManagedLegacySkillDirectory)"
    $summary.Add("S4=$s4Outcome") | Out-Null

    $s4gAction = Get-LegacyAction -Actions $actions1 -DirName $genericStaleName
    $s4gOutcome = if ($null -ne $s4gAction) { $s4gAction.Action } else { 'no-action-recorded' }
    Write-Probe "S4g (generic): stale older-canonical, no marker -> observed outcome '$s4gOutcome' (same rule chain, generic kind)"
    $summary.Add("S4g=$s4gOutcome") | Out-Null

    # S7 REAL-HISTORICAL generic content -> NEUTRAL PROBE (the reachable artifact)
    $s7Action = Get-LegacyAction -Actions $actions1 -DirName 'specrew-capacity-planning'
    $s7Outcome = if ($null -ne $s7Action) { $s7Action.Action } else { 'no-action-recorded' }
    Write-Probe "S7 (real-historical generic): F-021-era content, no marker, no front matter -> observed outcome '$s7Outcome' (classification rule: marker absent; exact-match vs current canonical fails; no leading '---'; generic-kind equality vs CURRENT LegacyContent fails -> fallthrough)"
    $summary.Add("S7=$s7Outcome") | Out-Null

    # S6 active roots: SKILL.md + marker present for a representative slash + generic skill
    $activeRoots = @(
        (Join-Path $project '.claude\skills'),
        (Join-Path $project '.cursor\rules'),
        (Join-Path $project '.github\skills'),
        (Join-Path $project '.agents\skills')
    )
    $s6Ok = $true
    foreach ($root in $activeRoots) {
        foreach ($skillDir in @($slashName, $genericRemovedName)) {
            $skillPath = Join-Path (Join-Path $root $skillDir) 'SKILL.md'
            $markerPath = Join-Path (Join-Path $root $skillDir) '.specrew-managed'
            if (-not (Test-Path -LiteralPath $skillPath -PathType Leaf)) { $s6Ok = $false }
            if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) { $s6Ok = $false }
        }
    }
    Assert-True $s6Ok "S6: all four active roots carry SKILL.md + .specrew-managed for representative skills"
    $summary.Add("S6=active-roots-deployed") | Out-Null

    # --- Run 2 (S5): idempotency ----------------------------------------------
    Write-Info "Run 2: re-executing deploy (idempotency probe)"
    $legacyStateBetween = @(Get-ChildItem -LiteralPath $legacyRoot -Directory | Sort-Object Name | Select-Object -ExpandProperty Name)
    $actions2 = @(& $deployScript -ProjectPath $project -PassThru)

    $run2Removals = @($actions2 | Where-Object { $_.Action -eq 'removed-legacy-managed-skill' })
    Assert-True ($run2Removals.Count -eq 0) "S5: second run removes nothing further (stable legacy end-state)"

    $run2ActiveUpdates = @($actions2 | Where-Object { $_.Action -eq 'updated' -and $_.Path -like (Join-Path $project '*skills*') })
    $run2ActiveUpdates += @($actions2 | Where-Object { $_.Action -eq 'updated' -and $_.Path -like (Join-Path $project '.cursor*') })
    Assert-True ($run2ActiveUpdates.Count -eq 0) "S5: second run reports no active-root skill updates (preserved/no-change)"

    $legacyStateAfter = @(Get-ChildItem -LiteralPath $legacyRoot -Directory | Sort-Object Name | Select-Object -ExpandProperty Name)
    Assert-True (($legacyStateBetween -join ',') -eq ($legacyStateAfter -join ',')) "S5: legacy directory set unchanged across re-run"

    $s2ContentRun2 = Get-Content -LiteralPath (Join-Path $s2Dir 'SKILL.md') -Raw
    Assert-True ([System.String]::Equals($s2ContentBefore, $s2ContentRun2, [System.StringComparison]::Ordinal)) `
        "S5/S2: user-authored SKILL.md still byte-identical after second run"
    $summary.Add("S5=idempotent") | Out-Null
}
finally {
    if (Test-Path -LiteralPath $sandbox) { Remove-Item -LiteralPath $sandbox -Recurse -Force }
}

Write-Host ""
Write-Host ("OUTCOME-SUMMARY: " + (($summary | Sort-Object) -join '; '))

if ($script:Failures.Count -gt 0) {
    Write-Host ("`n{0} assertion(s) failed:" -f $script:Failures.Count) -ForegroundColor Red
    foreach ($f in $script:Failures) { Write-Host "  - $f" -ForegroundColor Red }
    exit 1
}
Write-Host "`nmanaged-skill-stuck-preserving: all assertions pass" -ForegroundColor Green
