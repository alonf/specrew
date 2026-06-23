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

        # F-197 maintainer-authorized exception (2026-06-24): the maintainer AUTHORIZED editing the
        # F-184-protected scripts/internal/specrew-hook-dispatcher.ps1 to fix two dispatcher gaps the Feature 197
        # continuous co-review navigator surfaced - (1) adding co-review-navigator to the --event-json clean-args
        # allow-list so the navigator launches on Codex Stop, and (2) merging stop-block reasons from all
        # providers so a navigator stop-block no longer overwrites a co-occurring conformance stop-block. The
        # dispatcher STAYS in $ProtectedSurfacePaths above (the surface remains guarded for every OTHER change);
        # this narrowly whitelists ONLY this one path for THIS authorized F-197 change. Remove this entry once
        # the change lands on main and the authorization is consumed.
        $script:F197AuthorizedSurfaceExceptions = @(
            'scripts/internal/specrew-hook-dispatcher.ps1'
        )
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
                # F-197: a maintainer-authorized exception path is allowed to differ; skip it (the surface stays
                # protected for every other path). Scoped narrowly so the guard's intent is intact.
                if ($changedPath -in $script:F197AuthorizedSurfaceExceptions) { continue }
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
