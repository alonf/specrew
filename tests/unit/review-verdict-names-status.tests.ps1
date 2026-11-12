# Feature 206, T011 (FR-010): the review-verdict finding names the iteration's actual status.
#   A `retro` iteration whose review.md is not accepted is told "Retro iterations require ...", not
#   "Complete iterations require ..."; a `complete` iteration keeps its message.
#
# Runs the validator on a temp-folder project. No specrew start, update or init; no hooks; nothing written to
# the home folder.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'

    $script:Root = Join-Path ([System.IO.Path]::GetTempPath()) ('verdict-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path (Join-Path $script:Root '.specrew') -Force
    # The dev-tree renderer and its shared library, so the validator never falls back to an installed module.
    $null = New-Item -ItemType Directory -Path (Join-Path $script:Root 'scripts\internal') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $script:Root 'extensions\specrew-speckit\scripts') -Force
    Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts\internal\dashboard-renderer.ps1') -Destination (Join-Path $script:Root 'scripts\internal\dashboard-renderer.ps1')
    Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1') -Destination (Join-Path $script:Root 'extensions\specrew-speckit\scripts\shared-governance.ps1')
    $null = New-Item -ItemType Directory -Path (Join-Path $script:Root '.squad') -Force
    Copy-Item -LiteralPath (Join-Path $script:RepoRoot '.squad\team.md') -Destination (Join-Path $script:Root '.squad\team.md')

    function New-VerdictIteration {
        param([string]$Iteration, [string]$Status)
        $featureDir = Join-Path $script:Root 'specs\904-verdict'
        $dir = Join-Path $featureDir (Join-Path 'iterations' $Iteration)
        $null = New-Item -ItemType Directory -Path $dir -Force
        $spec = Join-Path $featureDir 'spec.md'
        if (-not (Test-Path -LiteralPath $spec)) { Set-Content -LiteralPath $spec -Value '# Feature Specification: 904-verdict' -Encoding UTF8 }
        Set-Content -LiteralPath (Join-Path $dir 'plan.md') -Value ("# Plan`n`n**Status**: $Status`n") -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'state.md') -Value ("# Iteration State: $Iteration`n`n**Schema**: v2`n**Iteration Status**: $Status`n") -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'drift-log.md') -Value "# Drift Log`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'retro.md') -Value "# Retro`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'review.md') -Value "# Review`n`n**Overall Verdict**: needs-rework`n" -Encoding UTF8
        return $dir
    }

    $script:RetroDir = New-VerdictIteration -Iteration '001' -Status 'retro'
    $script:CompleteDir = New-VerdictIteration -Iteration '002' -Status 'complete'

    function Invoke-VerdictValidator {
        param([string]$IterationPath)
        return (@(& pwsh -NoProfile -File $script:Validator -ProjectPath $script:Root -IterationPath $IterationPath 2>&1 | ForEach-Object { [string]$_ }) -join "`n")
    }
}

AfterAll {
    if ($script:Root -and (Test-Path -LiteralPath $script:Root)) {
        Remove-Item -LiteralPath $script:Root -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'T011: the review-verdict finding names the real status' {
    It 'a retro iteration is named as retro' {
        $output = Invoke-VerdictValidator -IterationPath $script:RetroDir
        $output | Should -Match "Retro iterations require review\.md overall verdict 'accepted' \(found 'needs-rework'\)"
        $output | Should -Not -Match 'Complete iterations require review\.md'
    }

    It 'a complete iteration keeps its message' {
        $output = Invoke-VerdictValidator -IterationPath $script:CompleteDir
        $output | Should -Match "Complete iterations require review\.md overall verdict 'accepted' \(found 'needs-rework'\)"
    }
}
