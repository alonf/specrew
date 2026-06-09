# Feature 171 T002: RefocusDigests integrity tests (FR-002, FR-019).
# Validates the REAL shipped digest family: presence, frontmatter contract (C5),
# token-budget caps (SC-003), placeholder mechanics, and the digest drift check
# (warn-style: a declared canonical source changed after reviewed_at).
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = 0
$script:Warnings = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failures++ }
function Write-DriftWarn { param([string]$Message) Write-Host "WARN: $Message" -ForegroundColor Yellow; $script:Warnings++ }

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Pass $Message } else { Write-Fail $Message }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$digestDir = Join-Path $repoRoot 'extensions\specrew-speckit\refocus'

$expectedStages = @('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'implement', 'review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')

function Get-TokenEstimate { param([string]$Text) return [int][math]::Ceiling($Text.Length / 4.0) }

function Read-DigestParts {
    param([Parameter(Mandatory = $true)][string]$Path)
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $match = [regex]::Match($raw, '(?s)^---\r?\n(?<fm>.*?)\r?\n---\r?\n(?<body>.*)$')
    if (-not $match.Success) { return $null }
    $fm = $match.Groups['fm'].Value
    $scope = [regex]::Match($fm, '(?m)^scope:\s*(?<v>\S+)').Groups['v'].Value
    $reviewedAt = [regex]::Match($fm, '(?m)^reviewed_at:\s*(?<v>\S+)').Groups['v'].Value
    $sources = @([regex]::Matches($fm, '(?m)^\s*-\s+(?<v>\S.*)$') | ForEach-Object { $_.Groups['v'].Value.Trim() })
    return @{ Scope = $scope; ReviewedAt = $reviewedAt; Sources = $sources; Body = $match.Groups['body'].Value }
}

# --- 1. Family completeness ---------------------------------------------------
Assert-True (Test-Path -LiteralPath (Join-Path $digestDir 'general.md') -PathType Leaf) 'general.md exists'
foreach ($stage in $expectedStages) {
    Assert-True (Test-Path -LiteralPath (Join-Path $digestDir "$stage.md") -PathType Leaf) "$stage.md exists"
}
$actualCount = @(Get-ChildItem -LiteralPath $digestDir -Filter '*.md' -File).Count
Assert-True ($actualCount -eq 11) "digest family has exactly 11 members (found $actualCount)"

# --- 2. Frontmatter contract (C5) + body conventions ---------------------------
foreach ($file in Get-ChildItem -LiteralPath $digestDir -Filter '*.md' -File) {
    $parts = Read-DigestParts -Path $file.FullName
    if ($null -eq $parts) { Write-Fail "$($file.Name): missing or malformed frontmatter"; continue }
    Assert-True (-not [string]::IsNullOrWhiteSpace($parts.Scope)) "$($file.Name): declares scope"
    Assert-True ($parts.Sources.Count -ge 1) "$($file.Name): declares at least one canonical source"
    Assert-True ($parts.ReviewedAt -match '^\d{4}-\d{2}-\d{2}$') "$($file.Name): reviewed_at is an ISO date"
    Assert-True ($parts.Body.Contains('{{project_root}}')) "$($file.Name): carries {{project_root}} deep-source pointers"

    $expectedScope = if ($file.BaseName -eq 'general') { 'general' } else { "boundary.$($file.BaseName)" }
    Assert-True ($parts.Scope -eq $expectedScope) "$($file.Name): scope '$($parts.Scope)' matches filename convention '$expectedScope'"

    foreach ($source in $parts.Sources) {
        $sourcePath = Join-Path $repoRoot $source
        Assert-True (Test-Path -LiteralPath $sourcePath -PathType Leaf) "$($file.Name): declared source exists ($source)"
    }
}

# --- 3. Token-budget caps (SC-003) ---------------------------------------------
$generalParts = Read-DigestParts -Path (Join-Path $digestDir 'general.md')
$generalTokens = Get-TokenEstimate -Text $generalParts.Body
Assert-True ($generalTokens -le 600) "general.md body is <= 600 tokens (got ~$generalTokens)"
Assert-True ($generalParts.Body -match 'verdict\*\* stop on the Claude host, invoke the `specrew-gate-stop` skill') 'general.md scopes specrew-gate-stop verdict routing to Claude'
Assert-True ($generalParts.Body -match 'On non-Claude hosts, render the full packet directly') 'general.md gives non-Claude hosts a direct-render fallback'
Assert-True (-not ($generalParts.Body -match 'At a \*\*verdict\*\* stop invoke the `specrew-gate-stop` skill')) 'general.md does not tell every host to invoke specrew-gate-stop'
$specifyParts = Read-DigestParts -Path (Join-Path $digestDir 'specify.md')
Assert-True ($specifyParts.Body -match 'On Claude, invoke `specrew-gate-stop`; on non-Claude hosts, render directly') 'specify.md scopes specrew-gate-stop verdict routing by host'
Assert-True (-not ($specifyParts.Body -match 'at the verdict stop invoke the `specrew-gate-stop` skill')) 'specify.md does not tell every host to invoke specrew-gate-stop'
foreach ($stage in $expectedStages) {
    $parts = Read-DigestParts -Path (Join-Path $digestDir "$stage.md")
    $tokens = Get-TokenEstimate -Text $parts.Body
    Assert-True ($tokens -le 1500) "$stage.md body is <= 1500 tokens (got ~$tokens)"
    $composed = $generalTokens + $tokens
    Assert-True ($composed -le 2500) "general + $stage composes <= 2500 tokens (got ~$composed)"
}

# --- 4. Digest drift check (FR-019, warn-style) ---------------------------------
# A declared source committed AFTER the digest's reviewed_at means the digest may
# digest stale truth. Warn (per FR-019); fail only when git itself is unusable.
foreach ($file in Get-ChildItem -LiteralPath $digestDir -Filter '*.md' -File) {
    $parts = Read-DigestParts -Path $file.FullName
    if ($null -eq $parts) { continue }
    foreach ($source in $parts.Sources) {
        $lastCommitIso = & git -C $repoRoot log -1 --format=%cs -- $source 2>$null
        if ([string]::IsNullOrWhiteSpace($lastCommitIso)) { continue } # untracked/new source: nothing to compare
        if ([datetime]$lastCommitIso -gt [datetime]$parts.ReviewedAt) {
            Write-DriftWarn "$($file.Name): source '$source' changed ($lastCommitIso) after reviewed_at ($($parts.ReviewedAt)) — re-review the digest"
        }
    }
}
Write-Pass "drift check executed ($script:Warnings warning(s) — warnings do not fail the lane per FR-019)"

# --- 5. Placeholder substitution through the REAL engine -------------------------
$engine = Join-Path $repoRoot 'scripts\internal\refocus.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\refocus-digests'
$projectRoot = Join-Path $scratchRoot 'project'
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
$extDir = Join-Path $projectRoot '.specify\extensions\specrew-speckit'
New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $extDir 'refocus') -Force | Out-Null
Copy-Item -Path (Join-Path $digestDir '*.md') -Destination (Join-Path $extDir 'refocus') -Force
$catalog = [ordered]@{
    schema_version = '1'
    scopes         = [ordered]@{ 'general' = @('refocus/general.md'); 'boundary.implement' = @('refocus/implement.md') }
    triggers       = [ordered]@{ b1 = [ordered]@{ enabled = $true; scopes = @('general', 'boundary.current') } }
    budgets        = [ordered]@{ b1 = 2500; manual = 3000 }
    providers      = @([ordered]@{ id = 'refocus'; kind = 'inject'; events = @('SessionStart'); order = 10; budget_share = 1.0; command = 'refocus.ps1' })
} | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText((Join-Path $extDir 'refocus-scopes.json'), $catalog, [System.Text.UTF8Encoding]::new($false))
$startContext = @{ session_state = @{ boundary_type = 'implement'; feature_ref = 'digest-fixture' } } | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\start-context.json'), $startContext, [System.Text.UTF8Encoding]::new($false))

$stdoutPath = Join-Path $scratchRoot 'stdout.txt'
$stderrPath = Join-Path $scratchRoot 'stderr.txt'
$proc = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $engine) `
    -WorkingDirectory $projectRoot -Wait -PassThru -NoNewWindow `
    -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
$stdout = (Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue) ?? ''
Assert-True ($proc.ExitCode -eq 0) 'engine composes real digests with exit 0'
Assert-True ($stdout.Contains('Always-true Specrew core') -or $stdout.Contains('always-true core')) 'real general digest body delivered'
Assert-True (-not $stdout.Contains('{{project_root}}')) 'placeholders are substituted in the payload'
Assert-True ($stdout.Contains('file:///')) 'deep-source pointers resolve to file:/// URLs'

# --- summary ---------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
if ($script:Failures -gt 0) {
    Write-Host "refocus-digests tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}
Write-Host "refocus-digests tests: all passed ($script:Warnings drift warning(s))" -ForegroundColor Green
exit 0
