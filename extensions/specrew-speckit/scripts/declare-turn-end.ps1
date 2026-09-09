#!/usr/bin/env pwsh
<#
.SYNOPSIS
  The governed TURN-END declaration. The agent supplies facts; this script decides what is rendered.

.DESCRIPTION
  WHAT THIS REPLACES, and why the replacement is a different KIND of thing rather than a better version of
  the same thing:

    - a check that scored the agent's prose - four of six header phrases in the flattened last message;
    - a 200-line transcript scan looking for orientation wording, which told one compliant session 188
      times that the human had never seen its banner;
    - an HTML comment the agent had to remember to type to declare intent;
    - and instruction text asking the agent to judge, unaided, whether a packet was earned.

  Each was a detector inferring intent from its shadow, and each punished correct output at least once.
  Here the agent passes FACTS as parameters, this script decides what to render and renders it, and the Stop
  hook asks one question with a yes/no answer: did this script run, for this session, for this turn?

  THE THREE GATES LIVE IN CODE, NOT IN THE AGENT'S JUDGEMENT. Actual work, time since the last render of
  this kind, and unchanged content were all instructions once. As instructions they produced eight stops in
  one session, none of them about the code. As a function they are decidable, testable, and the same on
  every host.

  A NO-OP IS RECORDED, NOT SKIPPED. "The agent declared and nothing was earned" and "the agent declared
  nothing at all" look identical from outside and mean opposite things, so the record distinguishes them.

  CHEAP AND HOST-NEUTRAL BY CONSTRUCTION. No git, no transcript, no module load, no host branch: a handful
  of small file reads the session already wrote. This runs at the end of every turn, and a per-turn cost is
  paid forever.

.EXAMPLE
  pwsh -File declare-turn-end.ps1 -Kind conversational
  pwsh -File declare-turn-end.ps1 -Kind in-flight -Pending 'the census dispatch'
  pwsh -File declare-turn-end.ps1 -Kind boundary -Summary 'Implemented fix 1 and proved it with four mutations.'
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

    # Artifacts this stage owes and has not produced. When any are named the boundary packet renders with NO
    # verdict options and NO marker and says what is owed instead - the governed rule, moved out of prose
    # into the one place that can actually enforce it.
    [AllowNull()][string[]] $Owed,

    [AllowNull()][string] $ProjectRoot,

    # Emit the decision as JSON on stderr-free stdout instead of the rendered text. For tests and tooling;
    # the agent never needs it.
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

$identity = Get-SpecrewSessionIdentityFromMarker -ProjectRoot $root
$paths = Get-SpecrewTurnEndPaths -ProjectRoot $root -HostKind $identity.host -SessionId $identity.session_id

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

function Get-SpecrewOrientationBlock {
    # (b) THE ORIENTATION, COMPOSED FROM ARTIFACTS RATHER THAN SCANNED FOR IN PROSE.
    #
    # What went before read up to 200 transcript lines hunting for banner wording, and got it wrong in the
    # direction that matters: it told a session whose opening message WAS a full banner that the human had
    # never seen one. This composes the same facts from the files that hold them - four small reads - and
    # returns them to be shown. The receipt is then written because this script rendered it, not because a
    # scan believed it did.
    param([string] $Root, $Identity)
    $lines = New-Object System.Collections.Generic.List[string]
    $version = ''
    try {
        $markerPath = Join-Path $Root '.specify/extensions/specrew-speckit/.specrew-extension-runtime.json'
        if (Test-Path -LiteralPath $markerPath -PathType Leaf) {
            $runtime = Get-Content -LiteralPath $markerPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if ($runtime.PSObject.Properties['specrew_version']) { $version = [string]$runtime.specrew_version }
        }
    }
    catch { $version = '' }

    $hostName = if ($null -ne $Identity -and -not [string]::IsNullOrWhiteSpace($Identity.host)) { $Identity.host } else { 'this host' }
    $versionText = if ([string]::IsNullOrWhiteSpace($version)) { 'Specrew' } else { ('Specrew {0}' -f $version) }
    $lines.Add(('**{0} is active on {1}.** Work here runs through spec -> plan -> implement -> review -> retro, and every stage boundary waits for your typed approval.' -f $versionText, $hostName)) | Out-Null

    try {
        $contextPath = Join-Path $Root '.specrew/start-context.json'
        if (Test-Path -LiteralPath $contextPath -PathType Leaf) {
            $context = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            $featureRef = ''
            $boundaryType = ''
            $lastAuthorized = ''
            if ($context.PSObject.Properties['session_state'] -and $null -ne $context.session_state) {
                if ($context.session_state.PSObject.Properties['feature_ref']) { $featureRef = [string]$context.session_state.feature_ref }
                if ($context.session_state.PSObject.Properties['boundary_type']) { $boundaryType = [string]$context.session_state.boundary_type }
            }
            if ($context.PSObject.Properties['boundary_enforcement'] -and $null -ne $context.boundary_enforcement) {
                if ($context.boundary_enforcement.PSObject.Properties['last_authorized_boundary']) { $lastAuthorized = [string]$context.boundary_enforcement.last_authorized_boundary }
            }
            if (-not [string]::IsNullOrWhiteSpace($featureRef)) {
                $lines.Add(('**Where this project stands**: feature `{0}`, working boundary `{1}`, last boundary you authorized `{2}`.' -f $featureRef, $boundaryType, $lastAuthorized)) | Out-Null
                $lines.Add(('**Your artifacts** live under `specs/{0}/`; the lifecycle position is in `.specrew/start-context.json` and the launch contract in `.specrew/last-start-prompt.md`.' -f $featureRef)) | Out-Null
            }
        }
    }
    catch { $null = $_ }

    $dials = New-Object System.Collections.Generic.List[string]
    try {
        $profilePath = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.specrew/user-profile.yml'
        if (Test-Path -LiteralPath $profilePath -PathType Leaf) {
            $inExpertise = $false
            foreach ($profileLine in @(Get-Content -LiteralPath $profilePath -Encoding UTF8 -ErrorAction Stop)) {
                if ($profileLine -cmatch '^expertise:\s*$') { $inExpertise = $true; continue }
                if ($inExpertise) {
                    if ($profileLine -cmatch '^\s{2,}([a-z_]+):\s*(\S+)\s*$') { $dials.Add(('{0}={1}' -f $Matches[1], $Matches[2])) | Out-Null }
                    elseif ($profileLine -cmatch '^\S') { break }
                }
            }
        }
    }
    catch { $null = $_ }
    if ($dials.Count -gt 0) {
        $lines.Add(('**How I am adapting to you** (from `~/.specrew/user-profile.yml`, and correct me if it is wrong): {0}.' -f ($dials -join ', '))) | Out-Null
    }

    $lines.Add('**At each boundary** the work stops and you are asked for an explicit `approved for <boundary>` reply. Nothing advances on my assessment that the work looks fine.') | Out-Null
    return ($lines -join [Environment]::NewLine)
}

# --- render -----------------------------------------------------------------------------------------
$pendingStopPath = Join-Path $root '.specrew/runtime/pending-verdict-stop.md'
$owedItems = @(@($Owed) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$body = ''
# Recorded so the hook can verify a boundary declaration against the pending crossing WITHOUT reading the
# transcript. Artifact against artifact: the declaration says which crossing it rendered, the gate state says
# which one is pending, and the two either name the same thing or they do not.
$declaredBoundary = ''
$declaredMarker = ''
$inFlightRun = 0
$inFlightExhausted = $false

switch ($Kind) {
    'conversational' {
        # Nothing. A turn that discussed something and changed nothing owes the human no ceremony, and
        # rendering one anyway is the noise this whole fix exists to remove.
        $body = ''
    }
    'in-flight' {
        # -Pending IS MANDATORY HERE and nowhere else. In-flight is the one kind no artifact can confirm: the
        # hook can check a boundary declaration against the pending crossing and a conversational one claims
        # nothing, but "work is in flight" is a statement about the world. The least it can be asked for is
        # WHAT is in flight, by name - which is also the only thing that makes the bound below meaningful,
        # since a run of identical waits is only detectable if the waits say what they are waiting for.
        if ([string]::IsNullOrWhiteSpace($Pending)) {
            throw "An in-flight turn must name what it is waiting for. Pass -Pending with the work in flight, for example: -Kind in-flight -Pending 'the census dispatch'."
        }
        $what = $Pending.Trim()
        $inFlightRun = Get-SpecrewInFlightRepeatCount -TurnEndRoot $paths.TurnEndRoot -PendingText $what -ExcludePath $paths.RecordPath
        if ($inFlightRun -gt $script:SpecrewTurnEndInFlightBound) {
            # THE BOUND TRIPS, and in-flight becomes a real stop. Carried from FR-045a rather than invented:
            # the same shape - an assertion that work continues, with nothing changing underneath it - already
            # had an answer, and giving in-flight its own unbounded lane would just move the old cap here.
            # The refusal NAMES the repeated text, because "you have said this too often" without quoting it
            # is a refusal the reader has to reconstruct.
            $inFlightExhausted = $true
            $body = ("Stopping rather than reporting in flight again. '{0}' has been the pending item on {1} consecutive turns with nothing else recorded, so continuing to wait on it is no longer a report - it is a loop. Say what should happen: keep waiting, check it directly, or abandon it." -f $what, $inFlightRun)
        }
        else {
            $body = ('In flight; continuing when {0} lands; nothing needed.' -f $what)
        }
    }
    'boundary' {
        $stop = Read-SpecrewPendingVerdictStop -Path $pendingStopPath
        if ($stop.present -and $owedItems.Count -eq 0) {
            $declaredBoundary = [string]$stop.boundary
            $declaredMarker = [string]$stop.marker
        }
        $sections = New-Object System.Collections.Generic.List[string]
        $sections.Add('## What I Just Did') | Out-Null
        $sections.Add($(if ([string]::IsNullOrWhiteSpace($Summary)) { '(no summary was supplied to the turn-end declaration)' } else { $Summary.Trim() })) | Out-Null
        $sections.Add('') | Out-Null
        $sections.Add('## Why I Stopped') | Out-Null
        if ($owedItems.Count -gt 0) {
            $sections.Add(('This stage owes artifacts it has not produced: {0}. There is nothing to approve yet, so this stop offers no options.' -f ($owedItems -join ', '))) | Out-Null
        }
        elseif ($stop.present) {
            $sections.Add(('The `{0}` boundary needs your judgment before the next stage starts.' -f $stop.boundary)) | Out-Null
            if (-not [string]::IsNullOrWhiteSpace($stop.coverage)) { $sections.Add($stop.coverage) | Out-Null }
        }
        else {
            $sections.Add($(if ([string]::IsNullOrWhiteSpace($Pending)) { 'The work reached a point where your judgment decides what happens next.' } else { $Pending.Trim() })) | Out-Null
        }
        $sections.Add('') | Out-Null
        $sections.Add('## What Needs Your Review') | Out-Null
        if ($stop.present) {
            $sections.Add(('Feature `{0}`; working boundary `{1}`; last boundary you authorized `{2}`.' -f $stop.feature, $stop.working_boundary, $stop.last_authorized)) | Out-Null
        }
        else { $sections.Add('The work described above.') | Out-Null }
        $sections.Add('') | Out-Null
        $sections.Add('## What Happens Next') | Out-Null
        if ($owedItems.Count -gt 0) {
            $sections.Add(('I produce what is owed - {0} - and come back to you then.' -f ($owedItems -join ', '))) | Out-Null
        }
        elseif ($stop.present) {
            $sections.Add(('On `{0}` the next stage starts. Nothing advances without it.' -f $stop.approval_phrase)) | Out-Null
        }
        else { $sections.Add('Your reply decides.') | Out-Null }
        $sections.Add('') | Out-Null
        $sections.Add('## Discussion Prompts') | Out-Null
        $sections.Add('Anything above you want changed, questioned, or done differently.') | Out-Null
        $sections.Add('') | Out-Null
        $sections.Add('## What I Need From You') | Out-Null
        if ($owedItems.Count -gt 0) {
            # NO options and NO marker while the stage owes artifacts - naming what is owed instead. The
            # rule existed in prose and nothing enforced it; a marker offered here is an approval phrase
            # for an empty increment.
            $sections.Add(('Nothing yet. What is missing is mine to produce: {0}.' -f ($owedItems -join ', '))) | Out-Null
        }
        elseif ($stop.present) {
            $sections.Add(('Reply with the approval phrase to advance: `{0}`' -f $stop.approval_phrase)) | Out-Null
            $sections.Add('Or tell me what to change instead - a correction is a complete answer.') | Out-Null
            $sections.Add('') | Out-Null
            $sections.Add($stop.marker) | Out-Null
        }
        else { $sections.Add('Your call on the above.') | Out-Null }
        $body = ($sections -join [Environment]::NewLine)
    }
}

# --- the gates, then the record ---------------------------------------------------------------------
$contentHash = Get-SpecrewTurnEndContentHash -Text $body
$previous = Get-SpecrewTurnEndPreviousRecord -TurnEndRoot $paths.TurnEndRoot -ExcludePath $paths.RecordPath -RenderedOnly
$decision = Get-SpecrewTurnEndRenderDecision -Kind $Kind -PreviousRecord $previous -ContentHash $contentHash
if ($inFlightExhausted) {
    # A tripped bound is a real stop, and a real stop is never rate-limited away. The in-flight gate exists
    # to stop the same reassurance repeating; suppressing the message that says the repetition has to end
    # would be the gate defeating its own purpose on the one turn it matters.
    $decision = [pscustomobject]@{ render = $true; reason = 'in-flight-bound-tripped' }
}

# The session's FIRST turn-end of any kind, including a conversational one: a session that opens with a
# question and answers it has still opened, and the human is owed the orientation on that turn rather than
# whenever work happens to begin.
$orientationOwed = -not (Test-Path -LiteralPath $paths.OrientationPath -PathType Leaf)
$orientationText = ''
if ($orientationOwed) {
    $orientationText = Get-SpecrewOrientationBlock -Root $root -Identity $identity
}

$rendered = ''
if ($decision.render -and -not [string]::IsNullOrWhiteSpace($body)) { $rendered = $body }
if (-not [string]::IsNullOrWhiteSpace($orientationText)) {
    $rendered = if ([string]::IsNullOrWhiteSpace($rendered)) { $orientationText } else { ($orientationText + [Environment]::NewLine + [Environment]::NewLine + $rendered) }
}

$record = [pscustomobject][ordered]@{
    schema_version = '1.0'
    kind           = $Kind
    turn_id        = [string]$paths.TurnId
    session_id     = [string]$identity.session_id
    host           = [string]$identity.host
    rendered       = (-not [string]::IsNullOrWhiteSpace($rendered))
    render_reason  = [string]$decision.reason
    content_hash   = $contentHash
    boundary       = $declaredBoundary
    marker         = $declaredMarker
    # The hook reads these two rather than recomputing the run: the count is a fact about the record set at
    # the moment of declaring, and a second opinion computed later could disagree with what was rendered.
    in_flight_run       = $inFlightRun
    in_flight_exhausted = $inFlightExhausted
    owed           = @($owedItems)
    pending        = $(if ([string]::IsNullOrWhiteSpace($Pending)) { '' } else { $Pending.Trim() })
    summary        = $(if ([string]::IsNullOrWhiteSpace($Summary)) { '' } else { $Summary.Trim() })
    orientation    = $orientationOwed
    rendered_at    = [DateTimeOffset]::UtcNow.ToString('o')
}
$written = Write-SpecrewTurnEndRecord -Path $paths.RecordPath -Record $record

# The orientation receipt is written because THIS SCRIPT rendered the orientation into its return value,
# which is the only claim the artifact makes. It is written after the record so a failed record write never
# leaves a session marked oriented with nothing to show for it.
if ($written -and $orientationOwed -and -not [string]::IsNullOrWhiteSpace($orientationText)) {
    try {
        $orientationDir = Split-Path -Parent $paths.OrientationPath
        if ($orientationDir -and -not (Test-Path -LiteralPath $orientationDir -PathType Container)) {
            New-Item -ItemType Directory -Path $orientationDir -Force | Out-Null
        }
        $receipt = [ordered]@{ schema_version = '1.0'; rendered_at = [DateTimeOffset]::UtcNow.ToString('o'); rendered_by = 'declare-turn-end' } | ConvertTo-Json -Compress
        [System.IO.File]::WriteAllText($paths.OrientationPath, ($receipt + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
    }
    catch { $null = $_ }
}

if ($AsJson) {
    [pscustomobject][ordered]@{
        record_path   = [string]$paths.RecordPath
        turn_id       = [string]$paths.TurnId
        anchored      = [bool]$paths.Anchored
        record_written = [bool]$written
        rendered      = [bool]$record.rendered
        render_reason = [string]$decision.reason
        orientation   = [bool]$orientationOwed
        text          = $rendered
    } | ConvertTo-Json -Depth 6
    return
}

if (-not [string]::IsNullOrWhiteSpace($rendered)) { Write-Output $rendered }
