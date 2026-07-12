#requires -Version 7.0
# Codex escalation fixes (2026-07-08, maintainer-approved repair path):
#   f1 - a review must NEVER run blind of design context silently: the resolver gains durable
#        fallbacks (.specrew/start-context.json session_state -> single unambiguous specs/*), and an
#        EMPTY resolution is RECORDED (status.design_context='empty'), told to the reviewer (prompt
#        note), and DEGRADES the run (completeness=partial -> the T094 ack tier).
#   f2 - the partial-findings harvest NORMALIZES every JSONL line into the FindingsResult ITEM schema
#        (defaults for missing/invalid fields, source_run_id forced, disposition/resolution forced
#        open/unresolved) - validated here against the REAL schema.

BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
    $env:SPECREW_MODULE_PATH = $script:RepoRoot
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1')
    $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'

    function script:New-TempGitRepo {
        param([switch]$WithSpec, [switch]$WithStartContext, [switch]$WithFeatureJson)
        $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('f1f2-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        & git -C $repo init -q 2>&1 | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'app.txt') -Value 'content' -Encoding UTF8
        if ($WithSpec) {
            New-Item -ItemType Directory -Path (Join-Path $repo 'specs/042-widget') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'specs/042-widget/spec.md') -Value '# widget spec' -Encoding UTF8
        }
        if ($WithStartContext) {
            New-Item -ItemType Directory -Path (Join-Path $repo '.specrew') -Force | Out-Null
            ([pscustomobject]@{ schema = 'v2'; session_state = [pscustomobject]@{ feature_ref = '042-widget' } } | ConvertTo-Json -Depth 5) |
                Set-Content -LiteralPath (Join-Path $repo '.specrew/start-context.json') -Encoding UTF8
        }
        if ($WithFeatureJson) {
            New-Item -ItemType Directory -Path (Join-Path $repo '.specify') -Force | Out-Null
            ([pscustomobject]@{ feature_directory = 'specs/042-widget' } | ConvertTo-Json) |
                Set-Content -LiteralPath (Join-Path $repo '.specify/feature.json') -Encoding UTF8
        }
        & git -C $repo -c user.name='t' -c user.email='t@t.local' add -A 2>&1 | Out-Null
        & git -C $repo -c user.name='t' -c user.email='t@t.local' commit -q -m seed 2>&1 | Out-Null
        return $repo
    }
}

Describe 'f1: design-context resolution has durable fallbacks' {

    It 'resolves via start-context.json session_state when feature.json is missing (the fresh-clone case)' {
        $repo = script:New-TempGitRepo -WithSpec -WithStartContext
        try {
            $ctx = @(Resolve-ContinuousCoReviewWorktreeDesignContext -RepoRoot $repo)
            $ctx | Should -Contain 'specs/042-widget/spec.md'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'resolves a SINGLE unambiguous specs/*/spec.md as the last resort' {
        $repo = script:New-TempGitRepo -WithSpec
        try {
            $ctx = @(Resolve-ContinuousCoReviewWorktreeDesignContext -RepoRoot $repo)
            $ctx | Should -Contain 'specs/042-widget/spec.md'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'still prefers feature.json when present' {
        $repo = script:New-TempGitRepo -WithSpec -WithFeatureJson
        try {
            @(Resolve-ContinuousCoReviewWorktreeDesignContext -RepoRoot $repo) | Should -Contain 'specs/042-widget/spec.md'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'f1: an empty design context is recorded, told to the reviewer, and degrades the run' {

    It 'the slim prompt states the gap honestly when -DesignContextEmpty' {
        $prompt = Get-ContinuousCoReviewSlimPrompt -RunId 'x' -DesignContextEmpty
        $prompt | Should -Match 'NO DESIGN CONTEXT RESOLVED'
        $prompt | Should -Match '(?i)RAISE the missing design context itself as a finding'
        (Get-ContinuousCoReviewSlimPrompt -RunId 'x') | Should -Not -Match 'NO DESIGN CONTEXT RESOLVED'
    }

    It 'a run with no resolvable context records design_context=empty and completeness=partial (the T094 ack tier)' {
        $repo = script:New-TempGitRepo   # no spec, no start-context, no feature.json
        try {
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith {
                [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' }
            }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"f1-run","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/r1') -RunId 'f1-run' -TimeoutSeconds 60
            [string]$st.status | Should -Be 'done'
            [string]$st.design_context | Should -Be 'empty'
            [string]$st.completeness | Should -Be 'partial' -Because 'a blind-of-design review is never silent full evidence (f1)'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a run WITH resolvable context records design_context=resolved and stays full' {
        $repo = script:New-TempGitRepo -WithSpec -WithStartContext
        try {
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith {
                [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' }
            }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"f1-run2","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/r2') -RunId 'f1-run2' -TimeoutSeconds 60
            [string]$st.design_context | Should -Be 'resolved'
            [string]$st.completeness | Should -Be 'full'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'T034b (reuse of Devin cca79708): explicit design-context refs must ALL resolve, else FAIL before reviewer execution (DEC-200-I004-006)' {

    It 'MIXED valid+invalid explicit refs FAIL with design-context-unresolved; the reviewer is NEVER invoked' {
        $repo = script:New-TempGitRepo -WithSpec   # specs/042-widget/spec.md is a real (valid) ref
        try {
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith { [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' } }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith { [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"x","status":"no_findings","findings":[]}'; stderr = ''; telemetry = $null } }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/dc-mixed') -RunId 'dc-mixed' -DesignContextFiles @('specs/042-widget/spec.md', 'specs/does-not-exist.md') -TimeoutSeconds 60
            [string]$st.status | Should -Be 'failed'
            [string]$st.failure_reason | Should -Match '^design-context-unresolved'
            [string]$st.failure_reason | Should -Match 'does-not-exist\.md' -Because 'the unresolved ref must be named'
            @($st.unresolved_design_context) | Should -Contain 'specs/does-not-exist.md'
            Should -Invoke -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -Times 0 -Because 'an explicit-but-wrong ref must never yield a design-blind review'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'ALL-invalid explicit refs FAIL with design-context-unresolved; the reviewer is NEVER invoked' {
        $repo = script:New-TempGitRepo -WithSpec
        try {
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith { [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' } }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith { [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"x","status":"no_findings","findings":[]}'; stderr = ''; telemetry = $null } }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/dc-all') -RunId 'dc-all' -DesignContextFiles @('nope-a.md', 'nope-b.md') -TimeoutSeconds 60
            [string]$st.status | Should -Be 'failed'
            [string]$st.failure_reason | Should -Match '^design-context-unresolved'
            @($st.unresolved_design_context).Count | Should -Be 2
            Should -Invoke -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -Times 0
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'OMITTED design context still auto-resolves + degrades to DESIGN_CONTEXT_EMPTY (only omitted/empty degrades, never the strict-fail)' {
        $repo = script:New-TempGitRepo   # no spec: auto-resolution finds nothing -> empty degrade, NOT a strict fail
        try {
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith { [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' } }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith { [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"x","status":"no_findings","findings":[]}'; stderr = ''; telemetry = $null } }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/dc-omit') -RunId 'dc-omit' -TimeoutSeconds 60   # no -DesignContextFiles
            [string]$st.status | Should -Be 'done' -Because 'omitted input takes the DESIGN_CONTEXT_EMPTY degrade, not the strict-fail'
            [string]$st.design_context | Should -Be 'empty'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a ../ TRAVERSAL ref to an existing file OUTSIDE the repo is REJECTED (no ambient-content leak); reviewer NEVER invoked (co-review 13a8f2bd)' {
        $repo = script:New-TempGitRepo -WithSpec
        $outside = Join-Path (Split-Path -Parent $repo) ('outside-secret-' + [guid]::NewGuid().ToString('N') + '.md')
        try {
            Set-Content -LiteralPath $outside -Value '# ambient host secret' -Encoding UTF8
            $traversalRef = '../' + (Split-Path -Leaf $outside)
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith { [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' } }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith { [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"x","status":"no_findings","findings":[]}'; stderr = ''; telemetry = $null } }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/dc-trav') -RunId 'dc-trav' -DesignContextFiles @($traversalRef) -TimeoutSeconds 60
            [string]$st.status | Should -Be 'failed'
            [string]$st.failure_reason | Should -Match '^design-context-unresolved'
            Should -Invoke -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -Times 0 -Because 'a traversal ref must never yield a design-blind review leaking outside content'
        }
        finally { Remove-Item -LiteralPath $outside -Force -ErrorAction SilentlyContinue; Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a ROOTED (absolute) ref is REJECTED even when it points inside the repo (refs must be repo-relative)' {
        $repo = script:New-TempGitRepo -WithSpec
        try {
            $absoluteRef = (Join-Path $repo 'specs/042-widget/spec.md')   # absolute path to an in-repo file
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith { [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' } }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith { [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"x","status":"no_findings","findings":[]}'; stderr = ''; telemetry = $null } }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/dc-root') -RunId 'dc-root' -DesignContextFiles @($absoluteRef) -TimeoutSeconds 60
            [string]$st.status | Should -Be 'failed'
            [string]$st.failure_reason | Should -Match '^design-context-unresolved'
            Should -Invoke -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -Times 0
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a valid in-repo relative ref still PASSES the gate and the reviewer IS invoked (hardening did not break valid refs)' {
        $repo = script:New-TempGitRepo -WithSpec
        try {
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith { [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' } }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith { [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"x","status":"no_findings","findings":[]}'; stderr = ''; telemetry = $null } }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/dc-ok') -RunId 'dc-ok' -DesignContextFiles @('specs/042-widget/spec.md') -TimeoutSeconds 60
            [string]$st.status | Should -Be 'done' -Because 'a valid in-repo ref passes the gate and the run completes'
            [string]$st.design_context | Should -Be 'resolved' -Because 'the explicit valid ref is the resolved design context'
            Should -Invoke -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -Times 1 -Because 'a valid ref proceeds to the reviewer'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'an INTERMEDIATE in-repo directory JUNCTION targeting OUTSIDE the repo is REJECTED (component-wise physical containment); reviewer NEVER invoked (co-review 44760c20)' {
        if (-not $IsWindows) { Set-ItResult -Skipped -Because 'directory-junction creation is Windows-specific'; return }
        $repo = script:New-TempGitRepo -WithSpec
        $outsideDir = Join-Path (Split-Path -Parent $repo) ('outside-dir-' + [guid]::NewGuid().ToString('N'))
        $rd = Join-Path (Split-Path -Parent $repo) ('dcjn-runs-' + [guid]::NewGuid().ToString('N'))
        $linkDir = Join-Path $repo 'linkdir'
        try {
            New-Item -ItemType Directory -Path $outsideDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $outsideDir 'secret.md') -Value '# ambient host secret' -Encoding UTF8
            New-Item -ItemType Junction -Path $linkDir -Target $outsideDir | Out-Null   # in-repo junction -> OUTSIDE
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith { [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' } }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith { [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"x","status":"no_findings","findings":[]}'; stderr = ''; telemetry = $null } }
            # LEXICALLY in-repo (linkdir/secret.md) but PHYSICALLY outside via the intermediate junction.
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'dc-jn' -DesignContextFiles @('linkdir/secret.md') -TimeoutSeconds 60
            [string]$st.status | Should -Be 'failed'
            [string]$st.failure_reason | Should -Match '^design-context-unresolved'
            Should -Invoke -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -Times 0 -Because 'an intermediate directory junction to outside must never yield a design-blind review that leaks host content'
        }
        finally {
            if (Test-Path -LiteralPath $linkDir) { try { [System.IO.Directory]::Delete($linkDir) } catch { $null = $_ } }
            Remove-Item -LiteralPath $outsideDir, $rd -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'f2: the partial-findings harvest normalizes into the FindingsResult item schema' {

    BeforeEach {
        $script:wt = Join-Path ([System.IO.Path]::GetTempPath()) ('f2-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $script:wt '.review') -Force | Out-Null
    }
    AfterEach {
        Remove-Item -LiteralPath $script:wt -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'a minimal {comment} line gains every required field with schema-valid defaults' {
        Set-Content -LiteralPath (Join-Path $script:wt '.review/findings.jsonl') -Value '{"comment":"something looked off in app.txt"}' -Encoding UTF8
        $json = Get-ContinuousCoReviewHarvestedPartialResult -WorktreePath $script:wt -RawStdout '' -RunId 'f2-run'
        $r = $json | ConvertFrom-Json
        $f = @($r.findings)[0]
        $f.finding_id | Should -Be 'partial-1'
        $f.source_run_id | Should -Be 'f2-run'
        $f.severity | Should -Be 'advisory'
        $f.kind | Should -Be 'partial-harvest'
        $f.design_reference | Should -Be 'partial-review-salvage'
        $f.disposition | Should -Be 'open'
        $f.resolution.state | Should -Be 'unresolved'
    }

    It 'a rich line keeps its content but source_run_id and disposition are forced' {
        Set-Content -LiteralPath (Join-Path $script:wt '.review/findings.jsonl') -Encoding UTF8 -Value '{"finding_id":"x9","source_run_id":"SOMEONE-ELSE","location":{"path":"src/a.ps1","line_start":4,"line_end":9},"severity":"blocking","kind":"defect","design_reference":"FR-001","comment":"real issue","disposition":"resolved","resolution":{"state":"resolved"}}'
        $json = Get-ContinuousCoReviewHarvestedPartialResult -WorktreePath $script:wt -RawStdout '' -RunId 'f2-run'
        $f = @(($json | ConvertFrom-Json).findings)[0]
        $f.finding_id | Should -Be 'x9'
        $f.severity | Should -Be 'blocking'
        $f.location.path | Should -Be 'src/a.ps1'
        $f.source_run_id | Should -Be 'f2-run' -Because 'a harvested line cannot claim another run''s identity'
        $f.disposition | Should -Be 'open' -Because 'an in-flight finding is never pre-resolved by its own report'
        $f.resolution.state | Should -Be 'unresolved'
    }

    It 'an invalid severity is coerced to advisory' {
        Set-Content -LiteralPath (Join-Path $script:wt '.review/findings.jsonl') -Value '{"comment":"weird sev","severity":"catastrophic"}' -Encoding UTF8
        $json = Get-ContinuousCoReviewHarvestedPartialResult -WorktreePath $script:wt -RawStdout '' -RunId 'f2-run'
        @(($json | ConvertFrom-Json).findings)[0].severity | Should -Be 'advisory'
    }

    It 'zero/negative/inverted line numbers are normalized (contract minimum 1) - the f2 verification-round residual' {
        Set-Content -LiteralPath (Join-Path $script:wt '.review/findings.jsonl') -Encoding UTF8 -Value @(
            '{"comment":"zero line","location":{"path":"a.ps1","line_start":0,"line_end":5}}'
            '{"comment":"negative line","location":{"path":"b.ps1","line_start":-3,"line_end":-1}}'
            '{"comment":"inverted range","location":{"path":"c.ps1","line_start":9,"line_end":2}}'
        )
        $json = Get-ContinuousCoReviewHarvestedPartialResult -WorktreePath $script:wt -RawStdout '' -RunId 'f2-run'
        $obj = $json | ConvertFrom-Json
        $f = @($obj.findings)
        $f[0].location.line_start | Should -BeNullOrEmpty -Because 'line 0 violates the contract minimum of 1'
        $f[1].location.line_start | Should -BeNullOrEmpty
        $f[1].location.line_end | Should -BeNullOrEmpty
        [int]$f[2].location.line_end | Should -Be 9 -Because 'an inverted range is clamped to a valid single-line range'
        $validation = Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $obj
        $validation.Valid | Should -BeTrue -Because ('errors: ' + (@($validation.Errors) -join '; '))
    }

    It 'the harvested result VALIDATES against the real FindingsResult schema (the f2 acceptance)' {
        Set-Content -LiteralPath (Join-Path $script:wt '.review/findings.jsonl') -Encoding UTF8 -Value @(
            '{"comment":"bare note"}'
            '{"finding_id":"k1","location":{"path":"a.ps1","line_start":1,"line_end":2},"severity":"nit","kind":"style","design_reference":"IMPL-1","comment":"style nit"}'
        )
        $json = Get-ContinuousCoReviewHarvestedPartialResult -WorktreePath $script:wt -RawStdout '' -RunId 'f2-run'
        $obj = $json | ConvertFrom-Json
        $validation = Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $obj
        $validation.Valid | Should -BeTrue -Because ('the harvest must emit only schema-valid findings; errors: ' + (@($validation.Errors) -join '; '))
    }
}
