$ErrorActionPreference = 'Stop'

# T019 step 6 piece 2 — the atomically-acquired per-lineage review LEASE (maintainer design 2026-07-13).
# These are the required paired tests: concurrent single-winner acquire; duplicate same-generation; newer-tree
# queueing; owner-completion -> pending eligibility; non-owner + stale-generation fail closed; owner-only
# release; dead-owner recovery + live-owner non-steal; PID-reuse protection; clean-stale-never-erases-blocking.
Describe 'T019 step 6 piece 2: per-lineage review lease (atomic acquire, owner-only release, crash recovery)' {
    BeforeAll {
        Set-StrictMode -Version Latest
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/co-review-lineage-lease.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-identity-contracts.ps1')  # Test-...BlockingPreserved
        $script:Lease = 'co-review-lineage-lease.ps1'

        function New-LeaseRepo {
            $d = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $d -Force | Out-Null
            return $d
        }
        # Plant a raw lease file directly (for the dead-owner scenario).
        function Set-RawLease {
            param($RepoRoot, $LineageId, $Fields)
            $path = Get-ContinuousCoReviewLineageLeasePath -RepoRoot $RepoRoot -LineageId $LineageId
            $dir = Split-Path -Parent $path
            if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            ([pscustomobject]$Fields | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $path -Encoding UTF8
        }
    }

    It '1. concurrent atomic acquisition: exactly ONE winner (barrier-synchronized race)' {
        $repo = New-LeaseRepo
        $module = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/co-review-lineage-lease.ps1'
        $startFile = (Join-Path $repo 'start.flag') -replace '\\', '/'
        $resultsDir = Join-Path $repo 'results'; New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null
        $repoFwd = $repo -replace '\\', '/'
        $moduleFwd = $module -replace '\\', '/'
        $resultsFwd = $resultsDir -replace '\\', '/'
        $winStyle = if ($IsWindows) { @{ WindowStyle = 'Hidden' } } else { @{} }
        $N = 6
        $procs = @()
        for ($i = 0; $i -lt $N; $i++) {
            $racer = @"
. '$moduleFwd'
while (-not (Test-Path -LiteralPath '$startFile')) { Start-Sleep -Milliseconds 5 }
`$r = Request-ContinuousCoReviewLineageLease -RepoRoot '$repoFwd' -LineageId 'L' -Generation 'genA' -RunId 'run-$i'
Set-Content -LiteralPath (Join-Path '$resultsFwd' 'r-$i.txt') -Value ([string]`$r.acquired) -Encoding UTF8
"@
            $racerFile = Join-Path $repo "racer-$i.ps1"
            Set-Content -LiteralPath $racerFile -Value $racer -Encoding UTF8
            $procs += Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-File', $racerFile) -PassThru @winStyle
        }
        Start-Sleep -Milliseconds 500   # let every racer reach the barrier
        Set-Content -LiteralPath ($startFile -replace '/', [System.IO.Path]::DirectorySeparatorChar) -Value 'go' -Encoding UTF8
        foreach ($p in $procs) { $null = $p.WaitForExit(20000) }
        $vals = @(Get-ChildItem -LiteralPath $resultsDir -Filter 'r-*.txt' | ForEach-Object { (Get-Content -LiteralPath $_.FullName -Raw).Trim() })
        $vals.Count | Should -Be $N -Because 'every racer recorded a result'
        @($vals | Where-Object { $_ -eq 'True' }).Count | Should -Be 1 -Because 'exactly one racer wins the atomic CreateNew'
    }

    It '2. duplicate same-generation fire: no acquire (the caller then spawns nothing, spends nothing)' {
        $repo = New-LeaseRepo
        (Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genA' -RunId 'run1').acquired | Should -BeTrue
        $r2 = Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genA' -RunId 'run2'
        $r2.acquired | Should -BeFalse
        $r2.reason | Should -Be 'duplicate-same-generation'
    }

    It '3. newer tree while an older generation is active (live owner): QUEUED as pending, not concurrently spawned' {
        $repo = New-LeaseRepo
        $r1 = Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genA' -RunId 'run1' -AcquiringPid $PID
        $r1.acquired | Should -BeTrue
        $r2 = Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genB' -RunId 'run2' -AcquiringPid $PID
        $r2.acquired | Should -BeFalse
        $r2.reason | Should -Be 'queued-newer-tree'
        [string](Get-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L').pending_tree | Should -Be 'genB'
    }

    It '4. owner completion -> the pending newest tree becomes eligible for the next generation' {
        $repo = New-LeaseRepo
        $r1 = Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genA' -RunId 'run1' -AcquiringPid $PID
        $null = Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genB' -RunId 'run2' -AcquiringPid $PID  # queues genB
        $rel = Complete-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genA' -OwnerToken $r1.lease.owner_token
        $rel.released | Should -BeTrue
        $rel.pending_tree | Should -Be 'genB' -Because 'the queued newest tree is returned so it can acquire the next generation'
        (Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genB' -RunId 'run3').acquired | Should -BeTrue
    }

    It '5. verdict authority requires ALL four conditions; non-owner + stale-generation + superseded + identity-fail each fail closed' {
        $lease = [pscustomobject]@{ run_id = 'owner-run'; owner_token = 'TOK'; generation = 'digestA' }
        (Test-ContinuousCoReviewLeasePromotionAuthority -Lease $lease -CompletingRunId 'owner-run' -CompletingOwnerToken 'TOK' -ResultReviewedDigest 'digestA' -CurrentDigest 'digestA' -IdentityJoinsPass $true).authoritative | Should -BeTrue
        # dimension-isolation cases carry the CORRECT owner token (an empty token is itself non-authoritative
        # since the 2026-07-14 wildcard fix - covered by its own regression below).
        (Test-ContinuousCoReviewLeasePromotionAuthority -Lease $lease -CompletingRunId 'OTHER' -CompletingOwnerToken 'TOK' -ResultReviewedDigest 'digestA' -CurrentDigest 'digestA' -IdentityJoinsPass $true).reason | Should -Be 'not-lease-owner'
        (Test-ContinuousCoReviewLeasePromotionAuthority -Lease $lease -CompletingRunId 'owner-run' -CompletingOwnerToken 'TOK' -ResultReviewedDigest 'digestOLD' -CurrentDigest 'digestOLD' -IdentityJoinsPass $true).reason | Should -Be 'generation-mismatch'
        (Test-ContinuousCoReviewLeasePromotionAuthority -Lease $lease -CompletingRunId 'owner-run' -CompletingOwnerToken 'TOK' -ResultReviewedDigest 'digestA' -CurrentDigest 'digestNEW' -IdentityJoinsPass $true).reason | Should -Be 'superseded-by-current'
        (Test-ContinuousCoReviewLeasePromotionAuthority -Lease $lease -CompletingRunId 'owner-run' -CompletingOwnerToken 'TOK' -ResultReviewedDigest 'digestA' -CurrentDigest 'digestA' -IdentityJoinsPass $false).reason | Should -Be 'identity-join-failed'
        (Test-ContinuousCoReviewLeasePromotionAuthority -Lease $null -CompletingRunId 'owner-run' -CompletingOwnerToken 'TOK' -ResultReviewedDigest 'digestA' -CurrentDigest 'digestA' -IdentityJoinsPass $true).authoritative | Should -BeFalse -Because 'no lease -> no authority'
    }

    It '5b. a MISSING completing owner token is non-authoritative exactly like a WRONG one - never a wildcard (review finding f4, run 20260714T172315119)' {
        $lease = [pscustomobject]@{ run_id = 'owner-run'; owner_token = 'TOK'; generation = 'digestA' }
        # the forgery case: knowledge of the run ID alone (empty token) must NOT substitute for ownership.
        $empty = Test-ContinuousCoReviewLeasePromotionAuthority -Lease $lease -CompletingRunId 'owner-run' -CompletingOwnerToken '' -ResultReviewedDigest 'digestA' -CurrentDigest 'digestA' -IdentityJoinsPass $true
        $empty.authoritative | Should -BeFalse -Because 'an empty token was the wildcard hole: run-id knowledge substituted for lease ownership'
        $empty.owner_match | Should -BeFalse
        $empty.reason | Should -Be 'not-lease-owner'
        # omitted entirely (the navigator''s legacy/corrupt-registry shape) - same non-authority.
        (Test-ContinuousCoReviewLeasePromotionAuthority -Lease $lease -CompletingRunId 'owner-run' -ResultReviewedDigest 'digestA' -CurrentDigest 'digestA' -IdentityJoinsPass $true).reason | Should -Be 'not-lease-owner'
        # wrong token - the pre-existing refusal, unchanged.
        (Test-ContinuousCoReviewLeasePromotionAuthority -Lease $lease -CompletingRunId 'owner-run' -CompletingOwnerToken 'FORGED' -ResultReviewedDigest 'digestA' -CurrentDigest 'digestA' -IdentityJoinsPass $true).reason | Should -Be 'not-lease-owner'
    }

    It '6. OWNER-ONLY release: a wrong owner token cannot release; the correct token does' {
        $repo = New-LeaseRepo
        $r1 = Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genA' -RunId 'run1'
        (Complete-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genA' -OwnerToken 'WRONG').released | Should -BeFalse
        (Complete-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'wrong-gen' -OwnerToken $r1.lease.owner_token).released | Should -BeFalse -Because 'the generation must also match'
        (Complete-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genA' -OwnerToken $r1.lease.owner_token).released | Should -BeTrue
    }

    It '7. dead-owner RECOVERY (reclaim) + live-owner NON-STEAL' {
        # DEAD owner: a lease owned by a process that has exited -> a newer-generation acquire reclaims it.
        $repo = New-LeaseRepo
        $dead = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'exit 0') -PassThru
        $null = $dead.WaitForExit(10000)
        Set-RawLease -RepoRoot $repo -LineageId 'L' -Fields @{ schema_version = '1.0'; lineage_id = 'L'; generation = 'genOLD'; run_id = 'dead-run'; owner_token = 'x'; pid = $dead.Id; process_start_id = 'stale-start-id'; acquired_at = '2020-01-01T00:00:00Z'; pending_tree = $null }
        $r = Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genNEW' -RunId 'run2'
        $r.acquired | Should -BeTrue -Because 'a provably-dead owner is reclaimed'
        $r.reclaimed | Should -BeTrue

        # LIVE owner: never stolen - a newer generation is queued, not reclaimed.
        $repo2 = New-LeaseRepo
        $null = Request-ContinuousCoReviewLineageLease -RepoRoot $repo2 -LineageId 'L' -Generation 'genA' -RunId 'run1' -AcquiringPid $PID
        (Request-ContinuousCoReviewLineageLease -RepoRoot $repo2 -LineageId 'L' -Generation 'genB' -RunId 'run2').reason | Should -Be 'queued-newer-tree'
    }

    It '8. PID-reuse protection: a matching PID but a DIFFERENT process-start identity is NOT the owner' {
        (Test-ContinuousCoReviewLeaseOwnerAlive -OwnerPid $PID -ProcessStartId 'a-different-start-id') | Should -BeFalse -Because 'a reused PID belonging to another process is not the owner'
        (Test-ContinuousCoReviewLeaseOwnerAlive -OwnerPid $PID -ProcessStartId (Get-ContinuousCoReviewProcessStartIdentity -ProcessId $PID)) | Should -BeTrue
        (Test-ContinuousCoReviewLeaseOwnerAlive -OwnerPid $null -ProcessStartId '') | Should -BeFalse
    }

    It '9. a CLEAN, STALE (superseded) completion is not authoritative AND never erases a current blocking result' {
        $lease = [pscustomobject]@{ run_id = 'r'; owner_token = 't'; generation = 'old' }
        $auth = Test-ContinuousCoReviewLeasePromotionAuthority -Lease $lease -CompletingRunId 'r' -CompletingOwnerToken 't' -ResultReviewedDigest 'old' -CurrentDigest 'new' -IdentityJoinsPass $true
        $auth.authoritative | Should -BeFalse
        $auth.reason | Should -Be 'superseded-by-current'
        $bp = Test-ContinuousCoReviewBlockingPreserved -ExistingBlockingCount 2 -IncomingOutcome 'clean'
        $bp.blocking_preserved | Should -BeTrue
        $bp.erased | Should -BeFalse
    }

    It 'lineage lease filename is a hash (no path traversal from a hostile lineage id)' {
        $repo = New-LeaseRepo
        $p = Get-ContinuousCoReviewLineageLeasePath -RepoRoot $repo -LineageId '../../etc/passwd'
        (Split-Path -Leaf $p) | Should -Match '^[0-9a-f]{64}\.json$'
        $p | Should -Not -Match '\.\.'
    }
}
