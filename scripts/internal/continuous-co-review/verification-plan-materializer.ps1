# FR-049 / T063 — project source capture plus hash-guarded materialization for the pure T062 selector.

if (-not (Get-Command -Name 'Select-ContinuousCoReviewVerificationPlan' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'verification-plan-supplier.ps1')
}

function Resolve-ContinuousCoReviewVerificationPlanCatalogPath {
    param([Parameter(Mandatory)][string]$RepoRoot, [AllowNull()][string]$CatalogPath)
    if (-not [string]::IsNullOrWhiteSpace($CatalogPath)) { return $CatalogPath }
    $deployed = Join-Path $RepoRoot '.specify/extensions/specrew-speckit/data/verification-plan-catalog.json'
    if (Test-Path -LiteralPath $deployed -PathType Leaf) { return $deployed }
    $moduleRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
    return (Join-Path $moduleRoot 'extensions/specrew-speckit/data/verification-plan-catalog.json')
}

function Get-ContinuousCoReviewProjectMetadataIds {
    param([Parameter(Mandatory)][string]$RepoRoot)
    $packagePath = Join-Path $RepoRoot 'package.json'
    if (-not (Test-Path -LiteralPath $packagePath -PathType Leaf)) { return @() }
    try {
        $package = Get-Content -LiteralPath $packagePath -Raw | ConvertFrom-Json
        $scripts = $package.PSObject.Properties['scripts']
        if ($null -eq $scripts -or $null -eq $scripts.Value) { return @() }
        $test = $scripts.Value.PSObject.Properties['test']
        if ($null -eq $test -or -not ($test.Value -is [string]) -or [string]::IsNullOrWhiteSpace([string]$test.Value)) { return @() }
        $declared = ([string]$test.Value).Trim()
        # npm's generated placeholder is not a trustworthy verification command.
        if ($declared -match '(?i)no\s+test\s+specified' -or $declared -match '(?i)^echo\b.*\bexit\s+1\s*$') { return @() }
        return @('package-json.scripts-test.v1')
    }
    catch { return @() }
}

function Get-ContinuousCoReviewActiveProjectProviders {
    param([Parameter(Mandatory)][string]$RepoRoot)
    $path = Join-Path $RepoRoot '.specrew/repository-governance.yml'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return @() }
    $block = ''
    foreach ($rawLine in @(Get-Content -LiteralPath $path)) {
        $line = ($rawLine -replace '\s+#.*$', '').TrimEnd()
        if ($line -match '^(?<name>[A-Za-z0-9_-]+):\s*$') { $block = $Matches.name; continue }
        $value = $null
        if ($line -match '^provider:\s*(?<value>[^\s]+)\s*$') { $value = $Matches.value }
        elseif ($block -eq 'provider' -and $line -match '^\s+name:\s*(?<value>[^\s]+)\s*$') { $value = $Matches.value }
        elseif ($block -eq 'repository_governance' -and $line -match '^\s{2}provider:\s*(?<value>[^\s]+)\s*$') { $value = $Matches.value }
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $normalized = $value.Trim('"', "'", ' ').ToLowerInvariant()
            if (Test-ContinuousCoReviewSupplierIdentity $normalized) { return @($normalized) }
            return @()
        }
    }
    return @()
}

function Write-ContinuousCoReviewVerificationPlanFile {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][AllowEmptyString()][string]$Content)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $temp = Join-Path $parent ('.verification-plan-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [System.IO.File]::WriteAllText($temp, $Content, [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temp, $Path, $true)
    }
    finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
}

# T007 / FR-012, FR-013. The N4 default allowlist, plus TMPDIR.
#
# PSModulePath is deliberately ABSENT, and that is a MEASUREMENT rather than a judgement (maintainer
# instruction, 2026-08-10): a child process started with the variable REMOVED is handed a fully
# populated default module path by pwsh at startup, and the governance validator behaves identically -
# exit 0 both ways, 11.9 s against 11.2 s, empty stderr. The env_ref is therefore not load-bearing, and
# a default that lists it would teach every consumer to inherit something they do not need.
$script:SpecrewStarterVerificationEnvRefs = @(
    'PATH', 'PATHEXT', 'SYSTEMROOT', 'COMSPEC', 'TEMP', 'TMP', 'TMPDIR', 'HOME', 'USERPROFILE',
    'APPDATA', 'LOCALAPPDATA', 'PROGRAMFILES', 'PROGRAMFILES(X86)', 'PROGRAMDATA'
)

function New-ContinuousCoReviewStarterVerificationPlan {
    # The plan every GOVERNED project can run on day one, so a fresh project is never left unable to
    # verify (DRIFT-199-I001-008: the campaign preflight cannot run without a plan, and the stop surface
    # then demands a review that cannot start - a bootstrap deadlock at the gate).
    #
    # ONE command, and it is the governance validator because that is the one thing EVERY governed
    # project has: `.specify/extensions/...` is deployed by init itself. Build and test commands cannot
    # be guessed from an empty tree, so they ship as TEMPLATES beside the plan rather than as commands
    # that would fail on first run and teach the consumer that verification is broken.
    #
    # DELIBERATELY GENERIC - no feature id in the plan_id, and no `-IterationPath`. Measured: the
    # validator resolves the ACTIVE iteration itself (`mode=scoped`, `iterations_validated=1`, exit 0).
    # That is what lets this survive a clone, a new worktree, and a new feature - the three things
    # DRIFT-199-I001-010 recorded the beta2 definition failing, because it hardcoded
    # `-IterationPath specs/198-beta2-hardening/iterations/008`.
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param()
    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        plan_id = 'verification.starter.governance.v1'
        commands = @(
            [pscustomobject][ordered]@{
                command_id = 'specrew-governance'
                executable = 'pwsh'
                arguments = @(
                    '-NoProfile'
                    '-File'
                    '.specify/extensions/specrew-speckit/scripts/validate-governance.ps1'
                    '-ProjectPath'
                    '.'
                    '-NoCacheRead'
                    '-NoParallel'
                )
                timeout_seconds = 180
                env_refs = @($script:SpecrewStarterVerificationEnvRefs)
                provenance = [pscustomobject][ordered]@{
                    kind = 'project-config'
                    source = '.specrew/verification-plan.json'
                }
                label = 'Specrew governance validation - the one check every governed project can run. Add your build and test commands beside it; see verification-plan.templates.md.'
            }
        )
    }
}

function Get-ContinuousCoReviewStarterVerificationTemplates {
    # Templates live BESIDE the plan, never inside it. The plan schema admits schema_version, plan_id
    # and commands only, with the explicit rationale that no secret value can ride an unrecognized
    # field - so an extra key or a "disabled command" flag would reopen a containment rule that exists
    # for secrets, to carry documentation. A markdown sidecar costs nothing and is readable.
    [OutputType([string])]
    [CmdletBinding()]
    param()
    return @'
# Verification plan - templates

`.specrew/verification-plan.json` is yours to edit. It starts with one command: Specrew's own
governance validation, which is the only check that works in every project without configuration.

**Add the command that builds and tests YOUR project.** Until you do, a review verifies that your
governance records are consistent - it does not verify that your code works.

Copy one of these into the `commands` array and adjust it.

## .NET

```json
{
  "command_id": "dotnet-test",
  "executable": "dotnet",
  "arguments": ["test", "--configuration", "Release", "--nologo"],
  "timeout_seconds": 900,
  "env_refs": ["PATH", "PATHEXT", "SYSTEMROOT", "COMSPEC", "TEMP", "TMP", "TMPDIR", "HOME", "USERPROFILE", "APPDATA", "LOCALAPPDATA", "PROGRAMFILES", "PROGRAMFILES(X86)", "PROGRAMDATA", "DOTNET_CLI_HOME", "NUGET_PACKAGES"],
  "provenance": { "kind": "project-config", "source": ".specrew/verification-plan.json" },
  "label": "Build and test"
}
```

## Node / npm

```json
{
  "command_id": "npm-test",
  "executable": "npm",
  "arguments": ["test"],
  "timeout_seconds": 900,
  "env_refs": ["PATH", "PATHEXT", "SYSTEMROOT", "COMSPEC", "TEMP", "TMP", "TMPDIR", "HOME", "USERPROFILE", "APPDATA", "LOCALAPPDATA", "PROGRAMFILES", "PROGRAMFILES(X86)", "PROGRAMDATA", "npm_config_cache"],
  "provenance": { "kind": "project-config", "source": ".specrew/verification-plan.json" },
  "label": "Build and test"
}
```

## Two rules worth knowing before you edit

**Environment variables are declared by NAME, never by value.** `env_refs` lists the names a command is
allowed to inherit. A literal `env` or `environment` map is refused, so that no plan can carry a secret.
If a command needs something not listed, add its NAME to `env_refs`.

**Every command must finish inside the review's time window.** The sum of the `timeout_seconds` values
has to fit within the window a review round is given, or a slow day ends in a failure that reports the
window rather than your tests. A timeout is a hang-catcher, not an estimate: set it well above how long
the command really takes, and still well inside the round.
'@
}

function New-ContinuousCoReviewVerificationMaterializationResult {
    param(
        [Parameter(Mandatory)][string]$State,
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][bool]$Mutated,
        [AllowNull()][string]$Warning,
        [AllowNull()]$Selection,
        [Parameter(Mandatory)][string]$PlanPath,
        [Parameter(Mandatory)][string]$MarkerPath
    )
    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        state = $State
        action = $Action
        mutated = $Mutated
        warning = if ([string]::IsNullOrWhiteSpace($Warning)) { $null } else { $Warning }
        plan_path = $PlanPath
        marker_path = $MarkerPath
        selection = $Selection
    }
}

function Invoke-ContinuousCoReviewVerificationPlanMaterialization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [AllowNull()][string]$CatalogPath,
        [AllowNull()][string]$QualityProfileId,
        [AllowNull()][string[]]$ActiveProviders,
        [switch]$PreviewOnly
    )
    $root = [System.IO.Path]::GetFullPath($RepoRoot)
    $planPath = Join-Path $root '.specrew/verification-plan.json'
    $markerPath = Join-Path $root '.specrew/verification-plan.generated.json'
    $resolvedCatalog = Resolve-ContinuousCoReviewVerificationPlanCatalogPath -RepoRoot $root -CatalogPath $CatalogPath
    if (-not (Test-Path -LiteralPath $resolvedCatalog -PathType Leaf)) {
        return New-ContinuousCoReviewVerificationMaterializationResult -State invalid -Action 'catalog-missing' -Mutated $false -Warning 'Verification-plan catalog is missing; no project plan was changed.' -Selection $null -PlanPath $planPath -MarkerPath $markerPath
    }
    try { $catalog = Get-Content -LiteralPath $resolvedCatalog -Raw | ConvertFrom-Json }
    catch {
        return New-ContinuousCoReviewVerificationMaterializationResult -State invalid -Action 'catalog-invalid' -Mutated $false -Warning 'Verification-plan catalog is malformed; no project plan was changed.' -Selection $null -PlanPath $planPath -MarkerPath $markerPath
    }

    $planExists = Test-Path -LiteralPath $planPath -PathType Leaf
    $markerExists = Test-Path -LiteralPath $markerPath -PathType Leaf
    $generatedAndUnmodified = $false
    if ($planExists -and $markerExists) {
        try {
            $marker = Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
            $expectedHash = [string](Get-ContinuousCoReviewSupplierProp $marker 'generated_content_hash')
            $currentHash = Get-ContinuousCoReviewSupplierSha256 (Get-Content -LiteralPath $planPath -Raw)
            $generatedAndUnmodified = ([string](Get-ContinuousCoReviewSupplierProp $marker 'schema_version') -ceq '1.0') -and ($expectedHash -cmatch '^[0-9a-f]{64}$') -and ($currentHash -ceq $expectedHash)
        }
        catch { $generatedAndUnmodified = $false }
        if (-not $generatedAndUnmodified) {
            return New-ContinuousCoReviewVerificationMaterializationResult -State 'preserved-modified' -Action 'preserved-modified-generated-plan' -Mutated $false -Warning 'The generated verification plan or its ownership marker changed; preserving both files byte-for-byte. Reconcile them explicitly before refresh.' -Selection $null -PlanPath $planPath -MarkerPath $markerPath
        }
    }
    elseif ($planExists) {
        $explicit = $null
        try { $explicit = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json } catch { $explicit = $null }
        $selection = Select-ContinuousCoReviewVerificationPlan -RepoRoot $root -Catalog $catalog -ExplicitPlanPresent -ExplicitPlan $explicit
        $action = if ($selection.state -eq 'selected') { 'preserved-explicit-plan' } else { 'preserved-invalid-explicit-plan' }
        $warning = if ($selection.state -eq 'selected') { $null } else { $selection.action }
        return New-ContinuousCoReviewVerificationMaterializationResult -State $selection.state -Action $action -Mutated $false -Warning $warning -Selection $selection -PlanPath $planPath -MarkerPath $markerPath
    }
    elseif ($markerExists) {
        if (-not $PreviewOnly) { Remove-Item -LiteralPath $markerPath -Force }
        $markerExists = $false
    }

    $metadataIds = @(Get-ContinuousCoReviewProjectMetadataIds -RepoRoot $root)
    $providers = if ($PSBoundParameters.ContainsKey('ActiveProviders')) { @($ActiveProviders) } else { @(Get-ContinuousCoReviewActiveProjectProviders -RepoRoot $root) }
    $selection = Select-ContinuousCoReviewVerificationPlan -RepoRoot $root -Catalog $catalog -DetectedMetadataIds $metadataIds -QualityProfileId $QualityProfileId -ActiveProviders $providers

    if ($selection.state -ne 'selected') {
        $removed = $false
        if ($generatedAndUnmodified) {
            $removed = $true
            if (-not $PreviewOnly) {
                Remove-Item -LiteralPath $planPath -Force
                Remove-Item -LiteralPath $markerPath -Force -ErrorAction SilentlyContinue
            }
        }
        $action = if ($removed) { if ($PreviewOnly) { 'would-remove-unconfigured-generated-plan' } else { 'removed-unconfigured-generated-plan' } } else { 'verification-not-configured' }
        if ($selection.state -eq 'invalid') { $action = if ($removed) { 'removed-invalid-generated-plan' } else { 'verification-plan-invalid' } }

        # T007 / FR-012: THE BOOTSTRAP DEADLOCK ENDS HERE. Reaching this point used to mean the project
        # had no verification plan and no way to get one - the campaign preflight then failed with
        # `verification-not-configured`, while the stop surface demanded a review that could not start
        # (DRIFT-199-I001-008, reproduced on this very repository). A project matches nothing simply by
        # not being an npm project, which is most of them.
        #
        # Only for the genuinely UNCONFIGURED state: an INVALID plan is a different situation and must
        # keep failing loudly, because scaffolding over a broken plan would hide the consumer's mistake.
        # Only when no plan file exists at all - never overwriting or resurrecting one.
        # GATED ON THE VALIDATOR ACTUALLY EXISTING, and that gate is load-bearing rather than defensive.
        # The starter's whole value is that its one command RUNS on day one; scaffolding a plan whose
        # only command is a missing script would fail on first review and teach the consumer that
        # verification is broken - worse than no plan, because it looks configured. The plan contract
        # validates shape, not the presence of an executable, so this is checked here.
        #
        # It also scopes the behaviour correctly: `.specify/extensions/...` is deployed by init itself,
        # so its presence is exactly the question "is this a governed project".
        $governanceValidator = Join-Path $root '.specify/extensions/specrew-speckit/scripts/validate-governance.ps1'
        if ($selection.state -eq 'verification-not-configured' -and
            -not (Test-Path -LiteralPath $planPath -PathType Leaf) -and
            (Test-Path -LiteralPath $governanceValidator -PathType Leaf)) {
            $starter = New-ContinuousCoReviewStarterVerificationPlan
            $starterCheck = Test-ContinuousCoReviewVerificationPlan -Plan $starter -RepoRoot $root
            if ($starterCheck.valid) {
                # Written as an EXPLICIT plan with NO ownership marker, so from here on it is found by
                # the project-config branch and PRESERVED byte-for-byte. A marked generated plan would
                # delete itself on the very next run, because the block above removes a generated plan
                # whose source has disappeared - and this one's source never appears.
                if (-not $PreviewOnly) {
                    Write-ContinuousCoReviewVerificationPlanFile -Path $planPath -Content (ConvertTo-ContinuousCoReviewSupplierCanonicalJson $starter)
                    Write-ContinuousCoReviewVerificationPlanFile -Path (Join-Path $root '.specrew/verification-plan.templates.md') -Content (Get-ContinuousCoReviewStarterVerificationTemplates)
                }
                $starterSelection = [pscustomobject][ordered]@{
                    state = 'selected'; source_kind = 'starter'
                    source_identity = [pscustomobject][ordered]@{ path = '.specrew/verification-plan.json' }
                    plan = $starter; plan_id = $starter.plan_id
                }
                return New-ContinuousCoReviewVerificationMaterializationResult -State 'selected' `
                    -Action $(if ($PreviewOnly) { 'would-create-starter-plan' } else { 'created-starter-plan' }) `
                    -Mutated (-not $PreviewOnly) -Warning $null -Selection $starterSelection -PlanPath $planPath -MarkerPath $markerPath
            }
        }

        return New-ContinuousCoReviewVerificationMaterializationResult -State $selection.state -Action $action -Mutated ($removed -and -not $PreviewOnly) -Warning $selection.action -Selection $selection -PlanPath $planPath -MarkerPath $markerPath
    }

    $planContent = ConvertTo-ContinuousCoReviewSupplierCanonicalJson $selection.plan
    $catalogId = [string](Get-ContinuousCoReviewSupplierProp $catalog 'catalog_id')
    $markerObject = [ordered]@{
        schema_version = '1.0'
        selection_id = $selection.selection_id
        generated_content_hash = $selection.generated_content_hash
        plan_id = $selection.plan_id
        catalog_id = $catalogId
        source_kind = $selection.source_kind
        source_identity = $selection.source_identity
    }
    $markerContent = ConvertTo-ContinuousCoReviewSupplierCanonicalJson $markerObject
    if ($generatedAndUnmodified -and (Get-Content -LiteralPath $planPath -Raw) -ceq $planContent -and (Get-Content -LiteralPath $markerPath -Raw) -ceq $markerContent) {
        return New-ContinuousCoReviewVerificationMaterializationResult -State selected -Action 'generated-plan-current' -Mutated $false -Warning $null -Selection $selection -PlanPath $planPath -MarkerPath $markerPath
    }
    $action = if ($generatedAndUnmodified) { if ($PreviewOnly) { 'would-refresh-generated-plan' } else { 'refreshed-generated-plan' } } else { if ($PreviewOnly) { 'would-create-generated-plan' } else { 'created-generated-plan' } }
    if (-not $PreviewOnly) {
        Write-ContinuousCoReviewVerificationPlanFile -Path $planPath -Content $planContent
        Write-ContinuousCoReviewVerificationPlanFile -Path $markerPath -Content $markerContent
    }
    return New-ContinuousCoReviewVerificationMaterializationResult -State selected -Action $action -Mutated (-not $PreviewOnly) -Warning $null -Selection $selection -PlanPath $planPath -MarkerPath $markerPath
}
