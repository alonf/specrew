$ErrorActionPreference = 'Stop'

# Trace: T032, FR-012, FR-013, IMPL-004, TG-012, SC-006, TG-011.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T032 TG-011 TG-012 reviewer host adapter registry obeys implementation-rules.yml protected naming' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:ReviewerModuleRoot = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review'
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Get-T032Command {
                $command = Get-Command -Name 'Get-ContinuousCoReviewReviewerHostAdapterRegistry' -ErrorAction SilentlyContinue
                $null = ($command | Should -Not -BeNullOrEmpty)
                return $command
            }

        function New-T032AdapterRoot {
                $adapterRoot = Join-Path $TestDrive 'adapter-root'
                New-Item -ItemType Directory -Path $adapterRoot -Force | Out-Null
                foreach ($fileName in @(
                        'reviewer-host-adapter-claude-prompt.ps1',
                        'reviewer-host-adapter-codex-exec.ps1',
                        'reviewer-host-adapter-copilot-prompt.ps1',
                        'reviewer-host-adapter-example-dropin.ps1',
                        'reviewer-host-adapter-fixture.ps1',
                        'provider-adapter.ps1',
                        'provider-github.ps1',
                        'host-runtime-inventory.ps1',
                        'reviewer-provider-adapter-ambiguous.ps1')) {
                    Set-Content -LiteralPath (Join-Path $adapterRoot $fileName) -Value "# fixture $fileName" -Encoding UTF8
                }
                return $adapterRoot
            }
}

    

    

    It 'declares the T032 reviewer-domain adapter registry command before execution engine lookup' {
        Get-T032Command | Should -Not -BeNullOrEmpty
    }

    It 'registers only adapter files named reviewer-host-adapter-*.ps1 from the reviewer module root' {
        $command = Get-T032Command
        $adapterRoot = New-T032AdapterRoot

        $registry = & $command -AdapterRoot $adapterRoot
        $registeredFileNames = @($registry.adapters | ForEach-Object { Split-Path -Path $_.path -Leaf })

        ($registeredFileNames -contains 'reviewer-host-adapter-claude-prompt.ps1') | Should -Be $true
        ($registeredFileNames -contains 'reviewer-host-adapter-codex-exec.ps1') | Should -Be $true
        ($registeredFileNames -contains 'reviewer-host-adapter-copilot-prompt.ps1') | Should -Be $true
        ($registeredFileNames -contains 'reviewer-host-adapter-example-dropin.ps1') | Should -Be $true
        ($registeredFileNames -contains 'reviewer-host-adapter-fixture.ps1') | Should -Be $true
        ($registeredFileNames -contains 'provider-adapter.ps1') | Should -Be $false
        ($registeredFileNames -contains 'provider-github.ps1') | Should -Be $false
        ($registeredFileNames -contains 'host-runtime-inventory.ps1') | Should -Be $false
        ($registeredFileNames -contains 'reviewer-provider-adapter-ambiguous.ps1') | Should -Be $false
    }

    It 'uses adapter ids derived from reviewer-host-adapter file names, not F-184 provider ids' {
        $command = Get-T032Command
        $adapterRoot = New-T032AdapterRoot

        $registry = & $command -AdapterRoot $adapterRoot
        $adapterIds = @($registry.adapters | ForEach-Object { $_.adapter_id })

        foreach ($adapterId in $adapterIds) {
            $adapterId | Should -Match '^reviewer-host-adapter-[a-z0-9-]+$'
        }
        ($adapterIds -join ',') | Should -Not -Match 'provider-adapter|provider-generic|provider-github|capability-detector'
    }

    It 'derives host adapter function names by file-name convention while preserving the fixture seam' {
        $command = Get-T032Command
        $adapterRoot = New-T032AdapterRoot

        $registry = & $command -AdapterRoot $adapterRoot
        $functionNamesByAdapterId = @{}
        foreach ($adapter in $registry.adapters) {
            $functionNamesByAdapterId[$adapter.adapter_id] = $adapter.function_name
        }

        $functionNamesByAdapterId['reviewer-host-adapter-claude-prompt'] | Should -Be 'Invoke-ContinuousCoReviewReviewerHostAdapterClaudePrompt'
        $functionNamesByAdapterId['reviewer-host-adapter-codex-exec'] | Should -Be 'Invoke-ContinuousCoReviewReviewerHostAdapterCodexExec'
        $functionNamesByAdapterId['reviewer-host-adapter-copilot-prompt'] | Should -Be 'Invoke-ContinuousCoReviewReviewerHostAdapterCopilotPrompt'
        $functionNamesByAdapterId['reviewer-host-adapter-example-dropin'] | Should -Be 'Invoke-ContinuousCoReviewReviewerHostAdapterExampleDropin'
        $functionNamesByAdapterId['reviewer-host-adapter-fixture'] | Should -Be 'Invoke-ContinuousCoReviewFixtureReviewerPath'
    }

    It 'does not reference protected F-184 provider, registry, host-runtime, refocus, or shared governance surfaces' {
        $sourcePath = Join-Path $script:ReviewerModuleRoot 'reviewer-host-adapter-registry.ps1'
        (Test-Path -LiteralPath $sourcePath -PathType Leaf) | Should -Be $true
        $source = Get-Content -LiteralPath $sourcePath -Raw

        $source | Should -Not -Match 'switch\s*\(\s*\$AdapterId\s*\)'
        $source | Should -Not -Match 'extensions/specrew-speckit/scripts/provider-adapter\.ps1'
        $source | Should -Not -Match 'provider-(adapter|generic|github)\.ps1'
        $source | Should -Not -Match 'hosts/_registry\.ps1|host-runtime-inventory\.ps1|shared-governance\.ps1|validate-governance\.ps1|refocus\.ps1'
    }
}
