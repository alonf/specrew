$ErrorActionPreference = 'Stop'

Describe 'Spec Kit init preflight path isolation' {
    BeforeAll {
        function Invoke-NativeCommandForOutput { throw 'test double was not installed' }
        . (Join-Path $PSScriptRoot '..\..\scripts\init\spec-kit-deploy.ps1')
    }

    It 'uses a short disposable temp root rather than nesting a full probe below the consumer project' {
        $consumerRoot = Join-Path $TestDrive ('consumer-' + ('x' * 120))
        New-Item -ItemType Directory -Path $consumerRoot -Force | Out-Null
        $script:observedProbeRoot = $null
        Mock Invoke-NativeCommandForOutput {
            param($FilePath, $ArgumentList, $WorkingDirectory)
            $script:observedProbeRoot = [IO.Path]::GetFullPath($WorkingDirectory)
            return [pscustomobject]@{ ExitCode = 0; Output = @() }
        }

        $result = Test-SpecifyInitPreflight -ProjectPath $consumerRoot `
            -ArgumentList @('init', '--here') -SpecKitVersion '0.12.9'

        $result.Ready | Should -BeTrue
        $script:observedProbeRoot | Should -Not -BeNullOrEmpty
        $script:observedProbeRoot.StartsWith([IO.Path]::GetFullPath($consumerRoot), [StringComparison]::OrdinalIgnoreCase) |
            Should -BeFalse -Because 'the safety probe must not make a valid target fail only by deepening its path'
        (Split-Path -Leaf $script:observedProbeRoot) | Should -Match '^specrew-specify-probe-[a-f0-9]{32}$'
        $script:observedProbeRoot.Length | Should -BeLessThan 160
        Test-Path -LiteralPath $script:observedProbeRoot | Should -BeFalse -Because 'the disposable probe is always removed'
    }
}
