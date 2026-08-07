$ErrorActionPreference = 'Stop'

# DRIFT-198-I011-011 — GENERATOR PARITY: a governed writer must emit artifacts that pass the
# repository's OWN required lint.
#
# The defect this pins: `scaffold-reviewer-artifacts.ps1` emitted MD009 (trailing spaces), MD032
# (blanks-around-lists) and MD047 (single trailing newline) violations, so `Specrew CI`'s REQUIRED
# `Lint` job failed on files nobody hand-wrote. Every code-touching iteration that ran the scaffolder
# inherited a red Lint until a human corrected it by hand — and it reached the release gate, where a
# GitHub Actions outage masked it for a full day.
#
# CONSUMER-REACHABLE, which is why this is a registry test rather than a repo convenience:
# templates/lifecycle/docs-only-lifecycle.md instructs CONSUMERS to run markdownlint. A generator that
# emits non-conformant markdown therefore hands every downstream project a red lint out of the box.
#
# THE PATTERN, stated once here because it generalizes past this generator: a writer's output is not
# "correct" because it parses — it is correct when it passes the same gate its consumers are told to
# run. Fixing the emitted FILES is a one-off; fixing the GENERATOR and pinning it with parity is the
# repair. The class fix — parity tests for every governed writer — is a beta3 row.
#
# Run standalone:
#   pwsh -NoProfile -File tests/integration/generator-markdown-parity.tests.ps1

$script:Fail = 0
$script:Hard = 0
function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Red { param([string]$m) Write-Host "RED: $m" -ForegroundColor Yellow; $script:Fail++ }
function Write-Measured { param([string]$m) Write-Host "MEASURED: $m" -ForegroundColor Cyan }
function Write-Inconclusive { param([string]$m) Write-Host "INCONCLUSIVE (harness defect, NOT a pass): $m" -ForegroundColor Magenta; $script:Hard++ }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$scaffolder = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1'
$reviewScaffolder = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-review-artifact.ps1'
$mdConfig = Join-Path $repoRoot '.markdownlint.json'

# markdownlint is what CI runs (`npm install -g markdownlint-cli`). Absent locally, this measures
# NOTHING — the third-outcome rule applies rather than a silent pass.
$mdl = Get-Command markdownlint -ErrorAction SilentlyContinue
if (-not $mdl) {
    Write-Inconclusive 'markdownlint is not installed; this harness cannot verify generator parity (npm install -g markdownlint-cli)'
    Write-Host ''
    Write-Host '=== generator-markdown-parity: INCONCLUSIVE — install markdownlint-cli ===' -ForegroundColor Magenta
    exit 2
}

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("genparity-" + [guid]::NewGuid().ToString('N'))
$iterDir = Join-Path $scratch 'specs\050-host-neutral-gate\iterations\001'
New-Item -ItemType Directory -Path $iterDir -Force | Out-Null

try {
    # A minimal but REAL iteration the scaffolders accept: plan.md supplies the task table they read.
    Set-Content -LiteralPath (Join-Path $iterDir 'plan.md') -Encoding UTF8 -Value @'
# Iteration Plan: 001

**Schema**: v1
**Status**: reviewing

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| --- | --- | --- | --- | --- | --- | --- |
| T001 | Do the thing | FR-001 | US-1 | 2 | Implementer | done |
'@

    # The scaffolder requires the iteration's own artifacts to exist — state.md and drift-log.md
    # alongside plan.md. Found by the INCONCLUSIVE guard on this harness's first run, which reported a
    # fixture gap instead of scoring the generator as parity-clean.
    Set-Content -LiteralPath (Join-Path $iterDir 'state.md') -Encoding UTF8 -Value @'
# Iteration State: 001

**Schema**: v1
**Current Phase**: review
**Iteration Status**: reviewing
**Last Completed Task**: T001
**Tasks Remaining**: (none)
**In Progress**: (none)
'@
    Set-Content -LiteralPath (Join-Path $iterDir 'drift-log.md') -Encoding UTF8 -Value @'
# Drift Log — Iteration 001

No drift recorded.
'@

    # scaffold-reviewer-artifacts requires review.md to exist first, so generate it with its own
    # governed scaffolder — BOTH writers are under test, not just the one that failed CI.
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $reviewScaffolder -IterationDirectory $iterDir *> $null
    if (-not (Test-Path -LiteralPath (Join-Path $iterDir 'review.md'))) {
        Write-Inconclusive 'scaffold-review-artifact.ps1 produced no review.md — the probe never reached the reviewer-artifact generator'
        exit 2
    }

    $out = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $scaffolder -IterationDirectory $iterDir 2>&1) -join "`n"
    $generated = @(Get-ChildItem -LiteralPath $iterDir -Filter '*.md' -File | Select-Object -ExpandProperty FullName)
    Write-Measured ("generated {0} markdown artifact(s): {1}" -f $generated.Count, (($generated | ForEach-Object { Split-Path -Leaf $_ }) -join ', '))

    if ($generated.Count -lt 3) {
        Write-Inconclusive ("the scaffolder produced too few artifacts to measure parity. Output: {0}" -f (($out -replace '\s+', ' ').Trim()))
        exit 2
    }

    # THE ASSERTION: the repository's own lint, over the generator's own output.
    #
    # The VERDICT is markdownlint's EXIT CODE, not this harness's parse of its text. The first revision
    # scored the rule matches instead and reported PASS while the exit code was 1 — a false green caused
    # by the harness mis-reading its own instrument, which is the exact defect class this iteration
    # exists to kill. The exit code is the tool's own verdict; the parsed lines are detail for a human.
    # Run FROM the artifact directory with RELATIVE names. markdownlint-cli's ignore layer throws
    # `RangeError: path should be a path.relative()'d string` on absolute paths outside its cwd, which
    # surfaces as a bare exit 1 indistinguishable from a violation — the ambiguity guarded below.
    $names = @($generated | ForEach-Object { Split-Path -Leaf $_ })
    Push-Location -LiteralPath $iterDir
    # Use the REPOSITORY's own config, which is what CI and consumers run. Without it this harness
    # flagged MD013 (line-length) — disabled in .markdownlint.json — and would have over-blocked the
    # generator on a rule the project deliberately turned off.
    try { $lintRaw = & markdownlint -c $mdConfig @names 2>&1; $lintExit = $LASTEXITCODE }
    finally { Pop-Location }
    $lint = (@($lintRaw | ForEach-Object { [string]$_ })) -join "`n"
    $violations = @($lint -split "`n" | Where-Object { $_ -match 'MD\d{3}' })
    Write-Measured ("markdownlint exit={0}; violation lines parsed={1}" -f $lintExit, $violations.Count)

    # A non-zero exit with NO parsed rule is ambiguous: markdownlint exits 1 for a USAGE error too.
    # Scoring that as RED would be a false RED — the mirror of the false PASS this harness already
    # produced once. Ambiguity is the third outcome, not a finding.
    if ($lintExit -ne 0 -and $violations.Count -eq 0) {
        Write-Inconclusive ("markdownlint exited {0} but named no MD rule — cannot distinguish violations from an invocation error. Raw: {1}" -f $lintExit, (($lint -replace '\s+', ' ').Trim().Substring(0, [Math]::Min(200, $lint.Length))))
    }
    elseif ($lintExit -ne 0) {
        $rules = @($violations | ForEach-Object { if ($_ -match '(MD\d{3})') { $Matches[1] } } | Sort-Object -Unique)
        Write-Measured ("rules violated: {0}" -f ($rules -join ', '))
        foreach ($v in ($violations | Select-Object -First 6)) { Write-Host ("       {0}" -f $v.Trim()) -ForegroundColor DarkYellow }
        Write-Red ("the reviewer-artifact generator emits markdown that FAILS the repository's own required lint ({0}) — every consumer running the documented markdownlint step inherits these" -f ($rules -join ', '))
    }
    else {
        Write-Pass 'the reviewer-artifact generator emits markdown that passes the repository''s own required lint'
    }
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($script:Hard -gt 0) {
    Write-Host "=== generator-markdown-parity: $($script:Hard) INCONCLUSIVE — fix the harness before reading any result ===" -ForegroundColor Magenta
    exit 2
}
if ($script:Fail -gt 0) {
    Write-Host "=== generator-markdown-parity: $($script:Fail) RED assertion(s) ===" -ForegroundColor Yellow
    exit 1
}
Write-Host '=== generator-markdown-parity: generator output is lint-clean ===' -ForegroundColor Green
exit 0
