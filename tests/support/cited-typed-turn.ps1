# Feature 203 T004 (FR-022): a captured boundary verdict is recorded only from the typed turn it cites, which the writer
# reads back from the host's record and classifies itself. A test that records a verdict through the real writer gives it
# such a turn: one human entry in a Claude-shaped transcript (the recorded shape of
# tests/fixtures/hook-payloads/claude/queued), outside the project so no fixture tree changes. Returns the splat the
# writer takes: @{ TurnIdentity; TranscriptPath; HostKind }.
#
# The writer re-reads the turn through the authority store, which every hook process loads; a suite that loaded only
# shared-governance gets it here. The store sets strict mode and the error preference where it is dot-sourced, so both
# are put back as the suite had them.
if (-not (Get-Command Resolve-SpecrewCitedTypedAct -ErrorAction SilentlyContinue)) {
    $citedTurnStrict = $true
    try { $null = $citedTurnUndefinedProbe; $citedTurnStrict = $false } catch { $citedTurnStrict = $true }
    $citedTurnPreference = $ErrorActionPreference
    . (Join-Path $PSScriptRoot '..\..\scripts\internal\bootstrap\HumanAuthorityStore.ps1')
    $ErrorActionPreference = $citedTurnPreference
    if (-not $citedTurnStrict) { Set-StrictMode -Off }
}
function Register-SpecrewTestTypedTurn {
    # Feature 203 T013 (B5F-066; maintainer rulings 2026-11-12): the turn's ledger row the prompt hook writes, pointing at the
    # transcript the host keeps, so an authorization recorded from this turn is found and checked when it is used. No switch
    # turns the check off: a test that records an approval and expects it to be used gives it this real-shaped turn.
    # Returns the act identity, the key every writer and the check use.
    param([Parameter(Mandatory)][string]$ProjectRoot, [Parameter(Mandatory)][string]$Text, [Parameter(Mandatory)][string]$MessageId,
        [Parameter(Mandatory)][string]$TranscriptPath, [string]$HostKind = 'claude', [string]$SourceEvent = 'UserPromptSubmit')
    $turnId = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = $HostKind; message_id = $MessageId; text = $Text })).Identity
    [System.IO.Directory]::CreateDirectory((Join-Path $ProjectRoot '.specrew/authority')) | Out-Null
    $null = Register-SpecrewExhaustedTurn -ProjectRoot $ProjectRoot -TurnId $turnId -HostKind $HostKind -SourceEvent $SourceEvent -MintedWriters '' `
        -ContentHash (Get-SpecrewHumanAuthorityHash -Text $Text.Trim()) -SessionId 'test-typed-turn' -Identity 'typed-act' -TurnOrigin 'typed-user' `
        -TranscriptPath $TranscriptPath -MessageId $MessageId
    return $turnId
}

function Add-SpecrewTestTypedTranscriptRecord {
    # Feature 203 T013 (B5F-066): ONLY the host's side of a typed turn - the transcript record Claude Code writes for a typed
    # message (turnOrigin human, promptSource typed, origin.kind human), appended to the given transcript or a new one. For a
    # test that drives the prompt hook's capture (Invoke-SpecrewTypedAuthorityCapture -MessageId -TranscriptPath), which writes
    # the turn's ledger row itself. Returns @{ TranscriptPath; MessageId }.
    param([Parameter(Mandatory)][string]$Text, [string]$TranscriptPath, [string]$MessageId)
    if ([string]::IsNullOrWhiteSpace($MessageId)) { $MessageId = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 12) }
    if ([string]::IsNullOrWhiteSpace($TranscriptPath)) {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) 'specrew-cited-turns'
        [System.IO.Directory]::CreateDirectory($dir) | Out-Null
        $TranscriptPath = Join-Path $dir ($MessageId + '.jsonl')
    }
    $entry = [ordered]@{
        type = 'user'; uuid = [guid]::NewGuid().ToString(); promptId = $MessageId; sessionId = 'test-typed-turn'
        timestamp = [DateTimeOffset]::UtcNow.ToString('o'); origin = [ordered]@{ kind = 'human' }; turnOrigin = 'human'; promptSource = 'typed'
        message = [ordered]@{ role = 'user'; content = $Text }
    }
    [System.IO.File]::AppendAllText($TranscriptPath, (($entry | ConvertTo-Json -Depth 6 -Compress) + "`n"), [System.Text.UTF8Encoding]::new($false))
    return @{ TranscriptPath = $TranscriptPath; MessageId = $MessageId }
}

function New-SpecrewTypedTurnFixture {
    # Feature 203 T013 (B5F-066): a typed turn as the host and the prompt hook leave it - a transcript record in the shape Claude
    # Code writes for a typed message (turnOrigin human, promptSource typed, origin.kind human), appended to the given
    # transcript or a new one, and the turn's ledger row pointing at it. Returns @{ TurnIdentity; TranscriptPath; MessageId;
    # HostKind }: TurnIdentity is what a writer takes as -TurnIdentity.
    param([Parameter(Mandatory)][string]$ProjectRoot, [Parameter(Mandatory)][string]$Text, [string]$TranscriptPath, [string]$MessageId)
    $record = Add-SpecrewTestTypedTranscriptRecord -Text $Text -TranscriptPath $TranscriptPath -MessageId $MessageId
    $TranscriptPath = $record.TranscriptPath; $MessageId = $record.MessageId
    $turnId = Register-SpecrewTestTypedTurn -ProjectRoot $ProjectRoot -Text $Text -MessageId $MessageId -TranscriptPath $TranscriptPath
    return @{ TurnIdentity = $turnId; TranscriptPath = $TranscriptPath; MessageId = $MessageId; HostKind = 'claude' }
}

function Register-SpecrewTestNoTranscriptHostTurn {
    # Feature 203 T013 (maintainer ruling 2026-11-12): a turn on a host whose hook input carries no transcript path (Copilot).
    # The prompt hook writes its ledger row with the host and no transcript path; the check then finds the turn and reports it
    # 'unverified' (the text rules decided at capture), journaled and counted by host. Returns the act identity.
    param([Parameter(Mandatory)][string]$ProjectRoot, [Parameter(Mandatory)][string]$Text, [string]$MessageId, [string]$HostKind = 'copilot')
    if ([string]::IsNullOrWhiteSpace($MessageId)) { $MessageId = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 12) }
    $turnId = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = $HostKind; message_id = $MessageId; text = $Text })).Identity
    [System.IO.Directory]::CreateDirectory((Join-Path $ProjectRoot '.specrew/authority')) | Out-Null
    $null = Register-SpecrewExhaustedTurn -ProjectRoot $ProjectRoot -TurnId $turnId -HostKind $HostKind -SourceEvent 'UserPromptSubmit' -MintedWriters '' `
        -ContentHash (Get-SpecrewHumanAuthorityHash -Text $Text.Trim()) -SessionId 'test-typed-turn' -Identity 'typed-act' -TurnOrigin 'typed-user' -MessageId $MessageId
    return $turnId
}

function New-SpecrewCitedVerdictTurn {
    # Feature 203 T013: with -ProjectRoot, the turn is also registered on that project's ledger, as the prompt hook does, so
    # the verdict the writer records from it is found by the sender check when the boundary gate uses it.
    param([Parameter(Mandatory)][string]$Text, [string]$ProjectRoot)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) 'specrew-cited-turns'
    [System.IO.Directory]::CreateDirectory($dir) | Out-Null
    $id = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 12)
    $entry = [ordered]@{
        type = 'user'; uuid = [guid]::NewGuid().ToString(); promptId = $id; sessionId = 'cited-turn'
        # Feature 203 T013: the shape Claude Code writes for a typed message (tests/fixtures/hook-payloads/claude/transcript-origins):
        # turnOrigin human with promptSource typed. A record that says human with no promptSource is "!" command output.
        timestamp = [DateTimeOffset]::UtcNow.ToString('o'); origin = [ordered]@{ kind = 'human' }; turnOrigin = 'human'; promptSource = 'typed'
        message = [ordered]@{ role = 'user'; content = $Text }
    }
    $path = Join-Path $dir ($id + '.jsonl')
    [System.IO.File]::WriteAllText($path, (($entry | ConvertTo-Json -Depth 6 -Compress) + "`n"), [System.Text.UTF8Encoding]::new($false))
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) { $null = Register-SpecrewTestTypedTurn -ProjectRoot $ProjectRoot -Text $Text -MessageId $id -TranscriptPath $path }
    return @{ TurnIdentity = $id; TranscriptPath = $path; HostKind = 'claude' }
}

# A fixture that records a verdict while no crossing is recorded (no boundary ledger, or none waiting) tests what an
# approval does downstream, not how one is captured; no capture could record it, so it says so: a declared out-of-band
# authorization, recorded as an authorization and as a bypass.
function Get-SpecrewFixtureOutOfBandSplat {
    param([Parameter(Mandatory)][string]$Reason)
    return @{ EvidenceSource = 'fixture-out-of-band'; OutOfBandReason = $Reason }
}

# Iteration review round A finding 1: a review launch spends a budget grant only when the before-implement verdict it cites
# was typed by the human. A fixture that writes a grant therefore records that verdict as the boundary sync does: an entry
# in the lifecycle ledger (.specrew/start-context.json verdict_history), captured from a typed turn this helper also leaves
# (the host's transcript record and the prompt hook's ledger row). An existing start-context is kept; the entry is added
# when the ledger does not already hold that authorization id. Returns the entry.
function Add-SpecrewTestLedgerVerdict {
    param([Parameter(Mandatory)][string]$ProjectRoot, [Parameter(Mandatory)][string]$AuthorizationId, [string]$FeatureRef = '001-demo',
        [string]$FromBoundary = 'tasks', [string]$ToBoundary = 'before-implement')
    $text = 'approved for ' + $ToBoundary
    $turn = New-SpecrewTypedTurnFixture -ProjectRoot $ProjectRoot -Text $text
    $path = Join-Path $ProjectRoot '.specrew/start-context.json'
    [System.IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
    $context = [ordered]@{}
    if (Test-Path -LiteralPath $path -PathType Leaf) { $context = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 32 }
    if ($context['boundary_enforcement'] -isnot [System.Collections.IDictionary]) { $context['boundary_enforcement'] = [ordered]@{} }
    $history = [System.Collections.Generic.List[object]]::new()
    foreach ($e in @($context['boundary_enforcement']['verdict_history'])) { if ($null -ne $e) { $history.Add($e) } }
    $existing = @($history | Where-Object { [string]$_['authorization_id'] -ceq $AuthorizationId }) | Select-Object -First 1
    if ($null -ne $existing) { return $existing }
    $entry = [ordered]@{ from_boundary = $FromBoundary; to_boundary = $ToBoundary; verdict_text = $text; authorizing_human = 'unattributed'
        feature_ref = $FeatureRef; recorded_at = '2026-11-01T10:00:00Z'; authorization_id = $AuthorizationId
        evidence_source = 'hook-captured-user-prompt'; host_kind = 'claude'; turn_identity = [string]$turn.TurnIdentity }
    $history.Add($entry)
    $context['boundary_enforcement']['verdict_history'] = @($history)
    [System.IO.File]::WriteAllText($path, ($context | ConvertTo-Json -Depth 32), [System.Text.UTF8Encoding]::new($false))
    return $entry
}