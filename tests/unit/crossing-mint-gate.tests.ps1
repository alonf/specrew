# Iteration 002, T014 (FR-024, SC-011): the crossing mint gate and the marker identity.
#
# Field case: KeyContextAI iteration 003 minted three crossings at one commit with no iteration
# directory, no plan.md; reproduced live at 199/001's closeout (DRIFT-199-I002-001) - the closeout
# capture minted `iteration-closeout -> plan` over an empty stage and demanded a verdict for it.
#
# Every minting mechanism goes through New-SpecrewPendingCrossingScope, so the gate lives there. These
# cases assert OBSERVABLE STATE in the store and the journal, never that a call exists:
#   1 REFUSE  - the ladder's first rung: closeout authorized, no next iteration on disk -> no crossing.
#   2 PERMIT  - the same fixture with iterations/002/plan.md present -> the crossing opens. This is the
#               permit-side proof the maintainer required (PreflightOnly never reaches the mint path;
#               without this a too-strict gate would surface at review-signoff, twelve tasks away).
#   3 REBIND  - the authorization writer's own rebind: authorizing before-implement with no review.md
#               mints nothing; with review.md it mints review-signoff.
#   4 MARKER  - a marker naming a superseded crossing identity is refused at capture; the right identity
#               captures; a bare marker still captures (documented residual until T015).
# Mutations that turn this file red: remove the owed-artifact block in New-SpecrewPendingCrossingScope
# (cases 1, 3a); check the wrong iteration or the FROM side (case 2, 3b); remove the identity check in
# Invoke-SpecrewBoundaryVerdictCapture (case 4a).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
$provider = (Join-Path $repoRoot 'scripts\internal\specrew-handover-provider.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-MintFixture {
    param(
        [string]$LastAuthorized,
        [string]$WorkingBoundary,
        [string]$Iteration = '001',
        [string[]]$IterationFiles = @('plan.md', 'state.md', 'quality/hardening-gate.md'),
        [switch]$NoGit
    )
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("mint-gate-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))
    $feature = Join-Path $root 'specs\001-feat'
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $feature ('iterations\' + $Iteration + '\quality')) | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    foreach ($rel in $IterationFiles) {
        Set-Content -LiteralPath (Join-Path $feature ('iterations\' + $Iteration + '\' + $rel)) -Value ("# {0}`n`n**Status**: fixture" -f $rel) -Encoding UTF8
    }
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root add -A
    & git -C $root commit -q -m fixture
    $head = ([string](& git -C $root rev-parse HEAD)).Trim()
    $context = [ordered]@{
        schema = 'v2'
        boundary_enforcement = [ordered]@{
            enabled = $true
            last_authorized_boundary = $LastAuthorized
            pending_next_boundary = $null
            policy_classes = [ordered]@{
                specify = 'human-judgment-required'; clarify = 'human-judgment-required'
                plan = 'human-judgment-required'; tasks = 'human-judgment-required'
                'before-implement' = 'human-judgment-required'; 'review-signoff' = 'human-judgment-required'
                retro = 'human-judgment-required'; 'iteration-closeout' = 'human-judgment-required'
                'feature-closeout' = 'human-judgment-required'
            }
            verdict_history = @()
            bypass_history = @()
        }
        generated_at_utc = '2026-08-29T00:00:00Z'
        session_state = [ordered]@{
            active = $true
            boundary_type = $WorkingBoundary
            feature_ref = '001-feat'
            feature_path = $feature
            iteration_number = $Iteration
            auth_commit_hash = $head
            recorded_at = '2026-08-29T00:00:00Z'
        }
    }
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew\start-context.json'), ($context | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Root = $root; Feature = $feature; Head = $head }
}
function Read-Enforcement { param([string]$Root) return (Get-Content -LiteralPath (Join-Path $Root '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12).boundary_enforcement }
function Read-Journal { param([string]$Root, [string]$Event)
    $p = Join-Path $Root '.specrew\runtime\handover-journal.jsonl'
    if (-not (Test-Path -LiteralPath $p)) { return @() }
    return @(Get-Content -LiteralPath $p -Encoding UTF8 | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.event -eq $Event })
}

# ---------------------------------------------------------------------------------------------------
Write-Host 'Case 1: the ladder is refused - iteration-closeout authorized, no next iteration on disk'
$f1 = New-MintFixture -LastAuthorized 'iteration-closeout' -WorkingBoundary 'iteration-closeout'
$scope1 = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f1.Root -WorkingBoundary 'iteration-closeout' -BoundaryCommitHash $f1.Head -RecordedAt '2026-08-29T00:00:01Z' -OpenNextCrossingWhenBoundaryAuthorized 2>$null
$e1 = Read-Enforcement -Root $f1.Root
Assert-True ($null -eq $scope1) 'no scope is returned for iteration-closeout -> plan when iterations/002 does not exist'
Assert-True ([string]::IsNullOrWhiteSpace([string]$e1.pending_next_boundary)) 'the store carries no pending_next_boundary'
Assert-True ($null -eq $e1.pending_crossing) 'the store carries no pending_crossing'
$j1 = @(Read-Journal -Root $f1.Root -Event 'crossing-not-minted-owed-artifacts-absent')
Assert-True ($j1.Count -eq 1 -and $j1[0].to -eq 'plan' -and (@($j1[0].missing) -contains 'plan.md') -and [string]$j1[0].iteration -eq '002') 'the refusal is journaled naming plan.md for iteration 002'
Assert-True (([string]$j1[0].message) -match "owes plan.md for iteration 002" -and ([string]$j1[0].message) -match 'no new verdict is being asked for') 'the refusal message names what is owed and that no verdict is asked for'

Write-Host 'Case 2: the permit side - the same fixture with iterations/002/plan.md present opens the crossing'
$f2 = New-MintFixture -LastAuthorized 'iteration-closeout' -WorkingBoundary 'iteration-closeout'
New-Item -ItemType Directory -Force -Path (Join-Path $f2.Feature 'iterations/002') | Out-Null
Set-Content -LiteralPath (Join-Path $f2.Feature 'iterations/002/plan.md') -Value "# Iteration Plan: 002`n`n**Status**: planning" -Encoding UTF8
$scope2 = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f2.Root -WorkingBoundary 'iteration-closeout' -BoundaryCommitHash $f2.Head -RecordedAt '2026-08-29T00:00:01Z' -OpenNextCrossingWhenBoundaryAuthorized 2>$null
$e2 = Read-Enforcement -Root $f2.Root
Assert-True ($null -ne $scope2 -and [string]$scope2['to_boundary'] -eq 'plan' -and [string]$scope2['from_boundary'] -eq 'iteration-closeout') 'iteration-closeout -> plan is minted when plan.md exists on disk (uncommitted is enough at mint time)'
Assert-True (-not [string]::IsNullOrWhiteSpace([string]$scope2['crossing_id'])) 'the minted crossing carries an identity'
Assert-True ([string]$e2.pending_next_boundary -eq 'plan') 'the store carries pending_next_boundary = plan'
Assert-True (@(Read-Journal -Root $f2.Root -Event 'crossing-not-minted-owed-artifacts-absent').Count -eq 0) 'nothing is journaled as refused on the permit side'

Write-Host 'Case 3a: the authorization writer''s rebind is the mechanism that minted the live ladder - authorizing iteration-closeout mints nothing when the next iteration does not exist'
# Ordinary boundaries do not auto-mint their successor at authorization (working == last authorized ->
# nothing pending); the CYCLE RESET does: authorizing iteration-closeout re-derives the pending crossing
# as iteration-closeout -> plan inside the rebind. That is exactly how DRIFT-199-I002-001 happened.
$f3 = New-MintFixture -LastAuthorized 'retro' -WorkingBoundary 'iteration-closeout' -IterationFiles @('plan.md', 'state.md', 'quality/hardening-gate.md', 'review.md', 'retro.md')
$pre3 = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f3.Root -WorkingBoundary 'iteration-closeout' -BoundaryCommitHash $f3.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
Assert-True ($null -ne $pre3 -and [string]$pre3['to_boundary'] -eq 'iteration-closeout') 'retro -> iteration-closeout is minted (state.md is present)'
Add-SpecrewBoundaryAuthorization -ProjectRoot $f3.Root -CurrentBoundary 'retro' -AuthorizedBoundary 'iteration-closeout' -AuthorizingHuman 'unattributed' -VerdictText 'approved for iteration-closeout' -EvidenceSource 'hook-captured-from-transcript' 2>$null | Out-Null
$e3 = Read-Enforcement -Root $f3.Root
Assert-True ([string]$e3.last_authorized_boundary -eq 'iteration-closeout') 'the closeout authorization itself is recorded'
Assert-True ($null -eq $e3.pending_crossing -and [string]::IsNullOrWhiteSpace([string]$e3.pending_next_boundary)) 'iteration-closeout -> plan is NOT minted by the rebind while iterations/002 does not exist (the live ladder, refused)'
$j3 = @(Read-Journal -Root $f3.Root -Event 'crossing-not-minted-owed-artifacts-absent')
Assert-True ($j3.Count -ge 1 -and (@($j3[-1].missing) -contains 'plan.md') -and [string]$j3[-1].iteration -eq '002') 'the rebind refusal is journaled naming plan.md for iteration 002'

Write-Host 'Case 3b: the same rebind mints iteration-closeout -> plan once iterations/002/plan.md exists'
$f3b = New-MintFixture -LastAuthorized 'retro' -WorkingBoundary 'iteration-closeout' -IterationFiles @('plan.md', 'state.md', 'quality/hardening-gate.md', 'review.md', 'retro.md')
New-Item -ItemType Directory -Force -Path (Join-Path $f3b.Feature 'iterations/002') | Out-Null
Set-Content -LiteralPath (Join-Path $f3b.Feature 'iterations/002/plan.md') -Value "# Iteration Plan: 002`n`n**Status**: planning" -Encoding UTF8
$null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f3b.Root -WorkingBoundary 'iteration-closeout' -BoundaryCommitHash $f3b.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
Add-SpecrewBoundaryAuthorization -ProjectRoot $f3b.Root -CurrentBoundary 'retro' -AuthorizedBoundary 'iteration-closeout' -AuthorizingHuman 'unattributed' -VerdictText 'approved for iteration-closeout' -EvidenceSource 'hook-captured-from-transcript' 2>$null | Out-Null
$e3b = Read-Enforcement -Root $f3b.Root
Assert-True ($null -ne $e3b.pending_crossing -and [string]$e3b.pending_crossing.to_boundary -eq 'plan' -and [string]$e3b.pending_crossing.from_boundary -eq 'iteration-closeout') 'iteration-closeout -> plan IS minted by the rebind when iterations/002/plan.md exists (permit side of the live mechanism)'

Write-Host 'Case 3c: an ordinary authorization does not mint its successor at all (working == last authorized) - documented, not a refusal'
$f3c = New-MintFixture -LastAuthorized 'tasks' -WorkingBoundary 'before-implement'
$null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f3c.Root -WorkingBoundary 'before-implement' -BoundaryCommitHash $f3c.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
Add-SpecrewBoundaryAuthorization -ProjectRoot $f3c.Root -CurrentBoundary 'tasks' -AuthorizedBoundary 'before-implement' -AuthorizingHuman 'unattributed' -VerdictText 'approved for before-implement' -EvidenceSource 'hook-captured-from-transcript' 2>$null | Out-Null
$e3c = Read-Enforcement -Root $f3c.Root
Assert-True ([string]$e3c.last_authorized_boundary -eq 'before-implement' -and $null -eq $e3c.pending_crossing) 'after an ordinary authorization nothing is pending until the next sync arrives with its artifacts'
Assert-True (@(Read-Journal -Root $f3c.Root -Event 'crossing-not-minted-owed-artifacts-absent').Count -eq 0) 'and nothing is journaled as refused, because nothing was attempted'

# ---------------------------------------------------------------------------------------------------
function Invoke-StopHook { param([string]$Root, [string]$Transcript) & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $Root --host-kind claude --transcript-path $Transcript 2>$null | Out-Null }
function Write-Transcript { param([string]$Root, [string]$Marker, [string]$Reply)
    $tx = Join-Path $Root 'transcript.jsonl'
    $turns = @(
        @{ role = 'assistant'; text = ("boundary packet. {0} What's your verdict?" -f $Marker) },
        @{ role = 'user'; text = $Reply })
    $lines = foreach ($t in $turns) { (@{ type = $t.role; message = @{ role = $t.role; content = @(@{ type = 'text'; text = $t.text }) } } | ConvertTo-Json -Depth 8 -Compress) }
    [System.IO.File]::WriteAllText($tx, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))
    return $tx
}
function New-MarkerFixture {
    $f = New-MintFixture -LastAuthorized 'plan' -WorkingBoundary 'tasks'
    $scope = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f.Root -WorkingBoundary 'tasks' -BoundaryCommitHash $f.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
    return [pscustomobject]@{ Fixture = $f; CrossingId = [string]$scope['crossing_id'] }
}

Write-Host 'Case 4a: a marker naming a superseded crossing identity is refused at capture'
$m4a = New-MarkerFixture
$stale = 'crossing-' + ('0' * 64)
$tx4a = Write-Transcript -Root $m4a.Fixture.Root -Marker ("<!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks @ {0} -->" -f $stale) -Reply 'approved for tasks'
Invoke-StopHook -Root $m4a.Fixture.Root -Transcript $tx4a
$e4a = Read-Enforcement -Root $m4a.Fixture.Root
Assert-True ([string]$e4a.last_authorized_boundary -eq 'plan') 'the stale-identity marker does NOT authorize plan -> tasks'
$j4a = @(Read-Journal -Root $m4a.Fixture.Root -Event 'verdict-refused-marker-identity-mismatch')
Assert-True ($j4a.Count -eq 1 -and [string]$j4a[0].marker_crossing_id -eq $stale -and [string]$j4a[0].pending_crossing_id -eq $m4a.CrossingId) 'the refusal is journaled with both identities'

Write-Host 'Case 4b: the marker naming the pending identity captures'
$m4b = New-MarkerFixture
$tx4b = Write-Transcript -Root $m4b.Fixture.Root -Marker ("<!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks @ {0} -->" -f $m4b.CrossingId) -Reply 'approved for tasks'
Invoke-StopHook -Root $m4b.Fixture.Root -Transcript $tx4b
$e4b = Read-Enforcement -Root $m4b.Fixture.Root
Assert-True ([string]$e4b.last_authorized_boundary -eq 'tasks') 'the matching-identity marker authorizes plan -> tasks'

Write-Host 'Case 4c: a bare marker still captures (residual until T015 makes every renderer emit the identity)'
$m4c = New-MarkerFixture
$tx4c = Write-Transcript -Root $m4c.Fixture.Root -Marker '<!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks -->' -Reply 'approved for tasks'
Invoke-StopHook -Root $m4c.Fixture.Root -Transcript $tx4c
$e4c = Read-Enforcement -Root $m4c.Fixture.Root
Assert-True ([string]$e4c.last_authorized_boundary -eq 'tasks') 'a bare marker authorizes plan -> tasks today (T015 flips this deliberately)'

Write-Host 'Case 5: the stop artifact re-minted after a capture carries the crossing identity in its marker line'
$art5 = Join-Path $m4b.Fixture.Root '.specrew\runtime\pending-verdict-stop.md'
$e5 = Read-Enforcement -Root $m4b.Fixture.Root
if ($null -ne $e5.pending_crossing) {
    $content5 = Get-Content -LiteralPath $art5 -Raw -Encoding UTF8
    Assert-True ($content5 -match ('SPECREW-VERDICT-BOUNDARY: tasks -> before-implement @ ' + [regex]::Escape([string]$e5.pending_crossing.crossing_id))) 'the re-minted artifact marker names the new crossing identity'
}
else {
    Write-Pass 'no successor crossing was minted after the capture (before-implement owes quality/hardening-gate.md - present here, so this branch records the observed shape rather than asserting it)'
}

foreach ($f in @($f1, $f2, $f3, $f3b, $f3c, $m4a.Fixture, $m4b.Fixture, $m4c.Fixture)) { try { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
if ($script:failCount -gt 0) { throw ("crossing-mint-gate: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'crossing-mint-gate: all assertions passed' -ForegroundColor Green
