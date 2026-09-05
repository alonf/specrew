[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# CLASS GUARD: AN EXEMPTION THAT NEVER FIRES IS INDISTINGUISHABLE FROM ONE CORRECTLY DECLINING.
#
# Measured 2026-09-05 (DRIFT-199-I003-059/-060). The workshop's outside-work stop has an exemption for the
# turn that OPENS a workshop, where the only file outside the workshop notes is the specification
# placeholder the governed scaffold wrote seconds earlier. That exemption was introduced 2026-08-14 and had
# never fired once in the 22 days since: it hashed spec.md against .specify/templates/spec-template.md -
# what the UPSTREAM scaffold leaves behind - while the governed wrapper immediately REPLACES that template
# with a much shorter stub. 917 bytes against 5374, so it failed on size before it ever reached a hash.
#
# Nothing noticed, and THAT is the class rather than the bug. A predicate returning $false because its
# condition is not met, and one returning $false because its condition CANNOT be met, produce identical
# behaviour, identical logs and identical test results. The suite around it was written entirely in the
# NEGATIVE - every assertion checked that the guard STOPS things - and a suite written in the negative
# agrees with a dead exemption perfectly.
#
# So the rule this file enforces: EVERY GUARD EXEMPTION OWES A POSITIVE TEST, one that proves it says yes.
# Add the next exemption here rather than trusting someone to notice it going quiet.
#
# WHY IT READS THE SHIPPED FILES RATHER THAN COPIES: the original defect was the scaffold and the predicate
# drifting apart while each stayed internally correct. This extracts the predicate from the provider AND the
# stub literal from the scaffold, then feeds one to the other. If either side changes what it writes or what
# it recognises, THIS test fails - which is the coupling that went unwatched.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$providerPath = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'
$scaffoldPath = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/create-governed-feature.ps1'
Assert-True (Test-Path -LiteralPath $providerPath -PathType Leaf) 'the conformance provider exists to be read'
Assert-True (Test-Path -LiteralPath $scaffoldPath -PathType Leaf) 'the governed feature scaffold exists to be read'

function Get-AstOf {
    param([string] $Path)
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref] $null, [ref] $errors)
    if ($errors -and $errors.Count -gt 0) { throw "FAIL: $Path has $($errors.Count) parse errors" }
    return $ast
}

# --- The predicate, taken from the shipped provider ----------------------------------------------
# Extracted rather than dot-sourced: the provider does work at load, and a guard must not depend on it.
$providerAst = Get-AstOf -Path $providerPath
$predicateAst = $providerAst.Find({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Test-SpecrewUntouchedFeatureSpecScaffold'
    }, $true)
Assert-True ($null -ne $predicateAst) 'the provider still defines Test-SpecrewUntouchedFeatureSpecScaffold'
. ([scriptblock]::Create($predicateAst.Extent.Text))

# --- The stub, taken from the shipped scaffold ---------------------------------------------------
# This is the coupling that broke. The predicate must recognise WHAT THE SCAFFOLD ACTUALLY WRITES, so the
# expected content is rendered from the scaffold itself rather than pasted into this test as a copy.
$scaffoldAst = Get-AstOf -Path $scaffoldPath
$stubAssignment = $scaffoldAst.Find({
        param($node)
        $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
        $node.Left.Extent.Text -eq '$specStub'
    }, $true)
Assert-True ($null -ne $stubAssignment) 'the scaffold still builds a spec stub named $specStub'

$featureRef = 'feat-1'
$scaffoldStub = & ([scriptblock]::Create($stubAssignment.Right.Extent.Text))
Assert-True (-not [string]::IsNullOrWhiteSpace([string] $scaffoldStub)) 'the scaffold stub renders to non-empty content'
Assert-True ([string] $scaffoldStub -match '<!--\s*specrew:spec-not-yet-authored\s*-->') 'the scaffold stub carries the sentinel that the specify gate and this exemption both read'

# --- Fixtures -------------------------------------------------------------------------------------
$scratch = Join-Path ([IO.Path]::GetTempPath()) ("specrew-exemption-guard-{0}" -f ([guid]::NewGuid().ToString('N')))
$upstreamTemplate = Join-Path $repoRoot '.specify/templates/spec-template.md'
Assert-True (Test-Path -LiteralPath $upstreamTemplate -PathType Leaf) 'the upstream spec template exists to be read'
$upstreamText = Get-Content -LiteralPath $upstreamTemplate -Raw -Encoding UTF8
Assert-True ([string] $upstreamText -notmatch 'specrew:spec-not-yet-authored') 'the upstream template does NOT carry the sentinel, so the stub and template cases are genuinely different'

function New-SpecWorkspace {
    param([string] $Name, [string] $SpecText, [bool] $WithTemplate = $true)
    $root = Join-Path $scratch $Name
    $null = New-Item -ItemType Directory -Path (Join-Path $root 'specs/feat-1') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $root '.specify/templates') -Force
    [IO.File]::WriteAllText((Join-Path $root 'specs/feat-1/spec.md'), $SpecText, [Text.UTF8Encoding]::new($false))
    if ($WithTemplate) {
        [IO.File]::WriteAllText((Join-Path $root '.specify/templates/spec-template.md'), $upstreamText, [Text.UTF8Encoding]::new($false))
    }
    return $root
}

try {
    $authoredSpec = @(
        '# Feature Specification: feat-1',
        '',
        '## Requirements',
        '',
        '- FR-001: System MUST convert CSV to JSON.'
    ) -join [Environment]::NewLine

    # --- THE POSITIVE CASE. This is the assertion the whole class exists for. --------------------
    $stubRoot = New-SpecWorkspace -Name 'untouched-governed-stub' -SpecText ([string] $scaffoldStub)
    $stubExempt = [bool](Test-SpecrewUntouchedFeatureSpecScaffold -ProjectRoot $stubRoot -FeatureRef 'feat-1')
    Assert-True $stubExempt 'POSITIVE: the exemption FIRES for the untouched stub the scaffold itself writes (a failure here is the 22-day defect returning)'

    # --- The negative half. T020 protection: authored content still stops. -----------------------
    $authoredRoot = New-SpecWorkspace -Name 'authored-spec' -SpecText $authoredSpec
    $authoredExempt = [bool](Test-SpecrewUntouchedFeatureSpecScaffold -ProjectRoot $authoredRoot -FeatureRef 'feat-1')
    Assert-True (-not $authoredExempt) 'NEGATIVE: an authored spec.md with the sentinel replaced is NOT exempt, so the outside-work stop still fires'

    # --- The legacy path, kept for projects scaffolded before the wrapper existed. ----------------
    $legacyRoot = New-SpecWorkspace -Name 'legacy-upstream-template' -SpecText $upstreamText
    Assert-True ([bool](Test-SpecrewUntouchedFeatureSpecScaffold -ProjectRoot $legacyRoot -FeatureRef 'feat-1')) 'the legacy comparison still exempts an untouched UPSTREAM template'

    $unrelatedRoot = New-SpecWorkspace -Name 'unrelated-content' -SpecText 'notes to self'
    Assert-True (-not [bool](Test-SpecrewUntouchedFeatureSpecScaffold -ProjectRoot $unrelatedRoot -FeatureRef 'feat-1')) 'unrelated content is not exempt'

    $noTemplateRoot = New-SpecWorkspace -Name 'stub-without-template' -SpecText ([string] $scaffoldStub) -WithTemplate $false
    Assert-True ([bool](Test-SpecrewUntouchedFeatureSpecScaffold -ProjectRoot $noTemplateRoot -FeatureRef 'feat-1')) 'the stub is recognised on its own content, with no template on disk to compare against'

    # --- NOT A CONSTANT. The whole point: it must be observed saying BOTH things in one run. -------
    Assert-True ($stubExempt -and -not $authoredExempt) 'the predicate is not a constant - it was observed returning BOTH true and false in this run'
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }
}

# --- The caller conjunction that bounds the exemption --------------------------------------------
# The predicate alone exempts an append that preserves the sentinel (DRIFT-199-I003-059, case B2). That
# residual is bounded HERE. If these conditions are relaxed the residual widens, silently, so they are
# pinned as text rather than left to review.
$providerText = Get-Content -LiteralPath $providerPath -Raw -Encoding UTF8
$boundConditions = @(
    @{ Pattern = "agenda_status -eq 'pending-confirmation'"; Label = "the pre-agenda turn only (agenda_status pending-confirmation)" }
    @{ Pattern = "lens -eq 'product-domain'"; Label = "the product-domain lens only" }
    @{ Pattern = "scope -eq 'feature'"; Label = "feature scope only" }
)
foreach ($bound in $boundConditions) {
    Assert-True ($providerText.Contains([string]$bound.Pattern)) ("the exemption is still bounded to {0}" -f $bound.Label)
}
Assert-True ($providerText.Contains('$preAgendaSpecPath = if ($preAgendaUntouchedScaffoldTurn)')) 'the exemption still applies to exactly one path, the feature spec, rather than a set of paths'

Write-Host 'guard exemptions still fire: all assertions pass' -ForegroundColor Green
