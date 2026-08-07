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
        $finishFile = Join-Path $repo 'finish.flag'
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
if (`$r.acquired) { while (-not (Test-Path -LiteralPath '$finishFile')) { Start-Sleep -Milliseconds 5 } }
"@
            $racerFile = Join-Path $repo "racer-$i.ps1"
            Set-Content -LiteralPath $racerFile -Value $racer -Encoding UTF8
            $procs += Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-File', $racerFile) -PassThru @winStyle
        }
        Start-Sleep -Milliseconds 500   # let every racer reach the barrier
        Set-Content -LiteralPath ($startFile -replace '/', [System.IO.Path]::DirectorySeparatorChar) -Value 'go' -Encoding UTF8
        $resultDeadline = [DateTime]::UtcNow.AddSeconds(20)
        while (@(Get-ChildItem -LiteralPath $resultsDir -Filter 'r-*.txt').Count -lt $N -and [DateTime]::UtcNow -lt $resultDeadline) { Start-Sleep -Milliseconds 10 }
        # Keep the first winner alive until every concurrent contender has observed that live owner.
        # Otherwise the winner can exit early and correct dead-owner recovery creates a second,
        # sequential winner, making this atomic-acquisition test timing-dependent.
        Set-Content -LiteralPath $finishFile -Value 'done' -Encoding UTF8
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

    It '2b. Linux process-start identity is identical across the owner and a separate observer' -Skip:(-not $IsLinux) {
        $repo = New-LeaseRepo
        $module = (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/co-review-lineage-lease.ps1') -replace '\\', '/'
        $identityFile = (Join-Path $repo 'owner-identity.txt') -replace '\\', '/'
        $releaseFile = (Join-Path $repo 'release.flag') -replace '\\', '/'
        $ownerScript = Join-Path $repo 'identity-owner.ps1'
        $ownerSource = @"
. '$module'
Set-Content -LiteralPath '$identityFile' -Value (Get-ContinuousCoReviewProcessStartIdentity -ProcessId `$PID) -Encoding UTF8
while (-not (Test-Path -LiteralPath '$releaseFile')) { Start-Sleep -Milliseconds 10 }
"@
        Set-Content -LiteralPath $ownerScript -Value $ownerSource -Encoding UTF8
        $owner = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-File', $ownerScript) -PassThru
        try {
            $deadline = [DateTime]::UtcNow.AddSeconds(10)
            while (-not (Test-Path -LiteralPath $identityFile -PathType Leaf) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 10 }
            Test-Path -LiteralPath $identityFile -PathType Leaf | Should -BeTrue -Because 'the owner must publish its self-observed start identity'
            $ownerIdentity = (Get-Content -LiteralPath $identityFile -Raw).Trim()
            $observerIdentity = Get-ContinuousCoReviewProcessStartIdentity -ProcessId $owner.Id
            $observerIdentity | Should -Be $ownerIdentity -Because 'lease liveness is evaluated by a different process than the owner that recorded it'
            (Test-ContinuousCoReviewLeaseOwnerAlive -OwnerPid $owner.Id -ProcessStartId $ownerIdentity) | Should -BeTrue
        }
        finally {
            Set-Content -LiteralPath $releaseFile -Value done -Encoding UTF8
            if (-not $owner.WaitForExit(10000)) { Stop-Process -Id $owner.Id -Force -ErrorAction SilentlyContinue }
        }
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

    It '7b. a provably-DEAD owner holding the SAME generation is reclaimed - a crash can no longer suppress every same-generation retry forever (review finding f3, run 20260714T215545754)' {
        $repo = New-LeaseRepo
        $dead = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'exit 0') -PassThru
        $null = $dead.WaitForExit(10000)
        Set-RawLease -RepoRoot $repo -LineageId 'L' -Fields @{ schema_version = '1.0'; lineage_id = 'L'; generation = 'genA'; run_id = 'dead-run'; owner_token = 'x'; pid = $dead.Id; process_start_id = 'stale-start-id'; acquired_at = '2020-01-01T00:00:00Z'; pending_tree = $null }
        # retry the IDENTICAL generation: pre-fix this returned duplicate-same-generation forever.
        $r = Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genA' -RunId 'retry-same-gen' -AcquiringPid $PID
        $r.acquired | Should -BeTrue -Because 'a dead same-generation owner is reclaimed, not treated as an active duplicate'
        $r.reclaimed | Should -BeTrue
        # paired: a LIVE same-generation owner is still a duplicate (the suppression is about liveness, not gone).
        $repo2 = New-LeaseRepo
        (Request-ContinuousCoReviewLineageLease -RepoRoot $repo2 -LineageId 'L' -Generation 'genA' -RunId 'live-owner' -AcquiringPid $PID).acquired | Should -BeTrue
        (Request-ContinuousCoReviewLineageLease -RepoRoot $repo2 -LineageId 'L' -Generation 'genA' -RunId 'dup-fire' -AcquiringPid $PID).reason | Should -Be 'duplicate-same-generation'
    }

    It '7c. CONCURRENT reclaim is single-winner CLAIM-BY-RENAME - the loser can never delete the winner''s replacement lease (review finding f4, run 20260714T215545754)' {
        $repo = New-LeaseRepo
        $dead = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'exit 0') -PassThru
        $null = $dead.WaitForExit(10000)
        Set-RawLease -RepoRoot $repo -LineageId 'L' -Fields @{ schema_version = '1.0'; lineage_id = 'L'; generation = 'genOLD'; run_id = 'dead-run'; owner_token = 'DEADTOKEN'; pid = $dead.Id; process_start_id = 'stale-start-id'; acquired_at = '2020-01-01T00:00:00Z'; pending_tree = $null }
        # TWO barrier-synchronized real processes race the reclaim of the SAME dead lease.
        $moduleDir = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review'
        $barrier = Join-Path $repo 'barrier.go'
        $workers = @()
        foreach ($w in @('A', 'B')) {
            $outFile = Join-Path $repo "reclaim-$w.json"
            $cmd = ". '$moduleDir/review-identity-contracts.ps1'; . '$moduleDir/co-review-lineage-lease.ps1'; " +
            "while (-not (Test-Path -LiteralPath '$barrier')) { Start-Sleep -Milliseconds 5 }; " +
            "`$r = Request-ContinuousCoReviewLineageLease -RepoRoot '$repo' -LineageId 'L' -Generation 'genNEW' -RunId 'reclaimer-$w'; " +
            "[pscustomobject]@{ acquired = `$r.acquired; reason = `$r.reason } | ConvertTo-Json -Compress | Set-Content -LiteralPath '$outFile' -Encoding UTF8; " +
            "if (`$r.acquired) { Start-Sleep -Seconds 8 }   # a real supervisor stays alive; exiting instantly would make the winner a legitimately reclaimable dead owner"
            $workers += Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', $cmd) -PassThru
        }
        Set-Content -LiteralPath $barrier -Value 'go' -Encoding UTF8   # release both at once
        foreach ($p in $workers) { $null = $p.WaitForExit(60000) }
        $ra = Get-Content -LiteralPath (Join-Path $repo 'reclaim-A.json') -Raw | ConvertFrom-Json
        $rb = Get-Content -LiteralPath (Join-Path $repo 'reclaim-B.json') -Raw | ConvertFrom-Json
        # INVARIANTS: exactly one winner, and the on-disk lease is the WINNER's replacement (never deleted by
        # the loser's stale-token path-delete - the pre-fix race).
        @(@($ra, $rb) | Where-Object { [bool]$_.acquired }).Count | Should -Be 1 -Because 'the reclaim is single-winner'
        $final = Get-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L'
        $final | Should -Not -BeNullOrEmpty -Because 'the replacement lease must survive the losing reclaimer'
        [string](Get-ContinuousCoReviewLeaseProp -Object $final -Name 'owner_token') | Should -Not -Be 'DEADTOKEN'
        [string](Get-ContinuousCoReviewLeaseProp -Object $final -Name 'generation') | Should -Be 'genNEW'
        # and no orphaned reclaim-intermediate files remain.
        @(Get-ChildItem -LiteralPath (Split-Path (Get-ContinuousCoReviewLineageLeasePath -RepoRoot $repo -LineageId 'L') -Parent) -Filter '*.reclaim.*' -File -ErrorAction SilentlyContinue).Count | Should -Be 0
    }

    It '10a. SUPERVISOR SELF-ADOPTION closes the parent-crash-before-handoff window: the live supervisor claims the dead parent''s lease, and no concurrent fire can then reclaim it (lease-lifecycle T6, 2026-07-15)' {
        $repo = New-LeaseRepo
        # the CRASH WINDOW: the acquiring parent died after the spawn, before the handoff - the lease still
        # names the dead parent while the supervisor (this process, standing in) is alive.
        $dead = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'exit 0') -PassThru
        $null = $dead.WaitForExit(10000)
        Set-RawLease -RepoRoot $repo -LineageId 'L' -Fields @{ schema_version = '1.0'; lineage_id = 'L'; generation = 'genA'; run_id = 'run1'; owner_token = 'TOK1'; pid = $dead.Id; process_start_id = 'stale-start-id'; acquired_at = '2020-01-01T00:00:00Z'; pending_tree = $null }
        # the registry the entry would read (written by the parent BEFORE the spawn).
        $regPath = Join-Path $repo 'run1.json'
        ([pscustomobject]@{ schema_version = '1.0'; run_id = 'run1'; status = 'running'; lineage_id = 'L'; generation = 'genA'; owner_token = 'TOK1' } | ConvertTo-Json) | Set-Content -LiteralPath $regPath -Encoding UTF8

        $gate = Invoke-ContinuousCoReviewSupervisorLeaseGate -RepoRoot $repo -RegistryPath $regPath -SupervisorPid $PID
        $gate.proceed | Should -BeTrue -Because 'the token+generation-matched adoption claims the dead parent''s lease for the live supervisor'
        $lease = Get-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L'
        [int](Get-ContinuousCoReviewLeaseProp -Object $lease -Name 'pid') | Should -Be $PID
        # the window is CLOSED: a concurrent fire now sees a LIVE owner - duplicate/queue, never a reclaim
        # that would double-spawn.
        (Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genA' -RunId 'racer' -AcquiringPid $PID).reason | Should -Be 'duplicate-same-generation'
        (Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L' -Generation 'genB' -RunId 'racer2' -AcquiringPid $PID).reason | Should -Be 'queued-newer-tree'
    }

    It '10b. a supervisor whose lease was RECLAIMED during the crash window REFUSES to run - never two authoritative reviewers (lease-lifecycle T6 refusal, 2026-07-15)' {
        $repo = New-LeaseRepo
        # the lease was reclaimed+replaced while unowned: it now carries a DIFFERENT owner token.
        Set-RawLease -RepoRoot $repo -LineageId 'L' -Fields @{ schema_version = '1.0'; lineage_id = 'L'; generation = 'genA'; run_id = 'run2-replacement'; owner_token = 'OTHERTOKEN'; pid = $PID; process_start_id = (Get-ContinuousCoReviewProcessStartIdentity -ProcessId $PID); acquired_at = '2026-07-15T00:00:00Z'; pending_tree = $null }
        $regPath = Join-Path $repo 'run1.json'
        ([pscustomobject]@{ schema_version = '1.0'; run_id = 'run1'; status = 'running'; lineage_id = 'L'; generation = 'genA'; owner_token = 'TOK1' } | ConvertTo-Json) | Set-Content -LiteralPath $regPath -Encoding UTF8

        $gate = Invoke-ContinuousCoReviewSupervisorLeaseGate -RepoRoot $repo -RegistryPath $regPath -SupervisorPid $PID
        $gate.proceed | Should -BeFalse -Because 'the lease belongs to another run now; this supervisor must exit rather than run unprotected'
        [string]$gate.reason | Should -Match 'lease-lost-at-startup'
        # the replacement lease is UNTOUCHED by the refusal.
        [string](Get-ContinuousCoReviewLeaseProp -Object (Get-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L') -Name 'owner_token') | Should -Be 'OTHERTOKEN'
        # paired: a LEGACY registry without lease fields proceeds (nothing to adopt - compatibility).
        $legacyReg = Join-Path $repo 'legacy.json'
        ([pscustomobject]@{ schema_version = '1.0'; run_id = 'legacy'; status = 'running' } | ConvertTo-Json) | Set-Content -LiteralPath $legacyReg -Encoding UTF8
        (Invoke-ContinuousCoReviewSupervisorLeaseGate -RepoRoot $repo -RegistryPath $legacyReg -SupervisorPid $PID).proceed | Should -BeTrue
    }

    It '8. PID-reuse protection: a matching PID but a DIFFERENT process-start identity is NOT the owner' {
        (Test-ContinuousCoReviewLeaseOwnerAlive -OwnerPid $PID -ProcessStartId 'a-different-start-id') | Should -BeFalse -Because 'a reused PID belonging to another process is not the owner'
        (Test-ContinuousCoReviewLeaseOwnerAlive -OwnerPid $PID -ProcessStartId (Get-ContinuousCoReviewProcessStartIdentity -ProcessId $PID)) | Should -BeTrue
        if ($IsLinux) {
            $legacyLiveIdentity = ('{0}:{1}' -f $PID, (Get-Process -Id $PID).StartTime.ToUniversalTime().Ticks)
            (Test-ContinuousCoReviewLeaseOwnerAlive -OwnerPid $PID -ProcessStartId $legacyLiveIdentity) | Should -BeTrue -Because 'an in-flight lease written before the /proc upgrade must be suppressed conservatively, not stolen'
            $legacyDead = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'exit 0') -PassThru
            $null = $legacyDead.WaitForExit(10000)
            (Test-ContinuousCoReviewLeaseOwnerAlive -OwnerPid $legacyDead.Id -ProcessStartId ("$($legacyDead.Id):1")) | Should -BeFalse -Because 'legacy compatibility does not keep a lease alive after its PID exits'
        }
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
