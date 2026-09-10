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
    $found = Find-SpecrewCurrentTurnToken -ProjectRoot $root
    Assert-True ([string]$found.token -ceq 'aa') 'the token is found from issued_at alone'
    # Two tokens 30 ms apart, both ISO-only: the ordering must see the 30 ms, which the string re-parse lost.
    $stateRoot2 = Join-Path $root '.specrew/runtime/conformance-sessions/def'
    New-Item -ItemType Directory -Path $stateRoot2 -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $stateRoot2 'turn-token.json'), ([ordered]@{ schema_version = '1.0'; token = 'bb'; turn_id = 'turn-1'; issued_at = $instant.AddMilliseconds(30).ToString('o') } | ConvertTo-Json -Compress), [System.Text.UTF8Encoding]::new($false))
    $found2 = Find-SpecrewCurrentTurnToken -ProjectRoot $root
    Assert-True ([string]$found2.token -ceq 'bb') 'and a token issued 30 ms later, ISO-only, orders as newer - the sub-second part survives the read'
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

if ($script:Failures -gt 0) {
    Write-Host ("timestamp-read: {0} FAILED" -f $script:Failures)
    exit 1
}
Write-Host 'timestamp-read: all cases passed'
exit 0
