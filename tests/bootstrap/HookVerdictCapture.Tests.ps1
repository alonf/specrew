$ErrorActionPreference = 'Stop'

# F-174 iteration 011 (T004, FR-026 / decision f174-i011-verdict-authority-stop-hook): END-TO-END proof that
# THE STOP HOOK IS THE VERDICT AUTHORITY. Invokes the real handover Stop-hook provider with a transcript that
# carries a boundary packet MARKER + a human approval, and proves the hook captured the human's verdict and
# advanced boundary_enforcement.last_authorized_boundary with evidence-source 'hook-captured-from-transcript'.
# Then proves the negatives: no marker -> no advance; a send-back -> no advance (the resume surfaces pending).
# This is the live counterpart to the unit-level verdict-capture-blocks tests; it exercises the actual hot path.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-handover-provider.ps1").Path
$marker = '<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->'

function New-CaptureProject {
    param([object[]]$Turns)
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-vcap-" + [guid]::NewGuid().ToString('N'))
    $proj = Join-Path $tmp 'proj'
    New-Item -ItemType Directory -Path (Join-Path $proj 'specs/001-feat') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $proj '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t' 2>$null; git -C $proj config user.name 't' 2>$null
    git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null
    git -C $proj checkout -q -b '001-feat' 2>$null
    # Schema v2 start-context: the WORKING boundary is before-implement; the last HUMAN-authorized is tasks
    # (so a before-implement approval is a FORWARD advance the hook should record).
    $ctx = [ordered]@{
        schema               = 'v2'
        session_state        = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '001-feat'; host = 'claude'; iteration_number = '001'; recorded_at = '2026-01-01T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    # The transcript (Claude JSONL shape).
    $tx = Join-Path $tmp 'transcript.jsonl'
    $lines = foreach ($t in $Turns) { (@{ type = $t.role; message = @{ role = $t.role; content = @(@{ type = 'text'; text = $t.text }) } } | ConvertTo-Json -Depth 8 -Compress) }
    [System.IO.File]::WriteAllText($tx, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Tmp = $tmp; Proj = $proj; Transcript = $tx }
}

function Invoke-StopHook { param([string]$Proj, [string]$Tx) & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $Proj --host-kind claude --transcript-path $Tx 2>$null | Out-Null }
function Read-Enforcement { param([string]$Proj) return (Get-Content -LiteralPath (Join-Path $Proj '.specrew/start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12).boundary_enforcement }

$cases = @()
try {
    # === Case 1: marker packet + human approval -> the hook advances the gate with hook-captured evidence. ===
    $c1 = New-CaptureProject -Turns @(
        @{ role = 'assistant'; text = "tasks boundary packet. $marker What's your verdict?" },
        @{ role = 'user'; text = 'Approve with instructions: fold T008 in' })
    $cases += $c1.Tmp
    Invoke-StopHook -Proj $c1.Proj -Tx $c1.Transcript
    $e1 = Read-Enforcement -Proj $c1.Proj
    Assert-True ([string]$e1.last_authorized_boundary -eq 'before-implement') "FIX: the Stop hook ADVANCED last_authorized_boundary tasks -> before-implement from the captured human approval (got '$($e1.last_authorized_boundary)')"
    $v1 = @($e1.verdict_history)[-1]
    Assert-True ([string]$v1.to_boundary -eq 'before-implement') "the recorded verdict_history entry targets before-implement"
    Assert-True ([string]$v1.evidence_source -eq 'hook-captured-from-transcript') "the verdict is tagged evidence_source='hook-captured-from-transcript' (not fabricated; got '$($v1.evidence_source)')"
    Assert-True ([string]$v1.authorizing_human -eq 'unattributed') "identity is UNATTRIBUTED (no host surface proved it) — honest over invented (got '$($v1.authorizing_human)')"

    # === Case 2: NO marker -> the hook does NOT advance (the human re-confirms via the pending surface). ===
    $c2 = New-CaptureProject -Turns @(
        @{ role = 'assistant'; text = "a packet with no marker. verdict?" },
        @{ role = 'user'; text = 'Approve' })
    $cases += $c2.Tmp
    Invoke-StopHook -Proj $c2.Proj -Tx $c2.Transcript
    $e2 = Read-Enforcement -Proj $c2.Proj
    Assert-True ([string]$e2.last_authorized_boundary -eq 'tasks') "no packet marker -> gate stays at tasks (no guessed advance); resume surfaces pending (got '$($e2.last_authorized_boundary)')"
    Assert-True (@($e2.verdict_history).Count -eq 0) "no marker -> no verdict_history entry written"

    # === Case 3: marker + send-back -> the hook does NOT advance (un-authorized). ===
    $c3 = New-CaptureProject -Turns @(
        @{ role = 'assistant'; text = "packet $marker verdict?" },
        @{ role = 'user'; text = 'Send back: the plan needs a rollback path' })
    $cases += $c3.Tmp
    Invoke-StopHook -Proj $c3.Proj -Tx $c3.Transcript
    $e3 = Read-Enforcement -Proj $c3.Proj
    Assert-True ([string]$e3.last_authorized_boundary -eq 'tasks') "marker + send-back -> gate stays at tasks (un-authorized, no fabrication)"

    Write-Host "`n=== HookVerdictCapture.Tests.ps1: all assertions passed (the hook IS the verdict authority) ===" -ForegroundColor Green
}
finally {
    foreach ($t in $cases) { Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue }
}
