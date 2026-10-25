#requires -Version 7.0
# Feature 202 T012 (FR-019; B4F-089): a resume says where things stand from DISK - the pending decision, the commits
# since the previous session's notes, and task progress - and shows those notes only as context, with their age.
# Notes older than the disk (written at another boundary, or before the ledger last changed) or naming another feature
# are flagged and not repeated.
#
# The RED is B4F-089's shape (router-skill project, 4a22ba8f): the notes said "at iteration-closeout ... starting now:
# validating and committing" while the disk held the closeout commit, the next iteration's plan commit and the plan
# decision pending. Two consecutive resumes repeated the notes.
#
# Driven through the real bootstrap provider (SessionStart) and the real `specrew start` resume block
# (Get-CoordinatorResumePromptBlock), in temp git projects.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'tests\bootstrap\TurnRecordTestSupport.ps1')
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
. (Join-Path $repoRoot 'scripts\internal\bootstrap\HandoverStore.ps1')
$provider = Join-Path $repoRoot 'scripts\internal\specrew-bootstrap-provider.ps1'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$staleNarrative = 'At iteration-closeout; the session stopped before that evidence was committed; starting now: validating and committing.'

function New-ResumeProject {
    # main holds only a README, so the feature branch is not merged (the notes stay valid by the freshness rules).
    param([string]$HandoverBoundary, [string]$HandoverFeature = '001-feat', [int]$NotesAgeMinutes = 60, [switch]$CommitsAfterNotes, [switch]$NoPending, [switch]$Ledger)
    $root = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('rfd-' + [guid]::NewGuid().ToString('N').Substring(0, 10))))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime'), (Join-Path $root '.specrew/handover') | Out-Null
    Set-Content -LiteralPath (Join-Path $root 'README.md') -Value '# project' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main; & git -C $root config user.email 't@t'; & git -C $root config user.name 't'; & git -C $root config core.autocrlf false
    & git -C $root add -A; & git -C $root commit -q -m 'readme'
    & git -C $root checkout -q -b 001-feat
    $feature = Join-Path $root 'specs/001-feat'
    New-Item -ItemType Directory -Force -Path (Join-Path $feature 'iterations/002'), (Join-Path $feature 'iterations/003') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $feature 'tasks.md') -Value (@('# Tasks', '', '- [x] T001 [owner: Implementer] **Parse the input.**', '- [x] T002 [owner: Implementer] **Write the report.**', '- [ ] T003 [owner: Implementer] **Route by skill.**', '- [ ] T004 [owner: Implementer] **Close out.**') -join "`n") -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $feature 'iterations/002/plan.md') -Value '# Iteration Plan: 002' -Encoding UTF8
    $plan003 = if ($Ledger) {
        (@('# Iteration Plan: 003', '', '## Tasks', '', '| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status |', '| --- | --- | --- | --- | --- | --- | --- | --- |',
            '| T020 | Plan the routing iteration | FR-001 | Routing | 0.5 | Planner | `specs/**` | done |',
            '| T021 | Wire the skill router | FR-001 | Routing | 1.0 | Implementer | `src/**` | in-progress |',
            '| T022 | Write the routing docs | FR-002 | Routing | 0.5 | Implementer | `docs/**` | pending |') -join "`n")
    }
    else { '# Iteration Plan: 003' }
    if ($Ledger) {
        # With -CommitsAfterNotes the plan arrives in its own later commit ('plan iteration 003').
        if (-not $CommitsAfterNotes) { Set-Content -LiteralPath (Join-Path $feature 'iterations/003/plan.md') -Value $plan003 -Encoding UTF8 }
        # Iteration 003's own ledger (task-progress.ps1: later iterations track their work here, not in the root list).
        Set-Content -LiteralPath (Join-Path $feature 'iterations/003/tasks-progress.yml') -Encoding UTF8 -Value (@(
            'schema: "v1"', 'feature: "001-feat"', 'iteration: "003"', 'updated_at: "2026-10-15T00:00:00Z"', 'tasks:',
            '  T020:', '    title: "Plan the routing iteration"', '    status: "done"', '    started_at: ""', '    completed_at: ""', '    blocked_reason: ""',
            '  T021:', '    title: "Wire the skill router"', '    status: "in-progress"', '    started_at: ""', '    completed_at: ""', '    blocked_reason: ""',
            '  T022:', '    title: "Write the routing docs"', '    status: "pending"', '    started_at: ""', '    completed_at: ""', '    blocked_reason: ""') -join "`n")
    }
    & git -C $root add -A; & git -C $root commit -q -m 'iteration 002 work'
    $notesCommit = ([string](& git -C $root rev-parse --short HEAD)).Trim()
    if ($CommitsAfterNotes) {
        Set-Content -LiteralPath (Join-Path $feature 'iterations/002/closeout.md') -Value '# Closeout' -Encoding UTF8
        & git -C $root add -A; & git -C $root commit -q -m 'closeout evidence for iteration 002'
        Set-Content -LiteralPath (Join-Path $feature 'iterations/003/plan.md') -Value $plan003 -Encoding UTF8
        & git -C $root add -A; & git -C $root commit -q -m 'plan iteration 003'
    }
    $head = ([string](& git -C $root rev-parse HEAD)).Trim()
    $ctx = [ordered]@{
        schema = 'v2'; feature_path = $feature
        session_state = [ordered]@{ active = $true; boundary_type = 'plan'; feature_ref = '001-feat'; host = 'claude'; iteration_number = '003'; auth_commit_hash = $head; recorded_at = '2026-10-14T00:00:00Z' }
        # With nothing pending, 'plan' is approved: a working boundary ahead of the last approved one IS a pending decision.
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = $(if ($NoPending) { 'plan' } else { 'iteration-closeout' }); pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
    if (-not $NoPending) {
        $tree = Get-SpecrewGitArtifactStateId -ProjectRoot $root -BoundaryCommitHash $head
        $scope = New-SpecrewPendingCrossingScope -LastAuthorizedBoundary 'iteration-closeout' -WorkingBoundary 'plan' -BoundaryCommitHash $head -ArtifactStateId $tree -RecordedAt ([DateTimeOffset]::UtcNow.AddMinutes(-5).ToString('o')) -ExistingScope $null
        $st = Get-SpecrewBoundaryEnforcementState -ProjectRoot $root
        $upd = [ordered]@{ enabled = $true; last_authorized_boundary = 'iteration-closeout'; pending_next_boundary = [string]$scope['to_boundary']; pending_crossing = $scope; verdict_history = @(); correction_history = @(); bypass_history = @() }
        Set-SpecrewBoundaryEnforcementState -ProjectRoot $root -BoundaryEnforcement $upd -Context $st.Context | Out-Null
        [IO.File]::WriteAllText((Join-Path $root '.specrew/runtime/pending-verdict-stop.md'), (@('# Specrew Pending Verdict Stop', '', 'Boundary to ask for: iteration-closeout -> plan', 'Human approval phrase: approved for plan', 'Marker last line exactly:', '<!-- SPECREW-VERDICT-BOUNDARY: iteration-closeout -> plan -->') -join "`n"), [Text.UTF8Encoding]::new($false))
    }
    $recorded = [DateTimeOffset]::UtcNow.AddMinutes(-$NotesAgeMinutes).ToString('o')
    $null = Write-SpecrewRollingHandover -HandoverDir (Join-Path $root '.specrew/handover') -Source 'Stop' -FromHost 'claude' -RecordedAt $recorded `
        -FromCommit $notesCommit -ActiveFeature $HandoverFeature -ActiveBoundary $HandoverBoundary `
        -MechanicalSections @{ 'Recommended next-immediate-step' = $staleNarrative; "Context the receiving host needs that artifacts don't carry" = 'The closeout evidence is not committed yet.' }
    return $root
}

function Invoke-SessionStart {
    param([string]$Root)
    $out = & pwsh -NoProfile -File $provider --turn-record (ConvertTo-SpecrewTestTurnRecordArgument -SessionId ('s-' + [guid]::NewGuid().ToString('N').Substring(0, 6)) -Source 'startup') --project-root $Root --host-kind claude 2>&1
    return (($out | ForEach-Object { [string]$_ }) -join "`n")
}

$roots = [Collections.Generic.List[string]]::new()
try {
    Write-Host 'Case 1: B4F-089 - notes at iteration-closeout, the disk at the pending plan decision with two commits since'
    $r1 = New-ResumeProject -HandoverBoundary 'iteration-closeout' -CommitsAfterNotes -Ledger; $roots.Add($r1)
    $o1 = Invoke-SessionStart $r1
    Assert-True ($o1 -match "(?i)where we are.*from disk") 'the resume carries a where-we-are section read from disk'
    Assert-True ($o1 -match "(?i)waiting for the human's decision on 'plan'") "it names the pending decision ('plan')"
    Assert-True ($o1 -match '2 commits since the previous session''s notes' -and $o1 -match 'plan iteration 003') 'it names the commits since the notes, newest first'
    Assert-True ($o1 -match 'Tasks: 1 of 3 done') 'it reports task progress from the current iteration''s ledger (round 4)'
    Assert-True ($o1 -match "(?i)Starting now: show the human the 'iteration-closeout -> plan' decision again") 'the starting-now line comes from the pending decision'
    Assert-True (-not $o1.Contains('starting now: validating and committing')) 'the stale notes are not repeated'
    Assert-True ($o1 -match "(?i)previous session's notes.*recorded 1 h ago.* older than the disk" -and $o1 -match "written at 'iteration-closeout'") 'the stale notes are flagged, with their age and why'

    Write-Host 'Case 2: notes that match the disk are shown as context, with their age'
    $r2 = New-ResumeProject -HandoverBoundary 'plan' -NotesAgeMinutes 12; $roots.Add($r2)
    $o2 = Invoke-SessionStart $r2
    Assert-True ($o2 -match "(?i)waiting for the human's decision on 'plan'") 'the disk position is still stated first'
    Assert-True ($o2 -match "(?i)context from the previous session, recorded 12 min ago") 'the notes are labelled as context with their age'
    Assert-True ($o2.Contains('starting now: validating and committing')) 'current notes are still shown'
    Assert-True ($o2 -notmatch '(?i)older than the disk') 'current notes are not flagged'

    Write-Host 'Case 3: notes written before the ledger last changed are flagged'
    $r3 = New-ResumeProject -HandoverBoundary 'plan' -NotesAgeMinutes 30; $roots.Add($r3)
    $ctx3 = Get-Content -LiteralPath (Join-Path $r3 '.specrew/start-context.json') -Raw | ConvertFrom-Json
    $ctx3.boundary_enforcement.verdict_history = @([pscustomobject]@{ authorized_boundary = 'iteration-closeout'; recorded_at = [DateTimeOffset]::UtcNow.AddMinutes(-10).ToString('o'); evidence_source = 'hook-captured-from-transcript' })
    [IO.File]::WriteAllText((Join-Path $r3 '.specrew/start-context.json'), ($ctx3 | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
    $o3 = Invoke-SessionStart $r3
    Assert-True ($o3 -match '(?i)older than the disk' -and $o3 -match '(?i)a decision was recorded after') 'notes older than the last ledger entry are flagged'
    Assert-True (-not $o3.Contains('starting now: validating and committing')) 'and not repeated'

    Write-Host 'Case 4: notes naming another feature are flagged and not repeated'
    $r4 = New-ResumeProject -HandoverBoundary 'plan' -HandoverFeature '099-other'; $roots.Add($r4)
    $o4 = Invoke-SessionStart $r4
    Assert-True ($o4 -match '099-other') 'the other feature is named in the flag'
    Assert-True (-not $o4.Contains('starting now: validating and committing')) 'its notes are not repeated'

    Write-Host 'Case 5: no pending decision - starting now is the next open task'
    # Co-review round 4 (202, FR-019): the session is in iteration 003, so its next task comes from iteration 003's own
    # ledger. Before, this case expected T003 from the root list, which is iteration 001's.
    $r5 = New-ResumeProject -HandoverBoundary 'plan' -NoPending -NotesAgeMinutes 5 -Ledger; $roots.Add($r5)
    $o5 = Invoke-SessionStart $r5
    Assert-True ($o5 -match "(?i)Starting now: T021 Wire the skill router") 'with nothing pending, the next open task of the current iteration is the starting point'
    Assert-True ($o5 -match "(?i)Tasks: 1 of 3 done") 'the progress line counts the current iteration''s ledger'

    Write-Host 'Case 7: a later iteration never takes its progress from the root task list (iteration 001''s)'
    $r7 = New-ResumeProject -HandoverBoundary 'plan' -NoPending -NotesAgeMinutes 5; $roots.Add($r7)
    $o7 = Invoke-SessionStart $r7
    Assert-True (-not ($o7 -match 'T003')) 'the stale unchecked T003 in the root list is not named for iteration 003'
    Assert-True (-not ($o7 -match '(?i)Tasks: 2 of 3 done')) 'the root list''s counts are not reported for iteration 003'

    Write-Host 'Case 6: the specrew start resume block says the same, from disk'
    . (Join-Path $repoRoot 'scripts\internal\coordinator-resume.ps1')
    $block = Get-CoordinatorResumePromptBlock -ProjectRoot $r1 -ResolvedFeaturePath (Join-Path $r1 'specs/001-feat') -SessionState ([pscustomobject]@{ feature_ref = '001-feat'; boundary_type = 'plan'; iteration_number = '003' })
    Assert-True ($block -match "(?i)waiting for the human's decision on 'plan'") 'specrew start names the pending decision'
    Assert-True ($block -match "(?i)Starting now: show the human the 'iteration-closeout -> plan' decision again") 'specrew start takes its starting point from disk'
    Assert-True ($block -match '(?i)older than the disk') 'specrew start flags the stale notes'
}
finally {
    foreach ($r in $roots) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue }
}
if ($script:failCount -gt 0) { Write-Host "resume-from-disk: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'resume-from-disk: all passed' -ForegroundColor Green
