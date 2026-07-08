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
