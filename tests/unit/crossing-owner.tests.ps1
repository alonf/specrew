# Iteration 002, T023 (FR-032, SC-019): a pending crossing is owed by the session that recorded it.
#
# Field case (DRIFT-199-I002-001, the maintainer watching): the boundary demand fired in the REVIEWER
# session - which had produced none of the work - on every Stop, every turn, regardless of topic, for as
# long as any crossing stayed open. A second session could not hold an ordinary conversation.
#
# Ownership has exactly three states and only one suppresses the demand:
#   owner-matches       -> the demand renders (this session recorded the arrival)
#   owner-differs       -> one informational line, no packet, no marker (a different LIVE session owns it)
#   owner-indeterminate -> the demand renders PLUS a sentence saying ownership could not be confirmed
# Indeterminate fails OPEN by construction (maintainer ruling, method rule 12): a session must never be
# locked out of its own crossing by an identity it cannot prove - a resumed or compacted session comes
# back with a new id, and that must not become an outage.
#
# Mutations that turn this file red: remove the ownership branch from the provider (case 3 demands a
# packet in the wrong session); make indeterminate suppress instead of render (cases 4, 5 - the outage);
# fold `owner` into the hashed crossing_id (case 2 - re-sync idempotence breaks).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
$provider = (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-OwnerFixture {
    param([string]$LastAuthorized = 'plan', [string]$WorkingBoundary = 'tasks', [string]$SessionId = 'session-alpha')
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("owner-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))
    # Normalized, separator-consistent paths: the evidence reader refuses a feature_path it cannot prove is
    # inside the project, and a mixed-separator path fails that containment check.
    $root = [System.IO.Path]::GetFullPath($root)
    $feature = [System.IO.Path]::GetFullPath((Join-Path $root (Join-Path 'specs' '001-feat')))
    $iter = [System.IO.Path]::GetFullPath((Join-Path $feature (Join-Path 'iterations' '001')))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $iter 'quality') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Value "# Iteration Plan: 001`n`n**Status**: planning`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'state.md') -Value "# Iteration State: 001`n`n**Current Phase**: plan`n**Iteration Status**: executing`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'quality/hardening-gate.md') -Value "# Hardening Gate`n`n**Overall Verdict**: ready" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root add -A
    & git -C $root commit -q -m fixture
    $head = ([string](& git -C $root rev-parse HEAD)).Trim()
    $context = [ordered]@{
        schema = 'v2'
        # The evidence reader resolves the feature from the context's TOP-LEVEL feature_path; inside
        # session_state it is not seen, and every crossing reads 'unverifiable' instead of checked.
        feature_path = $feature
        boundary_enforcement = [ordered]@{
            enabled = $true; last_authorized_boundary = $LastAuthorized; pending_next_boundary = $null
            policy_classes = [ordered]@{ specify = 'human-judgment-required'; clarify = 'human-judgment-required'; plan = 'human-judgment-required'; tasks = 'human-judgment-required'; 'before-implement' = 'human-judgment-required'; 'review-signoff' = 'human-judgment-required'; retro = 'human-judgment-required'; 'iteration-closeout' = 'human-judgment-required'; 'feature-closeout' = 'human-judgment-required' }
            verdict_history = @(); bypass_history = @()
        }
        generated_at_utc = '2026-08-29T00:00:00Z'
        session_state = [ordered]@{ active = $true; boundary_type = $WorkingBoundary; feature_ref = '001-feat'; feature_path = $feature; iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-08-29T00:00:00Z' }
    }
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($context | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    if (-not [string]::IsNullOrWhiteSpace($SessionId)) {
        $marker = [ordered]@{ started_at = '2026-08-29T00:00:00Z'; host = 'claude'; session_id = $SessionId; project_root = $root; branch = 'main'; head_commit = $head.Substring(0, 8) }
        [System.IO.File]::WriteAllText((Join-Path $root '.specrew/runtime/session-marker.json'), ($marker | ConvertTo-Json), [System.Text.UTF8Encoding]::new($false))
    }
    return [pscustomobject]@{ Root = $root; Head = $head; Iter = $iter }
}
function Read-Scope { param([string]$Root) return (Get-Content -LiteralPath (Join-Path $Root '.specrew/start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12).boundary_enforcement.pending_crossing }
function Get-Prop {
    # StrictMode makes a missing property THROW; a missing `owner` is exactly the pre-fix shape this suite
    # must report as a FAIL rather than an unhandled error.
    param($Object, [string]$Name)
    if ($null -eq $Object) { return '' }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -eq $p) { return '' }
    return [string]$p.Value
}
function Touch-SessionState {
    # Make an owner look LIVE the way the conformance provider does: its own per-session state directory.
    param([string]$Root, [string]$Owner)
    $hash = Get-SpecrewBoundarySha256 -Text $Owner
    $dir = Join-Path (Join-Path $Root '.specrew/runtime/conformance-sessions') $hash
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Set-Content -LiteralPath (Join-Path $dir 'last-fire.json') -Value '{"identity":"fixture","epoch":1}' -Encoding UTF8
}
function Invoke-Provider {
    param([string]$Root, [string]$SessionId, [string]$Transcript)
    $providerArgs = @('--project-root', $Root, '--host-kind', 'claude', '--source-event', 'Stop', '--event-json', '{"hook_event_name":"Stop"}')
    if (-not [string]::IsNullOrWhiteSpace($SessionId)) { $providerArgs += @('--session-id', $SessionId) }
    if (-not [string]::IsNullOrWhiteSpace($Transcript)) { $providerArgs += @('--transcript-path', $Transcript) }
    # The provider resolves its project root from the CWD first (it is not running as a deployed copy here),
    # which is how the hooks invoke it: cwd == the governed project. Without this the fixture's provider run
    # reads THIS repository's state and the case measures nothing.
    $previous = (Get-Location).Path
    try {
        Set-Location -LiteralPath $Root
        return ((& pwsh -NoProfile -File $provider @providerArgs 2>&1) -join "`n")
    }
    finally { Set-Location -LiteralPath $previous }
}
function Write-PlainTranscript {
    param([string]$Root)
    $tx = Join-Path $Root 'transcript.jsonl'
    $turns = @(@{ role = 'user'; text = 'What is the weather in the tests directory?' }, @{ role = 'assistant'; text = 'A short answer about something unrelated to any boundary.' })
    $lines = foreach ($t in $turns) { (@{ type = $t.role; message = @{ role = $t.role; content = @(@{ type = 'text'; text = $t.text }) } } | ConvertTo-Json -Depth 8 -Compress) }
    [System.IO.File]::WriteAllText($tx, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))
    return $tx
}

# ---------------------------------------------------------------------------------------------------
Write-Host 'Case 1: the mint records the owner from the session marker'
$f1 = New-OwnerFixture -SessionId 'session-alpha'
$s1 = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f1.Root -WorkingBoundary 'tasks' -BoundaryCommitHash $f1.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
$scope1 = Read-Scope -Root $f1.Root
Assert-True ((Get-Prop $scope1 'owner') -eq 'claude|session-alpha') 'pending_crossing.owner is the host|session identity of the minting session'
$pv1 = Get-SpecrewPendingVerdictState -ProjectRoot $f1.Root
Assert-True ((Get-Prop $pv1 'CrossingOwner') -eq 'claude|session-alpha') 'the pending-verdict state surfaces the owner for the demand to read'

Write-Host 'Case 2: the owner travels BESIDE the identity - a re-sync from another session keeps both'
$f2 = New-OwnerFixture -SessionId 'session-alpha'
$s2a = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f2.Root -WorkingBoundary 'tasks' -BoundaryCommitHash $f2.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
$marker2 = Join-Path $f2.Root '.specrew/runtime/session-marker.json'
$m2 = Get-Content -LiteralPath $marker2 -Raw -Encoding UTF8 | ConvertFrom-Json
$m2.session_id = 'session-beta'
[System.IO.File]::WriteAllText($marker2, ($m2 | ConvertTo-Json), [System.Text.UTF8Encoding]::new($false))
$s2b = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f2.Root -WorkingBoundary 'tasks' -BoundaryCommitHash $f2.Head -RecordedAt '2026-08-29T00:00:02Z' 2>$null
$scope2 = Read-Scope -Root $f2.Root
Assert-True ([string]$s2a['crossing_id'] -eq [string]$s2b['crossing_id']) 'the crossing identity is unchanged by a re-sync from a different session (idempotence holds)'
Assert-True ((Get-Prop $scope2 'owner') -eq 'claude|session-alpha') 'the ORIGINAL owner is preserved: the arrival was recorded once, by one session'

Write-Host 'Case 3: a different LIVE session gets one informational line - no packet, no marker'
$f3 = New-OwnerFixture -SessionId 'session-alpha'
$null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f3.Root -WorkingBoundary 'tasks' -BoundaryCommitHash $f3.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
Touch-SessionState -Root $f3.Root -Owner 'claude|session-alpha'
$out3 = Invoke-Provider -Root $f3.Root -SessionId 'session-beta' -Transcript (Write-PlainTranscript -Root $f3.Root)
Assert-True ($out3 -match "owed by session 'claude\|session-alpha'" -and $out3 -match 'this session owes nothing for it') 'the other session is told which session owes the crossing, and that it owes nothing'
Assert-True ($out3 -notmatch 'SPECREW-VERDICT-BOUNDARY' -and $out3 -notmatch 'Render the full six-section') 'no verdict marker and no packet demand reach the session that did not produce the work'
# THE DELIVERY MECHANISM, not just the words. The covering round found (`foreign-owner-still-stop-blocked`)
# that this branch composed the right informational text and then emitted it as a BLOCK anyway: the
# sentinel makes the dispatcher force-continue, the session stops again, and the loop repeats to the cap -
# the interruption FR-032 exists to remove, reinstated by the delivery path while the text looked correct.
# The assertions above all passed against that defect, because none of them looked at HOW the text left.
Assert-True ($out3 -notmatch 'SPECREW-STOP-BLOCK') 'and it arrives as an ORDINARY INFORMATIONAL INJECTION, not a stop-block: a foreign session must be able to stop or converse normally, not be force-continued into the same demand until the cap'
Assert-True ($out3 -match 'owed by session') 'the line is still actually delivered - releasing the block must not silence the explanation'

Write-Host 'Case 4: the OWNING session still gets the demand'
$f4 = New-OwnerFixture -SessionId 'session-alpha'
$null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f4.Root -WorkingBoundary 'tasks' -BoundaryCommitHash $f4.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
$out4 = Invoke-Provider -Root $f4.Root -SessionId 'session-alpha' -Transcript (Write-PlainTranscript -Root $f4.Root)
Assert-True ($out4 -match 'SPECREW-VERDICT-BOUNDARY: plan -> tasks') 'the owning session is asked for the packet and the marker'
Assert-True ($out4 -notmatch 'this session owes nothing') 'and is not told it owes nothing'
Assert-True ($out4 -match 'SPECREW-STOP-BLOCK') 'and the OWNER is still blocked - the fix for case 3 must not release the block for the session that actually owes the crossing'

Write-Host 'Case 5: a resumed/compacted owner (same host, new id, not live) FAILS OPEN with disclosure'
$f5 = New-OwnerFixture -SessionId 'session-alpha'
$null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f5.Root -WorkingBoundary 'tasks' -BoundaryCommitHash $f5.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
# no session state for session-alpha: it resumed into a new identity and left nothing live behind
$out5 = Invoke-Provider -Root $f5.Root -SessionId 'session-alpha-resumed' -Transcript (Write-PlainTranscript -Root $f5.Root)
Assert-True ($out5 -match 'SPECREW-VERDICT-BOUNDARY: plan -> tasks') 'the demand still renders - a resumed session is never locked out of its own crossing'
Assert-True ($out5 -match 'ownership could not be confirmed') 'and it says plainly that ownership could not be confirmed'

Write-Host 'Case 6: a host with no session identity keeps today''s behaviour, and says so'
$f6 = New-OwnerFixture -SessionId ''
$null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f6.Root -WorkingBoundary 'tasks' -BoundaryCommitHash $f6.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
$scope6 = Read-Scope -Root $f6.Root
Assert-True ((Get-Prop $scope6 'owner') -eq 'unknown') 'the crossing records owner: unknown rather than failing to mint'
$out6 = Invoke-Provider -Root $f6.Root -SessionId '' -Transcript (Write-PlainTranscript -Root $f6.Root)
Assert-True ($out6 -match 'SPECREW-VERDICT-BOUNDARY: plan -> tasks') 'the demand renders project-wide, exactly as before the fix'
Assert-True ($out6 -match 'may have reached a session that did not produce the work') 'the gap is named out loud in the packet directive'

Write-Host 'Case 7: the three-state resolver, directly'
$r7a = Resolve-SpecrewCrossingOwnership -RecordedOwner 'claude|a' -CurrentOwner 'claude|a'
$r7b = Resolve-SpecrewCrossingOwnership -RecordedOwner 'unknown' -CurrentOwner 'claude|a'
$r7c = Resolve-SpecrewCrossingOwnership -RecordedOwner 'claude|a' -CurrentOwner 'unknown'
$r7d = Resolve-SpecrewCrossingOwnership -RecordedOwner 'claude|a' -CurrentOwner 'copilot|b'
Assert-True ([string]$r7a.State -eq 'owner-matches' -and [bool]$r7a.DemandRenders) 'matching owner -> owner-matches, demand renders'
Assert-True ([string]$r7b.State -eq 'owner-indeterminate' -and [bool]$r7b.DemandRenders) 'a crossing recorded without an owner -> indeterminate, demand renders'
Assert-True ([string]$r7c.State -eq 'owner-indeterminate' -and [bool]$r7c.DemandRenders) 'a session with no identity -> indeterminate, demand renders'
Assert-True ([string]$r7d.State -eq 'owner-differs' -and -not [bool]$r7d.DemandRenders) 'a different host -> owner-differs, demand suppressed'

foreach ($f in @($f1, $f2, $f3, $f4, $f5, $f6)) { try { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
if ($script:failCount -gt 0) { throw ("crossing-owner: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'crossing-owner: all assertions passed' -ForegroundColor Green
