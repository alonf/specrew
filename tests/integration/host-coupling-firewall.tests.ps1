[CmdletBinding()]
param()

# Structural test: no PRODUCTION script file outside hosts/ should hardcode
# the multi-host enum. The architecture's Open-Closed promise depends on this.
#
# Allow-list patterns: certain callsites legitimately reference host names
# (ValidateSet attributes pending Phase D registry-driven validators; the
# registry script itself; integration tests; spec/proposal/CHANGELOG prose).
# Everything else must use Get-RegisteredHostKinds / Get-HostManifest.

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
    # Phase D follow-up — these 3 ValidateSets are the LAST remaining intentional hardcodes;
    # they become registry-driven when Phase D's [ValidateScript({...})] refactor lands.
    'scripts/specrew-start.ps1',
    'scripts/internal/host-flag-translation.ps1',
    'scripts/internal/coordinator-prompt-surgery.ps1',
    # Phase D follow-up — pre-refactor hardcodes that need the registry plumbed through
    # ~2400-line scripts. Fixing requires substantial scope; tracked separately.
    'scripts/specrew-init.ps1',                # lines 1642 (agent-enable validator) + 1730 (iteration-config.yml agents block) in original layout
    'scripts/init/agent-detection.ps1',        # Same hardcodes moved here during Proposal 108 Slice 6 extraction; cleanup requires iteration-config.yml schema migration to add antigravity slot (deferred)
    'tests/manual/multi-host-smoke.ps1'        # intentionally enumerates the original 3 hosts for smoke comparison
)

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
    Write-Fail ("Found {0} hardcoded-enum violation(s) across {1} file(s)." -f $violations.Count, ($violations.File | Sort-Object -Unique).Count)
}

Write-Pass ("No hardcoded host-enum violations across {0} scanned production .ps1 file(s) (allow-list: {1} known)." -f $scriptFiles.Count, $allowListExact.Count)

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
