# specrew-test-home: not-a-writer - parses the deployer's three copies and runs only the hook command it builds, against a stub launcher in a temp folder; the deployer itself never runs (203 iteration 002 DRIFT-040)
# Feature 203 T025 (T006's launcher half; DRIFT-018, DRIFT-046): a hook refusal is written as plain text. T006 made the
# generated project launcher's refusals plain text, but the guarded-project-encoded hook command the deployer writes into
# the host's settings (Claude's .claude/settings.local.json) still threw when the project launcher was missing. Through
# pwsh -EncodedCommand that throw reaches the host as CLIXML with ANSI color codes. The command is built here from the
# deployer's own functions, taken from each of its three copies by parsing them; the deployer itself is never run, so
# nothing is deployed and no home is touched.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Copies = @(
        'scripts/internal/deploy-refocus-hooks.ps1'
        'extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1'
        '.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1'
    )
    $script:Work = Join-Path ([IO.Path]::GetTempPath()) ('hook-cmd-refusal-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $script:Work -Force

    # The manifest values the deployer reads for Claude, from the host manifest itself.
    $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $script:RepoRoot 'hosts/claude/host.psd1')
    $script:hookBindings = $manifest.RefocusHookBindings
    $script:hookCommandMode = [string]$script:hookBindings.CommandMode
    $script:hostManifestPath = 'hosts/claude/host.psd1'
    $settingsDirRel = (Split-Path -Parent ([string]$script:hookBindings.SettingsFile)) -replace '\\', '/'
    $script:projectLauncherRelPath = $settingsDirRel.TrimEnd('/') + '/specrew-hook-launch.ps1'
    $script:launcherModulePath = ''
    $script:hostRuntimeBinding = ''

    # One copy's command builder, defined in this scope under the deployer's own names.
    function script:Import-CommandBuilder([string]$Copy) {
        $path = Join-Path $script:RepoRoot $Copy
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$null)
        $names = @('Test-ManifestKey', 'Get-ManifestValue', 'Get-GuardedProjectRootVariable', 'Get-SpecrewHookCommand')
        foreach ($name in $names) {
            $fn = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $true)
            if ($null -eq $fn) { throw "fixture: $name not found in $Copy" }
            . ([scriptblock]::Create(($fn.Extent.Text -replace '^function\s+', 'function script:')))
        }
    }

    # Runs a generated command the way a host does: a new pwsh with the project root in the host's variable.
    function script:Invoke-HookCommand([string]$Command, [string]$ProjectRoot, [string]$Name) {
        $encoded = ($Command -split '-EncodedCommand\s+')[1].Trim()
        $out = Join-Path $script:Work "$Name.out"; $err = Join-Path $script:Work "$Name.err"
        $saved = $env:CLAUDE_PROJECT_DIR
        try {
            $env:CLAUDE_PROJECT_DIR = $ProjectRoot
            $p = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encoded) `
                -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
        }
        finally { $env:CLAUDE_PROJECT_DIR = $saved }
        [pscustomobject]@{ Exit = $p.ExitCode; Out = [string](Get-Content -LiteralPath $out -Raw); Err = [string](Get-Content -LiteralPath $err -Raw) }
    }
}

AfterAll {
    if ((Split-Path -Leaf $script:Work) -like 'hook-cmd-refusal-*') { Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'T025 (T006 launcher half): the generated Claude hook command refuses in plain text' -ForEach @(
    @{ Copy = 'scripts/internal/deploy-refocus-hooks.ps1' }
    @{ Copy = 'extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1' }
    @{ Copy = '.specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1' }
) {
    BeforeAll {
        script:Import-CommandBuilder -Copy $Copy
        $script:Tag = ($Copy -replace '[^A-Za-z0-9]', '-')
    }

    It 'with the project launcher missing, says so in plain text on stderr and exits 1 (<Copy>)' {
        $project = Join-Path $script:Work ('missing-' + $script:Tag)
        $null = New-Item -ItemType Directory -Path $project -Force
        $result = script:Invoke-HookCommand -Command (Get-SpecrewHookCommand -EventName 'Stop') -ProjectRoot $project -Name ('missing-' + $script:Tag)
        $result.Exit | Should -Be 1
        $result.Err | Should -Not -Match 'CLIXML' -Because 'a thrown error under -EncodedCommand reaches the host serialized'
        $result.Err | Should -Not -Match "`e\[" -Because 'no ANSI color codes'
        $result.Err | Should -Not -Match '(?m)^\s*\|' -Because "no error-view '|' gutter"
        $result.Err | Should -Match 'Specrew could not find its hook launcher at'
        $result.Err | Should -Match ([regex]::Escape((Join-Path $project '.claude/specrew-hook-launch.ps1')) -replace '\\\\|/', '[\\/]')
        $result.Out | Should -BeNullOrEmpty
    }

    It 'with the project launcher present, runs it with the same arguments and exit code as before (pinned) (<Copy>)' {
        $project = Join-Path $script:Work ('present-' + $script:Tag)
        $null = New-Item -ItemType Directory -Path (Join-Path $project '.claude') -Force
        Set-Content -LiteralPath (Join-Path $project '.claude/specrew-hook-launch.ps1') -Encoding utf8NoBOM `
            -Value 'param([string]$Event) "ran:${Event}:$($args.Count)"; [Console]::Error.WriteLine("stub-err"); exit ([int]$env:T025_STUB_EXIT)'
        foreach ($case in @(@{ code = '3'; expect = 1 }, @{ code = '0'; expect = 0 })) {
            $env:T025_STUB_EXIT = $case.code
            try { $result = script:Invoke-HookCommand -Command (Get-SpecrewHookCommand -EventName 'Stop') -ProjectRoot $project -Name ('present-' + $case.code + $script:Tag) }
            finally { Remove-Item Env:\T025_STUB_EXIT -ErrorAction SilentlyContinue }
            $result.Out.Trim() | Should -BeExactly 'ran:Stop:0'
            $result.Err.Trim() | Should -BeExactly 'stub-err'
            $result.Exit | Should -Be $case.expect -Because "a launcher exiting $($case.code) left the command's exit at $($case.expect) before this change"
        }
    }

    It 'with no project root, does nothing and exits 0 (pinned) (<Copy>)' {
        $result = script:Invoke-HookCommand -Command (Get-SpecrewHookCommand -EventName 'Stop') -ProjectRoot '' -Name ('noroot-' + $script:Tag)
        $result.Exit | Should -Be 0
        $result.Out | Should -BeNullOrEmpty
        $result.Err | Should -BeNullOrEmpty
    }

    It 'stays within half of cmd.exe''s 8,191-character limit for every event (<Copy>)' {
        foreach ($event in 'SessionStart', 'UserPromptSubmit', 'PreToolUse', 'PostToolUse', 'Stop', 'PreCompact', 'SubagentStop') {
            (Get-SpecrewHookCommand -EventName $event).Length | Should -BeLessOrEqual 4095 -Because "the $event command"
        }
    }
}
