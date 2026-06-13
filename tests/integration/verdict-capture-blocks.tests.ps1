[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# F-174 iteration 011 (T004 building blocks): the conservative human-verdict recognizer
# (Test-SpecrewHumanVerdictToken) + the evidence-source tag on Add-SpecrewBoundaryAuthorization. SAFETY RULE
# (the maintainer's): only a CLEAR approval counts; anything negated / send-back / discuss / ambiguous / a bare
# question falls to NOT-approval so the caller records the crossing un-authorized rather than inventing one.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\bootstrap\ConversationCaptureAccessor.ps1')
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')

$scratch = Join-Path $repoRoot '.scratch\verdict-capture-blocks'
if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
New-Item -ItemType Directory -Path $scratch -Force | Out-Null

try {
    # ---- Part A: the recognizer (conservative classification) ----------------------------------------------
    $approvals = @(
        'Approve as-is',
        'Approve with instructions: keep FR-022 as an amendment',
        'approve plan -> tasks with instructions',
        'Approved for tasks',
        '1',
        '2',
        '2.'
    )
    foreach ($s in $approvals) {
        $v = Test-SpecrewHumanVerdictToken -Text $s
        if (-not $v.IsApproval) { Fail "expected APPROVE for: '$s' (got Action=$($v.Action))" }
    }
    Write-Pass "recognizer: clear approvals classified as approve ($($approvals.Count) phrasings incl. bare option numbers)"

    $notApprovals = @(
        @{ t = 'Send back: the spec needs a non-functional section'; a = 'send-back' },
        @{ t = '3'; a = 'send-back' },
        @{ t = "Approve the idea, but send back the diagram"; a = 'send-back' },   # contradictory -> safe = send-back, NOT approve
        @{ t = "Let's discuss prompt #2 before I decide"; a = 'discuss' },
        @{ t = '4'; a = 'discuss' },
        @{ t = 'do not approve yet'; a = 'none' },
        @{ t = "don't approve until the tests pass"; a = 'none' },
        @{ t = 'approve later, once you fix the clobber'; a = 'none' },
        @{ t = 'what about the antigravity case?'; a = 'none' },
        @{ t = 'I have 1 concern about the plan'; a = 'none' },                    # '1' not the whole turn
        @{ t = 'start'; a = 'none' },                                             # too ambiguous -> pending
        @{ t = ''; a = 'none' }
    )
    foreach ($c in $notApprovals) {
        $v = Test-SpecrewHumanVerdictToken -Text $c.t
        if ($v.IsApproval) { Fail "expected NOT-approve for: '$($c.t)' (it was classified approve)" }
        if ($v.Action -ne $c.a) { Fail "expected Action '$($c.a)' for: '$($c.t)', got '$($v.Action)'" }
    }
    Write-Pass "recognizer: send-back / discuss / negated / deferred / question / ambiguous -> NOT approve ($($notApprovals.Count) cases)"

    $named = Test-SpecrewHumanVerdictToken -Text 'approve plan -> tasks'
    if (($named.NamedBoundaries -notcontains 'plan') -or ($named.NamedBoundaries -notcontains 'tasks')) { Fail "named-boundary extraction must find plan + tasks" }
    Write-Pass "recognizer: named boundaries extracted for the contradiction cross-check (plan, tasks)"

    # ---- Part B: the evidence-source tag on Add-SpecrewBoundaryAuthorization --------------------------------
    function New-EnfProj {
        $proj = Join-Path $scratch ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
        $ctx = [ordered]@{
            schema               = 'v2'
            feature_path         = (Join-Path $proj 'specs\046-test')
            session_state        = [ordered]@{ active = $true; boundary_type = 'plan'; feature_ref = '046-test'; iteration_number = '001'; recorded_at = '2026-01-01T00:00:00Z' }
            boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'plan'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
        }
        [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
        return $proj
    }

    $pA = New-EnfProj
    Add-SpecrewBoundaryAuthorization -ProjectRoot $pA -CurrentBoundary 'plan' -AuthorizedBoundary 'tasks' -AuthorizingHuman 'Alon' -VerdictText 'approved for tasks' -AuthCommitHash 'TESTHASH' -RecordedAt '2026-01-01T00:00:00Z' -EvidenceSource 'hook-captured-from-transcript' | Out-Null
    $ctxA = Get-Content -LiteralPath (Join-Path $pA '.specrew\start-context.json') -Raw | ConvertFrom-Json -Depth 12
    $vA = @($ctxA.boundary_enforcement.verdict_history)[-1]
    if ($vA.evidence_source -ne 'hook-captured-from-transcript') { Fail "evidence_source expected 'hook-captured-from-transcript', got '$($vA.evidence_source)'" }
    Write-Pass "evidence tag: a hook-captured authorization records evidence_source='hook-captured-from-transcript'"

    $pB = New-EnfProj
    Add-SpecrewBoundaryAuthorization -ProjectRoot $pB -CurrentBoundary 'plan' -AuthorizedBoundary 'tasks' -AuthorizingHuman 'Alon' -VerdictText 'approved for tasks' -AuthCommitHash 'TESTHASH' -RecordedAt '2026-01-01T00:00:00Z' | Out-Null
    $ctxB = Get-Content -LiteralPath (Join-Path $pB '.specrew\start-context.json') -Raw | ConvertFrom-Json -Depth 12
    $vB = @($ctxB.boundary_enforcement.verdict_history)[-1]
    if ($vB.evidence_source -ne 'unspecified') { Fail "omitted EvidenceSource must default to 'unspecified', got '$($vB.evidence_source)'" }
    Write-Pass "evidence tag: omitted EvidenceSource defaults to 'unspecified' (never blank, never fabricated)"

    Write-Host "`n=== verdict-capture-blocks.tests.ps1: all assertions passed ===" -ForegroundColor Green
    exit 0
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
