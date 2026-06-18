# F-174 iteration 9: the Stop hook is the PRIMARY author of the rolling handover - it captures the git/fs
# session delta into the MECHANICAL body sections every material stop (never hollow, no agent cooperation),
# accumulates the activity arc across the boundary window, stamps the real host, and preserves an agent
# interpretive overlay. These tests pin the iter-9 contract the iter-8 cross-host dogfood demanded.
$ErrorActionPreference = 'Stop'

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/HandoverStore.ps1"
. "$base/ClassificationEngine.ps1"
. "$base/ProjectMetadataAccessor.ps1"
$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-handover-provider.ps1").Path

function Assert-Equal {
    param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Assert-Match {
    param([string]$Text, [string]$Pattern, [string]$Message)
    if ($Text -notmatch $Pattern) { throw "FAIL: $Message (pattern '$Pattern' not found in: $Text)" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Invoke-StopHook {
    param([string]$ProjectRoot, [string]$HostKind = 'codex')
    & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $ProjectRoot --host-kind $HostKind 2>$null | Out-Null
}
function Get-ActivityBulletCount {
    param([string]$Content)
    return @($Content -split "`n" | Where-Object { $_ -match '^\s*-\s' }).Count
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-iter9-" + [guid]::NewGuid().ToString('N'))
$activityTitle = 'What I just did (last 3-5 turns or last boundary work)'
$contextTitle = "Context the receiving host needs that artifacts don't carry"
$recTitle = 'Recommended next-immediate-step'
try {
    $proj = Join-Path $tmp 'proj'
    New-Item -ItemType Directory -Path (Join-Path $proj 'specs/001-notekeep') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $proj '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t'; git -C $proj config user.name 't'
    git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null
    git -C $proj checkout -q -b '001-notekeep' 2>$null
    (@{ session_state = @{ feature_ref = '001-notekeep'; boundary_type = 'before-implement'; host = 'claude' } } | ConvertTo-Json -Depth 5) |
        Set-Content -LiteralPath (Join-Path $proj '.specrew/start-context.json') -Encoding UTF8
    # THE NEAR-MISS the dogfood exposed: an implementation file written but NOT committed.
    Set-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('hi')`n" -Encoding UTF8

    # --- Get-SpecrewSessionDelta sees the uncommitted file (host-universal, no agent/transcript) ---
    $delta = Get-SpecrewSessionDelta -ProjectRoot $proj
    Assert-True $delta.has_uncommitted 'delta: detects the uncommitted implementation file'
    Assert-Equal $delta.uncommitted_count 1 'delta: one uncommitted file'
    Assert-True ($delta.uncommitted_files -contains 'notekeep.py') 'delta: names notekeep.py'
    Assert-Equal $delta.branch '001-notekeep' 'delta: resolves the feature branch'

    # --- The Stop hook AUTHORS the mechanical body from the delta: never hollow, real from_host ---
    Invoke-StopHook -ProjectRoot $proj -HostKind codex
    $hd = Join-Path $proj '.specrew/handover'
    $h = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-11T00:00:00Z'
    Assert-True ($null -ne $h) 'hook wrote the rolling handover on a material Stop'
    Assert-Equal $h.from_host 'codex' 'from_host is the REAL host from --host-kind, not the literal "host"'
    Assert-True (-not (Test-SpecrewHandoverBodyPlaceholder -Sections $h.sections).placeholder) 'body is NOT hollow - the hook authored mechanical sections from the delta with zero agent cooperation'
    Assert-Match ([string]$h.sections[$contextTitle]) 'notekeep\.py' 'Context surfaces the UNCOMMITTED notekeep.py (the exact near-miss the dogfood exposed)'
    Assert-Match ([string]$h.sections[$recTitle]) 'uncommitted' 'Recommended next-immediate-step warns about the uncommitted work'
    Assert-Match ([string]$h.sections[$activityTitle]) '^\s*-\s' 'What I just did is a bulleted activity line'

    # --- Activity ACCUMULATES across same-boundary stops (newest-first, bounded) ---
    Add-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('more')`n" -Encoding UTF8
    Invoke-StopHook -ProjectRoot $proj -HostKind codex
    $h2 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-11T00:01:00Z'
    Assert-True ((Get-ActivityBulletCount -Content ([string]$h2.sections[$activityTitle])) -ge 2) 'What I just did ACCUMULATES across same-boundary stops (the between-gate arc survives)'

    # --- A boundary change RESETS the activity arc ---
    (@{ session_state = @{ feature_ref = '001-notekeep'; boundary_type = 'review-signoff'; host = 'claude' } } | ConvertTo-Json -Depth 5) |
        Set-Content -LiteralPath (Join-Path $proj '.specrew/start-context.json') -Encoding UTF8
    Invoke-StopHook -ProjectRoot $proj -HostKind codex
    $h3 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-11T00:02:00Z'
    Assert-Equal $h3.active_boundary 'review-signoff' 'boundary advanced'
    Assert-Equal (Get-ActivityBulletCount -Content ([string]$h3.sections[$activityTitle])) 1 'a boundary change RESETS the activity arc to a single fresh bullet'

    # --- An agent interpretive overlay is PRESERVED across a hook stop; mechanical still refreshes ---
    $interp0 = (Get-SpecrewHandoverAgentOwnedSections)[0]
    Write-SpecrewHandoverContext -HandoverDir $hd -FromHost codex -RecordedAt '2026-06-11T00:03:00Z' `
        -ActiveFeature '001-notekeep' -ActiveBoundary 'review-signoff' -Sections @{ $interp0 = 'AGENT: the store schema migration is the open risk.' } | Out-Null
    Add-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('again')`n" -Encoding UTF8
    Invoke-StopHook -ProjectRoot $proj -HostKind codex
    $h4 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-11T00:04:00Z'
    Assert-Match ([string]$h4.sections[$interp0]) 'store schema migration' 'agent interpretive overlay PRESERVED across the next hook stop (section ownership)'
    Assert-Match ([string]$h4.sections[$recTitle]) 'uncommitted' 'mechanical sections still refresh alongside the preserved interpretive overlay'

    # --- No hollow-handover journal entry while the hook captures a real delta (recalibrated) ---
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $proj '.specrew/runtime/handover-journal.jsonl'))) 'NO hollow-handover-at-stop journaled while the hook captures a delta (recalibrated from the iter-5 every-build-stop hollow)'

    # --- Section classification stays consistent with the fixed order (iter-11 T002: now a THREE-way partition) ---
    $mech = Get-SpecrewHandoverMechanicalSections
    $agent = Get-SpecrewHandoverAgentOwnedSections
    $captured = Get-SpecrewHandoverCapturedSections
    Assert-Equal (@($mech).Count) 5 'five mechanical (hook-owned) sections (F-174 iter-10 T002 added "Recent conversation")'
    Assert-Equal (@($agent).Count) 2 'two interpretive (agent-owned) sections'
    Assert-Equal (@($captured).Count) 1 'one captured-packet section (iter-11 T002: the THIRD ownership category, hook-captured verbatim)'
    Assert-True (@(@($mech) + @($agent) + @($captured) | Sort-Object -Unique).Count -eq @(Get-SpecrewHandoverSectionOrder).Count) 'mechanical + interpretive + captured partition the full section order with no overlap or gap'
    Assert-True ((@($mech) | Where-Object { $captured -contains $_ }).Count -eq 0) 'the captured-packet section is NOT in the mechanical (refreshed-every-stop) bucket'
    Assert-True ((@($agent) | Where-Object { $captured -contains $_ }).Count -eq 0) 'the captured-packet section is NOT in the agent-owned bucket (provenance invariant: non-placeholder interpretive == agent)'

    # --- iter-9.1 multi-source: ONE core save (Update-SpecrewRollingHandover) reached by every trigger ---
    # (a) the core called directly with a 'workshop' source (the skill path).
    Add-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('ws')`n" -Encoding UTF8
    $r = Update-SpecrewRollingHandover -ProjectRoot $proj -HostKind claude -Source 'workshop' -NowUtc '2026-06-11T02:00:00Z'
    Assert-True $r.wrote 'core Update-SpecrewRollingHandover writes on a material change'
    $hw = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-11T02:00:01Z'
    Assert-Equal $hw.source 'workshop' "the core stamps the trigger source ('workshop') in the frontmatter"
    Assert-Match ([string]$hw.sections["Why I'm stopping (the switch trigger)"]) "trigger 'workshop'" 'the body names the workshop trigger source'

    # (b) the provider invoked with --source workshop (the skill's actual one-liner) -> same core, source stamped.
    Add-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('ws2')`n" -Encoding UTF8
    & pwsh -NoProfile -File $provider --project-root $proj --host-kind claude --source workshop 2>$null | Out-Null
    Assert-Equal (Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-12T00:00:00Z').source 'workshop' 'provider --source workshop routes through the core'

    # (c) the provider on a PostToolUse event -> refreshes MID-TURN (the workshop-freeze fix), source 'PostToolUse'.
    Add-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('ptu')`n" -Encoding UTF8
    & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"PostToolUse"}' --project-root $proj --host-kind claude 2>$null | Out-Null
    Assert-Equal (Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-12T00:00:00Z').source 'PostToolUse' 'provider on a PostToolUse event refreshes mid-turn (no Stop needed)'

    # (d) a CLEAN tree + unchanged boundary is gated out - the per-tool-call cheapness guarantee.
    git -C $proj add -A 2>$null; git -C $proj commit -q -m wip 2>$null   # commit -> clean working tree
    $rq = Update-SpecrewRollingHandover -ProjectRoot $proj -HostKind claude -Source 'PostToolUse' -NowUtc '2026-06-12T00:01:00Z'
    Assert-True (-not $rq.wrote) 'a clean tree + unchanged boundary is gated out (the per-tool-call cheapness guarantee)'

    # (e) [retargeted f184] Claude's refocus binding is manifest-driven and follows the APPROVED TG-004a
    #     model (iteration-001 review-signoff): BoundTriggers b1/b2 delivered via SessionStart, and B3 rides
    #     channel 1 (the boundary-sync wrapper stdout) rather than a per-tool-call hook - the PostToolUse
    #     spawn measured ~920ms/call vs the 150ms bar. So PostToolUse is UNREGISTERED as a refocus event and
    #     the OLD hardcoded per-host `'PostToolUse' = [pscustomobject]` registration in deploy-refocus-hooks
    #     is gone. These assertions positively pin that model AND stay a real regression guard: they FAIL if
    #     PostToolUse is re-registered (added to Events / re-bound as b3) or re-hardcoded in deploy.
    $claudeBindings = (Import-PowerShellDataFile (Resolve-Path "$PSScriptRoot/../../hosts/claude/host.psd1").Path).RefocusHookBindings
    Assert-True (($claudeBindings.BoundTriggers -contains 'b1') -and ($claudeBindings.BoundTriggers -contains 'b2')) 'Claude binds b1+b2 via the refocus hook (the approved model)'
    Assert-True (-not ($claudeBindings.BoundTriggers -contains 'b3')) 'b3 is NOT bound to a Claude hook - it rides channel 1 (TG-004a); guards against re-binding b3'
    Assert-True ($claudeBindings.Events -contains 'SessionStart') 'Claude registers the SessionStart refocus event (b1/b2 delivery)'
    Assert-True (-not ($claudeBindings.Events -contains 'PostToolUse')) 'Claude PostToolUse is UNREGISTERED as a refocus event (TG-004a); guards against re-registering it'
    $deploy = (Resolve-Path "$PSScriptRoot/../../scripts/internal/deploy-refocus-hooks.ps1").Path
    Assert-True ((Get-Content -LiteralPath $deploy -Raw) -notmatch "'PostToolUse'\s*=\s*\[pscustomobject\]") 'deploy-refocus-hooks does NOT re-hardcode a per-host PostToolUse registration (manifest-driven); guards against re-hardcoding'

    # (f) iter-9 T007 delta-noise: Specrew-managed scaffolding is partitioned out + deprioritized so the
    #     user's REAL files lead the handover (the live dogfood found the handover drowned in ~53 managed paths).
    git -C $proj add -A 2>$null; git -C $proj commit -q -m 'pre-noise' 2>$null   # clean tree first
    New-Item -ItemType Directory -Path (Join-Path $proj '.claude/skills/x') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $proj '.claude/skills/x/SKILL.md') -Value "managed`n" -Encoding UTF8
    New-Item -ItemType Directory -Path (Join-Path $proj 'src') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $proj 'src/app.ps1') -Value "Write-Host hi`n" -Encoding UTF8
    $dn = Get-SpecrewSessionDelta -ProjectRoot $proj
    Assert-True (@($dn.user_files) -contains 'src/app.ps1') 'T007: the user file src/app.ps1 surfaces in user_files'
    Assert-True (-not (@($dn.user_files) -contains '.claude/skills/x/SKILL.md')) 'T007: the .claude/ managed file is NOT in user_files'
    Assert-True (([int]$dn.managed_file_count) -ge 1) 'T007: managed scaffolding is counted (managed_file_count >= 1)'
    Assert-Equal (@($dn.uncommitted_files)[0]) 'src/app.ps1' 'T007: the prioritized list LEADS with the user file, not the managed scaffolding'
    Update-SpecrewRollingHandover -ProjectRoot $proj -HostKind claude -Source refresh -NowUtc '2026-06-12T01:00:00Z' | Out-Null
    $hh = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-12T01:00:01Z'
    Assert-Match ([string]$hh.sections[$activityTitle]) 'changed user file\(s\)' 'T007: the activity bullet reports CHANGED USER FILE(S), leading with the real work'
    Assert-Match ([string]$hh.sections[$activityTitle]) 'src/app\.ps1' 'T007: the activity bullet lists the user file'
    Assert-Match ([string]$hh.sections[$activityTitle]) 'Specrew-managed' 'T007: the activity bullet notes the managed scaffolding by COUNT, not by listing it'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'HandoverHookPrimary: all tests passed.' -ForegroundColor Green
