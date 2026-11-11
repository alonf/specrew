$ErrorActionPreference = 'Stop'

# B5F-042 (maintainer ruling 2026-11-11): the review preflight gives every suite it runs a temporary home, and fails the
# round, spending nothing, when the real home's hook files changed.
#
#   - Each preflight run gets a fresh home under the system temp folder, never inside the project, passed to every suite
#     as SPECREW_USER_HOME_OVERRIDE whatever the caller's environment held, and removed in a finally block on success,
#     failure and cancel.
#   - The real home's hook files are hashed before and after: every file under ~/.specrew/hooks/ (the launcher folders
#     and bindings/), ~/.specrew/hook-bindings/, ~/.specrew/specrew-hook-launch.ps1, ~/.codex/hooks.json,
#     ~/.cursor/hooks.json and the files in ~/.copilot/hooks/. A file changed, added or removed fails the preflight: no
#     round is spent, nothing is restored, and each file is named.
#
# "The real home" is the home a suite's deployer writes when nothing redirects it: SPECREW_USER_HOME_OVERRIDE when the
# caller set one, the user profile otherwise. These cases set it to a fixture folder, so the real home is never touched.
# RED before the fix: the preflight passes the caller's home through and checks nothing.
Describe 'B5F-042: the review preflight runs suites in a temporary home and checks the real one' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
        $script:SavedHome = $env:SPECREW_USER_HOME_OVERRIDE
        $script:EnvRefs = @('PATH', 'PATHEXT', 'SYSTEMROOT', 'COMSPEC', 'TEMP', 'TMP', 'TMPDIR', 'HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'PROGRAMFILES', 'PROGRAMDATA', 'PSModulePath')

        function script:New-PhRepo {
            param([Parameter(Mandatory)][string]$Path)
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            & git -C $Path init -q 2>&1 | Out-Null
            & git -C $Path branch -m main 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Path 'app.txt'), 'v1')
            & git -C $Path -c user.name=ph -c user.email=ph@example.invalid add -A 2>&1 | Out-Null
            & git -C $Path -c user.name=ph -c user.email=ph@example.invalid commit -qm initial 2>&1 | Out-Null
            return $Path
        }

        function script:Set-PhPlan {
            # One plan command: pwsh running $Script, with the plan's usual env_refs.
            param([Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)][string]$Script, [int]$TimeoutSeconds = 60)
            $command = [pscustomobject]@{
                command_id = 'home-probe'; executable = 'pwsh'; arguments = @('-NoProfile', '-NonInteractive', '-Command', $Script); timeout_seconds = $TimeoutSeconds
                env_refs = @($script:EnvRefs)
                provenance = [pscustomobject]@{ kind = 'project-config'; source = '.specrew/verification-plan.json' }; label = 'B5F-042 home probe'
            }
            $plan = [pscustomobject]@{ schema_version = '1.0'; plan_id = 'b5f042.fixture-plan.v1'; commands = @($command) }
            $path = Join-Path $Repo '.specrew/verification-plan.json'
            [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
            [IO.File]::WriteAllText($path, ($plan | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
        }

        function script:New-PhContext {
            param([Parameter(Mandatory)][string]$Root)
            $store = Join-Path $Root 'store'; $staging = Join-Path $Root 'staging'; $targets = Join-Path $Root 'targets'
            New-Item -ItemType Directory -Path $Root -Force | Out-Null
            $prompt = Join-Path $Root 'prompt.md'; [IO.File]::WriteAllText($prompt, 'bounded B5F-042 fixture prompt')
            $config = Join-Path $Root 'authority.json'; [IO.File]::WriteAllText($config, '{"schema_version":"1.0","mode":"campaign"}')
            $grant = [pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'grant'; campaign_id = 'cmp-ph'; grant_id = 'grant-ph'
                slots = 1; authority_kind = 'human'; authorization_ref = 'human-ph'; observed_at = '2026-11-11T00:00:00Z'
            }
            Add-ReviewCampaignGrantFact -StoreRoot $store -Fact $grant | Out-Null
            return [pscustomobject]@{ store = $store; staging = $staging; targets = $targets; prompt = $prompt; config = $config }
        }

        function script:New-PhHarness {
            param([Parameter(Mandatory)]$Capture)
            $preflight = { param($invocation) $Capture.preflight_count++; return [pscustomobject]@{ ok = $true; reason = 'fixture-ready' } }.GetNewClosure()
            $invoke = {
                param($invocation, $environment)
                $Capture.invoke_count++
                $candidate = [pscustomobject][ordered]@{
                    schema_version = '1.0'; run_id = [string]$invocation.run_id; target_digest = [string]$invocation.target_digest
                    completion = 'complete'; verdict = 'pass'; summary = 'fixture pass'; findings = @()
                }
                [IO.File]::WriteAllText([string]$invocation.candidate_result_path, ($candidate | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
                return [pscustomobject]@{ exit_code = 0; output_activity = $true }
            }.GetNewClosure()
            return [pscustomobject]@{ id = 'fixture-ph'; contract_version = '1.0'; preflight = $preflight; invoke = $invoke }
        }

        function script:Invoke-PhCampaign {
            param([string]$Repo, $Context, $Harness)
            return Invoke-ReviewCampaignRun -StoreRoot $Context.store -StagingRoot $Context.staging -CampaignId cmp-ph -RunId run-ph `
                -ReservationId res-ph -TargetLineage lin-ph -TargetPort (New-GitReviewTargetPort -OriginRepo $Repo -ExternalRoot $Context.targets) `
                -HarnessPort $Harness -RuntimePort (New-ReviewFixtureRuntimePort) -VerificationPort (New-ReviewProductionVerificationPort) `
                -ClockPort (New-ReviewSystemClockPort) -PromptPath $Context.prompt -TimeoutSeconds 60 -AuthorityConfigPath $Context.config
        }

        function script:New-PhRealHome {
            # A stand-in for the real home, holding one file at every hook path the check covers.
            param([Parameter(Mandatory)][string]$Path)
            foreach ($rel in @('.specrew/hooks/b958cbe133e6a88ee358f7c5f89d5a67/specrew-hook-launch.ps1', '.specrew/hooks/bindings/codex-1.binding',
                    '.specrew/hook-bindings/antigravity-1.binding', '.specrew/specrew-hook-launch.ps1', '.codex/hooks.json', '.cursor/hooks.json',
                    '.copilot/hooks/specrew-refocus.json', '.copilot/hooks/other-hooks.json')) {
                $full = Join-Path $Path $rel
                [IO.Directory]::CreateDirectory((Split-Path -Parent $full)) | Out-Null
                [IO.File]::WriteAllText($full, "original $rel")
            }
            return $Path
        }

        function script:Get-PhTree {
            param([Parameter(Mandatory)][string]$Path)
            if (-not (Test-Path -LiteralPath $Path)) { return @() }
            return @(Get-ChildItem -LiteralPath $Path -Recurse -File -Force | ForEach-Object { '{0} {1}' -f ($_.FullName.Substring($Path.Length) -replace '\\', '/'), (Get-FileHash -LiteralPath $_.FullName).Hash } | Sort-Object)
        }

        function script:ConvertTo-PsLiteral { param([string]$Value) return "'" + $Value.Replace("'", "''") + "'" }

        function script:New-PhDeployScript {
            # The deploy case's suite: it runs $Deployer for Codex with no redirect of its own, then lists what it wrote into
            # the home it was given (the preflight removes that home afterwards).
            # THE GUARD (DRIFT-056; maintainer rule 2026-11-11: written and proven before the test's first run). The
            # deployer writes the home it resolves, and with no redirect that is the REAL home: the first red run of this
            # case rewrote the maintainer's ~/.codex/hooks.json. So the suite deploys only when it was given a home that is
            # neither empty nor the stand-in for the real one; otherwise it exits 9 and writes nothing. The case before the
            # deploy case proves it with a canary in place of the deployer.
            param([Parameter(Mandatory)][string]$Deployer, [Parameter(Mandatory)][string]$Project, [Parameter(Mandatory)][string]$Listing, [Parameter(Mandatory)][string]$RealHome)
            return ('$h = [string]$env:SPECREW_USER_HOME_OVERRIDE; if ([string]::IsNullOrWhiteSpace($h) -or $h -eq {3}) {{ exit 9 }}; & {0} -ProjectPath {1} -HostKind codex *> $null; ' +
                '[IO.File]::WriteAllLines({2}, [string[]]@($h) + @(Get-ChildItem -LiteralPath $h -Recurse -File -Force | ForEach-Object {{ $_.FullName.Substring($h.Length) -replace ''\\'', ''/'' }})); exit 0') -f
                (ConvertTo-PsLiteral $Deployer), (ConvertTo-PsLiteral $Project), (ConvertTo-PsLiteral $Listing), (ConvertTo-PsLiteral $RealHome)
        }
        $script:DeployGuardProven = $false
    }

    AfterEach {
        if ($null -eq $script:SavedHome) { Remove-Item Env:\SPECREW_USER_HOME_OVERRIDE -ErrorAction SilentlyContinue }
        else { $env:SPECREW_USER_HOME_OVERRIDE = $script:SavedHome }
    }

    It 'gives the suite a temporary home under the system temp folder, not the caller''s, and removes it after a passing run' {
        $root = Join-Path $TestDrive 'pass'; $repo = New-PhRepo -Path (Join-Path $root 'origin')
        $realHome = New-PhRealHome -Path (Join-Path $root 'real-home')
        $env:SPECREW_USER_HOME_OVERRIDE = $realHome
        $seen = Join-Path $root 'seen-home.txt'
        Set-PhPlan -Repo $repo -Script ('[IO.File]::WriteAllText({0}, [string]$env:SPECREW_USER_HOME_OVERRIDE); exit 0' -f (ConvertTo-PsLiteral $seen))
        $context = New-PhContext -Root (Join-Path $root 'controller')
        $capture = [pscustomobject]@{ preflight_count = 0; invoke_count = 0 }

        $result = Invoke-PhCampaign -Repo $repo -Context $context -Harness (New-PhHarness -Capture $capture)

        $result.status | Should -Be 'terminal' -Because $result.reason
        $tempHome = [IO.File]::ReadAllText($seen)
        $tempHome | Should -Not -BeNullOrEmpty -Because 'the suite is given a home'
        $tempHome | Should -Not -Be $realHome -Because 'the caller''s home is never passed through'
        [IO.Path]::GetFullPath($tempHome).StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()), [StringComparison]::OrdinalIgnoreCase) | Should -BeTrue -Because 'it is under the system temp folder'
        [IO.Path]::GetFullPath($tempHome).StartsWith([IO.Path]::GetFullPath($repo), [StringComparison]::OrdinalIgnoreCase) | Should -BeFalse -Because 'never inside the project'
        [IO.Path]::GetFullPath($tempHome).StartsWith([IO.Path]::GetFullPath($context.targets), [StringComparison]::OrdinalIgnoreCase) | Should -BeFalse -Because 'never inside the frozen target'
        Test-Path -LiteralPath $tempHome | Should -BeFalse -Because 'it is removed when the preflight ends'
        $env:SPECREW_USER_HOME_OVERRIDE | Should -Be $realHome -Because 'the caller''s environment is restored'
    }

    It 'removes the temporary home after a failing suite too' {
        $root = Join-Path $TestDrive 'fail'; $repo = New-PhRepo -Path (Join-Path $root 'origin')
        $env:SPECREW_USER_HOME_OVERRIDE = New-PhRealHome -Path (Join-Path $root 'real-home')
        $seen = Join-Path $root 'seen-home.txt'
        Set-PhPlan -Repo $repo -Script ('[IO.File]::WriteAllText({0}, [string]$env:SPECREW_USER_HOME_OVERRIDE); exit 7' -f (ConvertTo-PsLiteral $seen))
        $context = New-PhContext -Root (Join-Path $root 'controller')
        $capture = [pscustomobject]@{ preflight_count = 0; invoke_count = 0 }

        $result = Invoke-PhCampaign -Repo $repo -Context $context -Harness (New-PhHarness -Capture $capture)

        $result.status | Should -Be 'failed'
        $tempHome = [IO.File]::ReadAllText($seen)
        $tempHome | Should -Not -BeNullOrEmpty
        Test-Path -LiteralPath $tempHome | Should -BeFalse -Because 'a failing preflight removes it as well'
    }

    It 'removes the temporary home when the preflight is cancelled' {
        $root = Join-Path $TestDrive 'cancel'; $repo = New-PhRepo -Path (Join-Path $root 'origin')
        $realHome = New-PhRealHome -Path (Join-Path $root 'real-home')
        $seen = Join-Path $root 'seen-home.txt'; $pidFile = Join-Path $root 'suite-pid.txt'
        Set-PhPlan -Repo $repo -TimeoutSeconds 120 -Script ('[IO.File]::WriteAllText({0}, [string]$PID); [IO.File]::WriteAllText({1}, [string]$env:SPECREW_USER_HOME_OVERRIDE); Start-Sleep -Seconds 90; exit 0' -f (ConvertTo-PsLiteral $pidFile), (ConvertTo-PsLiteral $seen))
        $context = New-PhContext -Root (Join-Path $root 'controller')
        $runner = @'
param($RepoRoot, $Repo, $Store, $Staging, $Targets, $Prompt, $Config, $RealHome)
$ErrorActionPreference = 'Stop'
$env:SPECREW_USER_HOME_OVERRIDE = $RealHome
. (Join-Path $RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
. (Join-Path $RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
$harness = [pscustomobject]@{ id = 'fixture-ph'; contract_version = '1.0'; preflight = { param($i) [pscustomobject]@{ ok = $true; reason = 'fixture-ready' } }; invoke = { param($i, $e) [pscustomobject]@{ exit_code = 0; output_activity = $true } } }
Invoke-ReviewCampaignRun -StoreRoot $Store -StagingRoot $Staging -CampaignId cmp-ph -RunId run-ph -ReservationId res-ph -TargetLineage lin-ph `
    -TargetPort (New-GitReviewTargetPort -OriginRepo $Repo -ExternalRoot $Targets) -HarnessPort $harness -RuntimePort (New-ReviewFixtureRuntimePort) `
    -VerificationPort (New-ReviewProductionVerificationPort) -ClockPort (New-ReviewSystemClockPort) -PromptPath $Prompt -TimeoutSeconds 60 -AuthorityConfigPath $Config
'@
        $ps = [PowerShell]::Create()
        $null = $ps.AddScript($runner).AddArgument($script:RepoRoot).AddArgument($repo).AddArgument($context.store).AddArgument($context.staging).AddArgument($context.targets).AddArgument($context.prompt).AddArgument($context.config).AddArgument($realHome)
        $handle = $ps.BeginInvoke()
        try {
            $deadline = [DateTime]::UtcNow.AddSeconds(60)
            while ([DateTime]::UtcNow -lt $deadline -and -not (Test-Path -LiteralPath $seen)) { Start-Sleep -Milliseconds 200 }
            Test-Path -LiteralPath $seen | Should -BeTrue -Because 'the suite started inside the preflight'
            $tempHome = [IO.File]::ReadAllText($seen)
            Test-Path -LiteralPath $tempHome | Should -BeTrue -Because 'the temporary home exists while the suite runs'
            $ps.Stop()
            try { $null = $ps.EndInvoke($handle) } catch { $null = $_ }
            Test-Path -LiteralPath $tempHome | Should -BeFalse -Because 'cancelling the preflight removes it'
        }
        finally {
            $ps.Dispose()
            if (Test-Path -LiteralPath $pidFile) { Stop-Process -Id ([int][IO.File]::ReadAllText($pidFile)) -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'proves the deploy guard first: with no home, or the real one, the suite never reaches the deployer' {
        # A canary stands in for the deployer: it records that it was called. Run outside any preflight, with the home
        # variable set as each condition needs; the real deployer is not involved.
        $root = Join-Path $TestDrive 'guard'; New-Item -ItemType Directory -Path $root -Force | Out-Null
        $realHome = New-PhRealHome -Path (Join-Path $root 'real-home')
        $canaryMark = Join-Path $root 'canary-called.txt'
        $canary = Join-Path $root 'canary.ps1'
        [IO.File]::WriteAllText($canary, ('[IO.File]::WriteAllText({0}, ''called'')' -f (ConvertTo-PsLiteral $canaryMark)))
        $guarded = New-PhDeployScript -Deployer $canary -Project (Join-Path $root 'project') -Listing (Join-Path $root 'listing.txt') -RealHome $realHome
        $saved = $env:SPECREW_USER_HOME_OVERRIDE
        try {
            foreach ($condition in @(@{ Name = 'no home'; Value = $null }, @{ Name = 'the real home'; Value = $realHome })) {
                if ($null -eq $condition.Value) { Remove-Item Env:\SPECREW_USER_HOME_OVERRIDE -ErrorAction SilentlyContinue } else { $env:SPECREW_USER_HOME_OVERRIDE = $condition.Value }
                $null = & pwsh -NoProfile -NonInteractive -Command $guarded 2>&1
                $LASTEXITCODE | Should -Be 9 -Because ('given {0}, the suite refuses' -f $condition.Name)
                Test-Path -LiteralPath $canaryMark | Should -BeFalse -Because ('given {0}, the deployer is never reached' -f $condition.Name)
            }
            $other = Join-Path $root 'given-home'; New-Item -ItemType Directory -Path $other -Force | Out-Null
            $env:SPECREW_USER_HOME_OVERRIDE = $other
            $null = & pwsh -NoProfile -NonInteractive -Command $guarded 2>&1
            $LASTEXITCODE | Should -Be 0 -Because 'given another home, the suite runs'
            Test-Path -LiteralPath $canaryMark | Should -BeTrue -Because 'and reaches the deployer'
        }
        finally {
            if ($null -eq $saved) { Remove-Item Env:\SPECREW_USER_HOME_OVERRIDE -ErrorAction SilentlyContinue } else { $env:SPECREW_USER_HOME_OVERRIDE = $saved }
        }
        $script:DeployGuardProven = $true
    }

    It 'lets a suite that deploys hooks without its own redirect write into the temporary home, leaving the real one unchanged' {
        if (-not $script:DeployGuardProven) { throw 'the deploy guard was not proven in this run, so the deploy case does not run (DRIFT-056)' }
        $root = Join-Path $TestDrive 'deploy'; $repo = New-PhRepo -Path (Join-Path $root 'origin')
        $realHome = New-PhRealHome -Path (Join-Path $root 'real-home')
        $env:SPECREW_USER_HOME_OVERRIDE = $realHome
        $realBefore = @(Get-PhTree -Path $realHome)
        $project = Join-Path $root 'deploy-project'; New-Item -ItemType Directory -Path $project -Force | Out-Null
        $deployer = Join-Path $script:RepoRoot 'scripts/internal/deploy-refocus-hooks.ps1'
        $listing = Join-Path $root 'temp-home-files.txt'
        $script = New-PhDeployScript -Deployer $deployer -Project $project -Listing $listing -RealHome $realHome
        Set-PhPlan -Repo $repo -TimeoutSeconds 120 -Script $script
        $context = New-PhContext -Root (Join-Path $root 'controller')
        $capture = [pscustomobject]@{ preflight_count = 0; invoke_count = 0 }

        $result = Invoke-PhCampaign -Repo $repo -Context $context -Harness (New-PhHarness -Capture $capture)

        $result.status | Should -Be 'terminal' -Because $result.reason
        $lines = @([IO.File]::ReadAllLines($listing))
        $lines[0] | Should -Not -Be $realHome
        @($lines | Select-Object -Skip 1 | Where-Object { $_ -like '/.codex/*' }).Count | Should -BeGreaterThan 0 -Because 'the deployer wrote the Codex hooks into the temporary home'
        @(Get-PhTree -Path $realHome) | Should -Be $realBefore -Because 'the real home is unchanged'
    }

    It 'fails the preflight, spending no round, when a suite <Case>; it restores nothing and names the file' -ForEach @(
        @{ Case = 'changes a hook file in the real home'; Rel = '.codex/hooks.json'; Action = 'change' }
        @{ Case = 'adds a binding under ~/.specrew/hooks/bindings'; Rel = '.specrew/hooks/bindings/added.binding'; Action = 'add' }
        @{ Case = 'removes a file from ~/.copilot/hooks'; Rel = '.copilot/hooks/other-hooks.json'; Action = 'remove' }
        @{ Case = 'changes the root launcher'; Rel = '.specrew/specrew-hook-launch.ps1'; Action = 'change' }
        @{ Case = 'changes a binding under ~/.specrew/hook-bindings'; Rel = '.specrew/hook-bindings/antigravity-1.binding'; Action = 'change' }
    ) {
        $root = Join-Path $TestDrive ('real-home-' + $Action + '-' + ($Rel -replace '[^a-z]', '')); $repo = New-PhRepo -Path (Join-Path $root 'origin')
        $realHome = New-PhRealHome -Path (Join-Path $root 'real-home')
        $env:SPECREW_USER_HOME_OVERRIDE = $realHome
        $target = Join-Path $realHome $Rel
        $script = switch ($Action) {
            'change' { '[IO.File]::WriteAllText({0}, ''rewritten by a suite''); exit 0' -f (ConvertTo-PsLiteral $target) }
            'add' { '[IO.File]::WriteAllText({0}, ''added by a suite''); exit 0' -f (ConvertTo-PsLiteral $target) }
            'remove' { 'Remove-Item -LiteralPath {0} -Force; exit 0' -f (ConvertTo-PsLiteral $target) }
        }
        Set-PhPlan -Repo $repo -Script $script
        $context = New-PhContext -Root (Join-Path $root 'controller')
        $capture = [pscustomobject]@{ preflight_count = 0; invoke_count = 0 }

        $result = Invoke-PhCampaign -Repo $repo -Context $context -Harness (New-PhHarness -Capture $capture)

        $result.status | Should -Be 'failed'
        $result.reason | Should -BeLike 'verification-changed-real-home:*'
        $result.reason | Should -Match ([regex]::Escape(('{0}: {1}' -f $(switch ($Action) { 'change' { 'changed' } 'add' { 'added' } 'remove' { 'removed' } }), $Rel)))
        $result.invoked | Should -BeFalse
        $capture.preflight_count | Should -Be 0 -Because 'the paid harness is never reached'
        $capture.invoke_count | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-ph -Kind spend).Count | Should -Be 0 -Because 'no round is spent'
        switch ($Action) {
            'change' { [IO.File]::ReadAllText($target) | Should -Be 'rewritten by a suite' -Because 'nothing is restored' }
            'add' { Test-Path -LiteralPath $target | Should -BeTrue -Because 'nothing is restored' }
            'remove' { Test-Path -LiteralPath $target | Should -BeFalse -Because 'nothing is restored' }
        }
    }
}
