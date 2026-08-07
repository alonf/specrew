$ErrorActionPreference = 'Stop'

# beta2 RELEASE BLOCKER regression (maintainer 2026-07-13): released 0.40.0 fails during "Deploying Squad
# runtime" because deploy-squad-runtime.ps1 reads specs/197-continuous-co-review/contracts/ (Copy-ManagedDirectory
# THROWS on a missing source dir) but those files were absent from the Specrew.psd1 FileList - so the packaged
# module did not ship them. This test builds the module from the FileList ONLY, imports it, runs the deploy step
# init runs, verifies .specrew/review/contracts is deployed, and fails if ANY deploy source is absent from the
# package.
Describe 'Packaged-artifact Squad-runtime deploy (beta2 release blocker)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        $script:Manifest = Import-PowerShellDataFile -Path (Join-Path $script:RepoRoot 'Specrew.psd1')
        $script:FileList = @($script:Manifest.FileList)

        # (1) BUILD THE MODULE USING ONLY FileList: stage a copy containing exactly the FileList files.
        $script:StageRoot = Join-Path $TestDrive ('staged-' + [guid]::NewGuid().ToString('N'))
        foreach ($rel in $script:FileList) {
            $src = Join-Path $script:RepoRoot $rel
            $dst = Join-Path $script:StageRoot $rel
            $dstDir = Split-Path -Parent $dst
            if (-not (Test-Path -LiteralPath $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
            Copy-Item -LiteralPath $src -Destination $dst -Force
        }
        $script:StagedManifest = Join-Path $script:StageRoot 'Specrew.psd1'
        $script:StagedDeploy = Join-Path $script:StageRoot 'extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1'
    }

    It '(2)+(3)+(4): the STAGED module imports, and its Squad-runtime deploy lands .specrew/review/contracts in a clean project' {
        Test-Path -LiteralPath $script:StagedDeploy -PathType Leaf | Should -BeTrue -Because 'the deploy script itself must be packaged'

        $project = Join-Path $TestDrive ('proj-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $project '.squad') -Force | Out-Null   # the deploy runs only when .squad exists (init's brownfield guard)

        # Import the STAGED module, then run the exact "Deploying Squad runtime" step - in an ISOLATED child pwsh
        # so it exercises ONLY the packaged files (and never the dev tree or the loaded session module).
        $driver = @"
`$ErrorActionPreference = 'Stop'
Import-Module '$($script:StagedManifest -replace "'", "''")' -Force
& '$($script:StagedDeploy -replace "'", "''")' -ProjectPath '$($project -replace "'", "''")'
exit `$LASTEXITCODE
"@
        $driverFile = Join-Path $TestDrive ('driver-' + [guid]::NewGuid().ToString('N') + '.ps1')
        Set-Content -LiteralPath $driverFile -Value $driver -Encoding UTF8
        $out = & (Get-Process -Id $PID).Path -NoProfile -NonInteractive -File $driverFile 2>&1
        $LASTEXITCODE | Should -Be 0 -Because "the packaged deploy must succeed (output: $($out -join ' | '))"

        $contractsTarget = Join-Path $project '.specrew/review/contracts'
        Test-Path -LiteralPath $contractsTarget -PathType Container | Should -BeTrue -Because 'the deploy must land the review contracts'
        Test-Path -LiteralPath (Join-Path $contractsTarget 'findings-result.schema.json') | Should -BeTrue
        @(Get-ChildItem -LiteralPath $contractsTarget -Filter '*.schema.json').Count | Should -BeGreaterOrEqual 6
    }

    It '(5): every source deploy-squad-runtime.ps1 reads is present in the FileList package' {
        $fileListSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($rel in $script:FileList) { $null = $fileListSet.Add(($rel -replace '\\', '/')) }

        # Whole DIRECTORIES the deploy copies (Copy-ManagedDirectory -Recurse) - every file must be packaged.
        $dirSources = @(
            'scripts/internal/continuous-co-review',
            'scripts/internal/agent-tasks',
            'specs/197-continuous-co-review/contracts'
        )
        # Individual FILES the deploy reads (the script + its dot-sourced helper + the single-file runtime dep).
        $fileSources = @(
            'scripts/internal/atomic-write.ps1',
            'extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1',
            'extensions/specrew-speckit/scripts/shared-governance.ps1'
        )

        $missing = New-Object System.Collections.Generic.List[string]
        foreach ($dir in $dirSources) {
            $abs = Join-Path $script:RepoRoot $dir
            Test-Path -LiteralPath $abs -PathType Container | Should -BeTrue -Because "the deploy source dir '$dir' must exist"
            foreach ($f in @(Get-ChildItem -LiteralPath $abs -File -Recurse)) {
                $rel = ([System.IO.Path]::GetRelativePath($script:RepoRoot, $f.FullName)) -replace '\\', '/'
                if (-not $fileListSet.Contains($rel)) { $missing.Add($rel) | Out-Null }
            }
        }
        foreach ($f in $fileSources) {
            if (-not $fileListSet.Contains(($f -replace '\\', '/'))) { $missing.Add($f) | Out-Null }
        }
        ($missing -join ', ') | Should -BeNullOrEmpty -Because 'every deploy-squad-runtime source must be in the Specrew.psd1 FileList, else the packaged deploy fails or silently drops runtime files'
    }
}
