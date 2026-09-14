#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Record this turn and verify the agent-authored message. Call as the turn's last tool.
.DESCRIPTION
  Returns information to the agent, never a replacement reply. Ordinary turns emit no text.
  Boundary drafts are verified; only missing machine-derived approval/marker lines are supplied.
  Token ownership, missing-artifact withholding and the pending crossing remain authoritative.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('boundary', 'in-flight', 'conversational')][string] $Kind,

    # What this turn actually did, in the agent's own words. A FACT supplied as a parameter - the script
    # never inspects prose to find it, and never scores it.
    [AllowNull()][AllowEmptyString()][string] $Summary,

    # What is pending: the named background work for an in-flight turn, or what the human is being asked to
    # decide at a boundary.
    [AllowNull()][AllowEmptyString()][string] $Pending,

    # Artifacts this stage owes and has not produced. Approval and marker are withheld;
    # the agent names the missing artifacts and next step in the drafted packet.
    [AllowNull()][string[]] $Owed,

    # THE TOKEN THE HOOK HANDED YOU AT THE START OF THIS TURN, in a line beginning `[specrew-turn]`. It is
    # how this declaration is placed under the session that is actually making it - the hook that issued
    # the token is the hook that will judge the record. With more than one session live in this project,
    # a declaration without it cannot be placed and is refused; with exactly one, it is optional.
    [AllowNull()][AllowEmptyString()][string] $Token,

    [AllowNull()][string] $ProjectRoot,

    # Draft of the human-facing reply; the script verifies it but never renders it.
    [AllowNull()][string] $MessagePath,

    # Emit the verification and any missing machine lines as JSON for tests and tooling.
    [switch] $AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$storePath = Join-Path $PSScriptRoot 'turn-end-store.ps1'
if (-not (Test-Path -LiteralPath $storePath -PathType Leaf)) {
    throw "The turn-end store is missing next to this script: '$storePath'."
}
. $storePath

$root = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { (Get-Location).Path } else { $ProjectRoot }
$root = [System.IO.Path]::GetFullPath($root)

# IDENTITY COMES FROM THE TOKEN THE HOOK HANDED THE AGENT, never from a project-wide file and never from a
# ranking of what is on disk. Two designs stood here and the independent review broke both the same way -
# a session credited for a declaration another session made. This one refuses rather than guesses: the
# four outcomes below are the ruling, and the two refusals each say exactly what would resolve them.
$holder = Resolve-SpecrewTurnTokenHolder -ProjectRoot $root -Token $Token
$scriptRelativePath = '.specify/extensions/specrew-speckit/scripts/declare-turn-end.ps1'
switch ([string]$holder.outcome) {
    'unknown-token' {
        # FAILS CLOSED, NAMING THE VALUE. A token no live session holds is either a stale line from an
        # earlier turn (the hook consumed that one at its Stop) or a typo; either way writing under some
        # other session would be the false credit this exists to prevent.
        $liveCount = @($holder.live).Count
        $lines = @(
            ("Turn-end declaration refused: the token '{0}' matches no live session in this project ({1} live token{2})." -f $Token.Trim(), $liveCount, $(if ($liveCount -eq 1) { '' } else { 's' })),
            "Use the token from the MOST RECENT line beginning '[specrew-turn]' in this turn - the hook hands one out at each turn start and consumes it at Stop, so an earlier turn's token is no longer live.",
            ("Then run again: pwsh -File {0} -Kind {1} -Token <that token>" -f $scriptRelativePath, $Kind)
        )
        [Console]::Error.WriteLine(($lines -join [Environment]::NewLine))
        exit 2
    }
    'ambiguous' {
        # REFUSED, NAMING BOTH SESSIONS AND THE PARAMETER. This is the only case the fallback decides, and
        # it decides by not deciding. A leftover from a crashed session lands here too, and the refusal
        # names each token's path and issue time so a human who knows a session is gone can remove its
        # token; nothing here ages one out on its own.
        $named = @($holder.live | ForEach-Object { '  - ' + (Get-SpecrewTurnTokenSessionLabel -LiveToken $_) })
        $lines = @(
            ("Turn-end declaration refused: {0} sessions are live in this project and no -Token was given, so this declaration cannot be placed under the right one:" -f @($holder.live).Count)
        ) + $named + @(
            "Pass -Token with the token the hook handed you at the start of this turn (the most recent line beginning '[specrew-turn]'):",
            ("  pwsh -File {0} -Kind {1} -Token <that token>" -f $scriptRelativePath, $Kind),
            "A token listed above that belongs to a session you know has ended can be removed at the path shown; it is a leftover, not a live turn."
        )
        [Console]::Error.WriteLine(($lines -join [Environment]::NewLine))
        exit 2
    }
}
$paths = if ([string]$holder.outcome -in @('matched', 'single')) {
    Get-SpecrewTurnEndPathsForStateRoot -ProjectRoot $root -StateRoot $holder.state_root -OwnerHash $holder.owner_hash
}
else {
    # Absent: this host delivered no turn-start event, so there is nothing to echo. The hook will have
    # none either, and the two degrade together - absence is not mismatch.
    Get-SpecrewTurnEndPaths -ProjectRoot $root -HostKind '' -SessionId ''
}

function Read-SpecrewPendingVerdictStop {
    # Parses the artifact sync-boundary-state.ps1 writes. THE VALUES COME FROM THE FILE, never from a guess
    # about which phase comes next - inferring the marker from the intended next phase is the specific
    # mistake this artifact exists to prevent, and it is worth restating at the one place that reads it.
    param([string] $Path)
    $result = [pscustomobject]@{
        present = $false; boundary = ''; approval_phrase = ''; marker = ''
        working_boundary = ''; last_authorized = ''; feature = ''; coverage = ''
    }
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $result }
        $lines = @(Get-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = [string]$lines[$i]
            if ($line -cmatch '^Boundary to ask for:\s*(.+)$') { $result.boundary = $Matches[1].Trim() }
            elseif ($line -cmatch '^Human approval phrase:\s*(.+)$') { $result.approval_phrase = $Matches[1].Trim() }
            elseif ($line -cmatch '^Working boundary:\s*(.+)$') { $result.working_boundary = $Matches[1].Trim() }
            elseif ($line -cmatch '^Last authorized boundary:\s*(.+)$') { $result.last_authorized = $Matches[1].Trim() }
            elseif ($line -cmatch '^Feature:\s*(.+)$') { $result.feature = $Matches[1].Trim() }
            elseif ($line -cmatch '^Coverage line[^:]*:\s*(.+)$') { $result.coverage = $Matches[1].Trim() }
            elseif ($line -cmatch '^Marker last line exactly:') {
                if (($i + 1) -lt $lines.Count) { $result.marker = ([string]$lines[$i + 1]).Trim() }
            }
        }
        $result.present = -not [string]::IsNullOrWhiteSpace($result.boundary)
        return $result
    }
    catch { return $result }
}

# The agent authors the reply. This declaration verifies the draft and records facts for Stop.
$message = ''
if (-not [string]::IsNullOrWhiteSpace($MessagePath)) {
    $message = Get-Content -LiteralPath $MessagePath -Raw -Encoding UTF8 -ErrorAction Stop
    if ([Text.Encoding]::UTF8.GetByteCount($message) -gt 131072) { throw 'The authored message exceeds 128 KiB.' }
}
$owedItems = @(@($Owed) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$declaredBoundary = ''
$declaredMarker = ''
$approvalPhrase = ''
$machineLines = [Collections.Generic.List[string]]::new()
$packetCheck = [pscustomobject]@{ valid = $false; missing = @() }
$inFlightRun = 0
$inFlightExhausted = $false
if ($Kind -eq 'in-flight') {
    if ([string]::IsNullOrWhiteSpace($Pending)) { throw 'An in-flight turn must name background work with -Pending.' }
    $inFlightRun = Get-SpecrewInFlightRepeatCount -TurnEndRoot $paths.TurnEndRoot -PendingText $Pending.Trim() -ExcludePath $paths.RecordPath
    $inFlightExhausted = $inFlightRun -gt $script:SpecrewTurnEndInFlightBound
}
if ($Kind -eq 'boundary') {
    $packetCheck = Test-SpecrewAuthoredPacket -Message $message
    $stop = Read-SpecrewPendingVerdictStop -Path (Join-Path $root '.specrew/runtime/pending-verdict-stop.md')
    if ($owedItems.Count -gt 0) {
        # Missing artifacts cannot acquire approval text or a marker through a drafted packet either.
        if ($message -match 'SPECREW-VERDICT-BOUNDARY|(?im)^\s*approved for ') {
            $packetCheck = [pscustomobject]@{ valid = $false; missing = @('withhold approval and marker while artifacts are owed') }
        }
    }
    elseif ($stop.present) {
        $declaredBoundary = [string]$stop.boundary
        $declaredMarker = [string]$stop.marker
        $approvalPhrase = [string]$stop.approval_phrase
        $draftMarkers = @([regex]::Matches($message, '<!--\s*SPECREW-VERDICT-BOUNDARY:[^>]*-->') | ForEach-Object { $_.Value })
        if (@($draftMarkers | Where-Object { $_ -cne $declaredMarker }).Count -gt 0) {
            $packetCheck = [pscustomobject]@{ valid = $false; missing = @('replace the stale crossing marker with the pending marker') }
        }
        if ($packetCheck.valid) {
            if (-not (Test-SpecrewTurnMessageVisible -Message $message -Expected $approvalPhrase)) { $machineLines.Add($approvalPhrase) }
            if (-not (Test-SpecrewTurnMessageVisible -Message $message -Expected $declaredMarker)) { $machineLines.Add($declaredMarker) }
        }
    }
}
$record = [pscustomobject][ordered]@{
    schema_version = '1.0'
    kind = $Kind
    turn_id = [string]$paths.TurnId
    turn_token = [string]$holder.token
    owner_hash = [string]$paths.OwnerHash
    rendered = $false
    render_reason = 'agent-authored-message'
    content_hash = Get-SpecrewTurnEndContentHash -Text $message
    message = $message
    packet_valid = [bool]$packetCheck.valid
    packet_missing = @($packetCheck.missing)
    boundary = $declaredBoundary
    marker = $declaredMarker
    approval_phrase = $approvalPhrase
    in_flight_run = $inFlightRun
    in_flight_exhausted = $inFlightExhausted
    owed = @($owedItems)
    pending = $(if ([string]::IsNullOrWhiteSpace($Pending)) { '' } else { $Pending.Trim() })
    summary = [string]$Summary
    orientation = $false
    rendered_at = [DateTimeOffset]::UtcNow.ToString('o')
    rendered_ms = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
}
$written = Write-SpecrewTurnEndRecord -Path $paths.RecordPath -Record $record
$machineText = $machineLines -join [Environment]::NewLine
if ($AsJson) {
    [pscustomobject][ordered]@{
        record_path = [string]$paths.RecordPath
        turn_id = [string]$paths.TurnId
        anchored = [bool]$paths.Anchored
        record_written = [bool]$written
        identity = [string]$holder.outcome
        rendered = $false
        render_reason = 'agent-authored-message'
        orientation = $false
        packet_valid = [bool]$packetCheck.valid
        packet_missing = @($packetCheck.missing)
        owed = @($owedItems)
        text = $machineText
    } | ConvertTo-Json -Depth 6
    return
}
if ($Kind -eq 'boundary' -and -not $packetCheck.valid) {
    [Console]::Error.WriteLine(('Packet not verified: {0}; pass the agent-authored packet with -MessagePath, then include it in your reply.' -f ($packetCheck.missing -join ', ')))
}
if (-not [string]::IsNullOrWhiteSpace($machineText)) { Write-Output $machineText }
