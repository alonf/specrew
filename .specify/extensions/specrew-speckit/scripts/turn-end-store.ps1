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
# name is data the dispatcher passes to the hook and is hashed into a directory name. The script never reads
# it at all - it takes identity from the token the hook issued, for the reasons under THE IDENTITY HANDSHAKE.
#
# CHEAP BY CONSTRUCTION: no git, no transcript, no module load. The whole path is small JSON reads on files
# the session already wrote, because this runs at the end of every turn and a per-turn cost is paid forever.

$script:SpecrewTurnEndSchemaVersion = '1.0'
$script:SpecrewTurnEndKinds = @('boundary', 'in-flight', 'conversational')

# EVERY TIMESTAMP IS READ THROUGH ONE FUNCTION. Three sites in this batch were bitten by ConvertFrom-Json
# coercing an ISO string into a [datetime] - the design-decision read-back, the token ordering, and the
# render cooldown - each wrong in a different way. The reader lives beside this file and is loaded here, so
# the writer and the reader of every record below agree on what a timestamp is the same way they agree on
# where a record lives: by sharing the code rather than re-deriving it.
$script:SpecrewTimestampReadPath = Join-Path $PSScriptRoot 'timestamp-read.ps1'
if (-not (Get-Command ConvertTo-SpecrewUtcTimestamp -ErrorAction SilentlyContinue) -and
    (Test-Path -LiteralPath $script:SpecrewTimestampReadPath -PathType Leaf)) {
    . $script:SpecrewTimestampReadPath
}

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

# THE IDENTITY HANDSHAKE: THE HOOK HANDS THE TOKEN TO THE AGENT, THE AGENT HANDS IT BACK, AND NOTHING
# IN BETWEEN GUESSES.
#
# What stood here first read `.specrew/runtime/session-marker.json` for the declaring session's identity.
# The independent review broke it in one probe: the marker is PROJECT-WIDE and stamped by whichever session
# started last, so with two sessions open, A declared and the record landed under B's path - A refused for a
# declaration it made, B credited with one it did not. **A project-scoped file cannot answer a
# session-scoped question**, so the read went, not repaired.
#
# What replaced it resolved to the NEWEST token across the project's session directories, and the
# confirmatory review broke that too, the same way: B started its turn last, A's declaration landed under
# B, and B's Stop CREDITED it. Newest-wins is the same inference from shared state with a different tiebreak.
# The ruling on it: crediting the wrong session is worse than refusing, so newest-wins is gone.
#
# What stands now has no inference in it at all:
#
#   - The hook writes a token into its OWN session directory when the turn starts, and HANDS IT TO THE
#     AGENT in its turn-start output - one line. The party that knows tells the party that acts.
#   - declare-turn-end takes -Token and writes under the session holding it. A token no live session holds
#     is refused, naming the value.
#   - With NO -Token: exactly one live token is unambiguous and is accepted; more than one is REFUSED,
#     naming both sessions and the parameter - that is the ambiguous case, and it is the only case where the
#     fallback decides anything. No tokens at all is absence: a host with no turn-start event, and both
#     sides degrade together.
#   - LIVE MEANS UNCONSUMED. The hook deletes its session's token at Stop, after judging the declaration
#     and only when the turn actually ended (a block force-continues the same turn and keeps it). A session
#     that crashed leaves its token behind, and that leftover costs the next token-less declarer one
#     refusal - which names the leftover's path, so a human who knows the session is gone can remove it.
#     Nothing here ages a token out, because "it is old so it must be dead" is inference again.
#
# ABSENCE IS STILL NOT MISMATCH: the hook that issued no token accepts a record carrying none. What fails
# closed is a token PRESENT on the hook side and different in the record.

function Get-SpecrewTurnTokenPath {
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $StateRoot)
    return (Join-Path $StateRoot 'turn-token.json')
}

function Write-SpecrewTurnToken {
    # THE HOOK'S WRITE, at turn start. A fresh random token per turn: it is an identity, not a secret, and
    # it only has to be different from the one another session is holding.
    #
    # -ReuseUnconsumed is how the hook calls it. A token still on disk at a turn start means this session's
    # own Stop has not consumed it: the turn is still open (a SessionStart fired mid-turn on compaction, or a
    # host delivered two turn-start events for one prompt), or the previous Stop never ran. Either way the
    # open turn keeps its token, and the line the agent was already handed stays true. Overwriting it here
    # would make the token in the agent's context unknown to the hook that issued it - one refusal per
    # session opening, on every host that fires SessionStart and then the first prompt event.
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $StateRoot, [AllowNull()][string] $TurnId, [switch] $ReuseUnconsumed)

    $temp = $null
    try {
        if ($ReuseUnconsumed) {
            $existing = Read-SpecrewTurnToken -StateRoot $StateRoot
            if (-not [string]::IsNullOrWhiteSpace($existing)) { return $existing }
        }
        if (-not (Test-Path -LiteralPath $StateRoot -PathType Container)) { New-Item -ItemType Directory -Path $StateRoot -Force | Out-Null }
        $token = [guid]::NewGuid().ToString('N')
        $path = Get-SpecrewTurnTokenPath -StateRoot $StateRoot
        $temp = $path + '.tmp-' + [guid]::NewGuid().ToString('N')
        # issued_ms is a NUMBER on purpose, and it is what the ordering reads. ConvertFrom-Json coerces an
        # ISO-8601 string into a [datetime] on the way back, and re-parsing that lost the sub-second part -
        # so two tokens issued in the same second compared EQUAL and the newest-wins sort became arbitrary.
        # Measured: session B won over a token issued 30 ms later, and the losing session could not recover.
        # This is the second time in this batch that date coercion has broken a round-trip; a number cannot
        # be coerced into something else, so the ordering no longer depends on a type surviving JSON.
        $record = [ordered]@{ schema_version = '1.0'; token = $token; turn_id = [string]$TurnId; issued_at = [DateTimeOffset]::UtcNow.ToString('o'); issued_ms = (Get-SpecrewUtcNowMilliseconds) }
        [System.IO.File]::WriteAllText($temp, ($record | ConvertTo-Json -Compress), [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temp, $path, $true)
        return $token
    }
    catch { return '' }
    finally {
        if (-not [string]::IsNullOrWhiteSpace($temp) -and (Test-Path -LiteralPath $temp -PathType Leaf)) {
            Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        }
    }
}

function Read-SpecrewTurnToken {
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $StateRoot)
    try {
        $path = Get-SpecrewTurnTokenPath -StateRoot $StateRoot
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return '' }
        $record = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $record -or -not $record.PSObject.Properties['token']) { return '' }
        return ([string]$record.token)
    }
    catch { return '' }
}

function Remove-SpecrewTurnToken {
    # THE HOOK'S CONSUMPTION, at Stop, after the declaration has been judged and only when the turn actually
    # ended. This is what "live" means: a token that is still on disk belongs to a turn that has not been
    # closed by its own hook. Returns whether a token was there to consume, so a hook can tell "consumed"
    # from "there was nothing" without a second read.
    [OutputType([bool])]
    param([Parameter(Mandatory)][string] $StateRoot)
    try {
        $path = Get-SpecrewTurnTokenPath -StateRoot $StateRoot
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
        Remove-Item -LiteralPath $path -Force -ErrorAction Stop
        return $true
    }
    catch { return $false }
}

function Get-SpecrewLiveTurnTokens {
    # Every UNCONSUMED token in this project, one per session directory that holds one. This is the whole
    # of what the script can see, and it is listed rather than ranked: the ranking was the bug.
    #
    # THE LEGACY ROOT IS A CANDIDATE TOO. A host that passes no session id keeps its state at the runtime
    # root itself, and the hook writes its token THERE. The first version scanned only the per-session
    # directories, so on such a host the hook held a token, the script found none, the record carried
    # none - and "absence is not mismatch" became a mismatch after all, failing closed on every
    # declaration. The independent review saw exactly that and withheld it as out of scope; the fix-2 tail
    # hit it as PH-e. Absence means neither side has a token, not that the script did not look.
    [OutputType([object[]])]
    param([Parameter(Mandatory)][string] $ProjectRoot)

    $live = New-Object System.Collections.Generic.List[object]
    try {
        $runtimeRoot = Join-Path $ProjectRoot '.specrew/runtime'
        $roots = @()
        $roots += [pscustomobject]@{ path = $runtimeRoot; owner = '' }
        $sessionsRoot = Join-Path $runtimeRoot 'conformance-sessions'
        if (Test-Path -LiteralPath $sessionsRoot -PathType Container) {
            foreach ($dir in @(Get-ChildItem -LiteralPath $sessionsRoot -Directory -ErrorAction Stop)) {
                $roots += [pscustomobject]@{ path = $dir.FullName; owner = $dir.Name }
            }
        }
        foreach ($rootEntry in $roots) {
            $tokenPath = Get-SpecrewTurnTokenPath -StateRoot $rootEntry.path
            if (-not (Test-Path -LiteralPath $tokenPath -PathType Leaf)) { continue }
            try {
                $record = Get-Content -LiteralPath $tokenPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                if ($null -eq $record -or [string]::IsNullOrWhiteSpace([string]$record.token)) { continue }
                # The issue time is reported in the refusal so a human can tell a leftover from a live turn. It
                # is READ THROUGH THE ONE HELPER, whichever shape the field survived JSON in.
                $issued = $null
                if ($record.PSObject.Properties['issued_ms'] -and $null -ne $record.issued_ms) { $issued = ConvertTo-SpecrewUtcTimestamp -Value $record.issued_ms }
                if ($null -eq $issued -and $record.PSObject.Properties['issued_at']) { $issued = ConvertTo-SpecrewUtcTimestamp -Value $record.issued_at }
                $live.Add([pscustomobject]@{
                        token      = [string]$record.token
                        state_root = [string]$rootEntry.path
                        owner_hash = [string]$rootEntry.owner
                        turn_id    = $(if ($record.PSObject.Properties['turn_id']) { [string]$record.turn_id } else { '' })
                        issued     = $issued
                        path       = [string]$tokenPath
                    }) | Out-Null
            }
            catch { continue }
        }
    }
    catch { $null = $_ }
    return @($live.ToArray())
}

function Resolve-SpecrewTurnTokenHolder {
    # THE SCRIPT'S SIDE, and the four outcomes are the ruling, in order:
    #
    #   matched        -Token names a live token: write under the session holding it.
    #   unknown-token  -Token names no live token: refused, naming the value. Fails CLOSED.
    #   single         no -Token, exactly one live token: unambiguous, accepted.
    #   ambiguous      no -Token, more than one live token: refused, naming every session and -Token.
    #   absent         no tokens at all: a host with no turn-start event; both sides degrade together.
    #
    # Nothing here picks. A caller that gets 'ambiguous' or 'unknown-token' has been told exactly what would
    # resolve it, and the resolution is information only the agent has.
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [AllowNull()][AllowEmptyString()][string] $Token
    )

    $live = @(Get-SpecrewLiveTurnTokens -ProjectRoot $ProjectRoot)
    $result = [pscustomobject]@{ outcome = 'absent'; token = ''; state_root = ''; owner_hash = ''; live = $live }
    $wanted = if ([string]::IsNullOrWhiteSpace($Token)) { '' } else { $Token.Trim() }
    if (-not [string]::IsNullOrWhiteSpace($wanted)) {
        $match = @($live | Where-Object { [string]$_.token -ceq $wanted })
        if ($match.Count -ge 1) {
            $result.outcome = 'matched'
            $result.token = [string]$match[0].token
            $result.state_root = [string]$match[0].state_root
            $result.owner_hash = [string]$match[0].owner_hash
        }
        else { $result.outcome = 'unknown-token' }
        return $result
    }
    if ($live.Count -eq 1) {
        $result.outcome = 'single'
        $result.token = [string]$live[0].token
        $result.state_root = [string]$live[0].state_root
        $result.owner_hash = [string]$live[0].owner_hash
    }
    elseif ($live.Count -gt 1) { $result.outcome = 'ambiguous' }
    return $result
}

function Get-SpecrewTurnTokenSessionLabel {
    # How a session is NAMED in a refusal. The per-session directory is a hash of host|session-id - opaque,
    # but it is the directory the human can go and look at, and the issue time beside it is what tells a
    # live turn from a leftover.
    [OutputType([string])]
    param([Parameter(Mandatory)]$LiveToken)
    $where = if ([string]::IsNullOrWhiteSpace([string]$LiveToken.owner_hash)) { 'the runtime root (a host that passes no session id)' } else { ('session ' + ([string]$LiveToken.owner_hash).Substring(0, [Math]::Min(12, ([string]$LiveToken.owner_hash).Length)) + '...') }
    $when = if ($null -ne $LiveToken.issued) { ([DateTimeOffset]$LiveToken.issued).ToString('yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture) + ' UTC' } else { 'an unknown time' }
    return ('{0}, token issued {1}, at {2}' -f $where, $when, [string]$LiveToken.path)
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


# THE ORDERING RULE (feature 203 T011, DRIFT-054; maintainer ruling 2026-11-10): A TURN'S TOKEN IS USED UP, AND ITS COUNTER
# STEPPED, ONLY AFTER EVERY CHECK IN THAT STOP HAS PASSED. The conformance provider used to do both as soon as it did not block
# itself, so a check that ran in the same Stop and blocked - the co-review navigator after it, or any other - force-continued
# a turn that had no token left: the reply to the block could not be declared, and its own Stop counted it as another,
# undeclared turn (DRIFT-054: the counter went 1 to 3, then 3 to 5). Now the provider only records its judgment here as
# pending, and the dispatcher - the one party that sees every check's result - commits it at the end of the Stop, or keeps
# the turn when any check blocked. Every Stop the provider judged leaves one history line, the record DRIFT-054 found missing.

function Get-SpecrewTurnCommitPendingPath {
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $StateRoot)
    return (Join-Path $StateRoot 'turn-commit-pending.json')
}

function Write-SpecrewTurnCommitPending {
    # The conformance provider's half: this Stop's judgment, waiting for the other checks. -Passed is whether the provider
    # itself let the turn end; a turn it blocked is still recorded, so the history line names the check that blocked.
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string] $StateRoot,
        [Parameter(Mandatory)][string] $TurnId,
        [Parameter()][AllowNull()][AllowEmptyString()][string] $DeclarationKind,
        [Parameter()][bool] $Passed = $false
    )
    $temp = $null
    try {
        if (-not (Test-Path -LiteralPath $StateRoot -PathType Container)) { New-Item -ItemType Directory -Path $StateRoot -Force | Out-Null }
        $path = Get-SpecrewTurnCommitPendingPath -StateRoot $StateRoot
        $temp = $path + '.tmp-' + [guid]::NewGuid().ToString('N')
        $record = [ordered]@{
            schema_version = '1.0'; turn_id = [string]$TurnId
            declaration_kind = $(if ([string]::IsNullOrWhiteSpace($DeclarationKind)) { 'absent' } else { [string]$DeclarationKind })
            passed = [bool]$Passed; judged_at = [DateTimeOffset]::UtcNow.ToString('o')
        }
        [System.IO.File]::WriteAllText($temp, ($record | ConvertTo-Json -Compress), [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temp, $path, $true)
        return $true
    }
    catch { return $false }
    finally {
        if (-not [string]::IsNullOrWhiteSpace($temp) -and (Test-Path -LiteralPath $temp -PathType Leaf)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
    }
}

function Read-SpecrewTurnCommitPending {
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $StateRoot)
    try {
        $path = Get-SpecrewTurnCommitPendingPath -StateRoot $StateRoot
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
        $record = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $record -or [string]$record.schema_version -cne '1.0') { return $null }
        return $record
    }
    catch { return $null }
}

function Complete-SpecrewTurnEnd {
    # The dispatcher's half, run once at the end of a Stop, after every check. With no block emitted and the conformance
    # provider's judgment passed, the turn ends: the counter steps and the token is used up. With any block emitted, the
    # turn goes on under the same token and the same id; the pending judgment stays until a Stop commits it or the provider
    # judges again. One history line is appended per Stop. Returns the line, or $null when no judgment was pending (the provider
    # did not run this Stop). Failing to step or to remove the token is said on stderr, as the provider used to say it.
    param(
        [Parameter(Mandatory)][string] $StateRoot,
        [Parameter()][bool] $Blocked = $false,
        [Parameter()][string[]] $BlockedBy = @(),
        [Parameter()][string[]] $BlockNotEmitted = @()
    )
    $pending = Read-SpecrewTurnCommitPending -StateRoot $StateRoot
    if ($null -eq $pending) { return $null }
    # A BLOCKED STOP KEEPS THE JUDGMENT. The continuation's Stop may be skipped by the provider as a duplicate delivery (an
    # identical reply is the same observable state), and it must still be able to end the turn; only a commit clears it.
    if (-not $Blocked -and [bool]$pending.passed) {
        try { Remove-Item -LiteralPath (Get-SpecrewTurnCommitPendingPath -StateRoot $StateRoot) -Force -ErrorAction Stop } catch { $null = $_ }
    }
    $stepped = $false; $counterAfter = $null; $token = 'kept'
    $tokenWasLive = $false
    try { $tokenWasLive = -not [string]::IsNullOrWhiteSpace((Read-SpecrewTurnToken -StateRoot $StateRoot)) } catch { $tokenWasLive = $false }
    if (-not $tokenWasLive) { $token = 'none' }
    if (-not $Blocked -and [bool]$pending.passed) {
        $next = -1
        try { $next = Step-SpecrewTurnCounter -StateRoot $StateRoot } catch { $next = -1 }
        if ($next -ge 1) { $stepped = $true; $counterAfter = ('turn-{0}' -f $next) }
        else {
            [Console]::Error.WriteLine(("[specrew-turn-end] WARN TURN_COUNTER_UNWRITABLE cannot advance the turn counter at '{0}'; this turn's declaration will keep satisfying later stops until it can be written." -f $StateRoot))
        }
        if ($tokenWasLive) {
            $consumed = $false
            try { $consumed = [bool](Remove-SpecrewTurnToken -StateRoot $StateRoot) } catch { $consumed = $false }
            if ($consumed) { $token = 'consumed' }
            else {
                [Console]::Error.WriteLine(("[specrew-turn-end] WARN TURN_TOKEN_UNCONSUMED cannot remove this turn's token at '{0}'; it will look live to the next declaration in this project and cost a token-less one a refusal." -f (Get-SpecrewTurnTokenPath -StateRoot $StateRoot)))
            }
        }
    }
    $line = [pscustomobject][ordered]@{
        schema_version = '1.0'; recorded_at = [DateTimeOffset]::UtcNow.ToString('o')
        turn_id = [string]$pending.turn_id; declaration_kind = [string]$pending.declaration_kind
        conformance_passed = [bool]$pending.passed; token = $token
        counter_stepped = $stepped; counter_after = $counterAfter
        blocked_by = @($BlockedBy | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        block_not_emitted = @($BlockNotEmitted | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }
    try {
        $historyPath = Join-Path $StateRoot 'turn-history.jsonl'
        [System.IO.File]::AppendAllText($historyPath, (($line | ConvertTo-Json -Compress -Depth 4) + "`n"), [System.Text.UTF8Encoding]::new($false))
    }
    catch { [Console]::Error.WriteLine(("[specrew-turn-end] WARN TURN_HISTORY_UNWRITABLE {0}" -f $_.Exception.Message)) }
    return $line
}

# THE JUDGMENT, LEFT BESIDE THE COUNTER (fix 2 item (c), PRED-BETA4-024). The conformance provider judges
# this session's declaration at Stop and steps the counter afterwards. Everything that runs AFTER it in the
# same Stop - the co-review navigator, by the dispatcher's order - used to know nothing about the session
# and blocked every Stop in the project while the tree was unreviewed: a read-only reviewer session was told
# seventeen times in a row that "its files" had not been reviewed. The judgment is written here once, by
# the one provider that made it, and read by whoever comes after. Nothing infers it a second time.

function Get-SpecrewTurnMaterialVerdictPath {
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $StateRoot)
    return (Join-Path $StateRoot 'turn-material.json')
}

function Write-SpecrewTurnMaterialVerdict {
    # Written BEFORE the counter steps, so `turn_id` names the turn that was judged. Fail-open: a missing
    # judgment reads as "no judgment", and the reader keeps today's behavior.
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string] $StateRoot,
        [Parameter(Mandatory)][string] $TurnId,
        [Parameter()][AllowNull()][AllowEmptyString()][string] $DeclarationKind,
        [Parameter()][bool] $Material = $false
    )
    $temp = $null
    try {
        $kind = if ([string]::IsNullOrWhiteSpace($DeclarationKind)) { 'absent' } else { [string]$DeclarationKind }
        if (-not (Test-Path -LiteralPath $StateRoot -PathType Container)) { New-Item -ItemType Directory -Path $StateRoot -Force | Out-Null }
        $path = Get-SpecrewTurnMaterialVerdictPath -StateRoot $StateRoot
        $temp = $path + '.tmp-' + [guid]::NewGuid().ToString('N')
        $record = [ordered]@{
            schema_version   = '1.0'
            turn_id          = [string]$TurnId
            declaration_kind = $kind
            material         = [bool]$Material
            judged_at        = [DateTimeOffset]::UtcNow.ToString('o')
        }
        [System.IO.File]::WriteAllText($temp, ($record | ConvertTo-Json -Compress), [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temp, $path, $true)
        return $true
    }
    catch { return $false }
    finally {
        if (-not [string]::IsNullOrWhiteSpace($temp) -and (Test-Path -LiteralPath $temp -PathType Leaf)) {
            Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        }
    }
}

function Read-SpecrewTurnMaterialVerdict {
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $StateRoot)
    try {
        $path = Get-SpecrewTurnMaterialVerdictPath -StateRoot $StateRoot
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
        $record = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $record -or [string]$record.schema_version -cne '1.0') { return $null }
        return $record
    }
    catch { return $null }
}

function Test-SpecrewTurnMaterialVerdictQuiet {
    # THE ONE QUESTION A LATER PROVIDER ASKS: did the provider that judged this session's turn find it
    # material? Quiet when the session DECLARED conversational, or declared nothing and was judged not
    # material. Not quiet - today's behavior - for in-flight, boundary, absent-with-material, no judgment
    # at all, or a judgment that cannot be THIS Stop's: its turn id is neither the current one (a block
    # left the counter alone) nor the one just stepped past, or it is older than -MaxAgeSeconds. Freshness
    # is the one clock in this, and it fails toward the advisory, never toward silence.
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $StateRoot,
        [int] $MaxAgeSeconds = 120
    )
    $r = [pscustomobject]@{ Quiet = $false; Reason = 'no-judgment'; DeclarationKind = ''; TurnId = '' }
    $verdict = Read-SpecrewTurnMaterialVerdict -StateRoot $StateRoot
    if ($null -eq $verdict) { return $r }
    $r.DeclarationKind = [string]$verdict.declaration_kind
    $r.TurnId = [string]$verdict.turn_id
    $current = Get-SpecrewTurnId -StateRoot $StateRoot
    $currentNumber = 0; $verdictNumber = 0
    if ($current -match '^turn-(\d+)$') { $currentNumber = [int]$Matches[1] }
    if ([string]$verdict.turn_id -match '^turn-(\d+)$') { $verdictNumber = [int]$Matches[1] }
    if ($verdictNumber -lt 1 -or ($verdictNumber -ne $currentNumber -and $verdictNumber -ne ($currentNumber - 1))) { $r.Reason = 'judgment-not-this-turn'; return $r }
    $age = [double]::MaxValue
    try {
        # THE ONE TIMESTAMP READER (timestamp-read.ps1): a [datetime] ConvertFrom-Json coerced, a string, or a
        # number all become one UTC instant there, never here - census 34533964445 caught a parse of this
        # store's own, which is exactly what the helper's class guard exists to catch.
        $judged = ConvertTo-SpecrewUtcTimestamp -Value $verdict.judged_at
        $age = if ($null -eq $judged) { [double]::MaxValue } else { ([DateTimeOffset]::UtcNow - $judged).TotalSeconds }
    }
    catch { $age = [double]::MaxValue }
    if ($age -lt 0 -or $age -gt $MaxAgeSeconds) { $r.Reason = 'judgment-stale'; return $r }
    $material = $false
    try { $material = [bool]$verdict.material } catch { $material = $true }
    switch ([string]$verdict.declaration_kind) {
        'conversational' { $r.Quiet = $true; $r.Reason = 'session declared conversational'; return $r }
        'absent' {
            if (-not $material) { $r.Quiet = $true; $r.Reason = 'session declared nothing and was judged not material'; return $r }
            $r.Reason = 'absent-with-material'; return $r
        }
        default { $r.Reason = ('declared ' + [string]$verdict.declaration_kind); return $r }
    }
    return $r
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

function Get-SpecrewTurnEndPathsForStateRoot {
    # The same shape Get-SpecrewTurnEndPaths returns, but resolved from a state root the caller already
    # found rather than from a host/session pair it would have to guess. This is the script's route: it
    # located the session by the token the hook issued, so it must write into THAT session's directories,
    # not into ones derived from anything it inferred for itself.
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $StateRoot,
        [AllowNull()][string] $OwnerHash
    )

    $runtimeRoot = Join-Path $ProjectRoot '.specrew/runtime'
    $anchored = -not [string]::IsNullOrWhiteSpace($OwnerHash)
    $turnEndRoot = if ($anchored) { Join-Path (Join-Path $runtimeRoot 'turn-end') $OwnerHash } else { Join-Path $runtimeRoot 'turn-end' }
    $turnId = Get-SpecrewTurnId -StateRoot $StateRoot
    return [pscustomobject]@{
        Anchored        = $anchored
        OwnerHash       = [string]$OwnerHash
        StateRoot       = $StateRoot
        TurnEndRoot     = $turnEndRoot
        TurnId          = $turnId
        RecordPath      = Join-Path $turnEndRoot ($turnId + '.json')
        OrientationPath = Join-Path $StateRoot 'orientation-rendered.json'
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

function Test-SpecrewTurnMessageVisible {
    param([AllowNull()][string]$Message, [AllowNull()][string]$Expected)
    if ([string]::IsNullOrWhiteSpace($Expected)) { return $false }
    # Host accessors normalize whitespace. Content and order, rather than line endings, bind presentation.
    $actualText = ([string]$Message -replace '\s+', ' ').Trim()
    $expectedText = ($Expected -replace '\s+', ' ').Trim()
    return $actualText.Contains($expectedText, [StringComparison]::Ordinal)
}

function Get-SpecrewReviewTargetLinks {
    # Every review link a message carries, as written (text) and as a local path (path; $null when it cannot be
    # resolved). ONE reader for the three places that need it - the packet validator, the meaning lines and the
    # reviewed-artifact memory (co-review round 3, 202): the validator accepted Markdown links to absolute paths while
    # the other two read only file:/// URLs, so such a link could be dropped from the reply unnoticed and a change to
    # its file never lifted suppression. Accepted: a bare file:/// URL (Rule 52's form), and a Markdown link whose
    # target is an absolute path - `C:\...` or `C:/...`, `/C:/...`, or `/...` - optionally in angle brackets.
    [OutputType([object[]])]
    param([AllowNull()][string] $Message)

    $links = [System.Collections.Generic.List[object]]::new()
    if ([string]::IsNullOrWhiteSpace($Message)) { return @() }
    # Co-review round 6 (202, FR-011): a path with parentheses ("app (draft)") was cut at the first ')', so the link
    # named a folder that does not exist, whose "missing" fingerprint never changes - an edit to the real file never
    # lifted suppression. Balanced parentheses belong to the path; an unbalanced ')' still ends it (a sentence's or a
    # Markdown link's closing parenthesis).
    foreach ($match in [regex]::Matches($Message, 'file:///(?:[^\s<>"''`\[\](){}|]|\([^\s<>"''`\[\](){}|]*\))+')) {
        $url = ([string]$match.Value).TrimEnd('.', ',', ';', ':', '!', '?', '*')
        $path = $null
        try { $path = [System.IO.Path]::GetFullPath([System.Uri]::new($url).LocalPath) } catch { $path = $null }
        $links.Add([pscustomobject]@{ text = $url; path = $path })
    }
    # An angle-wrapped destination runs to its '>' whatever it holds; a bare one keeps balanced parentheses.
    foreach ($match in [regex]::Matches($Message, '(?i)\]\(\s*(?:<(?<t>(?:[A-Z]:[/\\]|/[A-Z]:/|/)[^<>\r\n]*)>|(?<t>(?:[A-Z]:[/\\]|/[A-Z]:/|/)(?:[^()<>\r\n]|\([^()<>\r\n]*\))*?))\s*\)')) {
        $target = [string]$match.Groups['t'].Value
        $local = if ($target -match '^/[A-Za-z]:/') { $target.Substring(1) } else { $target }
        $path = $null
        try { $path = [System.IO.Path]::GetFullPath([System.Uri]::UnescapeDataString($local)) } catch { $path = $null }
        $links.Add([pscustomobject]@{ text = $target; path = $path })
    }
    return $links.ToArray()
}

# FEATURE 203 T011 FOLLOW-UP (FR-046; maintainer ruling 2026-11-11, item 1): THE PACKET IS READ FROM THE REPLY. There is
# no draft: declare-turn-end reads none, and nothing is checked against one. A boundary reply's packet is present when
#   - each of the six section headings starts a line (a Markdown heading of any level; words may follow the name);
#   - each section has text before the next of the six, and a section whose only content is stock placeholder text
#     (the lines below) counts as empty;
#   - What Needs Your Review carries at least one file link (Get-SpecrewReviewTargetLinks), and every one resolves to
#     an existing file.
# "recommend" does not block; whether the reply carries it is returned for the Stop's history line.
$script:SpecrewPacketHeadings = @('What I Just Did', 'Why I Stopped', 'What Needs Your Review', 'What Happens Next', 'Discussion Prompts', 'What I Need From You')
# Stock placeholder text: generic lines a packet template or fallback has used, which say nothing about this boundary.
# A line is matched whole, after its list or quote marker is removed. One source; the old separate checks are gone.
$script:SpecrewStockPlaceholderPatterns = @(
    '^The work named above\.?$'
    '^On .+ the next stage starts\.?$'
    '^Your reply decides\.?$'
    '^Anything above you want changed, questioned, or done differently\.?$'
    '^<[^<>!]+>$'
    '^(?:TBD|TODO|\.\.\.|…)$'
)

function Test-SpecrewStockPlaceholderLine {
    [OutputType([bool])]
    param([AllowNull()][string] $Line)
    $core = ([string]$Line).Trim()
    do { $before = $core; $core = $core -replace '^(?:>\s*|[-*+]\s+|\d+[.)]\s+)', '' } while ($core -ne $before)
    $core = $core.Trim()
    foreach ($pattern in $script:SpecrewStockPlaceholderPatterns) { if ($core -match "(?i)$pattern") { return $true } }
    return $false
}

function Test-SpecrewReplyPacket {
    # The six-section packet as the reply carries it. $Reply must keep its lines (the transcript read with -Raw).
    # Returns present, the problems (each a line the Stop shows) and recommendation_present.
    [OutputType([pscustomobject])]
    param([AllowNull()][string] $Reply)
    $problems = [System.Collections.Generic.List[string]]::new()
    $lines = @(([string]$Reply) -split '\r?\n')
    $starts = [ordered]@{}
    foreach ($heading in $script:SpecrewPacketHeadings) {
        $pattern = '(?i)^\s{0,3}#{1,6}\s+(?:\*\*|__)?' + [regex]::Escape($heading) + '\b'
        for ($n = 0; $n -lt $lines.Count; $n++) { if ($lines[$n] -match $pattern) { $starts[$heading] = $n; break } }
    }
    $bodies = @{}
    foreach ($heading in $script:SpecrewPacketHeadings) {
        if (-not $starts.Contains($heading)) { $problems.Add(('missing section: {0}' -f $heading)); continue }
        $from = [int]$starts[$heading] + 1
        $to = $lines.Count
        foreach ($other in $starts.Values) { if ([int]$other -ge $from -and [int]$other -lt $to) { $to = [int]$other } }
        $body = @(if ($to -gt $from) { $lines[$from..($to - 1)] })
        $bodies[$heading] = ($body -join "`n")
        $content = @($body | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_) -and
                ([string]$_).Trim() -notmatch '^<!--.*-->$' -and
                -not (Test-SpecrewStockPlaceholderLine -Line $_)
            })
        if ($content.Count -eq 0) { $problems.Add(('empty section: {0}' -f $heading)) }
    }
    if ($bodies.ContainsKey('What Needs Your Review')) {
        # Every link must resolve (a folder that exists is not missing), and at least one must be an existing file.
        $links = @(Get-SpecrewReviewTargetLinks -Message ([string]$bodies['What Needs Your Review']))
        $fileLinks = 0
        foreach ($link in $links) {
            $isFile = $false; $isFolder = $false
            if (-not [string]::IsNullOrWhiteSpace([string]$link.path)) {
                try { $isFile = [System.IO.File]::Exists([string]$link.path); $isFolder = [System.IO.Directory]::Exists([string]$link.path) } catch { $isFile = $false; $isFolder = $false }
            }
            if ($isFile) { $fileLinks++ }
            elseif (-not $isFolder) { $problems.Add(('review link to a missing file: {0}' -f [string]$link.text)) }
        }
        if ($fileLinks -eq 0 -and @($problems | Where-Object { $_ -like 'review link to a missing file:*' }).Count -eq 0) {
            $problems.Add('What Needs Your Review has no file link (a file:/// URL or a Markdown link to an existing file)')
        }
    }
    return [pscustomobject]@{
        present                = ($problems.Count -eq 0)
        problems               = @($problems)
        recommendation_present = ([string]$Reply -match '(?i)\brecommend(?:ation|ed|s)?\b')
    }
}

function Get-SpecrewVerdictResponseLines {
    # The four response lines with the record's approval phrase filled in, as a boundary reply must carry them.
    [OutputType([string[]])]
    param([Parameter(Mandatory)][string] $ApprovalPhrase)
    $to = ($ApprovalPhrase.Trim() -replace '^(?i:approved for)\s+', '')
    return @($script:SpecrewVerdictOptions | ForEach-Object { ([string]$_.Shown).Replace('<to>', $to) })
}

# FEATURE 203 T011 (FR-046; maintainer ruling 2026-11-10): A BOUNDARY REPLY'S DECISION PARTS, FROM THE RECORD.
# The Stop used to learn the approval line, the options and the marker from the agent's declared draft, so the options
# a reply had to carry were whatever the draft happened to say, and a reworded option blocked. They now come from
# .specrew/runtime/pending-verdict-stop.md and from the four response lines below, each held to its fixed start.
#
# THE FOUR RESPONSE LINES, ONE SOURCE. `Shown` is the line exactly as the gate-stop skill shows it to the agent
# (squad-templates/skills/gate-stop.md, the block under "Type one of these:"); tests/unit/presented-check.tests.ps1 holds
# the two equal. `Pattern` is the start a reply's line must have, with {0} the record's approval phrase: the instructions
# after " - ", what to change and the prompt number are the author's words.
#
# B5F-044 item 2 (maintainer ruling 2026-11-11): the second line says the instructions go on the approval's own line,
# because an approval that continues past its first line is refused (PRED-BETA4-022). Its matching rule is unchanged.
$script:SpecrewVerdictOptions = @(
    [pscustomobject]@{ Shown = 'approved for <to>'; Pattern = '^{0}$' }
    [pscustomobject]@{ Shown = 'approved for <to> - <your instructions, on this same line>'; Pattern = '^{0}\s+-\s+\S' }
    [pscustomobject]@{ Shown = 'changes needed: <what to change>'; Pattern = '^(?i:changes needed)\s*:' }
    [pscustomobject]@{ Shown = 'discuss prompt 1'; Pattern = '^(?i:discuss prompt)\s+\S' }
)

function Get-SpecrewDecisionLineCore {
    # A line without its Markdown wrapper: quote, bullet and number markers, then a leading and trailing code or bold
    # marker. Co-review round 6 (202, FR-015): the wrapper is formatting; the option inside it is the line.
    [OutputType([string])]
    param([AllowNull()][string] $Line)
    $core = ([string]$Line).Trim()
    do { $before = $core; $core = $core -replace '^(?:>\s*|[-*+]\s+|\d+[.)]\s+)', '' } while ($core -ne $before)
    $core = $core -replace '^(?:`+|\*\*|__|\*|_)', ''
    return ($core -replace '(?:`+|\*\*|__)\s*$', '').Trim()
}

function Get-SpecrewVerdictOptionIndex {
    # The indexes (0..3) of the response lines whose start this line has; empty for none. $Line is a core (above).
    [OutputType([int[]])]
    param([AllowNull()][string] $Line, [Parameter(Mandatory)][string] $ApprovalPhrase)
    $phrase = [regex]::Escape($ApprovalPhrase.Trim())
    $hits = [System.Collections.Generic.List[int]]::new()
    for ($i = 0; $i -lt $script:SpecrewVerdictOptions.Count; $i++) {
        if ([regex]::IsMatch([string]$Line, ([string]$script:SpecrewVerdictOptions[$i].Pattern -f $phrase))) { $hits.Add($i) }
    }
    return $hits.ToArray()
}

function Get-SpecrewApprovalTarget {
    # The boundary an "approved for <target>" line names, or '' when the line does not start that way.
    [OutputType([string])]
    param([AllowNull()][string] $Core)
    $m = [regex]::Match([string]$Core, '^(?i:approved for)\s+(?<t>[^\s,.;:!?`*_]+)')
    return $(if ($m.Success) { $m.Groups['t'].Value } else { '' })
}

function Get-SpecrewReplyDecisionParts {
    # What a boundary reply misses of its decision parts, and the approval lines it offers for another boundary.
    # $Reply must keep its lines (the transcript read with -Raw): each part is anchored at the start of a line once the
    # Markdown wrapper is stripped, so the phrase inside a sentence counts in neither direction.
    #   Missing: the response lines (as Shown, <to> filled in) no reply line starts as, then the marker if absent.
    #   Foreign: reply lines that start "approved for " and name a boundary other than the record's.
    [OutputType([pscustomobject])]
    param([AllowNull()][string] $Reply, [Parameter(Mandatory)][string] $ApprovalPhrase, [Parameter(Mandatory)][string] $Marker)
    $target = Get-SpecrewApprovalTarget -Core $ApprovalPhrase.Trim()
    $found = [System.Collections.Generic.HashSet[int]]::new()
    $foreign = [System.Collections.Generic.List[string]]::new()
    foreach ($raw in ([string]$Reply -split "`r?`n")) {
        $core = Get-SpecrewDecisionLineCore -Line $raw
        if ($core.Length -eq 0) { continue }
        foreach ($i in @(Get-SpecrewVerdictOptionIndex -Line $core -ApprovalPhrase $ApprovalPhrase)) { [void]$found.Add($i) }
        $named = Get-SpecrewApprovalTarget -Core $core
        if ($named.Length -gt 0 -and -not [string]::Equals($named, $target, [StringComparison]::OrdinalIgnoreCase)) { $foreign.Add($core) }
    }
    $missing = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $script:SpecrewVerdictOptions.Count; $i++) {
        if (-not $found.Contains($i)) { $missing.Add(([string]$script:SpecrewVerdictOptions[$i].Shown).Replace('approved for <to>', $ApprovalPhrase.Trim())) }
    }
    if (-not (Test-SpecrewTurnMessageVisible -Message $Reply -Expected $Marker)) { $missing.Add($Marker.Trim()) }
    return [pscustomobject]@{ Missing = @($missing); Foreign = @($foreign) }
}

function Read-SpecrewPendingVerdictStopRecord {
    # Parses the record sync-boundary-state.ps1 writes. THE VALUES COME FROM THE FILE, never from a guess about which
    # phase comes next. One reader for declare-turn-end.ps1 and the Stop (203 T011). `problem` says why the record
    # cannot be used, so the Stop can fail closed and name it: missing | unreadable (not UTF-8 text) |
    # no-boundary-line | no-approval-line | no-marker; '' when usable. `present` keeps its old meaning (a boundary line).
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $Path)
    $result = [pscustomobject]@{
        present = $false; problem = ''; boundary = ''; approval_phrase = ''; marker = ''
        working_boundary = ''; last_authorized = ''; feature = ''; coverage = ''
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { $result.problem = 'missing'; return $result }
    $text = $null
    try { $text = [System.Text.UTF8Encoding]::new($false, $true).GetString([System.IO.File]::ReadAllBytes($Path)) }
    catch { $result.problem = 'unreadable'; return $result }
    $lines = @($text.TrimStart([char]0xFEFF) -split "`r?`n")
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
    $result.problem = if (-not $result.present) { 'no-boundary-line' }
    elseif ([string]::IsNullOrWhiteSpace($result.approval_phrase)) { 'no-approval-line' }
    elseif ($result.marker -notmatch '^<!--\s*SPECREW-VERDICT-BOUNDARY:.*-->$') { 'no-marker' }
    else { '' }
    return $result
}

function Get-SpecrewPendingVerdictRecordProblemText {
    # The block line for a record the Stop cannot use. $Detail carries the two crossings for 'other-crossing'.
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $Problem, [AllowNull()][string] $Detail)
    $what = switch ($Problem) {
        'missing' { 'is missing' }
        'unreadable' { 'cannot be read (it is not UTF-8 text)' }
        'no-boundary-line' { "has no 'Boundary to ask for:' line" }
        'no-approval-line' { "has no 'Human approval phrase:' line" }
        'no-marker' { "has no marker line after 'Marker last line exactly:'" }
        'other-crossing' { [string]$Detail }
        default { ('cannot be used ({0})' -f $Problem) }
    }
    return ('Specrew: a boundary verdict is owed, but its record .specrew/runtime/pending-verdict-stop.md {0}, so the approval line and marker the reply must carry are unknown. Re-run the boundary sync for this crossing (sync-boundary-state.ps1); it writes the record again. Then present the packet from that record.' -f $what)
}

# FEATURE 202 T009 (FR-016, SC-005, B4F-107): ONE ADAPTATION SENTENCE ON EVERY HOST. What stood here rendered the
# profile's raw keys and numbers ("software_architecture=10, ...") and reached Codex that way, while Claude read
# the prose sentence the session orientation uses. The prose renderer in user-profile.ps1 is now the only one;
# the host adapter contributes only the correction reference (Get-SpecrewProfileCorrectionReference, beside it).
function Resolve-SpecrewModuleFile {
    # A file of the Specrew module tree, from wherever this script runs: the source tree or an installed module
    # (three levels above extensions/specrew-speckit/scripts), SPECREW_MODULE_PATH, a self-hosting project root,
    # or the newest installed module. $null when none has it.
    param([Parameter(Mandatory)][string] $RelativePath, [AllowNull()][string] $ProjectRoot)
    # Feature 203 T002 (DA-8): with a live-engine pin configured, the pin is the only source; an unusable one
    # resolves nothing. Without this, the self-hosting project root below loads the worktree's unreviewed copy.
    $liveEnginePath = Join-Path $PSScriptRoot 'live-engine-resolution.ps1'
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot) -and (Test-Path -LiteralPath (Join-Path $ProjectRoot '.specrew/runtime/live-engine.json') -PathType Leaf)) {
        if (-not (Test-Path -LiteralPath $liveEnginePath -PathType Leaf)) { return $null }
        if (-not (Get-Command Get-SpecrewLiveEnginePin -ErrorAction SilentlyContinue)) { . $liveEnginePath }
        $pin = Get-SpecrewLiveEnginePin -ProjectRoot $ProjectRoot
        if (-not [bool]$pin.Valid) { return $null }
        $pinned = Join-Path ([string]$pin.Root) $RelativePath
        if (Test-Path -LiteralPath $pinned -PathType Leaf) { return $pinned }
        return $null
    }
    $roots = [System.Collections.Generic.List[string]]::new()
    try { $roots.Add([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))) } catch { $null = $_ }
    if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_MODULE_PATH)) { $roots.Add($env:SPECREW_MODULE_PATH) }
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) { $roots.Add($ProjectRoot) }
    foreach ($candidateRoot in $roots) {
        $candidate = Join-Path $candidateRoot $RelativePath
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    try {
        $module = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.ModuleBase $RelativePath) -PathType Leaf } | Select-Object -First 1
        if ($module) { return (Join-Path $module.ModuleBase $RelativePath) }
    }
    catch { $null = $_ }
    return $null
}

function Get-SpecrewOrientationAdaptationLine {
    # The shared sentence, or '' when no profile is set. Read through user-profile.ps1's own reader, which honours
    # SPECREW_USER_PROFILE_PATH, so every surface reads the one profile the human configured.
    param([AllowNull()][string] $HostKind, [AllowNull()][string] $ProjectRoot)
    try {
        if (-not (Get-Command Get-SpecrewProfileCorrectionReference -ErrorAction SilentlyContinue)) {
            $profileScript = Resolve-SpecrewModuleFile -RelativePath 'scripts/internal/user-profile.ps1' -ProjectRoot $ProjectRoot
            if (-not $profileScript) { return '' }
            . $profileScript
        }
        $line = Get-SpecrewProfileOrientationLine -CorrectionReference (Get-SpecrewProfileCorrectionReference -HostKind $HostKind)
        if ([string]::IsNullOrWhiteSpace([string]$line)) { return '' }
        return [string]$line
    }
    catch { return '' }
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
            # THE THIRD INSTANCE OF ONE ROOT. ConvertFrom-Json coerces the ISO `rendered_at` into a
            # [datetime]; the first version cast that back to a string, which dropped the UTC designator and
            # the fraction, and re-parsed it as LOCAL time. The confirmatory review measured it on this
            # machine: a render 0.5 s old looked ~3 hours old, and the 45-second in-flight cooldown was
            # bypassed. Three instances made it a pattern, and the pattern's fix is one reader: `rendered_ms`
            # first (a number survives JSON), the coerced `rendered_at` as the fallback for an older record,
            # both through ConvertTo-SpecrewUtcTimestamp, which never goes through a string it was not given.
            $previousAt = $null
            if ($PreviousRecord.PSObject.Properties['rendered_ms'] -and $null -ne $PreviousRecord.rendered_ms) { $previousAt = ConvertTo-SpecrewUtcTimestamp -Value $PreviousRecord.rendered_ms }
            if ($null -eq $previousAt -and $PreviousRecord.PSObject.Properties['rendered_at']) { $previousAt = ConvertTo-SpecrewUtcTimestamp -Value $PreviousRecord.rendered_at }
            if ($null -ne $previousAt) {
                $elapsed = ([DateTimeOffset]::new($now, [TimeSpan]::Zero) - [DateTimeOffset]$previousAt).TotalSeconds
                if ($elapsed -ge 0 -and $elapsed -lt $MinimumSecondsBetweenRenders -and $Kind -eq 'in-flight') {
                    return [pscustomobject]@{ render = $false; reason = 'in-flight-line-already-shown-moments-ago' }
                }
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

# PRESENTED-CROSSING MEMORY (Feature 202 T006, FR-011, DA-2). An unchanged pending crossing is owed in full
# ONCE per session, and again only after a context gap. What stood before keyed the obligation on the turn:
# every non-verdict turn of a session with a pending crossing re-armed the packet and ended in a Stop block -
# a side question, a wrong verdict and an orientation request each repainted it (B4F-104).
#
# THE RECORD IS PER SESSION AND PER CROSSING. It lives in the session's own turn-end directory, so another
# session never inherits it - a new session owes its own presentation. It names the crossing it was written
# for, so a different crossing finds nothing to suppress against.
#
# THE CONTEXT GAPS are exactly the agreed four, and HEAD movement is deliberately not one of them: the
# agent's own bookkeeping commits (drift entries, findings) are what repainted the packet in 202's own
# sessions. A gap is:
#   - a changed crossing id (the record names another crossing);
#   - a change to the artifacts under review (the files the presented packet linked);
#   - SessionStart new/resume/compact (the session-start lane clears the record);
#   - the long gap ($script:SpecrewPresentedCrossingLongGapHours).
#
# THE RECOVERY PATH STAYS OPEN (DRIFT-008, B4F-112). A typed reply that carried this crossing's approval
# phrase while it was pending, and after which the crossing is STILL pending, is a capture miss: the human
# answered and the answer did not record. Suppression would leave that human with no packet to answer, so a
# capture miss lifts it whatever the gap state.
$script:SpecrewPresentedCrossingLongGapHours = 8
$script:SpecrewPresentedCrossingFileName = 'presented-crossings.json'
$script:SpecrewSessionStartFileName = 'session-start.json'
$script:SpecrewPresentedArtifactLimit = 32
$script:SpecrewPresentedArtifactMaxBytes = 8MB

# THE SHOWN RECORD (Feature 203 T005, FR-019; maintainer's design decision verdict-pairing-out-of-tail, option 4). A
# capture-only fact: this session's Stop verified that this crossing's packet reached the reply. A verdict whose packet
# has left the transcript tail pairs with the crossing at its own prompt event only if this says the packet was seen.
# The presented record cannot say so: every SessionStart clears it, on purpose, so that a compaction owes a repaint, and a
# packet, a compaction and a verdict would then refuse (US2 scenario 3). So a compaction leaves this record in place;
# startup, resume, clear and an unknown source clear it. Nothing that decides a repaint reads it.
$script:SpecrewShownCrossingFileName = 'shown-crossing.json'

function Get-SpecrewPresentedCrossingPath {
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $TurnEndRoot)
    return (Join-Path $TurnEndRoot $script:SpecrewPresentedCrossingFileName)
}

function Get-SpecrewShownCrossingPath {
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $TurnEndRoot)
    return (Join-Path $TurnEndRoot $script:SpecrewShownCrossingFileName)
}

function Get-SpecrewPresentedCrossingKey {
    # The crossing's identity in the session's records; a legacy unscoped crossing has no id, so its label stands in.
    [OutputType([string])]
    param([Parameter(Mandatory)]$Pending)
    if (-not [string]::IsNullOrWhiteSpace([string]$Pending.CrossingId)) { return [string]$Pending.CrossingId }
    return ('{0}->{1}|{2}|{3}' -f [string]$Pending.PendingFromMarkerBoundary, [string]$Pending.PendingToMarkerBoundary, [string]$Pending.WorkingBoundary, [string]$Pending.LastAuthorizedBoundary)
}

function Write-SpecrewTurnEndJsonFile {
    # The same atomic temp-and-move the turn records use, for the two small session records that are not
    # turn records (Read-SpecrewTurnEndRecord rightly refuses them: they carry no turn kind).
    [OutputType([bool])]
    param([Parameter(Mandatory)][string] $Path, [Parameter(Mandatory)]$Value)

    $temp = $null
    try {
        $directory = Split-Path -Parent $Path
        if ($directory -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        $temp = $Path + '.tmp-' + [guid]::NewGuid().ToString('N')
        [System.IO.File]::WriteAllText($temp, ($Value | ConvertTo-Json -Depth 8 -Compress), [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temp, $Path, $true)
        return $true
    }
    catch { return $false }
    finally {
        if (-not [string]::IsNullOrWhiteSpace($temp) -and (Test-Path -LiteralPath $temp -PathType Leaf)) {
            Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        }
    }
}

function Read-SpecrewTurnEndJsonFile {
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $Path)
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($item.Length -le 0 -or $item.Length -gt 262144) { return $null }
        $value = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $value -or $value -is [System.Array]) { return $null }
        return $value
    }
    catch { return $null }
}

function Clear-SpecrewPresentedCrossing {
    [OutputType([bool])]
    param([Parameter(Mandatory)][string] $TurnEndRoot)
    $path = Get-SpecrewPresentedCrossingPath -TurnEndRoot $TurnEndRoot
    try {
        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }
        return $true
    }
    catch { return $false }
}

function Write-SpecrewSessionStart {
    # Called on every SessionStart this session receives. EVERY SessionStart is a context gap, so the
    # presented record is cleared whatever its kind; the kind (startup, resume, clear, compact) is kept only
    # so the next presented record can say which gap it followed.
    [OutputType([bool])]
    param([Parameter(Mandatory)][string] $TurnEndRoot, [AllowNull()][string] $Source)

    $kind = if ([string]::IsNullOrWhiteSpace($Source)) { 'unknown' } else { $Source.Trim().ToLowerInvariant() }
    $null = Clear-SpecrewPresentedCrossing -TurnEndRoot $TurnEndRoot
    # Feature 203 T005: a compaction owes the repaint, but what the human saw stays seen. Any other start ends that.
    if ($kind -cne 'compact') {
        $shownPath = Get-SpecrewShownCrossingPath -TurnEndRoot $TurnEndRoot
        try { if (Test-Path -LiteralPath $shownPath -PathType Leaf) { Remove-Item -LiteralPath $shownPath -Force -ErrorAction Stop } } catch { $null = $_ }
    }
    return (Write-SpecrewTurnEndJsonFile -Path (Join-Path $TurnEndRoot $script:SpecrewSessionStartFileName) -Value ([pscustomobject][ordered]@{
                kind  = $kind
                at    = [DateTimeOffset]::UtcNow.ToString('o')
                at_ms = Get-SpecrewUtcNowMilliseconds
            }))
}

function Get-SpecrewReviewedArtifactState {
    # The artifacts under review are the files the presented packet LINKED (Rule 52's bare file:/// URLs):
    # the packet is where the human was told what to review. Each linked file is content-hashed. A linked
    # directory is a pointer to browse, not an artifact, so it is recorded but not hashed - hashing it would
    # turn every drift entry written inside an iteration folder into a "changed review target", which is the
    # bookkeeping-commit repaint by another route.
    [OutputType([object[]])]
    param([AllowNull()][string] $Message)

    $state = [System.Collections.Generic.List[object]]::new()
    if ([string]::IsNullOrWhiteSpace($Message)) { return @() }
    # Co-review round 6 (202): exact paths. Merging by case hid the second of two files differing only by case on a
    # case-sensitive filesystem; where case does not matter, both entries fingerprint the same file and change together.
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($link in @(Get-SpecrewReviewTargetLinks -Message $Message)) {
        if ($state.Count -ge $script:SpecrewPresentedArtifactLimit) { break }
        $localPath = [string]$link.path
        if ([string]::IsNullOrWhiteSpace($localPath)) { continue }
        if (-not $seen.Add($localPath)) { continue }
        $state.Add((Get-SpecrewArtifactFingerprint -Path $localPath))
    }
    return $state.ToArray()
}

function Get-SpecrewArtifactFingerprint {
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $Path)

    $entry = [ordered]@{ path = $Path; kind = 'missing'; sha256 = '' }
    try {
        if (Test-Path -LiteralPath $Path -PathType Container) { $entry.kind = 'directory' }
        elseif (Test-Path -LiteralPath $Path -PathType Leaf) {
            $item = Get-Item -LiteralPath $Path -ErrorAction Stop
            if ($item.Length -gt $script:SpecrewPresentedArtifactMaxBytes) {
                $entry.kind = 'file-large'
                $entry.sha256 = ('{0}:{1}' -f $item.Length, $item.LastWriteTimeUtc.Ticks)
            }
            else {
                $entry.kind = 'file'
                $entry.sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
            }
        }
    }
    catch { $entry.kind = 'unreadable' }
    return [pscustomobject]$entry
}

function Write-SpecrewPresentedCrossing {
    # Written only by the Stop that VERIFIED the presentation: a boundary declaration for this crossing whose
    # packet, approval line and marker all reached the visible reply. A declaration alone is not a
    # presentation, so nothing upstream of that check writes here.
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string] $TurnEndRoot,
        [Parameter(Mandatory)][string] $CrossingId,
        [AllowNull()][string] $ApprovalPhrase,
        [AllowNull()][string] $Marker,
        [AllowNull()][string] $Message
    )

    $sessionStart = Read-SpecrewTurnEndJsonFile -Path (Join-Path $TurnEndRoot $script:SpecrewSessionStartFileName)
    $sessionStartKind = if ($null -ne $sessionStart -and $sessionStart.PSObject.Properties['kind']) { [string]$sessionStart.kind } else { 'none-observed' }
    $artifactState = @(Get-SpecrewReviewedArtifactState -Message $Message)
    $presentedAt = [DateTimeOffset]::UtcNow.ToString('o')
    # Feature 203 T005: the same verified presentation, kept for capture (the shown record above).
    $null = Write-SpecrewTurnEndJsonFile -Path (Get-SpecrewShownCrossingPath -TurnEndRoot $TurnEndRoot) -Value ([pscustomobject][ordered]@{
            schema_version          = '1.0'
            crossing_id             = $CrossingId
            reviewed_artifact_state = $artifactState
            shown_at                = $presentedAt
        })
    return (Write-SpecrewTurnEndJsonFile -Path (Get-SpecrewPresentedCrossingPath -TurnEndRoot $TurnEndRoot) -Value ([pscustomobject][ordered]@{
                schema_version          = '1.0'
                crossing_id             = $CrossingId
                approval_phrase         = [string]$ApprovalPhrase
                marker                  = [string]$Marker
                reviewed_artifact_state = $artifactState
                presented_at            = $presentedAt
                presented_ms            = Get-SpecrewUtcNowMilliseconds
                session_start_kind      = $sessionStartKind
                verdict_reply_at        = $null
            }))
}

function Test-SpecrewReplyCarriesApprovalPhrase {
    # Was this typed reply an ATTEMPT to approve the presented crossing? Case- and whitespace-insensitive, on any line:
    # a reply whose phrase sits on its own line after a pasted block is exactly the DRIFT-008 shape this has to see.
    #
    # Co-review round 3 (202): an attempt, not a mention. The phrase anywhere in the reply also matched "What does
    # 'approved for before-implement' mean?" and "I have not approved for before-implement yet", and the crossing,
    # rightly still pending, was then read as a missed capture: a repaint, and a false "your approval did not
    # register". So the phrase must LEAD its line (after an optional "yes," / "I"), as the verdict recognizer
    # anchors it, and the clause it opens must not be a question; instructions after a delimiter are still fine.
    [OutputType([bool])]
    param([AllowNull()][string] $Reply, [AllowNull()][string] $ApprovalPhrase)
    if ([string]::IsNullOrWhiteSpace($Reply) -or [string]::IsNullOrWhiteSpace($ApprovalPhrase)) { return $false }
    $words = @((($ApprovalPhrase -replace '\s+', ' ').Trim()) -split ' ' | ForEach-Object { [regex]::Escape($_) })
    $pattern = '(?i)^\s*(?:(?:yes|confirmed)\s*[,;:\-–—]\s*)?(?:(?:i|we)\s+)?' + ($words -join '\s+') + '(?![\w-])'
    # Co-review round 5 (202, FR-011): a quoted example is a mention too. A side question with the phrase inside a fenced
    # code block ("Explain this example:" then the block) or an indented one was read as an attempt, and the next Stop
    # said the approval did not register and repainted. Lines inside a CLOSED fence, and lines of an indented code block
    # (4+ spaces or a tab, after a blank line), are skipped. An unclosed fence hides nothing, and a line typed after a
    # closed block still counts - the DRIFT-008 / B4F-125 shape.
    $lines = @($Reply -split "`r?`n")
    $quoted = New-Object bool[] $lines.Count
    $open = -1; $marker = ''
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $fence = [regex]::Match($lines[$i], '^\s{0,3}(```+|~~~+)')
        if (-not $fence.Success) { continue }
        if ($open -lt 0) { $open = $i; $marker = $fence.Groups[1].Value.Substring(0, 3) }
        elseif ($fence.Groups[1].Value.StartsWith($marker) -and $lines[$i].Trim() -match '^(```+|~~~+)$') {
            for ($j = $open; $j -le $i; $j++) { $quoted[$j] = $true }
            $open = -1; $marker = ''
        }
    }
    $inIndented = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ([string]::IsNullOrWhiteSpace($lines[$i])) { $inIndented = $false; continue }
        $indented = $lines[$i] -match '^(?: {4}|\t)'
        $afterBlank = $i -eq 0 -or [string]::IsNullOrWhiteSpace($lines[$i - 1])
        if ($indented -and ($afterBlank -or $inIndented)) { $inIndented = $true; $quoted[$i] = $true } else { $inIndented = $false }
    }
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($quoted[$i]) { continue }
        $line = $lines[$i]
        $match = [regex]::Match($line, $pattern)
        if (-not $match.Success) { continue }
        $clause = ([regex]::Split($line.Substring($match.Length), '[,.;:]|\s[-–—]\s', 2))[0]
        if (-not $clause.Contains('?')) { return $true }
    }
    return $false
}

function Register-SpecrewPresentedCrossingReply {
    # Prompt time, typed replies only. Records THAT a reply carried the presented crossing's approval phrase.
    # Whether it was a miss is decided at Stop, where the crossing is either still pending (the capture did
    # not record it) or gone (it did).
    [OutputType([bool])]
    param([Parameter(Mandatory)][string] $TurnEndRoot, [AllowNull()][string] $Reply)

    $path = Get-SpecrewPresentedCrossingPath -TurnEndRoot $TurnEndRoot
    $record = Read-SpecrewTurnEndJsonFile -Path $path
    if ($null -eq $record -or -not $record.PSObject.Properties['approval_phrase']) { return $false }
    if (-not (Test-SpecrewReplyCarriesApprovalPhrase -Reply $Reply -ApprovalPhrase ([string]$record.approval_phrase))) { return $false }
    $record.verdict_reply_at = [DateTimeOffset]::UtcNow.ToString('o')
    return (Write-SpecrewTurnEndJsonFile -Path $path -Value $record)
}

function Get-SpecrewPresentedCrossingDecision {
    # Does this session's earlier presentation still cover the pending crossing? suppress is $true only for a
    # crossing that was presented, is unchanged and had no capture miss. Otherwise the reason names the gap,
    # so the journal says WHY the packet was owed again.
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $TurnEndRoot,
        [Parameter(Mandatory)][string] $CrossingId,
        [Nullable[DateTimeOffset]] $Now
    )

    $nowValue = if ($null -ne $Now) { [DateTimeOffset]$Now } else { [DateTimeOffset]::UtcNow }
    $record = Read-SpecrewTurnEndJsonFile -Path (Get-SpecrewPresentedCrossingPath -TurnEndRoot $TurnEndRoot)
    if ($null -eq $record -or -not $record.PSObject.Properties['crossing_id']) { return [pscustomobject]@{ suppress = $false; reason = 'not-presented' } }
    if ([string]$record.crossing_id -cne $CrossingId) { return [pscustomobject]@{ suppress = $false; reason = 'crossing-changed' } }
    if ($record.PSObject.Properties['verdict_reply_at'] -and -not [string]::IsNullOrWhiteSpace([string]$record.verdict_reply_at)) {
        return [pscustomobject]@{ suppress = $false; reason = 'capture-miss' }
    }
    $presentedAt = if ($record.PSObject.Properties['presented_ms']) { ConvertTo-SpecrewUtcTimestamp -Value $record.presented_ms } else { $null }
    if ($null -eq $presentedAt -and $record.PSObject.Properties['presented_at']) { $presentedAt = ConvertTo-SpecrewUtcTimestamp -Value $record.presented_at }
    if ($null -eq $presentedAt) { return [pscustomobject]@{ suppress = $false; reason = 'record-unreadable' } }
    if (($nowValue - [DateTimeOffset]$presentedAt).TotalHours -ge $script:SpecrewPresentedCrossingLongGapHours) {
        return [pscustomobject]@{ suppress = $false; reason = 'long-gap' }
    }
    if (Test-SpecrewReviewedArtifactsChanged -State $record.reviewed_artifact_state) {
        return [pscustomobject]@{ suppress = $false; reason = 'reviewed-artifacts-changed' }
    }
    return [pscustomobject]@{ suppress = $true; reason = 'presented-unchanged' }
}

function Test-SpecrewReviewedArtifactsChanged {
    # Has any file the presented packet linked changed since? A linked directory is a pointer, not an artifact.
    [OutputType([bool])]
    param([AllowNull()]$State)
    foreach ($entry in @($State)) {
        if ($null -eq $entry -or -not $entry.PSObject.Properties['path']) { continue }
        if ([string]$entry.kind -eq 'directory') { continue }
        $current = Get-SpecrewArtifactFingerprint -Path ([string]$entry.path)
        if ([string]$current.kind -cne [string]$entry.kind -or [string]$current.sha256 -cne [string]$entry.sha256) { return $true }
    }
    return $false
}

function Get-SpecrewShownCrossingDecision {
    # Feature 203 T005 (FR-019): did this session see this crossing's packet, and is what it linked unchanged? For
    # capture only: the 8-hour gap decides a repaint, and is no reason to refuse a verdict typed after a long break.
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $TurnEndRoot, [Parameter(Mandatory)][string] $CrossingId)

    $record = Read-SpecrewTurnEndJsonFile -Path (Get-SpecrewShownCrossingPath -TurnEndRoot $TurnEndRoot)
    if ($null -eq $record -or -not $record.PSObject.Properties['crossing_id']) { return [pscustomobject]@{ shown = $false; reason = 'packet-not-shown' } }
    if ([string]$record.crossing_id -cne $CrossingId) { return [pscustomobject]@{ shown = $false; reason = 'packet-not-shown' } }
    $state = if ($record.PSObject.Properties['reviewed_artifact_state']) { $record.reviewed_artifact_state } else { $null }
    if (Test-SpecrewReviewedArtifactsChanged -State $state) { return [pscustomobject]@{ shown = $false; reason = 'reviewed-artifacts-changed' } }
    return [pscustomobject]@{ shown = $true; reason = 'shown' }
}

