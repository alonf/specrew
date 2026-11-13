# Feature 203 T012 (FR-024, FR-041): THE AUTHORITY AUDIT. Every record that grants or spends the human's authority joins a
# typed human turn: it names a turn identity, and the turn ledger (.specrew/authority/exhausted-turns.jsonl) holds that turn
# as one the human typed (turn_origin typed-user - the prompt hook's reservation, or the turn end's recovery of a message
# whose transcript origin it confirmed). The audit fails on any record that names no turn, names a turn the ledger does not
# hold, or names a turn whose only rows carry no typed origin (a backstop-minted record).
#
# What it reads, and how each kind joins:
#   - boundary verdicts (.specrew/start-context.json verdict_history), and the captures under .specrew/review/ (stop
#     answers, pause decisions, the allowance reset, the partial sign-off, the coverage deferral): their own turn_identity.
#   - the review authority store's human facts (budget grants, launch grants, reservations, resets, allowed reviewers,
#     finding dispositions, human dispositions, pause decisions): their own turn_identity. A reservation also cites the
#     window it is spent in: budget_grant_id always, and reset_id when a reset opened it, each existing in the campaign and
#     joining a typed turn itself.
#   - run facts (run states, result, recovery, spend, release, claim, finalization): through their run's reservation, which
#     must pass the audit. A human pause decision authorizes the stop it answers, never a spend (maintainer, 2026-11-12):
#     a run with run facts, a pause decision and no reservation fails.
#   - stops (pending pause facts) are not grants: a stop takes authority away and its answer is what the human types, so a
#     stop is not joined; its answer is.
# Read only: the audit writes nothing.
#
# Iteration review round A finding 3 (FR-024, B5F-066): the ledger's typed-user row is the prompt hook's reservation, written
# before the host records who sent the message, so it is not proof on its own. For each joined turn the audit reads the sender
# from the transcript record the row points at (Resolve-SpecrewAuthorizationSender -NoRecord, storing nothing): a turn not sent
# by the human, or one that cannot be found, fails (turn-sender-<sender>); a capture or verdict that does not say what its turn
# said fails (record-not-what-turn-said); a turn on a host with no transcript to read is passed and listed under 'unverified',
# apart from the confirmed ones. Without the check loaded, every joined record fails (sender-check-unavailable).

function Invoke-SpecrewAuthorityAudit {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $root = [IO.Path]::GetFullPath($ProjectRoot)
    $failures = [Collections.Generic.List[object]]::new()
    $state = [pscustomobject]@{ checked = 0 }
    $typedTurns = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $knownTurns = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $turnHosts = @{}
    $senders = @{}
    $unverified = [Collections.Generic.List[object]]::new()
    $canResolve = [bool](Get-Command -Name 'Resolve-SpecrewAuthorizationSender' -ErrorAction SilentlyContinue) -and [bool](Get-Command -Name 'Test-SpecrewAuthorizationRecordMatchesTurn' -ErrorAction SilentlyContinue)

    $ledger = Join-Path $root '.specrew/authority/exhausted-turns.jsonl'
    if (Test-Path -LiteralPath $ledger -PathType Leaf) {
        foreach ($line in [IO.File]::ReadAllLines($ledger)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $row = $null
            try { $row = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
            if ($null -eq $row -or -not $row.PSObject.Properties['turn_id']) { continue }
            $turnId = [string]$row.turn_id
            if ([string]::IsNullOrWhiteSpace($turnId)) { continue }
            $null = $knownTurns.Add($turnId)
            if ($row.PSObject.Properties['host_kind'] -and -not [string]::IsNullOrWhiteSpace([string]$row.host_kind) -and -not $turnHosts.ContainsKey($turnId)) { $turnHosts[$turnId] = ([string]$row.host_kind).Trim().ToLowerInvariant() }
            if ($row.PSObject.Properties['turn_origin'] -and [string]$row.turn_origin -ceq 'typed-user') { $null = $typedTurns.Add($turnId) }
        }
    }

    $property = {
        param($Object, [string]$Name)
        if ($null -eq $Object) { return '' }
        $p = $Object.PSObject.Properties[$Name]
        if ($null -eq $p -or $null -eq $p.Value) { return '' }
        return [string]$p.Value
    }
    $fail = {
        param([string]$Kind, [string]$Id, [string]$Path, [string]$Reason, [string]$Turn)
        $failures.Add([pscustomobject][ordered]@{ kind = $Kind; id = $Id; path = $Path; reason = $Reason; turn_identity = $Turn }) | Out-Null
    }
    # One record that must name its own typed turn. Returns $true when it joins one.
    # $Record, when given, is a capture or verdict that carries the turn's text: it must say what the turn said.
    $joinTurn = {
        param([string]$Kind, [string]$Id, [string]$Path, [string]$Turn, $Record)
        $state.checked++
        $reason = if ([string]::IsNullOrWhiteSpace($Turn)) { 'no-turn-identity' }
        elseif ($typedTurns.Contains($Turn)) { '' }
        elseif ($knownTurns.Contains($Turn)) { 'turn-not-typed' }
        else { 'turn-not-in-ledger' }
        if ($reason -eq '') {
            if (-not $canResolve) { $reason = 'sender-check-unavailable' }
            else {
                if (-not $senders.ContainsKey($Turn)) {
                    $turnHost = if ($turnHosts.ContainsKey($Turn)) { [string]$turnHosts[$Turn] } else { 'claude' }
                    $senders[$Turn] = Resolve-SpecrewAuthorizationSender -ProjectRoot $root -TurnIdentity $Turn -Purpose 'authority audit' -HostKind $turnHost -NoRecord
                }
                $sender = $senders[$Turn]
                if (-not [bool]$sender.accepted) { $reason = 'turn-sender-' + [string]$sender.sender }
                elseif ($null -ne $Record -and $null -ne $sender.turn -and -not (Test-SpecrewAuthorizationRecordMatchesTurn -Record $Record -Turn $sender.turn)) { $reason = 'record-not-what-turn-said' }
                elseif ([string]$sender.sender -ceq 'unverified') {
                    $unverified.Add([pscustomobject][ordered]@{ kind = $Kind; id = $Id; path = $Path; turn_identity = $Turn; host_kind = [string]$sender.host_kind; reason = [string]$sender.reason }) | Out-Null
                }
            }
        }
        if ($reason -ne '') { & $fail $Kind $Id $Path $reason $Turn; return $false }
        return $true
    }
    $readJson = {
        param([string]$Path)
        try { return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 32 -ErrorAction Stop) } catch { return $null }
    }
    $jsonFiles = {
        param([string]$Directory, [switch]$Recurse)
        if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { return @() }
        return @(Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File -Recurse:$Recurse | Sort-Object FullName)
    }

    # Boundary verdicts.
    $contextPath = Join-Path $root '.specrew/start-context.json'
    if (Test-Path -LiteralPath $contextPath -PathType Leaf) {
        $context = & $readJson $contextPath
        $enforcement = if ($null -ne $context -and $context.PSObject.Properties['boundary_enforcement']) { $context.boundary_enforcement } else { $null }
        $history = if ($null -ne $enforcement -and $enforcement.PSObject.Properties['verdict_history']) { @($enforcement.verdict_history) } else { @() }
        foreach ($entry in $history) {
            if ($null -eq $entry) { continue }
            $null = & $joinTurn 'boundary-verdict' (& $property $entry 'authorization_id') $contextPath (& $property $entry 'turn_identity') $entry
        }
    }

    # Captures of the human's typed lines.
    $review = Join-Path $root '.specrew/review'
    foreach ($file in (& $jsonFiles (Join-Path $review 'stop-answer') -Recurse)) {
        $capture = & $readJson $file.FullName
        $null = & $joinTurn 'stop-answer' $file.BaseName $file.FullName (& $property $capture 'turn_identity') $capture
    }
    foreach ($file in (& $jsonFiles (Join-Path $review 'pause-decision'))) {
        $capture = & $readJson $file.FullName
        $null = & $joinTurn 'pause-decision-capture' $file.BaseName $file.FullName (& $property $capture 'turn_identity') $capture
    }
    $allowance = Join-Path $review 'allowance-reset/pending-allowance-reset.json'
    if (Test-Path -LiteralPath $allowance -PathType Leaf) {
        $capture = & $readJson $allowance
        $null = & $joinTurn 'allowance-reset-capture' 'pending-allowance-reset' $allowance (& $property $capture 'turn_identity') $capture
    }
    foreach ($file in (& $jsonFiles (Join-Path $review 'signoff-gate/override-authorizations'))) {
        $capture = & $readJson $file.FullName
        $null = & $joinTurn 'partial-signoff' $file.BaseName $file.FullName (& $property $capture 'turn_identity') $capture
    }
    $coverage = Join-Path $review 'coverage-disposition/coverage-deferral.json'
    if (Test-Path -LiteralPath $coverage -PathType Leaf) {
        $capture = & $readJson $coverage
        $null = & $joinTurn 'coverage-deferral' 'coverage-deferral' $coverage (& $property $capture 'turn_identity') $capture
    }

    # The review authority store, one campaign at a time.
    $campaigns = Join-Path $review 'authority/campaigns'
    if (Test-Path -LiteralPath $campaigns -PathType Container) {
        foreach ($campaign in @(Get-ChildItem -LiteralPath $campaigns -Directory | Sort-Object Name)) {
            $dir = $campaign.FullName
            $authorizedRuns = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            $simple = [ordered]@{
                'budget-grants'        = @('budget-grant', 'grant_id')
                'grants'               = @('launch-grant', 'grant_id')
                'budget-resets'        = @('budget-reset', 'reset_id')
                'allowed-reviewers'    = @('allowed-reviewer', 'host')
                'finding-dispositions' = @('finding-disposition', 'finding_key')
            }
            # Whether each budget grant and reset in this campaign joined a typed turn, for the reservations that cite them.
            $windowJoined = @{ 'budget-grant' = @{}; 'budget-reset' = @{} }
            foreach ($folder in $simple.Keys) {
                $kind = $simple[$folder][0]; $idName = $simple[$folder][1]
                foreach ($file in (& $jsonFiles (Join-Path $dir $folder))) {
                    $fact = & $readJson $file.FullName
                    $factId = & $property $fact $idName
                    $joinedFact = & $joinTurn $kind $factId $file.FullName (& $property $fact 'turn_identity')
                    if ($windowJoined.ContainsKey($kind) -and -not [string]::IsNullOrWhiteSpace($factId)) { $windowJoined[$kind][$factId] = [bool]$joinedFact }
                }
            }
            foreach ($file in (& $jsonFiles (Join-Path $dir 'reservations') -Recurse)) {
                $fact = & $readJson $file.FullName
                $id = & $property $fact 'reservation_id'
                $joined = & $joinTurn 'reservation' $id $file.FullName (& $property $fact 'turn_identity')
                # FR-024 (maintainer, 2026-11-12): a reservation cites the window it is spent in, not only the (possibly older)
                # slot it holds. It names the budget grant whether or not a reset opened the window; the grant, and the reset
                # when one is named, exist in this campaign and themselves join a typed turn.
                if ($joined) {
                    $citedGrant = & $property $fact 'budget_grant_id'
                    $citedReset = & $property $fact 'reset_id'
                    $windowReason = if ([string]::IsNullOrWhiteSpace($citedGrant)) { 'no-window-citation' }
                    elseif (-not $windowJoined['budget-grant'].ContainsKey($citedGrant)) { 'cited-budget-grant-missing' }
                    elseif (-not $windowJoined['budget-grant'][$citedGrant]) { 'cited-budget-grant-not-joined' }
                    elseif ([string]::IsNullOrWhiteSpace($citedReset)) { '' }
                    elseif (-not $windowJoined['budget-reset'].ContainsKey($citedReset)) { 'cited-reset-missing' }
                    elseif (-not $windowJoined['budget-reset'][$citedReset]) { 'cited-reset-not-joined' }
                    else { '' }
                    if ($windowReason -ne '') {
                        & $fail 'reservation' $id $file.FullName $windowReason (& $property $fact 'turn_identity')
                        $joined = $false
                    }
                }
                if ($joined) { $null = $authorizedRuns.Add((& $property $fact 'run_id')) }
            }
            foreach ($file in (& $jsonFiles (Join-Path $dir 'dispositions') -Recurse)) {
                $fact = & $readJson $file.FullName
                $null = & $joinTurn 'human-disposition' (& $property $fact 'disposition_id') $file.FullName (& $property $fact 'turn_identity')
            }
            $runsDir = Join-Path $dir 'runs'
            $runFacts = [Collections.Generic.List[object]]::new()
            if (Test-Path -LiteralPath $runsDir -PathType Container) {
                foreach ($runDir in @(Get-ChildItem -LiteralPath $runsDir -Directory | Sort-Object Name)) {
                    foreach ($file in @(Get-ChildItem -LiteralPath $runDir.FullName -Filter '*.json' -File | Sort-Object Name)) {
                        if ($file.Name -ceq 'pause-decision.json') {
                            # The decision joins its own typed turn and authorizes the stop it answers; it adds nothing to
                            # the runs whose facts are authorized (the halt between stops writes no run facts).
                            $null = & $joinTurn 'pause-decision' $runDir.Name $file.FullName (& $property (& $readJson $file.FullName) 'turn_identity')
                        }
                        elseif ($file.Name -ceq 'pending-pause.json') { continue }
                        else { $runFacts.Add([pscustomobject]@{ run_id = $runDir.Name; path = $file.FullName }) | Out-Null }
                    }
                }
            }
            foreach ($folder in @('spend', 'releases')) {
                foreach ($file in (& $jsonFiles (Join-Path $dir $folder))) { $runFacts.Add([pscustomobject]@{ run_id = (& $property (& $readJson $file.FullName) 'run_id'); path = $file.FullName }) | Out-Null }
            }
            foreach ($file in (& $jsonFiles (Join-Path $dir 'claims') -Recurse)) { $runFacts.Add([pscustomobject]@{ run_id = (& $property (& $readJson $file.FullName) 'run_id'); path = $file.FullName }) | Out-Null }
            $finalization = Join-Path $dir 'finalization.json'
            if (Test-Path -LiteralPath $finalization -PathType Leaf) { $runFacts.Add([pscustomobject]@{ run_id = (& $property (& $readJson $finalization) 'run_id'); path = $finalization }) | Out-Null }
            foreach ($runFact in $runFacts) {
                $state.checked++
                if (-not $authorizedRuns.Contains([string]$runFact.run_id)) { & $fail 'run-fact' ([string]$runFact.run_id) ([string]$runFact.path) 'run-without-authorized-reservation' '' }
            }
        }
    }

    return [pscustomobject][ordered]@{
        passed          = ($failures.Count -eq 0)
        records_checked = [int]$state.checked
        failures        = @($failures)
        unverified      = @($unverified)
    }
}
