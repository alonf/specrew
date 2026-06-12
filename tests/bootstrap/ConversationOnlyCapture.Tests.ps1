$ErrorActionPreference = 'Stop'

# F-174 iteration 010 (Prop-145 round-4, HIGH). FALSIFICATION floor for the reviewer finding "conversation-only
# progress is not captured": the material-change gate (boundary OR tracked-file change) returned no-material-change
# and never reached the transcript read, so a pure analysis/conversation turn (clean tree, same boundary) lost its
# conversation. Fix: END-OF-TURN events (Stop/agentStop/stop) refresh regardless (capture the transcript tail +
# recorded_at), while the activity bullet stays delta-gated so conversation-only turns do NOT flush real work out
# of the 6-bullet window. This reproduces the reviewer's harness: one real-work Stop, then THREE conversation-only
# Stops, asserting the new conversation is captured each time AND the real-work bullet survives.

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/HandoverStore.ps1"
. "$base/ClassificationEngine.ps1"
. "$base/ProjectMetadataAccessor.ps1"
. "$base/ConversationCaptureAccessor.ps1"
function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$activityTitle = 'What I just did (last 3-5 turns or last boundary work)'
$convoTitle = 'Recent conversation (last few exchanges, hook-captured)'

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("convo-only-" + [guid]::NewGuid().ToString('N'))
$proj = Join-Path $tmp 'proj'
New-Item -ItemType Directory -Path (Join-Path $proj 'specs/myfeat') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
$transcript = Join-Path $tmp 'convo.jsonl'
$hd = Join-Path $proj '.specrew/handover'
$rf = Join-Path $hd 'session-handover.md'
try {
    (@{ session_state = @{ feature_ref = 'myfeat'; boundary_type = 'plan'; host = 'cursor' } } | ConvertTo-Json -Depth 5) |
        Set-Content -LiteralPath (Join-Path $proj '.specrew/start-context.json') -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $proj '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t'; git -C $proj config user.name 't'
    git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null

    function Add-Turn { param($Role, $Text) Add-Content -LiteralPath $transcript -Value ('{"role":"' + $Role + '","message":{"content":[{"type":"text","text":"' + $Text + '"}]}}') -Encoding UTF8 }
    function Read-Section { param($Title) (ConvertFrom-SpecrewHandoverFile -Path $rf).sections[$Title] }

    # 1. REAL-WORK turn: an uncommitted USER file (root-level, not Specrew-managed) + conversation CANARY-1.
    Set-Content -LiteralPath (Join-Path $proj 'myapp.py') -Value "print('real work')" -Encoding UTF8
    Add-Turn 'user' 'CANARY-CONVO-1 do the work'; Add-Turn 'assistant' 'real work done'
    Update-SpecrewRollingHandover -ProjectRoot $proj -HostKind cursor -Source 'stop' -NowUtc '2026-06-12T10:00:00Z' -TranscriptPath $transcript | Out-Null
    $act1 = [string](Read-Section $activityTitle)
    Assert-True ($act1 -match '1 changed user file') 'first (real-work) Stop recorded a real-work activity bullet (1 changed user file)'
    Assert-True ([string](Read-Section $convoTitle) -match 'CANARY-CONVO-1') 'first Stop captured the conversation'

    # Revert the uncommitted file -> clean tree at the SAME HEAD (NO new commit - committing would itself count
    # as real work). Now any further Stop is genuinely CONVERSATION-ONLY: no changed files AND no new commit.
    Remove-Item -LiteralPath (Join-Path $proj 'myapp.py') -Force

    # 2-4. THREE conversation-only Stops. Each must CAPTURE the new turn AND preserve the real-work bullet.
    $t = 11
    foreach ($n in 2, 3, 4) {
        Add-Turn 'assistant' "CANARY-CONVO-$n only-talking"
        Update-SpecrewRollingHandover -ProjectRoot $proj -HostKind cursor -Source 'stop' -NowUtc ("2026-06-12T{0}:00:00Z" -f $t) -TranscriptPath $transcript | Out-Null
        $t++
        $convo = [string](Read-Section $convoTitle)
        $act = [string](Read-Section $activityTitle)
        Assert-True ($convo -match "CANARY-CONVO-$n") "conversation-only Stop #$n CAPTURED the new turn (the gate no longer skips end-of-turn)"
        Assert-True ($act -match '1 changed user file') "conversation-only Stop #$n PRESERVED the real-work bullet (not flushed)"
        Assert-True (-not ($act -match '0 changed user file')) "conversation-only Stop #$n did NOT add a '0 changed' noise bullet"
    }
    # After 3 conversation-only turns the real-work bullet is STILL the only activity bullet.
    $bullets = @([string](Read-Section $activityTitle) -split "`n" | Where-Object { $_ -match '^\s*-\s' })
    Assert-True ($bullets.Count -eq 1) 'the activity log still holds exactly the one real-work bullet (no conversation-noise accretion)'

    Write-Host "`n=== ConversationOnlyCapture.Tests.ps1: all assertions passed ===" -ForegroundColor Green
}
finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
