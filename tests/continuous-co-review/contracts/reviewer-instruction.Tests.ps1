$ErrorActionPreference = 'Stop'

# Trace: T107 (iter-010 fold), FR-017, FR-018, FR-021, SEC-007, SC-013, SC-014.
# The canonical reviewer instruction now LIVES IN the real outbound prompt — Get-ContinuousCoReviewSlimPrompt —
# per the maintainer fold decision (D-197-I009-016) and the preservation manifest
# (specs/197-continuous-co-review/requirement-reconciliation.md §D). This suite asserts:
#   - every TO-FOLD manifest row is PRESENT in the actual outbound slim prompt (FR-021/SC-014: test the
#     real prompt, not a side file), and
#   - every DROP row is ABSENT (the stale ReviewRequest.v2 / composed-prompt-visibility / prompt-injection /
#     mirror-authority framing must not leak back), and
#   - the old runtime file is RETIRED (moved to docs/reference/, off the module FileList).
Describe 'Proposal 197 T107 reviewer instruction lives in the outbound slim prompt (fold)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
        $script:Prompt = Get-ContinuousCoReviewSlimPrompt -RunId 'instr-test' -RoundNumber 1 -MaxRounds 2
    }

    It 'carries the report-falsification stance (manifest row 2 - the adversarial posture)' {
        $script:Prompt | Should -Match 'REPORT-FALSIFICATION STANCE'
        $script:Prompt | Should -Match 'SEEK evidence'
        $script:Prompt | Should -Match '(?i)challenge pass claims'
        $script:Prompt | Should -Match '(?i)hidden mutation'
    }

    It 'binds workshop-decision conformance (row 3) and per-lens validation with lens naming (row 4)' {
        $script:Prompt | Should -Match 'WORKSHOP-DECISION CONFORMANCE'
        $script:Prompt | Should -Match '(?i)bypasses approved seams'
        $script:Prompt | Should -Match '(?i)absorbs deferred work'
        foreach ($lens in @('architecture', 'component', 'requirements/NFR', 'data-storage', 'security-compliance', 'integration/API', 'devops/operations', 'observability/resilience', 'code-implementation')) {
            $script:Prompt | Should -Match ([regex]::Escape($lens))
        }
        $script:Prompt | Should -Match '(?i)NAME the violated lens'
    }

    It 'carries all six P145 review phases incl. the mandatory-blocking decision rule (rows 5-10)' {
        foreach ($phase in @('Requirement conformance', 'Architecture and separation', 'Security and privacy', 'Verification confidence', 'Operations and observability', 'Review decision')) {
            $script:Prompt | Should -Match ([regex]::Escape($phase))
        }
        $script:Prompt | Should -Match 'FR/SC/TG/SEC/INT/OBS/IMPL'
        $script:Prompt | Should -Match '(?i)do not collapse'
        $script:Prompt | Should -Match '(?i)MUST be a blocking finding'
        $script:Prompt | Should -Match '(?i)no new dependencies'
    }

    It 'carries the claim/design-trace policy (row 11)' {
        $script:Prompt | Should -Match '(?i)claim WITHOUT a traceable basis is itself a finding'
        $script:Prompt | Should -Match '(?i)fixture-owned substitute'
    }

    It 'carries never-false-green: deterministic failure is never a clean pass (row 12)' {
        $script:Prompt | Should -Match 'NEVER-FALSE-GREEN'
        $script:Prompt | Should -Match '(?i)NEVER "no findings"'
        $script:Prompt | Should -Match '(?i)empty stdout'
    }

    It 'carries the no-web/no-deps/no-paid-providers guardrail (row 13) and secret non-exfiltration (row 14)' {
        $script:Prompt | Should -Match '(?i)do not use live\s+web search'
        $script:Prompt | Should -Match '(?i)paid/non-default providers'
        $script:Prompt | Should -Match '(?i)never request, infer, persist, or echo secrets'
        $script:Prompt | Should -Not -Match '(?i)token value|api key|password value|secret value'
    }

    It 'DROPS the stale composed-prompt world (rows 17-20): no ReviewRequest.v2, no composer, no read-only-prompt visibility, no mirror authority' {
        $script:Prompt | Should -Not -Match 'ReviewRequest\.v2' -Because 'the composer + ReviewRequest.v2 were deleted at the worktree cutover'
        $script:Prompt | Should -Not -Match '(?i)prompt composer'
        $script:Prompt | Should -Not -Match '(?i)read only the content included in the composed prompt' -Because 'the worktree reviewer is SUPPOSED to browse the repo and run tests'
        $script:Prompt | Should -Not -Match '(?i)prompt injection.*blocking'
        $script:Prompt | Should -Not -Match '(?i)native host-agent mirrors as authority'
    }

    It 'keeps the worktree conduct: browse+run trusted, but READ-ONLY on source, FindingsResult.v1 out' {
        $script:Prompt | Should -Match '(?i)READ-ONLY on the source'
        $script:Prompt | Should -Match 'FindingsResult\.v1'
        $script:Prompt | Should -Match ([regex]::Escape('.review/findings.jsonl'))
    }

    It 'the old runtime file is RETIRED: gone from the runtime path + FileList, kept as a reference doc' {
        Test-Path -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/code-review-agent.md') -PathType Leaf | Should -BeFalse -Because 'the file was folded + retired (T107)'
        Test-Path -LiteralPath (Join-Path $script:RepoRoot 'docs/reference/code-review-agent.md') -PathType Leaf | Should -BeTrue -Because 'the reference copy documents the historical instruction'
        (Get-Content -LiteralPath (Join-Path $script:RepoRoot 'docs/reference/code-review-agent.md') -Raw) | Should -Match 'RETIRED'
        (Get-Content -LiteralPath (Join-Path $script:RepoRoot 'Specrew.psd1') -Raw) | Should -Not -Match 'code-review-agent\.md' -Because 'a retired doc must not ship in the module FileList'
    }
}
