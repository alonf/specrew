#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W47 (2026-08-23): THE NO-CODE-WITHOUT-APPROVAL PROMISE GETS MECHANICAL ENFORCEMENT.
#
# On the KeyContextAI walk a Copilot/gpt-5.6-sol session committed product source (7 files) while
# last_authorized_boundary was `tasks`, the hardening gate was blocked, and no before-implement
# crossing had been minted. Nothing fired: state-advance-without-verdict watches the STATE, and the
# state never advanced - the session wrote code where it stood. Gate checks fire at sync time, and a
# session that never runs the sync never meets them. Eight days hardening the evidence path, and the
# flagship guarantee rested on agent compliance alone.
#
# The producer-level fix, same principle as W12: detect product-source changes (the shared source
# classifier already defines "product") made while the authorized boundary is pre-implement. FAIL at
# validation; refuse at the stop/conformance layer. These cases drive the REAL validator against a
# DOWNSTREAM-SHAPED fixture (method rule 5: no Specrew.psd1 at the root), through the real git
# history and the real boundary ledger.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')

    function script:Invoke-Git {
        param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string[]]$GitArgs)
        $out = & git -C $Root @GitArgs 2>&1
        if ($LASTEXITCODE -ne 0) { throw ("git {0} failed: {1}" -f ($GitArgs -join ' '), ($out -join '; ')) }
        return $out
    }

    function script:New-GovernedProjectAtTasks {
        # The walk's exact shape: a governed project whose ledger says tasks, holding real source
        # committed AFTER the tasks authorization. Every fact is real - real git history, real
        # start-context, a real verdict-history entry anchored to a real commit.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w47-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-fixture') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'specs/001-fixture/spec.md') -Value "# Spec`n" -Encoding UTF8
        Invoke-Git -Root $root -GitArgs @('init', '--quiet') | Out-Null
        Invoke-Git -Root $root -GitArgs @('config', 'user.email', 'fixture@example.invalid') | Out-Null
        Invoke-Git -Root $root -GitArgs @('config', 'user.name', 'Fixture') | Out-Null
        Invoke-Git -Root $root -GitArgs @('add', '-A') | Out-Null
        Invoke-Git -Root $root -GitArgs @('commit', '--quiet', '-m', 'lifecycle records through tasks') | Out-Null
        $anchor = ([string](Invoke-Git -Root $root -GitArgs @('rev-parse', 'HEAD'))).Trim()

        $ctx = [ordered]@{
            schema               = 'v2'
            feature_path         = (Join-Path $root 'specs/001-fixture')
            session_state        = [ordered]@{ active = $true; boundary_type = 'tasks'; feature_ref = '001-fixture'; iteration_number = '001'; recorded_at = '2026-08-23T00:00:00Z' }
            boundary_enforcement = [ordered]@{
                enabled = $true
                last_authorized_boundary = 'tasks'
                pending_next_boundary = $null
                verdict_history = @([ordered]@{
                        from_boundary = 'plan'; to_boundary = 'tasks'
                        verdict_text = 'approved for tasks'; authorizing_human = 'unattributed'
                        recorded_at = '2026-08-23T00:00:00Z'; auth_commit_hash = $anchor
                        evidence_source = 'hook-captured-from-transcript'; kind = 'standard'
                    })
                bypass_history = @()
            }
        }
        [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'),
            ($ctx | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
        return [pscustomobject]@{ Root = $root; Anchor = $anchor }
    }

    function script:Add-SourceCommit {
        param([Parameter(Mandatory)][string]$Root)
        New-Item -ItemType Directory -Path (Join-Path $Root 'src') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $Root 'src/layout.ts') -Value 'export const layout = () => 1;' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $Root 'src/autocorrect.ts') -Value 'export const fix = () => 2;' -Encoding UTF8
        Invoke-Git -Root $Root -GitArgs @('add', '-A') | Out-Null
        Invoke-Git -Root $Root -GitArgs @('commit', '--quiet', '-m', 'feat(layout): product source') | Out-Null
    }

    function script:Copy-SpecrewBundleInto {
        param([Parameter(Mandatory)][string]$Root)
        New-Item -ItemType Directory -Path (Join-Path $Root 'scripts/internal') -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review') `
            -Destination (Join-Path $Root 'scripts/internal/continuous-co-review') -Recurse -Force
        Set-Content -LiteralPath (Join-Path $Root 'scripts/internal/continuous-co-review/.specrew-runtime.json') -Value '{"files":[]}' -Encoding UTF8
    }

    function script:Invoke-Validator {
        param([Parameter(Mandatory)][string]$Root)
        $output = @(& pwsh -NoProfile -File $script:Validator -ProjectPath $Root 2>&1 | ForEach-Object { [string]$_ })
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
    }
}

Describe 'W47 ACCEPTANCE through the real validator' {
    It 'a source commit at tasks with no before-implement verdict FAILS, naming the missing verdict' {
        $f = New-GovernedProjectAtTasks
        try {
            Add-SourceCommit -Root $f.Root
            $run = Invoke-Validator -Root $f.Root
            $run.ExitCode | Should -Not -Be 0
            $run.Text | Should -Match 'source-without-implement-authorization'
            $run.Text | Should -Match 'approved for before-implement' -Because 'the refusal must name the missing verdict, not just the violation'
            $run.Text | Should -Match 'src/layout\.ts'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the SAME commit after the verdict passes this check' {
        $f = New-GovernedProjectAtTasks
        try {
            Add-SourceCommit -Root $f.Root
            # The human's verdict, recorded through the REAL writer - not a hand-edited ledger.
            $null = Add-SpecrewBoundaryAuthorization -ProjectRoot $f.Root -CurrentBoundary 'tasks' -AuthorizedBoundary 'before-implement' `
                -AuthorizingHuman 'unattributed' -VerdictText 'approved for before-implement' `
                -EvidenceSource 'hook-captured-from-transcript'
            $run = Invoke-Validator -Root $f.Root
            $run.Text | Should -Not -Match 'source-without-implement-authorization' -Because 'the verdict is exactly what licenses the work'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'W48: a specrew update refreshing the deployed bundle does NOT fire the guard' {
        # The first downstream firing, reproduced: the refusal named scripts/internal/continuous-co-review/*
        # - Specrew's own review bundle, refreshed by the human's own governed update - as product source.
        # DRIFT-104's blind spot in the classifier's fifth consumer. Machinery is the integrity markers'
        # jurisdiction; the no-code guard watches the PRODUCT.
        $f = New-GovernedProjectAtTasks
        try {
            # The REAL bundle, as specrew update deploys it - a lone file was the first fixture's
            # lie: worktree-reviewer.ps1 dot-sources its siblings, so only a full bundle loads.
            Copy-SpecrewBundleInto -Root $f.Root
            $bundle = Join-Path $f.Root 'scripts/internal/continuous-co-review'
            Set-Content -LiteralPath (Join-Path $bundle 'hook-health-receipt.ps1') -Value '# refreshed by update' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $bundle '.specrew-runtime.json') -Value '{"files":[]}' -Encoding UTF8
            Invoke-Git -Root $f.Root -GitArgs @('add', '-A') | Out-Null
            Invoke-Git -Root $f.Root -GitArgs @('commit', '--quiet', '-m', 'chore: specrew update bundle refresh') | Out-Null
            $run = Invoke-Validator -Root $f.Root
            $run.Text | Should -Not -Match 'source-without-implement-authorization' -Because 'the human running specrew update is not the project writing product code'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'W48: a mixed commit still fires, and names only the product files' {
        $f = New-GovernedProjectAtTasks
        try {
            Copy-SpecrewBundleInto -Root $f.Root
            $bundle = Join-Path $f.Root 'scripts/internal/continuous-co-review'
            Set-Content -LiteralPath (Join-Path $bundle 'host-support-tier.ps1') -Value '# refreshed' -Encoding UTF8
            Add-SourceCommit -Root $f.Root
            $run = Invoke-Validator -Root $f.Root
            $run.Text | Should -Match 'source-without-implement-authorization'
            $run.Text | Should -Match 'src/layout\.ts'
            $run.Text | Should -Not -Match 'host-support-tier\.ps1' -Because 'the refusal must not ask the human to license Specrew''s own machinery as their product'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'W48: in the Specrew SOURCE repository the engine paths stay product' {
        # The W37 revert's whole point, preserved: here, scripts/internal/continuous-co-review IS the
        # product, and the resolver answers with the source-repo machinery list that excludes it.
        $filtered = @(Select-SpecrewProductSourcePaths -ProjectRoot $script:RepoRoot -Paths @(
                'scripts/internal/continuous-co-review/worktree-reviewer.ps1', 'src/app.ts'))
        $filtered | Should -Contain 'scripts/internal/continuous-co-review/worktree-reviewer.ps1'
        $filtered | Should -Contain 'src/app.ts'
    }

    It 'records-only commits at tasks stay clean - the classifier decides, not the diff size' {
        $f = New-GovernedProjectAtTasks
        try {
            Set-Content -LiteralPath (Join-Path $f.Root 'specs/001-fixture/plan.md') -Value "# Plan`n" -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $f.Root 'docs.md') -Value "# Notes`n" -Encoding UTF8
            Invoke-Git -Root $f.Root -GitArgs @('add', '-A') | Out-Null
            Invoke-Git -Root $f.Root -GitArgs @('commit', '--quiet', '-m', 'plan and notes') | Out-Null
            $run = Invoke-Validator -Root $f.Root
            $run.Text | Should -Not -Match 'source-without-implement-authorization' -Because 'planning at the planning stage is the process working'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W47 the shared detector, edge by edge' {
    It 'fails OPEN when the anchor commit cannot be resolved, and says so' {
        # "Could not tell" must never manufacture a violation. STATED LIMIT: a history rewrite that
        # discards the auth commit silences the check - but the ledger still names the commit, so the
        # rewrite is visible there.
        $f = New-GovernedProjectAtTasks
        try {
            $ctxPath = Join-Path $f.Root '.specrew/start-context.json'
            $ctx = Get-Content -LiteralPath $ctxPath -Raw | ConvertFrom-Json -Depth 12
            $ctx.boundary_enforcement.verdict_history[0].auth_commit_hash = ('f' * 40)
            [IO.File]::WriteAllText($ctxPath, ($ctx | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
            Add-SourceCommit -Root $f.Root
            $drift = Get-SpecrewUnauthorizedSourceDrift -ProjectRoot $f.Root
            $drift.checked | Should -BeFalse
            $drift.reason | Should -Be 'anchor-commit-unresolvable'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'sees uncommitted source too, for the live layer' {
        $f = New-GovernedProjectAtTasks
        try {
            New-Item -ItemType Directory -Path (Join-Path $f.Root 'src') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $f.Root 'src/wip.ts') -Value 'export const wip = 1;' -Encoding UTF8
            $drift = Get-SpecrewUnauthorizedSourceDrift -ProjectRoot $f.Root
            $drift.checked | Should -BeTrue
            @($drift.uncommitted_source) | Should -Contain 'src/wip.ts'
            @($drift.committed_source) | Should -BeNullOrEmpty
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'reports implementation-authorized once the ledger crosses before-implement' {
        $f = New-GovernedProjectAtTasks
        try {
            Add-SourceCommit -Root $f.Root
            $null = Add-SpecrewBoundaryAuthorization -ProjectRoot $f.Root -CurrentBoundary 'tasks' -AuthorizedBoundary 'before-implement' `
                -AuthorizingHuman 'unattributed' -VerdictText 'approved for before-implement' -EvidenceSource 'hook-captured-from-transcript'
            $drift = Get-SpecrewUnauthorizedSourceDrift -ProjectRoot $f.Root
            $drift.checked | Should -BeTrue
            $drift.pre_implement | Should -BeFalse
            $drift.reason | Should -Be 'implementation-authorized'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W47 the live conformance layer refuses on the same fact' {
    It 'the stop layer carries an unauthorized-source block that names the verdict and forbids self-authorization' {
        # The provider is Stop-hook machinery; its block pipeline is exercised live by hosts, so the
        # wiring is pinned structurally: the kind exists in the block resolution, its refusal text
        # names the verdict and the STOP instruction, and it consumes the SAME shared detector the
        # validator uses - one fact, two enforcement points, no parallel classification.
        $provider = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1') -Raw -Encoding UTF8
        $provider | Should -Match "elseif \(\`$unauthorizedSourceBlock\) \{ 'unauthorized-source' \}"
        $provider.Contains('Get-SpecrewUnauthorizedSourceDrift -ProjectRoot $projectRoot') | Should -BeTrue -Because 'the live layer and the validator must refuse on the same shared fact'
        # Anchored on the branch's own W47 comment: the same `$blockKind -eq` test also appears in the
        # advance-key resolution, and the first match there swallowed the assertion once already.
        $block = [regex]::Match($provider, "(?s)elseif \(\`$blockKind -eq 'unauthorized-source'\) \{\s*\r?\n\s*# W47.+?\r?\n            \}").Value
        $block | Should -Not -BeNullOrEmpty
        $block.Contains('STOP implementing now') | Should -BeTrue
        $block.Contains('approved for before-implement') | Should -BeTrue
        $block.Contains('do not record any authorization yourself') | Should -BeTrue
        $block.Contains('quote it') | Should -BeTrue -Because 'the licence the session believed it had is evidence about the wording, and the wording was part of this defect'
    }

    It 'the contract wording now names the checkable condition first' {
        # The contributing cause: Rule 28's dominant verbs were momentum - automatic, do not stop - and
        # the safety condition was a subordinate clause a weak model resolved against the freshest
        # approval in context. The condition is now named, checkable, and first, in both surfaces.
        $contract = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts\internal\launch-contract.ps1') -Raw -Encoding UTF8
        $contract | Should -Match '(?s)28\. \*\*Until the boundary ledger holds the human''s typed ``approved for before-implement``, no product source file is created or modified'
        $contract | Should -Match 'not the tasks verdict, not after-tasks succeeding, not a relayed go-ahead'
        $refocus = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\refocus\before-implement.md') -Raw -Encoding UTF8
        $refocus | Should -Match 'After the verdict, run . and not one source file before it'
        $refocus | Should -Match 'a go-ahead you inferred is not one the ledger recorded'
    }
}
