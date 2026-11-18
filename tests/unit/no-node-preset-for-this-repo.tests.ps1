# Feature 206, T017 (FR-014, SC-006, bug list item 6a): a stray root package.json (react, express, pg; added by an early
# quality-roadmap commit) made the quality resolver recognise this PowerShell repository as a Node REST service with
# Postgres and select a Node preset for its features. The file is removed; f049's stack-detection assertion, which read
# that file, moves onto a fixture with its own package.json.
#
# The resolver is run read-only (-OutputFormat Json prints its result); the fixture is a temp folder this suite makes.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Resolver = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\resolve-quality-profile.ps1'
    $script:Fixture = Join-Path ([IO.Path]::GetTempPath()) ('no-node-preset-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $script:Fixture -Force
}

AfterAll {
    if ((Split-Path -Leaf $script:Fixture) -like 'no-node-preset-*') { Remove-Item -LiteralPath $script:Fixture -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'The quality resolver sees this repository as what it is (FR-014, SC-006)' {
    It 'has no root package.json' {
        Test-Path -LiteralPath (Join-Path $script:RepoRoot 'package.json') | Should -BeFalse
    }

    It 'selects no Node or React preset for feature 201''s spec' {
        $output = @(& pwsh -NoProfile -File $script:Resolver -ProjectPath $script:RepoRoot -FeaturePath (Join-Path $script:RepoRoot 'specs\201-first-run-experience') -OutputFormat Json 2>&1) -join "`n"
        $profile = $output | ConvertFrom-Json
        $presets = @($profile.preset_refs | ForEach-Object { if ($_.PSObject.Properties['preset_id']) { [string]$_.preset_id } else { [string]$_ } })
        $stacks = @($profile.stack_surfaces | ForEach-Object { [string]$_.recognized_stack })
        ($presets + $stacks) -join ', ' | Should -Not -Match '(?i)node|react' -Because "presets: $($presets -join ', '); stacks: $($stacks -join ', ')"
    }

    It 'still detects nodejs in a project that has its own package.json' {
        . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\intake\helpers\Detect-RepoStack.ps1')
        [IO.File]::WriteAllText((Join-Path $script:Fixture 'package.json'), '{ "dependencies": { "express": "^4.19.0" } }', [Text.UTF8Encoding]::new($false))
        Detect-RepoStack -ProjectRoot $script:Fixture | Should -Be 'nodejs'
    }
}
