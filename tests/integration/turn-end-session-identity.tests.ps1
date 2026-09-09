# THE IDENTITY HANDSHAKE: the hook declares, the script echoes, a mismatch fails CLOSED.
#
# THIS SUITE EXISTS BECAUSE AN INDEPENDENT REVIEW BROKE THE FIRST DESIGN IN ONE PROBE. declare-turn-end took
# the declaring session's identity from `.specrew/runtime/session-marker.json`, which is PROJECT-WIDE and
# stamped by whichever session started last. With two sessions open, session A declared and the record
# landed under B's path: A was refused for a declaration it had made, and B was credited with one it had
# not. The reviewer's probe printed it plainly - `A_record_exists:false, B_record_exists:true`.
#
# The repair is not a more careful read of that file. **A project-scoped file cannot answer a session-scoped
# question**, so the read is gone. The hook issues a per-turn token into its own session directory, the
# script echoes it into the record, and at Stop the hook accepts only the token it wrote itself.
#
# Case 1 is the reviewer's probe, kept as it was written. Case 2 is the maintainer's addition and is the one
# that decides whether this is a fix or just a stricter failure: the losing session, having re-declared on
# its next turn, is ACCEPTED. A handshake that fails closed and never recovers is a deadlock with better
# manners.

$ErrorActionPreference = 'Stop'
$script:Failures = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host ("  PASS: {0}" -f $Message) }
    else { Write-Host ("  FAIL: {0}" -f $Message); $script:Failures++ }
}

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$store = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/turn-end-store.ps1'
$declarer = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/declare-turn-end.ps1'

Write-Host 'turn-end-session-identity'
Write-Host '  --- preconditions ---'
Assert-True (Test-Path -LiteralPath $store -PathType Leaf) 'the turn-end store is present'
Assert-True (Test-Path -LiteralPath $declarer -PathType Leaf) 'the declaration script is present'
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE'; exit 1 }
. $store

# THE READ THAT CAUSED IT IS GONE, asserted directly. A behavioural test can pass while the old path
# survives unused, waiting to be called again by the next author who sees a convenient helper.
$declarerText = Get-Content -LiteralPath $declarer -Raw -Encoding UTF8
$storeText = Get-Content -LiteralPath $store -Raw -Encoding UTF8
Assert-True ($declarerText -notmatch 'session-marker\.json') 'the declaration script no longer reads the project-wide session marker'
Assert-True ($storeText -notmatch "Get-SpecrewSessionIdentityFromMarker") 'and the helper that read it is gone from the store, not merely unused'

$roots = New-Object System.Collections.Generic.List[string]
function New-ProjectRoot {
    $r = Join-Path ([IO.Path]::GetTempPath()) ('tesi-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    New-Item -ItemType Directory -Path (Join-Path $r '.specrew/runtime') -Force | Out-Null
    $roots.Add($r) | Out-Null
    return $r
}

try {
    # ============ Case 1: the reviewer's two-session probe ==========================================
    Write-Host '  --- Case 1: two sessions in one project (the reviewer''s probe) ---'
    $root = New-ProjectRoot
    $a = Get-SpecrewTurnEndPaths -ProjectRoot $root -HostKind 'claude' -SessionId 'A'
    $b = Get-SpecrewTurnEndPaths -ProjectRoot $root -HostKind 'claude' -SessionId 'B'

    # Both hooks start a turn. B starts LAST, which is what made the old marker read resolve to B.
    $tokenA = Write-SpecrewTurnToken -StateRoot $a.StateRoot -TurnId $a.TurnId
    Start-Sleep -Milliseconds 20
    $tokenB = Write-SpecrewTurnToken -StateRoot $b.StateRoot -TurnId $b.TurnId
    Assert-True ($tokenA -ne $tokenB -and -not [string]::IsNullOrWhiteSpace($tokenA)) 'each session issued its own distinct turn token'

    # Session A runs the script. It resolves to the newest token, which is B's.
    $declared = & pwsh -NoProfile -File $declarer -Kind 'conversational' -Summary 'A did some work' -ProjectRoot $root -AsJson | ConvertFrom-Json
    Assert-True ([bool]$declared.record_written) 'the declaration is written somewhere - the script does not silently do nothing'

    $recordUnderB = Read-SpecrewTurnEndRecord -Path $b.RecordPath
    Assert-True ($null -ne $recordUnderB) 'it lands under the session whose turn started last, which is what the script can honestly see'
    Assert-True ([string]$recordUnderB.turn_token -ceq $tokenB) 'and it carries THAT session''s token, echoed - not one it invented'

    # THE DECIDING ASSERTION: A's hook must NOT accept it. Under the old design the record was simply
    # absent from A's path and A was refused with a message about not declaring - true-sounding and wrong.
    $tokenSeenByA = Read-SpecrewTurnToken -StateRoot $a.StateRoot
    $recordUnderA = Read-SpecrewTurnEndRecord -Path $a.RecordPath
    Assert-True ($tokenSeenByA -ceq $tokenA) 'session A''s hook still holds its own token'
    Assert-True ($null -eq $recordUnderA -or [string]$recordUnderA.turn_token -cne $tokenA) 'session A has no record carrying ITS token, so A fails CLOSED rather than being credited'

    # ============ Case 2: the losing session recovers on its next turn ==============================
    Write-Host '  --- Case 2: the losing session re-declares on its next turn and IS accepted ---'
    # A's turn ends and its next one begins: its hook issues a fresh token, which is now the newest.
    $null = Step-SpecrewTurnCounter -StateRoot $a.StateRoot
    $a2 = Get-SpecrewTurnEndPaths -ProjectRoot $root -HostKind 'claude' -SessionId 'A'
    Assert-True ($a2.TurnId -cne $a.TurnId) 'A''s turn advanced'
    $tokenA2 = Write-SpecrewTurnToken -StateRoot $a2.StateRoot -TurnId $a2.TurnId
    Assert-True ($tokenA2 -cne $tokenA) 'and its new turn carries a fresh token'

    $declared2 = & pwsh -NoProfile -File $declarer -Kind 'conversational' -Summary 'A did some more work' -ProjectRoot $root -AsJson | ConvertFrom-Json
    Assert-True ([bool]$declared2.record_written) 'A declares again'
    $recordUnderA2 = Read-SpecrewTurnEndRecord -Path $a2.RecordPath
    Assert-True ($null -ne $recordUnderA2) 'the record lands under A this time'
    Assert-True ($null -ne $recordUnderA2 -and [string]$recordUnderA2.turn_token -ceq $tokenA2) 'carrying the token A''s own hook issued - so A''s Stop ACCEPTS it'
    Assert-True ($null -ne $recordUnderA2 -and [string]$recordUnderA2.kind -ceq 'conversational') 'and it is the declaration A actually made'

    # ============ Case 3: absence is not mismatch ==================================================
    Write-Host '  --- Case 3: a host that issues no token still declares (absence is not mismatch) ---'
    # The rule that keeps this from bricking hosts with no turn-start event: no token on either side means
    # both degrade together. Only a token PRESENT on the hook side and different in the record fails closed.
    $quiet = New-ProjectRoot
    $found = Find-SpecrewCurrentTurnToken -ProjectRoot $quiet
    Assert-True ([string]::IsNullOrWhiteSpace($found.token)) 'no turn-start event means no token to echo'
    $declared3 = & pwsh -NoProfile -File $declarer -Kind 'conversational' -Summary 'a host with no prompt event' -ProjectRoot $quiet -AsJson | ConvertFrom-Json
    Assert-True ([bool]$declared3.record_written) 'and the session can still declare - it is not locked out'
    $quietPaths = Get-SpecrewTurnEndPaths -ProjectRoot $quiet -HostKind '' -SessionId ''
    $quietRecord = Read-SpecrewTurnEndRecord -Path $quietPaths.RecordPath
    Assert-True ($null -ne $quietRecord -and [string]::IsNullOrWhiteSpace([string]$quietRecord.turn_token)) 'the record carries no token, matching the hook that issued none'
}
finally {
    foreach ($r in $roots) { if (Test-Path -LiteralPath $r) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($script:Failures -gt 0) {
    Write-Host ("turn-end-session-identity: {0} FAILED" -f $script:Failures)
    exit 1
}
Write-Host 'turn-end-session-identity: all cases passed'
exit 0
