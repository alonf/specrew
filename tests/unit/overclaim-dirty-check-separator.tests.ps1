# Feature 206, T002 (FR-002, bug list item 2a): the over-claim dirty-tree check must see an uncommitted edit to a
# closed iteration's canonical artifact. It compared git's forward-slash paths, turned into backslashes, with a
# canonical list in forward slashes, so nothing ever matched and the check was inert on every platform.
#
# This suite exercises the same fixture as assertions 1 and 2 of tests/integration/validator-hardening-iteration2.ps1
# through validate-governance.ps1 only: no specrew start, no update, no hooks. Each workspace is a temp-folder copy
# of the repository's .specrew, .squad and .github and the feature-013 specs; the validator runs against it in a
# child pwsh. Nothing outside the temp folder is written.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
    $script:FeatureSource = Join-Path $script:RepoRoot 'specs\013-validator-hardening'
    $script:PwshPath = (Get-Process -Id $PID).Path
    $script:Workspaces = New-Object System.Collections.Generic.List[string]

    function New-OverclaimWorkspace {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ('overclaim-sep-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $null = New-Item -ItemType Directory -Path $root -Force
        $script:Workspaces.Add($root)
        foreach ($item in @('.specrew', '.squad', '.github')) {
            $source = Join-Path $script:RepoRoot $item
            if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $root -Recurse -Force }
        }
        $specs = Join-Path $root 'specs'
        $null = New-Item -ItemType Directory -Path $specs -Force
        Copy-Item -LiteralPath $script:FeatureSource -Destination $specs -Recurse -Force

        foreach ($gitArgs in @(
                @('init', '--quiet'),
                @('config', 'user.email', 'test@specrew.local'),
                @('config', 'user.name', 'Test User'),
                @('config', 'commit.gpgsign', 'false'),
                @('config', 'core.autocrlf', 'false'),
                @('add', '-A'),
                @('commit', '--quiet', '-m', 'Seed overclaim fixture'))) {
            $null = & git -C $root @gitArgs 2>&1
            if ($LASTEXITCODE -ne 0) { throw "git $($gitArgs -join ' ') failed in $root" }
        }
        return $root
    }

    function Invoke-FixtureValidator {
        param([Parameter(Mandatory = $true)][string]$Root)
        $iteration = Join-Path $Root (Join-Path 'specs' (Join-Path '013-validator-hardening' (Join-Path 'iterations' '001')))
        $command = "& '{0}' -ProjectPath '{1}' -IterationPath @('{2}')" -f $script:Validator.Replace("'", "''"), $Root.Replace("'", "''"), $iteration.Replace("'", "''")
        $output = @(& $script:PwshPath -NoProfile -ExecutionPolicy Bypass -Command $command 2>&1)
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
    }
}

AfterAll {
    foreach ($root in $script:Workspaces) {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'Over-claim dirty-tree check on a closed iteration (FR-002)' {
    It 'passes a closed iteration whose canonical artifacts are committed' {
        $root = New-OverclaimWorkspace
        $result = Invoke-FixtureValidator -Root $root
        $result.Text | Should -Not -Match 'uncommitted changes'
        $result.ExitCode | Should -Be 0 -Because $result.Text
    }

    It 'fails when a canonical artifact has an uncommitted edit, naming it with forward slashes' {
        $root = New-OverclaimWorkspace
        $plan = Join-Path $root (Join-Path 'specs' (Join-Path '013-validator-hardening' (Join-Path 'iterations' (Join-Path '001' 'plan.md'))))
        Add-Content -LiteralPath $plan -Value "`nDirty change" -Encoding UTF8
        $result = Invoke-FixtureValidator -Root $root
        $result.ExitCode | Should -Not -Be 0 -Because 'a dirty canonical artifact must not let the iteration claim closure'
        $result.Text | Should -Match 'category=over-claim'
        $result.Text | Should -Match 'uncommitted changes: specs/013-validator-hardening/iterations/001/plan\.md'
    }

    It 'ignores an uncommitted file in the iteration folder that is not a canonical artifact' {
        $root = New-OverclaimWorkspace
        $note = Join-Path $root (Join-Path 'specs' (Join-Path '013-validator-hardening' (Join-Path 'iterations' (Join-Path '001' 'scratch-note.txt'))))
        Set-Content -LiteralPath $note -Value 'not canonical' -Encoding UTF8
        $result = Invoke-FixtureValidator -Root $root
        $result.Text | Should -Not -Match 'uncommitted changes'
        $result.ExitCode | Should -Be 0 -Because $result.Text
    }
}
