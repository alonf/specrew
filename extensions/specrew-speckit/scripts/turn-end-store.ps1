# THE TURN-END DECLARATION STORE - the one place the writer and the reader agree on.
#
# WHY THIS FILE EXISTS AT ALL, and it is the whole design in one sentence: the hook verifies artifacts the
# agent's SCRIPTS wrote, never the agent's PROSE. What went before scored the agent's text - four of six
# header phrases in the flattened last message, a 200-line transcript scan for banner wording, an HTML
# comment marker the agent had to remember to type. Every one of those punished compliant output at least
# once, because a detector reading prose is guessing at intent from its shadow. Here the agent supplies
# FACTS as parameters, a script decides what to render, and the hook asks one question with a yes/no answer:
# did the script run, for this session, for this turn?
#
# AND THE HANDSHAKE IS THE FAILURE MODE. If the writer and the reader ever compute a different path, the
# hook finds no record and refuses every compliant turn - strictly worse than what it replaces. So the path
# is computed HERE, once, and both sides dot-source this file. A second copy of this arithmetic anywhere is
# the bug, not a convenience.
#
# HOST-NEUTRAL BY CONSTRUCTION: nothing below names a host, branches on one, or asks one anything. The host
# name is data that arrives in session-marker.json and is hashed into a directory name.
#
# CHEAP BY CONSTRUCTION: no git, no transcript, no module load. The whole path is small JSON reads on files
# the session already wrote, because this runs at the end of every turn and a per-turn cost is paid forever.

$script:SpecrewTurnEndSchemaVersion = '1.0'
$script:SpecrewTurnEndKinds = @('boundary', 'in-flight', 'conversational')

# IN-FLIGHT IS THE ONE KIND THE HOOK CANNOT VERIFY, so it is the one that needs a bound.
#
# A boundary declaration is checked against the pending crossing; a conversational one claims nothing. But
# "work is in flight, continuing when it lands" is an assertion about the world that no artifact confirms -
# and an unbounded assertion of that shape is a way to never stop. FR-045a already met this problem from the
# other direction and answered it the same way: a `continue` needs intervening progress, and repeated
# continues with none trip a bounded guard rather than looping forever. That bound is 3, and it is carried
# here rather than re-chosen, because two different numbers for the same idea is how a guard rots.
$script:SpecrewTurnEndInFlightBound = 3

function Get-SpecrewTurnEndOwnerHash {
    # The SAME arithmetic Get-SpecrewMaterialRuntimeState uses for its per-session state root, kept
    # deliberately identical so a session's turn-end records sit beside its other per-session records
    # instead of in a parallel namespace with its own drift.
    [OutputType([string])]
    param([AllowNull()][string] $HostKind, [AllowNull()][string] $SessionId)

    if ([string]::IsNullOrWhiteSpace($SessionId)) { return '' }
    $safeHost = if ([string]::IsNullOrWhiteSpace($HostKind)) { 'unknown' } else { (($HostKind -replace '[^a-zA-Z0-9-]+', '-').Trim('-').ToLowerInvariant()) }
    $safeSession = (($SessionId -replace '[^a-zA-Z0-9-]+', '-').Trim('-'))
    if ([string]::IsNullOrWhiteSpace($safeSession)) { return '' }
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes(('{0}|{1}' -f $safeHost, $safeSession))
        return (-join ([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }))
    }
    catch { return '' }
}

function Get-SpecrewSessionIdentityFromMarker {
    # The agent's script has no host arguments - it is invoked by a human-facing skill, not by the
    # dispatcher - so it takes its identity from the marker the session's own bootstrap wrote. The hook
    # receives the same two values as flags and does NOT read the marker, which is the point: if the two
    # ever disagree the handshake is broken, and the test asserts they do not.
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $ProjectRoot)

    $result = [pscustomobject]@{ host = ''; session_id = ''; found = $false }
    try {
        $markerPath = Join-Path $ProjectRoot '.specrew/runtime/session-marker.json'
        if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) { return $result }
        $marker = Get-Content -LiteralPath $markerPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $marker) { return $result }
        $result.host = if ($marker.PSObject.Properties['host']) { [string]$marker.host } else { '' }
        $result.session_id = if ($marker.PSObject.Properties['session_id']) { [string]$marker.session_id } else { '' }
        $result.found = -not [string]::IsNullOrWhiteSpace($result.session_id)
        return $result
    }
    catch { return $result }
}

function Get-SpecrewTurnCounterPath {
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $StateRoot)
    return (Join-Path $StateRoot 'turn-counter.json')
}

function Get-SpecrewTurnId {
    # WHAT A "TURN" IS: a counter THE HOOK INCREMENTS AT STOP. Nothing else advances it.
    #
    # The first design derived the id from the conformance turn baseline, which the provider writes at the
    # host's genuine prompt boundary. It reads well and it is wrong in a way that only shows on the hosts
    # this most needs to work on: a host that never delivers a prompt event never writes a baseline, so every
    # turn in that session resolves to the SAME id - and a declaration made once, in turn 1, would satisfy
    # the hook at turn 50 forever after. The check would be perfectly green and measuring nothing.
    #
    # A counter the hook itself advances cannot have that failure. It needs no host cooperation, it advances
    # exactly once per Stop the hook actually processed, and "did the agent declare THIS turn" becomes a
    # question about a number rather than about whether a host emitted an event.
    #
    # It is READ here and never written: the writer of the counter is the hook, at Stop, and a reader that
    # also increments would race the very thing it is trying to measure.
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $StateRoot)

    try {
        $counterPath = Get-SpecrewTurnCounterPath -StateRoot $StateRoot
        if (-not (Test-Path -LiteralPath $counterPath -PathType Leaf)) { return 'turn-1' }
        $counter = Get-Content -LiteralPath $counterPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $counter -or -not $counter.PSObject.Properties['turn']) { return 'turn-1' }
        $turn = [int]$counter.turn
        if ($turn -lt 1) { $turn = 1 }
        return ('turn-{0}' -f $turn)
    }
    catch { return 'turn-1' }
}

function Step-SpecrewTurnCounter {
    # THE HOOK'S WRITE, and the only one. Called at Stop AFTER the declaration for the current turn has been
    # read and judged, so a declaration written earlier in the same turn - which is where it will be written,
    # since the agent runs the script as its last ACTION and the Stop fires after the message - still matches
    # when the hook looks for it.
    #
    # Only a fire the provider actually processed advances it. A duplicate hook delivery for the same
    # message must not, or the turn would move underneath a declaration that is still current.
    [OutputType([int])]
    param([Parameter(Mandatory)][string] $StateRoot)

    $temp = $null
    try {
        $counterPath = Get-SpecrewTurnCounterPath -StateRoot $StateRoot
        $current = 1
        if (Test-Path -LiteralPath $counterPath -PathType Leaf) {
            try {
                $existing = Get-Content -LiteralPath $counterPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                if ($null -ne $existing -and $existing.PSObject.Properties['turn']) { $current = [int]$existing.turn }
            }
            catch { $current = 1 }
        }
        if ($current -lt 1) { $current = 1 }
        $next = $current + 1
        if (-not (Test-Path -LiteralPath $StateRoot -PathType Container)) { New-Item -ItemType Directory -Path $StateRoot -Force | Out-Null }
        $temp = $counterPath + '.tmp-' + [guid]::NewGuid().ToString('N')
        [System.IO.File]::WriteAllText($temp, (([ordered]@{ schema_version = '1.0'; turn = $next; stepped_at = [DateTimeOffset]::UtcNow.ToString('o') } | ConvertTo-Json -Compress)), [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temp, $counterPath, $true)
        return $next
    }
    catch { return -1 }
    finally {
        if (-not [string]::IsNullOrWhiteSpace($temp) -and (Test-Path -LiteralPath $temp -PathType Leaf)) {
            Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-SpecrewTurnEndPaths {
    # THE ONE RESOLVER. Everything that reads or writes a turn-end record comes through here.
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [AllowNull()][string] $HostKind,
        [AllowNull()][string] $SessionId
    )

    $runtimeRoot = Join-Path $ProjectRoot '.specrew/runtime'
    $ownerHash = Get-SpecrewTurnEndOwnerHash -HostKind $HostKind -SessionId $SessionId
    $anchored = -not [string]::IsNullOrWhiteSpace($ownerHash)
    $stateRoot = if ($anchored) { Join-Path (Join-Path $runtimeRoot 'conformance-sessions') $ownerHash } else { $runtimeRoot }
    $turnEndRoot = if ($anchored) { Join-Path (Join-Path $runtimeRoot 'turn-end') $ownerHash } else { Join-Path $runtimeRoot 'turn-end' }
    $turnId = Get-SpecrewTurnId -StateRoot $stateRoot
    return [pscustomobject]@{
        Anchored        = $anchored
        OwnerHash       = $ownerHash
        StateRoot       = $stateRoot
        TurnEndRoot     = $turnEndRoot
        TurnId          = $turnId
        RecordPath      = Join-Path $turnEndRoot ($turnId + '.json')
        OrientationPath = Join-Path $stateRoot 'orientation-rendered.json'
    }
}

function Read-SpecrewTurnEndRecord {
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $Path)

    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($item.Length -le 0 -or $item.Length -gt 262144) { return $null }
        $record = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $record -or $record -is [System.Array]) { return $null }
        if ([string]$record.schema_version -cne $script:SpecrewTurnEndSchemaVersion) { return $null }
        if ([string]$record.kind -cnotin $script:SpecrewTurnEndKinds) { return $null }
        return $record
    }
    catch { return $null }
}

function Write-SpecrewTurnEndRecord {
    # Atomic temp-and-move, UTF-8 without BOM, and it READS THE RECORD BACK before reporting success. A
    # write this whole contract rests on must not be reported on the strength of no exception.
    [OutputType([bool])]
    param([Parameter(Mandatory)][string] $Path, [Parameter(Mandatory)]$Record)

    $temp = $null
    try {
        $directory = Split-Path -Parent $Path
        if ($directory -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        $temp = $Path + '.tmp-' + [guid]::NewGuid().ToString('N')
        [System.IO.File]::WriteAllText($temp, ($Record | ConvertTo-Json -Depth 8 -Compress), [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temp, $Path, $true)
        $back = Read-SpecrewTurnEndRecord -Path $Path
        return ($null -ne $back -and [string]$back.kind -ceq [string]$Record.kind -and [string]$back.turn_id -ceq [string]$Record.turn_id)
    }
    catch { return $false }
    finally {
        if (-not [string]::IsNullOrWhiteSpace($temp) -and (Test-Path -LiteralPath $temp -PathType Leaf)) {
            Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-SpecrewTurnEndRenderDecision {
    # THE THREE GATES, AND THEY LIVE HERE RATHER THAN IN THE AGENT'S HEAD.
    #
    # This is the half that used to be instruction text: render a packet when there was actual work, not too
    # soon after the last one, and not the same thing twice. Instructions asking an agent to judge those
    # three things produced the measured failure this replaces - eight stops in one session, none about the
    # code. As a function it is decidable, testable, and identical on every host.
    #
    # Returning a NO-OP is a first-class outcome, not a failure: the declaration is still recorded, so the
    # hook can tell "the agent declared and nothing was earned" from "the agent declared nothing at all".
    # Those two look the same from the outside and mean opposite things.
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][ValidateSet('boundary', 'in-flight', 'conversational')][string] $Kind,
        [AllowNull()]$PreviousRecord,
        [AllowNull()][string] $ContentHash,
        [int] $MinimumSecondsBetweenRenders = 45,
        [AllowNull()][datetime] $NowUtc
    )

    $now = if ($null -eq $NowUtc) { [datetime]::UtcNow } else { $NowUtc.ToUniversalTime() }

    # Gate 1 - actual work. A conversational turn earns nothing by definition; that is what the kind means.
    if ($Kind -eq 'conversational') {
        return [pscustomobject]@{ render = $false; reason = 'conversational-turn-renders-nothing' }
    }

    if ($null -eq $PreviousRecord) {
        return [pscustomobject]@{ render = $true; reason = 'first-render-of-this-kind' }
    }

    # Gate 2 - unchanged content. Checked BEFORE elapsed time on purpose: re-rendering an identical packet
    # is noise no matter how long ago the last one was, and saying so names the real reason.
    if (-not [string]::IsNullOrWhiteSpace($ContentHash) -and
        [string]$PreviousRecord.content_hash -ceq $ContentHash -and
        [string]$PreviousRecord.kind -ceq $Kind) {
        return [pscustomobject]@{ render = $false; reason = 'identical-to-the-last-render-of-this-kind' }
    }

    # Gate 3 - elapsed time since the last render OF THIS KIND. Scoped to the kind so an in-flight line
    # never suppresses a boundary packet, which is the case that must never be rate-limited away.
    if ([string]$PreviousRecord.kind -ceq $Kind) {
        try {
            $previousAt = [datetimeoffset]::Parse([string]$PreviousRecord.rendered_at, [System.Globalization.CultureInfo]::InvariantCulture).UtcDateTime
            $elapsed = ($now - $previousAt).TotalSeconds
            if ($elapsed -ge 0 -and $elapsed -lt $MinimumSecondsBetweenRenders -and $Kind -eq 'in-flight') {
                return [pscustomobject]@{ render = $false; reason = 'in-flight-line-already-shown-moments-ago' }
            }
        }
        catch { $null = $_ }
    }

    return [pscustomobject]@{ render = $true; reason = 'render-earned' }
}

function Get-SpecrewTurnEndContentHash {
    [OutputType([string])]
    param([AllowNull()][string] $Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        return (-join ([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }))
    }
    catch { return '' }
}

function Get-SpecrewInFlightRepeatCount {
    # How many times IN A ROW this session has declared in-flight against the SAME pending text, counting the
    # declaration about to be written. The run must be unbroken: any other kind, or a different pending text,
    # resets it - because the thing being bounded is "nothing is changing", not "in-flight was used a lot".
    # A session that alternates real work with in-flight waits is doing exactly what in-flight is for.
    #
    # IT COUNTS SUPPRESSED NO-OPS TOO, and that is the opposite of what Get-SpecrewTurnEndPreviousRecord does
    # with -RenderedOnly. The asymmetry is deliberate and load-bearing. The render gates ask *what did the
    # human last SEE*, so a no-op must not suppress against itself. This bound asks *how long has nothing
    # changed*, and a suppressed no-op is the strongest possible evidence for that - it is a turn that
    # produced nothing new, by the gates' own judgement. Filtering it out here would mean the quieter a
    # session got, the longer it could go on saying nothing, which is exactly backwards.
    # Measured: runs 1-5 against one pending item give run counts 1,2,3,4,5 with renders at 1, 4 and 5 - the
    # two suppressed turns still carry the run forward and the bound trips on schedule.
    [OutputType([int])]
    param(
        [Parameter(Mandatory)][string] $TurnEndRoot,
        [AllowNull()][AllowEmptyString()][string] $PendingText,
        [AllowNull()][string] $ExcludePath
    )

    if ([string]::IsNullOrWhiteSpace($PendingText)) { return 1 }
    $needle = $PendingText.Trim()
    $run = 1
    try {
        if (-not (Test-Path -LiteralPath $TurnEndRoot -PathType Container)) { return $run }
        $files = @(Get-ChildItem -LiteralPath $TurnEndRoot -Filter '*.json' -File -ErrorAction Stop |
                Where-Object { [string]::IsNullOrWhiteSpace($ExcludePath) -or $_.FullName -ne $ExcludePath } |
                Sort-Object LastWriteTimeUtc -Descending)
        foreach ($file in $files) {
            $record = Read-SpecrewTurnEndRecord -Path $file.FullName
            if ($null -eq $record) { continue }
            # A CONVERSATIONAL TURN DOES NOT BREAK THE RUN, and the first version of this let it.
            #
            # Found by the independent review, which ran the sequence rather than reading it: in-flight,
            # conversational, in-flight, conversational... reset the count to 1 every time and the bound
            # NEVER TRIPPED. An agent could wait forever on one item by saying "nothing to report" between
            # waits - and "nothing to report" is, by its own declaration, nothing happening. Treating it as
            # progress meant the cheapest possible turn laundered the guard.
            #
            # So the walk SKIPS conversational records. What breaks a run is something that actually
            # happened: a boundary declaration (the human was asked something) or a wait on a DIFFERENT
            # item. Both are real events; a no-op is the absence of one.
            if ([string]$record.kind -ceq 'conversational') { continue }
            if ([string]$record.kind -cne 'in-flight') { break }
            $recordPending = if ($record.PSObject.Properties['pending']) { ([string]$record.pending).Trim() } else { '' }
            if ($recordPending -cne $needle) { break }
            $run++
        }
        return $run
    }
    catch { return $run }
}

function Get-SpecrewTurnEndPreviousRecord {
    # The most recent record for this session, whatever turn it belonged to - the gates compare across
    # turns, because "already shown moments ago" is a fact about the session and not about one turn.
    #
    # -RenderedOnly is what keeps the gates from suppressing against something the human never saw. A no-op
    # record is still a record, and comparing new content against a no-op would let one suppressed render
    # suppress the next one for the same reason, forever. The gates ask "what did the human last SEE".
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $TurnEndRoot,
        [AllowNull()][string] $ExcludePath,
        [switch] $RenderedOnly
    )

    try {
        if (-not (Test-Path -LiteralPath $TurnEndRoot -PathType Container)) { return $null }
        $files = @(Get-ChildItem -LiteralPath $TurnEndRoot -Filter '*.json' -File -ErrorAction Stop |
                Where-Object { [string]::IsNullOrWhiteSpace($ExcludePath) -or $_.FullName -ne $ExcludePath } |
                Sort-Object LastWriteTimeUtc -Descending)
        foreach ($file in $files) {
            $record = Read-SpecrewTurnEndRecord -Path $file.FullName
            if ($null -eq $record) { continue }
            if ($RenderedOnly -and -not [bool]$record.rendered) { continue }
            return $record
        }
        return $null
    }
    catch { return $null }
}
