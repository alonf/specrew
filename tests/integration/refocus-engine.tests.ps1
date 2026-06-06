# Feature 171 T001: RefocusEngine integration tests (FR-001/003/004/005/012/017).
# Exercises the REAL engine against a scratch Specrew project: golden payloads,
# budget caps, confinement refusals, fail-open paths, and operator commands.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failures++ }

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Pass $Message } else { Write-Fail $Message }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$engine = Join-Path $repoRoot 'scripts\internal\refocus.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\refocus-engine'
$projectRoot = Join-Path $scratchRoot 'project'

if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }

function Invoke-Engine {
    param([string[]]$EngineArgs = @())
    $stdoutPath = Join-Path $scratchRoot 'stdout.txt'
    $stderrPath = Join-Path $scratchRoot 'stderr.txt'
    Push-Location $projectRoot
    try {
        $proc = Start-Process -FilePath 'pwsh' -ArgumentList (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $engine) + $EngineArgs) `
            -WorkingDirectory $projectRoot -Wait -PassThru -NoNewWindow `
            -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        return @{
            ExitCode = $proc.ExitCode
            StdOut   = (Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue) ?? ''
            StdErr   = (Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue) ?? ''
        }
    }
    finally { Pop-Location }
}

function New-ScratchProject {
    param([switch]$WithCatalog, [string]$SchemaVersion = '1')

    if (Test-Path -LiteralPath $projectRoot) { Remove-Item -LiteralPath $projectRoot -Recurse -Force }
    $extDir = Join-Path $projectRoot '.specify\extensions\specrew-speckit'
    $digestDir = Join-Path $extDir 'refocus'
    New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path $digestDir -Force | Out-Null

    $startContext = @{ session_state = @{ boundary_type = 'implement'; feature_ref = '171-specrew-refocus' } } | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\start-context.json'), $startContext, [System.Text.UTF8Encoding]::new($false))

    $generalDigest = @"
---
scope: general
sources:
  - .specrew/constitution.md
  - docs/methodology/lifecycle-discipline.md
reviewed_at: 2026-06-07
---
## Always-true Specrew core (fixture)

Boundary discipline holds. One approval advances one boundary.
"@
    [System.IO.File]::WriteAllText((Join-Path $digestDir 'general.md'), $generalDigest, [System.Text.UTF8Encoding]::new($false))

    $implementDigest = @"
---
scope: boundary.implement
sources:
  - docs/methodology/lifecycle-discipline.md
reviewed_at: 2026-06-07
---
## Implement-stage discipline (fixture)

Commit per boundary. Tests ride with code. IMPLEMENT-MARKER.
"@
    [System.IO.File]::WriteAllText((Join-Path $digestDir 'implement.md'), $implementDigest, [System.Text.UTF8Encoding]::new($false))

    $reviewDigest = @"
---
scope: boundary.review-signoff
sources:
  - docs/methodology/review-instructions.md
reviewed_at: 2026-06-07
---
## Review-signoff discipline (fixture)

Runtime claims need runtime evidence. REVIEW-MARKER.
"@
    [System.IO.File]::WriteAllText((Join-Path $digestDir 'review-signoff.md'), $reviewDigest, [System.Text.UTF8Encoding]::new($false))

    if ($WithCatalog) {
        $catalog = [ordered]@{
            schema_version = $SchemaVersion
            scopes         = [ordered]@{
                'general'                  = @('refocus/general.md')
                'boundary.implement'       = @('refocus/implement.md')
                'boundary.review-signoff'  = @('refocus/review-signoff.md')
            }
            triggers       = [ordered]@{
                b1 = [ordered]@{ enabled = $true; scopes = @('general', 'boundary.current') }
                b2 = [ordered]@{ enabled = $true; scopes = @('general') }
                b3 = [ordered]@{ enabled = $true; scopes = @('general', 'boundary.current') }
            }
            budgets        = [ordered]@{ b1 = 2500; b2 = 1200; b3 = 2000; manual = 3000 }
            providers      = @(
                [ordered]@{ id = 'refocus'; kind = 'inject'; events = @('SessionStart', 'PostToolUse'); order = 10; budget_share = 1.0; command = 'refocus.ps1' }
            )
        } | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText((Join-Path $extDir 'refocus-scopes.json'), $catalog, [System.Text.UTF8Encoding]::new($false))
    }
}

# --- 1. Golden path: no-args composes general + current boundary -------------
New-ScratchProject -WithCatalog
$result = Invoke-Engine
Assert-True ($result.ExitCode -eq 0) 'no-args exits 0'
$firstLine = ($result.StdOut -split "`r?`n")[0]
Assert-True ($firstLine -match '^\[specrew-refocus\] trigger=manual scope=general\+boundary\.implement sources=\d+ tokens~\d+$') "banner is line 1 with trigger/scope/sources/tokens (got: $firstLine)"
Assert-True ($result.StdOut.Contains('Always-true Specrew core')) 'payload contains the general digest body'
Assert-True ($result.StdOut.Contains('IMPLEMENT-MARKER')) 'payload contains the current-stage digest body'
Assert-True (-not $result.StdOut.Contains('reviewed_at')) 'frontmatter is stripped from the payload'
Assert-True ([string]::IsNullOrWhiteSpace($result.StdErr)) 'golden path emits no warnings'

# --- 2. --boundary explicit stage --------------------------------------------
$result = Invoke-Engine -EngineArgs @('--boundary', 'review-signoff')
Assert-True ($result.ExitCode -eq 0) '--boundary exits 0'
Assert-True ($result.StdOut.Contains('REVIEW-MARKER')) '--boundary review-signoff loads the named stage digest'

# --- 3. Unknown scope fails open with SOURCE_MISSING -------------------------
$result = Invoke-Engine -EngineArgs @('--boundary', 'no-such-stage')
Assert-True ($result.ExitCode -eq 0) 'unknown boundary still exits 0 (fail-open)'
Assert-True ($result.StdErr.Contains('WARN SOURCE_MISSING')) 'unknown boundary warns SOURCE_MISSING'
Assert-True ($result.StdOut.Contains('fallback pointer set')) 'unknown boundary substitutes the fallback pointer set'

# --- 4. Missing catalog fails open -------------------------------------------
New-ScratchProject
$result = Invoke-Engine
Assert-True ($result.ExitCode -eq 0) 'missing catalog exits 0 (fail-open)'
Assert-True ($result.StdErr.Contains('WARN SOURCE_MISSING')) 'missing catalog warns SOURCE_MISSING'
Assert-True ($result.StdOut.Contains('fallback pointer set')) 'missing catalog emits the fallback pointer set'

# --- 5. Schema mismatch fails open with CATALOG_SCHEMA -----------------------
New-ScratchProject -WithCatalog -SchemaVersion '99'
$result = Invoke-Engine
Assert-True ($result.ExitCode -eq 0) 'schema mismatch exits 0 (fail-open)'
Assert-True ($result.StdErr.Contains('WARN CATALOG_SCHEMA')) 'schema mismatch warns CATALOG_SCHEMA'

# --- 6. Confinement: absolute + traversal digest paths refused ---------------
New-ScratchProject -WithCatalog
$extDir = Join-Path $projectRoot '.specify\extensions\specrew-speckit'
$catalogPath = Join-Path $extDir 'refocus-scopes.json'
$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$catalog.scopes.'general' = @('C:\evil\absolute.md', '..\..\escape.md', 'refocus/general.md')
[System.IO.File]::WriteAllText($catalogPath, ($catalog | ConvertTo-Json -Depth 6), [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Engine
Assert-True ($result.ExitCode -eq 0) 'confinement refusal still exits 0'
Assert-True (([regex]::Matches($result.StdErr, 'WARN SOURCE_CONFINED')).Count -eq 2) 'absolute and traversal paths each warn SOURCE_CONFINED'
Assert-True ($result.StdOut.Contains('Always-true Specrew core')) 'confined entries are skipped but safe entries still load'

# --- 7. Budget clipping with BUDGET_EXCEEDED ----------------------------------
New-ScratchProject -WithCatalog
$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$catalog.budgets.b1 = 10
[System.IO.File]::WriteAllText($catalogPath, ($catalog | ConvertTo-Json -Depth 6), [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Engine -EngineArgs @('--trigger', 'b1')
Assert-True ($result.ExitCode -eq 0) 'clipped payload exits 0'
Assert-True ($result.StdErr.Contains('WARN BUDGET_EXCEEDED')) 'over-budget payload warns BUDGET_EXCEEDED'
Assert-True ($result.StdOut.Contains('payload clipped to the catalog budget cap')) 'clipped payload says so in-band'

# --- 8. --trigger b1 resolves boundary.current placeholder --------------------
New-ScratchProject -WithCatalog
$result = Invoke-Engine -EngineArgs @('--trigger', 'b1')
Assert-True ($result.ExitCode -eq 0) '--trigger b1 exits 0'
$firstLine = ($result.StdOut -split "`r?`n")[0]
Assert-True ($firstLine -match '^\[specrew-refocus\] trigger=b1 scope=general\+boundary\.implement ') "trigger banner resolves boundary.current to the live stage (got: $firstLine)"
Assert-True ($result.StdOut.Contains('IMPLEMENT-MARKER')) 'b1 payload carries the current-stage digest'

# --- 9. Bad args exit 2 with EVENT_PARSE --------------------------------------
$result = Invoke-Engine -EngineArgs @('--no-such-flag')
Assert-True ($result.ExitCode -eq 2) 'unknown flag exits 2 (human surface)'
Assert-True ($result.StdErr.Contains('WARN EVENT_PARSE')) 'unknown flag warns EVENT_PARSE'
$result = Invoke-Engine -EngineArgs @('--trigger', 'b9')
Assert-True ($result.ExitCode -eq 2) 'invalid trigger id exits 2'

# --- 10. --compact-instructions from live state -------------------------------
$result = Invoke-Engine -EngineArgs @('--compact-instructions')
Assert-True ($result.ExitCode -eq 0) '--compact-instructions exits 0'
Assert-True ($result.StdOut.StartsWith('/compact preserve:')) 'compact instructions are paste-ready'
Assert-True ($result.StdOut.Contains('171-specrew-refocus')) 'preserve-list names the live feature'
Assert-True ($result.StdOut.Contains('implement')) 'preserve-list names the live boundary'

# --- 11. --status runs clean ---------------------------------------------------
$result = Invoke-Engine -EngineArgs @('--status')
Assert-True ($result.ExitCode -eq 0) '--status exits 0'
Assert-True ($result.StdOut.Contains('env SPECREW_REFOCUS_DISABLE')) '--status reports the env kill switch'
Assert-True ($result.StdOut.Contains('trigger b1: enabled')) '--status reports per-trigger catalog flags'
Assert-True ($result.StdOut.Contains('no runtime state recorded yet')) '--status reports session state absence honestly'

# --- 12. --role missing charter fails open -------------------------------------
$result = Invoke-Engine -EngineArgs @('--role', 'reviewer')
Assert-True ($result.ExitCode -eq 0) 'missing role charter exits 0 (fail-open)'
Assert-True ($result.StdErr.Contains('WARN SOURCE_MISSING')) 'missing role charter warns SOURCE_MISSING'

# --- 13. --role loads a real charter -------------------------------------------
$roleDir = Join-Path $projectRoot '.specrew\team\agents'
New-Item -ItemType Directory -Path $roleDir -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $roleDir 'reviewer.md'), "# Reviewer charter fixture`nROLE-MARKER", [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Engine -EngineArgs @('--role', 'reviewer')
Assert-True ($result.ExitCode -eq 0) '--role exits 0'
Assert-True ($result.StdOut.Contains('ROLE-MARKER')) '--role loads the charter body'

# --- summary -------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
if ($script:Failures -gt 0) {
    Write-Host "refocus-engine tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}
Write-Host 'refocus-engine tests: all passed' -ForegroundColor Green
exit 0
