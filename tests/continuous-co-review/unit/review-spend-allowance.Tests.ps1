#requires -Version 7.0
$ErrorActionPreference = 'Stop'

# T020 (F-198 FR-018 / FR-019 / SC-007, NFR-007): the review-loop spend allowance.
# Proves the four observed stale-latch incidents (self-leak c894a74b/970a8d7c, FR-020
# efbbb98d/e4e88cb0) can no longer happen: a RESOLVED-AGAINST-DISK disposition clears the
# sticky blocking round-state and resets the round, so a fixed finding can NEITHER re-escalate
# NOR keep consuming the round allowance - AND it requires committed fix evidence (no
# false-green door). Plus the two-budget accounting (provider spend vs round allowance) and the
# consumer-legible halt message (zero internal identifiers).
Describe 'review spend allowance + resolved-against-disk disposition (T020 / FR-018 / FR-019)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1')

        function script:New-LatchedRepo {
            # A temp repo whose round-state holds a blocking finding at a HIGH round (the stuck latch),
            # with a committed 'fix' whose commit is an ancestor of HEAD (real fix evidence).
            $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('t020-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $repo '.specrew/runtime') -Force | Out-Null
            & git -C $repo init -q 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'code.ps1') -Value '# buggy' -Encoding UTF8 -NoNewline
            & git -C $repo -c user.name='t' -c user.email='t@e.c' add -A 2>&1 | Out-Null
            & git -C $repo -c user.name='t' -c user.email='t@e.c' commit -q -m 'seed (the finding)' 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'code.ps1') -Value '# fixed' -Encoding UTF8 -NoNewline
            & git -C $repo -c user.name='t' -c user.email='t@e.c' add -A 2>&1 | Out-Null
            & git -C $repo -c user.name='t' -c user.email='t@e.c' commit -q -m 'the fix' 2>&1 | Out-Null
            $fix = (& git -C $repo rev-parse HEAD).Trim()
            $baseBranch = (& git -C $repo branch --show-current).Trim()
            $held = @{ schema_version = '1.0'; run_id = 'r-stale'; status = 'findings'; findings = @(@{ finding_id = 'f1'; severity = 'blocking'; kind = 'defect'; location = @{ path = 'code.ps1'; line_start = 1 } }) } | ConvertTo-Json -Depth 8 -Compress
            (@{ changed_paths = @('code.ps1'); round = 3; blocking = $true; findings = $held; remediation = $null } | ConvertTo-Json -Depth 8 -Compress) |
                Set-Content -LiteralPath (Join-Path $repo '.specrew/runtime/co-review-round-state.json') -Encoding UTF8
            return [pscustomobject]@{ Repo = $repo; FixCommit = $fix; BaseBranch = $baseBranch }
        }
    }

    Context 'resolved-against-disk disposition clears the latch (the four field incidents)' {
        It 'clears blocking + lineage but PRESERVES the spent rounds (never implicitly replenishes allowance - DRIFT-198-I003-005)' {
            $f = script:New-LatchedRepo
            try {
                $d = Set-ContinuousCoReviewFindingResolvedAgainstDisk -RepoRoot $f.Repo -FixEvidenceRef $f.FixCommit
                $d.state | Should -Be 'resolved-against-disk'
                $d.fix_evidence_ref | Should -Be $f.FixCommit
                $d.rounds_spent_before_resolution | Should -Be 3
                $rs = Get-ContinuousCoReviewRoundState -RepoRoot $f.Repo
                $rs.blocking | Should -Be $false -Because 'a cleared latch cannot re-escalate'
                $rs.round | Should -Be 3 -Because 'resolving a finding NEVER replenishes the spend allowance - the rounds stay spent (FR-019 amended; only an explicit allowance-reset replenishes)'
                @($rs.changed_paths).Count | Should -Be 0 -Because 'the lineage reset stops the file-overlap climb'
                @($rs.dispositions).Count | Should -Be 1
                $rs.dispositions[0].state | Should -Be 'resolved-against-disk'
            }
            finally { Remove-Item -LiteralPath $f.Repo -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'the reset survives a subsequent per-run round-state write (disposition trail preserved)' {
            $f = script:New-LatchedRepo
            try {
                $null = Set-ContinuousCoReviewFindingResolvedAgainstDisk -RepoRoot $f.Repo -FixEvidenceRef $f.FixCommit
                # A later run writes fresh round-state; the disposition trail must persist.
                Set-ContinuousCoReviewRoundState -RepoRoot $f.Repo -ChangedPaths @('other.ps1') -Round 1 -Blocking $false -Findings $null
                $rs = Get-ContinuousCoReviewRoundState -RepoRoot $f.Repo
                @($rs.dispositions).Count | Should -Be 1 -Because 'the resolved-against-disk trail must not be wiped by a per-run write'
            }
            finally { Remove-Item -LiteralPath $f.Repo -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'REFUSES a resolved-against-disk claim with no real fix-evidence commit (no false-green door)' {
            $f = script:New-LatchedRepo
            try {
                { Set-ContinuousCoReviewFindingResolvedAgainstDisk -RepoRoot $f.Repo -FixEvidenceRef 'not-a-real-commit' } |
                    Should -Throw -ExpectedMessage '*does not resolve to a commit*'
                (Get-ContinuousCoReviewRoundState -RepoRoot $f.Repo).blocking | Should -Be $true -Because 'a bare claim must not clear the latch'
            }
            finally { Remove-Item -LiteralPath $f.Repo -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'REFUSES fix evidence that is not an ancestor of HEAD (the fix is not in the reviewed tree)' {
            $f = script:New-LatchedRepo
            try {
                # A divergent commit NOT in HEAD's history.
                & git -C $f.Repo -c user.name='t' -c user.email='t@e.c' checkout -q -b side HEAD~1 2>&1 | Out-Null
                Set-Content -LiteralPath (Join-Path $f.Repo 'code.ps1') -Value '# divergent' -Encoding UTF8 -NoNewline
                & git -C $f.Repo -c user.name='t' -c user.email='t@e.c' commit -aq -m 'divergent' 2>&1 | Out-Null
                $divergent = (& git -C $f.Repo rev-parse HEAD).Trim()
                & git -C $f.Repo -c user.name='t' -c user.email='t@e.c' checkout -q $f.BaseBranch 2>&1 | Out-Null
                (& git -C $f.Repo branch --show-current).Trim() | Should -Be $f.BaseBranch
                & git -C $f.Repo merge-base --is-ancestor $divergent HEAD 2>$null
                $LASTEXITCODE | Should -Be 1 -Because 'the fixture must prove its divergent commit is outside the reviewed HEAD history'
                { Set-ContinuousCoReviewFindingResolvedAgainstDisk -RepoRoot $f.Repo -FixEvidenceRef $divergent } |
                    Should -Throw -ExpectedMessage '*not an ancestor of HEAD*'
            }
            finally { Remove-Item -LiteralPath $f.Repo -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    Context 'allowance-reset is the SEPARATE, explicit human-approved replenish (T020 SPLIT, DRIFT-198-I003-005)' {
        It 'REPLENISHES the round allowance to 0, records authorizer/when/previous-new, and LEAVES resolved-finding evidence intact' {
            $f = script:New-LatchedRepo
            try {
                # Resolve the finding first (round PRESERVED at 3), THEN a separate human allowance-reset replenishes.
                $null = Set-ContinuousCoReviewFindingResolvedAgainstDisk -RepoRoot $f.Repo -FixEvidenceRef $f.FixCommit
                [int](Get-ContinuousCoReviewRoundState -RepoRoot $f.Repo).round | Should -Be 3 -Because 'resolve preserves the spend'
                $d = Set-ContinuousCoReviewAllowanceReset -RepoRoot $f.Repo -AuthorizedBy 'Alon' -Reason 'approved more review budget'
                $d.state | Should -Be 'allowance-reset'
                $d.authorized_by | Should -Be 'Alon' -Because 'the audit records WHO authorized the reset'
                [int]$d.previous_round | Should -Be 3 -Because 'the audit records the PREVIOUS allowance'
                [int]$d.new_round | Should -Be 0 -Because 'the audit records the NEW allowance'
                [string]$d.recorded_at | Should -Not -BeNullOrEmpty -Because 'the audit records WHEN'
                $rs = Get-ContinuousCoReviewRoundState -RepoRoot $f.Repo
                [int]$rs.round | Should -Be 0 -Because 'ONLY the explicit allowance-reset replenishes the allowance'
                @($rs.dispositions | Where-Object { $_.state -eq 'resolved-against-disk' }).Count | Should -Be 1 -Because 'the resolved-finding evidence is LEFT INTACT'
                @($rs.dispositions | Where-Object { $_.state -eq 'allowance-reset' }).Count | Should -Be 1 -Because 'the allowance-reset is itself recorded in the trail'
            }
            finally { Remove-Item -LiteralPath $f.Repo -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'via the remediation-choice API REQUIRES an explicit --ack-reason (human intent recorded), then replenishes' {
            $f = script:New-LatchedRepo
            try {
                { Set-ContinuousCoReviewRemediationChoice -RepoRoot $f.Repo -Choice 'allowance-reset' } |
                    Should -Throw -ExpectedMessage '*needs --ack-reason*'
                $rem = Set-ContinuousCoReviewRemediationChoice -RepoRoot $f.Repo -Choice 'allowance-reset' -Reason 'human approved more budget' -AuthorizedBy 'Alon'
                $rem.choice | Should -Be 'allowance-reset'
                [int](Get-ContinuousCoReviewRoundState -RepoRoot $f.Repo).round | Should -Be 0 -Because 'the human-approved reset replenishes immediately'
            }
            finally { Remove-Item -LiteralPath $f.Repo -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    Context 'two-budget accounting (provider spend vs round allowance)' {
        It 'preflight failure (input never materialized) consumes NEITHER budget' {
            $c = Get-ContinuousCoReviewRoundSpendClass -InputMaterialized $false -ModelInvoked $false -ProducedReview $false
            $c.class | Should -Be 'preflight-failed'
            $c.consumes_round | Should -Be $false
            $c.records_provider_spend | Should -Be $false
        }
        It 'an invoked run that produced a review consumes a round and records provider spend' {
            $c = Get-ContinuousCoReviewRoundSpendClass -InputMaterialized $true -ModelInvoked $true -ProducedReview $true
            $c.class | Should -Be 'invoked-reviewed'
            $c.consumes_round | Should -Be $true
            $c.records_provider_spend | Should -Be $true
        }
        It 'an invoked run that failed (no valid review) records provider spend AND counts the round' {
            $c = Get-ContinuousCoReviewRoundSpendClass -InputMaterialized $true -ModelInvoked $true -ProducedReview $false
            $c.class | Should -Be 'invoked-failed'
            $c.consumes_round | Should -Be $true -Because 'a failed invocation never disappears from round accounting'
            $c.records_provider_spend | Should -Be $true -Because 'the model was invoked, so provider budget was spent'
        }
    }

    # Trace: T008 / FR-014 / SC-008.
    #
    # CHARACTERIZATION, NOT A REPAIR - and the label is load-bearing. Measured across all five authority
    # stores in existence (T067's, 198-i008/i009/i010/i011, and this feature's own): reuses == releases
    # in every one. GRANT REUSE WAS NEVER BROKEN. F4 was real but is a DISCLOSURE gap, not a ledger
    # defect: a restored slot is never surfaced, so a human mints an authorization they did not need.
    #
    # These cases exist so the behaviour cannot regress silently, and so no future analysis re-derives
    # the false identity that produced a retracted defect claim (DRIFT-199-I001-026).
    Context 'T008 allowance ledger - characterization of behaviour that already works' {
        BeforeAll {
            function script:New-Grant {
                param([string]$Id, [int]$Slots = 1, [string]$Campaign = 'cmp-t008-x-i001')
                [pscustomobject][ordered]@{
                    schema_version = '1.0'; fact_type = 'grant'; campaign_id = $Campaign; grant_id = $Id
                    slots = $Slots; authority_kind = 'human'; authorization_ref = 'human-verdict'
                    observed_at = '2026-08-10T00:00:00Z'
                }
            }
            function script:New-Reservation {
                param([string]$Id, [string]$Grant, [int]$Slot = 1, [string]$Run, [string]$Campaign = 'cmp-t008-x-i001')
                [pscustomobject][ordered]@{
                    schema_version = '1.0'; fact_type = 'reservation'; campaign_id = $Campaign
                    reservation_id = $Id; grant_id = $Grant; slot = $Slot; run_id = $Run
                    observed_at = '2026-08-10T00:00:01Z'
                }
            }
            function script:New-Release {
                param([string]$Reservation, [string]$Run, [string]$Campaign = 'cmp-t008-x-i001')
                [pscustomobject][ordered]@{
                    schema_version = '1.0'; fact_type = 'release'; campaign_id = $Campaign
                    reservation_id = $Reservation; run_id = $Run; reason = 'preflight-failed'
                    observed_at = '2026-08-10T00:00:02Z'
                }
            }
            function script:New-Spend {
                param([string]$Reservation, [string]$Run, [string]$Campaign = 'cmp-t008-x-i001')
                [pscustomobject][ordered]@{
                    schema_version = '1.0'; fact_type = 'spend'; campaign_id = $Campaign
                    reservation_id = $Reservation; run_id = $Run; invocation_started_at = '2026-08-10T00:00:03Z'
                }
            }
        }

        It '1. a pre-invocation failure RELEASES its reservation (no spend exists)' {
            $decision = Resolve-ReviewCampaignReleaseDecision `
                -Reservation (script:New-Reservation -Id 'res-t008a' -Grant 'grant-t008a' -Run 'run-t008a') `
                -Reason 'preflight-failed:verification' -ObservedAt '2026-08-10T00:00:02Z' -Spends @()

            $decision.permitted | Should -BeTrue
            $decision.reason | Should -Be 'proven-pre-invocation-release'
        }

        It '2. an INVOKED run keeps its charge - the release is refused when a spend exists' {
            # The other direction, so case 1 cannot be satisfied by releasing everything. Only the
            # launch-failed call site passes real spends, and this is why that matters.
            $reservation = script:New-Reservation -Id 'res-t008b' -Grant 'grant-t008b' -Run 'run-t008b'
            $decision = Resolve-ReviewCampaignReleaseDecision -Reservation $reservation `
                -Reason 'launch-failed' -ObservedAt '2026-08-10T00:00:02Z' `
                -Spends @((script:New-Spend -Reservation 'res-t008b' -Run 'run-t008b'))

            $decision.permitted | Should -BeFalse
            $decision.reason | Should -Be 'invoked-slot-remains-spent' -Because 'a round that reached a reviewer is charged; that is the rule T008 protects, not one it breaks'
        }

        It '3. THE ONE THAT MATTERS: a grant is REUSABLE after its slot is released' {
            # Measured 12 times across the five real stores. Pinned here so it cannot regress quietly.
            $grant = script:New-Grant -Id 'grant-t008c'
            $reservation = script:New-Reservation -Id 'res-t008c' -Grant 'grant-t008c' -Run 'run-t008c'

            $held = Get-ReviewCampaignAllowanceState -CampaignId 'cmp-t008-x-i001' -Grants @($grant) `
                -Reservations @($reservation) -Spends @() -Releases @()
            $held.available.Count | Should -Be 0 -Because 'an unreleased reservation holds the slot'
            $held.active.Count | Should -Be 1

            $restored = Get-ReviewCampaignAllowanceState -CampaignId 'cmp-t008-x-i001' -Grants @($grant) `
                -Reservations @($reservation) -Spends @() `
                -Releases @((script:New-Release -Reservation 'res-t008c' -Run 'run-t008c'))

            $restored.valid | Should -BeTrue
            $restored.available.Count | Should -Be 1 -Because 'a released, unspent slot returns to the pool - the human does not owe a fresh authorization'
            $restored.active.Count | Should -Be 0
            $restored.spent.Count | Should -Be 0
        }

        It '3b. a SPENT slot never returns, however many releases are recorded elsewhere' {
            $grant = script:New-Grant -Id 'grant-t008d'
            $state = Get-ReviewCampaignAllowanceState -CampaignId 'cmp-t008-x-i001' -Grants @($grant) `
                -Reservations @((script:New-Reservation -Id 'res-t008d' -Grant 'grant-t008d' -Run 'run-t008d')) `
                -Spends @((script:New-Spend -Reservation 'res-t008d' -Run 'run-t008d')) -Releases @()

            $state.available.Count | Should -Be 0
            $state.spent.Count | Should -Be 1 -Because 'the cap is a policy ceiling and a spent slot is genuinely gone'
        }

        It '4. a grant MINTED BUT NEVER RESERVED is available - the shape that broke the aggregate reasoning' {
            # THE RETRACTED-FINDING GUARD (DRIFT-199-I001-026). Deriving reuses as
            # `reservations - grants` assumes every grant is reserved against. In the real i008 store 25
            # grants had only 21 reservation containers, so that identity reported 1 reuse where there
            # were 5 - and produced a committed, FALSE defect claim.
            #
            # This case pins the shape that breaks it, so a future analysis meets a fixture rather than
            # re-deriving the same wrong number.
            $state = Get-ReviewCampaignAllowanceState -CampaignId 'cmp-t008-x-i001' `
                -Grants @((script:New-Grant -Id 'grant-used'), (script:New-Grant -Id 'grant-never-used')) `
                -Reservations @((script:New-Reservation -Id 'res-used' -Grant 'grant-used' -Run 'run-used')) `
                -Spends @() -Releases @()

            $state.valid | Should -BeTrue -Because 'a grant nobody reserved against is an ordinary state, not a corrupt store'
            $state.granted_slots | Should -Be 2
            $state.available.Count | Should -Be 1
            @($state.available)[0].grant_id | Should -Be 'grant-never-used'
            # The identity that produced the retracted claim, asserted to be WRONG on this shape.
            $reservations = 1; $grants = 2; $releases = 0
            ($reservations - $grants) | Should -Not -Be $releases -Because 'COUNT THE LEAF FACTS: an aggregate over container counts silently assumes every grant was reserved against, and is wrong exactly when one was not'
        }
    }

    Context 'consumer-legible halt message (FR-018)' {
        It 'has zero internal identifiers, states N-of-M, names the reset command, and shows resolved-vs-open' {
            . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
            $json = New-ContinuousCoReviewCeilingEscalationResult -RunId 'run-x' -Round 2 -MaxRounds 2 -ResolvedAgainstDiskCount 2
            $comment = ($json | ConvertFrom-Json).findings[0].comment
            $comment | Should -Match '2 review rounds' -Because 'the count is the rounds that ACTUALLY reviewed, hitting the limit'
            $comment | Should -Match 'limit is 2'
            $comment | Should -Match 'specrew review --remediate more-time' -Because 'the exact reset command must be named'
            $comment | Should -Match '2 earlier blocking item' -Because 'resolved-vs-open must come from the disposition trail'
            $comment | Should -Match 'budget guard'
            # Zero Specrew-internal identifiers in the human-facing halt.
            $comment | Should -Not -Match 'co_review_max_rounds'
            $comment | Should -Not -Match 'T0\d\d'
            $comment | Should -Not -Match 'F-19\d'
            $comment | Should -Not -Match '(?i)proposal|FR-0|NFR-|SC-0|DEC-198|escalated_to_human|round-state'
        }
    }

    Context 'two-budget accounting wired into the orchestrator (end-to-end)' {
        BeforeAll {
            function script:New-RunRepo {
                $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('t020e2e-' + [guid]::NewGuid().ToString('N'))
                New-Item -ItemType Directory -Path $repo -Force | Out-Null
                & git -C $repo init -q 2>&1 | Out-Null
                Set-Content -LiteralPath (Join-Path $repo 'app.txt') -Value 'v1' -Encoding UTF8
                & git -C $repo -c user.name='t' -c user.email='t@t.local' add -A 2>&1 | Out-Null
                & git -C $repo -c user.name='t' -c user.email='t@t.local' commit -q -m base 2>&1 | Out-Null
                $baseline = (& git -C $repo rev-parse HEAD).Trim()
                Set-Content -LiteralPath (Join-Path $repo 'app.txt') -Value 'v2 changed content' -Encoding UTF8
                & git -C $repo -c user.name='t' -c user.email='t@t.local' commit -aq -m change 2>&1 | Out-Null
                return [pscustomobject]@{ Repo = $repo; Baseline = $baseline }
            }
        }

        It 'PREFLIGHT: a missing changes.diff fails BEFORE model invocation and consumes NEITHER budget' {
            $f = script:New-RunRepo
            $fakeWt = Join-Path ([System.IO.Path]::GetTempPath()) ('t020wt-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $fakeWt '.review') -Force | Out-Null   # a worktree with NO changes.diff
            try {
                Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith { [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test'; independence_source = 'flag' } }
                Mock -CommandName New-ContinuousCoReviewStrippedWorktree -MockWith { [pscustomobject]@{ worktree_path = $fakeWt; tree_id = 'deadbeef'; changed_count = 1; changed_paths = @('app.txt'); diff_bytes = 0 } }
                Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith { [pscustomobject]@{ exit_code = 0; stdout = '{}'; stderr = ''; telemetry = $null } }
                $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $f.Repo -RunDir (Join-Path $f.Repo '.runs/pf') -RunId 'pf-run' -BaselineRef $f.Baseline -TimeoutSeconds 60
                [string]$st.status | Should -Be 'failed'
                [string]$st.failure_reason | Should -Be 'input-not-materialized'
                [string]$st.spend_class | Should -Be 'preflight-failed'
                $st.provider_spend | Should -Be $false
                $st.round_consumed | Should -Be $false
                Should -Invoke -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -Times 0 -Because 'a missing input must prevent the model invocation entirely'
            }
            finally { Remove-Item -LiteralPath $f.Repo, $fakeWt -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'CEILING HALT counts only the rounds that ACTUALLY reviewed, never the never-invoked +1 attempt (finding 9e3a44f1)' {
            $f = script:New-RunRepo
            try {
                Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith { [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test'; independence_source = 'flag' } }
                Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith { [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"x","status":"no_findings","findings":[]}'; stderr = ''; telemetry = $null } }
                # Seed a sticky blocking round-state AT the limit (2 rounds already reviewed), lineage = app.txt.
                $seed = '{"schema_version":"1.0","run_id":"p","status":"findings","findings":[{"finding_id":"f1","source_run_id":"p","location":{"path":"app.txt","line_start":null,"line_end":null},"severity":"blocking","kind":"x","design_reference":"d","comment":"c","disposition":"open","resolution":{"state":"unresolved","fix_evidence_ref":null,"rationale":null}}],"created_at":"2026-07-11T00:00:00Z"}'
                Set-ContinuousCoReviewRoundState -RepoRoot $f.Repo -ChangedPaths @('app.txt') -Round 2 -Blocking $true -Findings $seed
                $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $f.Repo -RunDir (Join-Path $f.Repo '.runs/ceil') -RunId 'ceil-run' -BaselineRef $f.Baseline -TimeoutSeconds 60
                [bool]$st.ceiling_halted | Should -Be $true -Because 'a 3rd overlapping round past the limit of 2 halts'
                [int]$st.round | Should -Be 2 -Because 'the never-invoked halt attempt does NOT count as a reviewed round'
                Should -Invoke -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -Times 0 -Because 'the ceiling halt never invokes a reviewer'
                $comment = (Get-Content -LiteralPath (Join-Path $f.Repo '.runs/ceil/result.out') -Raw | ConvertFrom-Json).findings[0].comment
                $comment | Should -Match '2 review rounds' -Because 'the halt reports the rounds that actually ran'
                $comment | Should -Not -Match '3 review rounds' -Because 'the 3rd attempt never reviewed - claiming 3-of-2 is false accounting'
                [int](Get-ContinuousCoReviewRoundState -RepoRoot $f.Repo).round | Should -Be 2 -Because 'the persisted sticky state records the honest count'
            }
            finally { Remove-Item -LiteralPath $f.Repo -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'POST-INVOCATION: an invoked run with no valid review consumes BOTH budgets + records a failed-invocation disposition' {
            $f = script:New-RunRepo
            try {
                Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith { [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test'; independence_source = 'flag' } }
                Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith { [pscustomobject]@{ exit_code = 0; stdout = ''; stderr = 'boom'; telemetry = $null } }
                $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $f.Repo -RunDir (Join-Path $f.Repo '.runs/inv') -RunId 'inv-run' -BaselineRef $f.Baseline -TimeoutSeconds 60
                [string]$st.status | Should -Be 'failed'
                [string]$st.spend_class | Should -Be 'invoked-failed'
                $st.provider_spend | Should -Be $true -Because 'the model was invoked, so provider budget was spent'
                $st.round_consumed | Should -Be $true -Because 'an invoked failure counts the round'
                $rs = Get-ContinuousCoReviewRoundState -RepoRoot $f.Repo
                @($rs.dispositions | Where-Object { $_.state -eq 'failed-invocation' }).Count | Should -BeGreaterOrEqual 1 -Because 'a failed invocation never disappears from accounting'
            }
            finally { Remove-Item -LiteralPath $f.Repo -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}
