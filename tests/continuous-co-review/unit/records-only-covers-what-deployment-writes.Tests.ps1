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

    It 'the source repo classifies its own host mirrors as source (feature 203 T022); downstream they stay machinery' {
        # Amended by feature 203 T022 (the maintainer's "203 T022: 1", 2026-11-16): in the Specrew source repository a
        # host mirror is what the agents working here load, so a commit of one stales the round. The downstream answer
        # this case used to pin beside it is kept by the ACCEPTANCE case above and by
        # records-only-source-repo-narrowed.Tests.ps1.
        Test-RecordsOnly -Paths @('.github/agents/squad.agent.md') -Root $script:RepoRoot | Should -BeFalse
        Test-RecordsOnly -Paths @('.github/agents/squad.agent.md') | Should -BeTrue
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

# Round 3 of 203 iteration 002's review, finding-9cc1155f2c83f5f7 (major). The maintainer decided "203 deployed files: fix
# it in 203" (2026-11-23, about 13:14 local), then narrowed it to the parts that work: "203 host folders: record the limit,
# follow up" (about 14:44 local), after an end-to-end probe showed that downstream the reviewed-state digest strips the
# whole machinery list, so a change under a host tool folder never reaches the records-only check.
#   - The project's own hook and MCP server configuration is source by name.
#   - The shared classifier's directory exemption counts record kinds only: a script in .claude/, .cursor/, .copilot/ or
#     docs/ outside the machinery list can run.
#   - The generated Claude launcher, .claude/specrew-hook-launch.ps1, is a downstream-only machinery entry; the Specrew
#     source repository keeps reviewing it.
#   - THE RECORDED LIMIT: downstream, a project's own file under a host tool folder (a framework subfolder, .agents,
#     .antigravitycli, a marked folder) is outside the review - not in the reviewer's worktree and not in the digest. A
#     follow-up proposal brings it in; it will turn the limit case below around.
# A records-only case for the sign-off path is proven through the digest (digest, change, digest, then the check on the
# real delta), not by calling the check with a delta that may never occur.
Describe 'downstream: what can run in a host folder is source where the review can see it (round 3 finding 2)' {
    BeforeAll {
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
        $script:HostFixtures = @()
        function script:New-HostFixture {
            param([Parameter(Mandatory)][string]$Name, [string[]]$Files = @())
            $root = Join-Path ([IO.Path]::GetTempPath()) ('fr009-f2-' + $Name + '-' + [guid]::NewGuid().ToString('N'))
            $ext = Join-Path $root '.specify/extensions/specrew-speckit/scripts'
            New-Item -ItemType Directory -Path $ext -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-fixture/iterations/001') -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1') `
                -Destination (Join-Path $ext 'shared-governance.ps1') -Force
            foreach ($file in $Files) {
                $full = Join-Path $root $file
                New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force | Out-Null
                Set-Content -LiteralPath $full -Value 'fixture' -Encoding utf8NoBOM
            }
            $script:HostFixtures += @($root)
            return $root
        }
        $script:HostRoot = script:New-HostFixture -Name 'plain' -Files @(
            '.claude/hooks/pre.ps1', '.cursor/hooks/run.sh', '.copilot/hooks/x.ps1', '.github/ISSUE_TEMPLATE/check.ps1',
            '.claude/settings.json', '.cursor/hooks.json', '.cursor/mcp.json', '.copilot/mcp-config.json',
            '.copilot/hooks/specrew-refocus.json', '.claude/specrew-hook-launch.ps1')
    }

    AfterAll {
        foreach ($root in @($script:HostFixtures)) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'runnable files in host folders outside the machinery list are source' {
        foreach ($path in @('.claude/hooks/pre.ps1', '.cursor/hooks/run.sh', '.copilot/hooks/x.ps1', '.github/ISSUE_TEMPLATE/check.ps1')) {
            Test-RecordsOnly -Paths @($path) -Root $script:HostRoot | Should -BeFalse -Because "$path can run and no machinery entry names its place"
        }
    }

    It 'the project''s own hook and MCP server configuration is source by name' {
        foreach ($path in @('.claude/settings.json', '.cursor/hooks.json', '.copilot/hooks/specrew-refocus.json', '.cursor/mcp.json', '.copilot/mcp-config.json')) {
            Test-RecordsOnly -Paths @($path) -Root $script:HostRoot | Should -BeFalse -Because "$path names the commands the host runs"
        }
    }

    It 'the deployed Claude launcher is on the downstream machinery list, and not on the source repository''s' {
        @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $script:HostRoot) | Should -Contain '.claude/specrew-hook-launch.ps1'
        @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $script:RepoRoot) | Should -Not -Contain '.claude/specrew-hook-launch.ps1'
    }
}

Describe 'downstream, through the reviewed-state digest: the sign-off path sees what the records-only check decides (round 3 finding 2)' {
    BeforeAll {
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewed-state-digest.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1')
        $script:DigestFixtures = @()
        # A committed git project. -Source adds both source-repository detection files (Specrew.psd1 and the loader).
        function script:New-DigestFixture {
            param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string[]]$Files, [switch]$Source)
            $root = Join-Path ([IO.Path]::GetTempPath()) ('fr009-f2d-' + $Name + '-' + [guid]::NewGuid().ToString('N'))
            $ext = Join-Path $root '.specify/extensions/specrew-speckit/scripts'
            New-Item -ItemType Directory -Path $ext -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1') `
                -Destination (Join-Path $ext 'shared-governance.ps1') -Force
            $all = @($Files + @('src/app.ps1'))
            if ($Source) { $all += @('Specrew.psd1', 'scripts/internal/continuous-co-review/_load.ps1') }
            foreach ($file in $all) {
                $full = Join-Path $root $file
                New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force | Out-Null
                Set-Content -LiteralPath $full -Value 'v1' -Encoding utf8NoBOM
            }
            & git -C $root init -q 2>$null
            & git -C $root -c user.name=fixture -c user.email=fixture@example.invalid -c core.autocrlf=false add -A 2>$null
            & git -C $root -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m base 2>$null
            $script:DigestFixtures += @($root)
            return $root
        }
        # Digest, change one file, digest again, then the check on the real delta between the two.
        function script:Invoke-ChangeThroughDigest {
            param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Path)
            $before = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $Root -NoCache
            $before.ok | Should -BeTrue -Because ([string]$before.failure_reason)
            Set-Content -LiteralPath (Join-Path $Root $Path) -Value 'v2' -Encoding utf8NoBOM
            $after = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $Root -NoCache
            $after.ok | Should -BeTrue -Because ([string]$after.failure_reason)
            $delta = @(Get-ReviewCampaignChangedPathsSinceResult -RepoRoot $Root -ReviewedDigest ([string]$before.tree_id) -CurrentDigest ([string]$after.tree_id))
            Set-Content -LiteralPath (Join-Path $Root $Path) -Value 'v1' -Encoding utf8NoBOM
            $recordsOnly = $null
            if ($delta.Count -gt 0) { $recordsOnly = [bool](Test-ReviewCampaignDeltaIsRecordsOnly -ChangedPaths $delta -RepoRoot $Root -FeatureId '001-fixture') }
            return [pscustomobject]@{ Moved = ([string]$after.tree_id -cne [string]$before.tree_id); Delta = $delta; RecordsOnly = $recordsOnly }
        }
        $script:Downstream = script:New-DigestFixture -Name 'downstream' -Files @(
            '.claude/hooks/pre.ps1', '.claude/settings.json', '.claude/notes.md', '.claude/specrew-hook-launch.ps1',
            '.cursor/mcp.json', '.github/skills/release/scripts/publish.ps1', '.agents/skills/release/scripts/publish.ps1')
        $script:SourceShaped = script:New-DigestFixture -Name 'source' -Files @('.claude/specrew-hook-launch.ps1') -Source
    }

    AfterAll {
        foreach ($root in @($script:DigestFixtures)) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a script in a host folder outside the machinery list moves the digest and reads as source' {
        $r = script:Invoke-ChangeThroughDigest -Root $script:Downstream -Path '.claude/hooks/pre.ps1'
        $r.Moved | Should -BeTrue
        $r.Delta | Should -Be @('.claude/hooks/pre.ps1')
        $r.RecordsOnly | Should -BeFalse
    }

    It 'the project''s own hook and MCP server configuration moves the digest and reads as source' {
        foreach ($path in @('.claude/settings.json', '.cursor/mcp.json')) {
            $r = script:Invoke-ChangeThroughDigest -Root $script:Downstream -Path $path
            $r.Moved | Should -BeTrue -Because $path
            $r.RecordsOnly | Should -BeFalse -Because "$path names the commands the host runs"
        }
    }

    It 'a document in a host folder moves the digest and stays records (pinned)' {
        $r = script:Invoke-ChangeThroughDigest -Root $script:Downstream -Path '.claude/notes.md'
        $r.Moved | Should -BeTrue
        $r.RecordsOnly | Should -BeTrue
    }

    It 'the generated Claude launcher is downstream machinery: a change to it does not move the digest' {
        $r = script:Invoke-ChangeThroughDigest -Root $script:Downstream -Path '.claude/specrew-hook-launch.ps1'
        $r.Moved | Should -BeFalse -Because 'a redeploy that changes the generated launcher does not stale a review'
    }

    It 'in the Specrew source repository a change to the launcher moves the digest and reads as source (pinned)' {
        $r = script:Invoke-ChangeThroughDigest -Root $script:SourceShaped -Path '.claude/specrew-hook-launch.ps1'
        $r.Moved | Should -BeTrue
        $r.RecordsOnly | Should -BeFalse
    }

    It 'THE RECORDED LIMIT ("203 host folders: record the limit, follow up", 2026-11-23): a project''s own script under a host tool folder does not move the digest, so no review stales; the follow-up turns this case around' {
        foreach ($path in @('.github/skills/release/scripts/publish.ps1', '.agents/skills/release/scripts/publish.ps1')) {
            $r = script:Invoke-ChangeThroughDigest -Root $script:Downstream -Path $path
            $r.Moved | Should -BeFalse -Because "$path is under a folder the downstream strip and digest leave out (the recorded limit)"
        }
    }
}
