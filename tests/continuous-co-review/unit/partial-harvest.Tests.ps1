#requires -Version 7.0
# T090/R1: Get-ContinuousCoReviewHarvestedPartialResult harvests the incremental .review/findings.jsonl prefix on
# a cut-short run (skipping a truncated trailing line), with a prose-salvage floor, tagged completeness:'partial'.

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' '..' 'scripts' 'internal' 'continuous-co-review' 'worktree-reviewer.ps1')
}

Describe 'Get-ContinuousCoReviewHarvestedPartialResult (T090/R1)' {

    BeforeEach {
        $script:wt = Join-Path ([System.IO.Path]::GetTempPath()) ("ccr-t090-" + [guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $script:wt '.review') -Force
    }
    AfterEach {
        Remove-Item -LiteralPath $script:wt -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'harvests the clean prefix of .review/findings.jsonl and skips a truncated trailing line' {
        $jsonl = Join-Path $script:wt '.review/findings.jsonl'
        $f1 = '{"finding_id":"f1","severity":"blocking","kind":"bug","comment":"a real bug","disposition":"open"}'
        $f2 = '{"finding_id":"f2","severity":"advisory","kind":"nit","comment":"a nit","disposition":"open"}'
        $truncated = '{"finding_id":"f3","severity":"advis'   # the reviewer was killed mid-write
        Set-Content -LiteralPath $jsonl -Value @($f1, $f2, $truncated) -Encoding UTF8

        $json = Get-ContinuousCoReviewHarvestedPartialResult -WorktreePath $script:wt -RawStdout '' -RunId 'r1'
        $json | Should -Not -BeNullOrEmpty
        $obj = $json | ConvertFrom-Json
        $obj.completeness | Should -Be 'partial'
        $obj.status | Should -Be 'findings'
        @($obj.findings).Count | Should -Be 2   # f1 + f2; the truncated f3 is skipped, not fatal
        $obj.findings[0].finding_id | Should -Be 'f1'
        $obj.findings[1].finding_id | Should -Be 'f2'
    }

    It 'prose-salvages the reviewer reasoning when there is no structured findings file' {
        $json = Get-ContinuousCoReviewHarvestedPartialResult -WorktreePath $script:wt -RawStdout 'I was reviewing the auth change and noticed a possible boundary issue before the run ended.' -RunId 'r2'
        $json | Should -Not -BeNullOrEmpty
        $obj = $json | ConvertFrom-Json
        $obj.completeness | Should -Be 'partial'
        @($obj.findings).Count | Should -Be 1
        $obj.findings[0].kind | Should -Be 'partial-unverified-notes'
        $obj.findings[0].severity | Should -Be 'advisory'
        $obj.findings[0].comment | Should -BeLike '*UNVERIFIED reviewer notes salvaged*'
    }

    It 'returns null when there is genuinely nothing to harvest (no jsonl, no prose)' {
        $json = Get-ContinuousCoReviewHarvestedPartialResult -WorktreePath $script:wt -RawStdout '' -RunId 'r3'
        $json | Should -BeNullOrEmpty
    }
}
