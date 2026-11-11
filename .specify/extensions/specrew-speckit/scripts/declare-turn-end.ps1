#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Record this turn and verify the agent-authored message. Call as the turn's last tool.
.DESCRIPTION
  Returns information to the agent, never a replacement reply. Ordinary turns emit no text.
  A boundary declaration returns the four response lines and the marker from the pending-verdict record; the Stop
  reads the packet from the reply itself (203 T011 follow-up). No draft is read.
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
    # the agent names the missing artifacts and next step in its packet.
    [AllowNull()][string[]] $Owed,

    # THE TOKEN THE HOOK HANDED YOU AT THE START OF THIS TURN, in a line beginning `[specrew-turn]`. It is
    # how this declaration is placed under the session that is actually making it - the hook that issued
    # the token is the hook that will judge the record. With more than one session live in this project,
    # a declaration without it cannot be placed and is refused; with exactly one, it is optional.
    [AllowNull()][AllowEmptyString()][string] $Token,

    [AllowNull()][string] $ProjectRoot,

    # NOT READ (203 T011 follow-up, FR-046; maintainer ruling 2026-11-11). There is no draft any more: the Stop reads
    # the packet from the reply. Accepted, and ignored, so a caller still passing a draft path declares as before;
    # stdin is not read either.
    [AllowNull()][string] $MessagePath,

    # Emit the record facts and the lines for the reply as JSON for tests and tooling.
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

# 203 T011: the record is read by Read-SpecrewPendingVerdictStopRecord in turn-end-store.ps1, the one reader the
# Stop uses too, so the two cannot parse it differently.

# The agent authors the reply; this declaration records facts for the Stop. 203 T011 follow-up (FR-046; maintainer
# ruling 2026-11-11): it reads no draft, from a file or stdin, and checks nothing against one. The Stop reads the packet
# from the reply (Test-SpecrewReplyPacket) and the decision parts from the pending-verdict record.
$draftSource = 'none'
# Maintainer ruling 2026-11-11: a caller still passing a draft path is told, once, that it is not read.
if ($PSBoundParameters.ContainsKey('MessagePath')) {
    [Console]::Error.WriteLine('declare-turn-end: -MessagePath is no longer read, and the draft it names is ignored: the Stop reads your reply itself. Drop -MessagePath from the call.')
}
$owedItems = @(@($Owed) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$declaredBoundary = ''
$declaredMarker = ''
$approvalPhrase = ''
$machineLines = [Collections.Generic.List[string]]::new()
$inFlightRun = 0
$inFlightExhausted = $false
if ($Kind -eq 'in-flight') {
    if ([string]::IsNullOrWhiteSpace($Pending)) { throw 'An in-flight turn must name background work with -Pending.' }
    $inFlightRun = Get-SpecrewInFlightRepeatCount -TurnEndRoot $paths.TurnEndRoot -PendingText $Pending.Trim() -ExcludePath $paths.RecordPath
    $inFlightExhausted = $inFlightRun -gt $script:SpecrewTurnEndInFlightBound
}
if ($Kind -eq 'boundary') {
    $stop = Read-SpecrewPendingVerdictStopRecord -Path (Join-Path $root '.specrew/runtime/pending-verdict-stop.md')
    # Missing artifacts acquire no approval text or marker: the stop names what is owed instead.
    if ($owedItems.Count -eq 0 -and $stop.present) {
        $declaredBoundary = [string]$stop.boundary
        $declaredMarker = [string]$stop.marker
        $approvalPhrase = [string]$stop.approval_phrase
        # The lines the reply must carry, from the record: the four responses, then the marker last.
        foreach ($line in @(Get-SpecrewVerdictResponseLines -ApprovalPhrase $approvalPhrase)) { $machineLines.Add($line) }
        $machineLines.Add($declaredMarker)
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
    boundary = $declaredBoundary
    marker = $declaredMarker
    approval_phrase = $approvalPhrase
    in_flight_run = $inFlightRun
    in_flight_exhausted = $inFlightExhausted
    owed = @($owedItems)
    pending = $(if ([string]::IsNullOrWhiteSpace($Pending)) { '' } else { $Pending.Trim() })
    summary = [string]$Summary
    draft_source = $draftSource
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
        owed = @($owedItems)
        draft_source = $draftSource
        text = $machineText
    } | ConvertTo-Json -Depth 6
    return
}
if (-not [string]::IsNullOrWhiteSpace($machineText)) { Write-Output $machineText }
