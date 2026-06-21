$ErrorActionPreference = 'Stop'

# F-174 iteration 011 (T004, FR-026 / decision f174-i011-verdict-authority-stop-hook): END-TO-END proof that
# THE STOP HOOK IS THE VERDICT AUTHORITY — and that it advances the gate ONE BOUNDARY AT A TIME. Invokes the
# real handover Stop-hook provider with a transcript carrying a boundary packet MARKER + a human approval, and
# asserts the hook captured the verdict and advanced boundary_enforcement.last_authorized_boundary ONLY when the
# capture is CONTIGUOUS with the authorized cursor (marker FROM == cursor, marker TO == FROM's immediate
# successor). The GATE-CONTIGUITY cases (4-6) are the falsification the maintainer found: forward-only is not
# enough — a real approval for 'tasks -> before-implement' must NOT be applied when 'plan -> tasks' was never
# authorized (it would skip a gate). Case 7 pins idempotence.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-handover-provider.ps1").Path

function New-CaptureProject {
    param([string]$LastAuth = 'tasks', [object[]]$Turns)
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-vcap-" + [guid]::NewGuid().ToString('N'))
    $proj = Join-Path $tmp 'proj'
    New-Item -ItemType Directory -Path (Join-Path $proj 'specs/001-feat') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $proj '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t' 2>$null; git -C $proj config user.name 't' 2>$null
    git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null
    git -C $proj checkout -q -b '001-feat' 2>$null
    $ctx = [ordered]@{
        schema               = 'v2'
        session_state        = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '001-feat'; host = 'claude'; iteration_number = '001'; recorded_at = '2026-01-01T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = $LastAuth; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    $tx = Join-Path $tmp 'transcript.jsonl'
    $lines = foreach ($t in $Turns) { (@{ type = $t.role; message = @{ role = $t.role; content = @(@{ type = 'text'; text = $t.text }) } } | ConvertTo-Json -Depth 8 -Compress) }
    [System.IO.File]::WriteAllText($tx, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Tmp = $tmp; Proj = $proj; Transcript = $tx }
}
function Invoke-StopHook { param([string]$Proj, [string]$Tx) & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $Proj --host-kind claude --transcript-path $Tx 2>$null | Out-Null }
function Read-Enforcement { param([string]$Proj) return (Get-Content -LiteralPath (Join-Path $Proj '.specrew/start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12).boundary_enforcement }
function Packet { param([string]$From, [string]$To, [string]$Resp) return @(
        @{ role = 'assistant'; text = "boundary packet. <!-- SPECREW-VERDICT-BOUNDARY: $From -> $To --> What's your verdict?" },
        @{ role = 'user'; text = $Resp }) }

$cases = @()
try {
    # === Case 1 (maintainer test 1) — CONTIGUOUS: lastAuth=tasks + marker tasks->before-implement + approval -> AUTHORIZES. ===
    $c1 = New-CaptureProject -LastAuth 'tasks' -Turns (Packet 'tasks' 'before-implement' 'Approve as-is'); $cases += $c1.Tmp
    Invoke-StopHook -Proj $c1.Proj -Tx $c1.Transcript
    $e1 = Read-Enforcement -Proj $c1.Proj
    Assert-True ([string]$e1.last_authorized_boundary -eq 'before-implement') "1 CONTIGUOUS: tasks + (tasks->before-implement) + approve -> gate ADVANCES to before-implement (got '$($e1.last_authorized_boundary)')"
    $v1 = @($e1.verdict_history)[-1]
    Assert-True ([string]$v1.evidence_source -eq 'hook-captured-from-transcript' -and [string]$v1.authorizing_human -eq 'unattributed') "1: recorded with evidence_source=hook-captured-from-transcript + authorizing_human=unattributed"

    # === Case 2 — capture mechanics: NO marker -> no advance. ===
    $c2 = New-CaptureProject -LastAuth 'tasks' -Turns @(@{ role = 'assistant'; text = 'packet with no marker. verdict?' }, @{ role = 'user'; text = 'Approve' }); $cases += $c2.Tmp
    Invoke-StopHook -Proj $c2.Proj -Tx $c2.Transcript
    Assert-True ([string](Read-Enforcement -Proj $c2.Proj).last_authorized_boundary -eq 'tasks') "2: no marker -> gate stays at tasks (resume surfaces pending)"

    # === Case 3 — capture mechanics: send-back -> no advance. ===
    $c3 = New-CaptureProject -LastAuth 'tasks' -Turns (Packet 'tasks' 'before-implement' 'Send back: needs a rollback path'); $cases += $c3.Tmp
    Invoke-StopHook -Proj $c3.Proj -Tx $c3.Transcript
    Assert-True ([string](Read-Enforcement -Proj $c3.Proj).last_authorized_boundary -eq 'tasks') "3: marker + send-back -> gate stays at tasks (un-authorized)"

    # === Case 4 (maintainer test 2) — THE BUG: lastAuth=plan + marker tasks->before-implement + approval -> does NOT authorize (would skip plan->tasks). ===
    $c4 = New-CaptureProject -LastAuth 'plan' -Turns (Packet 'tasks' 'before-implement' 'Approve as-is'); $cases += $c4.Tmp
    Invoke-StopHook -Proj $c4.Proj -Tx $c4.Transcript
    $e4 = Read-Enforcement -Proj $c4.Proj
    Assert-True ([string]$e4.last_authorized_boundary -eq 'plan') "4 FROM-SKIP (the bug): plan + (tasks->before-implement) + approve -> gate STAYS at plan; the real approval is NOT applied to a skipped gate (got '$($e4.last_authorized_boundary)')"
    Assert-True (@($e4.verdict_history).Count -eq 0) "4: no verdict_history entry written for the non-contiguous capture"

    # === Case 5 (maintainer test 3) — FROM-MISMATCH: lastAuth=tasks + marker plan->before-implement + approval -> does NOT authorize. ===
    $c5 = New-CaptureProject -LastAuth 'tasks' -Turns (Packet 'plan' 'before-implement' 'Approve as-is'); $cases += $c5.Tmp
    Invoke-StopHook -Proj $c5.Proj -Tx $c5.Transcript
    Assert-True ([string](Read-Enforcement -Proj $c5.Proj).last_authorized_boundary -eq 'tasks') "5 FROM-MISMATCH: tasks + (plan->before-implement) marker -> gate STAYS at tasks (marker FROM != cursor)"

    # === Case 6 (maintainer test 4) — TO-JUMP: lastAuth=tasks + marker tasks->review-signoff + approval -> does NOT authorize (skips before-implement). ===
    $c6 = New-CaptureProject -LastAuth 'tasks' -Turns (Packet 'tasks' 'review-signoff' 'Approve as-is'); $cases += $c6.Tmp
    Invoke-StopHook -Proj $c6.Proj -Tx $c6.Transcript
    Assert-True ([string](Read-Enforcement -Proj $c6.Proj).last_authorized_boundary -eq 'tasks') "6 TO-JUMP: tasks + (tasks->review-signoff) marker -> gate STAYS at tasks (TO is not FROM's immediate successor)"

    # === Case 7 (maintainer test 5) — IDEMPOTENT: a duplicate Stop after the boundary is already authorized does NOT re-record. ===
    $c7 = New-CaptureProject -LastAuth 'tasks' -Turns (Packet 'tasks' 'before-implement' 'Approve with instructions'); $cases += $c7.Tmp
    Invoke-StopHook -Proj $c7.Proj -Tx $c7.Transcript
    Invoke-StopHook -Proj $c7.Proj -Tx $c7.Transcript   # fire again
    $e7 = Read-Enforcement -Proj $c7.Proj
    Assert-True ([string]$e7.last_authorized_boundary -eq 'before-implement') "7 IDEMPOTENT: gate at before-implement after two stops"
    Assert-True (@($e7.verdict_history).Count -eq 1) "7 IDEMPOTENT: exactly ONE verdict_history entry (the re-fired Stop's marker FROM no longer matches the advanced cursor) (got $(@($e7.verdict_history).Count))"

    # === Case 8 — FIRST BOUNDARY: no lastAuth + marker intake->specify + approval -> AUTHORIZES specify. ===
    $c8 = New-CaptureProject -LastAuth '' -Turns (Packet 'intake' 'specify' 'approved for specify'); $cases += $c8.Tmp
    Invoke-StopHook -Proj $c8.Proj -Tx $c8.Transcript
    $e8 = Read-Enforcement -Proj $c8.Proj
    Assert-True ([string]$e8.last_authorized_boundary -eq 'specify') "8 FIRST: none + (intake->specify) + approve -> gate ADVANCES to specify (got '$($e8.last_authorized_boundary)')"
    $v8 = @($e8.verdict_history)[-1]
    Assert-True ([string]$v8.to_boundary -eq 'specify') "8: first verdict_history to_boundary=specify"
    Assert-True ([string]::IsNullOrWhiteSpace([string]$v8.from_boundary)) "8: first verdict_history from_boundary is empty/null (intake is marker-only, not a canonical persisted boundary)"

    # === Case 9 — FIRST BOUNDARY WRONG MARKER: no lastAuth + marker specify->clarify + approval -> does NOT authorize. ===
    $c9 = New-CaptureProject -LastAuth '' -Turns (Packet 'specify' 'clarify' 'approved for clarify'); $cases += $c9.Tmp
    Invoke-StopHook -Proj $c9.Proj -Tx $c9.Transcript
    $e9 = Read-Enforcement -Proj $c9.Proj
    Assert-True ([string]::IsNullOrWhiteSpace([string]$e9.last_authorized_boundary)) "9 FIRST-WRONG: none + (specify->clarify) + approve -> gate STAYS unauthorized until intake->specify is captured (got '$($e9.last_authorized_boundary)')"
    Assert-True (@($e9.verdict_history).Count -eq 0) "9: no verdict_history entry written for the non-contiguous first-boundary marker"

    Write-Host "`n=== HookVerdictCapture.Tests.ps1: all assertions passed (the hook is the verdict authority AND advances one boundary at a time) ===" -ForegroundColor Green
}
finally {
    foreach ($t in $cases) { Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue }
}
