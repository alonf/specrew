#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W34-B (2026-08-20): who wrote the verdict is OBSERVED, never declared.
#
# W31 checks the cited run is complete, current, valid and a reviewed outcome. W33 checks it examined
# code. Neither asks who wrote the verdict, and that gap produced the same record twice on two
# projects: specrew beta3 on 2026-08-17 (the implementing session wrote its own 13 task verdicts and
# an overall `accepted`) and KeyContextAI on 2026-08-19. Only the second is caught today, because its
# cited run was partial and the store says so. The first has genuine evidence, and a clean run plus an
# implementer-authored verdict passes every check that exists. DRIFT-199-I001-037 recorded the
# signature once already and only the campaign-evidence half was fixed.
#
# The load-bearing property here is that the fact is minted from what the hook WATCHED, never from
# what the writing agent says about itself - an `authored_by` field in review.md would be this same
# class one level up. 'a declaration inside the record changes nothing' is the case that pins it.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')

    $script:ReviewPath = 'specs/001-thing/iterations/001/review.md'

    function script:New-AuthorshipProject {
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w34-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
        return $root
    }
    function script:Observe {
        param(
            [Parameter(Mandatory)][string]$Root,
            [Parameter(Mandatory)][string]$Session,
            [string]$HostKind = 'claude',
            [Parameter(Mandatory)][string[]]$Paths
        )
        # W37: observations now carry HOW the turn was attributed. These cases model a session whose
        # writes were exactly attributed, which is what they were always meant to describe.
        Write-SpecrewReviewAuthorshipObservation -ProjectRoot $Root -HostKind $HostKind -SessionId $Session -ChangedPaths $Paths -AttributionMode 'exact-turn'
        # Observations carry a UTC timestamp and the "source at or before the write" rule compares
        # them, so two observations inside the same tick would be indistinguishable. One tick apart
        # is enough and keeps the suite deterministic without a clock port.
        Start-Sleep -Milliseconds 5
    }
    function script:StateOf {
        param([Parameter(Mandatory)][string]$Root)
        return [string](Get-SpecrewReviewAuthorship -ProjectRoot $Root -ReviewPath $script:ReviewPath).state
    }
}

Describe 'W34-B the observed authorship of a review record' {
    It 'reads unattributed when nothing watched the record being written' {
        # An older record, another host, or a hook that never fired. NOT the same as clean - which is
        # why the validator reports this state out loud instead of staying silent.
        $root = New-AuthorshipProject
        try { StateOf -Root $root | Should -Be 'unattributed' }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'reads implementing-session when the writer had already written source' {
        # The specrew beta3 shape: one session writes the code, then writes its own verdicts on it.
        $root = New-AuthorshipProject
        try {
            Observe -Root $root -Session 'sess-a' -Paths @('src/Engine.cs')
            Observe -Root $root -Session 'sess-a' -Paths @($script:ReviewPath)
            StateOf -Root $root | Should -Be 'implementing-session'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'counts partial authorship, because judging your own output is the concern' {
        $root = New-AuthorshipProject
        try {
            Observe -Root $root -Session 'sess-a' -Paths @('src/One.cs')
            Observe -Root $root -Session 'sess-b' -Paths @('src/Two.cs', 'src/Three.cs')
            Observe -Root $root -Session 'sess-a' -Paths @($script:ReviewPath)
            StateOf -Root $root | Should -Be 'implementing-session'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'reads independent-session when a different session wrote the source' {
        $root = New-AuthorshipProject
        try {
            Observe -Root $root -Session 'sess-code' -Paths @('src/Engine.cs')
            Observe -Root $root -Session 'sess-review' -Paths @($script:ReviewPath)
            StateOf -Root $root | Should -Be 'independent-session'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'does not count source first written AFTER the record, which the record cannot have judged' {
        $root = New-AuthorshipProject
        try {
            Observe -Root $root -Session 'sess-a' -Paths @($script:ReviewPath)
            Observe -Root $root -Session 'sess-a' -Paths @('src/Engine.cs')
            StateOf -Root $root | Should -Be 'independent-session'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'treats a record-only session as independent, since records are not source' {
        # Parity with W33's classifier: specs/, docs/, dot-directories and .md are records. If the two
        # rules ever diverge, a session could author code this one cannot see.
        $root = New-AuthorshipProject
        try {
            Observe -Root $root -Session 'sess-a' -Paths @('specs/001-thing/spec.md', 'docs/guide.md', '.specrew/config.yml')
            Observe -Root $root -Session 'sess-a' -Paths @($script:ReviewPath)
            StateOf -Root $root | Should -Be 'independent-session'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'ignores a declaration written inside the record itself' {
        # THE LOAD-BEARING CASE. An agent that writes `authored_by: independent-review` into review.md
        # is making a claim about authority about itself - the same class one level up. The fact comes
        # from what the hook watched, so the file's own contents move nothing.
        $root = New-AuthorshipProject
        try {
            New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-thing/iterations/001') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root $script:ReviewPath) -Encoding UTF8 -Value @(
                '# Review: Iteration 001', 'authored_by: independent-review', 'reviewer: not-the-implementer')
            Observe -Root $root -Session 'sess-a' -Paths @('src/Engine.cs')
            Observe -Root $root -Session 'sess-a' -Paths @($script:ReviewPath)
            StateOf -Root $root | Should -Be 'implementing-session'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'records nothing for a session id it never got, rather than inventing an owner' {
        $root = New-AuthorshipProject
        try {
            Write-SpecrewReviewAuthorshipObservation -ProjectRoot $root -HostKind 'claude' -SessionId '' -ChangedPaths @($script:ReviewPath)
            StateOf -Root $root | Should -Be 'unattributed'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'survives a damaged observation file without throwing on a Stop path' {
        # This runs inside the hook. A corrupt file must degrade to `unattributed`, never take a stop
        # down with it.
        $root = New-AuthorshipProject
        try {
            Set-Content -LiteralPath (Get-SpecrewReviewAuthorshipPath -ProjectRoot $root) -Value 'not json' -Encoding UTF8
            { Observe -Root $root -Session 'sess-a' -Paths @($script:ReviewPath) } | Should -Not -Throw
            StateOf -Root $root | Should -Be 'independent-session'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'keeps separate records per iteration' {
        $root = New-AuthorshipProject
        try {
            Observe -Root $root -Session 'sess-a' -Paths @('src/Engine.cs')
            Observe -Root $root -Session 'sess-a' -Paths @('specs/001-thing/iterations/002/review.md')
            StateOf -Root $root | Should -Be 'unattributed'
            [string](Get-SpecrewReviewAuthorship -ProjectRoot $root -ReviewPath 'specs/001-thing/iterations/002/review.md').state |
                Should -Be 'implementing-session'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W37 a source-writer fact is not minted from what happens to be dirty' {
    # Surfaced by the KeyContextAI walk: `review-authored-by-implementer` fired on a session that wrote
    # no product code. A SessionStart redeploy rewrote 15 files under that project's deployed copy of
    # Specrew's runtime at 09:42 and they stayed dirty all session, and in degraded-worktree mode the
    # observation minted a source-writer fact from dirty state rather than from what the turn wrote.
    #
    # conformance-turn-delta.ps1 already computes the signal that names this - and its only consumer
    # outside that file picks a display label. A computed control decided wording while a FACTUAL
    # assertion about who wrote what never consulted it.

    It 'mints nothing at all when attribution is degraded' {
        $root = New-AuthorshipProject
        try {
            Write-SpecrewReviewAuthorshipObservation -ProjectRoot $root -HostKind 'claude' -SessionId 'sess-a' `
                -ChangedPaths @('src/Engine.cs', $script:ReviewPath) -AttributionMode 'degraded-worktree'
            StateOf -Root $root | Should -Be 'unattributed' -Because 'unknown is the honest answer when attribution is unavailable'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'THE WALK SHAPE: a redeploy left dirty in a degraded turn mints nothing' {
        # Exactly what happened: a SessionStart redeploy rewrote 15 files under the project's deployed
        # copy of Specrew's runtime and they sat dirty all session, while the session itself wrote only
        # governance artifacts. The attribution mode is what covers this - the paths were never what the
        # turn WROTE - so nothing is minted and the record stays unattributed.
        #
        # An earlier version of this case asserted a path exclusion for scripts/internal/ instead. That
        # exclusion was reverted: the same predicate feeds W33's coverage classifier, and in the one
        # repository where those paths ARE the product it recounted a real review from 17 source paths
        # to 9. Attribution is the honest fix; the path rule was quietly wrong.
        $root = New-AuthorshipProject
        try {
            Write-SpecrewReviewAuthorshipObservation -ProjectRoot $root -HostKind 'claude' -SessionId 'sess-gov' `
                -AttributionMode 'degraded-worktree' -ChangedPaths @(
                    $script:ReviewPath,
                    'scripts/internal/continuous-co-review/review-authority-core.ps1',
                    'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
            StateOf -Root $root | Should -Be 'unattributed' -Because 'dirty state is not what the session wrote'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'treats an unstated attribution mode as degraded' {
        # FAIL-CLOSED, inverting W33's posture on purpose: a caller that does not say how it attributed
        # cannot support a claim about who wrote what.
        $root = New-AuthorshipProject
        try {
            Write-SpecrewReviewAuthorshipObservation -ProjectRoot $root -HostKind 'claude' -SessionId 'sess-a' `
                -ChangedPaths @('src/Engine.cs', $script:ReviewPath)
            StateOf -Root $root | Should -Be 'unattributed'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'GENERAL PROPERTY: no source-writer fact exists while attribution is degraded' {
        # Not just the verdict - the stored fact itself must be absent, so a later reader cannot derive
        # anything from it either.
        $root = New-AuthorshipProject
        try {
            Write-SpecrewReviewAuthorshipObservation -ProjectRoot $root -HostKind 'claude' -SessionId 'sess-a' `
                -ChangedPaths @('src/Engine.cs') -AttributionMode 'degraded-worktree'
            $statePath = Get-SpecrewReviewAuthorshipPath -ProjectRoot $root
            if (Test-Path -LiteralPath $statePath -PathType Leaf) {
                $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
                $sources = if ($state.PSObject.Properties['source_sessions']) { @($state.source_sessions.PSObject.Properties) } else { @() }
                @($sources).Count | Should -Be 0
            }
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'still mints normally when attribution is exact' {
        # The fix must not gut W34-B: an exactly-attributed session that writes code is still an
        # implementing session.
        $root = New-AuthorshipProject
        try {
            Observe -Root $root -Session 'sess-a' -Paths @('src/Engine.cs')
            Observe -Root $root -Session 'sess-a' -Paths @($script:ReviewPath)
            StateOf -Root $root | Should -Be 'implementing-session'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
