$ErrorActionPreference = 'Stop'

# Trace: T045 / FR-057, FR-058, FR-062 / SC-017, SC-020.
Describe 'Immutable review authority JSON store (T045)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:CorePath = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1'
        $script:StorePath = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-store.ps1'
        . $script:CorePath
        . $script:StorePath

        function script:New-StoreGrant {
            param([string]$Campaign = 'cmp-demo', [string]$Grant = 'grant-human', [int]$Slots = 1)
            [pscustomobject][ordered]@{ schema_version = '1.0'; fact_type = 'grant'; campaign_id = $Campaign; grant_id = $Grant; slots = $Slots; authority_kind = 'human'; authorization_ref = 'human-verdict'; observed_at = '2026-07-16T00:00:00Z' }
        }
        function script:New-StoreRun {
            param([string]$Campaign = 'cmp-demo', [string]$Run = 'run-one', [string]$State = 'requested', [string]$Digest = 'digest-one')
            [pscustomobject][ordered]@{ schema_version = '1.0'; campaign_id = $Campaign; run_id = $Run; target_digest = $Digest; harness_id = 'fixture'; state = $State }
        }
        function script:New-StoreSpend {
            param([string]$Campaign = 'cmp-demo', [string]$Run = 'run-one', [string]$Reservation = 'res-one')
            [pscustomobject][ordered]@{ schema_version = '1.0'; fact_type = 'spend'; campaign_id = $Campaign; reservation_id = $Reservation; run_id = $Run; invocation_started_at = '2026-07-16T00:00:02Z' }
        }
        function script:New-StoreResult {
            param([string]$Campaign = 'cmp-demo', [string]$Run = 'run-one', [string]$Digest = 'digest-one')
            [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $Campaign; run_id = $Run; target_digest = $Digest; harness_id = 'fixture'
                completion = 'complete'; verdict = 'pass'; runtime_outcome = 'completed'; termination_verified = $true
                containment = 'verified'; currentness = 'current'; validation = 'valid'; can_approve_current = $true
                failure_reason = $null; summary = 'clean'; findings = @(); started_at = '2026-07-16T00:00:00Z'
                ended_at = '2026-07-16T00:00:01Z'; duration_ms = 1000
            }
        }
        function script:New-StoreFinalization {
            param([string]$Campaign = 'cmp-demo', [string]$Run = 'run-one', [string]$Digest = ('a' * 40), [string]$Commit = ('b' * 40))
            [pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'review-finalization'; campaign_id = $Campaign
                run_id = $Run; reviewed_digest = $Digest; finalization_commit = $Commit
            }
        }
        function script:Start-EncodedPwsh {
            param([Parameter(Mandatory)][string]$Command)
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Command))
            $parameters = @{ FilePath = (Get-Command pwsh).Source; ArgumentList = @('-NoProfile', '-NonInteractive', '-EncodedCommand', $encoded); PassThru = $true }
            if ($IsWindows) { $parameters.WindowStyle = 'Hidden' }
            return Start-Process @parameters
        }
        function script:Quote-PsLiteral([string]$Value) { return "'" + $Value.Replace("'", "''") + "'" }
    }

    It 'publishes with CreateNew, treats canonical identity as idempotent, and rejects conflicting overwrite' {
        $store = Join-Path $TestDrive 'idempotency'
        $grant = New-StoreGrant
        $first = Add-ReviewCampaignGrantFact -StoreRoot $store -Fact $grant
        $first.created | Should -BeTrue

        # Same semantic object in a different property order canonicalizes to the same immutable bytes.
        $same = [pscustomobject][ordered]@{ observed_at = '2026-07-16T00:00:00Z'; authorization_ref = 'human-verdict'; authority_kind = 'human'; slots = 1; grant_id = 'grant-human'; campaign_id = 'cmp-demo'; fact_type = 'grant'; schema_version = '1.0' }
        $again = Add-ReviewCampaignGrantFact -StoreRoot $store -Fact $same
        $again.created | Should -BeFalse
        $again.idempotent | Should -BeTrue

        # SystemClock uses DateTimeOffset.ToString('o'). ConvertFrom-Json may coerce this to local
        # DateTime and change offset/precision on serialization; immutable byte replay must still win.
        $precise = New-StoreGrant -Grant grant-precise
        $precise.observed_at = [DateTimeOffset]::UtcNow.ToString('o')
        $preciseFirst = Add-ReviewCampaignGrantFact -StoreRoot $store -Fact $precise
        $preciseAgain = Add-ReviewCampaignGrantFact -StoreRoot $store -Fact $precise
        $preciseFirst.created | Should -BeTrue
        $preciseAgain.idempotent | Should -BeTrue

        { Add-ReviewCampaignGrantFact -StoreRoot $store -Fact (New-StoreGrant -Slots 2) } | Should -Throw -ExpectedMessage '*review-store-corruption:conflicting-immutable-fact*'
        (Read-ReviewAuthorityFactFile -Path $first.path -ContractName GrantFact).slots | Should -Be 1
    }

    It 'preserves scalar arrays as scalar JSON values during canonicalization' {
        $json = ConvertTo-ReviewAuthorityCanonicalJson -Fact ([pscustomobject][ordered]@{
            paths = @('one/path', 'two/path')
            counts = @(1, 2)
        })
        $roundTrip = $json | ConvertFrom-Json
        $roundTrip.paths | Should -Be @('one/path', 'two/path')
        $roundTrip.counts | Should -Be @(1, 2)
        $json | Should -Not -Match '"Length"'
    }

    It 'fails closed on traversal, identity substitution, run-stage mismatch, and torn JSON' {
        $store = Join-Path $TestDrive 'closed'
        { Write-ReviewAuthorityImmutableFact -StoreRoot $store -RelativePath '../escape.json' -Fact (New-StoreGrant) -ContractName GrantFact } | Should -Throw -ExpectedMessage '*invalid-relative-path*'
        { Write-ReviewRunAuthorityFact -StoreRoot $store -CampaignId cmp-demo -RunId run-one -Stage requested -Fact (New-StoreRun -Run run-other) } | Should -Throw -ExpectedMessage '*identity-mismatch*'
        { Write-ReviewRunAuthorityFact -StoreRoot $store -CampaignId cmp-demo -RunId run-one -Stage requested -Fact (New-StoreRun -State invoked) } | Should -Throw -ExpectedMessage '*run-stage-mismatch*'

        $torn = Join-Path $store 'campaigns/cmp-demo/grants/grant-torn.json'
        [IO.Directory]::CreateDirectory((Split-Path -Parent $torn)) | Out-Null
        [IO.File]::WriteAllText($torn, '{', [Text.UTF8Encoding]::new($false))
        { Read-ReviewAuthorityFactFile -Path $torn -ContractName GrantFact } | Should -Throw -ExpectedMessage '*review-store-corruption:invalid-json*'
    }

    It 'uses unique run directories for immutable terminal results' {
        $store = Join-Path $TestDrive 'unique-results'
        $one = Publish-ReviewRunResultFact -StoreRoot $store -CampaignId cmp-demo -RunId run-one -Fact (New-StoreResult -Run run-one)
        $two = Publish-ReviewRunResultFact -StoreRoot $store -CampaignId cmp-demo -RunId run-two -Fact (New-StoreResult -Run run-two)
        $one.path | Should -Not -Be $two.path
        (Split-Path -Leaf $one.path) | Should -Be 'result.json'
        (Split-Path -Leaf $two.path) | Should -Be 'result.json'
        $separator = [IO.Path]::DirectorySeparatorChar
        $one.path | Should -Match ([regex]::Escape("runs${separator}run-one"))
        $two.path | Should -Match ([regex]::Escape("runs${separator}run-two"))
        (Read-ReviewAuthorityFactFile -Path $one.path -ContractName ReviewResult).findings.Count | Should -Be 0
    }

    It 'publishes one campaign finalization with CreateNew and rejects a second envelope' {
        $store = Join-Path $TestDrive 'one-finalization'
        $fact = New-StoreFinalization
        $first = Write-ReviewCampaignFinalizationFact -StoreRoot $store -Fact $fact
        $first.created | Should -BeTrue
        $replay = Write-ReviewCampaignFinalizationFact -StoreRoot $store -Fact $fact
        $replay.created | Should -BeFalse
        $replay.idempotent | Should -BeTrue

        { Write-ReviewCampaignFinalizationFact -StoreRoot $store -Fact (New-StoreFinalization -Run run-two -Commit ('c' * 40)) } |
            Should -Throw -ExpectedMessage '*review-store-corruption:conflicting-immutable-fact*'
        $persisted = Get-ReviewCampaignFinalizationFact -StoreRoot $store -CampaignId cmp-demo
        $persisted.run_id | Should -Be 'run-one'
        $persisted.finalization_commit | Should -Be ('b' * 40)
    }

    It 'makes claim ownership a run identity with append-only generations, never a process handoff' {
        $store = Join-Path $TestDrive 'claims'
        $first = Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code -ObservedAt t1
        $first.acquired | Should -BeTrue
        $first.claim.generation | Should -Be 1
        (Get-ReviewAuthorityPropertyNames -Object $first.claim) | Should -Not -Contain 'owner_pid'
        (Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId cmp-demo -RunId run-two -TargetLineage lin-code -ObservedAt t2).reason | Should -Be 'active-claim'
        (Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId cmp-demo -RunId run-two -TargetLineage lin-code -Disposition released -ObservedAt t3).reason | Should -Be 'claim-owned-by-other-run'

        $release = Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code -Disposition released -ObservedAt t3
        $release.completed | Should -BeTrue
        (Test-Path -LiteralPath $first.path) | Should -BeTrue
        (Test-Path -LiteralPath $release.path) | Should -BeTrue

        $second = Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId cmp-demo -RunId run-two -TargetLineage lin-code -ObservedAt t4
        $second.acquired | Should -BeTrue
        $second.claim.generation | Should -Be 2
        @(Get-ReviewAuthorityClaimFacts -StoreRoot $store -CampaignId cmp-demo -TargetLineage lin-code).Count | Should -Be 3
    }

    It 'has one reservation winner across barrier-synchronized processes' {
        $store = Join-Path $TestDrive 'reservation-race'
        Add-ReviewCampaignGrantFact -StoreRoot $store -Fact (New-StoreGrant) | Out-Null
        $barrier = Join-Path $TestDrive 'reservation.go'
        $processes = @()
        $outputs = @()
        for ($i = 1; $i -le 6; $i++) {
            $output = Join-Path $TestDrive "reservation-$i.json"
            $outputs += $output
            $command = @"
. $(Quote-PsLiteral $script:CorePath)
. $(Quote-PsLiteral $script:StorePath)
while (-not [IO.File]::Exists($(Quote-PsLiteral $barrier))) { Start-Sleep -Milliseconds 5 }
try { `$r = Request-ReviewCampaignReservationFact -StoreRoot $(Quote-PsLiteral $store) -CampaignId cmp-demo -RunId run-$i -ReservationId res-$i -ObservedAt t$i; `$o = [pscustomobject]@{ acquired = `$r.acquired; reason = `$r.reason } }
catch { `$o = [pscustomobject]@{ acquired = `$false; reason = `$_.Exception.Message } }
[IO.File]::WriteAllText($(Quote-PsLiteral $output), (`$o | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new(`$false))
"@
            $processes += Start-EncodedPwsh -Command $command
        }
        Start-Sleep -Milliseconds 100
        [IO.File]::WriteAllText($barrier, 'go')
        foreach ($process in $processes) { $process.WaitForExit(30000) | Should -BeTrue; $process.ExitCode | Should -Be 0 }
        $results = @($outputs | ForEach-Object { Get-Content -LiteralPath $_ -Raw | ConvertFrom-Json })
        @($results | Where-Object acquired).Count | Should -Be 1
        @($results | Where-Object { -not $_.acquired -and $_.reason -eq 'allowance-exhausted' }).Count | Should -Be 5
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $store -CampaignId cmp-demo -Kind reservations).Count | Should -Be 1
    }

    It 'appends a new immutable generation when a pre-invocation release restores a slot' {
        $store = Join-Path $TestDrive 'reservation-reuse'
        Add-ReviewCampaignGrantFact -StoreRoot $store -Fact (New-StoreGrant) | Out-Null
        $first = Request-ReviewCampaignReservationFact -StoreRoot $store -CampaignId cmp-demo -RunId run-one -ReservationId res-one -ObservedAt t1
        $release = Resolve-ReviewCampaignReleaseDecision -Reservation $first.fact -Reason 'preflight failed' -ObservedAt t2
        Write-ReviewCampaignReleaseFact -StoreRoot $store -Fact $release.fact | Out-Null

        $second = Request-ReviewCampaignReservationFact -StoreRoot $store -CampaignId cmp-demo -RunId run-two -ReservationId res-two -ObservedAt t3
        $second.acquired | Should -BeTrue
        $second.fact.slot | Should -Be 1
        $second.path | Should -Match 'generation-002\.json$'
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $store -CampaignId cmp-demo -Kind reservations).Count | Should -Be 2
    }

    It 'has one claim winner across barrier-synchronized processes' {
        $store = Join-Path $TestDrive 'claim-race'
        $barrier = Join-Path $TestDrive 'claim.go'
        $processes = @()
        $outputs = @()
        for ($i = 1; $i -le 6; $i++) {
            $output = Join-Path $TestDrive "claim-$i.json"
            $outputs += $output
            $command = @"
. $(Quote-PsLiteral $script:CorePath)
. $(Quote-PsLiteral $script:StorePath)
while (-not [IO.File]::Exists($(Quote-PsLiteral $barrier))) { Start-Sleep -Milliseconds 5 }
try { `$r = Request-ReviewAuthorityClaim -StoreRoot $(Quote-PsLiteral $store) -CampaignId cmp-demo -RunId run-$i -TargetLineage lin-code -ObservedAt t$i; `$o = [pscustomobject]@{ acquired = `$r.acquired; reason = `$r.reason } }
catch { `$o = [pscustomobject]@{ acquired = `$false; reason = `$_.Exception.Message } }
[IO.File]::WriteAllText($(Quote-PsLiteral $output), (`$o | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new(`$false))
"@
            $processes += Start-EncodedPwsh -Command $command
        }
        Start-Sleep -Milliseconds 100
        [IO.File]::WriteAllText($barrier, 'go')
        foreach ($process in $processes) { $process.WaitForExit(30000) | Should -BeTrue; $process.ExitCode | Should -Be 0 }
        $results = @($outputs | ForEach-Object { Get-Content -LiteralPath $_ -Raw | ConvertFrom-Json })
        @($results | Where-Object acquired).Count | Should -Be 1
        @($results | Where-Object { -not $_.acquired -and $_.reason -eq 'active-claim' }).Count | Should -Be 5
        $facts = @(Get-ReviewAuthorityClaimFacts -StoreRoot $store -CampaignId cmp-demo -TargetLineage lin-code)
        $facts.Count | Should -Be 1
        (Get-ReviewAuthorityActiveClaim -Facts $facts) | Should -Not -BeNullOrEmpty
    }

    It 'reconciles every crash boundary deterministically without mutating history' {
        # Reserved but never invoked: release the slot and abandon the run-owned claim.
        $store1 = Join-Path $TestDrive 'reconcile-reserved'
        Add-ReviewCampaignGrantFact -StoreRoot $store1 -Fact (New-StoreGrant) | Out-Null
        $reservation = (Request-ReviewCampaignReservationFact -StoreRoot $store1 -CampaignId cmp-demo -RunId run-one -ReservationId res-one -ObservedAt t1).fact
        Request-ReviewAuthorityClaim -StoreRoot $store1 -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code -ObservedAt t2 | Out-Null
        $plan1 = Get-ReviewRunReconciliationPlan -StoreRoot $store1 -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code
        $plan1.actions | Should -Be @('release-non-invoked-reservation', 'retire-claim-abandoned')

        # Invoked/spent but no terminal result: spend remains and the controller must close abandoned.
        $store2 = Join-Path $TestDrive 'reconcile-spent'
        Add-ReviewCampaignGrantFact -StoreRoot $store2 -Fact (New-StoreGrant) | Out-Null
        $reservation2 = (Request-ReviewCampaignReservationFact -StoreRoot $store2 -CampaignId cmp-demo -RunId run-one -ReservationId res-one -ObservedAt t1).fact
        Write-ReviewCampaignSpendFact -StoreRoot $store2 -Fact (New-StoreSpend) | Out-Null
        Write-ReviewRunAuthorityFact -StoreRoot $store2 -CampaignId cmp-demo -RunId run-one -Stage invoked -Fact (New-StoreRun -State invoked) | Out-Null
        Request-ReviewAuthorityClaim -StoreRoot $store2 -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code -ObservedAt t2 | Out-Null
        (Get-ReviewRunReconciliationPlan -StoreRoot $store2 -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code).actions | Should -Be @('publish-spent-abandoned-result', 'retire-claim-abandoned')

        # Candidate reached validation: continue deterministically rather than rerun provider.
        Write-ReviewRunAuthorityFact -StoreRoot $store2 -CampaignId cmp-demo -RunId run-one -Stage validating -Fact (New-StoreRun -State validating) | Out-Null
        (Get-ReviewRunReconciliationPlan -StoreRoot $store2 -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code).actions | Should -Be @('continue-validation-and-classification')

        # Terminal result: only claim retirement remains; once retired, reconciliation is complete.
        Publish-ReviewRunResultFact -StoreRoot $store2 -CampaignId cmp-demo -RunId run-one -Fact (New-StoreResult) | Out-Null
        (Get-ReviewRunReconciliationPlan -StoreRoot $store2 -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code).actions | Should -Be @('retire-claim-released')
        Complete-ReviewAuthorityClaim -StoreRoot $store2 -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code -Disposition released -ObservedAt t3 | Out-Null
        (Get-ReviewRunReconciliationPlan -StoreRoot $store2 -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code).actions | Should -Be @('complete')
    }

    It 'contains no generic lock, CAS, database, event-store, process-owner, or delete mechanism' {
        $source = Get-Content -LiteralPath $script:StorePath -Raw
        $source | Should -Match 'FileMode\]::CreateNew'
        $executableSource = $source -replace '(?m)^\s*#.*$', ''
        $executableSource | Should -Not -Match 'Mutex|Semaphore|Monitor::|SQLite|SqlConnection|event[- ]store|owner_pid|Remove-Item|File\]::Delete'
    }
}
