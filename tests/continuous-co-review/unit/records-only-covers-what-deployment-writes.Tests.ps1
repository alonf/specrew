#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# DRIFT-007's TWIN (2026-08-22, found by the downstream walk after b5c84f48 fixed the validator): the
# evidence gate's FR-009 records-only exemption classified the delta path-by-path against the machinery
# list plus the feature allowlist, failing closed on the first unclassifiable path - and the
# Spec-Kit/Squad deployers write host mirrors (.github/agents/, .github/prompts/, .claude/skills/,
# .cursor/rules/) that are in NEITHER. So every redeploy permanently staled every review in a
# downstream project. The same byte-vs-source question, surviving in a second copy of the check.
#
# MEASURED, because the first draft of this suite got it wrong: in the SPECREW SOURCE REPO the
# machinery list enumerates the .specrew-managed mirrors, so the host-mirror paths classified fine here
# and the acceptance case passed even against the pre-fix gate. The failure lives only in a
# DOWNSTREAM-shaped root, whose machinery list is
#   .agents, .antigravitycli, .claude/settings.local.json, .git, .specify, .specrew, .squad, ...
# - no .github/agents, no .claude/skills, no .cursor/rules. So every case here runs against a
# downstream-shaped fixture, and the source-repo behavior is pinned separately.
#
# The fix is the same SHARED classifier the validator got - Test-SpecrewReviewAuthorshipSourcePath -
# not a longer parallel list. WHAT MUST SURVIVE: FR-009 as ruled 2026-08-10 distinguishes INPUT from
# OUTPUT inside the feature tree; the classifier calls all of specs/ non-source, so it is scoped OUT of
# specs/ and the allowlist stays authoritative there.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1')
    $script:Feature = '001-fixture'

    # A DOWNSTREAM-shaped project: no Specrew.psd1 at root, the deployed extension present so the
    # gate's load ladder can resolve the shared classifier from the project itself.
    $script:Downstream = Join-Path ([IO.Path]::GetTempPath()) ('fr009-' + [guid]::NewGuid().ToString('N'))
    $extScripts = Join-Path $script:Downstream '.specify/extensions/specrew-speckit/scripts'
    New-Item -ItemType Directory -Path $extScripts -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:Downstream 'specs/001-fixture/iterations/001') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1') `
        -Destination (Join-Path $extScripts 'shared-governance.ps1') -Force

    function script:Test-RecordsOnly {
        param([Parameter(Mandatory)][object[]]$Paths, [string]$Root = $script:Downstream)
        return [bool](Test-ReviewCampaignDeltaIsRecordsOnly -ChangedPaths $Paths -RepoRoot $Root -FeatureId $script:Feature)
    }
}

AfterAll {
    Remove-Item -LiteralPath $script:Downstream -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'FR-009 the records-only exemption covers what deployment actually writes' {
    It 'ACCEPTANCE: a host-mirror redeploy delta does not stale a review in a downstream project' {
        # The exact shape the walk hit: specrew update rewrites the host mirrors, no code moves, and
        # before this fix the first unclassifiable path staled every review in the project -
        # permanently, because the next redeploy re-staled it. None of these paths is in the
        # downstream machinery list.
        Test-RecordsOnly -Paths @(
            '.github/agents/squad.agent.md',
            '.github/prompts/speckit.plan.prompt.md',
            '.claude/skills/speckit-plan/SKILL.md',
            '.cursor/rules/specrew-review/SKILL.md',
            '.copilot/skills/specrew-drift-check/SKILL.md'
        ) | Should -BeTrue
    }

    It 'a documentation-only delta does not stale either, matching the validator since b5c84f48' {
        Test-RecordsOnly -Paths @('docs/architecture.md', 'README.md') | Should -BeTrue
    }

    It 'one source file in the delta still stales, whatever else rode along' {
        Test-RecordsOnly -Paths @('.github/agents/squad.agent.md', 'src/app.ts') | Should -BeFalse
    }

    It 'a workflow change is source and still stales - dot-github is not a blanket pass' {
        # .github/workflows is genuinely behavior: CI is executable. This case was written pinning the
        # OPPOSITE - the b5c84f48 limit, where the shared classifier called all of .github/ non-source -
        # with the instruction that changing it means changing the SHARED classifier so all consumers
        # move together. Round 16 (DRIFT-199-I001-126) found the limit reaching a consequence the note
        # anticipated: a commit touching only a workflow read as records-only and signoff reused a
        # review of a tree that never held the executable change. The classifier moved; this case now
        # pins what its own name always said.
        Test-RecordsOnly -Paths @('.github/workflows/ci.yml') | Should -BeFalse -Because 'CI is executable behavior, and the digest already treated it as reviewable'
        Test-RecordsOnly -Paths @('.github/actions/setup/action.yml') | Should -BeFalse -Because 'a composite action is executable too'
        # The records half of .github stays records: host instruction mirrors and skill catalogs.
        Test-RecordsOnly -Paths @('.github/copilot-instructions.md') | Should -BeTrue
        Test-RecordsOnly -Paths @('.github/skills/specrew-review/SKILL.md') | Should -BeTrue
    }

    It 'THE FR-009 RULING SURVIVES: the active features plan is review INPUT and still stales' {
        # The shared classifier alone would quiet this - it calls all of specs/ non-source. If this
        # case ever flips, the classifier has leaked into the feature tree and a spec change no longer
        # invalidates the review that judged code against it.
        Test-RecordsOnly -Paths @('specs/001-fixture/plan.md') | Should -BeFalse
        Test-RecordsOnly -Paths @('specs/001-fixture/spec.md') | Should -BeFalse
    }

    It 'review OUTPUT in the active feature tree stays records-only' {
        Test-RecordsOnly -Paths @(
            'specs/001-fixture/iterations/001/drift-log.md',
            'specs/001-fixture/iterations/001/review.md',
            'specs/001-fixture/iterations/001/state.md'
        ) | Should -BeTrue
    }

    It 'another features specs tree is ordinary content to this campaign and stales' {
        Test-RecordsOnly -Paths @('specs/042-other-feature/spec.md') | Should -BeFalse
    }

    It 'an empty or unknown delta still fails closed' {
        Test-ReviewCampaignDeltaIsRecordsOnly -ChangedPaths @() -RepoRoot $script:Downstream -FeatureId $script:Feature | Should -BeFalse
        Test-ReviewCampaignDeltaIsRecordsOnly -ChangedPaths @('.github/agents/x.md') -RepoRoot '' -FeatureId $script:Feature | Should -BeFalse
    }

    It 'the source repo still classifies its own mirrors as machinery, unchanged' {
        Test-RecordsOnly -Paths @('.github/agents/squad.agent.md') -Root $script:RepoRoot | Should -BeTrue
    }
}

Describe 'FR-009 the classifier resolves from the deployed project itself' {
    It 'a fresh process with only the gate loaded finds the classifier via the projects .specify copy' {
        # Downstream, the gate may run in a process that never loaded shared-governance. The load ladder
        # must find the DEPLOYED copy; if it cannot, the path stays unclassifiable and stales - the fail
        # direction - which is exactly what this child asserts by expecting True only through the ladder.
        $gatePath = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1'
        $result = & pwsh -NoProfile -Command ". '$gatePath'; [bool](Test-ReviewCampaignDeltaIsRecordsOnly -ChangedPaths @('.github/agents/squad.agent.md') -RepoRoot '$($script:Downstream)' -FeatureId '001-fixture')"
        [bool]::Parse(($result | Select-Object -Last 1)) | Should -BeTrue
    }
}

Describe 'FR-009 one classifier, not a parallel list' {
    It 'the gate calls the shared classifier rather than carrying its own host-mirror enumeration' {
        # The maintainer's instruction verbatim: rather than maintaining a parallel classification that
        # under-covers what deployment writes. A future "fix" that adds .github/** to a local list here
        # instead of using the shared function recreates the drift this suite exists to prevent.
        $gate = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1') -Raw -Encoding UTF8
        $gate.Contains('Test-SpecrewReviewAuthorshipSourcePath') | Should -BeTrue
        # And the scope guard is real: the classifier must not be consulted for specs/ paths.
        $fn = [regex]::Match($gate, '(?s)function Test-ReviewCampaignDeltaIsRecordsOnly.+?\r?\nfunction ').Value
        $fn.Contains("StartsWith('specs/'") | Should -BeTrue -Because 'inside specs/ the INPUT/OUTPUT allowlist stays authoritative'
    }
}
