# THE IDENTITY HANDSHAKE: the hook hands the token to the agent, the agent hands it back, nothing guesses.
#
# THIS SUITE EXISTS BECAUSE AN INDEPENDENT REVIEW BROKE TWO DESIGNS THE SAME WAY. The first took the
# declaring session's identity from `.specrew/runtime/session-marker.json`, which is PROJECT-WIDE and stamped
# by whichever session started last: A declared, the record landed under B, A was refused and B credited.
# The second resolved to the NEWEST token across the project's session directories, and the confirmatory
# pass broke it identically - B started last, A's declaration landed under B, B's Stop CREDITED it. Both were
# inference from shared state; the ruling on the second was that crediting the wrong session is worse than
# refusing, so inference is gone altogether.
#
# What stands: the hook issues a token into its own session directory at turn start and HANDS IT TO THE
# AGENT in one line; `declare-turn-end.ps1 -Token` writes under the session holding it. Given a token no
# live session holds: refused, naming the value. No token and exactly one live: accepted. No token and more
# than one: refused, naming both sessions and the parameter. No tokens: absence, both sides degrade together.
# LIVE MEANS UNCONSUMED - the hook deletes its token at Stop after judging - so a crashed session's leftover
# costs the next token-less declarer one refusal that names the leftover's path.
#
# Case 1 is the reviewer's two-session probe under all four branches. Case 2 is the stale-token shape.
# Case 3 is consumption, driven through the real provider. Case 4 is absence. Case 5 is the turn-start line
# itself, reached THROUGH THE DISPATCHER - the control that would have caught B4F-053 (the provider was
# never registered for the turn-start events, so the token was issued once per session).

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
$provider = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'
$dispatcher = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
$registry = Join-Path $repoRoot 'extensions/specrew-speckit/refocus-scopes.json'

Write-Host 'turn-end-session-identity'
Write-Host '  --- preconditions ---'
Assert-True (Test-Path -LiteralPath $store -PathType Leaf) 'the turn-end store is present'
Assert-True (Test-Path -LiteralPath $declarer -PathType Leaf) 'the declaration script is present'
Assert-True (Test-Path -LiteralPath $provider -PathType Leaf) 'the conformance provider is present'
Assert-True (Test-Path -LiteralPath $dispatcher -PathType Leaf) 'the hook dispatcher is present'
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE'; exit 1 }
. $store

# THE READS THAT CAUSED IT ARE GONE, asserted directly. A behavioural test can pass while an old path
# survives unused, waiting to be called again by the next author who sees a convenient helper.
$declarerText = Get-Content -LiteralPath $declarer -Raw -Encoding UTF8
$storeText = Get-Content -LiteralPath $store -Raw -Encoding UTF8
Assert-True ($declarerText -notmatch 'session-marker\.json') 'the declaration script no longer reads the project-wide session marker'
Assert-True ($storeText -notmatch 'Get-SpecrewSessionIdentityFromMarker') 'the helper that read it is gone from the store'
Assert-True ($storeText -notmatch 'Find-SpecrewCurrentTurnToken' -and $declarerText -notmatch 'Find-SpecrewCurrentTurnToken') 'and the newest-wins resolver is gone too, not merely unused'

function Invoke-Declare {
    # Runs the real script out of process, the way the agent does, and returns exit code, stdout, stderr.
    param([string[]]$Arguments)
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    foreach ($a in @('-NoProfile', '-File', $declarer) + $Arguments) { $psi.ArgumentList.Add($a) }
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    $out = $proc.StandardOutput.ReadToEnd()
    $err = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    return [pscustomobject]@{ Code = $proc.ExitCode; Out = $out; Err = $err }
}

function Invoke-Provider {
    param([string]$ProjectRoot, [string]$Event, [string]$SessionId, [string]$HostKind = 'claude')
    Push-Location $ProjectRoot
    try {
        $args = @('-NoProfile', '-File', $provider, '--host-kind', $HostKind, '--source-event', $Event)
        if (-not [string]::IsNullOrWhiteSpace($SessionId)) { $args += @('--session-id', $SessionId) }
        $out = & pwsh @args 2>&1 | Out-String
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = $out }
    }
    finally { Pop-Location }
}

$roots = New-Object System.Collections.Generic.List[string]
function New-ProjectRoot {
    $r = Join-Path ([IO.Path]::GetTempPath()) ('tesi-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    New-Item -ItemType Directory -Path (Join-Path $r '.specrew/runtime') -Force | Out-Null
    $roots.Add($r) | Out-Null
    return $r
}

try {
    # ============ Case 1: the reviewer's two-session probe, under all four branches ==================
    Write-Host '  --- Case 1: two sessions in one project (the reviewer''s probe), four branches ---'
    $root = New-ProjectRoot
    $a = Get-SpecrewTurnEndPaths -ProjectRoot $root -HostKind 'claude' -SessionId 'A'
    $b = Get-SpecrewTurnEndPaths -ProjectRoot $root -HostKind 'claude' -SessionId 'B'
    $tokenA = Write-SpecrewTurnToken -StateRoot $a.StateRoot -TurnId $a.TurnId
    Start-Sleep -Milliseconds 20
    $tokenB = Write-SpecrewTurnToken -StateRoot $b.StateRoot -TurnId $b.TurnId   # B starts LAST - the shape that beat both old designs
    Assert-True ($tokenA -ne $tokenB -and -not [string]::IsNullOrWhiteSpace($tokenA)) 'each session issued its own distinct turn token'

    # (1a) no -Token, two live: REFUSED, naming both sessions and the parameter. This is the exact call that
    # used to land A's declaration under B.
    $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'A did some work', '-ProjectRoot', $root, '-AsJson')
    Assert-True ($r.Code -ne 0) '1a: with two live tokens and no -Token the declaration is REFUSED (non-zero exit)'
    Assert-True ($null -eq (Read-SpecrewTurnEndRecord -Path $a.RecordPath) -and $null -eq (Read-SpecrewTurnEndRecord -Path $b.RecordPath)) '1a: and no record was written under EITHER session - refused means refused'
    Assert-True ($r.Err -match '-Token') '1a: the refusal names the -Token parameter'
    Assert-True ($r.Err -match [regex]::Escape($a.OwnerHash.Substring(0, 12)) -and $r.Err -match [regex]::Escape($b.OwnerHash.Substring(0, 12))) '1a: and names BOTH sessions'
    Assert-True ($r.Err -match '\[specrew-turn\]') '1a: and says where the token comes from - the turn-start line'

    # (1b) -Token A: written under A, carrying A's token; B untouched. Then the symmetric call for B.
    $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'A did some work', '-ProjectRoot', $root, '-Token', $tokenA, '-AsJson')
    $declared = if ($r.Code -eq 0) { $r.Out | ConvertFrom-Json } else { $null }
    Assert-True ($r.Code -eq 0 -and $null -ne $declared -and [bool]$declared.record_written) '1b: with -Token <A> the declaration is accepted and written'
    Assert-True ($null -ne $declared -and [string]$declared.identity -ceq 'matched') '1b: resolved by the token (identity=matched), not by ranking'
    $recordA = Read-SpecrewTurnEndRecord -Path $a.RecordPath
    Assert-True ($null -ne $recordA -and [string]$recordA.turn_token -ceq $tokenA) '1b: the record is under A and carries A''s token - so A''s Stop credits it'
    Assert-True ($null -eq (Read-SpecrewTurnEndRecord -Path $b.RecordPath)) '1b: B has NO record - the session that started last is not credited for A''s work'
    $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'B did other work', '-ProjectRoot', $root, '-Token', $tokenB, '-AsJson')
    $recordB = Read-SpecrewTurnEndRecord -Path $b.RecordPath
    Assert-True ($r.Code -eq 0 -and $null -ne $recordB -and [string]$recordB.turn_token -ceq $tokenB) '1b: symmetric - B with -Token <B> lands under B carrying B''s token'
    Assert-True ([string](Read-SpecrewTurnEndRecord -Path $a.RecordPath).summary -ceq 'A did some work') '1b: and A''s record is still A''s, untouched by B''s declaration'

    # (1c) -Token with a value no live session holds: REFUSED, naming the value.
    $bogus = 'deadbeefdeadbeefdeadbeefdeadbeef'
    $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'who am I', '-ProjectRoot', $root, '-Token', $bogus, '-AsJson')
    Assert-True ($r.Code -ne 0) '1c: a token no live session holds is REFUSED'
    Assert-True ($r.Err -match [regex]::Escape($bogus)) '1c: and the refusal names the value it was given'
    Assert-True ([string](Read-SpecrewTurnEndRecord -Path $a.RecordPath).summary -ceq 'A did some work' -and [string](Read-SpecrewTurnEndRecord -Path $b.RecordPath).summary -ceq 'B did other work') '1c: neither session''s record was touched'

    # (1d) exactly one live token and no -Token: accepted - the unambiguous case needs no parameter.
    $null = Remove-SpecrewTurnToken -StateRoot $b.StateRoot     # B's Stop consumed its token
    $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'A again, alone now', '-ProjectRoot', $root, '-AsJson')
    $declared = if ($r.Code -eq 0) { $r.Out | ConvertFrom-Json } else { $null }
    Assert-True ($r.Code -eq 0 -and $null -ne $declared -and [string]$declared.identity -ceq 'single') '1d: with exactly one live token, no -Token is accepted (identity=single)'
    Assert-True ([string](Read-SpecrewTurnEndRecord -Path $a.RecordPath).turn_token -ceq $tokenA) '1d: and it is placed under the one live session'

    # ============ Case 2: the stale-token shape =====================================================
    Write-Host '  --- Case 2: one leftover token from a dead session plus one live session ---'
    $root2 = New-ProjectRoot
    $dead = Get-SpecrewTurnEndPaths -ProjectRoot $root2 -HostKind 'claude' -SessionId 'crashed'
    $live = Get-SpecrewTurnEndPaths -ProjectRoot $root2 -HostKind 'claude' -SessionId 'alive'
    $tokenDead = Write-SpecrewTurnToken -StateRoot $dead.StateRoot -TurnId $dead.TurnId     # its Stop never ran
    Start-Sleep -Milliseconds 20
    $tokenLive = Write-SpecrewTurnToken -StateRoot $live.StateRoot -TurnId $live.TurnId
    $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'work by the live one', '-ProjectRoot', $root2, '-AsJson')
    Assert-True ($r.Code -ne 0) '2: without -Token the leftover makes the shape ambiguous and it is REFUSED'
    Assert-True ($r.Err -match [regex]::Escape((Get-SpecrewTurnTokenPath -StateRoot $dead.StateRoot))) '2: the refusal names the leftover''s PATH, so a human who knows that session is gone can remove it'
    Assert-True ($r.Err -match 'issued \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC') '2: and each token''s issue time, so a leftover can be told from a live turn'
    $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'work by the live one', '-ProjectRoot', $root2, '-Token', $tokenLive, '-AsJson')
    Assert-True ($r.Code -eq 0 -and [string](Read-SpecrewTurnEndRecord -Path $live.RecordPath).turn_token -ceq $tokenLive) '2: with -Token <live> it is accepted under the live session'
    Assert-True ($null -eq (Read-SpecrewTurnEndRecord -Path $dead.RecordPath)) '2: and nothing was written under the dead one'
    # The live session's Stop consumes its token; the leftover is STILL there, and it still costs a
    # token-less declarer a refusal. Nothing ages it out - that would be inference again.
    $null = Remove-SpecrewTurnToken -StateRoot $live.StateRoot
    $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'a later token-less turn', '-ProjectRoot', $root2, '-AsJson')
    $declared = if ($r.Code -eq 0) { $r.Out | ConvertFrom-Json } else { $null }
    Assert-True ($r.Code -eq 0 -and $null -ne $declared -and [string]$declared.identity -ceq 'single' -and $null -ne (Read-SpecrewTurnEndRecord -Path $dead.RecordPath)) '2: after the live token is consumed the leftover is the ONLY live token - and a token-less declaration lands under the DEAD session (the cost of a leftover, exactly as ruled: it is not aged out)'

    # ============ Case 3: consumption, through the real provider ====================================
    Write-Host '  --- Case 3: the hook consumes the token at a Stop that ended the turn, and keeps it across a block ---'
    $root3 = New-ProjectRoot
    # A minimal governed root: .specrew present, no pending verdict, no material change - a Stop that judges
    # and does not block.
    $s3 = Get-SpecrewTurnEndPaths -ProjectRoot $root3 -HostKind 'claude' -SessionId 'S3'
    $start = Invoke-Provider -ProjectRoot $root3 -Event 'UserPromptSubmit' -SessionId 'S3'
    Assert-True ($start.Code -eq 0) '3: the turn-start lane runs'
    $issued = Read-SpecrewTurnToken -StateRoot $s3.StateRoot
    Assert-True (-not [string]::IsNullOrWhiteSpace($issued)) '3: and issued a token'
    Assert-True ($start.Out -match ('\[specrew-turn\].*declare-turn-end\.ps1.*-Token ' + [regex]::Escape($issued))) '3: the turn-start output HANDS THE TOKEN TO THE AGENT in a [specrew-turn] line naming the script'
    $lineCount = @($start.Out.Trim() -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
    Assert-True ($lineCount -eq 1 -and $start.Out.Trim().Length -lt 240) ('3: and it is ONE line under 240 characters (measured {0} line(s), {1} chars)' -f $lineCount, $start.Out.Trim().Length)
    $again = Invoke-Provider -ProjectRoot $root3 -Event 'SessionStart' -SessionId 'S3'
    Assert-True ((Read-SpecrewTurnToken -StateRoot $s3.StateRoot) -ceq $issued) '3: a second turn-start event for the SAME open turn (compaction mid-turn) REUSES the unconsumed token rather than orphaning the line already handed out'
    $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'a quiet turn', '-ProjectRoot', $root3, '-Token', $issued, '-AsJson')
    Assert-True ($r.Code -eq 0) '3: the agent declares with the token it was handed'
    $stop = Invoke-Provider -ProjectRoot $root3 -Event 'Stop' -SessionId 'S3'
    Assert-True ($stop.Code -eq 0 -and $stop.Out -notmatch 'SPECREW-STOP-BLOCK') '3: the Stop judges the declaration and does not block'
    Assert-True ([string]::IsNullOrWhiteSpace((Read-SpecrewTurnToken -StateRoot $s3.StateRoot))) '3: and CONSUMED the token - live means unconsumed'
    Assert-True (@(Get-SpecrewLiveTurnTokens -ProjectRoot $root3).Count -eq 0) '3: so the project now has no live token'
    $next = Invoke-Provider -ProjectRoot $root3 -Event 'UserPromptSubmit' -SessionId 'S3'
    $fresh = Read-SpecrewTurnToken -StateRoot $s3.StateRoot
    Assert-True (-not [string]::IsNullOrWhiteSpace($fresh) -and $fresh -cne $issued) '3: the next turn start issues a FRESH token'
    $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'using last turn''s token', '-ProjectRoot', $root3, '-Token', $issued, '-AsJson')
    Assert-True ($r.Code -ne 0 -and $r.Err -match [regex]::Escape($issued)) '3: and last turn''s token is now refused by name - it was consumed'

    # ============ Case 3b: a Stop that BLOCKS keeps the token ========================================
    Write-Host '  --- Case 3b: a blocking Stop keeps the token - the turn has not ended ---'
    # A pending boundary and NO declaration: a shape that blocks. This fixture binds no crossing, so the
    # block is the stage-evidence gate's rather than the boundary demand - and for the token it makes no
    # difference: a block force-continues the SAME turn, so the token must survive it. The release path -
    # declare with the same token, the second Stop credits it and consumes - needs the bound-crossing
    # fixture and is Case 2e of conformance-detection.tests.ps1.
    $root3b = New-ProjectRoot
    $ctx = [ordered]@{
        schema               = 'v2'
        feature_path         = (Join-Path $root3b 'specs\050-host-neutral-gate')
        session_state        = [ordered]@{ active = $true; boundary_type = 'plan'; feature_ref = '050-host-neutral-gate'; iteration_number = '001'; recorded_at = '2026-06-20T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'clarify'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $root3b '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    $null = & git -C $root3b init --quiet
    $null = & git -C $root3b config core.autocrlf false
    [System.IO.File]::WriteAllText((Join-Path $root3b '.fixture-base'), "fixture`n", [System.Text.UTF8Encoding]::new($false))
    $null = & git -C $root3b add .fixture-base
    $null = & git -C $root3b -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m 'fixture baseline'
    $iter = Join-Path $root3b 'specs\050-host-neutral-gate\iterations\001'
    New-Item -ItemType Directory -Path (Join-Path $iter 'quality') -Force | Out-Null
    foreach ($pair in @(@{ Rel = 'plan.md'; Body = '# Iteration Plan' }, @{ Rel = 'state.md'; Body = '# Iteration State' }, @{ Rel = 'review.md'; Body = '# Iteration Review' }, @{ Rel = 'retro.md'; Body = '# Iteration Retro' }, @{ Rel = 'quality\hardening-gate.md'; Body = '# Hardening Gate' })) {
        [System.IO.File]::WriteAllText((Join-Path $iter $pair.Rel), $pair.Body, [System.Text.UTF8Encoding]::new($false))
    }
    $stopLines = @('# Specrew Pending Verdict Stop', '', 'Boundary to ask for: clarify -> plan', 'Human approval phrase: approved for plan', 'Marker last line exactly:', '<!-- SPECREW-VERDICT-BOUNDARY: clarify -> plan -->', '', 'Working boundary: plan', 'Last authorized boundary: clarify', 'Feature: 050-host-neutral-gate')
    [System.IO.File]::WriteAllText((Join-Path $root3b '.specrew\runtime\pending-verdict-stop.md'), (($stopLines -join [Environment]::NewLine) + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
    $transcript = Join-Path $root3b '.specrew\runtime\transcript.jsonl'
    $turns = @(@{ role = 'user'; text = 'continue' }, @{ role = 'assistant'; text = 'Done with the plan work.' }) | ForEach-Object { ([pscustomobject]@{ type = $_.role; message = [pscustomobject]@{ content = @([pscustomobject]@{ type = 'text'; text = $_.text }) } } | ConvertTo-Json -Depth 8 -Compress) }
    [System.IO.File]::WriteAllLines($transcript, [string[]]$turns, [System.Text.UTF8Encoding]::new($false))

    $s3b = Get-SpecrewTurnEndPaths -ProjectRoot $root3b -HostKind 'claude' -SessionId 'S3b'
    $null = Invoke-Provider -ProjectRoot $root3b -Event 'UserPromptSubmit' -SessionId 'S3b'
    $tok3b = Read-SpecrewTurnToken -StateRoot $s3b.StateRoot
    Assert-True (-not [string]::IsNullOrWhiteSpace($tok3b)) '3b: the turn started and a token was issued'
    Push-Location $root3b
    try { $blocked = (& pwsh -NoProfile -File $provider --host-kind claude --source-event Stop --session-id S3b --transcript-path $transcript 2>&1 | Out-String) }
    finally { Pop-Location }
    Assert-True ($blocked -match '<<<SPECREW-STOP-BLOCK>>>') '3b: the Stop BLOCKS'
    Assert-True ((Read-SpecrewTurnToken -StateRoot $s3b.StateRoot) -ceq $tok3b) '3b: and the block KEPT the token - the turn has not ended'


    # ============ Case 4: absence is not mismatch ===================================================
    Write-Host '  --- Case 4: a host that issues no token still declares (absence is not mismatch) ---'
    $quiet = New-ProjectRoot
    $holder = Resolve-SpecrewTurnTokenHolder -ProjectRoot $quiet -Token ''
    Assert-True ([string]$holder.outcome -ceq 'absent') 'no turn-start event means no token, resolved as absence'
    $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'a host with no prompt event', '-ProjectRoot', $quiet, '-AsJson')
    $declared = if ($r.Code -eq 0) { $r.Out | ConvertFrom-Json } else { $null }
    Assert-True ($r.Code -eq 0 -and $null -ne $declared -and [bool]$declared.record_written -and [string]$declared.identity -ceq 'absent') 'and the session can still declare - it is not locked out'
    $quietPaths = Get-SpecrewTurnEndPaths -ProjectRoot $quiet -HostKind '' -SessionId ''
    $quietRecord = Read-SpecrewTurnEndRecord -Path $quietPaths.RecordPath
    Assert-True ($null -ne $quietRecord -and [string]::IsNullOrWhiteSpace([string]$quietRecord.turn_token)) 'the record carries no token, matching the hook that issued none'

    # ============ Case 5: the line is reachable THROUGH THE DISPATCHER (B4F-053's control) ============
    Write-Host '  --- Case 5: the turn-start line reaches the agent through the dispatcher, not only when the provider is called directly ---'
    $catalog = Get-Content -LiteralPath $registry -Raw -Encoding UTF8 | ConvertFrom-Json
    $row = @($catalog.providers | Where-Object { [string]$_.id -eq 'conformance' })[0]
    Assert-True (@($row.events) -ccontains 'UserPromptSubmit' -and @($row.events) -ccontains 'PreInvocation') '5: the conformance registry row subscribes to BOTH turn-start events (B4F-053: it subscribed to neither)'
    $root5 = New-ProjectRoot
    # The dispatcher resolves the catalog and the providers from the PROJECT's deployed extension tree (an
    # out-of-tree provider is refused by design), so the scratch project gets a deployed copy of the repo's
    # scripts and registry, and the DEPLOYED dispatcher is the one run - the same path a host takes.
    $deployed = Join-Path $root5 '.specify/extensions/specrew-speckit'
    New-Item -ItemType Directory -Path $deployed -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/scripts') -Destination (Join-Path $deployed 'scripts') -Recurse -Force
    Copy-Item -LiteralPath $registry -Destination (Join-Path $deployed 'refocus-scopes.json') -Force
    $deployedDispatcher = Join-Path $deployed 'scripts/specrew-hook-dispatcher.ps1'
    $evtJson = (@{ session_id = 'S5'; prompt = 'hello' } | ConvertTo-Json -Compress)
    Push-Location $root5
    try {
        $dispatched = (& pwsh -NoProfile -File $deployedDispatcher -Event 'UserPromptSubmit' -HostKind 'claude' -EventJson $evtJson 2>&1 | Out-String)
    }
    finally { Pop-Location }
    $s5 = Get-SpecrewTurnEndPaths -ProjectRoot $root5 -HostKind 'claude' -SessionId 'S5'
    $tok5 = Read-SpecrewTurnToken -StateRoot $s5.StateRoot
    Assert-True (-not [string]::IsNullOrWhiteSpace($tok5)) '5: a dispatched UserPromptSubmit issued a token under the session the host named'
    Assert-True ($dispatched -match ('\[specrew-turn\].*' + [regex]::Escape($tok5))) '5: and the dispatcher''s output carries the [specrew-turn] line with that token - wrapped in the host envelope'
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
