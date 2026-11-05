# Feature 203 iteration 001, T004 (FR-021, FR-022, FR-025): the re-deriving writer and the supersession fact.
#
# Two cases this project met, each RED against the build before T004:
#   1 THE CITED TURN (spec US2 scenario 5, FR-022). An agent cites the maintainer's real `confirm` turn and asks a writer
#     for a verdict. Today the boundary writer takes a captured evidence label on the caller's word and records the
#     verdict. After T004 a captured label is honoured only by re-reading the cited turn and re-deriving its act through
#     the classifier (Resolve-SpecrewTypedAct): `confirm` is no verdict, so nothing is recorded; the real typed verdict
#     is recorded once and a second citation of it is already-recorded.
#   2 THE RE-TYPED ROUND APPROVAL (02:44 local, 2026-11-02; DRIFT-019, DRIFT-023; FR-021). The 21:47 approval had minted
#     round 4 and its reservation was released before invocation. The maintainer typed the approval again; the capture
#     writer returned the older record and wrote nothing, and the relaunch ran on the 21:47 approval. After T004 the
#     newer typed act writes its own capture and an immutable supersession fact retires the older one. The relaunch
#     (maintainer's instruction, 2026-11-03, option 1) keeps the same round number, reuses the grant's slot as its next
#     reservation generation (no second grant, no second slot), and the run is cited through the newer approval's own
#     record: it carries the round reference and, once spent, the run's id. The engine's record formats are unchanged;
#     the run record naming the approval itself is T012's.
#
# Each case runs in a temporary project root; the launches run the real review CLI from this checkout in a fixture
# with no commit, so preflight refuses before any reviewer is invoked (an undelivered round, released). Never the
# repository's own stores: a host's project-root variables are cleared in this process and in every child launch (run
# inside a Claude session, CLAUDE_PROJECT_DIR names the real worktree), and the suite fails if the real worktree's
# round-approval store or the real ~/.specrew changed during the run.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }
$script:roots = [System.Collections.Generic.List[string]]::new()

# The host project-root variables, as the T001 probes cleared them; any other *_PROJECT_DIR is cleared too.
$script:hostRootVariablePattern = '^(CLAUDE_PROJECT_DIR|CURSOR_PROJECT_DIR|COPILOT_PROJECT_DIR|\w+_PROJECT_DIR)$'
$script:clearedHostRoots = [ordered]@{}
foreach ($entry in @(Get-ChildItem Env: | Where-Object { $_.Name -match $script:hostRootVariablePattern })) {
    $script:clearedHostRoots[$entry.Name] = [string]$entry.Value
    Remove-Item -LiteralPath ('Env:' + $entry.Name) -ErrorAction SilentlyContinue
}

# The real stores this suite must never touch: the round-approval store of this checkout and of any project a cleared
# variable named (the real worktree when run inside a session), and the real user profile's .specrew, resolved from the
# OS rather than from USERPROFILE so a lane's redirected home does not hide it.
$script:guardedPaths = [System.Collections.Generic.List[string]]::new()
foreach ($projectRoot in @(@($repoRoot) + @($script:clearedHostRoots.Values) | Where-Object { $_ } | ForEach-Object { [IO.Path]::GetFullPath($_) } | Sort-Object -Unique)) {
    $script:guardedPaths.Add((Join-Path $projectRoot '.specrew\review\round-approval'))
}
$script:guardedPaths.Add((Join-Path ([Environment]::GetFolderPath('UserProfile')) '.specrew'))
function Get-GuardSnapshot {
    $lines = foreach ($path in $script:guardedPaths) {
        if (-not (Test-Path -LiteralPath $path)) { "$path|absent"; continue }
        foreach ($item in @(Get-ChildItem -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue)) {
            if ($item.PSIsContainer) { "$($item.FullName)|dir" }
            else { '{0}|{1}|{2}' -f $item.FullName, $item.Length, $item.LastWriteTimeUtc.Ticks }
        }
    }
    return @($lines | Sort-Object)
}
$script:guardBefore = Get-GuardSnapshot

. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
. (Join-Path $repoRoot 'scripts\internal\bootstrap\HumanAuthorityStore.ps1')
$reviewCli = Join-Path $repoRoot 'scripts\specrew-review.ps1'

# A writer parameter T004 adds is passed only when the writer has it, so the RED is the behaviour, not a binding error.
function Add-IfSupported {
    param([hashtable]$Splat, [string]$Command, [string]$Name, $Value)
    if ((Get-Command $Command).Parameters.ContainsKey($Name)) { $Splat[$Name] = $Value }
}

# ---------------------------------------------------------------------------------------------------
# Case 1 fixture: a project waiting at tasks -> before-implement, and the host's record of two typed turns.
function New-CitedTurnFixture {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ('t004-cite-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $script:roots.Add($root)
    $feature = Join-Path $root 'specs\001-feat'
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $feature 'iterations\001\quality') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    foreach ($rel in 'plan.md', 'state.md', 'quality/hardening-gate.md') {
        Set-Content -LiteralPath (Join-Path $feature ('iterations\001\' + $rel)) -Value ("# {0}`n`n**Status**: fixture" -f $rel) -Encoding UTF8
    }
    Set-Content -LiteralPath (Join-Path $feature 'tasks.md') -Value "# Tasks`n`n- [ ] T001 fixture" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root -c core.autocrlf=false add -A
    & git -C $root commit -q -m fixture
    $head = ([string](& git -C $root rev-parse HEAD)).Trim()
    $context = [ordered]@{
        schema = 'v2'
        boundary_enforcement = [ordered]@{
            enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null
            policy_classes = [ordered]@{
                specify = 'human-judgment-required'; clarify = 'human-judgment-required'; plan = 'human-judgment-required'
                tasks = 'human-judgment-required'; 'before-implement' = 'human-judgment-required'
                'review-signoff' = 'human-judgment-required'; retro = 'human-judgment-required'
                'iteration-closeout' = 'human-judgment-required'; 'feature-closeout' = 'human-judgment-required'
            }
            verdict_history = @(); bypass_history = @()
        }
        generated_at_utc = '2026-11-02T00:00:00Z'
        session_state = [ordered]@{
            active = $true; boundary_type = 'before-implement'; feature_ref = '001-feat'; feature_path = $feature
            iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-11-02T00:00:00Z'
        }
    }
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew\start-context.json'), ($context | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    $null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $root -WorkingBoundary 'before-implement' -BoundaryCommitHash $head -RecordedAt '2026-11-02T00:00:01Z' 2>$null

    # The host's record: Claude's transcript, in the recorded shape (tests/fixtures/hook-payloads/claude/queued).
    $session = 'session-t004'
    $lines = @(
        [ordered]@{ type = 'assistant'; uuid = 'a-1'; sessionId = $session; timestamp = '2026-11-02T08:00:00.000Z'
            message = [ordered]@{ role = 'assistant'; content = @([ordered]@{ type = 'text'; text = 'Does this agenda look right?' }) } }
        [ordered]@{ type = 'user'; uuid = 'u-confirm'; promptId = 'prompt-confirm'; sessionId = $session; timestamp = '2026-11-02T08:01:00.000Z'
            origin = [ordered]@{ kind = 'human' }; turnOrigin = 'human'; message = [ordered]@{ role = 'user'; content = 'confirm' } }
        [ordered]@{ type = 'assistant'; uuid = 'a-2'; sessionId = $session; timestamp = '2026-11-02T08:02:00.000Z'
            message = [ordered]@{ role = 'assistant'; content = @([ordered]@{ type = 'text'; text = 'Type approved for before-implement to start.' }) } }
        [ordered]@{ type = 'user'; uuid = 'u-verdict'; promptId = 'prompt-verdict'; sessionId = $session; timestamp = '2026-11-02T08:03:00.000Z'
            origin = [ordered]@{ kind = 'human' }; turnOrigin = 'human'; message = [ordered]@{ role = 'user'; content = 'approved for before-implement' } }
    )
    $transcript = Join-Path $root 'transcript.jsonl'
    [System.IO.File]::WriteAllLines($transcript, [string[]]@($lines | ForEach-Object { $_ | ConvertTo-Json -Depth 8 -Compress }), [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Root = $root; Transcript = $transcript; Session = $session }
}
function Get-VerdictHistory {
    param([string]$Root)
    $ctx = Get-Content -LiteralPath (Join-Path $Root '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
    return @($ctx.boundary_enforcement.verdict_history | Where-Object { $null -ne $_ })
}
function Invoke-AgentBoundaryWrite {
    # What an agent can do today: dot-source the writer and call it with a captured evidence label.
    param($Fixture, [string]$TurnIdentity)
    $splat = @{
        ProjectRoot = $Fixture.Root; CurrentBoundary = 'tasks'; AuthorizedBoundary = 'before-implement'; AuthorizingHuman = 'unattributed'
        VerdictText = 'approved for before-implement'; EvidenceSource = 'hook-captured-from-transcript'
    }
    if ($TurnIdentity) {
        Add-IfSupported -Splat $splat -Command 'Add-SpecrewBoundaryAuthorization' -Name 'TurnIdentity' -Value $TurnIdentity
        Add-IfSupported -Splat $splat -Command 'Add-SpecrewBoundaryAuthorization' -Name 'TranscriptPath' -Value $Fixture.Transcript
        Add-IfSupported -Splat $splat -Command 'Add-SpecrewBoundaryAuthorization' -Name 'HostKind' -Value 'claude'
    }
    try { $null = Add-SpecrewBoundaryAuthorization @splat 2>$null; return 'returned' } catch { return ('refused: ' + $_.Exception.Message) }
}

Write-Host '--- case 1: an agent cites the real `confirm` turn to a writer (FR-022) ---'
$f1 = New-CitedTurnFixture
$outcome1 = Invoke-AgentBoundaryWrite -Fixture $f1 -TurnIdentity 'prompt-confirm'
Assert-True (@(Get-VerdictHistory -Root $f1.Root).Count -eq 0) "citing the 'confirm' turn records no verdict (writer $outcome1)"

$f1b = New-CitedTurnFixture
$outcome1b = Invoke-AgentBoundaryWrite -Fixture $f1b -TurnIdentity ''
Assert-True (@(Get-VerdictHistory -Root $f1b.Root).Count -eq 0) "a captured label with no cited turn records no verdict (writer $outcome1b)"

$hasWriter = $null -ne (Get-Command 'Write-SpecrewTypedAct' -ErrorAction SilentlyContinue)
Assert-True $hasWriter 'Write-SpecrewTypedAct exists: the only writer for the recovery paths'
if ($hasWriter) {
    $f1c = New-CitedTurnFixture
    $confirm = Write-SpecrewTypedAct -ProjectRoot $f1c.Root -HostKind 'claude' -TurnIdentity 'prompt-confirm' -TranscriptPath $f1c.Transcript
    Assert-True ([string]$confirm.Act.Kind -cne 'boundary-verdict' -and -not [bool]$confirm.Written) ("the re-derived act of 'confirm' is no verdict and nothing is written (got {0}/{1})" -f $confirm.Act.Kind, $confirm.Act.Reason)
    Assert-True (@(Get-VerdictHistory -Root $f1c.Root).Count -eq 0) "the ledger holds no verdict after citing 'confirm'"

    $typed = Write-SpecrewTypedAct -ProjectRoot $f1c.Root -HostKind 'claude' -TurnIdentity 'prompt-verdict' -TranscriptPath $f1c.Transcript
    $history = @(Get-VerdictHistory -Root $f1c.Root)
    Assert-True ([string]$typed.Act.Kind -ceq 'boundary-verdict' -and [bool]$typed.Written -and $history.Count -eq 1) 'the real typed verdict, cited, is recorded once'
    Assert-True ($history.Count -eq 1 -and $history[0].PSObject.Properties['turn_identity'] -and [string]$history[0].turn_identity -ceq [string]$typed.Act.TurnIdentity) 'the ledger entry carries the turn identity it was derived from'
    $again = Write-SpecrewTypedAct -ProjectRoot $f1c.Root -HostKind 'claude' -TurnIdentity 'prompt-verdict' -TranscriptPath $f1c.Transcript
    Assert-True (-not [bool]$again.Written -and [string]$again.Act.Reason -ceq 'already-recorded' -and @(Get-VerdictHistory -Root $f1c.Root).Count -eq 1) 'citing the same turn again records nothing (already-recorded)'
    $unknown = Write-SpecrewTypedAct -ProjectRoot $f1c.Root -HostKind 'claude' -TurnIdentity 'prompt-not-in-the-record' -TranscriptPath $f1c.Transcript
    Assert-True (-not [bool]$unknown.Written -and @(Get-VerdictHistory -Root $f1c.Root).Count -eq 1) ("a turn the host's record does not hold mints nothing (got {0})" -f $unknown.Act.Reason)
}

# ---------------------------------------------------------------------------------------------------
# Case 2 fixture: a review campaign with no commit, so every launch is released before invocation.
function New-CampaignFixture {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ('t004-round-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $script:roots.Add($root)
    New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-fixture/iterations/001') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"" -Encoding UTF8
    & git init -q -b 001-fixture $root 2>&1 | Out-Null
    return $root
}
function Invoke-AgentLaunch {
    # -File, so --live and --approve-round reach the CLI's own argument parser; an agent session, as the crew runs it.
    param([string]$Root)
    # The child clears the host project-root variables itself as well, so nothing it inherits names the real worktree.
    $command = "Get-ChildItem Env: | Where-Object { `$_.Name -match '$($script:hostRootVariablePattern)' } | ForEach-Object { Remove-Item -LiteralPath ('Env:' + `$_.Name) }; " +
        "`$env:CLAUDECODE = '1'; pwsh -NoProfile -File '$reviewCli' -ProjectPath '$Root' -FeatureId 001-fixture --live --approve-round; exit `$LASTEXITCODE"
    $output = @(& pwsh -NoProfile -Command $command 2>&1 | ForEach-Object { [string]$_ })
    $text = $output -join "`n"
    $runId = if ($text -match 'Run: (run-\S+)') { $Matches[1] } else { '' }
    return [pscustomobject]@{ Text = $text; RunId = $runId }
}
function Write-TypedRoundApproval {
    param([string]$Root, [string]$NowUtc, [string]$TurnIdentity)
    $splat = @{ ProjectRoot = $Root; Response = 'approved for review round'; HostKind = 'claude'; SourceEvent = 'UserPromptSubmit'; NowUtc = $NowUtc }
    Add-IfSupported -Splat $splat -Command 'Write-SpecrewReviewRoundApprovalAuthorization' -Name 'TurnIdentity' -Value $TurnIdentity
    return Write-SpecrewReviewRoundApprovalAuthorization @splat
}
function Test-SameInstant { param($Value, [string]$Expected)
    $instant = ConvertTo-SpecrewAuthorityInstant -Value $Value
    return ($null -ne $instant -and ([DateTimeOffset]$instant).UtcDateTime -eq ([DateTimeOffset]::Parse($Expected)).UtcDateTime)
}
function Read-Captures { param([string]$Root)
    $path = Join-Path $Root '.specrew/review/round-approval/captures.jsonl'
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    return @(Get-Content -LiteralPath $path -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json -Depth 8 })
}
function Read-Pending { param([string]$Root)
    return Get-Content -LiteralPath (Join-Path $Root '.specrew/review/round-approval/pending-round-approval.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8
}

Write-Host '--- case 2: the re-typed round approval (02:44 local, 2026-11-02; FR-021) ---'
$older = '2026-11-01T19:47:39.0000000+00:00'   # 21:47:39 local
$newer = '2026-11-02T00:44:14.0000000+00:00'   # 02:44:14 local
$r2 = New-CampaignFixture
$null = Write-TypedRoundApproval -Root $r2 -NowUtc $older -TurnIdentity 'turn-2147'
$launch1 = Invoke-AgentLaunch -Root $r2
$campaign = Join-Path $r2 '.specrew/review/authority/campaigns/cmp-001-fixture-i001'
$roundRef = 'cmp-001-fixture-i001-round-1'
$grants1 = @(Get-ChildItem -LiteralPath (Join-Path $campaign 'grants') -Filter '*.json' -File -ErrorAction SilentlyContinue)
Assert-True ($grants1.Count -eq 1 -and [string](Read-Pending -Root $r2).minted_ref -ceq $roundRef) 'setup: the 21:47 approval minted round 1 and its grant; the launch was released before invocation'

$retyped = Write-TypedRoundApproval -Root $r2 -NowUtc $newer -TurnIdentity 'turn-0244'
Assert-True ($null -ne $retyped -and (Test-SameInstant -Value $retyped.observed_at -Expected $newer)) 'the re-typed approval is its own capture, not the 21:47 record returned'
$captures = @(Read-Captures -Root $r2)
$approvalLines = @($captures | Where-Object { [string]$_.fact_type -ceq 'review-round-approval' })
Assert-True (@($approvalLines | Where-Object { Test-SameInstant -Value $_.observed_at -Expected $newer }).Count -eq 1) 'the capture journal holds a line for the 02:44 approval'
$supersession = @($captures | Where-Object { [string]$_.fact_type -ceq 'review-round-approval-superseded' })
Assert-True ($supersession.Count -eq 1 -and
    $supersession[0].PSObject.Properties['superseded_observed_at'] -and (Test-SameInstant -Value $supersession[0].superseded_observed_at -Expected $older) -and
    $supersession[0].PSObject.Properties['superseded_by_observed_at'] -and (Test-SameInstant -Value $supersession[0].superseded_by_observed_at -Expected $newer)) 'one immutable supersession fact retires the 21:47 approval in favour of the 02:44 one'
$pending = Read-Pending -Root $r2
Assert-True ((Test-SameInstant -Value $pending.observed_at -Expected $newer) -and [string]::IsNullOrWhiteSpace([string]$pending.minted_ref) -and [string]::IsNullOrWhiteSpace([string]$pending.spent_at)) 'the waiting slot holds the 02:44 approval, unminted and unspent'
$standing = Get-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $r2
Assert-True ($null -ne $standing -and (Test-SameInstant -Value $standing.observed_at -Expected $newer)) 'the spender sees only the newest approval'

$launch2 = Invoke-AgentLaunch -Root $r2
Assert-True ($launch2.Text -match [regex]::Escape("recorded it as $roundRef")) 'the relaunch keeps the same round number'
$grants2 = @(Get-ChildItem -LiteralPath (Join-Path $campaign 'grants') -Filter '*.json' -File -ErrorAction SilentlyContinue)
$grantId = if ($grants2.Count -eq 1) { [IO.Path]::GetFileNameWithoutExtension($grants2[0].Name) } else { '' }
$slots = @(if ($grantId) { Get-ChildItem -LiteralPath (Join-Path $campaign "reservations/$grantId") -Directory -ErrorAction SilentlyContinue })
$generations = @(if ($slots.Count -eq 1) { Get-ChildItem -LiteralPath $slots[0].FullName -Filter 'generation-*.json' -File | Sort-Object Name })
Assert-True ($grants2.Count -eq 1 -and $slots.Count -eq 1 -and $slots[0].Name -ceq 'slot-001') 'no second grant and no second slot'
$gen2 = if ($generations.Count -eq 2) { Get-Content -LiteralPath $generations[1].FullName -Raw | ConvertFrom-Json } else { $null }
Assert-True ($generations.Count -eq 2 -and $generations[1].Name -ceq 'generation-002.json' -and $null -ne $gen2 -and [string]$gen2.run_id -ceq $launch2.RunId -and $launch2.RunId) 'the relaunch reserves the same slot as its next generation'
$pendingAfter = Read-Pending -Root $r2
Assert-True ((Test-SameInstant -Value $pendingAfter.observed_at -Expected $newer) -and [string]$pendingAfter.minted_ref -ceq $roundRef) 'the round reference is stamped on the 02:44 approval'

# The run is cited through the approval's own record: spending names the run (the CLI passes it at consumption).
$completeSplat = @{ ProjectRoot = $r2; AuthorizationRef = $roundRef }
Add-IfSupported -Splat $completeSplat -Command 'Complete-SpecrewReviewRoundApprovalAuthorization' -Name 'RunId' -Value $launch2.RunId
$spent = Complete-SpecrewReviewRoundApprovalAuthorization @completeSplat
$spentRecord = Read-Pending -Root $r2
Assert-True ([bool]$spent.consumed -and (Test-SameInstant -Value $spentRecord.observed_at -Expected $newer) -and
    $spentRecord.PSObject.Properties['run_id'] -and [string]$spentRecord.run_id -ceq $launch2.RunId) 'the spent 02:44 approval names the run it paid for'
$citing = @(Read-Captures -Root $r2 | Where-Object { $_.PSObject.Properties['run_id'] -and [string]$_.run_id -ceq $launch2.RunId })
$citesNewer = { param($line) if ($line.PSObject.Properties['approval_observed_at']) { Test-SameInstant -Value $line.approval_observed_at -Expected $newer } else { Test-SameInstant -Value $line.observed_at -Expected $newer } }
Assert-True ($citing.Count -ge 1 -and @($citing | Where-Object { -not (& $citesNewer $_) }).Count -eq 0) 'no record ties the run to the superseded 21:47 approval'
$cliSource = Get-Content -LiteralPath $reviewCli -Raw
Assert-True ($cliSource -match 'Complete-SpecrewReviewRoundApprovalAuthorization -ProjectRoot \$resolvedProjectPath -AuthorizationRef \$campaignGrantAuthorizationRef -RunId') 'the review CLI passes the run to the consumption after a delivered round'

# ---------------------------------------------------------------------------------------------------
# Case 3 (the round-7 shape; maintainer's finding on dbc4cd3b, 2026-11-03): approval A minted round 7, the maintainer
# typed approval B while round 7 ran, and B took the waiting slot. When round 7 completes with A's reference, the spend
# belongs to A: B stays unspent and usable, and the spent line names A, never B.
Write-Host '--- case 3: an approval typed while the round runs (the round-7 shape) ---'
$atA = '2026-11-02T12:30:00.0000000+00:00'   # 14:30 local
$atB = '2026-11-02T12:45:00.0000000+00:00'   # 14:45 local, while round 7 runs
$r3 = New-CampaignFixture
$null = Write-TypedRoundApproval -Root $r3 -NowUtc $atA -TurnIdentity 'turn-A'
$null = Set-SpecrewReviewRoundApprovalMintedRef -ProjectRoot $r3 -AuthorizationRef 'cmp-x-round-7'
$null = Write-TypedRoundApproval -Root $r3 -NowUtc $atB -TurnIdentity 'turn-B'
$completeA = @{ ProjectRoot = $r3; AuthorizationRef = 'cmp-x-round-7' }
Add-IfSupported -Splat $completeA -Command 'Complete-SpecrewReviewRoundApprovalAuthorization' -Name 'RunId' -Value 'run-round-7'
$spentA = Complete-SpecrewReviewRoundApprovalAuthorization @completeA
$slot3 = Read-Pending -Root $r3
Assert-True ((Test-SameInstant -Value $slot3.observed_at -Expected $atB) -and [string]::IsNullOrWhiteSpace([string]$slot3.spent_at) -and
    [string]::IsNullOrWhiteSpace([string]$slot3.minted_ref) -and -not ($slot3.PSObject.Properties['run_id'] -and $slot3.run_id)) 'B, typed while round 7 ran, stays unspent and unminted when round 7 completes'
$standing3 = Get-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $r3
Assert-True ($null -ne $standing3 -and (Test-SameInstant -Value $standing3.observed_at -Expected $atB)) 'B is still the standing approval for the next round'
$spentLines3 = @(Read-Captures -Root $r3 | Where-Object { [string]$_.fact_type -ceq 'review-round-approval-spent' })
Assert-True ($spentLines3.Count -eq 1 -and [string]$spentLines3[0].run_id -ceq 'run-round-7' -and [string]$spentLines3[0].authorization_ref -ceq 'cmp-x-round-7' -and
    (Test-SameInstant -Value $spentLines3[0].approval_observed_at -Expected $atA) -and [string]$spentLines3[0].approval_turn_identity -ceq 'turn-A') 'the spent line names A, the approval round 7 was minted from'
Assert-True ([bool]$spentA.consumed) ("the spend of the superseded approval is reported as recorded (got {0})" -f $spentA.reason)
$againA = Complete-SpecrewReviewRoundApprovalAuthorization @completeA
Assert-True (@(Read-Captures -Root $r3 | Where-Object { [string]$_.fact_type -ceq 'review-round-approval-spent' }).Count -eq 1 -and [bool]$againA.consumed) 'recording the same spend again adds no second line'

# A reference that matches neither the waiting approval's round nor any superseded approval marks nothing spent.
$r3b = New-CampaignFixture
$null = Write-TypedRoundApproval -Root $r3b -NowUtc $atB -TurnIdentity 'turn-B'
$null = Set-SpecrewReviewRoundApprovalMintedRef -ProjectRoot $r3b -AuthorizationRef 'cmp-x-round-8'
$completeOther = @{ ProjectRoot = $r3b; AuthorizationRef = 'cmp-x-round-9' }
Add-IfSupported -Splat $completeOther -Command 'Complete-SpecrewReviewRoundApprovalAuthorization' -Name 'RunId' -Value 'run-round-9'
$spentOther = Complete-SpecrewReviewRoundApprovalAuthorization @completeOther
$slot3b = Read-Pending -Root $r3b
Assert-True (-not [bool]$spentOther.consumed -and [string]::IsNullOrWhiteSpace([string]$slot3b.spent_at) -and [string]$slot3b.minted_ref -ceq 'cmp-x-round-8' -and
    @(Read-Captures -Root $r3b | Where-Object { [string]$_.fact_type -ceq 'review-round-approval-spent' }).Count -eq 0) ("a round the waiting approval was not minted for marks nothing spent (got {0})" -f $spentOther.reason)

# ---------------------------------------------------------------------------------------------------
# Cases 4-6 (maintainer's finding on 50ffca8f, 2026-11-03): two more routes to the round-7 outcome. The engine's facts a
# running round leaves are written here in the engine's own shapes: a reservation generation naming the run, and the
# campaign's held claim.
function Write-EngineFact { param([string]$Path, [System.Collections.IDictionary]$Fact)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    Set-Content -LiteralPath $Path -Value ([pscustomobject]$Fact | ConvertTo-Json -Compress -Depth 8) -Encoding UTF8 -NoNewline
}
function Read-SpentLines { param([string]$Root) return @(Read-Captures -Root $Root | Where-Object { [string]$_.fact_type -ceq 'review-round-approval-spent' }) }
$campaignId = 'cmp-001-fixture-i001'
$roundOne = 'cmp-001-fixture-i001-round-1'
$runningRun = 'run-20261102-123500000-0a0a0a0a'   # reserved 14:35 local, between A (14:30) and B (14:45)
$reservedAtRunning = '2026-11-02T12:35:00.0000000+00:00'

# Route 1: B typed during the round, plus a launch attempt. The reference is rounds run + 1, which leaves out the
# running round, so the launch would mint B the running round's reference; the claim is refused, the stamp stays, and
# the finishing round matches the slot. The launch must refuse before minting.
Write-Host '--- case 4: a launch attempt while the round runs (route 1) ---'
$r4 = New-CampaignFixture
$null = Write-TypedRoundApproval -Root $r4 -NowUtc $atA -TurnIdentity 'turn-A'
$null = Invoke-AgentLaunch -Root $r4
$campaign4 = Join-Path $r4 ".specrew/review/authority/campaigns/$campaignId"
$grants4 = @(Get-ChildItem -LiteralPath (Join-Path $campaign4 'grants') -Filter '*.json' -File -ErrorAction SilentlyContinue)
$grantId4 = if ($grants4.Count -eq 1) { [IO.Path]::GetFileNameWithoutExtension($grants4[0].Name) } else { '' }
Assert-True ($grantId4 -and [string](Read-Pending -Root $r4).minted_ref -ceq $roundOne) 'setup: A minted round 1 and its grant'
# Round 1 is now running: its relaunch reserved the slot's next generation and holds the campaign's claim.
Write-EngineFact -Path (Join-Path $campaign4 "reservations/$grantId4/slot-001/generation-002.json") -Fact ([ordered]@{
        campaign_id = $campaignId; fact_type = 'reservation'; grant_id = $grantId4; observed_at = $reservedAtRunning
        reservation_id = 'res-0a0a0a0a0a0a0a0a0a0a'; run_id = $runningRun; schema_version = '1.0'; slot = 1 })
$claimDir = Join-Path $campaign4 'claims/lin-001-fixture'
$nextClaim = 1 + @(Get-ChildItem -LiteralPath $claimDir -Filter '*-held.json' -File -ErrorAction SilentlyContinue).Count
Write-EngineFact -Path (Join-Path $claimDir ('{0:d8}-held.json' -f $nextClaim)) -Fact ([ordered]@{
        campaign_id = $campaignId; disposition = 'held'; fact_type = 'claim-held'; generation = $nextClaim
        observed_at = '2026-11-02T12:36:00.0000000+00:00'; run_id = $runningRun; schema_version = '1.0'; target_lineage = 'lin-001-fixture' })
$null = Write-TypedRoundApproval -Root $r4 -NowUtc $atB -TurnIdentity 'turn-B'
$launchB = Invoke-AgentLaunch -Root $r4
$slot4 = Read-Pending -Root $r4
Assert-True ((Test-SameInstant -Value $slot4.observed_at -Expected $atB) -and [string]::IsNullOrWhiteSpace([string]$slot4.minted_ref)) ("a launch while round 1 runs mints nothing on B (minted_ref '{0}')" -f [string]$slot4.minted_ref)
Assert-True ($launchB.Text -match [regex]::Escape($runningRun)) 'the refusal names the running round'
$generations4 = @(Get-ChildItem -LiteralPath (Join-Path $campaign4 "reservations/$grantId4/slot-001") -Filter 'generation-*.json' -File)
Assert-True ($generations4.Count -eq 2 -and @(Get-ChildItem -LiteralPath (Join-Path $campaign4 'grants') -Filter '*.json' -File).Count -eq 1) 'the refused launch reserved nothing and minted no grant'
$complete4 = @{ ProjectRoot = $r4; AuthorizationRef = $roundOne; RunId = $runningRun }
$spent4 = Complete-SpecrewReviewRoundApprovalAuthorization @complete4
$slot4After = Read-Pending -Root $r4
$spentLines4 = @(Read-SpentLines -Root $r4)
Assert-True ([string]::IsNullOrWhiteSpace([string]$slot4After.spent_at)) 'round 1 completing leaves B unspent'
Assert-True ($spentLines4.Count -eq 1 -and [string]$spentLines4[0].approval_turn_identity -ceq 'turn-A' -and [string]$spentLines4[0].run_id -ceq $runningRun) ("the spent line names A (got {0} line(s), {1})" -f $spentLines4.Count, $spent4.reason)

# The same outcome when a stamp lands anyway (the engine reserves before it claims, and a stamp from an earlier build may
# already be on the slot): B observed after the round's reservation is never the approval that paid for it, at
# completion or when a later launch retires a delivered round.
Write-Host '--- case 4b: a stamp left on B by a mid-run launch ---'
$r4b = New-CampaignFixture
$campaign4b = Join-Path $r4b ".specrew/review/authority/campaigns/$campaignId"
$grantId4b = 'grant-0b0b0b0b0b0b0b0b0b0b'
Write-EngineFact -Path (Join-Path $campaign4b "grants/$grantId4b.json") -Fact ([ordered]@{
        authorization_ref = $roundOne; campaign_id = $campaignId; fact_type = 'grant'; grant_id = $grantId4b; observed_at = '2026-11-02T12:31:00.0000000+00:00'; schema_version = '1.0' })
Write-EngineFact -Path (Join-Path $campaign4b "reservations/$grantId4b/slot-001/generation-001.json") -Fact ([ordered]@{
        campaign_id = $campaignId; fact_type = 'reservation'; grant_id = $grantId4b; observed_at = $reservedAtRunning
        reservation_id = 'res-0b0b0b0b0b0b0b0b0b0b'; run_id = $runningRun; schema_version = '1.0'; slot = 1 })
$null = Write-TypedRoundApproval -Root $r4b -NowUtc $atA -TurnIdentity 'turn-A'
$null = Set-SpecrewReviewRoundApprovalMintedRef -ProjectRoot $r4b -AuthorizationRef $roundOne
$null = Write-TypedRoundApproval -Root $r4b -NowUtc $atB -TurnIdentity 'turn-B'
$null = Set-SpecrewReviewRoundApprovalMintedRef -ProjectRoot $r4b -AuthorizationRef $roundOne
Write-EngineFact -Path (Join-Path $campaign4b "runs/$runningRun/result.json") -Fact ([ordered]@{
        campaign_id = $campaignId; run_id = $runningRun; runtime_outcome = 'completed'; started_at = $reservedAtRunning })
$deliveredSplat = @{ ProjectRoot = $r4b; CampaignId = $campaignId; AuthorizationRef = $roundOne }
Add-IfSupported -Splat $deliveredSplat -Command 'Get-SpecrewDeliveredRoundForMintedRef' -Name 'CaptureObservedAt' -Value $atB
$delivered4b = Get-SpecrewDeliveredRoundForMintedRef @deliveredSplat
Assert-True ($null -eq $delivered4b) 'a later launch does not take the round reserved before B as the round B paid for'
$spent4b = Complete-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $r4b -AuthorizationRef $roundOne -RunId $runningRun
$slot4b = Read-Pending -Root $r4b
$spentLines4b = @(Read-SpentLines -Root $r4b)
Assert-True ([string]::IsNullOrWhiteSpace([string]$slot4b.spent_at)) ("B, stamped with the running round's reference, stays unspent when that round completes (got {0})" -f $spent4b.reason)
Assert-True ($spentLines4b.Count -eq 1 -and [string]$spentLines4b[0].approval_turn_identity -ceq 'turn-A') 'the spent line names A'

# Route 2: the partial sign-off of a run whose reservation the store does not name. Its round reference resolves empty,
# and the waiting approval B never minted a round, so it paid for nothing.
Write-Host '--- case 5: a partial sign-off with a waiting approval that minted nothing (route 2) ---'
function Test-PartialSignoffSpendsWaitingApproval {
    param([string]$Root, [string]$RunId)
    $null = Write-TypedRoundApproval -Root $Root -NowUtc $atB -TurnIdentity 'turn-B'
    $null = Write-SpecrewReviewSignoffOverrideRequest -ProjectRoot $Root -TargetTreeId ('a' * 40) -CampaignId $campaignId -RunId $RunId
    $null = Write-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $Root -Response 'approved for partial review signoff - the uncovered files are docs only' `
        -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -NowUtc '2026-11-02T13:30:00.0000000+00:00' 2>$null
    $slot = Read-Pending -Root $Root
    return (-not [string]::IsNullOrWhiteSpace([string]$slot.spent_at)) -or @(Read-SpentLines -Root $Root | Where-Object { [string]$_.approval_turn_identity -ceq 'turn-B' }).Count -gt 0
}
$r5 = New-CampaignFixture
Assert-True (-not (Test-PartialSignoffSpendsWaitingApproval -Root $r5 -RunId $runningRun)) 'accepting a partial of a run the store does not name leaves B unspent'
# The same with the run's reservation and grant on record: B was typed after the run was reserved.
$r5b = New-CampaignFixture
$campaign5b = Join-Path $r5b ".specrew/review/authority/campaigns/$campaignId"
Write-EngineFact -Path (Join-Path $campaign5b "grants/$grantId4b.json") -Fact ([ordered]@{
        authorization_ref = $roundOne; campaign_id = $campaignId; fact_type = 'grant'; grant_id = $grantId4b; observed_at = '2026-11-02T12:31:00.0000000+00:00'; schema_version = '1.0' })
Write-EngineFact -Path (Join-Path $campaign5b "reservations/$grantId4b/slot-001/generation-001.json") -Fact ([ordered]@{
        campaign_id = $campaignId; fact_type = 'reservation'; grant_id = $grantId4b; observed_at = $reservedAtRunning
        reservation_id = 'res-0b0b0b0b0b0b0b0b0b0b'; run_id = $runningRun; schema_version = '1.0'; slot = 1 })
Assert-True (-not (Test-PartialSignoffSpendsWaitingApproval -Root $r5b -RunId $runningRun)) 'accepting a partial of a run reserved before B leaves B unspent'

# Only each lineage's newest claim generation says whether a round runs: an older generation left held under a newer,
# retired one is not a running round, or it would refuse every launch for good.
Write-Host '--- case 5c: a stale held claim under a newer, released generation ---'
$r5c = New-CampaignFixture
$claims5c = Join-Path $r5c ".specrew/review/authority/campaigns/$campaignId/claims/lin-001-fixture"
$claimFact = { param([int]$Generation, [string]$Disposition, [string]$RunId)
    [ordered]@{ campaign_id = $campaignId; disposition = $Disposition; fact_type = "claim-$Disposition"; generation = $Generation
        observed_at = '2026-11-02T12:36:00.0000000+00:00'; run_id = $RunId; schema_version = '1.0'; target_lineage = 'lin-001-fixture' } }
Write-EngineFact -Path (Join-Path $claims5c '00000001-held.json') -Fact (& $claimFact 1 'held' 'run-20261102-110000000-01010101')
Write-EngineFact -Path (Join-Path $claims5c '00000002-held.json') -Fact (& $claimFact 2 'held' $runningRun)
Write-EngineFact -Path (Join-Path $claims5c '00000002-released.json') -Fact (& $claimFact 2 'released' $runningRun)
$stale = Get-SpecrewCampaignRoundInFlight -ProjectRoot $r5c -CampaignId $campaignId
Assert-True ($null -eq $stale) ("an older held generation under a released newer one is not a round in flight (got {0})" -f $(if ($null -ne $stale) { $stale.run_id } else { 'none' }))
Write-EngineFact -Path (Join-Path $claims5c '00000003-held.json') -Fact (& $claimFact 3 'held' 'run-20261102-130000000-03030303')
$live = Get-SpecrewCampaignRoundInFlight -ProjectRoot $r5c -CampaignId $campaignId
Assert-True ($null -ne $live -and [string]$live.run_id -ceq 'run-20261102-130000000-03030303' -and [string]$live.evidence -ceq 'claim-held') 'a held newest generation is the round in flight'

# The automatic retry recomputes the round reference after an undelivered attempt. The waiting approval is re-stamped
# with it, and only while the slot still holds the approval this launch minted; otherwise the delivered retry would find
# the slot minted for another round and leave its approval unspent.
Write-Host '--- case 6: the automatic retry re-stamps the round it pays for ---'
$r6 = New-CampaignFixture
$null = Write-TypedRoundApproval -Root $r6 -NowUtc $atA -TurnIdentity 'turn-A'
$null = Set-SpecrewReviewRoundApprovalMintedRef -ProjectRoot $r6 -AuthorizationRef $roundOne
$moved = @{ ProjectRoot = $r6; AuthorizationRef = 'cmp-001-fixture-i001-round-2' }
Add-IfSupported -Splat $moved -Command 'Set-SpecrewReviewRoundApprovalMintedRef' -Name 'ExpectedMintedRef' -Value 'cmp-001-fixture-i001-round-9'
$movedStamp = Set-SpecrewReviewRoundApprovalMintedRef @moved
Assert-True (-not [bool]$movedStamp.stamped -and [string](Read-Pending -Root $r6).minted_ref -ceq $roundOne) 'a re-stamp refuses when the slot no longer holds the expected round'
$restampSplat = @{ ProjectRoot = $r6; AuthorizationRef = 'cmp-001-fixture-i001-round-2' }
Add-IfSupported -Splat $restampSplat -Command 'Set-SpecrewReviewRoundApprovalMintedRef' -Name 'ExpectedMintedRef' -Value $roundOne
$restamp = Set-SpecrewReviewRoundApprovalMintedRef @restampSplat
$spent6 = Complete-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $r6 -AuthorizationRef 'cmp-001-fixture-i001-round-2'
Assert-True ([bool]$restamp.stamped -and [bool]$spent6.consumed) ("the delivered retry spends the re-stamped approval (got {0})" -f $spent6.reason)
Assert-True ($cliSource -match 'Set-SpecrewReviewRoundApprovalMintedRef -ProjectRoot \$resolvedProjectPath -AuthorizationRef \$campaignGrantAuthorizationRef -ExpectedMintedRef') 'the review CLI re-stamps before the automatic retry'

# ---------------------------------------------------------------------------------------------------
# Case 7 (maintainer's UX ruling, 2026-11-04, 19:05 local): A REPLY TYPED WHILE THE TURN IS STILL ENDING JUST WORKS. A
# human answers a question when they see it, which is often while the Stop hook is still running. Claude hands that
# queued reply to the prompt hook with the RUNNING turn's prompt id (DRIFT-006, measured on Claude Code 2.1.314), and
# its transcript entry may carry the same id. Keyed on the id alone, the reply read as the running turn, already
# recorded, and was dropped without a word. It must be recorded once as its own act, and the next turn acts on it: for
# an option answer such as `1` and for `approved for review round`. Every step runs the real provider as its own
# process, as the hooks do; the running turn's Stop runs while the reply's prompt hook runs.
Write-Host '--- case 7: a reply typed while the turn is still ending is recorded once, as its own act ---'
$handoverProvider = Join-Path $repoRoot 'scripts\internal\specrew-handover-provider.ps1'
function New-QueuedReplyFixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('typed-act-queued-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew') | Out-Null
    Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"" -Encoding UTF8
    & git init -q -b 001-fixture $root 2>&1 | Out-Null
    $script:roots.Add($root)
    return [pscustomobject]@{ Root = $root; Transcript = (Join-Path $root 'transcript.jsonl') }
}
function Add-ClaudeEntry {
    # Returns the entry's own uuid, the record Claude keeps the hook's output under.
    param($Fixture, [string]$Role, [string]$Text, [string]$PromptId)
    $uuid = [guid]::NewGuid().ToString()
    $entry = if ($Role -eq 'user') {
        @{ type = 'user'; uuid = $uuid; timestamp = [DateTimeOffset]::UtcNow.ToString('o'); sessionId = 's1'; promptId = $PromptId
            origin = @{ kind = 'human' }; message = @{ role = 'user'; content = $Text } }
    }
    else { @{ type = 'assistant'; uuid = $uuid; message = @{ role = 'assistant'; content = @(@{ type = 'text'; text = $Text }) } } }
    Add-Content -LiteralPath $Fixture.Transcript -Value ($entry | ConvertTo-Json -Depth 8 -Compress) -Encoding UTF8
    return $uuid
}
function Add-HookAttachment {
    # Claude stores the prompt hook's output as an attachment under the message's own record (measured on this project's
    # transcript, Claude Code 2.1.31x: every UserPromptSubmit output sits under the user entry, or under the queued_command
    # attachment of a message absorbed into a running turn).
    param($Fixture, [string]$ParentUuid, [AllowNull()][string[]]$Output)
    $entry = @{ type = 'attachment'; uuid = [guid]::NewGuid().ToString(); parentUuid = $ParentUuid; sessionId = 's1'; timestamp = [DateTimeOffset]::UtcNow.ToString('o')
        attachment = @{ type = 'hook_additional_context'; content = @((@($Output) | Where-Object { $_ }) -join "`n"); hookName = 'UserPromptSubmit'; hookEvent = 'UserPromptSubmit' } }
    Add-Content -LiteralPath $Fixture.Transcript -Value ($entry | ConvertTo-Json -Depth 8 -Compress) -Encoding UTF8
}
function Invoke-PromptHook {
    # The prompt hook as its own process; returns what it printed (the hook's output Claude records).
    param($Fixture, [string]$Text, [string]$PromptId)
    $process = Start-HookProcess -ArgList (Get-PromptHookArgs -Fixture $Fixture -Text $Text -PromptId $PromptId)
    return (Wait-HookProcess $process)
}
function Send-ClaudeMessage {
    # A typed message as Claude handles it: the prompt hook runs, then the entry and the hook's output under it.
    param($Fixture, [string]$Text, [string]$PromptId)
    $out = Invoke-PromptHook -Fixture $Fixture -Text $Text -PromptId $PromptId
    $uuid = Add-ClaudeEntry -Fixture $Fixture -Role 'user' -Text $Text -PromptId $PromptId
    Add-HookAttachment -Fixture $Fixture -ParentUuid $uuid -Output $out
}
function Get-PromptHookArgs {
    param($Fixture, [string]$Text, [string]$PromptId)
    return @('-NoProfile', '-File', $handoverProvider, '--project-root', $Fixture.Root, '--host-kind', 'claude', '--source-event', 'UserPromptSubmit',
        '--transcript-path', $Fixture.Transcript, '--last-user-message', $Text, '--turn-origin', 'typed-user', '--session-id', 's1',
        '--message-identity', 'declared', '--message-id', $PromptId)
}
function Get-StopHookArgs {
    param($Fixture)
    return @('-NoProfile', '-File', $handoverProvider, '--project-root', $Fixture.Root, '--host-kind', 'claude', '--source-event', 'Stop',
        '--transcript-path', $Fixture.Transcript, '--session-id', 's1', '--message-identity', 'declared')
}
function Start-HookProcess {
    param([string[]]$ArgList)
    $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
    foreach ($a in $ArgList) { $psi.ArgumentList.Add([string]$a) }
    $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.CreateNoWindow = $true
    $psi.Environment['SPECREW_MODULE_PATH'] = $repoRoot
    return [Diagnostics.Process]::Start($psi)
}
function Wait-HookProcess {
    param($Process)
    $stdout = $Process.StandardOutput.ReadToEnd(); [void]$Process.StandardError.ReadToEnd(); $Process.WaitForExit()
    return [string[]]@($stdout -split "`r?`n" | Where-Object { $_ })
}
function Get-ReplyKeys {
    param($Fixture, [string]$Text)
    $path = Join-Path $Fixture.Root '.specrew/authority/exhausted-turns.jsonl'
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    $hash = Get-SpecrewHumanAuthorityHash -Text $Text.Trim()
    return @(Get-Content -LiteralPath $path | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json } |
            Where-Object { $_.PSObject.Properties['content_hash'] -and [string]$_.content_hash -ceq $hash } | ForEach-Object { [string]$_.turn_id } | Sort-Object -Unique)
}
function Get-NotRecordedCount {
    param($Fixture)
    $path = Get-SpecrewAuthorityNotRecordedJournalPath -ProjectRoot $Fixture.Root
    if (-not (Test-Path -LiteralPath $path)) { return 0 }
    return @(Get-Content -LiteralPath $path | Where-Object { $_.Trim() }).Count
}
function Get-RoundCaptureCount {
    param($Fixture)
    $path = Join-Path $Fixture.Root '.specrew/review/round-approval/captures.jsonl'
    if (-not (Test-Path -LiteralPath $path)) { return 0 }
    return @(Get-Content -LiteralPath $path | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { [string]$_.fact_type -ceq 'review-round-approval' }).Count
}

foreach ($reply in @('1', 'approved for review round')) {
    $f7 = New-QueuedReplyFixture
    $running = 'prompt-running-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
    $first = 'which review host should run the next round? show me the options'
    # The running turn: the human's message, recorded by the prompt hook, and the reply that asks the question.
    Send-ClaudeMessage -Fixture $f7 -Text $first -PromptId $running
    $null = Add-ClaudeEntry -Fixture $f7 -Role 'assistant' -Text 'Two hosts can run it. Type one: 1 - codex, 2 - copilot.'
    # The turn is ending: its Stop hook runs, and the human answers now. The queued reply carries the running turn's id;
    # its hook runs when it is sent, and Claude records it, with the hook's output under it, when it is dequeued.
    $stop = Start-HookProcess -ArgList (Get-StopHookArgs -Fixture $f7)
    $promptOut = Invoke-PromptHook -Fixture $f7 -Text $reply -PromptId $running
    $replyUuid = Add-ClaudeEntry -Fixture $f7 -Role 'user' -Text $reply -PromptId $running
    Add-HookAttachment -Fixture $f7 -ParentUuid $replyUuid -Output $promptOut
    $null = Wait-HookProcess $stop
    # The next turn acts on it, and ends.
    $null = Add-ClaudeEntry -Fixture $f7 -Role 'assistant' -Text 'Acting on your reply.'
    $null = & pwsh @(Get-StopHookArgs -Fixture $f7) *> $null

    $replyKeys = @(Get-ReplyKeys -Fixture $f7 -Text $reply)
    $firstKeys = @(Get-ReplyKeys -Fixture $f7 -Text $first)
    $ownKey = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = $running; text = $reply })).Identity
    Assert-True ($replyKeys.Count -eq 1 -and $replyKeys[0] -ceq $ownKey) ("[{0}] the queued reply is recorded once, under its own key (got {1} key(s))" -f $reply, $replyKeys.Count)
    Assert-True ($firstKeys.Count -ge 1 -and @($firstKeys | Where-Object { $replyKeys -ccontains $_ }).Count -eq 0) ("[{0}] and not as the running turn's message" -f $reply)
    Assert-True ((Get-NotRecordedCount -Fixture $f7) -eq 0) ("[{0}] nothing is reported as not recorded" -f $reply)
    if ($reply -ne '1') {
        $pending = Get-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $f7.Root
        Assert-True ((Get-RoundCaptureCount -Fixture $f7) -eq 1) ("[{0}] one round approval is captured (got {1})" -f $reply, (Get-RoundCaptureCount -Fixture $f7))
        Assert-True ($null -ne $pending -and [string]$pending.turn_identity -ceq $ownKey) ("[{0}] and the next turn finds it waiting, as the reply's own act" -f $reply)
    }
}

function Get-PendingRoundTurn {
    param($Fixture)
    $pending = Get-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $Fixture.Root
    if ($null -eq $pending -or -not $pending.PSObject.Properties['turn_identity']) { return '' }
    return [string]$pending.turn_identity
}
function Get-RoundSupersessionCount {
    param($Fixture)
    $path = Join-Path $Fixture.Root '.specrew/review/round-approval/captures.jsonl'
    if (-not (Test-Path -LiteralPath $path)) { return 0 }
    return @(Get-Content -LiteralPath $path | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { [string]$_.fact_type -ceq 'review-round-approval-superseded' }).Count
}
$approval = 'approved for review round'

# Case 7b (co-review round 8, finding 2; maintainer's instruction 2026-11-05): THE SAME LINE RETYPED UNDER THE SAME PROMPT ID
# IS A SECOND MESSAGE. The running turn's message was itself `approved for review round`, and the human types it again
# while the turn ends: Claude hands the retype the running turn's prompt_id, so id and text are the first message's. The
# discriminator is the host's own record of each message, never a time window: Claude stores each prompt hook's output
# under that message's own transcript record, and the hook names its prompt event there.
Write-Host '--- case 7b: the same approval retyped while the turn ends, under the running prompt id, is its own act ---'
$f7b = New-QueuedReplyFixture
$running7b = 'prompt-running-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
Send-ClaudeMessage -Fixture $f7b -Text $approval -PromptId $running7b
$firstTurn7b = Get-PendingRoundTurn -Fixture $f7b
$null = Add-ClaudeEntry -Fixture $f7b -Role 'assistant' -Text 'Launching the round.'
$stop7b = Start-HookProcess -ArgList (Get-StopHookArgs -Fixture $f7b)
$out7b = Invoke-PromptHook -Fixture $f7b -Text $approval -PromptId $running7b
$retype7b = Add-ClaudeEntry -Fixture $f7b -Role 'user' -Text $approval -PromptId $running7b
Add-HookAttachment -Fixture $f7b -ParentUuid $retype7b -Output $out7b
$null = Wait-HookProcess $stop7b
$null = Add-ClaudeEntry -Fixture $f7b -Role 'assistant' -Text 'Acting on your reply.'
$null = & pwsh @(Get-StopHookArgs -Fixture $f7b) *> $null
$keys7b = @(Get-ReplyKeys -Fixture $f7b -Text $approval)
$held7b = Get-PendingRoundTurn -Fixture $f7b
Assert-True ($keys7b.Count -eq 2) ("the retyped approval is recorded as a second act (got {0} key(s))" -f $keys7b.Count)
Assert-True ((Get-RoundCaptureCount -Fixture $f7b) -eq 2 -and -not [string]::IsNullOrWhiteSpace($held7b) -and $held7b -cne $firstTurn7b -and $keys7b -ccontains $held7b) ("and the next turn finds the retype waiting, not the first approval (captures {0})" -f (Get-RoundCaptureCount -Fixture $f7b))
Assert-True ((Get-RoundSupersessionCount -Fixture $f7b) -eq 1 -and (Get-NotRecordedCount -Fixture $f7b) -eq 0) 'with one fact naming the approval it retired, and nothing reported as not recorded'

# Case 7c: the entry is in the transcript before the hook's output is (Claude writes a typed entry first). The hook's
# reservation of a message with that text, under no record yet, stands for it; the turn end recovers nothing twice.
Write-Host '--- case 7c: an entry whose hook output is not written yet is not recovered a second time ---'
$f7c = New-QueuedReplyFixture
$id7c = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$out7c = Invoke-PromptHook -Fixture $f7c -Text $approval -PromptId $id7c
$entry7c = Add-ClaudeEntry -Fixture $f7c -Role 'user' -Text $approval -PromptId $id7c
$null = & pwsh @(Get-StopHookArgs -Fixture $f7c) *> $null
Add-HookAttachment -Fixture $f7c -ParentUuid $entry7c -Output $out7c
$null = & pwsh @(Get-StopHookArgs -Fixture $f7c) *> $null
Assert-True (@(Get-ReplyKeys -Fixture $f7c -Text $approval).Count -eq 1 -and (Get-RoundCaptureCount -Fixture $f7c) -eq 1) ("one key and one capture (got {0} key(s), {1} capture(s))" -f @(Get-ReplyKeys -Fixture $f7c -Text $approval).Count, (Get-RoundCaptureCount -Fixture $f7c))

# Case 7d (maintainer's instruction 2026-11-05): no double-fire tolerance folds a real retype on Claude. The approval typed
# twice as two messages a second apart is two acts.
Write-Host '--- case 7d: the same approval typed twice within a few seconds on Claude is two acts ---'
$f7d = New-QueuedReplyFixture
Send-ClaudeMessage -Fixture $f7d -Text $approval -PromptId ('prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$first7d = Get-PendingRoundTurn -Fixture $f7d
Send-ClaudeMessage -Fixture $f7d -Text $approval -PromptId ('prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$null = & pwsh @(Get-StopHookArgs -Fixture $f7d) *> $null
$held7d = Get-PendingRoundTurn -Fixture $f7d
Assert-True (@(Get-ReplyKeys -Fixture $f7d -Text $approval).Count -eq 2 -and (Get-RoundCaptureCount -Fixture $f7d) -eq 2 -and $held7d -cne $first7d) ("two keys, two captures, the second waiting (got {0} key(s))" -f @(Get-ReplyKeys -Fixture $f7d -Text $approval).Count)

# ---------------------------------------------------------------------------------------------------
# Case 9 (co-review round 8, finding 1): RESERVE BEFORE MINTING, on the recovery path too. A ledger that can be read but not
# appended: the recovery writer wrote the approval and then failed to register the turn, so after the approval was spent
# the next turn end recovered the same entry into a fresh one. No reservation, no approval.
Write-Host '--- case 9: a turn the ledger cannot record mints nothing on the recovery path ---'
$f9 = New-QueuedReplyFixture
$id9 = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$null = Add-ClaudeEntry -Fixture $f9 -Role 'user' -Text $approval -PromptId $id9
$ledger9 = Join-Path $f9.Root '.specrew/authority/exhausted-turns.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ledger9) | Out-Null
Set-Content -LiteralPath $ledger9 -Value '{"schema_version":"1.0","fact_type":"typed-turn-exhausted","turn_id":"unrelated"}' -Encoding UTF8
(Get-Item -LiteralPath $ledger9).IsReadOnly = $true
try {
    $cite9 = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = $id9; text = $approval })).Identity
    $r9 = Write-SpecrewTypedAct -ProjectRoot $f9.Root -HostKind 'claude' -TurnIdentity $cite9 -TranscriptPath $f9.Transcript -SourceEvent 'stop-transcript' -SessionId 's1'
}
finally { (Get-Item -LiteralPath $ledger9).IsReadOnly = $false }
Assert-True (-not [bool]$r9.Written -and $null -eq (Get-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $f9.Root)) ("no approval is written when its turn cannot be reserved (written={0})" -f [bool]$r9.Written)

# Case 10 (co-review round 8, finding 3): A RECOVERED ACT IS DATED BY WHEN IT WAS TYPED. Approval B was captured at 10:10;
# an older missed approval A, typed at 10:00, is recovered at 10:20. A must not retire B.
Write-Host '--- case 10: an older approval recovered late does not retire a newer one ---'
$f10 = New-QueuedReplyFixture
$null = Write-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $f10.Root -Response $approval -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -TurnIdentity 'turn-B' -NowUtc '2026-11-04T10:10:00.0000000Z'
$id10 = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$entry10 = @{ type = 'user'; uuid = [guid]::NewGuid().ToString(); timestamp = '2026-11-04T10:00:00.000Z'; sessionId = 's1'; promptId = $id10; origin = @{ kind = 'human' }; message = @{ role = 'user'; content = $approval } }
Add-Content -LiteralPath $f10.Transcript -Value ($entry10 | ConvertTo-Json -Depth 8 -Compress) -Encoding UTF8
$cite10 = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = $id10; text = $approval })).Identity
$null = Write-SpecrewTypedAct -ProjectRoot $f10.Root -HostKind 'claude' -TurnIdentity $cite10 -TranscriptPath $f10.Transcript -SourceEvent 'stop-transcript' -SessionId 's1' -NowUtc '2026-11-04T10:20:00.0000000Z'
Assert-True ((Get-PendingRoundTurn -Fixture $f10) -ceq 'turn-B' -and (Get-RoundSupersessionCount -Fixture $f10) -eq 0) ("B stays waiting and no fact says A retired it (holds '{0}')" -f (Get-PendingRoundTurn -Fixture $f10))

# ---------------------------------------------------------------------------------------------------
# Case 8 (FR-021; tasks.md, "the same rule covers the top-up, the coverage deferral and the partial sign-off"): A NEWER
# TYPED ACT SUPERSEDES; IT NEVER FOLDS, for the three review acts beside the round approval. Today the top-up folds a
# re-typed reset into the older unspent record, the deferral overwrites with no record of what it replaced, and a second
# partial sign-off for the same request is refused as a conflict. After T004 each newer typed act (another turn
# identity) takes the record with an immutable supersession fact naming what it retired; the same act re-offered changes
# nothing; an older act arriving late never retires the newer one.
Write-Host '--- case 8: the top-up, the coverage deferral and the partial sign-off supersede, never fold ---'
$t0 = [DateTimeOffset]::Parse('2026-11-04T10:00:00Z')
function Invoke-ReviewActWriter {
    param([string]$Kind, [string]$Root, [string]$Text, [string]$TurnIdentity, [DateTimeOffset]$At)
    $command = switch ($Kind) { 'top-up' { 'Write-SpecrewAllowanceResetAuthorization' } 'coverage-deferral' { 'Write-SpecrewCoverageDeferralAuthorization' } 'partial-signoff' { 'Write-SpecrewReviewSignoffOverrideAuthorization' } }
    $splat = @{ ProjectRoot = $Root; Response = $Text; HostKind = 'claude'; SourceEvent = 'UserPromptSubmit'; NowUtc = $At.ToString('o') }
    Add-IfSupported -Splat $splat -Command $command -Name 'TurnIdentity' -Value $TurnIdentity
    try { return (& $command @splat) } catch { return $null }
}
function Read-ReviewActRecord {
    param([string]$Kind, [string]$Root)
    $path = switch ($Kind) {
        'top-up' { Join-Path $Root '.specrew/review/allowance-reset/pending-allowance-reset.json' }
        'coverage-deferral' { Join-Path $Root '.specrew/review/coverage-disposition/coverage-deferral.json' }
        'partial-signoff' { @(Get-ChildItem -LiteralPath (Join-Path $Root '.specrew/review/signoff-gate/override-authorizations') -Filter 'override-*.json' -ErrorAction SilentlyContinue)[0].FullName }
    }
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)) { return $null }
    return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -Depth 8)
}
function Get-SupersessionFacts {
    param([string]$Root)
    return @(Get-ChildItem -LiteralPath (Join-Path $Root '.specrew/review') -Recurse -Filter 'supersessions.jsonl' -ErrorAction SilentlyContinue |
            ForEach-Object { Get-Content -LiteralPath $_.FullName } | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
}
$reviewActs = @(
    @{ Kind = 'top-up'; A = 'approved for allowance reset'; B = 'approved for allowance reset' }
    @{ Kind = 'coverage-deferral'; A = 'continue without coverage until the review phase'; B = 'continue without coverage until the review phase' }
    @{ Kind = 'partial-signoff'; A = 'approved for partial review signoff - the security checks are covered'; B = 'approved for partial review signoff - the remaining files are test data' }
)
foreach ($act in $reviewActs) {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('typed-act-supersede-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew') | Out-Null
    $script:roots.Add($root)
    if ($act.Kind -eq 'partial-signoff') {
        $tree = 'a' * 40; $campaign = 'cmp-001-fixture-i001'
        $requestId = 'override-' + (Get-SpecrewHumanAuthorityHash -Text ($tree + '|' + $campaign)).Substring(0, 24)
        $requestDir = Join-Path $root '.specrew/review/signoff-gate'
        New-Item -ItemType Directory -Force -Path $requestDir | Out-Null
        ([pscustomobject]@{ schema_version = '1.0'; request_id = $requestId; target_tree_id = $tree; campaign_id = $campaign; run_id = 'run-1'
            required_phrase = 'approved for partial review signoff - <why accepting partial coverage is safe>'; created_at = $t0.AddMinutes(-5).ToString('o') } |
            ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $requestDir 'pending-override.json') -Encoding UTF8
    }
    $k = $act.Kind
    $null = Invoke-ReviewActWriter -Kind $k -Root $root -Text $act.A -TurnIdentity 'turn-A' -At $t0
    $null = Invoke-ReviewActWriter -Kind $k -Root $root -Text $act.B -TurnIdentity 'turn-B' -At $t0.AddMinutes(10)
    $record = Read-ReviewActRecord -Kind $k -Root $root
    $heldTurn = if ($null -ne $record -and $record.PSObject.Properties['turn_identity']) { [string]$record.turn_identity } else { '' }
    Assert-True ($heldTurn -ceq 'turn-B') ("[{0}] the newer typed act takes the record (holds '{1}')" -f $k, $heldTurn)
    $facts = @(Get-SupersessionFacts -Root $root)
    Assert-True ($facts.Count -eq 1 -and [string]$facts[0].superseded_turn_identity -ceq 'turn-A' -and [string]$facts[0].superseded_by_turn_identity -ceq 'turn-B') ("[{0}] and an immutable fact records that it retired the older one (got {1})" -f $k, $facts.Count)
    $null = Invoke-ReviewActWriter -Kind $k -Root $root -Text $act.B -TurnIdentity 'turn-B' -At $t0.AddMinutes(15)
    $null = Invoke-ReviewActWriter -Kind $k -Root $root -Text $act.A -TurnIdentity 'turn-old' -At $t0.AddMinutes(-30)
    $after = Read-ReviewActRecord -Kind $k -Root $root
    $afterTurn = if ($null -ne $after -and $after.PSObject.Properties['turn_identity']) { [string]$after.turn_identity } else { '' }
    Assert-True ($afterTurn -ceq 'turn-B' -and @(Get-SupersessionFacts -Root $root).Count -eq 1) ("[{0}] the same act again, or an older act arriving late, changes nothing" -f $k)
}

foreach ($root in $script:roots) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host '--- the real stores are unchanged ---'
$guardAfter = Get-GuardSnapshot
$guardDiff = @(Compare-Object -ReferenceObject $script:guardBefore -DifferenceObject $guardAfter)
foreach ($change in ($guardDiff | Select-Object -First 10)) { Write-Host ("  {0} {1}" -f $(if ($change.SideIndicator -eq '=>') { 'now' } else { 'was' }), $change.InputObject) }
Assert-True ($guardDiff.Count -eq 0) ("no file changed under {0}" -f ($script:guardedPaths -join '; '))
foreach ($name in $script:clearedHostRoots.Keys) { Set-Item -LiteralPath ('Env:' + $name) -Value $script:clearedHostRoots[$name] }

if ($script:failCount -gt 0) { Write-Host "typed-act-writer: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'typed-act-writer: all passed' -ForegroundColor Green
