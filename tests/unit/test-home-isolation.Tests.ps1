$ErrorActionPreference = 'Stop'

# Feature 203, B5F-042 follow-up and B5F-039 (maintainer ruling 2026-11-11): EVERY TEST THAT CAN WRITE A HOME HOOK FILE,
# OR THAT RUNS THE REVIEW PREFLIGHT'S HOME CHECK, GIVES ITSELF A PRIVATE HOME.
#
#   - CI on c7b55e5c: review-campaign-verification.Tests.ps1 ran the real preflight with no home of its own, so its "real
#     home" was the Linux runner's $HOME; distribution-module-update.ps1, running beside it, ran specrew-update.ps1 with no
#     home redirect and deployed hooks there, and B5F-042's check failed the unrelated preflight.
#   - The same suites, run on a workstation outside the sweep driver, rewrite the maintainer's real hook files (B5F-039).
#
# The deployer (scripts/internal/deploy-refocus-hooks.ps1) writes the home named by -UserHomeOverride, else by
# SPECREW_USER_HOME_OVERRIDE, else [Environment]::GetFolderPath('UserProfile'), which ignores HOME and USERPROFILE on
# Windows: a suite that sets only HOME is safe on Linux and writes the real home on Windows. So the rule is stated on
# SPECREW_USER_HOME_OVERRIDE (or -UserHomeOverride, which the deployer reads first).
#
# A file that only MENTIONS an entry point (reads, parses or hashes its text) says so on a line of its own:
#   # specrew-test-home: not-a-writer - <why>
# and the reason was confirmed by reading the file (the 2026-11-11 census in docs/beta5-findings.md B5F-039).
Describe 'Tests that can write home hook files, or run the preflight home check, use a private home' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        $script:Self = [IO.Path]::GetFullPath($PSCommandPath)
        $script:TestFiles = @(Get-ChildItem -LiteralPath (Join-Path $script:RepoRoot 'tests') -Recurse -File -Include '*.ps1', '*.sh' |
                Where-Object { $_.FullName -notmatch '[\\/]fixtures[\\/]' -and [IO.Path]::GetFullPath($_.FullName) -cne $script:Self })
        # A private home: the variable assigned (any spelling of the assignment), or the deployer's parameter.
        $script:PrivateHomePattern = '\$env:SPECREW_USER_HOME_OVERRIDE\s*=|SetEnvironmentVariable\(\s*[''"]SPECREW_USER_HOME_OVERRIDE|SPECREW_USER_HOME_OVERRIDE\s*=\s*\$|-UserHomeOverride\b|--user-home-override\b|Enter-SpecrewPrivateTestHome\b'
        function script:Get-RelativeTestPath { param([string]$Path) return ([IO.Path]::GetRelativePath($script:RepoRoot, $Path) -replace '\\', '/') }
    }

    It 'names every test file that runs the updater, init, the hooks command or the hook deployer without a private home' {
        $entryPoints = 'specrew-update\.ps1|specrew-init\.ps1|specrew-start\.ps1|specrew-hooks\.ps1|deploy-refocus-hooks\.ps1|Invoke-RefocusHookDeployment'
        $offenders = @(foreach ($file in $script:TestFiles) {
                $text = [IO.File]::ReadAllText($file.FullName)
                if ($text -notmatch $entryPoints) { continue }
                if ($text -match $script:PrivateHomePattern) { continue }
                if ($text -match '(?m)^\s*#\s*specrew-test-home:\s*not-a-writer\s*-\s*\S') { continue }
                Get-RelativeTestPath $file.FullName
            })
        $offenders | Should -BeNullOrEmpty -Because ("each runs a hook-writing entry point with no private home, or must say why it does not (offenders: {0})" -f ($offenders -join ', '))
    }

    It 'names every test file that runs the review preflight against a plan without a private home' {
        # The home check runs only inside the production verification with a configured plan.
        $preflight = 'New-ReviewProductionVerificationPort|New-ReviewCampaignProductionPorts|Invoke-ReviewCampaignFrozenVerification|Invoke-ReviewCampaignStopHereLanding|specrew-review\.ps1'
        $offenders = @(foreach ($file in $script:TestFiles) {
                $text = [IO.File]::ReadAllText($file.FullName)
                if ($text -notmatch $preflight -or $text -notmatch 'verification-plan\.json') { continue }
                if ($text -match $script:PrivateHomePattern) { continue }
                Get-RelativeTestPath $file.FullName
            })
        $offenders | Should -BeNullOrEmpty -Because ("each runs the preflight's real-home check against the shared home (offenders: {0})" -f ($offenders -join ', '))
    }

    It 'restores what it set: every file that takes the shared helper''s private home gives it back' {
        # tests/support/private-test-home.ps1: Exit puts the caller's value back and deletes the folder; a file that
        # enters without exiting leaves its home set for whatever runs next in the same session.
        $offenders = @(foreach ($file in $script:TestFiles) {
                $text = [IO.File]::ReadAllText($file.FullName)
                if ($text -notmatch 'Enter-SpecrewPrivateTestHome\s+-') { continue }
                if ($text -match '(?s)(finally\s*\{|AfterAll\s*\{)[^}]*Exit-SpecrewPrivateTestHome') { continue }
                Get-RelativeTestPath $file.FullName
            })
        $offenders | Should -BeNullOrEmpty -Because ("each enters a private home without exiting it in a finally or AfterAll (offenders: {0})" -f ($offenders -join ', '))
    }

    It 'takes the private home in a Pester file''s only root BeforeAll (a second one silently replaces the first)' {
        # Measured 2026-11-11 (DRIFT-057): Pester keeps only the LAST BeforeAll at one level. The private home was added as
        # a second root BeforeAll in deployed-extension-marker-on-update.tests.ps1, never ran, and that suite's
        # specrew update wrote the sweep's shared home; the text checks above passed. Read from the syntax tree.
        $offenders = @(foreach ($file in $script:TestFiles) {
                if ($file.Extension -ne '.ps1') { continue }
                $text = [IO.File]::ReadAllText($file.FullName)
                if ($text -notmatch 'Enter-SpecrewPrivateTestHome\s+-') { continue }
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$null, [ref]$null)
                $rootCommands = @($ast.EndBlock.Statements | ForEach-Object {
                        if ($_ -is [System.Management.Automation.Language.PipelineAst] -and $_.PipelineElements[0] -is [System.Management.Automation.Language.CommandAst]) { $_.PipelineElements[0].GetCommandName() }
                    })
                if (@($rootCommands | Where-Object { $_ -eq 'BeforeAll' }).Count -gt 1 -or @($rootCommands | Where-Object { $_ -eq 'AfterAll' }).Count -gt 1) {
                    Get-RelativeTestPath $file.FullName
                }
            })
        $offenders | Should -BeNullOrEmpty -Because ("each has more than one root BeforeAll or AfterAll, so Pester runs only the last (offenders: {0})" -f ($offenders -join ', '))
    }

    It 'catches the shapes it exists for (the rule''s own falsifiability)' {
        # The suites that escaped: an updater run with no redirect, and a HOME-only redirect.
        $escaped = @(
            '& pwsh -NoProfile -File (Join-Path $repoRoot ''scripts/specrew-update.ps1'') -ProjectPath $project'
            '$env:HOME = $tempHome; & (Join-Path $repoRoot ''scripts/internal/deploy-refocus-hooks.ps1'') -ProjectPath $p -HostKind codex'
        )
        foreach ($sample in $escaped) { $sample | Should -Not -Match $script:PrivateHomePattern -Because "'$sample' gives no private home" }
        foreach ($sample in @('$env:SPECREW_USER_HOME_OVERRIDE = $h', '[Environment]::SetEnvironmentVariable(''SPECREW_USER_HOME_OVERRIDE'', $h)', '& $deploy -ProjectPath $p -UserHomeOverride $h')) {
            $sample | Should -Match $script:PrivateHomePattern -Because "'$sample' gives a private home"
        }
    }
}
