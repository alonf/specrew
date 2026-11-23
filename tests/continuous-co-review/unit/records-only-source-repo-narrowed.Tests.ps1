#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 203 T022, the records rule (the maintainer's "203 T022: 1", 2026-11-16 14:17 local; B5F-087).
#
# The gate's records-only classifier, Test-ReviewCampaignDeltaIsRecordsOnly, decides whether a commit after a review
# round leaves that round current (run currentness) and whether a typed partial sign-off carries across it (the
# acceptance carry). In the Specrew SOURCE repository it accepted, as records, files the agents working here obey:
# the .specify mirror the boundary syncs and the governance check execute, scripts under docs/, product Markdown
# (skills, templates, the coordinator fragment), test fixtures, every host directory, AGENTS.md and CLAUDE.md, and the
# methodology the refocus sends agents to read. A commit of any of them after a round left the round "current".
#
# The narrowed rule, in the source repository only:
#   - non-Markdown: .specify/** and non-Markdown files under docs/ are source;
#   - Markdown and text, turned round: a .md or .txt file is records only in a named records place, and source
#     everywhere else, whichever host directory it is in;
#   - the acceptance carry's diff takes --no-renames, so a code file renamed into a records path is seen as the
#     code file it was.
# Downstream projects keep today's answers, and so does the shared classifier Test-SpecrewReviewAuthorshipSourcePath
# (the validator's authorship rule and the boundary coverage line read it).
#
# The source repository is the existing detection, Test-ContinuousCoReviewSpecrewSourceRepo: Specrew.psd1 AND
# scripts/internal/continuous-co-review/_load.ps1 at the root. One stray file of the two must not switch the rule.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    $script:GatePath = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1'
    $script:SharedGovernance = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1'
    . $script:GatePath
    # The source-repository detection the rule keys on; the gate itself loads it lazily.
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
    $script:Feature = '001-fixture'
    $script:Temp = Join-Path ([IO.Path]::GetTempPath()) ('t022-records-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $script:Temp -Force | Out-Null

    function script:Test-RecordsOnly {
        param([Parameter(Mandatory)][string[]]$Paths, [string]$Root = $script:RepoRoot)
        return [bool](Test-ReviewCampaignDeltaIsRecordsOnly -ChangedPaths $Paths -RepoRoot $Root -FeatureId $script:Feature)
    }

    # A downstream-shaped project, optionally holding ONE of the two source-repository markers.
    function script:New-DownstreamFixture {
        param([Parameter(Mandatory)][string]$Name, [switch]$WithManifest, [switch]$WithLoader)
        $root = Join-Path $script:Temp $Name
        $ext = Join-Path $root '.specify/extensions/specrew-speckit/scripts'
        New-Item -ItemType Directory -Path $ext -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-fixture/iterations/001') -Force | Out-Null
        Copy-Item -LiteralPath $script:SharedGovernance -Destination (Join-Path $ext 'shared-governance.ps1') -Force
        if ($WithManifest) { Set-Content -LiteralPath (Join-Path $root 'Specrew.psd1') -Value '@{}' -Encoding utf8NoBOM }
        if ($WithLoader) {
            $loaderDir = Join-Path $root 'scripts/internal/continuous-co-review'
            New-Item -ItemType Directory -Path $loaderDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $loaderDir '_load.ps1') -Value '# fixture' -Encoding utf8NoBOM
        }
        return $root
    }

    # A source-shaped git repository for the acceptance carry: both markers, the shared classifier, one code file.
    function script:Invoke-FixtureGit {
        # Plain $args on purpose: git switches such as -q must pass through, not bind as PowerShell parameters.
        $Root = [string]$args[0]
        $GitArgs = @($args | Select-Object -Skip 1 | ForEach-Object { [string]$_ })
        $out = & git -C $Root @GitArgs 2>&1
        if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed: $out" }
        return $out
    }
    function script:New-CarryFixture {
        param([Parameter(Mandatory)][string]$Name)
        $root = Join-Path $script:Temp $Name
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        Invoke-FixtureGit $root init -q
        Invoke-FixtureGit $root config user.name 'fixture'
        Invoke-FixtureGit $root config user.email 'fixture@example.invalid'
        Invoke-FixtureGit $root config core.autocrlf false
        Invoke-FixtureGit $root config diff.renames true
        Set-Content -LiteralPath (Join-Path $root 'Specrew.psd1') -Value '@{}' -Encoding utf8NoBOM
        $loaderDir = Join-Path $root 'scripts/internal/continuous-co-review'
        New-Item -ItemType Directory -Path $loaderDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $loaderDir '_load.ps1') -Value '# fixture' -Encoding utf8NoBOM
        $ext = Join-Path $root 'extensions/specrew-speckit/scripts'
        New-Item -ItemType Directory -Path $ext -Force | Out-Null
        Copy-Item -LiteralPath $script:SharedGovernance -Destination (Join-Path $ext 'shared-governance.ps1') -Force
        New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'src/tool.ps1') -Value ((1..40 | ForEach-Object { "Write-Output 'line $_'" }) -join "`n") -Encoding utf8NoBOM
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-fixture/iterations/001') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'specs/001-fixture/iterations/001/drift-log.md') -Value '# Drift' -Encoding utf8NoBOM
        Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value '.specrew/' -Encoding utf8NoBOM
        Invoke-FixtureGit $root add -A
        Invoke-FixtureGit $root commit -q -m 'accepted tree'
        return $root
    }
    function script:Get-TreeId { param([string]$Root) return [string](Invoke-FixtureGit $Root rev-parse 'HEAD^{tree}') }
    function script:Write-AcceptanceFact {
        param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$TreeId)
        $dir = Join-Path $Root '.specrew/review/signoff-gate/override-authorizations'
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        [ordered]@{
            fact_type = 'review-signoff-partial-override'; authority_kind = 'human'; campaign_id = 'cmp-fixture'
            target_tree_id = $TreeId; observed_at = '2026-11-17T21:00:00Z'
        } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dir 'accept-1.json') -Encoding utf8NoBOM
    }
    function script:Get-Carry {
        param([Parameter(Mandatory)][string]$Root)
        return Get-SpecrewCarriedSignoffOverrideAuthorization -ProjectRoot $Root -CurrentTreeId (Get-TreeId $Root) -CampaignId 'cmp-fixture' -FeatureId $script:Feature
    }
}

AfterAll {
    if ($script:Temp -and (Test-Path -LiteralPath $script:Temp)) { Remove-Item -LiteralPath $script:Temp -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'T022 records rule: in the source repository these are source, and a commit of one stales the round' {
    It 'is run against a source checkout (both detection files present)' {
        Test-ContinuousCoReviewSpecrewSourceRepo -RepoRoot $script:RepoRoot | Should -BeTrue
    }

    It 'a script under docs/ is source' {
        Test-RecordsOnly -Paths @('docs/examples/check.ps1') | Should -BeFalse
    }

    It 'a .specify-only change is source (the mirror the syncs and the governance check execute)' {
        Test-RecordsOnly -Paths @('.specify/extensions/specrew-speckit/scripts/sync-review-signoff.ps1') | Should -BeFalse
        Test-RecordsOnly -Paths @('.specify/extensions/specrew-speckit/prompts/coordinator-response.md') | Should -BeFalse
    }

    It 'a hash-record-only change is source' {
        Test-RecordsOnly -Paths @('.specify/extensions/specrew-speckit/.specrew-extension-runtime.json') | Should -BeFalse
    }

    It 'product Markdown is source: a skill under extensions/, a template, the coordinator fragment' {
        Test-RecordsOnly -Paths @('extensions/specrew-speckit/squad-templates/skills/specrew-review/SKILL.md') | Should -BeFalse
        Test-RecordsOnly -Paths @('templates/coordinator-instructions.md') | Should -BeFalse
        Test-RecordsOnly -Paths @('extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md') | Should -BeFalse
    }

    It 'a test fixture .md and a test fixture .txt under tests/ are source' {
        Test-RecordsOnly -Paths @('tests/continuous-co-review/fixtures/dispositions/README.md') | Should -BeFalse
        Test-RecordsOnly -Paths @('tests/continuous-co-review/fixtures/fake-adapter/invalid-json.stdout.txt') | Should -BeFalse
    }

    It 'a .agents/skills/**/SKILL.md is source' {
        Test-RecordsOnly -Paths @('.agents/skills/specrew-code-rules/SKILL.md') | Should -BeFalse
    }

    It 'a .github/prompts file and a .github/agents file are source in the source repository' {
        Test-RecordsOnly -Paths @('.github/prompts/speckit.analyze.prompt.md') | Should -BeFalse
        Test-RecordsOnly -Paths @('.github/agents/squad.agent.md') | Should -BeFalse
    }

    It 'every other host directory is source too' {
        foreach ($path in @(
                '.claude/skills/specrew-review/SKILL.md', '.cursor/rules/specrew-review/SKILL.md',
                '.copilot/skills/specrew-review/SKILL.md', '.github/skills/specrew-review/SKILL.md')) {
            Test-RecordsOnly -Paths @($path) | Should -BeFalse -Because "$path is a host directory agents load"
        }
    }

    It 'a .md under scripts/, hosts/ or tools/ is source' {
        Test-RecordsOnly -Paths @('scripts/internal/continuous-co-review/reviewer-spawn-contract.md') | Should -BeFalse
        Test-RecordsOnly -Paths @('hosts/claude/notes.md') | Should -BeFalse
        Test-RecordsOnly -Paths @('tools/maintenance/notes.md') | Should -BeFalse
    }

    It 'AGENTS.md, CLAUDE.md, a squad charter and the constitution are source' {
        foreach ($path in @('AGENTS.md', 'CLAUDE.md', '.squad/agents/data/charter.md', '.specrew/constitution.md')) {
            Test-RecordsOnly -Paths @($path) | Should -BeFalse -Because "$path holds instructions the agents working here obey"
        }
    }

    It 'the team instructions and contracts under .squad and .specrew are source' {
        foreach ($path in @(
                '.squad/ceremonies.md', '.squad/routing.md', '.squad/team.md', '.squad/identity/wisdom.md',
                '.specrew/team/agents/implementer.md', '.specrew/review/contracts/finding.md',
                '.specrew/quality/known-traps.md', '.specrew/release-gate-suites.txt')) {
            Test-RecordsOnly -Paths @($path) | Should -BeFalse -Because "$path is read by agents or selects suites"
        }
    }

    It 'docs/methodology/** is source' {
        Test-RecordsOnly -Paths @('docs/methodology/README.md') | Should -BeFalse
    }

    It 'on a case-sensitive volume, Markdown and text are told by extension whatever its case' {
        # The extension says what kind of file it is, not which file it is: notes.MD is Markdown to every agent that loads
        # it, so on a case-sensitive volume it must not fall back to today's answer (records) by missing the new rule.
        Mock -CommandName Get-ContinuousCoReviewPathComparison -MockWith { [StringComparison]::Ordinal }
        Test-RecordsOnly -Paths @('templates/NOTES.MD') | Should -BeFalse -Because 'an upper-case .MD is still Markdown outside a records place'
        Test-RecordsOnly -Paths @('tests/fixtures/OUTPUT.TXT') | Should -BeFalse -Because 'an upper-case .TXT is still text outside a records place'
        Test-RecordsOnly -Paths @('docs/beta5-findings.MD') | Should -BeTrue -Because 'a records place keeps its records under any extension case'
        Test-RecordsOnly -Paths @('docs/examples/check.PS1') | Should -BeFalse -Because 'a non-Markdown file under docs/ is source'
    }

    # Round 1 of 203 iteration 002's review, finding-a0cc0ae3cd9703dc (major). The guard above compares directory
    # prefixes with the volume's case rule, but a non-Markdown path that misses it still reaches the shared classifier,
    # whose exemptions ((?i)^(specs|docs)/, the dot-directories) ignore case. On a case-sensitive volume Docs/check.ps1
    # is a different path from docs/check.ps1: the guard does not see it, the classifier calls it a document, and the
    # commit reads as records-only, so a passing review would be kept for a script nobody reviewed. Where the guard
    # and the classifier disagree on case, the path is source.
    It 'a script under a directory the guard tells apart by case is source on this volume (round 1 finding 2)' {
        # No mock: the volume this test runs on. On a case-insensitive volume Docs/ is docs/ and the guard catches it;
        # on a case-sensitive one (Linux CI, WSL) it is a distinct directory and must not fall through to records.
        Test-RecordsOnly -Paths @('Docs/check.ps1') | Should -BeFalse -Because 'Docs/check.ps1 is a script, and the guard and the classifier must not disagree into records'
    }

    It 'on a case-sensitive volume, a path the classifier exempts only by ignoring case is source (round 1 finding 2)' {
        Mock -CommandName Get-ContinuousCoReviewPathComparison -MockWith { [StringComparison]::Ordinal }
        Test-RecordsOnly -Paths @('Docs/check.ps1') | Should -BeFalse -Because 'Docs/ is not docs/ on this volume'
        Test-RecordsOnly -Paths @('.Specify/extensions/specrew-speckit/scripts/tool.ps1') | Should -BeFalse -Because '.Specify/ is not the .specify/ the guard names'
        Test-RecordsOnly -Paths @('Specs/tool.ps1') | Should -BeFalse -Because 'Specs/ is not the specs/ the fallback excludes'
        Test-RecordsOnly -Paths @('docs/examples/check.ps1') | Should -BeFalse -Because 'the exact docs/ prefix stays source (pinned)'
        Test-RecordsOnly -Paths @('specs/001-fixture/iterations/001/drift-log.md') | Should -BeTrue -Because 'an exact records place keeps its records (pinned)'
    }

    # The gate's prefix list (Test-ReviewCampaignPathMatchesExemptPrefixOnlyIgnoringCase) must hold every directory
    # exemption of the shared classifier: a directory exempted by the classifier alone would fall through to records on a
    # case-sensitive volume. This case reads the classifier's directory rules from its own source, so it goes red the day
    # an exemption is added to the classifier and not to the gate (the reviewer session's ruling on round 1 finding 2).
    It 'every directory the shared classifier exempts, written in another case, is source on a case-sensitive volume' {
        . $script:SharedGovernance
        $tokens = $null; $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:SharedGovernance, [ref]$tokens, [ref]$parseErrors)
        $classifierAst = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Test-SpecrewReviewAuthorshipSourcePath' }, $true)
        $classifierAst | Should -Not -BeNullOrEmpty
        # Every anchored rule: -match '(?i)^...'. The unanchored extension rule names a kind of file, not a place.
        $rules = @([regex]::Matches($classifierAst.Extent.Text, "-match\s+'\(\?i\)\^([^']+)'") | ForEach-Object { $_.Groups[1].Value })
        $rules.Count | Should -BeGreaterOrEqual 4 -Because 'the classifier has at least four directory rules today'
        $expand = {
            param([string]$Pattern)
            $group = [regex]::Match($Pattern, '\((?:\?:)?([^()]+)\)')
            if ($group.Success) {
                foreach ($alternative in $group.Groups[1].Value.Split('|')) {
                    & $expand ($Pattern.Substring(0, $group.Index) + $alternative + $Pattern.Substring($group.Index + $group.Length))
                }
                return
            }
            ($Pattern -replace '\[\^/\]\+', 'x' -replace '\$$', '' -replace '\\\.', '.')
        }
        $samples = @($rules | ForEach-Object { & $expand $_ })
        $samples.Count | Should -BeGreaterOrEqual 16 -Because 'specs, docs, seven dot-directories, six .github directories and the .github Markdown rule'
        $swap = { param([string]$s) -join ($s.ToCharArray() | ForEach-Object { if ([char]::IsUpper($_)) { [char]::ToLowerInvariant($_) } else { [char]::ToUpperInvariant($_) } }) }
        Mock -CommandName Get-ContinuousCoReviewPathComparison -MockWith { [StringComparison]::Ordinal }
        foreach ($sample in $samples) {
            $path = if ($sample.EndsWith('/')) { (& $swap $sample) + 'tool.ps1' } else { & $swap $sample }
            Test-SpecrewReviewAuthorshipSourcePath -Path $path | Should -BeFalse -Because "the classifier exempts $path by ignoring case (rule sample $sample)"
            Test-RecordsOnly -Paths @($path) | Should -BeFalse -Because "$path is not $sample on a case-sensitive volume, so it is source"
        }
    }

    It 'a records file riding with one source file still stales' {
        Test-RecordsOnly -Paths @('specs/001-fixture/iterations/001/drift-log.md', 'templates/coordinator-instructions.md') | Should -BeFalse
    }
}

Describe 'T022 records rule: what stays as it is in the source repository (pinned)' {
    It 'plan.md, spec.md and tasks.md stay review input and stale' {
        foreach ($name in @('plan.md', 'spec.md', 'tasks.md')) {
            Test-RecordsOnly -Paths @("specs/001-fixture/$name") | Should -BeFalse
        }
    }

    It 'a records file and a code file in one commit stale' {
        Test-RecordsOnly -Paths @('specs/001-fixture/iterations/001/drift-log.md', 'scripts/internal/x.ps1') | Should -BeFalse
    }

    It 'an executable under specs/ stales' {
        Test-RecordsOnly -Paths @('specs/001-fixture/iterations/001/tool.ps1') | Should -BeFalse
    }

    It 'each named records place stays records-only' {
        foreach ($path in @(
                'specs/001-fixture/iterations/001/drift-log.md', '.squad/decisions.md', '.squad/decisions-archive.md',
                '.squad/decisions/inbox/entry.md', '.squad/identity/now.md', '.squad/log/2026-11-17-entry.md',
                '.squad/orchestration-log/2026-11-17-entry.md', '.squad/agents/data/history.md',
                '.specrew/cross-platform-backlog.md', '.specrew/reviewer-regression-log.md',
                '.specrew/review/inline/run-1/review.md', 'docs/beta5-findings.md', 'proposals/001-path-resolution-bug.md',
                'README.md', 'CHANGELOG.md', 'CONTRIBUTING.md', 'NOTICE.md', 'SECURITY.md', 'CODE_OF_CONDUCT.md')) {
            Test-RecordsOnly -Paths @($path) | Should -BeTrue -Because "$path is a named records place"
        }
    }

    It 'all the records places together in one commit stay records-only' {
        Test-RecordsOnly -Paths @(
            'specs/001-fixture/iterations/001/drift-log.md', 'specs/001-fixture/iterations/001/state.md',
            '.squad/decisions.md', '.squad/identity/now.md', 'docs/beta5-findings.md', 'README.md'
        ) | Should -BeTrue
    }

    It 'a non-Markdown file in the active iteration folder (the scaffold''s mechanical findings) stays records' {
        Test-RecordsOnly -Paths @('specs/001-fixture/iterations/001/quality/mechanical-findings.json') | Should -BeTrue
    }

    It 'non-Markdown state the syncs write under .specrew stays records' {
        Test-RecordsOnly -Paths @('.specrew/start-context.json') | Should -BeTrue
    }

    It 'the shared classifier keeps its answers (the validator''s authorship rule and the coverage line read it)' {
        $probe = @(
            '.github/agents/squad.agent.md', 'docs/methodology/README.md', '.specify/extensions/specrew-speckit/scripts/x.ps1',
            'extensions/specrew-speckit/squad-templates/skills/specrew-review/SKILL.md',
            'scripts/internal/continuous-co-review/reviewer-spawn-contract.md',
            'tests/continuous-co-review/fixtures/dispositions/README.md', 'docs/examples/check.ps1', 'AGENTS.md',
            'src/app.ts', 'scripts/internal/x.ps1')
        $expected = @('False', 'False', 'False', 'False', 'False', 'False', 'False', 'False', 'True', 'True')
        $list = ($probe | ForEach-Object { "'$_'" }) -join ','
        $out = @(& pwsh -NoProfile -Command ". '$($script:SharedGovernance)'; foreach (`$p in @($list)) { [string][bool](Test-SpecrewReviewAuthorshipSourcePath -Path `$p) }")
        $LASTEXITCODE | Should -Be 0
        ($out -join ',') | Should -Be ($expected -join ',')
    }
}

Describe 'T022 records rule: downstream projects keep today''s answers' {
    # Round 2 of 203 iteration 002's review changed one downstream answer on purpose (C1 of its inventory): a script under
    # docs/ is source now (see 'C1 downstream' below), so these pins probe docs/ with a document, which keeps its answer.
    It 'with neither detection file, host directories, .specify, docs scripts and instruction files stay records-only' {
        $root = New-DownstreamFixture -Name 'downstream-plain'
        foreach ($path in @(
                '.github/agents/squad.agent.md', '.github/prompts/speckit.plan.prompt.md', '.claude/skills/speckit-plan/SKILL.md',
                '.agents/skills/specrew-review/SKILL.md', '.specify/extensions/specrew-speckit/scripts/x.ps1',
                '.specify/extensions/specrew-speckit/.specrew-extension-runtime.json', 'docs/examples/guide.md',
                'docs/methodology/README.md', 'AGENTS.md', 'CLAUDE.md')) {
            Test-RecordsOnly -Paths @($path) -Root $root | Should -BeTrue -Because "$path keeps today's downstream answer"
        }
    }

    It 'only Specrew.psd1 at the root does not switch the source-repository rule on' {
        $root = New-DownstreamFixture -Name 'downstream-manifest-only' -WithManifest
        Test-ContinuousCoReviewSpecrewSourceRepo -RepoRoot $root | Should -BeFalse
        foreach ($path in @('.github/agents/squad.agent.md', '.specify/extensions/specrew-speckit/scripts/x.ps1', 'docs/examples/guide.md')) {
            Test-RecordsOnly -Paths @($path) -Root $root | Should -BeTrue -Because "one stray Specrew.psd1 must not change $path"
        }
    }

    It 'only scripts/internal/continuous-co-review/_load.ps1 does not switch the source-repository rule on' {
        $root = New-DownstreamFixture -Name 'downstream-loader-only' -WithLoader
        Test-ContinuousCoReviewSpecrewSourceRepo -RepoRoot $root | Should -BeFalse
        foreach ($path in @('.github/agents/squad.agent.md', '.specify/extensions/specrew-speckit/scripts/x.ps1', 'docs/examples/guide.md')) {
            Test-RecordsOnly -Paths @($path) -Root $root | Should -BeTrue -Because "one stray _load.ps1 must not change $path"
        }
    }

    It 'a source-shaped fixture (both files) takes the narrowed rule' {
        $root = New-DownstreamFixture -Name 'source-shaped' -WithManifest -WithLoader
        Test-ContinuousCoReviewSpecrewSourceRepo -RepoRoot $root | Should -BeTrue
        Test-RecordsOnly -Paths @('.specify/extensions/specrew-speckit/scripts/x.ps1') -Root $root | Should -BeFalse
        Test-RecordsOnly -Paths @('docs/examples/check.ps1') -Root $root | Should -BeFalse
        Test-RecordsOnly -Paths @('specs/001-fixture/iterations/001/drift-log.md') -Root $root | Should -BeTrue
    }
}

Describe 'T022 records rule: the acceptance carry reads the delta without rename detection' {
    It 'a code file renamed into a records path does not carry an acceptance' {
        $root = New-CarryFixture -Name 'carry-rename-into-records'
        Write-AcceptanceFact -Root $root -TreeId (Get-TreeId $root)
        New-Item -ItemType Directory -Path (Join-Path $root 'docs/notes') -Force | Out-Null
        Invoke-FixtureGit $root mv 'src/tool.ps1' 'docs/notes/tool.md'
        Invoke-FixtureGit $root commit -q -m 'rename code into records'
        Get-Carry -Root $root | Should -BeNullOrEmpty -Because 'the delete of src/tool.ps1 is a source change that rename detection hid'
    }

    It 'a records-only commit still carries the acceptance (pinned)' {
        $root = New-CarryFixture -Name 'carry-records-only'
        Write-AcceptanceFact -Root $root -TreeId (Get-TreeId $root)
        Add-Content -LiteralPath (Join-Path $root 'specs/001-fixture/iterations/001/drift-log.md') -Value '- entry' -Encoding utf8NoBOM
        Invoke-FixtureGit $root commit -q -am 'records'
        Get-Carry -Root $root | Should -Not -BeNullOrEmpty
    }

    It 'a code file renamed within code does not carry (pinned)' {
        $root = New-CarryFixture -Name 'carry-rename-code'
        Write-AcceptanceFact -Root $root -TreeId (Get-TreeId $root)
        Invoke-FixtureGit $root mv 'src/tool.ps1' 'src/tool2.ps1'
        Invoke-FixtureGit $root commit -q -m 'rename code'
        Get-Carry -Root $root | Should -BeNullOrEmpty
    }

    It 'a mode change of a code file does not carry (pinned)' {
        $root = New-CarryFixture -Name 'carry-mode'
        Write-AcceptanceFact -Root $root -TreeId (Get-TreeId $root)
        Invoke-FixtureGit $root update-index --chmod=+x 'src/tool.ps1'
        Invoke-FixtureGit $root commit -q -m 'mode'
        Get-Carry -Root $root | Should -BeNullOrEmpty
    }

    It 'the carry''s diff names --no-renames' {
        $gate = Get-Content -LiteralPath $script:GatePath -Raw -Encoding UTF8
        $fn = [regex]::Match($gate, '(?s)function Get-SpecrewCarriedSignoffOverrideAuthorization.+?\r?\nfunction ').Value
        $fn | Should -Match 'diff --no-renames --name-only|diff --name-only --no-renames'
    }
}

# Round 2 of 203 iteration 002's review, finding-7a5e1b6f01a5008d (major), and the reviewer session's ruling that closes
# the class, not the instance: the records-only decision asked WHERE a path is and not WHAT it is. The inventory and the
# rule are in DRIFT entry of iteration 002; each case below is one row of that inventory.
#   B2, B3 (the shared Test-SpecrewLifecycleExecutionRecordPath, every caller): a closeout* name and the descendants of
#     quality/, checklists/, dashboards/ and gates/ are records only when they are a record KIND.
#   A, C2, C3, C5 in the source repository: outside specs/, a path is records only in a named records place, whatever its
#     extension (a .yml can be an agent definition, a .json the hook settings).
#   C1 downstream: a non-record kind under docs/ is source.
#   A, C2, C3 downstream (deployed machinery and host mirrors): unchanged, an open design question put to the maintainer on
#     2026-11-23; pinned here so a change to them is deliberate.
Describe 'records by kind and by named place (round 2 finding, finding-7a5e1b6f01a5008d)' {
    It 'B3: a script under quality/, checklists/, dashboards/ or gates/ of the active feature is source' {
        foreach ($path in @(
                'specs/001-fixture/iterations/001/quality/check.ps1', 'specs/001-fixture/iterations/001/checklists/run.sh',
                'specs/001-fixture/iterations/001/dashboards/render.py', 'specs/001-fixture/iterations/001/gates/gate.psm1',
                'specs/001-fixture/quality/check.ps1')) {
            Test-RecordsOnly -Paths @($path) | Should -BeFalse -Because "$path can run, so it is source wherever it sits"
        }
    }

    It 'B2: a script named closeout* in the feature or iteration folder is source' {
        Test-RecordsOnly -Paths @('specs/001-fixture/iterations/001/closeout-check.ps1') | Should -BeFalse
        Test-RecordsOnly -Paths @('specs/001-fixture/closeout.ps1') | Should -BeFalse
    }

    It 'B2, B3: the records the lifecycle writes there stay records (pinned)' {
        foreach ($path in @(
                'specs/001-fixture/iterations/001/quality/mechanical-findings.json', 'specs/001-fixture/iterations/001/quality/hardening-gate.md',
                'specs/001-fixture/iterations/001/checklists/requirements.md', 'specs/001-fixture/iterations/001/dashboards/burndown.json',
                'specs/001-fixture/iterations/001/gates/before-implement.md', 'specs/001-fixture/iterations/001/quality/notes.txt',
                'specs/001-fixture/iterations/001/closeout-summary.md', 'specs/001-fixture/closeout.md')) {
            Test-RecordsOnly -Paths @($path) | Should -BeTrue -Because "$path is a record the lifecycle writes"
        }
    }

    It 'A, C2, C3 in the source repository: a runnable file in a machinery or host directory is source whatever its extension' {
        foreach ($path in @(
                '.claude/settings.local.json', '.github/agents/squad.agent.yml', '.agents/skills/specrew-help/run.ps1',
                '.squad/config.json', '.squad/casting/registry.json', '.specrew/verification-plan.json', '.specrew/config.yml',
                '.cursor/rules/specrew-help/.specrew-managed', '.github/prompts/review.prompt.yml', '.copilot/hooks.json')) {
            Test-RecordsOnly -Paths @($path) | Should -BeFalse -Because "$path is not a named records place"
        }
    }

    It 'A, C2, C3 in the source repository: a script under a named records prefix is source' {
        foreach ($path in @('.squad/log/run.ps1', '.specrew/review/inline/run-1/tool.ps1', 'proposals/tool.ps1', '.squad/decisions/inbox/hook.ps1')) {
            Test-RecordsOnly -Paths @($path) | Should -BeFalse -Because "$path is under a records place but is not a record kind"
        }
    }

    It 'A in the source repository: the records the syncs, the start and the review write there stay records (pinned, from the census)' {
        foreach ($path in @(
                '.squad/events/lifecycle-events.jsonl', '.squad/active-features.yml', '.specrew/closed-iterations.yml',
                '.specrew/last-validator-summary.json', '.specrew/start-context.json', '.specrew/version-check-cache.json',
                '.specrew/runtime/refocus-channel1.json', '.specrew/review/signoff-gate/latest.json',
                '.specrew/review/test-evidence/0123abcd.json', '.specrew/review/pause-decision/stop-here.json',
                '.specrew/review/pause-decision/captures.jsonl', '.specrew/review/inline/run-1/result.json')) {
            Test-RecordsOnly -Paths @($path) | Should -BeTrue -Because "$path is a record the lifecycle writes"
        }
    }

    # Found by the crew's own reading before round 3, not by a reviewer: the census read past commits, and no stop answer had
    # been committed yet, so the stop-answer records (written at a review stop, the one review-authority folder that is not
    # gitignored) and the bypass audit were missing from the named places. T027's live stop writes exactly these.
    It 'A in the source repository: a review stop answer and the bypass audit are records, and a script beside them is source' {
        foreach ($path in @('.specrew/review/stop-answer/run-1/stop-review-0123abcd4567ef89.json', '.specrew/review/stop-answer/captures.jsonl',
                '.specrew/bypass-audit/bypass-log.md')) {
            Test-RecordsOnly -Paths @($path) | Should -BeTrue -Because "$path is a record the lifecycle writes"
        }
        Test-RecordsOnly -Paths @('.specrew/review/stop-answer/run-1/hook.ps1') | Should -BeFalse -Because 'a script under a records prefix is source'
    }

    It 'C5 in the source repository: a document kind outside a named records place is source' {
        Test-RecordsOnly -Paths @('templates/coordinator.adoc') | Should -BeFalse
        Test-RecordsOnly -Paths @('scripts/internal/notes.rst') | Should -BeFalse
    }

    It 'C1 downstream: a non-record kind under docs/ is source, and a document there stays records' {
        $root = New-DownstreamFixture -Name 'round2-docs'
        Test-RecordsOnly -Paths @('docs/check.ps1') -Root $root | Should -BeFalse -Because 'a script under docs/ can run'
        Test-RecordsOnly -Paths @('docs/guide.md') -Root $root | Should -BeTrue -Because 'a document under docs/ stays records downstream (pinned)'
    }

    It 'B3 downstream: a script under the active iteration''s quality/ is source there too' {
        $root = New-DownstreamFixture -Name 'round2-quality'
        Test-RecordsOnly -Paths @('specs/001-fixture/iterations/001/quality/check.ps1') -Root $root | Should -BeFalse
        Test-RecordsOnly -Paths @('specs/001-fixture/iterations/001/quality/mechanical-findings.json') -Root $root | Should -BeTrue
    }

    It 'A, C2, C3 downstream stay as they are: deployed machinery and host mirrors are records by design (open design question, 2026-11-23; pinned)' {
        $root = New-DownstreamFixture -Name 'round2-design-row'
        foreach ($path in @('.specify/extensions/specrew-speckit/scripts/tool.ps1', '.claude/skills/specrew-help/SKILL.md', '.github/agents/squad.agent.md')) {
            Test-RecordsOnly -Paths @($path) -Root $root | Should -BeTrue -Because "$path is a deployment write downstream (DRIFT-007's twin)"
        }
    }

    It 'the gate''s fallback body and the shared Test-SpecrewLifecycleExecutionRecordPath give the same answer for every probe' {
        $probes = @(
            'drift-log.md', 'state.md', 'tasks-progress.yml', 'review.md', 'review-signoff-listing.json', 'retro.md', 'plan.md', 'spec.md', 'dashboard.md', 'security-surface.md', 'reviewer-index.md', 'review-signoff.md',
            'closeout.md', 'closeout-summary.md', 'closeout.ps1', 'closeout-check.sh', 'closeout/notes.md',
            'quality/mechanical-findings.json', 'quality/hardening-gate.md', 'quality/notes.txt', 'quality/check.ps1', 'quality/x.yml',
            'quality/x.jsonl', 'quality/x.rst', 'quality/x.adoc', 'quality/x.markdown', 'quality/x.yaml', 'quality/x.psm1', 'quality/x',
            'checklists/a.md', 'checklists/run.sh', 'dashboards/b.json', 'dashboards/render.py', 'gates/c.md', 'gates/gate.psd1',
            'workshop/product-domain.md', 'tool.ps1')
        $paths = @(foreach ($p in $probes) { "specs/001-fixture/iterations/001/$p"; "specs/001-fixture/$p" })
        $probeFile = Join-Path $script:Temp 'probes.txt'
        [IO.File]::WriteAllLines($probeFile, $paths)
        # Each body in a process of its own: the gate alone runs its fallback (the shared function is not loaded).
        $gateOnly = "Set-StrictMode -Version Latest; . '$script:GatePath'; foreach (`$p in [IO.File]::ReadAllLines('$probeFile')) { '{0}={1}' -f `$p, [bool](Test-ReviewCampaignPathIsFeatureProcessRecord -Path `$p -FeatureId '001-fixture' -Comparison ([StringComparison]::OrdinalIgnoreCase)) }"
        $shared = "Set-StrictMode -Version Latest; . '$script:SharedGovernance'; foreach (`$p in [IO.File]::ReadAllLines('$probeFile')) { '{0}={1}' -f `$p, [bool](Test-SpecrewLifecycleExecutionRecordPath -Path `$p -FeatureId '001-fixture') }"
        $fromGate = @(& pwsh -NoProfile -NonInteractive -Command $gateOnly 2>&1 | ForEach-Object { [string]$_ })
        $fromShared = @(& pwsh -NoProfile -NonInteractive -Command $shared 2>&1 | ForEach-Object { [string]$_ })
        $fromGate.Count | Should -Be $paths.Count -Because ($fromGate -join "`n")
        $fromShared.Count | Should -Be $paths.Count -Because ($fromShared -join "`n")
        for ($i = 0; $i -lt $paths.Count; $i++) { $fromGate[$i] | Should -BeExactly $fromShared[$i] -Because 'the two bodies must agree path by path' }
        @($fromShared | Where-Object { $_ -like '*quality/check.ps1=True' }).Count | Should -Be 0 -Because 'a script under quality/ is not a record (round 2 finding)'
    }
}
