# P-145 step 1 + 1b — the producer -> signoff-gate end-to-end. The P-145 review flagged that NO test exercised
# promotion -> gate (the divergence bug shipped because the only gate test hand-fed the gate its OWN digest and never
# ran the real promotion). These tests run the REAL producer (Add-...PassRunRecord) against the REAL gate
# (Get-...SignoffGateDecision), proving: a DIGEST promotion is fresh, a HEAD-tree promotion on a divergent tree is
# stale (the bug guard), and the 1b promotable-pass decision is correct.

BeforeAll {
    $script:ccr = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\scripts\internal\continuous-co-review')).Path
    . (Join-Path $script:ccr '_load.ps1')
    . (Join-Path $script:ccr 'continuous-co-review-navigator.ps1')
    . (Join-Path $script:ccr 'co-review-service.ps1')

    function New-GateFx {
        # A feature branch off main with one commit. -Divergent ALSO tracks a .specrew file (the self-host case),
        # which the digest STRIPS but the HEAD-tree keeps -> the two identities diverge.
        param([switch]$Divergent)
        $fx = Join-Path ([System.IO.Path]::GetTempPath()) ('ccr-gate-' + [System.Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $fx -Force | Out-Null
        Push-Location $fx
        try {
            git init -b main -q
            git -c user.email=t@t -c user.name=t commit --allow-empty -q -m base
            git checkout -q -b feature
            'code' | Set-Content (Join-Path $fx 'app.txt')
            git add app.txt
            if ($Divergent) {
                New-Item -ItemType Directory -Path (Join-Path $fx '.specrew') -Force | Out-Null
                'runtime' | Set-Content (Join-Path $fx '.specrew\state.json')
                git add -f .specrew/state.json
            }
            git -c user.email=t@t -c user.name=t commit -q -m feature
        }
        finally { Pop-Location }
        return $fx
    }
}

Describe 'signoff gate: the DIGEST promotion is fresh; the HEAD-tree (the bug) is stale' {
    It 'a digest-promoted pass is allow / fresh-and-covered' {
        $fx = New-GateFx
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $fx
        $null = Add-ContinuousCoReviewNavigatorPassRunRecord -RepoRoot $fx -RunId 'r1' -TreeId $d.tree_id -TrunkName 'main' -EvidenceLabels ([pscustomobject]@{ completeness = 'full'; independence = 'independent'; budget = 'normal' }) -Now ([datetime]::UtcNow)
        $dec = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $fx -TrunkName 'main'
        $dec.decision | Should -Be 'allow'
        $dec.reason | Should -Be 'fresh-and-covered'
    }

    It 'on a divergent tree the digest != the HEAD-tree, and the HEAD-tree promotion is block / stale (the bug guard)' {
        $fx = New-GateFx -Divergent
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $fx
        $head = Get-ContinuousCoReviewWorktreeIdentity -RepoRoot $fx
        $d.tree_id | Should -Not -Be $head
        $null = Add-ContinuousCoReviewNavigatorPassRunRecord -RepoRoot $fx -RunId 'r1' -TreeId $head -TrunkName 'main' -EvidenceLabels ([pscustomobject]@{ completeness = 'full'; independence = 'independent'; budget = 'normal' }) -Now ([datetime]::UtcNow)
        $dec = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $fx -TrunkName 'main'
        $dec.decision | Should -Be 'block'
        $dec.reason | Should -Be 'stale-co-review-evidence'
    }

    It 'on the SAME divergent tree the DIGEST promotion is fresh (the fix lands where the bug lived)' {
        $fx = New-GateFx -Divergent
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $fx
        $null = Add-ContinuousCoReviewNavigatorPassRunRecord -RepoRoot $fx -RunId 'r1' -TreeId $d.tree_id -TrunkName 'main' -EvidenceLabels ([pscustomobject]@{ completeness = 'full'; independence = 'independent'; budget = 'normal' }) -Now ([datetime]::UtcNow)
        $dec = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $fx -TrunkName 'main'
        $dec.decision | Should -Be 'allow'
    }
}

Describe '1b promotable-pass decision: the canonical producer gate (shared by reap + inline door)' {
    It 'accepts an affirmative pass, rejects blocking / stub / needs-work / not-ok' {
        (Test-ContinuousCoReviewVerdictIsPromotablePass -Verdict ([pscustomobject]@{ ok = $true; blocking = $false; is_stub = $false; disposition = 'pass' })) | Should -BeTrue
        (Test-ContinuousCoReviewVerdictIsPromotablePass -Verdict ([pscustomobject]@{ ok = $true; blocking = $false; is_stub = $false; disposition = 'no_findings' })) | Should -BeTrue
        (Test-ContinuousCoReviewVerdictIsPromotablePass -Verdict ([pscustomobject]@{ ok = $true; blocking = $true; is_stub = $false; disposition = 'pass' })) | Should -BeFalse
        (Test-ContinuousCoReviewVerdictIsPromotablePass -Verdict ([pscustomobject]@{ ok = $true; blocking = $false; is_stub = $true; disposition = 'pass' })) | Should -BeFalse
        (Test-ContinuousCoReviewVerdictIsPromotablePass -Verdict ([pscustomobject]@{ ok = $true; blocking = $false; is_stub = $false; disposition = 'needs-work' })) | Should -BeFalse
        (Test-ContinuousCoReviewVerdictIsPromotablePass -Verdict ([pscustomobject]@{ ok = $false })) | Should -BeFalse
    }

    It 'a real no_findings result.out extracts to a promotable verdict (the inline-door path)' {
        $rd = Join-Path ([System.IO.Path]::GetTempPath()) ('ccr-rd-' + [System.Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $rd -Force | Out-Null
        '{"schema_version":"1.0","run_id":"r1","status":"no_findings","findings":[]}' | Set-Content (Join-Path $rd 'result.out')
        $v = ConvertFrom-ContinuousCoReviewNavigatorVerdict -ResultPath (Join-Path $rd 'result.out')
        (Test-ContinuousCoReviewVerdictIsPromotablePass -Verdict $v) | Should -BeTrue
    }
}
