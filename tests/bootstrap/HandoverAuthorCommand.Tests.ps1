$ErrorActionPreference = 'Stop'

# F-174 iteration 011 (T001, FR-022 / DF-7, SC-012 / SC-015): PROVE the agent-callable handover BODY-authoring
# surface `specrew handover author`. This is the reachable replacement for the un-exported
# Write-SpecrewHandoverContext (the directive now NAMES this command). The tests drive the REAL command
# (scripts/specrew-handover.ps1) and the dispatcher wiring (scripts/specrew.ps1 handover ...) against scratch
# projects, then read the rolling handover back with the SAME parser a resume uses, asserting:
#   1. the authored body (esp. the INTERPRETIVE sections no hook can author) round-trips verbatim (SC-012);
#   2. tolerant `## ` headers (short / reordered) map to the canonical handover sections;
#   3. the `specrew handover` dispatcher arm forwards to the command;
#   4. unrecognized headers are reported + ignored (never written);
#   5. authoring does NOT clobber a hook-captured boundary packet (the centralized clobber guard, SC-015).

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$cmd = Join-Path $repoRoot 'scripts/specrew-handover.ps1'
$dispatcher = Join-Path $repoRoot 'scripts/specrew.ps1'
$provider = Join-Path $repoRoot 'scripts/internal/specrew-handover-provider.ps1'
. (Resolve-Path (Join-Path $repoRoot 'scripts/internal/bootstrap/HandoverStore.ps1')).Path
$capturedTitle = @(Get-SpecrewHandoverCapturedSections)[0]

function New-Project {
    param([string]$Boundary = 'before-implement', [string]$FeatureRef = '001-feat', [string]$HostKind = 'claude', [switch]$WithGit)
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-hauthor-" + [guid]::NewGuid().ToString('N'))
    $proj = Join-Path $tmp 'proj'
    New-Item -ItemType Directory -Path (Join-Path $proj 'specs/001-feat') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    if ($WithGit) {
        Set-Content -LiteralPath (Join-Path $proj '.gitignore') -Value ".specrew/`n" -Encoding UTF8
        git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t' 2>$null; git -C $proj config user.name 't' 2>$null
        git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null
        git -C $proj checkout -q -b $FeatureRef 2>$null
    }
    $ctx = [ordered]@{
        schema               = 'v2'
        session_state        = [ordered]@{ active = $true; boundary_type = $Boundary; feature_ref = $FeatureRef; host = $HostKind; iteration_number = '001'; recorded_at = '2026-01-01T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Tmp = $tmp; Proj = $proj; Transcript = (Join-Path $tmp 'transcript.jsonl') }
}
function Write-Draft { param([string]$Tmp, [string]$Body) $p = Join-Path $Tmp 'draft.md'; [System.IO.File]::WriteAllText($p, $Body, [System.Text.UTF8Encoding]::new($false)); return $p }
function Invoke-Author { param([string]$Proj, [string]$Draft, [string[]]$Extra = @()) return @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $cmd author --from $Draft --project-path $Proj @Extra 2>&1 | ForEach-Object { [string]$_ }) }
function Read-Handover { param([string]$Proj) return (ConvertFrom-SpecrewHandoverFile -Path (Join-Path $Proj '.specrew/handover/session-handover.md')) }

$cases = @()
try {
    # === 1. Round-trip — the interpretive + narrative body lands verbatim; feature/boundary/host resolved from session_state. ===
    $c1 = New-Project -Boundary 'before-implement' -HostKind 'claude'; $cases += $c1.Tmp
    $draft1 = Write-Draft -Tmp $c1.Tmp -Body @"
## What I just did
Implemented the handover-author parser and wired the dispatcher arm in scripts/specrew.ps1.

## Open questions
Should the matcher also accept the Rule-46 gate-stop headers? Parked — the handover body uses the Pillar-2 titles.

## Working hypothesis
A resuming session will trust last_authorized_boundary; this body carries my interpretive reasoning across the switch.

## Recommended next step
Run the focused tests, then move to T007 deterministic consolidation.
"@
    $out1 = Invoke-Author -Proj $c1.Proj -Draft $draft1
    Assert-True ($LASTEXITCODE -eq 0) '1: author exits 0'
    $h1 = Read-Handover -Proj $c1.Proj
    $oq = [string]$h1.sections['Open questions / pending clarifications']
    $wh = [string]$h1.sections["Agent's working hypothesis / mental model"]
    $wd = [string]$h1.sections['What I just did (last 3-5 turns or last boundary work)']
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content $oq) '1: Open questions (interpretive) is AUTHORED, not a placeholder'
    Assert-True ($oq -like '*Should the matcher also accept the Rule-46*') '1: Open questions content round-trips verbatim'
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content $wh) '1: Working hypothesis (interpretive) is AUTHORED'
    Assert-True ($wh -like '*trust last_authorized_boundary*') '1: Working hypothesis content round-trips verbatim'
    Assert-True ($wd -like '*Implemented the handover-author parser*') '1: a narrative section (What I just did) also round-trips'
    Assert-True ([string]$h1.active_boundary -eq 'before-implement') '1: active_boundary resolved from session_state'
    Assert-True ([string]$h1.from_host -eq 'claude') '1: from_host resolved from session_state'
    Assert-True ([string]$h1.source -eq 'agent') '1: source recorded as agent (the agent-authored body)'

    # === 2. Tolerant headers — short / reordered '## ' headers map to the canonical handover sections. ===
    $c2 = New-Project -Boundary 'plan'; $cases += $c2.Tmp
    $draft2 = Write-Draft -Tmp $c2.Tmp -Body @"
## Context
The branch is mid-plan; the spec is approved and the iteration cap is 32.

## Recommended next
Present the plan boundary packet and await the human verdict.
"@
    Invoke-Author -Proj $c2.Proj -Draft $draft2 | Out-Null
    $h2 = Read-Handover -Proj $c2.Proj
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content ([string]$h2.sections["Context the receiving host needs that artifacts don't carry"])) "2: '## Context' maps to the canonical Context section"
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content ([string]$h2.sections['Recommended next-immediate-step'])) "2: '## Recommended next' maps to the canonical Recommended-next section"

    # === 3. Dispatcher arm — `specrew handover author ...` forwards to the command. ===
    $c3 = New-Project -Boundary 'before-implement'; $cases += $c3.Tmp
    $draft3 = Write-Draft -Tmp $c3.Tmp -Body "## Open questions`nDoes the dispatcher arm forward correctly?"
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $dispatcher handover author --from $draft3 --project-path $c3.Proj 2>&1 | Out-Null
    Assert-True ($LASTEXITCODE -eq 0) '3: the specrew.ps1 handover dispatcher arm exits 0'
    Assert-True (Test-Path -LiteralPath (Join-Path $c3.Proj '.specrew/handover/session-handover.md')) '3: the dispatcher arm produced the handover file'
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content ([string](Read-Handover -Proj $c3.Proj).sections['Open questions / pending clarifications'])) '3: the dispatcher-routed author wrote the section'

    # === 4. Unrecognized headers are reported + ignored; a recognized header still lands. ===
    $c4 = New-Project -Boundary 'before-implement'; $cases += $c4.Tmp
    $draft4 = Write-Draft -Tmp $c4.Tmp -Body @"
## Totally Bogus Header
this should be ignored

## Open questions
this should be written
"@
    $out4 = (Invoke-Author -Proj $c4.Proj -Draft $draft4) -join "`n"
    Assert-True ($out4 -match 'ignored.*Totally Bogus Header') '4: an unrecognized header is reported as ignored'
    $h4 = Read-Handover -Proj $c4.Proj
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content ([string]$h4.sections['Open questions / pending clarifications'])) '4: the recognized Open-questions header still lands'
    Assert-True (-not ($h4.sections.Keys -contains 'Totally Bogus Header')) '4: the bogus header is NOT written as a section'

    # === 5. Clobber guard — authoring the interpretive body does NOT clobber a hook-captured boundary packet (SC-015). ===
    $c5 = New-Project -Boundary 'before-implement' -WithGit; $cases += $c5.Tmp
    $packet = @"
<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->

## What I Just Did
Completed the tasks boundary work.

## Why I Stopped
This is a human-verdict boundary; advancing needs your explicit approval.

## What Needs Your Review
The task breakdown traced to the spec acceptance criteria.

## What Happens Next
On approval the lifecycle advances to before-implement.

## Discussion Prompts
1. Are the estimates right-sized?

## What I Need From You
What's your verdict? 1. Approve as-is 2. Approve with instructions 3. Send back
"@
    $turn = (@{ type = 'assistant'; message = @{ role = 'assistant'; content = @(@{ type = 'text'; text = $packet }) } } | ConvertTo-Json -Depth 8 -Compress)
    [System.IO.File]::WriteAllText($c5.Transcript, $turn, [System.Text.UTF8Encoding]::new($false))
    & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $c5.Proj --host-kind claude --transcript-path $c5.Transcript 2>$null | Out-Null
    $beforeCapture = [string](Read-Handover -Proj $c5.Proj).sections[$capturedTitle]
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content $beforeCapture) '5 precondition: the Stop hook captured the boundary packet into the handover'
    # Now the agent authors ONLY interpretive sections via the command — the captured packet must survive.
    $draft5 = Write-Draft -Tmp $c5.Tmp -Body "## Open questions`nAny edge cases left in the contiguity guard?`n`n## Working hypothesis`nThe gate stays put until the human re-confirms."
    Invoke-Author -Proj $c5.Proj -Draft $draft5 | Out-Null
    $h5 = Read-Handover -Proj $c5.Proj
    $afterCapture = [string]$h5.sections[$capturedTitle]
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content $afterCapture) '5: the hook-captured packet is PRESERVED after the agent authors its body (clobber guard, SC-015)'
    Assert-True ($afterCapture -eq $beforeCapture) '5: the captured packet body is UNCHANGED (not regenerated/placeholdered)'
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content ([string]$h5.sections['Open questions / pending clarifications'])) '5: the newly authored interpretive section also landed (both coexist)'

    # === 6. --stdin — the body piped on stdin is authored (the documented non-file path). ===
    $c6 = New-Project -Boundary 'before-implement'; $cases += $c6.Tmp
    $stdinBody = "## Open questions`nDoes the piped stdin path author correctly?"
    $stdinBody | & pwsh -NoProfile -ExecutionPolicy Bypass -File $cmd author --stdin --project-path $c6.Proj 2>&1 | Out-Null
    Assert-True ($LASTEXITCODE -eq 0) '6: author --stdin exits 0'
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content ([string](Read-Handover -Proj $c6.Proj).sections['Open questions / pending clarifications'])) '6: the stdin-piped body is authored into the handover'

    # === 7. (145-review LOW) apostrophe normalization — possessive / contraction headers still map (curly or straight). ===
    $c7 = New-Project -Boundary 'plan'; $cases += $c7.Tmp
    # Straight-apostrophe possessive AND a curly-apostrophe variant (both must normalize to the canonical).
    # Build the body FIRST (in command-arg position '+' is not concatenation), then pass it.
    $body7 = "## Agent's working hypothesis`nThe matcher should not be apostrophe-fragile.`n`n## Why I" + ([char]0x2019) + "m stopping`nCurly apostrophe from a copy-paste must still map."
    $draft7 = Write-Draft -Tmp $c7.Tmp -Body $body7
    Invoke-Author -Proj $c7.Proj -Draft $draft7 | Out-Null
    $h7 = Read-Handover -Proj $c7.Proj
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content ([string]$h7.sections["Agent's working hypothesis / mental model"])) "7: '## Agent's working hypothesis' (straight apostrophe) maps to the canonical section"
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content ([string]$h7.sections["Why I'm stopping (the switch trigger)"])) "7: a curly-apostrophe 'Why I’m stopping' header still maps (apostrophe-normalized)"

    # === 8. (145-review LOW) collision signal — two headers mapping to one section are WARNED, not silently dropped. ===
    $c8 = New-Project -Boundary 'plan'; $cases += $c8.Tmp
    $draft8 = Write-Draft -Tmp $c8.Tmp -Body "## Open questions`nfirst`n`n## Open questions / pending`nsecond"
    $out8 = (Invoke-Author -Proj $c8.Proj -Draft $draft8) -join "`n"
    Assert-True ($out8 -match 'multiple headers mapped to one section') '8: a same-section header collision is WARNED (not silently last-wins)'

    Write-Host "`n=== HandoverAuthorCommand.Tests.ps1: all assertions passed (agent-callable authoring round-trip + tolerant/apostrophe headers + dispatch + clobber-guard + stdin + collision-signal) ===" -ForegroundColor Green
}
finally {
    foreach ($t in $cases) { Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue }
}
