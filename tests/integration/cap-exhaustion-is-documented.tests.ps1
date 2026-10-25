[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W53 (2026-08-24, maintainer ruling): AN EXEMPTION-BY-EXHAUSTION IS A DOCUMENTED EVENT, NOT AN
# AMBIENT STATE.
#
# The stop discipline capped out on the crew that built it, silently - the store showed the material
# nudge a week stale and the evidence-absent counter parked at its cap, while every capped turn read
# exactly like a complied one. The existing announcement corrections were real but landed on a channel
# the claude Stop hook drops (plain stdout is not delivered to the model on a Stop), so from the
# transcript "complied" and "outlasted" were indistinguishable - and the maintainer caught the
# difference from the outside, which is exactly how it must not be caught.
#
# The ruling, two parts, both pinned here:
#   1. The FIRST capped stop announces itself through the one channel that reaches the transcript -
#      a stop-block whose directive is to include the one-line cap notice in the final permitted
#      output - and records a durable fact BEFORE it fires, so the extra block is bounded by the
#      same durability rule as the counter (an unverifiable write must not add an unrecorded block).
#   2. Subsequent capped stops do NOT re-block (the cap still caps); the fact is written once per
#      session per unmet advance, and a fresh session announces again because its counters are its own.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
if (-not (Test-Path -LiteralPath $provider)) { Fail "conformance provider not found at $provider" }
. (Join-Path $repoRoot 'scripts\internal\specrew-consumer-language.ps1')

$priorModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ('specrew-cap-doc-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch -Force | Out-Null

try {
    # --- fixture: a project mid-crossing whose stops keep omitting the packet, the exact shape the
    #     walk produced. Minimal but real: the provider runs as the dispatcher runs it.
    $proj = Join-Path $scratch 'proj'
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    $specDir = Join-Path $proj 'specs\050-cap-fixture'
    New-Item -ItemType Directory -Path $specDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $specDir 'spec.md') -Value "# Feature Specification: Cap Fixture`n`nThe authoritative contract." -Encoding UTF8
    $ctx = [ordered]@{
        schema               = 'v2'
        feature_path         = $specDir
        session_state        = [ordered]@{ active = $true; boundary_type = 'plan'; feature_ref = '050-cap-fixture'; iteration_number = '001'; recorded_at = '2026-08-24T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'specify'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    $null = & git -C $proj init --quiet
    $null = & git -C $proj config core.autocrlf false
    $null = & git -C $proj add -A
    $null = & git -C $proj -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m 'fixture baseline'
    if ($LASTEXITCODE -ne 0) { Fail 'fixture baseline commit failed' }

    function New-Transcript {
        param([string]$Text)
        $dir = Join-Path $proj '.specrew\runtime'
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $path = Join-Path $dir ('transcript-' + [guid]::NewGuid().ToString('N') + '.jsonl')
        $line = ([pscustomobject]@{ type = 'assistant'; message = [pscustomobject]@{ content = @([pscustomobject]@{ type = 'text'; text = $Text }) } } | ConvertTo-Json -Depth 8 -Compress)
        [System.IO.File]::WriteAllLines($path, [string[]]@($line), [System.Text.UTF8Encoding]::new($false))
        return $path
    }

    function Invoke-Stop {
        param([string]$SessionId, [int]$Turn)
        # A NEW transcript per stop: the loop produces a new packet-less message each forced turn.
        $tp = New-Transcript -Text ("I did some more work on the plan (turn $Turn) and here is a summary of it.")
        $cmd = "Set-Location -LiteralPath '$proj'; & '$provider' --host-kind claude --source-event Stop --session-id '$SessionId' --transcript-path '$tp'"
        $out = & pwsh -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1
        $rendered = (@($out) -join "`n")
        return [pscustomobject]@{ Out = $rendered; Blocked = ($rendered -match '<<<SPECREW-STOP-BLOCK>>>') }
    }

    function Get-SessionStateRoot {
        param([string]$SessionId)
        $owner = "claude|$SessionId"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($owner)
        $hash = -join ([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })
        return (Join-Path (Join-Path $proj '.specrew/runtime/conformance-sessions') $hash)
    }

    $s1 = 'cap-doc-session-one'

    # --- 1..3: the discipline blocks, exactly as designed. Nothing here changes.
    for ($i = 1; $i -le 3; $i++) {
        $r = Invoke-Stop -SessionId $s1 -Turn $i
        if (-not $r.Blocked) { Fail "stop $i should be BLOCKED (count below the cap). Out: $($r.Out)" }
    }
    Write-Pass 'stops 1-3 are blocked - the discipline enforces up to its cap unchanged'

    # --- 4: THE FIRST CAPPED STOP. This is the ruling's surface: one more block, whose directive is
    #     the one-line notice in the final permitted output, backed by a durable fact.
    $r4 = Invoke-Stop -SessionId $s1 -Turn 4
    if (-not $r4.Blocked) { Fail "the FIRST capped stop must announce itself as a stop-block so the notice reaches the transcript. Out: $($r4.Out)" }
    if ($r4.Out -notmatch 'packet discipline capped for this session after 3 refusals') {
        Fail "the announcement must carry the exact one-line notice for the final permitted output. Out: $($r4.Out)"
    }
    if ($r4.Out -notmatch '(?i)still unmet') { Fail "the announcement must say the requirement is STILL UNMET - released is not satisfied. Out: $($r4.Out)" }
    $banned = @(Get-SpecrewBannedConsumerNoun -Text $r4.Out)
    if ($banned.Count -gt 0) { Fail "the announcement leaked internal vocabulary [$($banned -join ', ')]: $($r4.Out)" }
    Write-Pass 'the first capped stop announces itself, with the exact one-line notice and no internal vocabulary'

    $capFacts = Join-Path (Get-SessionStateRoot -SessionId $s1) 'cap-facts.jsonl'
    if (-not (Test-Path -LiteralPath $capFacts -PathType Leaf)) { Fail "the cap fact file must exist after the announcement: $capFacts" }
    $facts = @(Get-Content -LiteralPath $capFacts -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
    if (@($facts).Count -ne 1) { Fail "exactly ONE cap fact after the announcement, got $(@($facts).Count)" }
    if ([string]$facts[0].fact_type -ne 'conformance-cap-reached') { Fail "the fact names its type: got '$($facts[0].fact_type)'" }
    if ([int]$facts[0].cap -ne 3) { Fail "the fact records the cap that was reached: got '$($facts[0].cap)'" }
    if ([string]::IsNullOrWhiteSpace([string]$facts[0].advance_key)) { Fail 'the fact records WHICH advance capped' }
    if ([string]::IsNullOrWhiteSpace([string]$facts[0].block_kind)) { Fail 'the fact records the block kind' }
    Write-Pass 'the cap is a recorded fact: type, cap, advance key and kind, durably on disk'

    # --- 5: the cap still caps. No announcement loop - the fact was written once, so this stop is
    #     released without a block, and no second fact appears.
    $r5 = Invoke-Stop -SessionId $s1 -Turn 5
    if ($r5.Blocked) { Fail "a SECOND capped stop must not block again - the announcement is one turn, not a new loop. Out: $($r5.Out)" }
    $factsAfter = @(Get-Content -LiteralPath $capFacts -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
    if (@($factsAfter).Count -ne 1) { Fail "still exactly ONE cap fact after a later capped stop, got $(@($factsAfter).Count)" }
    Write-Pass 'later capped stops stay released and mint no duplicate fact - the announcement cannot become a hang'

    # --- a FRESH session: its counters are its own, so the discipline enforces again from zero and,
    #     if outlasted again, announces again - a cap is per session, never a permanent exemption.
    $s2 = 'cap-doc-session-two'
    $fresh = Invoke-Stop -SessionId $s2 -Turn 1
    if (-not $fresh.Blocked) { Fail "a fresh session must be enforced from zero - the old session's exhaustion is not its exemption. Out: $($fresh.Out)" }
    Write-Pass 'a fresh session starts enforced - exhaustion does not carry across sessions'
}
finally {
    if ($null -eq $priorModulePath) { Remove-Item Env:SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $priorModulePath }
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'cap exhaustion is documented: all assertions pass' -ForegroundColor Green
