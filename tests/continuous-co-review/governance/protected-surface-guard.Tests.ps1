$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 protected surface guard' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ProtectedSurfacePaths = @(
            'hosts/_registry.ps1'
            'hosts/_team-canonical.ps1'
            'hosts/claude/handlers.ps1'
            'hosts/codex/handlers.ps1'
            'hosts/copilot/handlers.ps1'
            'scripts/specrew-host.ps1'
            'scripts/specrew-hooks.ps1'
            'scripts/internal/host-runtime-inventory.ps1'
            'scripts/internal/host-history.ps1'
            'scripts/internal/host-flag-translation.ps1'
            'scripts/internal/specrew-hook-dispatcher.ps1'
            'scripts/internal/specrew-hook-health.ps1'
            'scripts/internal/refocus.ps1'
            'scripts/internal/refocus-deploy-integration.ps1'
            'extensions/specrew-speckit/scripts/provider-adapter.ps1'
            'extensions/specrew-speckit/scripts/provider-generic.ps1'
            'extensions/specrew-speckit/scripts/provider-github.ps1'
            'extensions/specrew-speckit/scripts/capability-detector.ps1'
            'extensions/specrew-speckit/scripts/refocus.ps1'
            'extensions/specrew-speckit/scripts/shared-governance.ps1'
            'extensions/specrew-speckit/scripts/validate-governance.ps1'
        )

        $script:ProtectedSurfacePaths += $script:ProtectedSurfacePaths |
            Where-Object { $_ -like 'extensions/specrew-speckit/scripts/*' } |
            ForEach-Object { ".specify/$_" }
    }

    It 'keeps the current git diff outside F-184 protected surfaces' {
        Push-Location -LiteralPath $script:RepoRoot
        try {
            $changedPaths = @(& git --no-pager diff --name-only)
            $gitExitCode = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }

        $gitExitCode | Should Be 0

        $normalizedChangedPaths = @(
            $changedPaths |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                ForEach-Object { $_.Trim().Replace('\', '/') }
        )

        $violations = @(
            foreach ($changedPath in $normalizedChangedPaths) {
                foreach ($protectedPath in $script:ProtectedSurfacePaths) {
                    if (($changedPath -eq $protectedPath) -or $changedPath.StartsWith("$protectedPath/")) {
                        $changedPath
                    }
                }
            }
        ) | Select-Object -Unique

        ($violations -join "`n") | Should Be ''
    }
}
