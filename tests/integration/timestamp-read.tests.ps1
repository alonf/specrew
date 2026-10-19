# ONE TIMESTAMP READER, and the three sites that were each wrong in their own way about a value JSON coerced.
#
# ConvertFrom-Json turns an ISO-8601 string into a [datetime] on the way back. In one batch, three sites did
# something reasonable-looking with the result and each was wrong differently: a type check that a correct
# round-trip could not survive (design-decision `recorded_at`), a re-parse through a string that lost the
# sub-second part (token ordering), and a string cast that dropped the UTC designator so the re-parse read
# LOCAL time (render cooldown - a render 0.5 s old looked ~3 hours old on this machine's zone and the
# cooldown was bypassed). Three instances is a pattern; the fix is one reader every timestamp field goes
# through. This suite proves the reader, then proves each site reads through it.
#
# -MutateCooldown reverts the cooldown site to the string-cast re-parse. Under it the cooldown case goes RED
# on any machine whose zone is not UTC, and the helper's own cases stay green - which is the point: the
# helper is right and the site was wrong.

param([switch] $MutateCooldown)

$ErrorActionPreference = 'Stop'
$script:Failures = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host ("  PASS: {0}" -f $Message) }
    else { Write-Host ("  FAIL: {0}" -f $Message); $script:Failures++ }
}

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$helper = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/timestamp-read.ps1'
$store = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/turn-end-store.ps1'
$decisionStore = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/design-decision-store.ps1'
$provider = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'

Write-Host 'timestamp-read'
Write-Host '  --- preconditions ---'
Assert-True (Test-Path -LiteralPath $helper -PathType Leaf) 'the helper is present beside the store'
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE'; exit 1 }
. $helper
. $store
. $decisionStore

if ($MutateCooldown) {
    # THE MUTATION: the cooldown as it stood before the helper - cast the coerced [datetime] to a string,
    # parse it back. On a non-UTC machine the parse reads local time and the elapsed seconds are off by the
    # zone offset. Redefining the function after the store is loaded is how the old body is put back.
    function Get-SpecrewTurnEndRenderDecision {
        param([string] $Kind, $PreviousRecord, [string] $ContentHash, [int] $MinimumSecondsBetweenRenders = 45, [AllowNull()][datetime] $NowUtc)
        $now = if ($null -eq $NowUtc) { [datetime]::UtcNow } else { $NowUtc.ToUniversalTime() }
        if ($Kind -eq 'conversational') { return [pscustomobject]@{ render = $false; reason = 'conversational-turn-renders-nothing' } }
        if ($null -eq $PreviousRecord) { return [pscustomobject]@{ render = $true; reason = 'first-render-of-this-kind' } }
        if ([string]$PreviousRecord.kind -ceq $Kind) {
            try {
                $previousAt = [datetime]::Parse([string]$PreviousRecord.rendered_at).ToUniversalTime()
                $elapsed = ($now - $previousAt).TotalSeconds
                if ($elapsed -ge 0 -and $elapsed -lt $MinimumSecondsBetweenRenders -and $Kind -eq 'in-flight') {
                    return [pscustomobject]@{ render = $false; reason = 'in-flight-line-already-shown-moments-ago' }
                }
            }
            catch { $null = $_ }
        }
        return [pscustomobject]@{ render = $true; reason = 'render-earned' }
    }
    Write-Host '  (MUTATION ACTIVE: the cooldown re-parses the coerced timestamp through a string)'
}

$zoneOffsetMinutes = [int][TimeZoneInfo]::Local.GetUtcOffset([datetime]::UtcNow).TotalMinutes
Write-Host ("  --- this machine's zone offset: {0} minutes (a zero offset cannot distinguish the local-time mistake) ---" -f $zoneOffsetMinutes)

# ============ Case 1: the four shapes of one instant read as the same instant ========================
Write-Host '  --- Case 1: one instant, four shapes JSON can hand back ---'
$instant = [DateTimeOffset]::new(2026, 9, 10, 8, 49, 29, 735, [TimeSpan]::Zero)
$isoString = $instant.ToString('o')
$coerced = ($isoString | ConvertTo-Json | ConvertFrom-Json)               # what ConvertFrom-Json hands back
$unixMs = $instant.ToUnixTimeMilliseconds()
$asOffset = $instant
Assert-True ($coerced -is [datetime]) ('the fixture is real: ConvertFrom-Json coerced the ISO string into a [datetime] (Kind {0})' -f $coerced.Kind)
$fromString = ConvertTo-SpecrewUtcTimestamp -Value $isoString
$fromCoerced = ConvertTo-SpecrewUtcTimestamp -Value $coerced
$fromMs = ConvertTo-SpecrewUtcTimestamp -Value $unixMs
$fromOffset = ConvertTo-SpecrewUtcTimestamp -Value $asOffset
foreach ($pair in @(@{ n = 'ISO string'; v = $fromString }, @{ n = 'coerced [datetime]'; v = $fromCoerced }, @{ n = 'unix milliseconds'; v = $fromMs }, @{ n = '[DateTimeOffset]'; v = $fromOffset })) {
    Assert-True ($null -ne $pair.v -and ([DateTimeOffset]$pair.v) -eq $instant -and ([DateTimeOffset]$pair.v).Offset -eq [TimeSpan]::Zero) ('{0} reads as the same UTC instant, to the millisecond' -f $pair.n)
}
Assert-True ($null -eq (ConvertTo-SpecrewUtcTimestamp -Value 'not a time') -and $null -eq (ConvertTo-SpecrewUtcTimestamp -Value $null) -and $null -eq (ConvertTo-SpecrewUtcTimestamp -Value '')) 'unreadable, null and empty read as $null rather than throwing or defaulting to now'
$bare = ConvertTo-SpecrewUtcTimestamp -Value '2026-09-10T08:49:29'
Assert-True ($null -ne $bare -and ([DateTimeOffset]$bare).Hour -eq 8) 'a bare stamp with no designator is read as UTC, never as this machine''s local time'
$culture = [System.Threading.Thread]::CurrentThread.CurrentCulture
try {
    [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('he-IL')
    Assert-True ((ConvertTo-SpecrewUtcTimestamp -Value $isoString) -eq $instant) 'the read is invariant-culture: the same under he-IL'
}
finally { [System.Threading.Thread]::CurrentThread.CurrentCulture = $culture }

# ============ Case 2: the render cooldown reads through it (site 3) ==================================
Write-Host '  --- Case 2: the in-flight render cooldown on a record whose rendered_at survived JSON as a [datetime] ---'
# A record written 0.5 s ago, round-tripped through JSON the way the store reads it back, WITHOUT the
# rendered_ms field - the older-record shape whose only timestamp is the coerced one.
$halfSecondAgo = [DateTimeOffset]::UtcNow.AddMilliseconds(-500)
$previous = ([ordered]@{ schema_version = '1.0'; kind = 'in-flight'; rendered = $true; content_hash = 'abc'; rendered_at = $halfSecondAgo.ToString('o') } | ConvertTo-Json -Compress | ConvertFrom-Json)
Assert-True ($previous.rendered_at -is [datetime]) 'the fixture is real: the record''s rendered_at came back as a [datetime]'
$decision = Get-SpecrewTurnEndRenderDecision -Kind 'in-flight' -PreviousRecord $previous -ContentHash 'different'
Assert-True (-not [bool]$decision.render -and [string]$decision.reason -ceq 'in-flight-line-already-shown-moments-ago') ('a render 0.5 s old is inside the 45 s cooldown - suppressed (got: {0})' -f $decision.reason)
$withMs = ([ordered]@{ schema_version = '1.0'; kind = 'in-flight'; rendered = $true; content_hash = 'abc'; rendered_at = $halfSecondAgo.ToString('o'); rendered_ms = $halfSecondAgo.ToUnixTimeMilliseconds() } | ConvertTo-Json -Compress | ConvertFrom-Json)
$decisionMs = Get-SpecrewTurnEndRenderDecision -Kind 'in-flight' -PreviousRecord $withMs -ContentHash 'different'
Assert-True (-not [bool]$decisionMs.render) 'and the same with rendered_ms present - the number is read first'
$longAgo = ([ordered]@{ schema_version = '1.0'; kind = 'in-flight'; rendered = $true; content_hash = 'abc'; rendered_at = [DateTimeOffset]::UtcNow.AddSeconds(-120).ToString('o') } | ConvertTo-Json -Compress | ConvertFrom-Json)
Assert-True ([bool](Get-SpecrewTurnEndRenderDecision -Kind 'in-flight' -PreviousRecord $longAgo -ContentHash 'different').render) 'a render two minutes old is outside the cooldown - rendered (the gate is not simply closed)'

# ============ Case 3: the design-decision read-back reads through it (site 1) =========================
Write-Host '  --- Case 3: the design-decision validator on a record whose recorded_at survived JSON as a [datetime] ---'
$decisionRecord = [ordered]@{
    schema_version = $script:SpecrewDesignDecisionSchemaVersion; feature_ref = '001-x'; key = 'k'
    question = 'q'; options = @(@{ id = '1'; summary = 'a' }, @{ id = '2'; summary = 'b' }); chosen = '1'; rationale = 'r'
    confirmation = $script:SpecrewDesignDecisionConfirmation; confirmation_scope = $script:SpecrewDesignDecisionScope
    human_turn = 'design decision: option 1 - because'; recorded_at = [DateTimeOffset]::UtcNow.ToString('o')
}
$roundTripped = ($decisionRecord | ConvertTo-Json -Depth 6 -Compress | ConvertFrom-Json)
Assert-True ($roundTripped.recorded_at -is [datetime]) 'the fixture is real: recorded_at came back as a [datetime]'
$validated = Test-SpecrewDesignDecisionRecord -Record $roundTripped
Assert-True ([bool]$validated.valid) ('a record whose timestamp survived JSON as a [datetime] validates (reason: {0})' -f $validated.reason)
$roundTripped.recorded_at = 'yesterday-ish'
$rejected = Test-SpecrewDesignDecisionRecord -Record $roundTripped
Assert-True (-not [bool]$rejected.valid -and [string]$rejected.reason -ceq 'design-decision-recorded-at-unreadable') 'and an unreadable timestamp is rejected by name - the check reads the value, not its type'

# ============ Case 4: the token listing reads through it (site 2) ====================================
Write-Host '  --- Case 4: the live-token listing on a token whose issued_at survived JSON as a [datetime] ---'
$root = Join-Path ([IO.Path]::GetTempPath()) ('tsr-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
try {
    $stateRoot = Join-Path $root '.specrew/runtime/conformance-sessions/abc'
    New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
    # An OLDER token record: issued_at only, no issued_ms - the shape from before the number existed.
    [System.IO.File]::WriteAllText((Join-Path $stateRoot 'turn-token.json'), ([ordered]@{ schema_version = '1.0'; token = 'aa'; turn_id = 'turn-1'; issued_at = $instant.ToString('o') } | ConvertTo-Json -Compress), [System.Text.UTF8Encoding]::new($false))
    $live = @(Get-SpecrewLiveTurnTokens -ProjectRoot $root)
    Assert-True ($live.Count -eq 1 -and $null -ne $live[0].issued -and ([DateTimeOffset]$live[0].issued) -eq $instant) 'the issue time is read to the millisecond from issued_at alone'
    $label = Get-SpecrewTurnTokenSessionLabel -LiveToken $live[0]
    Assert-True ($label -match '2026-09-10 08:49:29 UTC') ('and the refusal label prints it as UTC, invariant: {0}' -f $label)
}
finally { if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue } }

# ============ Case 5: no site parses a timestamp on its own any more ===================================
Write-Host '  --- Case 5: the sites are converted, asserted on the text ---'
$storeText = Get-Content -LiteralPath $store -Raw -Encoding UTF8
$decisionText = Get-Content -LiteralPath $decisionStore -Raw -Encoding UTF8
$providerText = Get-Content -LiteralPath $provider -Raw -Encoding UTF8
Assert-True ($storeText -notmatch '\[datetimeoffset\]::Parse\(' -and $storeText -notmatch '\[datetime\]::Parse\(') 'the turn-end store contains no timestamp parse of its own'
Assert-True ($decisionText -match 'ConvertTo-SpecrewUtcTimestamp') 'the design-decision store reads recorded_at through the helper'
Assert-True ($providerText -notmatch '\[datetime\]::Parse\(\$recordedRaw\)' -and $providerText -notmatch "\[datetime\]::Parse\(\`$m\.Groups\['stamp'\]") 'the provider''s two handover timestamp parses are gone, routed through the helper'

# ============ Case 6: the approval checks from T017 read the ledger's times as instants ==================
# 202 iteration 002, after review sign-off: the fourth and fifth sites. "Was this approval already recorded?" read each
# ledger row's observed_at through [string] and re-parsed it as UTC. A row written with a `+00:00` offset comes back
# from ConvertFrom-Json as a LOCAL [datetime], so the re-parse read it shifted by this machine's zone: hours late ahead
# of UTC (an old record counted as this message's), hours early behind it (this message's own record skipped, so the
# turn end recorded it again - B4F-127's failure). A `Z` row lost only its fraction of a second.
Write-Host '  --- Case 6: the T017 approval checks on ledger rows whose observed_at survived JSON as a [datetime] ---'
$authorityStore = Join-Path $repoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1'
. $authorityStore
$root6 = Join-Path ([IO.Path]::GetTempPath()) ('tsr6-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
try {
    New-Item -ItemType Directory -Path (Join-Path $root6 '.specrew/authority') -Force | Out-Null
    $ledger6 = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $root6
    $hash6 = Get-SpecrewHumanAuthorityHash -Text 'approved for review round'
    $arrival6 = [DateTimeOffset]::UtcNow
    $write6 = {
        param([object[]]$Rows)
        $lines = foreach ($r in $Rows) { ([ordered]@{ schema_version = '1.0'; fact_type = 'typed-turn-exhausted'; turn_id = $r.turn; content_hash = $hash6; host_kind = 'copilot'; source_event = 'UserPromptSubmit'; minted = 'Write-SpecrewReviewRoundApprovalAuthorization'; session_id = 's6'; observed_at = $r.at } | ConvertTo-Json -Compress) }
        [IO.File]::WriteAllLines($ledger6, [string[]]@($lines))
    }
    foreach ($form in @(@{ n = '+00:00'; f = { param($t) $t.ToString('o') } }, @{ n = 'Z'; f = { param($t) $t.UtcDateTime.ToString('o') } })) {
        $recent = & $form.f $arrival6.AddSeconds(4)
        $old = & $form.f $arrival6.AddHours(-2)
        & $write6 @(@{ turn = 't-recent'; at = $recent })
        Assert-True ([bool](Test-SpecrewPromptChannelSawContent -ProjectRoot $root6 -ContentHash $hash6 -HostKind 'copilot' -SinceUtc $arrival6.ToString('o') -SessionId 's6')) ('{0} row: the message hook''s record 4 s after arrival counts as this message''s' -f $form.n)
        Assert-True ([bool](Test-SpecrewPromptChannelSawContent -ProjectRoot $root6 -ContentHash $hash6 -HostKind 'copilot' -SinceUtc $arrival6.ToString('o') -SessionId 's6' -MessageTimesUtc @($arrival6.ToString('o')))) ('{0} row: and pairs with the message''s own arrival, inside 15 s' -f $form.n)
        & $write6 @(@{ turn = 't-old'; at = $old })
        Assert-True (-not [bool](Test-SpecrewPromptChannelSawContent -ProjectRoot $root6 -ContentHash $hash6 -HostKind 'copilot' -SinceUtc $arrival6.ToString('o') -SessionId 's6')) ('{0} row: a record of the same text two hours earlier is not this message''s' -f $form.n)
        # The legacy check: history from before the message-ID key, so the rows carry no identity.
        & $write6 @(@{ turn = 'legacy-recent'; at = $recent })
        Assert-True ([bool](Test-SpecrewLegacyTurnRecorded -ProjectRoot $root6 -LegacyTurnId 'other' -ContentHash $hash6 -HostKind 'copilot' -SinceUtc $arrival6.ToString('o'))) ('{0} row: an old-key record of this message is found, so the turn end does not record it again' -f $form.n)
        & $write6 @(@{ turn = 'legacy-old'; at = $old })
        Assert-True (-not [bool](Test-SpecrewLegacyTurnRecorded -ProjectRoot $root6 -LegacyTurnId 'other' -ContentHash $hash6 -HostKind 'copilot' -SinceUtc $arrival6.ToString('o'))) ('{0} row: an old-key record of the same text two hours earlier is not this message' -f $form.n)
    }
}
finally { if (Test-Path -LiteralPath $root6) { Remove-Item -LiteralPath $root6 -Recurse -Force -ErrorAction SilentlyContinue } }

# ============ Case 7: the dispatcher's undelivered-line check reads the row's time as an instant ==========
# The sixth site, and the one CI caught: a not-recorded line disclosed in the same second the hook fire started read
# as older than the fire (the fraction dropped), so it was never put back. Run on the function itself, taken from the
# shipped dispatcher.
Write-Host '  --- Case 7: the dispatcher puts back a line disclosed during this fire, and only that one ---'
$dispatcher = Join-Path $repoRoot 'scripts/internal/specrew-hook-dispatcher.ps1'
$ast7 = [System.Management.Automation.Language.Parser]::ParseFile($dispatcher, [ref]$null, [ref]$null)
foreach ($fn in $ast7.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Restore-DispatcherUndeliveredNotRecordedLine', 'ConvertTo-DispatcherInstant', 'Write-DispatcherWarn') }, $true)) {
    . ([scriptblock]::Create($fn.Extent.Text))
}
$script:Banner = '[tsr]'
$root7 = Join-Path ([IO.Path]::GetTempPath()) ('tsr7-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
try {
    New-Item -ItemType Directory -Path (Join-Path $root7 '.specrew/runtime') -Force | Out-Null
    $journal7 = Join-Path $root7 '.specrew/runtime/authority-capture-drops.jsonl'
    # The fire starts 100 ms into a second; the line is disclosed 300 ms later, in the same second.
    $now7 = [DateTimeOffset]::UtcNow
    $start7 = [DateTimeOffset]::new($now7.Year, $now7.Month, $now7.Day, $now7.Hour, $now7.Minute, $now7.Second, 100, [TimeSpan]::Zero)
    $rows7 = @(
        ([ordered]@{ event = 'authority-phrase-not-recorded-disclosed'; entry_key = 'k-this-fire'; host_kind = 'claude'; session_id = 's7'; recorded_at = $start7.AddMilliseconds(300).ToString('o') } | ConvertTo-Json -Compress),
        ([ordered]@{ event = 'authority-phrase-not-recorded-disclosed'; entry_key = 'k-earlier'; host_kind = 'claude'; session_id = 's7'; recorded_at = $start7.AddHours(-2).ToString('o') } | ConvertTo-Json -Compress)
    )
    [IO.File]::WriteAllLines($journal7, [string[]]$rows7)
    $script:DispatcherStartedUtc = $start7
    $script:DispatcherNotRecordedReconciled = $false
    $script:DispatcherOutputWithheldThisFire = $false
    Restore-DispatcherUndeliveredNotRecordedLine -ProjectRoot $root7 -SessionId 's7' -DeliveredPayload '' 2>$null
    $putBack = @([IO.File]::ReadAllLines($journal7) | Where-Object { $_ -match 'not-recorded-undelivered' } | ForEach-Object { [string]($_ | ConvertFrom-Json).entry_key })
    Assert-True ($putBack -contains 'k-this-fire') 'the line disclosed 300 ms after the fire started, in the same second, is put back'
    Assert-True ($putBack -notcontains 'k-earlier') ('the line disclosed two hours before this fire is not (put back: {0})' -f ($putBack -join ', '))
}
finally { if (Test-Path -LiteralPath $root7) { Remove-Item -LiteralPath $root7 -Recurse -Force -ErrorAction SilentlyContinue } }

# ============ Case 9: the other stored times compared to the second ======================================
# The sweep that followed: the review engine's "latest" orderings and the reply-recording episode read their stored
# times through a [string] cast too. Their writers' formats kept the hours right, but not the fraction, so two records
# from the same second tied and the tie-breaker - not time - chose the newest.
Write-Host '  --- Case 9: the passing-run order and the degraded episode keep the fraction of a second ---'
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/reviewer-contracts.ps1')
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/review-run-index-writer.ps1')
$root9 = Join-Path ([IO.Path]::GetTempPath()) ('tsr9-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
try {
    $second9 = [DateTimeOffset]::new(2026, 10, 19, 8, 0, 0, 0, [TimeSpan]::Zero)
    foreach ($run in @(@{ id = 'run-b'; at = $second9.AddMilliseconds(100) }, @{ id = 'run-a'; at = $second9.AddMilliseconds(900) })) {
        $dir9 = Join-Path $root9 ('.specrew/review/inline/' + $run.id)
        New-Item -ItemType Directory -Path $dir9 -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $dir9 'review-run.json'), ([ordered]@{ run_id = $run.id; status = 'pass'; created_at = $run.at.ToString('o') } | ConvertTo-Json -Compress))
    }
    $order9 = @(Get-ContinuousCoReviewPassingReviewRuns -RepoRoot $root9 | ForEach-Object { [string]$_.run_id })
    Assert-True ($order9.Count -eq 2 -and $order9[0] -ceq 'run-a') ('the run created 800 ms later in the same second is the newest, not the one the run-id tie-breaker picks (order: {0})' -f ($order9 -join ', '))
    . (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1')
    New-Item -ItemType Directory -Path (Join-Path $root9 '.specrew/runtime') -Force | Out-Null
    $firstSeen9 = $second9.AddMilliseconds(437)
    [IO.File]::WriteAllText((Join-Path $root9 '.specrew/runtime/hook-output-health.jsonl'), ([ordered]@{ schema_version = '1.0'; state = 'degraded'; class = 'x'; first_seen = $firstSeen9.ToString('o'); count = 1 } | ConvertTo-Json -Compress))
    $since9 = Get-SpecrewReplyRecordingDegradedSince -ProjectRoot $root9
    Assert-True ($null -ne $since9 -and $since9.UtcTicks -eq $firstSeen9.UtcTicks) ('the degraded episode reads its first-seen time to the tick (got: {0})' -f $(if ($null -ne $since9) { $since9.ToString('o') } else { 'null' }))
}
finally { if (Test-Path -LiteralPath $root9) { Remove-Item -LiteralPath $root9 -Recurse -Force -ErrorAction SilentlyContinue } }

# ============ Case 8: no stored time is compared through a string any more ===============================
Write-Host '  --- Case 8: the authority store and both dispatcher copies, asserted on the text ---'
foreach ($site in @($authorityStore, $dispatcher, (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'))) {
    $siteText = Get-Content -LiteralPath $site -Raw -Encoding UTF8
    $stringReparse = [regex]::Matches($siteText, '\[DateTimeOffset\]::TryParse\(\s*\[string\]\$(entry|row|fact|request)\.[a-z_]+\s*,[^\n]*AssumeUniversal')
    Assert-True ($stringReparse.Count -eq 0) ('{0}: no stored time is re-parsed from a [string] cast with AssumeUniversal ({1} found)' -f (Split-Path $site -Leaf), $stringReparse.Count)
}
$governanceText = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1') -Raw -Encoding UTF8
Assert-True ($governanceText -notmatch '\[string\]\$(_\.)?result\.ended_at') 'shared-governance.ps1: neither "latest result" ordering reads ended_at through a [string] cast'

# ============ The same suite in a zone behind UTC =========================================================
# CI runs in UTC, where a local [datetime] and a UTC one print the same clock and only the fraction is lost. On Linux
# and macOS the zone is an environment variable, so the suite runs again in New York, once, where the hours show.
if (-not $IsWindows -and [string]::IsNullOrEmpty($env:SPECREW_TSR_ZONE_PASS)) {
    Write-Host '  --- the same suite again under TZ=America/New_York ---'
    $zoneArgs = @('-NoProfile', '-NonInteractive', '-File', $PSCommandPath)
    if ($MutateCooldown) { $zoneArgs += '-MutateCooldown' }
    $env:SPECREW_TSR_ZONE_PASS = '1'; $previousTz = $env:TZ; $env:TZ = 'America/New_York'
    try { $zoneOut = & pwsh @zoneArgs 2>&1; $zoneExit = $LASTEXITCODE }
    finally { $env:TZ = $previousTz; Remove-Item Env:SPECREW_TSR_ZONE_PASS -ErrorAction SilentlyContinue }
    $zoneOut | ForEach-Object { Write-Host ('    ' + $_) }
    Assert-True ($zoneExit -eq 0) 'the suite passes in a zone behind UTC'
}

if ($script:Failures -gt 0) {
    Write-Host ("timestamp-read: {0} FAILED" -f $script:Failures)
    exit 1
}
Write-Host 'timestamp-read: all cases passed'
exit 0
