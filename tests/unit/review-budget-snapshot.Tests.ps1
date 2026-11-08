#requires -Version 7.0
# Feature 203 T007 (FR-001, FR-002, FR-003, FR-008): the review budget is declared once, in the plan, and snapshotted
# into a single grant when the human records the before-implement verdict.
#
# Before T007 the review engine had no budget of its own: each `approved for review round` minted a one-slot grant, and
# the cap was `co_review_max_rounds` read live from `.specrew/config.yml` at every round. This suite records the
# before-implement verdict through the real writer (Add-SpecrewBoundaryAuthorization, with a cited typed turn, as the
# hook records it) in temp git projects, and runs the real plan sync through the deployed wrapper.
#
# RED before T007: recording the verdict writes no budget grant at all; the only grant the engine knows is one slot per
# round authorization.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:PriorModulePath = $env:SPECREW_MODULE_PATH
    $env:SPECREW_MODULE_PATH = $script:RepoRoot
    . (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
    . (Join-Path $script:RepoRoot 'tests/support/cited-typed-turn.ps1')
    $script:SyncWrapper = Join-Path $script:RepoRoot '.specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1'
    $script:Roots = [System.Collections.Generic.List[string]]::new()
    $script:Utf8 = [Text.UTF8Encoding]::new($false)

    function New-BudgetFixture {
        # A git project whose feature 001-fixture has iteration 001 at before-implement (tasks authorized). The feature
        # plan carries -Budget under `## Review budget` when given; -ConfigExtra is appended to .specrew/config.yml.
        # -SpecrewVersion: the plan-sync cases declare a version below 0.30.0, where the design-analysis gate starts, so
        # the plan sync reaches the budget check without a design-analysis artifact; that gate is not under test here.
        # -SessionFeature and -SessionIteration are what the lifecycle state's session names; -PendingFeature adds a pending
        # crossing to before-implement for that feature, which the verdict writer reads before the session.
        param([AllowNull()][string]$Budget, [string]$ConfigExtra = '', [string]$Boundary = 'before-implement', [string]$LastAuthorized = 'tasks', [string]$SpecrewVersion = '0.40.0',
            [string]$SessionFeature = '001-fixture', [string]$SessionIteration = '001', [string]$PendingFeature = '')
        $root = Join-Path ([IO.Path]::GetTempPath()) ('rbs-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $script:Roots.Add($root) | Out-Null
        foreach ($d in @('.specrew/runtime', '.specify', '.squad', '.github/agents', 'specs/001-fixture/iterations/001')) { $null = New-Item -ItemType Directory -Path (Join-Path $root $d) -Force }
        [IO.File]::WriteAllText((Join-Path $root '.specrew/config.yml'), ("project_name: fixture`nspecrew_version: `"$SpecrewVersion`"`nbootstrap_date: `"2026-09-01`"`n" + $ConfigExtra), $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.specify/feature.json'), "{`n  `"feature_directory`": `"specs/001-fixture`"`n}`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.squad/team.md'), "# Team`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.squad/config.json'), "{}`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.squad/decisions.md'), "# Decisions`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.github/agents/squad.agent.md'), "# Squad Agent`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root 'README.md'), "# Fixture`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/runtime/`n.specrew/review/`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/spec.md'), "# Feature Specification: Fixture`n`n## Requirements`n`n- **FR-001**: Do the thing.`n", $script:Utf8)
        $plan = "# Implementation Plan: Fixture`n`n## Summary`n`nDo the thing.`n"
        if (-not [string]::IsNullOrWhiteSpace($Budget)) { $plan += "`n## Review budget`n`n``````yaml`n" + $Budget.TrimEnd() + "`n```````n`nWhy this budget.`n" }
        $plan += "`n## Structure`n`nOne file.`n"
        [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/plan.md'), $plan, $script:Utf8)
        $iter = Join-Path $root 'specs/001-fixture/iterations/001'
        [IO.File]::WriteAllText((Join-Path $iter 'plan.md'), "# Iteration Plan: 001`n`n**Status**: planned`n`n## Tasks`n`n| Task | Requirement | Title | Story | Effort |`n| ---- | ----------- | ----- | ----- | ------ |`n| T-001 | FR-001 | Do the thing | S-1 | 2 |`n", $script:Utf8)
        $null = & git -C $root init -q -b 001-fixture 2>&1
        $null = & git -C $root config user.email 'fixture@specrew.local' 2>&1
        $null = & git -C $root config user.name 'Fixture' 2>&1
        $null = & git -C $root add -A 2>&1
        $null = & git -C $root commit -q -m 'fixture' 2>&1
        $head = (@(& git -C $root rev-parse HEAD 2>&1))[0].ToString().Trim()
        $ctx = [ordered]@{
            schema               = 'v2'
            feature_path         = (Join-Path $root 'specs/001-fixture')
            session_state        = [ordered]@{ active = $true; boundary_type = $Boundary; feature_ref = $SessionFeature; iteration_number = $SessionIteration; auth_commit_hash = $head; recorded_at = '2026-11-08T08:00:00Z' }
            boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = $LastAuthorized; pending_next_boundary = $Boundary; verdict_history = @(); bypass_history = @() }
        }
        if (-not [string]::IsNullOrWhiteSpace($PendingFeature)) {
            $tree = (@(& git -C $root rev-parse 'HEAD^{tree}' 2>&1))[0].ToString().Trim()
            $ctx.boundary_enforcement['pending_crossing'] = New-SpecrewBoundaryCrossingIdentity -FromBoundary $LastAuthorized -ToBoundary $Boundary `
                -BoundaryCommitHash $head -ArtifactStateId $tree -RecordedAt '2026-11-08T08:00:00Z' -FeatureRef $PendingFeature -IdentityVersion '2'
        }
        [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), $script:Utf8)
        $null = & git -C $root add -A 2>&1
        $null = & git -C $root commit -q -m 'cursor at before-implement' 2>&1
        return $root
    }

    function Invoke-BeforeImplementApproval {
        # -Cite replays a turn already cited: one verdict reaches the writer twice by design (the prompt hook and Stop).
        param([string]$Root, [hashtable]$Cite)
        $cite = if ($null -ne $Cite) { $Cite } else { New-SpecrewCitedVerdictTurn -Text 'approved for before-implement' }
        $script:LastCite = $cite
        return Add-SpecrewBoundaryAuthorization -ProjectRoot $Root -CurrentBoundary 'tasks' -AuthorizedBoundary 'before-implement' `
            -AuthorizingHuman 'Fixture Human' -VerdictText 'approved for before-implement' -EvidenceSource 'hook-captured-from-transcript' @cite 2>$null
    }

    function Get-GrantDirectory { param([string]$Root, [string]$Kind = 'budget-grants') Join-Path $Root ".specrew/review/authority/campaigns/cmp-001-fixture-i001/$Kind" }
    function Get-BudgetGrants {
        param([string]$Root)
        $dir = Get-GrantDirectory -Root $Root
        if (-not (Test-Path -LiteralPath $dir)) { return @() }
        return @(Get-ChildItem -LiteralPath $dir -Filter *.json -File | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12 })
    }
    function Get-VerdictHistory {
        param([string]$Root)
        return @((Get-Content -LiteralPath (Join-Path $Root '.specrew/start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20).boundary_enforcement.verdict_history)
    }
    function Get-RefusalText {
        param([scriptblock]$Action)
        try { & $Action | Out-Null; return $null } catch { return [string]$_.Exception.Message }
    }
}

AfterAll {
    $env:SPECREW_MODULE_PATH = $script:PriorModulePath
    foreach ($r in $script:Roots) { if (Test-Path -LiteralPath $r) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } }
}

Describe 'the before-implement verdict snapshots the review budget (FR-003)' {
    It 'writes one grant with the plan''s rounds and host order, citing the verdict it was recorded with' {
        $root = New-BudgetFixture -Budget "iteration-001:`n  rounds: 3`n  host_order: [codex, copilot]`n  infra_failure_cap: 2"
        $verdict = Invoke-BeforeImplementApproval -Root $root
        $verdict.AuthorizedBoundary | Should -Be 'before-implement'
        $grants = @(Get-BudgetGrants -Root $root)
        $grants.Count | Should -Be 1 -Because 'one verdict, one grant; before T007 there was none (a grant was one slot per round authorization)'
        $grant = $grants[0]
        $grant.fact_type | Should -Be 'budget-grant'
        $grant.campaign_id | Should -Be 'cmp-001-fixture-i001'
        $grant.budget_total | Should -Be 3
        @($grant.host_order) -join ',' | Should -Be 'codex,copilot'
        $grant.host_order_stated | Should -BeTrue
        $grant.infra_failure_cap | Should -Be 2
        $grant.budget_source | Should -Be 'plan'
        $grant.ceiling | Should -Be 4
        $history = @(Get-VerdictHistory -Root $root)
        $history.Count | Should -Be 1
        $grant.verdict_entry | Should -Be ([string]$history[-1].authorization_id) -Because 'the grant cites the verdict entry it was snapshotted with'
        $grant.plan_hash | Should -Match '^[0-9a-f]{64}$'
        Test-Path -LiteralPath (Get-GrantDirectory -Root $root -Kind 'grants') | Should -BeFalse -Because 'no one-slot round grant is minted by the verdict'
    }

    It 'keeps the grant as snapshotted when the plan is edited afterwards, and a repeated capture adds nothing' {
        $root = New-BudgetFixture -Budget "iteration-001:`n  rounds: 3`n  host_order: [codex]"
        $null = Invoke-BeforeImplementApproval -Root $root
        $file = @(Get-ChildItem -LiteralPath (Get-GrantDirectory -Root $root) -Filter *.json -File)[0].FullName
        $before = [IO.File]::ReadAllBytes($file)
        $planPath = Join-Path $root 'specs/001-fixture/plan.md'
        [IO.File]::WriteAllText($planPath, ([IO.File]::ReadAllText($planPath).Replace('rounds: 3', 'rounds: 4').Replace('[codex]', '[claude]')), $script:Utf8)
        $replayed = Invoke-BeforeImplementApproval -Root $root -Cite $script:LastCite
        $replayed.AuthorizedBoundary | Should -Be 'before-implement' -Because 'the same verdict read again is the recorded one'
        @(Get-VerdictHistory -Root $root).Count | Should -Be 1
        @(Get-BudgetGrants -Root $root).Count | Should -Be 1
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($file)) | Should -Be ([Convert]::ToBase64String($before))
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $read = Get-ReviewCampaignBudgetGrant -StoreRoot (Join-Path $root '.specrew/review/authority') -CampaignId 'cmp-001-fixture-i001'
        $read.budget_total | Should -Be 3 -Because 'the engine reads the grant, never the plan, after the snapshot'
        @($read.host_order) -join ',' | Should -Be 'codex'
    }
}

Describe 'the floor of 2 rounds (FR-001, FR-008)' {
    It 'gives a plan with no review budget 2 rounds and no host order of its own' {
        $root = New-BudgetFixture -Budget $null
        $null = Invoke-BeforeImplementApproval -Root $root
        $grant = @(Get-BudgetGrants -Root $root)[0]
        $grant.budget_total | Should -Be 2
        $grant.budget_source | Should -Be 'floor-not-stated'
        @($grant.host_order).Count | Should -Be 0
        $grant.host_order_stated | Should -BeFalse
        $grant.infra_failure_cap | Should -Be 2
    }

    It 'raises a stated budget below 2 to 2' {
        $root = New-BudgetFixture -Budget "iteration-001:`n  rounds: 1`n  host_order: [codex]"
        $null = Invoke-BeforeImplementApproval -Root $root
        $grant = @(Get-BudgetGrants -Root $root)[0]
        $grant.budget_total | Should -Be 2
        $grant.budget_source | Should -Be 'floor-raised'
    }

    It 'reads a block without iteration keys as every iteration''s budget, and an entry for another iteration as not this one''s' {
        $flat = New-BudgetFixture -Budget "rounds: 3`nhost_order: [copilot, claude]"
        $null = Invoke-BeforeImplementApproval -Root $flat
        @(Get-BudgetGrants -Root $flat)[0].budget_total | Should -Be 3
        $other = New-BudgetFixture -Budget "iteration-002:`n  rounds: 3`n  host_order: [codex]"
        $null = Invoke-BeforeImplementApproval -Root $other
        @(Get-BudgetGrants -Root $other)[0].budget_source | Should -Be 'floor-not-stated'
    }
}

Describe 'the ceiling (FR-002)' {
    It 'refuses a budget above co_review_max_rounds at the snapshot, naming the ceiling and where it is set, and records nothing' {
        $root = New-BudgetFixture -Budget "iteration-001:`n  rounds: 6`n  host_order: [codex]"
        $refusal = Get-RefusalText { Invoke-BeforeImplementApproval -Root $root }
        $refusal | Should -Not -BeNullOrEmpty
        $refusal | Should -Match '\b6\b'
        $refusal | Should -Match '\b4\b'
        $refusal | Should -Match 'co_review_max_rounds'
        $refusal | Should -Match '\.specrew/config\.yml'
        $refusal | Should -Match 'approved for before-implement' -Because 'the refusal ends with the one recovery action'
        @(Get-VerdictHistory -Root $root).Count | Should -Be 0 -Because 'a verdict whose budget is refused is not recorded'
        @(Get-BudgetGrants -Root $root).Count | Should -Be 0
    }

    It 'admits the same budget once the ceiling is raised in the config' {
        $root = New-BudgetFixture -Budget "iteration-001:`n  rounds: 6`n  host_order: [codex]" -ConfigExtra "co_review_max_rounds: 8`n"
        $null = Invoke-BeforeImplementApproval -Root $root
        $grant = @(Get-BudgetGrants -Root $root)[0]
        $grant.budget_total | Should -Be 6
        $grant.ceiling | Should -Be 8
    }

    It 'refuses a reviewer host Specrew does not know, and a rounds value that is not a number' {
        $typo = New-BudgetFixture -Budget "iteration-001:`n  rounds: 3`n  host_order: [codx]"
        $refusal = Get-RefusalText { Invoke-BeforeImplementApproval -Root $typo }
        $refusal | Should -Match 'codx'
        $refusal | Should -Match 'codex' -Because 'the refusal names the hosts it knows'
        @(Get-VerdictHistory -Root $typo).Count | Should -Be 0
        $words = New-BudgetFixture -Budget "iteration-001:`n  rounds: many`n  host_order: [codex]"
        $refusal = Get-RefusalText { Invoke-BeforeImplementApproval -Root $words }
        $refusal | Should -Match 'rounds'
        $refusal | Should -Match 'many'
        @(Get-VerdictHistory -Root $words).Count | Should -Be 0
    }

    It 'tells the human, through the hook''s own capture, why the verdict was not recorded and how to go on' {
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
        $root = New-BudgetFixture -Budget "iteration-001:`n  rounds: 6`n  host_order: [codex]"
        $transcript = Join-Path $root '.specrew/runtime/transcript.jsonl'
        $human = 'approved for before-implement'
        Set-Content -LiteralPath $transcript -Encoding UTF8 -Value @(
            ('{"role":"assistant","message":{"content":[{"type":"text","text":' + (("Packet body.`n`n<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->") | ConvertTo-Json) + '}]}}')
            ('{"role":"user","promptId":"prompt-rbs-1","origin":{"kind":"human"},"message":{"content":[{"type":"text","text":' + ($human | ConvertTo-Json) + '}]}}')
        )
        $capture = Invoke-SpecrewBoundaryVerdictCapture -ProjectRoot $root -TranscriptPath $transcript -LastAuthorizedBoundary 'tasks' -Source 'Stop' -NowUtc '2026-11-08T08:30:00Z' 2>$null
        $capture.authorized | Should -BeFalse
        $capture.reason | Should -Be 'review-budget-refused'
        @(Get-VerdictHistory -Root $root).Count | Should -Be 0
        $line = Get-SpecrewVerdictCaptureDisclosure -ProjectRoot $root -HumanText $human -NowUtc '2026-11-08T08:30:00Z' -Source 'Stop' `
            -CaptureReason ([string]$capture.reason) -CaptureDetail ([string]$capture.reason_detail)
        $line | Should -Match '^Specrew did not record the before-implement approval'
        $line | Should -Match 'co_review_max_rounds'
        $line | Should -Match 'then send: approved for before-implement$'
    }

    It 'refuses the plan sync for a plan stating a budget above the ceiling, and accepts one within it' {
        $over = New-BudgetFixture -Budget "iteration-001:`n  rounds: 3`n  host_order: [codex]`niteration-002:`n  rounds: 9" -Boundary 'clarify' -LastAuthorized 'clarify' -SpecrewVersion '0.29.0'
        $head = (@(& git -C $over rev-parse HEAD 2>&1))[0].ToString().Trim()
        $out = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $script:SyncWrapper -ProjectPath $over -BoundaryType plan -FeatureRef 001-fixture -IterationNumber 001 -AuthCommitHash $head 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
        $LASTEXITCODE | Should -Not -Be 0 -Because "iteration-002 asks for 9 rounds and the ceiling is 4:`n$out"
        $out | Should -Match 'iteration-002'
        $out | Should -Match '\b9\b'
        $out | Should -Match 'co_review_max_rounds'
        $out | Should -Match '\.specrew/config\.yml'
        $within = New-BudgetFixture -Budget "iteration-001:`n  rounds: 3`n  host_order: [codex]" -Boundary 'clarify' -LastAuthorized 'clarify' -SpecrewVersion '0.29.0'
        $head = (@(& git -C $within rev-parse HEAD 2>&1))[0].ToString().Trim()
        $out = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $script:SyncWrapper -ProjectPath $within -BoundaryType plan -FeatureRef 001-fixture -IterationNumber 001 -AuthCommitHash $head 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
        $out | Should -Not -Match 'review budget' -Because "a budget within the ceiling is not refused:`n$out"
    }
}

Describe 'no grant, no verdict: an approval the snapshot cannot ground is refused (FR-003; maintainer ruling, DRIFT-048)' {
    # A before-implement verdict recorded without a grant would leave the iteration nothing to spend and no way to make a
    # grant: a second approval for a boundary already crossed authorizes nothing. So each case below refuses the verdict,
    # records nothing, and ends with the one recovery action. Before the ruling each recorded the verdict with a warning.

    It 'refuses an approval whose lifecycle state names no feature' {
        $root = New-BudgetFixture -Budget "iteration-001:`n  rounds: 3" -SessionFeature ''
        $refusal = Get-RefusalText { Invoke-BeforeImplementApproval -Root $root }
        $refusal | Should -Match '^Specrew did not record the before-implement approval, because the lifecycle state names no feature'
        $refusal | Should -Match 'Nothing else was changed'
        $refusal | Should -Match '-BoundaryType before-implement -FeatureRef <feature> -IterationNumber <NNN>'
        $refusal | Should -Match 'then send: approved for before-implement$'
        @(Get-VerdictHistory -Root $root).Count | Should -Be 0 -Because 'no grant, no verdict'
        Test-Path -LiteralPath (Join-Path $root '.specrew/review/authority') | Should -BeFalse
    }

    It 'refuses an approval whose lifecycle state names no iteration' {
        $root = New-BudgetFixture -Budget "iteration-001:`n  rounds: 3" -SessionIteration ''
        $refusal = Get-RefusalText { Invoke-BeforeImplementApproval -Root $root }
        $refusal | Should -Match 'names no iteration of 001-fixture'
        $refusal | Should -Match 'then send: approved for before-implement$'
        @(Get-VerdictHistory -Root $root).Count | Should -Be 0
        @(Get-BudgetGrants -Root $root).Count | Should -Be 0
    }

    It 'refuses rather than grant another feature''s iteration when the pending crossing and the session name different features' {
        # A pending crossing's typed verdict needs the crossing's stage evidence, which is not under test here; the writer
        # is reached as a declared out-of-band authorization, which takes the same snapshot before it is saved.
        $root = New-BudgetFixture -Budget "iteration-001:`n  rounds: 3" -SessionFeature '002-other' -PendingFeature '001-fixture'
        $outOfBand = Get-SpecrewFixtureOutOfBandSplat -Reason 'review-budget-snapshot fixture: the session names another feature'
        $refusal = Get-RefusalText { Add-SpecrewBoundaryAuthorization -ProjectRoot $root -CurrentBoundary 'tasks' -AuthorizedBoundary 'before-implement' `
                -AuthorizingHuman 'Fixture Human' -VerdictText 'approved for before-implement' @outOfBand 2>$null }
        $refusal | Should -Match 'names no iteration of 001-fixture' -Because 'the session''s iteration 001 belongs to 002-other, not to the approval''s feature'
        @(Get-VerdictHistory -Root $root).Count | Should -Be 0
        @(Get-BudgetGrants -Root $root).Count | Should -Be 0
    }

    It 'refuses an approval when no review engine can be loaded' {
        $root = New-BudgetFixture -Budget "iteration-001:`n  rounds: 3"
        Mock Get-SpecrewReviewEngineLoadPath { $null }
        $refusal = Get-RefusalText { Invoke-BeforeImplementApproval -Root $root }
        $refusal | Should -Match 'because no Specrew review engine was found to load'
        $refusal | Should -Match 'Run specrew update'
        $refusal | Should -Match 'then send: approved for before-implement$'
        @(Get-VerdictHistory -Root $root).Count | Should -Be 0
        Test-Path -LiteralPath (Join-Path $root '.specrew/review/authority') | Should -BeFalse
    }

    It 'refuses an approval when the engine it loads is older than the approval capture' {
        $root = New-BudgetFixture -Budget "iteration-001:`n  rounds: 3"
        $old = Join-Path $root 'old-module/scripts/internal/continuous-co-review'
        $null = New-Item -ItemType Directory -Path $old -Force
        [IO.File]::WriteAllText((Join-Path $old '_load.ps1'), "# an engine from before T007: no review budget functions`n", $script:Utf8)
        Mock Get-SpecrewReviewEngineLoadPath { Join-Path $old '_load.ps1' }
        $refusal = Get-RefusalText { Invoke-BeforeImplementApproval -Root $root }
        $refusal | Should -Match 'has no review budget support, so it is older than the approval capture'
        $refusal | Should -Match ([regex]::Escape((Join-Path $root 'old-module/scripts/internal')))
        $refusal | Should -Match 'Run specrew update'
        @(Get-VerdictHistory -Root $root).Count | Should -Be 0
    }
}

Describe 'new plans carry the section (FR-001)' {
    It 'ships the Review budget section in the plan template, and the reader takes the template''s own budget as written' {
        $template = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'templates/specify/templates/plan-template.md') -Raw -Encoding UTF8
        $template | Should -Match '(?m)^## Review budget\s*$' -Because 'before this change the template had no such section, so a new plan stated none and got the floor'
        $section = [regex]::Match($template, '(?ms)^## Review budget\s*$.*?(?=^## )').Value
        $section | Should -Match 'co_review_max_rounds'
        $block = [regex]::Match($section, '(?ms)^```yaml\s*$\n(.*?)^```').Groups[1].Value
        $block | Should -Not -BeNullOrEmpty
        $root = New-BudgetFixture -Budget $block
        $null = Invoke-BeforeImplementApproval -Root $root
        $grant = @(Get-BudgetGrants -Root $root)[0]
        $grant.budget_source | Should -Be 'plan' -Because 'the template''s example is a budget the snapshot reads as stated, not a block it refuses or ignores'
        $grant.budget_total | Should -Be 2
        @($grant.host_order) -join ',' | Should -Be 'codex,copilot'
        $deployed = Get-Content -LiteralPath (Join-Path $script:RepoRoot '.specify/templates/plan-template.md') -Raw -Encoding UTF8
        $deployed | Should -BeExactly $template -Because 'this repository''s own plans are written from the deployed copy'
    }

    It 'tells the planner to state the budget, in both planner charters' {
        foreach ($charter in @('extensions/specrew-speckit/squad-templates/agents/planner/charter.md', 'templates/squad/agents/planner/charter.md')) {
            $text = Get-Content -LiteralPath (Join-Path $script:RepoRoot $charter) -Raw -Encoding UTF8
            $text | Should -Match '## Review budget' -Because "$charter is what a planner reads"
            $text | Should -Match 'co_review_max_rounds'
        }
    }
}
