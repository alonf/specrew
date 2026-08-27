#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W77 / KeyContextAI walk finding: THE SYNC'S PREFLIGHT MOVES THE TREE ITS OWN GATE THEN REFUSES AS MOVED.
#
# Measured on a real landing: partial signoff is accepted, the landing completes, the sync runs, its
# preflight demands the lint commits and the owed review.md, THOSE COMMITS MOVE THE TREE, and the
# sync's gate re-evaluates coverage against the new digest and refuses - asking the human to authorize
# the same gap a second time because the machinery moved it in between.
#
# The override is looked up with -ExpectedTargetTreeId set to the tree AT GATE TIME, so an acceptance
# captured for tree T is orphaned the moment the preflight's own commits produce T'. Landing and sync
# judge coverage independently and an acceptance spent at one does not carry to the other.
#
# Same family as DRIFT-008 and the digest race: A GATE REASONING ABOUT A DELTA THAT EXISTS BECAUSE OF
# THE GATE. The only escape was chaining commit and sync in one invocation so nothing moved in the
# window - a workaround the operator has to discover, which is not a control.
#
# THE RULE: an acceptance carries across a RECORDS-ONLY delta, and only that. The human accepted a
# coverage gap; records moving does not change the gap, because no source moved. If SOURCE moved
# between the acceptance and the sync, the gap is genuinely different and a fresh acceptance is right.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1')

    function script:New-CarryFixture {
        # A real repo, because the rule is a tree diff and a fixture without an object store would
        # exercise only the arm that was never broken.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w77-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/199-feature/iterations/001') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'src/Engine.cs') -Value 'class Engine { }' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $root 'specs/199-feature/iterations/001/review.md') -Value '# Review' -Encoding UTF8
        & git init -q -b 199-feature $root 2>&1 | Out-Null
        & git -C $root add -A 2>&1 | Out-Null
        & git -C $root -c user.name=t -c user.email=t@t commit -q -m init 2>&1 | Out-Null
        return $root
    }
    function script:Get-TreeId { param([string]$Root) return (& git -C $Root rev-parse 'HEAD^{tree}').Trim() }
    function script:Write-Override {
        param([string]$Root, [string]$TreeId, [string]$CampaignId = 'cmp-199-feature-i001')
        $dir = Join-Path $Root '.specrew/review/signoff-gate/override-authorizations'
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $requestId = 'override-' + $TreeId.Substring(0, 24)
        ([pscustomobject]@{
                schema_version = '1.0'; fact_type = 'review-signoff-partial-override'; authority_kind = 'human'
                request_id = $requestId; target_tree_id = $TreeId; campaign_id = $CampaignId
                rationale = 'accepted for the walk'; verdict_text = 'approved for partial review signoff - accepted for the walk'
                observed_at = '2026-08-27T12:00:00.0000000+00:00'
            } | ConvertTo-Json -Compress) | Set-Content -LiteralPath (Join-Path $dir ($requestId + '.json')) -Encoding UTF8
        return $requestId
    }
}

Describe 'W77 an acceptance survives the commits the gate''s own preflight demanded' {
    It 'RED-FIRST: carries across a RECORDS-ONLY delta - the preflight''s own doing' {
        $root = New-CarryFixture
        try {
            $accepted = Get-TreeId -Root $root
            $null = Write-Override -Root $root -TreeId $accepted
            # Exactly what the preflight demands: the owed record, committed.
            Set-Content -LiteralPath (Join-Path $root 'specs/199-feature/iterations/001/review.md') -Value "# Review`n`nThe landing completed." -Encoding UTF8
            & git -C $root add -A 2>&1 | Out-Null
            & git -C $root -c user.name=t -c user.email=t@t commit -q -m 'owed record' 2>&1 | Out-Null
            $now = Get-TreeId -Root $root
            $now | Should -Not -Be $accepted -Because 'precondition: the preflight''s commit really did move the tree'

            $carried = Get-SpecrewCarriedSignoffOverrideAuthorization -ProjectRoot $root -CurrentTreeId $now `
                -CampaignId 'cmp-199-feature-i001' -FeatureId '199-feature'
            $carried | Should -Not -BeNullOrEmpty -Because 'the human accepted a coverage gap, and records moving does not change that gap'
            [string]$carried.target_tree_id | Should -Be $accepted
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'does NOT carry across a SOURCE delta, because that is a different gap' {
        $root = New-CarryFixture
        try {
            $accepted = Get-TreeId -Root $root
            $null = Write-Override -Root $root -TreeId $accepted
            Set-Content -LiteralPath (Join-Path $root 'src/Engine.cs') -Value 'class Engine { void Added() { } }' -Encoding UTF8
            & git -C $root add -A 2>&1 | Out-Null
            & git -C $root -c user.name=t -c user.email=t@t commit -q -m 'source' 2>&1 | Out-Null
            $now = Get-TreeId -Root $root

            Get-SpecrewCarriedSignoffOverrideAuthorization -ProjectRoot $root -CurrentTreeId $now `
                -CampaignId 'cmp-199-feature-i001' -FeatureId '199-feature' |
                Should -BeNullOrEmpty -Because 'source moving is a genuinely different coverage gap and deserves a fresh acceptance'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'does not carry an acceptance from ANOTHER campaign' {
        $root = New-CarryFixture
        try {
            $accepted = Get-TreeId -Root $root
            $null = Write-Override -Root $root -TreeId $accepted -CampaignId 'cmp-other-i001'
            Set-Content -LiteralPath (Join-Path $root 'specs/199-feature/iterations/001/review.md') -Value "# Review`n`nmoved" -Encoding UTF8
            & git -C $root add -A 2>&1 | Out-Null
            & git -C $root -c user.name=t -c user.email=t@t commit -q -m 'records' 2>&1 | Out-Null
            Get-SpecrewCarriedSignoffOverrideAuthorization -ProjectRoot $root -CurrentTreeId (Get-TreeId -Root $root) `
                -CampaignId 'cmp-199-feature-i001' -FeatureId '199-feature' |
                Should -BeNullOrEmpty -Because 'an acceptance is for the campaign it was typed against'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the gate wiring consults the carry before refusing' {
        # The structural half: the rule must be reached from the path that refuses, or it is a helper
        # nobody calls - which is the class this log has recorded ten times.
        $wiring = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/signoff-gate-wiring.ps1') -Raw -Encoding UTF8
        $wiring | Should -Match 'Get-SpecrewCarriedSignoffOverrideAuthorization' -Because 'the refusal path is where the carry has to be asked'
        $carryIndex = $wiring.IndexOf('Get-SpecrewCarriedSignoffOverrideAuthorization')
        $throwIndex = $wiring.IndexOf('review-signoff refused')
        $carryIndex | Should -BeGreaterThan -1
        $carryIndex | Should -BeLessThan $throwIndex -Because 'asked before the refusal, not after it'
        # AND THE CALL MUST BE REACHABLE. The first cut asserted only that the call EXISTS, so a
        # mutation replacing its guard with `if ($false)` left the text in place and the case green -
        # a structural assertion that cannot see a disabled call, which is the inert-control class
        # inside a test again. The guard is now required to branch on the thing it exists to
        # supplement, so a constant-false guard is visible as a missing reference.
        #
        # STATED PLAINLY: this is still structural. It proves the call is wired and reachable, not
        # that the gate allows - the three cases above prove the rule itself against real git trees,
        # and a full wiring fixture would need an entire campaign store to add little beyond them.
        $guardLine = @($wiring -split "`r?`n" | Where-Object { $_ -match 'Get-SpecrewCarriedSignoffOverrideAuthorization -ErrorAction' })
        @($guardLine).Count | Should -BeGreaterThan 0
        $guardLine[0] | Should -Match '\$capturedOverride' -Because 'the carry runs only when the exact-tree lookup found nothing, and a guard that names nothing is a disabled one'
    }
}
