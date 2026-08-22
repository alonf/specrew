#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# DRIFT-005 (2026-08-22): A CONTROL THAT REFUSES MUST BE PROVEN TO FIRE ON THE PATH ITS OWN REMEDY
# NAMES.
#
# W43 added an integrity check for the deployed extension, and a suite that exercised it. Every case in
# that suite called `Write-SpecrewDeployedExtensionMarker` directly. None of them went through
# `specrew update` - the command the check's own refusal message names as the way back.
#
# On the real path the stamp sat AFTER `if ($PassThru) { ... return }` in deploy-speckit-extension.ps1,
# and both init and update invoke that script with -PassThru. So the marker was never written, the check
# fails open by design, and the guarantee was silently inactive for every project. Nothing crashed. The
# unit suite stayed green throughout, because it was proving the control in the shape I had invoked it
# rather than the shape a consumer reaches.
#
# So these cases drive the REAL commands end to end. They are slower than a unit suite on purpose: the
# defect lived exactly in the gap the fast version could not see.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:MarkerRelative = '.specify/extensions/specrew-speckit/.specrew-extension-runtime.json'

    function script:New-ManagedProject {
        # A project shaped like one that has been through init: Specrew-managed, with a deployed
        # extension directory already present. `specrew update` skips .specify entirely when it is
        # absent, so a fixture without one would pass this suite while proving nothing.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('drift005-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root '.specify/extensions/specrew-speckit/scripts') -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot '.specrew/config.yml') -Destination (Join-Path $root '.specrew/config.yml') -Force
        Set-Content -LiteralPath (Join-Path $root '.specify/extensions/specrew-speckit/scripts/placeholder.ps1') -Value '# pre-existing deployment' -Encoding UTF8
        return $root
    }

    function script:Get-MarkerPath {
        param([Parameter(Mandatory)][string]$Root)
        return (Join-Path $Root $script:MarkerRelative)
    }

    # The validator's check, lifted the same way the unit suite lifts it.
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'), [ref]$t, [ref]$e)
    $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $n.Name -eq 'Test-DeployedExtensionIntegrity' }, $true) | Select-Object -First 1
    if (-not $fn) { throw 'Test-DeployedExtensionIntegrity not found' }
    . ([scriptblock]::Create($fn.Extent.Text))
}

Describe 'DRIFT-005 the marker is written by the command its own refusal names' {
    It 'ACCEPTANCE: after a real specrew update, the marker exists and a later hand-edit is refused' {
        # Both halves in one case, deliberately. "The marker exists" is not the guarantee; "an edit is
        # refused" is, and separating them would let the first pass while the second was never checked -
        # which is the shape of the defect this case exists to prevent.
        $root = New-ManagedProject
        try {
            & pwsh -NoProfile -File (Join-Path $script:RepoRoot 'scripts/specrew-update.ps1') -ProjectPath $root *> $null
            $LASTEXITCODE | Should -Be 0 -Because 'the update itself must succeed for the rest to mean anything'

            (Test-Path -LiteralPath (Get-MarkerPath -Root $root) -PathType Leaf) |
                Should -BeTrue -Because 'specrew update is the remedy the refusal names, so it must be the path that arms the check'

            $validator = Join-Path $root '.specify/extensions/specrew-speckit/scripts/validate-governance.ps1'
            (Test-Path -LiteralPath $validator -PathType Leaf) | Should -BeTrue
            Add-Content -LiteralPath $validator -Value '# hand-patched to clear a blocker' -Encoding UTF8

            $errors = [System.Collections.Generic.List[string]]::new()
            Test-DeployedExtensionIntegrity -ProjectRoot $root -Errors $errors
            @($errors).Count | Should -Be 1
            $errors[0] | Should -Match 'validate-governance\.ps1'
            $errors[0] | Should -Match 'specrew update --project-path'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'stamps on the -PassThru call shape, which is the one every caller uses' {
        # The defect in one case. init and update both invoke the deploy script with -PassThru; the stamp
        # sat below that early return. Deleting the stamp, or moving it back under the return, turns this
        # red - a string match on the file could not tell the difference.
        $root = New-ManagedProject
        try {
            $null = & pwsh -NoProfile -File (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1') `
                -ProjectPath $root -RefreshExisting -PassThru *> $null
            (Test-Path -LiteralPath (Get-MarkerPath -Root $root) -PathType Leaf) | Should -BeTrue
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'stamps on the init path too, whichever of its two branches this machine takes' {
        # specrew init routes through Invoke-SpecKitExtensionDeployment rather than calling the deploy
        # script directly. It was never traced when W43 landed, so it is traced here rather than assumed.
        #
        # That helper branches: `specify extension add --dev` when the Spec Kit CLI is present, and the
        # deploy script with -PassThru when it is not. Which one runs depends on the machine, so this
        # case asserts the OUTCOME both must produce rather than the branch it happened to take - and
        # both were separately unstamped before this fix.
        $root = New-ManagedProject
        try {
            Remove-Item -LiteralPath (Join-Path $root '.specify/extensions/specrew-speckit') -Recurse -Force
            . (Join-Path $script:RepoRoot 'scripts/init/_utilities.ps1')
            . (Join-Path $script:RepoRoot 'scripts/init/spec-kit-deploy.ps1')
            $null = Invoke-SpecKitExtensionDeployment `
                -ProjectPath $root `
                -RepoRoot $script:RepoRoot `
                -FallbackScriptPath (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1') `
                -PreviewOnly:$false *> $null
            (Test-Path -LiteralPath (Get-MarkerPath -Root $root) -PathType Leaf) | Should -BeTrue
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'writes no marker on a dry run, because a preview must not mint a fact' {
        $root = New-ManagedProject
        try {
            $null = & pwsh -NoProfile -File (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1') `
                -ProjectPath $root -RefreshExisting -PassThru -DryRun *> $null
            (Test-Path -LiteralPath (Get-MarkerPath -Root $root) -PathType Leaf) | Should -BeFalse
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the marker describes what is on disk, not what the package intended' {
        # Written after the copy, so its hashes match the deployed bytes. If it were written first, the
        # check would compare a deployment against a prediction of itself and drift would read clean.
        $root = New-ManagedProject
        try {
            $null = & pwsh -NoProfile -File (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1') `
                -ProjectPath $root -RefreshExisting -PassThru *> $null
            $errors = [System.Collections.Generic.List[string]]::new()
            Test-DeployedExtensionIntegrity -ProjectRoot $root -Errors $errors
            @($errors).Count | Should -Be 0 -Because 'a freshly deployed tree must verify against its own marker'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
