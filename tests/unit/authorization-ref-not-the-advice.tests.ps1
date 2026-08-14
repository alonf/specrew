$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T014 COMPLETION — `--authorization-ref` MUST NOT BE THE ADVICE.
#
# THE DEFECT. T014 replaced "invent an identifier" with "approve a round", because the maintainer -
# holding full context - could not work out what to type into `--authorization-ref <ref>`. The flag was
# then left as the INSTRUCTION in consumer-facing messages, so the product went on telling people to fill
# in the exact field the task existed to remove. Same incomplete-fix shape as the emission point and the
# in-flight staleness path: the capability landed and the callers kept the old form.
#
# WHY IT MATTERED ON A DEADLINE: a driver with a single agent CLI takes the labelled SAME-HOST FALLBACK
# path, whose note is one of these messages, so they would have met it minutes into their first review -
# spending the dogfood's first finding on something already known.
#
# SWEPT BY PROPERTY, NOT BY LINE NUMBER, and that is why this file exists rather than two edits. The two
# sites found by grep were not the set: the sweep found FIVE more - the CLI's own usage example, a
# Write-Host remediation, and two agent-facing refocus instructions. A guard over a hand-read list is
# method rule 2, and this iteration has already been bitten by exactly that (the front-door whitelist,
# whose recorded countermeasure was "a test covers the quartet" and which could not see a fifth flag).
#
# WHAT IS BANNED IS THE PLACEHOLDER FORM, NOT THE FLAG. `--authorization-ref` remains valid and supported
# for scripts and for anyone naming their own label - the maintainer's ruling keeps a working interface.
# What may not appear is `--authorization-ref <ref>`: a placeholder that asks a human to invent a value
# whose meaning was never explained. A CONCRETE label (`--authorization-ref workshop-<feature>`) is
# someone naming their own and stays legal, which is why the pattern targets the placeholder rather than
# the flag.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$failures = 0
function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Fail { param([string]$m) $script:failures++; Write-Host "FAIL: $m" -ForegroundColor Red }

# The surfaces a consumer or an agent reads. `.specify/` is a deployed mirror regenerated from
# extensions/, so it is excluded here and covered by its own parity guard.
$roots = @('scripts', 'extensions', 'templates', 'hosts', 'bin')
$scanned = 0
$offenders = [System.Collections.Generic.List[string]]::new()

foreach ($root in $roots) {
    $rootPath = Join-Path $repoRoot $root
    if (-not (Test-Path -LiteralPath $rootPath)) { continue }
    foreach ($file in Get-ChildItem -LiteralPath $rootPath -Recurse -File -Include '*.ps1', '*.md', '*.psm1') {
        $scanned++
        $lineNumber = 0
        foreach ($line in (Get-Content -LiteralPath $file.FullName)) {
            $lineNumber++
            # The instruction shape: a `specrew review` command carrying the PLACEHOLDER form.
            if ($line -match 'specrew review[^`''"]*--authorization-ref\s*<') {
                $relative = ($file.FullName.Substring($repoRoot.Length + 1)) -replace '\\', '/'
                $offenders.Add(("{0}:{1}" -f $relative, $lineNumber)) | Out-Null
            }
        }
    }
}

if ($offenders.Count -eq 0) {
    Write-Pass ("no consumer-facing message instructs --authorization-ref <ref> as the route ({0} files scanned)" -f $scanned)
}
else {
    Fail ("{0} message(s) still tell a human to invent an authorization reference. Use --approve-round; the system mints the reference:`n    {1}" -f $offenders.Count, ($offenders -join "`n    "))
}

# THE POSITIVE HALF (rule 4): a prohibition alone is satisfied by deleting the advice entirely, which
# would leave a consumer refused with no way forward - the failure the stop-block rewrite already made
# once. The two messages a driver actually meets must NAME the approving command.
$navigator = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1') -Raw
foreach ($required in @('SAME-HOST fallback', 'NO reviewer host is authorized')) {
    $found = [regex]::Match($navigator, [regex]::Escape($required) + '.{0,600}', 'Singleline')
    if (-not $found.Success) {
        Fail "the '$required' message is gone - it must still exist and still name a next step"
        continue
    }
    if ($found.Value -match '--approve-round') { Write-Pass "the '$required' message names --approve-round" }
    else { Fail "the '$required' message no longer names how to authorize a reviewer" }
}

# And the flag itself must remain SUPPORTED, or "it stays valid for scripts" would be untrue.
$reviewCli = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/specrew-review.ps1') -Raw
if ($reviewCli -match "Alias\('authorization-ref'\)") { Write-Pass '--authorization-ref remains a supported flag for scripts and self-chosen labels' }
else { Fail '--authorization-ref was removed; the ruling keeps it working and only stops it being the advice' }

# Reviewer selection is project setup, not a review spend. The same flag has a stricter meaning when it
# is carried into --live, so the help must name the distinction instead of making one branch look invalid.
if ($reviewCli -match 'With --host and without --live' -and
    $reviewCli -match 'When it authorizes a live round, --ack-reason is required') {
    Write-Pass 'help distinguishes non-spending reviewer setup from out-of-band live-round authority'
}
else {
    Fail 'help does not explain that pure reviewer setup needs no --ack-reason while live-round authority does'
}

if ($failures -gt 0) { Write-Host "$failures failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'authorization-ref is no longer the advice; --approve-round is.' -ForegroundColor Green
exit 0
