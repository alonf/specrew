[CmdletBinding()]
param()

# Feature 160 (Proposal 161) — managed-skill ".specrew-managed" sidecar fixture.
#
# Suspected issue: Test-IsManagedLegacySkillDirectory (deploy-squad-runtime.ps1)
# decides whether a legacy .copilot/skills/specrew-* dir is Specrew-managed (safe
# to remove on cleanup) or user-edited (preserve). When no .specrew-managed marker
# is present it falls back to a SKILL.md content heuristic that treats any leading
# '---' (front matter) as user-edited. Because ALL current canonical skill
# templates start with '---' (enforced by skill-templates.tests.ps1, F-044), a
# marker-less legacy dir holding Specrew's OWN canonical content is misclassified
# as user-edited and frozen — provenance is overridden by a content guess.
#
# This is a DIRECT deploy-logic fixture (FR-005/FR-006): it AST-extracts the real
# classifier from the source script (so it always tests live behavior) and
# exercises marker-present, canonical-content, legacy-signature, and user-edited
# cases. Repro-first: the canonical-content-without-marker assertions FAIL before
# the fix and PASS after (FR-007/FR-008). The user-edited assertion guards against
# data loss and must PASS in both states.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "INFO: $Message" -ForegroundColor Cyan }

$script:Failures = New-Object System.Collections.Generic.List[string]
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Pass $Message } else { $script:Failures.Add($Message) | Out-Null; Write-Host "FAIL: $Message" -ForegroundColor Red }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
$deployScript = Join-Path $repoRoot 'extensions' 'specrew-speckit' 'scripts' 'deploy-squad-runtime.ps1'
$sharedGovernance = Join-Path $repoRoot 'extensions' 'specrew-speckit' 'scripts' 'shared-governance.ps1'
$skillsTemplateRoot = Join-Path $repoRoot 'extensions' 'specrew-speckit' 'squad-templates' 'skills'

foreach ($p in @($deployScript, $sharedGovernance, $skillsTemplateRoot)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "Required path not found: $p" }
}

# Dependency for Get-LegacySpecrewSkillDefinitions (Get-SlashCommandSkillCatalog etc.).
. $sharedGovernance | Out-Null

# AST-extract the deploy script's function definitions — defines the live source
# functions (classifier + its helpers) WITHOUT running the script's top-level
# deploy logic, so behavior is tested with zero side effects.
$ast = [System.Management.Automation.Language.Parser]::ParseFile($deployScript, [ref]$null, [ref]$null)
$funcs = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false))
foreach ($f in $funcs) { . ([scriptblock]::Create($f.Extent.Text)) }
foreach ($required in @('Get-ManagedSkillMarkerContent', 'Get-LegacySpecrewSkillDefinitions', 'Test-IsManagedLegacySkillDirectory', 'Get-SlashCommandSkillCatalog')) {
    if (-not (Get-Command -Name $required -CommandType Function -ErrorAction SilentlyContinue)) {
        throw "Required function '$required' was not defined after AST extraction."
    }
}

$definitions = @(Get-LegacySpecrewSkillDefinitions -SkillsTemplateRoot $skillsTemplateRoot)
$genericDef = $definitions | Where-Object { $_.Kind -eq 'generic' } | Select-Object -First 1
$slashDef = $definitions | Where-Object { $_.Kind -eq 'slash-command' } | Select-Object -First 1
if ($null -eq $genericDef) { throw 'No generic-kind skill definition found.' }
if ($null -eq $slashDef) { throw 'No slash-command-kind skill definition found.' }
Write-Info ("Definitions: {0} total; using generic='{1}', slash='{2}' (legacy cmd '{3}')" -f $definitions.Count, $genericDef.Directory, $slashDef.Directory, $slashDef.LegacySlashCommand)

# Reachability proof: canonical content starts with front matter.
Assert-True ($genericDef.CurrentContent.TrimStart().StartsWith('---')) "Generic canonical content starts with '---' (front matter — defeats the heuristic)"
Assert-True ($slashDef.CurrentContent.TrimStart().StartsWith('---'))   "Slash canonical content starts with '---' (front matter — defeats the heuristic)"

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-sidecar-fixture-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch -Force | Out-Null
function New-SkillDir {
    param([string]$Name, [string]$SkillContent, [switch]$WithMarker, [string]$MarkerDir)
    $dir = Join-Path $scratch $Name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $dir 'SKILL.md'), $SkillContent, [System.Text.UTF8Encoding]::new($false))
    if ($WithMarker) {
        [System.IO.File]::WriteAllText((Join-Path $dir '.specrew-managed'), (Get-ManagedSkillMarkerContent -SkillDirectory $MarkerDir), [System.Text.UTF8Encoding]::new($false))
    }
    return $dir
}

try {
    # Case A — canonical content, NO marker. SHOULD be managed (it is Specrew's own
    # content); the heuristic wrongly returns not-managed. REPRO: fails pre-fix.
    $aGen = New-SkillDir -Name 'A-generic-canonical-no-marker' -SkillContent $genericDef.CurrentContent
    Assert-True (Test-IsManagedLegacySkillDirectory -SkillDirectoryPath $aGen -Definition $genericDef) `
        "Case A (generic): canonical content + NO marker is classified MANAGED (repro: fails until marker-provenance fix lands)"

    $aSlash = New-SkillDir -Name 'A-slash-canonical-no-marker' -SkillContent $slashDef.CurrentContent
    Assert-True (Test-IsManagedLegacySkillDirectory -SkillDirectoryPath $aSlash -Definition $slashDef) `
        "Case A (slash): canonical content + NO marker is classified MANAGED (repro: fails until marker-provenance fix lands)"

    # Case B — canonical content WITH marker. Managed via provenance. Passes always.
    $bSlash = New-SkillDir -Name 'B-slash-canonical-with-marker' -SkillContent $slashDef.CurrentContent -WithMarker -MarkerDir $slashDef.Directory
    Assert-True (Test-IsManagedLegacySkillDirectory -SkillDirectoryPath $bSlash -Definition $slashDef) `
        "Case B (slash): canonical content + marker present is classified MANAGED"

    # Case C — genuine pre-marker legacy signature (no front matter), NO marker.
    # Must stay managed via the signature fallback (the fix must not break this).
    $bt = [char]96
    $legacySignature = @(
        ('# {0}' -f $slashDef.Directory)
        ''
        ('**Namespace**: {0}/specrew{0}' -f $bt)
        ('**Canonical command**: {0}{1}{0}' -f $bt, $slashDef.LegacySlashCommand)
        ''
        'Legacy body content from a pre-front-matter Specrew.'
    ) -join "`n"
    $cSlash = New-SkillDir -Name 'C-slash-legacy-signature-no-marker' -SkillContent $legacySignature
    Assert-True (Test-IsManagedLegacySkillDirectory -SkillDirectoryPath $cSlash -Definition $slashDef) `
        "Case C (slash): legacy signature (no front matter) + NO marker is classified MANAGED via the signature fallback"

    # Case D — genuinely USER-EDITED content (front matter, not canonical), NO
    # marker. Must be PRESERVED (not-managed) in both states — data-loss guard.
    $userEdited = "---`nname: my-custom-skill`ndescription: hand authored`n---`n# My Custom Skill`n`nUser wrote this; do not delete.`n"
    $dGen = New-SkillDir -Name 'D-generic-user-edited-no-marker' -SkillContent $userEdited
    Assert-True (-not (Test-IsManagedLegacySkillDirectory -SkillDirectoryPath $dGen -Definition $genericDef)) `
        "Case D (generic): genuine user-edited content + NO marker stays NOT-MANAGED (preserved — no user-data loss)"
    $dSlash = New-SkillDir -Name 'D-slash-user-edited-no-marker' -SkillContent $userEdited
    Assert-True (-not (Test-IsManagedLegacySkillDirectory -SkillDirectoryPath $dSlash -Definition $slashDef)) `
        "Case D (slash): genuine user-edited content + NO marker stays NOT-MANAGED (preserved — no user-data loss)"
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
}

# ----------------------------------------------------------------------------
# Source/mirror parity (FR-005/SC-005): the deployed .specify mirror must carry
# the same provenance-by-content marker fix as the source. The fingerprint is the
# ordinal exact-match guard added by the Feature 160 fix.
# ----------------------------------------------------------------------------
$fixFingerprint = '[System.String]::Equals($content, $canonical, [System.StringComparison]::Ordinal)'
$deployMirror = Join-Path $repoRoot '.specify' 'extensions' 'specrew-speckit' 'scripts' 'deploy-squad-runtime.ps1'
Assert-True ((Get-Content -LiteralPath $deployScript -Raw).Contains($fixFingerprint)) `
    "Source deploy-squad-runtime.ps1 carries the provenance-by-content marker fix"
if (Test-Path -LiteralPath $deployMirror -PathType Leaf) {
    Assert-True ((Get-Content -LiteralPath $deployMirror -Raw).Contains($fixFingerprint)) `
        ".specify mirror deploy-squad-runtime.ps1 carries the same fix (source/mirror parity)"
}
else {
    Write-Info "deploy mirror not present (downstream layout); parity check skipped"
}

if ($script:Failures.Count -gt 0) {
    Write-Host ("`n{0} assertion(s) failed:" -f $script:Failures.Count) -ForegroundColor Red
    foreach ($f in $script:Failures) { Write-Host "  - $f" -ForegroundColor Red }
    exit 1
}
Write-Host "`nmanaged-runtime-sidecar: all assertions pass" -ForegroundColor Green
