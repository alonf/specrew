# T019 step 6 piece 2 — the atomically-acquired per-lineage review LEASE (maintainer design 2026-07-13).
#
# One active lease per lineage. The GENERATION is the IMMUTABLE reviewed-tree digest (never a timestamp, never
# "latest fire wins"). The atomic winner is the exclusive file creator (FileMode::CreateNew); a failed acquire for
# the same lineage SUPPRESSES the spawn (the caller then consumes neither provider spend nor a review round).
# Ownership + crash recovery are explicit: the lease persists lineage_id, generation, run_id, a random owner token,
# the owner PID + process-START identity (PID-reuse protection), and the acquisition time. Release is OWNER-ONLY
# (token + generation must match). A stale lease is RECLAIMED only when its owner is PROVABLY DEAD (or by explicit
# remediation) - NEVER merely because wall-clock time elapsed. A newer tree arriving while the current tree is
# under review is QUEUED as pending_tree (no second reviewer); when the owner completes, its now-stale result is
# superseded and the pending newest tree becomes eligible for the next generation.
#
# Verdict authority is NOT lease ownership alone: Test-ContinuousCoReviewLeasePromotionAuthority requires ALL of
# owner-match, generation==result-digest, the T019 identity joins, and not-superseded-by-current.

# StrictMode-safe property read (self-contained so the module loads independently).
function Get-ContinuousCoReviewLeaseProp {
    param([Parameter(Mandatory)][AllowNull()]$Object, [Parameter(Mandatory)][string]$Name)
    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) { if ($Object.Contains($Name)) { return $Object[$Name] } else { return $null } }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -ne $p) { return $p.Value }
    return $null
}

function Get-ContinuousCoReviewLineageLeaseDir {
    param([Parameter(Mandatory)][string]$RepoRoot)
    Join-Path $RepoRoot '.specrew/runtime/co-review-lineage-lease'
}

# HASH the lineage id for the filename so a hostile/odd lineage id cannot traverse paths or produce an invalid
# filename (the raw lineage id is preserved INSIDE the lease record, only the filename is the hash).
function Get-ContinuousCoReviewLineageLeasePath {
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][AllowEmptyString()][string]$LineageId)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$LineageId)
    $hash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::HashData($bytes)).Replace('-', '').ToLowerInvariant()
    Join-Path (Get-ContinuousCoReviewLineageLeaseDir -RepoRoot $RepoRoot) ($hash + '.json')
}

# Process-START identity (PID + start-time ticks) - the PID-reuse guard. '' when the process is gone.
function Get-ContinuousCoReviewProcessStartIdentity {
    param([Parameter(Mandatory)][int]$ProcessId)
    try {
        $p = Get-Process -Id $ProcessId -ErrorAction Stop
        return ('{0}:{1}' -f $ProcessId, $p.StartTime.ToUniversalTime().Ticks)
    }
    catch { return '' }
}

# The recorded owner is ALIVE iff a process with that PID exists AND its start-identity matches (so a REUSED PID
# now belonging to a DIFFERENT process reads as NOT the owner). A blank/zero pid or blank start id -> not alive.
function Test-ContinuousCoReviewLeaseOwnerAlive {
    param([AllowNull()]$OwnerPid, [AllowEmptyString()][string]$ProcessStartId)
    if ($null -eq $OwnerPid) { return $false }
    $pidInt = 0
    if (-not [int]::TryParse([string]$OwnerPid, [ref]$pidInt)) { return $false }
    if ($pidInt -le 0) { return $false }
    if ([string]::IsNullOrWhiteSpace($ProcessStartId)) { return $false }
    $current = Get-ContinuousCoReviewProcessStartIdentity -ProcessId $pidInt
    if ([string]::IsNullOrWhiteSpace($current)) { return $false }   # no such process -> dead
    return ($current -eq [string]$ProcessStartId)                   # same PID AND same start -> alive; else dead / PID-reused
}

function Get-ContinuousCoReviewLineageLease {
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][AllowEmptyString()][string]$LineageId)
    $path = Get-ContinuousCoReviewLineageLeasePath -RepoRoot $RepoRoot -LineageId $LineageId
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try { return (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}

# Queue a NEWER reviewed tree as the lease's pending_tree (advisory hint for the next acquire). Guarded by the
# expected generation so we never clobber a lease that has already advanced. Benign read-modify-write.
function Set-ContinuousCoReviewLineageLeasePendingTree {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$LineageId,
        [Parameter(Mandatory)][AllowEmptyString()][string]$PendingTree,
        [Parameter(Mandatory)][AllowEmptyString()][string]$ExpectGeneration
    )
    $path = Get-ContinuousCoReviewLineageLeasePath -RepoRoot $RepoRoot -LineageId $LineageId
    $lease = Get-ContinuousCoReviewLineageLease -RepoRoot $RepoRoot -LineageId $LineageId
    if ($null -eq $lease) { return $false }
    if ([string](Get-ContinuousCoReviewLeaseProp -Object $lease -Name 'generation') -cne $ExpectGeneration) { return $false }
    try {
        $lease | Add-Member -NotePropertyName 'pending_tree' -NotePropertyValue ([string]$PendingTree) -Force
        ($lease | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $path -Encoding UTF8
        return $true
    }
    catch { return $false }
}

# ATOMIC acquire. Returns @{ acquired; lease?; reason; existing?; reclaimed }. reasons:
#  acquired | duplicate-same-generation | queued-newer-tree | acquire-contended
function Request-ContinuousCoReviewLineageLease {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$LineageId,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Generation,   # = the reviewed-tree digest (immutable epoch)
        [Parameter(Mandatory)][AllowEmptyString()][string]$RunId,
        [datetime]$Now = [datetime]::UtcNow,
        [int]$AcquiringPid = $PID
    )
    $dir = Get-ContinuousCoReviewLineageLeaseDir -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $null = New-Item -ItemType Directory -Path $dir -Force }
    $path = Get-ContinuousCoReviewLineageLeasePath -RepoRoot $RepoRoot -LineageId $LineageId

    for ($attempt = 0; $attempt -lt 6; $attempt++) {
        # 1. ATOMIC WINNER: exclusively CREATE the lease file (throws if it already exists).
        $ownerToken = [guid]::NewGuid().ToString('N')
        $record = [ordered]@{
            schema_version   = '1.0'
            lineage_id       = $LineageId
            generation       = $Generation
            run_id           = $RunId
            owner_token      = $ownerToken
            pid              = $AcquiringPid
            process_start_id = (Get-ContinuousCoReviewProcessStartIdentity -ProcessId $AcquiringPid)
            acquired_at      = $Now.ToUniversalTime().ToString('o')
            pending_tree     = $null
        }
        $json = ([pscustomobject]$record | ConvertTo-Json -Depth 6)
        $fs = $null
        $created = $false
        try {
            $fs = [System.IO.File]::Open($path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
            $fs.Write($bytes, 0, $bytes.Length)
            $fs.Flush()
            $created = $true
        }
        catch [System.IO.IOException] { $created = $false }   # the file exists -> inspect the incumbent
        finally { if ($null -ne $fs) { $fs.Dispose() } }
        if ($created) {
            return [pscustomobject]@{ acquired = $true; lease = ([pscustomobject]$record); reason = 'acquired'; existing = $null; reclaimed = ($attempt -gt 0) }
        }

        # 2. A lease exists. Inspect it.
        $existing = Get-ContinuousCoReviewLineageLease -RepoRoot $RepoRoot -LineageId $LineageId
        if ($null -eq $existing) { continue }   # vanished (a concurrent release) -> retry the atomic create

        $existingGen = [string](Get-ContinuousCoReviewLeaseProp -Object $existing -Name 'generation')
        if ($existingGen -ceq $Generation) {
            # SAME generation (same reviewed-tree epoch) = a duplicate fire. Do NOT acquire, do NOT spawn.
            return [pscustomobject]@{ acquired = $false; lease = $null; reason = 'duplicate-same-generation'; existing = $existing; reclaimed = $false }
        }

        # DIFFERENT generation: is the incumbent owner still ALIVE?
        $ownerPid = Get-ContinuousCoReviewLeaseProp -Object $existing -Name 'pid'
        $ownerStart = [string](Get-ContinuousCoReviewLeaseProp -Object $existing -Name 'process_start_id')
        if (Test-ContinuousCoReviewLeaseOwnerAlive -OwnerPid $ownerPid -ProcessStartId $ownerStart) {
            # LIVE owner reviewing an OLDER tree: NEVER steal, NEVER spawn a second reviewer. QUEUE our newer tree.
            $null = Set-ContinuousCoReviewLineageLeasePendingTree -RepoRoot $RepoRoot -LineageId $LineageId -PendingTree $Generation -ExpectGeneration $existingGen
            return [pscustomobject]@{ acquired = $false; lease = $null; reason = 'queued-newer-tree'; existing = $existing; reclaimed = $false }
        }

        # DEAD owner (crash) = RECLAIM. Delete the stale lease (only if it is STILL the dead one we inspected, to
        # avoid racing a concurrent reclaimer), then loop to retry the atomic create.
        try {
            $reRead = Get-ContinuousCoReviewLineageLease -RepoRoot $RepoRoot -LineageId $LineageId
            $deadToken = [string](Get-ContinuousCoReviewLeaseProp -Object $existing -Name 'owner_token')
            $curToken = [string](Get-ContinuousCoReviewLeaseProp -Object $reRead -Name 'owner_token')
            if ($curToken -eq $deadToken) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }
        }
        catch { $null = $_ }
    }
    return [pscustomobject]@{ acquired = $false; lease = $null; reason = 'acquire-contended'; existing = (Get-ContinuousCoReviewLineageLease -RepoRoot $RepoRoot -LineageId $LineageId); reclaimed = $false }
}

# OWNER-ONLY release: release ONLY when the owner token AND generation match the on-disk lease. Returns the queued
# pending_tree (if any) so the caller can make it eligible for the next generation.
function Complete-ContinuousCoReviewLineageLease {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$LineageId,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Generation,
        [Parameter(Mandatory)][AllowEmptyString()][string]$OwnerToken
    )
    $existing = Get-ContinuousCoReviewLineageLease -RepoRoot $RepoRoot -LineageId $LineageId
    if ($null -eq $existing) { return [pscustomobject]@{ released = $false; reason = 'no-lease'; pending_tree = $null } }
    $eGen = [string](Get-ContinuousCoReviewLeaseProp -Object $existing -Name 'generation')
    $eTok = [string](Get-ContinuousCoReviewLeaseProp -Object $existing -Name 'owner_token')
    if (($eTok -ceq $OwnerToken) -and ($eGen -ceq $Generation) -and (-not [string]::IsNullOrWhiteSpace($OwnerToken))) {
        $pending = [string](Get-ContinuousCoReviewLeaseProp -Object $existing -Name 'pending_tree')
        $path = Get-ContinuousCoReviewLineageLeasePath -RepoRoot $RepoRoot -LineageId $LineageId
        try { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }
        catch { return [pscustomobject]@{ released = $false; reason = 'delete-failed'; pending_tree = $pending } }
        return [pscustomobject]@{ released = $true; reason = 'released'; pending_tree = $pending }
    }
    return [pscustomobject]@{ released = $false; reason = 'not-owner'; pending_tree = $null }
}

# Stamp the lease's owner PROCESS (pid + start identity) after the reviewer supervisor is spawned, so crash
# recovery tracks the process actually running the review. Owner-token + generation guarded.
function Update-ContinuousCoReviewLineageLeaseOwnerProcess {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$LineageId,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Generation,
        [Parameter(Mandatory)][AllowEmptyString()][string]$OwnerToken,
        [Parameter(Mandatory)][int]$OwnerPid
    )
    $existing = Get-ContinuousCoReviewLineageLease -RepoRoot $RepoRoot -LineageId $LineageId
    if ($null -eq $existing) { return $false }
    if (([string](Get-ContinuousCoReviewLeaseProp -Object $existing -Name 'owner_token') -cne $OwnerToken) -or
        ([string](Get-ContinuousCoReviewLeaseProp -Object $existing -Name 'generation') -cne $Generation)) { return $false }
    try {
        $existing | Add-Member -NotePropertyName 'pid' -NotePropertyValue $OwnerPid -Force
        $existing | Add-Member -NotePropertyName 'process_start_id' -NotePropertyValue (Get-ContinuousCoReviewProcessStartIdentity -ProcessId $OwnerPid) -Force
        ($existing | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath (Get-ContinuousCoReviewLineageLeasePath -RepoRoot $RepoRoot -LineageId $LineageId) -Encoding UTF8
        return $true
    }
    catch { return $false }
}

# VERDICT AUTHORITY is NOT lease ownership alone (maintainer 2026-07-13). Promotion/blocking authority requires
# ALL of: owner match (run_id + owner token); generation == the RESULT's reviewed-tree digest; the T019 identity
# joins pass (reviewed tree + baseline); and the result is NOT superseded by the current digest.
function Test-ContinuousCoReviewLeasePromotionAuthority {
    param(
        [AllowNull()]$Lease,
        [Parameter(Mandatory)][AllowEmptyString()][string]$CompletingRunId,
        [AllowEmptyString()][string]$CompletingOwnerToken = '',
        [Parameter(Mandatory)][AllowEmptyString()][string]$ResultReviewedDigest,
        [Parameter(Mandatory)][AllowEmptyString()][string]$CurrentDigest,
        [Parameter(Mandatory)][bool]$IdentityJoinsPass
    )
    $leaseRun = [string](Get-ContinuousCoReviewLeaseProp -Object $Lease -Name 'run_id')
    $leaseTok = [string](Get-ContinuousCoReviewLeaseProp -Object $Lease -Name 'owner_token')
    $leaseGen = [string](Get-ContinuousCoReviewLeaseProp -Object $Lease -Name 'generation')

    $ownerMatch = ($null -ne $Lease) -and (-not [string]::IsNullOrWhiteSpace($CompletingRunId)) -and ($leaseRun -ceq $CompletingRunId) -and
                  (([string]::IsNullOrWhiteSpace($CompletingOwnerToken)) -or ($leaseTok -ceq $CompletingOwnerToken))
    $generationMatchesResult = (-not [string]::IsNullOrWhiteSpace($ResultReviewedDigest)) -and ($leaseGen -ceq $ResultReviewedDigest)
    $notSuperseded = (-not [string]::IsNullOrWhiteSpace($ResultReviewedDigest)) -and ($ResultReviewedDigest -ceq $CurrentDigest)
    $authoritative = $ownerMatch -and $generationMatchesResult -and $IdentityJoinsPass -and $notSuperseded

    $reason = if ($authoritative) { $null }
    elseif (-not $ownerMatch) { 'not-lease-owner' }
    elseif (-not $generationMatchesResult) { 'generation-mismatch' }
    elseif (-not $IdentityJoinsPass) { 'identity-join-failed' }
    else { 'superseded-by-current' }

    return [pscustomobject]@{
        authoritative             = $authoritative
        owner_match               = $ownerMatch
        generation_matches_result = $generationMatchesResult
        identity_joins_pass       = $IdentityJoinsPass
        not_superseded            = $notSuperseded
        reason                    = $reason
    }
}

# Resolve the repo's lineage id for the fire path: the STABLE merge-base commit with trunk (resolved to a commit
# id so aliases are equivalent - T019 final-correction 3) + the branch target. Falls back to a stable
# repo-derived key when git cannot resolve (non-repo / detached / no trunk), so two concurrent fires of the SAME
# checkout still contend on the SAME lease file. Uses Get-ContinuousCoReviewLineageId when the contract module is
# loaded, else a self-contained hash.
function Resolve-ContinuousCoReviewRepoLineageId {
    param([Parameter(Mandatory)][string]$RepoRoot)
    $anchor = ''
    $target = ''
    try {
        # Trunk via the ONE shared resolver (replaces this loop's duplicated candidate list). Unlike the gate,
        # the lineage key must ALWAYS resolve for dedup, so an ambiguous/greenfield/failed trunk is not fatal
        # here - it simply falls through to the stable HEAD anchor below (two concurrent fires of the same
        # checkout still contend on the same lease). Guard for a standalone dot-source of only this module.
        $trunk = ''
        if (Get-Command -Name 'Resolve-ContinuousCoReviewTrunkRef' -ErrorAction SilentlyContinue) {
            $resolvedTrunk = Resolve-ContinuousCoReviewTrunkRef -RepoRoot $RepoRoot
            if ($resolvedTrunk.ok -and -not [string]::IsNullOrWhiteSpace([string]$resolvedTrunk.trunk_ref)) { $trunk = [string]$resolvedTrunk.trunk_ref }
        }
        if (-not [string]::IsNullOrWhiteSpace($trunk)) {
            $mb = (& git -C $RepoRoot merge-base HEAD $trunk 2>$null)
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($mb)) { $anchor = ([string]$mb).Trim() }
        }
        if ([string]::IsNullOrWhiteSpace($anchor)) {
            $head = (& git -C $RepoRoot rev-parse HEAD 2>$null)
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($head)) { $anchor = ([string]$head).Trim() }
        }
        $br = (& git -C $RepoRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($br)) { $target = ([string]$br).Trim() }
    }
    catch { $null = $_ }
    if ([string]::IsNullOrWhiteSpace($anchor)) { $anchor = 'no-anchor' }
    if ([string]::IsNullOrWhiteSpace($target)) {
        $rp = (Resolve-Path -LiteralPath $RepoRoot -ErrorAction SilentlyContinue)
        $target = if ($null -ne $rp) { $rp.Path } else { [string]$RepoRoot }
    }
    if (Get-Command -Name 'Get-ContinuousCoReviewLineageId' -ErrorAction SilentlyContinue) {
        return Get-ContinuousCoReviewLineageId -AnchorCommitId $anchor -TargetIdentity $target
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(("{0}`n{1}" -f $anchor, $target))
    return 'lin-' + [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::HashData($bytes)).Replace('-', '').ToLowerInvariant().Substring(0, 16)
}
