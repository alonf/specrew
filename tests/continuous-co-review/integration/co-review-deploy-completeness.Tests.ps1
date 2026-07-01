$ErrorActionPreference = 'Stop'

# F-197 deploy-completeness guard. The co-review deploy (deploy-squad-runtime.ps1) shipped
# continuous-co-review/ + the contracts but NOT the isolated-task launcher (agent-tasks/) or its
# atomic-write dependency, so on every deployed project the navigator reached fire and fail-opened to a
# SILENT no-op - co-review was inert on real projects. This guard catches the CLASS (a freshly-deployed
# runtime that cannot LOAD + FIRE), not just today's two filenames: it deploys into a clean project, then -
# in an ISOLATED child process (so the worktree's own loaded functions cannot mask a missing deployed file)
# - dot-sources the DEPLOYED navigator and asserts the launcher + atomic-write loaded and the contract
# schema resolves. Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'F-197 co-review deploy is complete (deployed runtime loads + can fire)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:DeployScript = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1'
    }

    It 'deploys a co-review runtime whose launcher + atomic-write load and whose contracts resolve' {
        $proj = Join-Path $TestDrive 'deployed-project'
        # Minimal init surfaces the runtime-deploy step requires (it is a part of init, not standalone).
        foreach ($d in @('.squad', '.specrew', '.specify')) { New-Item -ItemType Directory -Path (Join-Path $proj $d) -Force | Out-Null }

        & $script:DeployScript -ProjectPath $proj | Out-Null

        # The fire-path dependency set must be present.
        (Test-Path (Join-Path $proj 'scripts/internal/agent-tasks/isolated-task-launcher.ps1')) | Should -Be $true
        (Test-Path (Join-Path $proj 'scripts/internal/agent-tasks/isolated-task-supervisor.ps1')) | Should -Be $true
        (Test-Path (Join-Path $proj 'scripts/internal/atomic-write.ps1')) | Should -Be $true
        (Test-Path (Join-Path $proj 'scripts/internal/continuous-co-review/_load.ps1')) | Should -Be $true
        (Test-Path (Join-Path $proj '.specrew/review/contracts/findings-result.schema.json')) | Should -Be $true

        # CLASS guard: dot-source the DEPLOYED runtime in an ISOLATED child process (no worktree functions
        # in scope) and confirm it LOADS + can fire - this trips on ANY missing deployed dependency.
        $probe = @"
`$ErrorActionPreference = 'Stop'
`$proj = '$($proj -replace "'", "''")'
`$env:SPECREW_MODULE_PATH = `$proj
. (Join-Path `$proj 'scripts/internal/continuous-co-review/_load.ps1')
. (Join-Path `$proj 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
`$canFire = (`$null -ne (Get-Command Start-SpecrewIsolatedTask -ErrorAction SilentlyContinue)) -and (`$null -ne (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue))
`$cr = Get-ContinuousCoReviewContractRoot -RepoRoot `$proj
`$schemaOk = Test-Path (Join-Path `$cr 'findings-result.schema.json')
if (`$canFire -and `$schemaOk) { 'LOADS-AND-FIRES' } else { 'BROKEN' }
"@
        $probeFile = Join-Path $TestDrive 'deploy-probe.ps1'
        Set-Content -LiteralPath $probeFile -Value $probe -Encoding UTF8
        $result = (& pwsh -NoProfile -NonInteractive -File $probeFile 2>&1 | Select-Object -Last 1)
        [string]$result | Should -Be 'LOADS-AND-FIRES'
    }
}
