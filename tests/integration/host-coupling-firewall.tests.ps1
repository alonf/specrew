[CmdletBinding()]
param()

# Structural test: no PRODUCTION script file outside hosts/ should hardcode
# the multi-host enum. The architecture's Open-Closed promise depends on this.
#
# Allow-list patterns: certain legacy callsites and tests legitimately reference
# host names. Everything else must use Get-RegisteredHostKinds /
# Get-HostManifest.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path

# Regex matching the 4-host enum tuple in any order (lowercase + quoted).
# Catches: @('copilot','claude','codex','antigravity'); @('copilot', 'claude', 'codex'); '... copilot | claude | codex...' lists.
$enumPatterns = @(
    "@\(\s*'copilot'\s*,\s*'claude'\s*,\s*'codex'"
    "@\(\s*'claude'\s*,\s*'codex'\s*,\s*'antigravity'"
    "@\(\s*'copilot'\s*,\s*'claude'\s*,\s*'codex'\s*,\s*'antigravity'"
    "ValidateSet\s*\(\s*'copilot'\s*,\s*'claude'\s*,\s*'codex'"
)

# Files explicitly allow-listed (architecture's deliberate "open work" remaining)
$allowListExact = @(
    'hosts/_registry.ps1',                              # the registry itself enumerates manifests
    'tests/integration/host-registry.tests.ps1',        # test asserts the expected enum
    'tests/integration/multi-host-launch-path.tests.ps1', # F-040 integration test goldens
    'tests/integration/host-coupling-firewall.tests.ps1', # this file (defines the regex literals)
    'tests/integration/crew-bootstrap-contract.tests.ps1', # E2E test legitimately iterates all supported hosts
    # Phase D follow-up — pre-refactor hardcodes that need the registry plumbed through
    # ~2400-line scripts. Fixing requires substantial scope; tracked separately.
    'scripts/specrew-init.ps1',                # lines 1642 (agent-enable validator) + 1730 (iteration-config.yml agents block) in original layout
    'scripts/init/agent-detection.ps1',        # Same hardcodes moved here during Proposal 108 Slice 6 extraction; cleanup requires iteration-config.yml schema migration to add antigravity slot (deferred)
    'tests/manual/multi-host-smoke.ps1'        # intentionally enumerates the original 3 hosts for smoke comparison
)

$preFeatureAllowListCount = 11
$sliceAAllowListCeiling = 8
if ($allowListExact.Count -gt $sliceAAllowListCeiling) {
    Write-Fail ("Host-enum allow-list grew or failed to shrink: baseline {0}, Slice A ceiling {1}, actual {2}." -f $preFeatureAllowListCount, $sliceAAllowListCeiling, $allowListExact.Count)
}
if ($allowListExact.Count -ge $preFeatureAllowListCount) {
    Write-Fail ("Host-enum allow-list must remain below its pre-feature baseline of {0}; actual {1}." -f $preFeatureAllowListCount, $allowListExact.Count)
}
Write-Pass ("Host-enum allow-list is bounded below the pre-feature baseline ({0} -> {1}; ceiling {2})" -f $preFeatureAllowListCount, $allowListExact.Count, $sliceAAllowListCeiling)

# Directories to skip wholesale (specs, proposals, CHANGELOG, docs, .scratch, .squad, .specify mirrors)
$skipDirs = @(
    'specs', 'proposals', 'docs', '.scratch', '.squad', '.specify', '.specrew',
    '.git', 'node_modules', 'hosts'   # hosts/ is allowed by definition
)

$violations = New-Object System.Collections.Generic.List[hashtable]
$scriptFiles = Get-ChildItem -Path $repoRoot -Filter '*.ps1' -Recurse -File | Where-Object {
    $rel = $_.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
    $topLevel = $rel.Split('/')[0]
    -not ($skipDirs -contains $topLevel)
}

foreach ($file in $scriptFiles) {
    $rel = $file.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
    if ($allowListExact -contains $rel) { continue }

    $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($content)) { continue }

    foreach ($pattern in $enumPatterns) {
        $hits = [regex]::Matches($content, $pattern)
        if ($hits.Count -gt 0) {
            $lineNumbers = @()
            $lines = $content -split "`n"
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match $pattern) {
                    $lineNumbers += ($i + 1)
                }
            }
            $violations.Add(@{
                File    = $rel
                Pattern = $pattern
                Lines   = $lineNumbers
            }) | Out-Null
        }
    }
}

if ($violations.Count -gt 0) {
    Write-Host "VIOLATIONS — hardcoded host enums outside hosts/ + allow-list:" -ForegroundColor Red
    foreach ($v in $violations) {
        Write-Host ("  {0} (lines: {1})" -f $v.File, ($v.Lines -join ', ')) -ForegroundColor Yellow
        Write-Host ("    pattern: {0}" -f $v.Pattern) -ForegroundColor DarkGray
    }
    Write-Host ''
    Write-Host "To resolve: replace the hardcoded enum with Get-RegisteredHostKinds (from hosts/_registry.ps1) OR add the file to the allow-list with a documented exception." -ForegroundColor Yellow
    $violationFiles = @($violations | ForEach-Object { $_.File } | Sort-Object -Unique)
    Write-Fail ("Found {0} hardcoded-enum violation(s) across {1} file(s)." -f $violations.Count, $violationFiles.Count)
}

Write-Pass ("No hardcoded host-enum violations across {0} scanned production .ps1 file(s) (allow-list: {1} known)." -f $scriptFiles.Count, $allowListExact.Count)

# Permanent host-addition purity proof. Keep the reserved names assembled so
# this test does not itself become a hand-authored host literal outside the
# package it protects.
$reservedHostTokens = @(
    (@('de', 'vin') -join ''),
    (@('wind', 'surf') -join '')
)
$purityEvidenceSkipDirs = @(
    'tests', 'specs', 'proposals', 'docs', '.scratch', '.squad', '.specify',
    '.specrew', '.git', 'node_modules'
)
$purityGeneratedArtifactExemptions = @(
    'Specrew.psd1'
)
$purityExtensions = @('.ps1', '.psm1', '.psd1', '.sh', '.json', '.yml', '.yaml')

function Find-SpecrewHostAdditionPurityViolation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [Parameter(Mandatory = $true)]
        [string[]]$HostTokens,
        [string[]]$EvidenceSkipDirs = @(),
        [string[]]$GeneratedArtifactExemptions = @()
    )

    $root = (Resolve-Path -LiteralPath $RootPath).Path
    $protectedPackagePrefix = "hosts/$($HostTokens[0])/"
    $found = [System.Collections.Generic.List[object]]::new()

    foreach ($file in @(Get-ChildItem -LiteralPath $root -Recurse -File -Force)) {
        $relative = [System.IO.Path]::GetRelativePath($root, $file.FullName).Replace('\', '/')
        $topLevel = $relative.Split('/')[0]
        if ($EvidenceSkipDirs -contains $topLevel) { continue }
        if ($GeneratedArtifactExemptions -contains $relative) { continue }
        if ($relative.StartsWith($protectedPackagePrefix, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($purityExtensions -notcontains $file.Extension.ToLowerInvariant()) { continue }

        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($content)) { continue }
        foreach ($token in $HostTokens) {
            if ($content.IndexOf($token, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
            $lineNumbers = [System.Collections.Generic.List[int]]::new()
            $lines = $content -split '\r?\n'
            for ($index = 0; $index -lt $lines.Count; $index++) {
                if ($lines[$index].IndexOf($token, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $lineNumbers.Add($index + 1) | Out-Null
                }
            }
            $found.Add([pscustomobject]@{
                    File  = $relative
                    Token = $token
                    Lines = @($lineNumbers)
                }) | Out-Null
        }
    }

    return @($found)
}

$purityViolations = @(
    Find-SpecrewHostAdditionPurityViolation `
        -RootPath $repoRoot `
        -HostTokens $reservedHostTokens `
        -EvidenceSkipDirs $purityEvidenceSkipDirs `
        -GeneratedArtifactExemptions $purityGeneratedArtifactExemptions
)
if ($purityViolations.Count -gt 0) {
    $details = @(
        $purityViolations |
            ForEach-Object { "{0}:{1} ({2})" -f $_.File, ($_.Lines -join ','), $_.Token }
    )
    Write-Fail ("Host-addition purity violation outside the protected package: {0}" -f ($details -join '; '))
}
Write-Pass 'Production shared core contains no reserved-host routing literals outside the protected host package'

$purityScratch = Join-Path $repoRoot ('.scratch\host-purity-' + [guid]::NewGuid().ToString('N'))
try {
    $fixtureScripts = Join-Path $purityScratch 'scripts'
    New-Item -ItemType Directory -Path $fixtureScripts -Force | Out-Null
    $plantedPath = Join-Path $fixtureScripts 'planted-routing.ps1'
    $plantedContent = "if (`$HostKind -eq '$($reservedHostTokens[0])') { return '$($reservedHostTokens[1])' }"
    Set-Content -LiteralPath $plantedPath -Encoding UTF8 -Value $plantedContent
    $plantedViolations = @(
        Find-SpecrewHostAdditionPurityViolation `
            -RootPath $purityScratch `
            -HostTokens $reservedHostTokens
    )
    if ($plantedViolations.Count -ne 2) {
        Write-Fail "Purity negative test expected both planted tokens through the production scanner; found $($plantedViolations.Count)."
    }

    Set-Content -LiteralPath $plantedPath -Encoding UTF8 -Value "if (`$HostKind -in (Get-RegisteredHostKinds)) { Get-HostManifest -Kind `$HostKind }"
    $cleanViolations = @(
        Find-SpecrewHostAdditionPurityViolation `
            -RootPath $purityScratch `
            -HostTokens $reservedHostTokens
    )
    if ($cleanViolations.Count -ne 0) {
        Write-Fail 'Purity scanner flagged clean registry-driven fixture content.'
    }
}
finally {
    if (Test-Path -LiteralPath $purityScratch) {
        Remove-Item -LiteralPath $purityScratch -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Pass 'Purity negative proof uses the production scanner and distinguishes planted literals from registry-driven content'

# F-184 sendback guard: shared hook/bootstrap core may receive a HostKind value,
# but host routing/output policy must come from RefocusHookBindings.DispatcherRuntime,
# not from Antigravity/agy literals in core conditionals.
$forbiddenCorePatterns = @(
    "Get-Command 'agy'",
    "Get-Command `"agy`"",
    "TargetHost -eq 'antigravity'",
    "HostKind -eq 'antigravity'",
    "'antigravity' {",
    "hostKind -notin @('claude', 'codex', 'copilot', 'cursor', 'antigravity')",
    "antigravity' { return 'pointer'"
)
foreach ($coreRel in @(
        'scripts/internal/specrew-hook-dispatcher.ps1',
        'scripts/internal/specrew-bootstrap-provider.ps1',
        'scripts/internal/deploy-refocus-hooks.ps1',
        'scripts/internal/instruction-deploy.ps1',        # F-184 iter-002 (T005): host-neutral instruction-delivery core
        'scripts/internal/instruction-file-merge.ps1'     # F-184 iter-002 (T005): single-source merge primitive
    )) {
    $corePath = Join-Path $repoRoot $coreRel
    $coreText = Get-Content -LiteralPath $corePath -Raw
    foreach ($pattern in $forbiddenCorePatterns) {
        if ($coreText.Contains($pattern)) {
            Write-Fail "Forbidden host abstraction leak in ${coreRel}: $pattern"
        }
    }
}
Write-Pass 'Shared hook/bootstrap core has no Antigravity/agy routing literals; it consumes manifest runtime policy'

# F-184 iter-002 (T005): NEGATIVE test - prove the forbidden-core scan actually CATCHES a planted single-host
# literal (the Shape-8 lesson: exercise the failure path, not only the happy path). Uses the SAME
# $forbiddenCorePatterns + Contains detection the scan above runs on the guarded core files.
$plantedLiteral = "if (`$HostKind -eq 'antigravity') { return 'pointer' }"
$detectedOnPlant = $false
foreach ($pattern in $forbiddenCorePatterns) { if ($plantedLiteral.Contains($pattern)) { $detectedOnPlant = $true; break } }
if (-not $detectedOnPlant) { Write-Fail "Negative test broken: the firewall did NOT detect a planted single-host literal: $plantedLiteral" }
Write-Pass 'Negative test: the firewall DETECTS a planted single-host literal (fails closed, not just on clean files)'

$cleanContent = "if (`$kind -in (Get-RegisteredHostKinds)) { Get-HostManifest -Kind `$kind }"
$detectedOnClean = $false
foreach ($pattern in $forbiddenCorePatterns) { if ($cleanContent.Contains($pattern)) { $detectedOnClean = $true; break } }
if ($detectedOnClean) { Write-Fail 'Negative test broken: the firewall flagged clean manifest-driven content' }
Write-Pass 'Negative test: the firewall PASSES clean host-neutral (manifest-driven) content'

# Bonus check: manifest-completeness — every supported host should have InstructionsFile set
# (caught the Antigravity drift in the deep-review audit).
. (Join-Path $repoRoot 'hosts\_registry.ps1')
$missingInstructionsFile = @()
foreach ($kind in @(Get-SpecrewHostsByStatus -Status supported)) {
    $manifest = Get-HostManifest -Kind $kind
    if (-not $manifest.ContainsKey('InstructionsFile') -or [string]::IsNullOrWhiteSpace([string]$manifest.InstructionsFile)) {
        $missingInstructionsFile += $kind
    }
}
if ($missingInstructionsFile.Count -gt 0) {
    Write-Fail ("Supported hosts missing manifest InstructionsFile field: {0}. Phase D parameterization of Test-HostInstructionsChangeType depends on this field." -f ($missingInstructionsFile -join ', '))
}
Write-Pass 'All supported hosts populate manifest InstructionsFile field'

Write-Host "`nHost-coupling firewall: all assertions pass" -ForegroundColor Green
