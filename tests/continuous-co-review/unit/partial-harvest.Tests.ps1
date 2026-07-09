#requires -Version 7.0
# T090/R1: Get-ContinuousCoReviewHarvestedPartialResult harvests the incremental .review/findings.jsonl prefix on
# a cut-short run (skipping a truncated trailing line), with a prose-salvage floor. The harvested result MUST be
# a SCHEMA-CONFORMANT FindingsResult (f1 / D-197-I009-001 co-review finding: no top-level completeness; salvage
# needs a non-empty design_reference and must OMIT location.path).

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' '..' 'scripts' 'internal' 'continuous-co-review' 'worktree-reviewer.ps1')
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')).Path
    $script:SchemaPath = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts/findings-result.schema.json'
}

Describe 'Get-ContinuousCoReviewHarvestedPartialResult (T090/R1)' {

    BeforeEach {
        $script:wt = Join-Path ([System.IO.Path]::GetTempPath()) ("ccr-t090-" + [guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $script:wt '.review') -Force
    }
    AfterEach {
        Remove-Item -LiteralPath $script:wt -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'harvests the clean prefix of .review/findings.jsonl, skips a truncated line, and conforms to the schema' {
        $jsonl = Join-Path $script:wt '.review/findings.jsonl'
        $f1 = '{"finding_id":"f1","source_run_id":"r1","location":{"path":"a.ps1","line_start":1,"line_end":2},"severity":"blocking","kind":"bug","design_reference":"FR-001","comment":"a real bug","disposition":"open","resolution":{"state":"unresolved","fix_evidence_ref":null,"rationale":null}}'
        $f2 = '{"finding_id":"f2","source_run_id":"r1","location":{"path":"b.ps1","line_start":null,"line_end":null},"severity":"advisory","kind":"nit","design_reference":"FR-002","comment":"a nit","disposition":"open","resolution":{"state":"unresolved","fix_evidence_ref":null,"rationale":null}}'
        $truncated = '{"finding_id":"f3","severity":"advis'   # killed mid-write
        Set-Content -LiteralPath $jsonl -Value @($f1, $f2, $truncated) -Encoding UTF8

        $json = Get-ContinuousCoReviewHarvestedPartialResult -WorktreePath $script:wt -RawStdout '' -RunId 'r1'
        $json | Should -Not -BeNullOrEmpty
        $obj = $json | ConvertFrom-Json
        $obj.status | Should -Be 'findings'
        @($obj.findings).Count | Should -Be 2   # f1 + f2; the truncated f3 is skipped, not fatal
        ($obj.PSObject.Properties.Name -contains 'completeness') | Should -BeFalse -Because 'f1: the FindingsResult schema is additionalProperties:false'
        $json | Test-Json -SchemaFile $script:SchemaPath | Should -BeTrue -Because 'f1: the harvested result must validate against the authoritative FindingsResult schema'
    }

    It 'prose-salvages with a SCHEMA-VALID salvage finding (non-empty design_reference, no location.path)' {
        $json = Get-ContinuousCoReviewHarvestedPartialResult -WorktreePath $script:wt -RawStdout 'I was reviewing the auth change and noticed a possible boundary issue before the run ended.' -RunId 'r2'
        $json | Should -Not -BeNullOrEmpty
        $obj = $json | ConvertFrom-Json
        @($obj.findings).Count | Should -Be 1
        $obj.findings[0].kind | Should -Be 'partial-unverified-notes'
        $obj.findings[0].design_reference | Should -Not -BeNullOrEmpty -Because 'f1: schema requires a non-empty design_reference'
        ($obj.findings[0].location.PSObject.Properties.Name -contains 'path') | Should -BeFalse -Because 'f1: location.path must be OMITTED, not null'
        ($obj.PSObject.Properties.Name -contains 'completeness') | Should -BeFalse
        $json | Test-Json -SchemaFile $script:SchemaPath | Should -BeTrue -Because 'f1: the salvage result must validate against the schema'
    }

    It 'returns null when there is genuinely nothing to harvest (no jsonl, no prose)' {
        $json = Get-ContinuousCoReviewHarvestedPartialResult -WorktreePath $script:wt -RawStdout '' -RunId 'r3'
        $json | Should -BeNullOrEmpty
    }
}
