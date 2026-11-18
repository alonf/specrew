# Feature 206, T024 (SC-001, bug list item 25's init case): `specrew init -DryRun` on an existing folder never named
# that folder. No action records the project path when the folder exists, and the summary printed the path only after
# a real run ("Bootstrap completed for ..."). SC-001's regression script checks that init resolved the folder the
# user ran it in, so its dry-run case could not pass. A dry run now names the folder it previewed.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts\init\post-bootstrap-output.ps1')
    $script:Project = Join-Path ([IO.Path]::GetTempPath()) ('init-dry-run-names-' + [guid]::NewGuid().ToString('N').Substring(0, 10))

    function Get-SummaryText {
        param([bool]$DryRun)
        $actions = [System.Collections.ArrayList]::new()
        $null = $actions.Add([pscustomobject]@{ Step = 'specify-init'; Outcome = 'preserved existing .specify' })
        return ((Write-BootstrapSummary -Actions $actions -DryRunMode $DryRun -ProjectPath $script:Project -ShowGuidance $false 6>&1 | Out-String -Width 400))
    }
}

Describe 'The bootstrap summary names the project folder (SC-001)' {
    It 'names the folder after a dry run, and says nothing was changed' {
        $text = Get-SummaryText -DryRun $true
        $text | Should -Match ([regex]::Escape($script:Project))
        $text | Should -Match 'No files were changed'
    }

    It 'still names the folder after a real run' {
        $text = Get-SummaryText -DryRun $false
        $text | Should -Match ([regex]::Escape("Bootstrap completed for $($script:Project)."))
    }
}
