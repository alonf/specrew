# Feature 203 T008 (DRIFT-028, DRIFT-051): a review launch for a project with a live-engine pin runs the pin's engine,
# from the pin's own review command only; with no pin the launch resolves exactly as before. Fixtures only: no reviewer
# host is started, and the CLI cases stop at engine resolution, before any review store is touched.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:RepoRoot 'scripts/internal/review-engine-resolution.ps1')
    . (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/live-engine-resolution.ps1')
    $script:ReviewCli = Join-Path $script:RepoRoot 'scripts/specrew-review.ps1'
    $script:PinRequiredFiles = @(
        'scripts/internal/bootstrap/HandoverStore.ps1',
        'scripts/internal/bootstrap/HumanAuthorityStore.ps1',
        'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1',
        'scripts/internal/continuous-co-review/worktree-navigator.ps1',
        'extensions/specrew-speckit/scripts/shared-governance.ps1',
        '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
    )
    $script:PinCommit = 'a489e6c07976c68ac4224aa60283b2466f2a2596'

    function Write-FixtureText([string]$Path, [string]$Text) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
        [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
    }

    function New-EngineFixture([string]$Root, [string]$Content) {
        Write-FixtureText (Join-Path $Root '_load.ps1') "`$script:loaded = '$Content'"
        Write-FixtureText (Join-Path $Root 'engine.ps1') $Content
    }

    # A detached checkout as the pin reader sees it: .git/HEAD holds the bare commit, the engine files exist.
    function New-PinFixture([string]$Root, [string]$Commit) {
        foreach ($rel in $script:PinRequiredFiles) { Write-FixtureText (Join-Path $Root $rel) '# fixture' }
        New-EngineFixture -Root (Join-Path $Root 'scripts/internal/continuous-co-review') -Content 'pin-engine'
        Write-FixtureText (Join-Path $Root '.git/HEAD') $Commit
    }

    # A project whose own engine copy has drifted from its marker: the pre-T008 resolver refuses it.
    function New-DriftedProjectFixture([string]$Root) {
        $runtime = Join-Path $Root 'scripts/internal/continuous-co-review'
        New-EngineFixture -Root $runtime -Content 'project-engine-edited'
        $marker = [ordered]@{ schema_version = '1.0'; specrew_version = '0.40.0'; runtime_bundle_sha256 = ('0' * 64); source = 'test' }
        Write-FixtureText (Join-Path $runtime '.specrew-runtime.json') ($marker | ConvertTo-Json)
    }

    function Write-PinRecord([string]$ProjectRoot, [string]$PinRoot, [string]$Commit) {
        Write-FixtureText (Join-Path $ProjectRoot '.specrew/runtime/live-engine.json') ([ordered]@{ path = $PinRoot; commit = $Commit } | ConvertTo-Json)
    }

    function Invoke-ReviewCliLive([string]$ProjectRoot) {
        $stdout = Join-Path $ProjectRoot '..\cli-out.txt'
        $stderr = Join-Path $ProjectRoot '..\cli-err.txt'
        $stdin = Join-Path $ProjectRoot '..\cli-in.txt'
        [IO.File]::WriteAllText($stdin, '')
        $process = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-NonInteractive', '-File', $script:ReviewCli, '-ProjectPath', $ProjectRoot, '-Live') `
            -RedirectStandardInput $stdin `
            -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru -Wait
        # The child's error view wraps the message over boxed, coloured lines; read it back as one line of words.
        $text = (Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue) + (Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue)
        $text = (($text -replace "`e\[[0-9;]*m", '') -replace '\s*\|\s+', ' ') -replace '\s+', ' '
        return [pscustomobject]@{ ExitCode = $process.ExitCode; Text = $text }
    }
}

Describe 'a pinned project reviews with the pin''s engine (DRIFT-051)' {
    BeforeEach {
        $script:Scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-pinned-launch-' + [guid]::NewGuid().ToString('N'))
        $script:Project = Join-Path $script:Scratch 'project'
        $script:Pin = Join-Path $script:Scratch 'pin'
        $script:OtherCli = Join-Path $script:Scratch 'other/scripts/internal/continuous-co-review'
        New-DriftedProjectFixture -Root $script:Project
        New-PinFixture -Root $script:Pin -Commit $script:PinCommit
        New-EngineFixture -Root $script:OtherCli -Content 'other-engine'
    }
    AfterEach { Remove-Item -LiteralPath $script:Scratch -Recurse -Force -ErrorAction SilentlyContinue }

    It 'with no pin, resolves exactly as before' {
        $clean = Join-Path $script:Scratch 'clean-project'
        New-Item -ItemType Directory -Force -Path $clean | Out-Null
        $selection = Resolve-SpecrewReviewEngineForLaunch -ProjectRoot $clean -InstalledRuntimeRoot $script:OtherCli -Pin (Get-SpecrewLiveEnginePin -ProjectRoot $clean)
        $selection.source | Should -BeExactly 'installed'
        $selection.runtime_root | Should -Be (Resolve-Path -LiteralPath $script:OtherCli).Path
        { Resolve-SpecrewReviewEngineForLaunch -ProjectRoot $script:Project -InstalledRuntimeRoot $script:OtherCli -Pin $null } |
            Should -Throw '*review-engine-project-runtime-drifted*'
    }

    It 'from the pin''s own command, loads the pin''s engine and never reads the project''s drifted copy' {
        Write-PinRecord -ProjectRoot $script:Project -PinRoot $script:Pin -Commit $script:PinCommit
        $pinEngine = Join-Path $script:Pin 'scripts/internal/continuous-co-review'
        $selection = Resolve-SpecrewReviewEngineForLaunch -ProjectRoot $script:Project -InstalledRuntimeRoot $pinEngine -Pin (Get-SpecrewLiveEnginePin -ProjectRoot $script:Project)
        $selection.source | Should -BeExactly 'pin'
        $selection.runtime_root | Should -Be ([IO.Path]::GetFullPath($pinEngine))
        $selection.bundle_sha256 | Should -BeExactly (Get-SpecrewReviewRuntimeBundleSha256 -RuntimeRoot $pinEngine)
    }

    It 'from any other copy of the command, refuses and names the pin''s command' {
        Write-PinRecord -ProjectRoot $script:Project -PinRoot $script:Pin -Commit $script:PinCommit
        $refusal = $null
        try { Resolve-SpecrewReviewEngineForLaunch -ProjectRoot $script:Project -InstalledRuntimeRoot $script:OtherCli -Pin (Get-SpecrewLiveEnginePin -ProjectRoot $script:Project) }
        catch { $refusal = $_.Exception }
        $refusal | Should -Not -BeNullOrEmpty
        $refusal.Data['specrew_reason'] | Should -BeExactly 'review-engine-not-pinned-launch'
        $refusal.Message | Should -BeLike '*Nothing was launched, recorded or spent*'
        $refusal.Message | Should -BeLike ('*' + (Join-Path $script:Pin 'scripts/specrew-review.ps1') + '*')
    }

    It 'with a configured pin that cannot be used, refuses and never falls back to the project or the command''s own engine' {
        Write-PinRecord -ProjectRoot $script:Project -PinRoot $script:Pin -Commit ('b' * 40)
        $refusal = $null
        $pinEngine = Join-Path $script:Pin 'scripts/internal/continuous-co-review'
        try { Resolve-SpecrewReviewEngineForLaunch -ProjectRoot $script:Project -InstalledRuntimeRoot $pinEngine -Pin (Get-SpecrewLiveEnginePin -ProjectRoot $script:Project) }
        catch { $refusal = $_.Exception }
        $refusal | Should -Not -BeNullOrEmpty
        $refusal.Data['specrew_reason'] | Should -BeExactly 'review-engine-pin-unusable'
        $refusal.Message | Should -BeLike '*is not at the reviewed commit it was set to*'
    }

    It 'through the review command: a project pinned elsewhere is refused before any review state is written' {
        Write-PinRecord -ProjectRoot $script:Project -PinRoot $script:Pin -Commit $script:PinCommit
        $before = @(Get-ChildItem -LiteralPath $script:Project -Recurse -File | ForEach-Object FullName | Sort-Object)
        $result = Invoke-ReviewCliLive -ProjectRoot $script:Project
        $result.ExitCode | Should -Be 1
        $result.Text | Should -BeLike '*this review command is a different copy*'
        @(Get-ChildItem -LiteralPath $script:Project -Recurse -File | ForEach-Object FullName | Sort-Object) | Should -Be $before
    }

    It 'through the review command: a configured pin that is missing is refused in plain words' {
        Write-PinRecord -ProjectRoot $script:Project -PinRoot (Join-Path $script:Scratch 'no-such-pin') -Commit $script:PinCommit
        $result = Invoke-ReviewCliLive -ProjectRoot $script:Project
        $result.ExitCode | Should -Be 1
        $result.Text | Should -BeLike '*could not be used*does not exist*'
        $result.Text | Should -Not -BeLike '*review-engine-project-runtime-drifted*'
    }
}
