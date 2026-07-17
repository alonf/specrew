$ErrorActionPreference = 'Stop'

# T094 / FR-036 + SC-019/SC-020 (iter-009 D4): the TIERED degraded-evidence signoff gate.
# Every run carries 3 assurance dimensions { completeness, independence, budget }:
#   full + independent (any budget)  -> auto-allow ('time-extended' is NOT reduced assurance).
#   partial OR not-provably-independent -> allow ONLY with a recorded FIRST-CLASS human ack
#   (degraded-ack.json / -DegradedAcknowledgement), else block with the exact ack ask.
# NEVER deadlocks: the worst case is the ack, always satisfiable via
# `specrew review --ack-degraded <run-id> --ack-reason "<why>"`.
Describe 'T094 tiered degraded-evidence signoff gate (FR-036)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')

        function Invoke-GateGit { param($Root, [string[]] $GitArgs) Push-Location $Root; try { & git @GitArgs 2>&1 | Out-Null } finally { Pop-Location } }

        function New-FeatureRepo {
            param([string] $Name)
            $repo = Join-Path $TestDrive $Name
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            Invoke-GateGit $repo @('init', '-q'); Invoke-GateGit $repo @('config', 'user.email', 't@e.c'); Invoke-GateGit $repo @('config', 'user.name', 't')
            Set-Content -LiteralPath (Join-Path $repo 'base.txt') -Value 'shipped' -Encoding UTF8
            Invoke-GateGit $repo @('add', '-A'); Invoke-GateGit $repo @('commit', '-q', '-m', 'base')
            Invoke-GateGit $repo @('branch', '-M', 'main')
            $anchor = (& git -C $repo rev-parse HEAD).Trim()
            Invoke-GateGit $repo @('checkout', '-q', '-b', 'feature')
            Set-Content -LiteralPath (Join-Path $repo 'feat.txt') -Value 'feature v0' -Encoding UTF8
            Invoke-GateGit $repo @('add', '-A'); Invoke-GateGit $repo @('commit', '-q', '-m', 'feat')
            return @{ repo = $repo; anchor = $anchor }
        }

        function Write-LabelledPassRun {
            param($Repo, $RunId, $BaselineRef, $TreeId, $ReviewedRef, [AllowNull()]$Labels)
            $dir = Join-Path (Join-Path $Repo '.specrew/review/inline') $RunId
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            $record = [ordered]@{
                schema_version = '1.0'; run_id = $RunId; checkpoint_id = 'cp'; baseline_ref = $BaselineRef
                diff_hash = 'sha256:x'; reviewed_ref = $ReviewedRef; reviewed_tree_id = $TreeId; status = 'pass'
                created_at = '2026-07-08T00:00:01Z'; updated_at = '2026-07-08T00:00:01Z'
            }
            if ($null -ne $Labels) { $record.evidence_labels = $Labels }
            ([pscustomobject]$record | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath (Join-Path $dir 'review-run.json') -Encoding UTF8 -NoNewline
        }

        function New-FreshRepoWithRun {
            param([string]$Name, [AllowNull()]$Labels)
            $f = New-FeatureRepo $Name
            $head = (& git -C $f.repo rev-parse HEAD).Trim()
            $treeId = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $f.repo).tree_id
            Write-LabelledPassRun -Repo $f.repo -RunId 'r1' -BaselineRef $f.anchor -TreeId $treeId -ReviewedRef $head -Labels $Labels
            return $f
        }
    }

    BeforeEach {
        # This suite characterizes the read-only legacy evidence gate. Production now ships in
        # campaign mode, so select the historical authority explicitly instead of inheriting HEAD.
        Mock -CommandName Get-ContinuousCoReviewAuthorityDecision -MockWith {
            [pscustomobject]@{
                mode = 'legacy'; valid = $true; legacy_promotion_enabled = $true
                campaign_authority_enabled = $false; reason = 'authority-mode-legacy'
            }
        }
    }

    It 'auto-allows full + independent evidence' {
        $f = New-FreshRepoWithRun 'tier-full-indep' ([pscustomobject]@{ completeness = 'full'; independence = 'independent'; budget = 'normal' })
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $d.decision | Should -Be 'allow'
        $d.reason | Should -Be 'fresh-and-covered'
        $d.evidence_labels.independence | Should -Be 'independent'
    }

    It 'auto-allows time-extended full + independent evidence (budget is not reduced assurance)' {
        $f = New-FreshRepoWithRun 'tier-time-ext' ([pscustomobject]@{ completeness = 'full'; independence = 'independent'; budget = 'time-extended' })
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $d.decision | Should -Be 'allow'
        $d.reason | Should -Be 'fresh-and-covered'
    }

    It 'blocks PARTIAL evidence with the exact ack ask (never a silent pass, never a deadlock)' {
        $f = New-FreshRepoWithRun 'tier-partial' ([pscustomobject]@{ completeness = 'partial'; independence = 'independent'; budget = 'normal' })
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $d.decision | Should -Be 'block'
        $d.reason | Should -Be 'degraded-evidence-needs-ack'
        $d.message | Should -Match '--ack-degraded r1' -Because 'the block IS the ask - it names the exact command (never-deadlock)'
    }

    It 'allows PARTIAL evidence once a recorded first-class ack exists (the durable per-run artifact)' {
        $f = New-FreshRepoWithRun 'tier-partial-ack' ([pscustomobject]@{ completeness = 'partial'; independence = 'independent'; budget = 'normal' })
        $null = Add-ContinuousCoReviewDegradedAck -RepoRoot $f.repo -RunId 'r1' -AuthorizedBy 'Alon' -Rationale 'timeboxed review accepted for this docs-only slice'
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $d.decision | Should -Be 'allow'
        $d.reason | Should -Be 'degraded-evidence-acknowledged'
        $d.acknowledgement.authorized_by | Should -Be 'Alon'
        $d.acknowledgement.rationale | Should -Not -BeNullOrEmpty
    }

    It 'blocks SAME-HOST evidence without an ack; allows with an explicit -DegradedAcknowledgement' {
        $f = New-FreshRepoWithRun 'tier-samehost' ([pscustomobject]@{ completeness = 'full'; independence = 'same-host'; budget = 'normal' })
        $blocked = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $blocked.decision | Should -Be 'block'
        $blocked.reason | Should -Be 'degraded-evidence-needs-ack'

        $ack = [pscustomobject]@{ authorized_by = 'Alon'; rationale = 'no independent host available on this machine; accepted consciously' }
        $allowed = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main' -DegradedAcknowledgement $ack
        $allowed.decision | Should -Be 'allow'
        $allowed.reason | Should -Be 'degraded-evidence-acknowledged'
    }

    It 'announces the tracker-only reconcile on BOTH degraded paths - the ack decision never loses the reused-evidence fact (FR-020 ANNOUNCED, run-86af61e6 catch)' {
        $f = New-FeatureRepo 'tier-tracker-degraded'
        $iterDir = Join-Path $f.repo 'specs/demo/iterations/001'
        New-Item -ItemType Directory -Path $iterDir -Force | Out-Null
        @'
# Review: Iteration 001

**Overall Verdict**: accepted

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-001 | pass | done |
| T002 | FR-002 | needs-work | not yet |
'@ | Set-Content (Join-Path $iterDir 'review.md') -Encoding UTF8
        @'
# Iteration State: 001

**Iteration Status**: executing
**Last Completed Task**: (none)
'@ | Set-Content (Join-Path $iterDir 'state.md') -Encoding UTF8
        Invoke-GateGit $f.repo @('add', '-A'); Invoke-GateGit $f.repo @('commit', '-q', '-m', 'trackers')
        $head = (& git -C $f.repo rev-parse HEAD).Trim()
        $treeId = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $f.repo).tree_id
        Write-LabelledPassRun -Repo $f.repo -RunId 'r1' -BaselineRef $f.anchor -TreeId $treeId -ReviewedRef $head -Labels ([pscustomobject]@{ completeness = 'partial'; independence = 'independent'; budget = 'normal' })

        # An honest tracker-only reconcile AFTER the reviewed tree: T001 done, matching the
        # accepted pass verdict. The matched (degraded) evidence is now REUSED across this
        # reconcile - a material fact the human's ack decision must be told.
        @'
# Iteration State: 001

**Iteration Status**: executing
**Last Completed Task**: T001
'@ | Set-Content (Join-Path $iterDir 'state.md') -Encoding UTF8
        Invoke-GateGit $f.repo @('add', '-A'); Invoke-GateGit $f.repo @('commit', '-q', '-m', 'tracker reconcile')

        $blocked = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $blocked.decision | Should -Be 'block'
        $blocked.reason | Should -Be 'degraded-evidence-needs-ack'
        $blocked.message | Should -Match 'TRACKER-ONLY RECONCILE ACCEPTED' -Because 'the ack ASK must carry the reused-evidence fact'
        $blocked.message | Should -Match '--ack-degraded r1'

        $ack = [pscustomobject]@{ authorized_by = 'Alon'; rationale = 'partial assurance accepted for the tracker-only reconcile scenario' }
        $allowed = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main' -DegradedAcknowledgement $ack
        $allowed.decision | Should -Be 'allow'
        $allowed.reason | Should -Be 'degraded-evidence-acknowledged'
        $allowed.message | Should -Match 'TRACKER-ONLY RECONCILE ACCEPTED' -Because 'the recorded ALLOW must carry it too'
    }

    It 'treats a LEGACY record (no labels) as unverified independence -> needs ack (conservative)' {
        $f = New-FreshRepoWithRun 'tier-legacy' $null
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $d.decision | Should -Be 'block'
        $d.reason | Should -Be 'degraded-evidence-needs-ack'
        $d.evidence_labels.independence | Should -Be 'unverified'
    }

    It 'a malformed ack (missing rationale) is ignored - the ack is never implicit' {
        $f = New-FreshRepoWithRun 'tier-badack' ([pscustomobject]@{ completeness = 'partial'; independence = 'independent'; budget = 'normal' })
        $bad = [pscustomobject]@{ authorized_by = 'Alon'; rationale = '' }
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main' -DegradedAcknowledgement $bad
        $d.decision | Should -Be 'block'
        $d.reason | Should -Be 'degraded-evidence-needs-ack'
    }

    It 'the promotion writer carries the evidence labels onto the durable record' {
        $f = New-FeatureRepo 'promo-labels'
        $treeId = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $f.repo).tree_id
        $labels = [pscustomobject]@{ completeness = 'partial'; independence = 'same-host'; budget = 'time-extended' }
        $promoted = Add-ContinuousCoReviewNavigatorPassRunRecord -RepoRoot $f.repo -RunId 'promo1' -TreeId $treeId -TrunkName 'main' -EvidenceLabels $labels
        $promoted | Should -Be 'promo1'
        $rec = Get-Content -LiteralPath (Join-Path $f.repo '.specrew/review/inline/promo1/review-run.json') -Raw | ConvertFrom-Json
        $rec.evidence_labels.completeness | Should -Be 'partial'
        $rec.evidence_labels.independence | Should -Be 'same-host'
        $rec.evidence_labels.budget | Should -Be 'time-extended'
    }
}
