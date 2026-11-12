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
function New-SpecrewCitedVerdictTurn {
    param([Parameter(Mandatory)][string]$Text)
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
    return @{ TurnIdentity = $id; TranscriptPath = $path; HostKind = 'claude' }
}

# A fixture that records a verdict while no crossing is recorded (no boundary ledger, or none waiting) tests what an
# approval does downstream, not how one is captured; no capture could record it, so it says so: a declared out-of-band
# authorization, recorded as an authorization and as a bypass.
function Get-SpecrewFixtureOutOfBandSplat {
    param([Parameter(Mandatory)][string]$Reason)
    return @{ EvidenceSource = 'fixture-out-of-band'; OutOfBandReason = $Reason }
}
