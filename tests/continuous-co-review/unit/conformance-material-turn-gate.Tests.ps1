#requires -Version 7.0
# T099 / FR-040 (design N3): the material-turn gate for the Stop-hook conformance parse. The per-line
# transcript JSON parse (the dominant Stop-hook cost, scales with session size) runs ONLY when the stop
# actually followed material work (the live owner-scoped turn delta), a boundary verdict is
# pending, a material forced-continue retry is in flight, or exact active-feature state has a remaining workshop
# lens whose rendered question must be validated. The old `$anySpec` trigger made EVERY stop in EVERY real project
# (any specs/*/spec.md on disk) pay the parse - trivial/conversational stops still skip it entirely.

BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
    $script:Provider = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'
    $script:Mirror = Join-Path $script:RepoRoot '.specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'
}

Describe 'T099 conformance material-turn gate (FR-040)' {

    It 'the expensive transcript parse is NOT triggered by a mere spec on disk (anySpec dropped)' {
        # Source-contract: the parse gate names boundary/material/retry plus the scoped workshop-state candidate.
        # $anySpec still feeds the cheap intake regex WHEN the parse already ran, but is not itself a trigger.
        $src = Get-Content -LiteralPath $script:Provider -Raw
        $gateLine = ($src -split "`r?`n" | Where-Object { $_ -match '^\s*if \(' -and $_ -match 'materialRetryKey' -and $_ -match 'workshopStateInProgress' } | Select-Object -First 1)
        $gateLine | Should -Not -BeNullOrEmpty -Because 'the expensive-parse gate line must exist'
        $gateLine | Should -Not -Match 'anySpec' -Because 'a spec on disk alone must not trigger the per-line transcript parse (T099/N3)'
        $gateLine | Should -Match 'hasPending' -Because 'a pending boundary verdict still warrants the parse'
        $gateLine | Should -Match 'materialStop' -Because 'a material-turn stop still warrants the parse'
        $gateLine | Should -Match 'workshopStateInProgress' -Because 'a scoped remaining-lens candidate must be parsed so its exact question marker can be proved'
    }

    It 'the deployed mirror carries the same gate (parity)' {
        if (-not (Test-Path -LiteralPath $script:Mirror -PathType Leaf)) {
            Set-ItResult -Skipped -Because 'no deployed mirror in this checkout'
            return
        }
        (Get-Content -LiteralPath $script:Provider -Raw) | Should -Be (Get-Content -LiteralPath $script:Mirror -Raw) -Because 'the source provider and the deployed mirror must stay byte-identical'
    }

    It 'a conversational stop (no material signal, no pending verdict) emits nothing and writes no journal' {
        $proj = Join-Path ([System.IO.Path]::GetTempPath()) ('t099-conv-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
        # A spec on disk - under the OLD gate this alone forced the parse path.
        New-Item -ItemType Directory -Path (Join-Path $proj 'specs/001-x') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $proj 'specs/001-x/spec.md') -Value '# spec' -Encoding UTF8
        # A transcript whose LAST assistant message is conversational (no packet, no marker).
        $transcript = Join-Path $proj 'transcript.jsonl'
        ('{"type":"assistant","message":{"content":[{"type":"text","text":"Sure - the tests are green and nothing else changed."}]}}') | Set-Content -LiteralPath $transcript -Encoding UTF8
        try {
            $out = & pwsh -NoProfile -NonInteractive -Command "Set-Location '$proj'; & '$($script:Provider)' --host-kind claude --source-event Stop --transcript-path '$transcript'" 2>$null
            ($out -join "`n") | Should -Not -Match 'SPECREW-STOP-BLOCK' -Because 'a conversational stop owes nothing'
            Test-Path -LiteralPath (Join-Path $proj '.specrew/runtime/conformance-journal.jsonl') | Should -BeFalse -Because 'no trigger fired - the stop stayed cheap (no parse, no journal)'
        }
        finally {
            Remove-Item -LiteralPath $proj -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
