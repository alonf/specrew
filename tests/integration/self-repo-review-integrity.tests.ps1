#requires -Version 7.0
# Feature 203 T002 follow-up (B5F-033; DRIFT-047; maintainer, 2026-11-07). The validator applies W43, the deployed
# machinery's integrity check, only while it checks a review record: inside its review-artifact check, which runs for
# an iteration in reviewing, retro or complete status and returns early when there is no review.md. Iteration 001 is
# executing with no review.md, so validating this repository as it stands never reaches W43, and the eleven files the
# mirror's stale record named would first have failed 203's own review sign-off.
#
# This case validates a copy of this tree with iteration 001 put in reviewing status and a review.md present, so the
# record is proven fresh on every run up to the sign-off. A control run with one deployed file hand-edited must show
# the integrity error, so the first run's silence cannot come from the check not being reached.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$iteration = 'specs/203-beta5-stabilization/iterations/001'
$integrityLine = 'does not match what was installed'
$failures = 0
function Write-Result {
    param([bool]$Ok, [string]$Message, [string]$Detail = '')
    if ($Ok) { Write-Host "PASS: $Message" -ForegroundColor Green; return }
    Write-Host "FAIL: $Message" -ForegroundColor Red
    if ($Detail) { Write-Host $Detail }
    $script:failures++
}

# The tree as the validator would see it at sign-off: tracked and unignored files, uncommitted changes included.
$listed = @(& git -C $repoRoot ls-files -co --exclude-standard 2>&1)
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: could not list this tree's files with git: $($listed -join ' ')" -ForegroundColor Red; exit 1 }
$copy = Join-Path ([IO.Path]::GetTempPath()) ('self-repo-review-' + [guid]::NewGuid().ToString('N'))
try {
    foreach ($relative in $listed) {
        $from = Join-Path $repoRoot $relative
        if (-not (Test-Path -LiteralPath $from -PathType Leaf)) { continue }   # deleted in the work tree
        # A tracked symbolic link (e.g. under .antigravitycli) may point at nothing on this machine; the validator reads none.
        if ((Get-Item -LiteralPath $from -Force).LinkType) { continue }
        $to = Join-Path $copy $relative
        $parent = Split-Path -Parent $to
        if (-not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
        [IO.File]::Copy($from, $to, $true)
    }

    $statePath = Join-Path $copy "$iteration/state.md"
    $state = [IO.File]::ReadAllText($statePath)
    if ($state -notmatch '(?m)^\*\*Iteration Status\*\*: \S+') { throw "no Iteration Status line in $iteration/state.md" }
    $state = [regex]::Replace($state, '(?m)^(\*\*Iteration Status\*\*: )\S+', '${1}reviewing')
    [IO.File]::WriteAllText($statePath, $state, [Text.UTF8Encoding]::new($false))
    # The validator takes the iteration's status from plan.md's own Status line, and requires it to agree with review.md.
    $planPath = Join-Path $copy "$iteration/plan.md"
    $plan = [IO.File]::ReadAllText($planPath)
    if ($plan -notmatch '(?m)^\*\*Status\*\*: \S+') { throw "no Status line in $iteration/plan.md" }
    $plan = ([regex]'(?m)^(\*\*Status\*\*: )\S+').Replace($plan, '${1}reviewing', 1)
    # A reviewing iteration needs every task terminal and a review record with a verdict per task, so the copy's
    # task table is marked done and review.md is written in the shape of a real one. Only the copy is changed.
    $verdictRows = [System.Collections.Generic.List[string]]::new()
    $planLines = $plan -split "`n"
    for ($n = 0; $n -lt $planLines.Count; $n++) {
        if ($planLines[$n] -notmatch '^\| T\d{3} \|') { continue }
        $cells = $planLines[$n].TrimEnd("`r") -split '\|'
        $cells[8] = ' done '
        $planLines[$n] = ($cells -join '|') + $(if ($planLines[$n].EndsWith("`r")) { "`r" } else { '' })
        [void]$verdictRows.Add(('| {0} | {1} | pass | Placeholder verdict in the copy; this case checks the deployed mirror only. |' -f $cells[1].Trim(), $cells[3].Trim()))
    }
    if ($verdictRows.Count -eq 0) { throw "no task rows in $iteration/plan.md" }
    $plan = $planLines -join "`n"
    [IO.File]::WriteAllText($planPath, $plan, [Text.UTF8Encoding]::new($false))
    $reviewPath = Join-Path $copy "$iteration/review.md"
    if (-not (Test-Path -LiteralPath $reviewPath)) {
        $review = @('# Review: Iteration 001', '', '**Schema**: v1', ('**Reviewed**: {0}' -f (Get-Date -Format 'yyyy-MM-dd')),
            '**Overall Verdict**: accepted', '', 'Written by self-repo-review-integrity in a copy of the tree, so the review-artifact check runs.', '',
            '## Task Verdicts', '', '| Task | Requirement | Verdict | Notes |', '| ---- | ----------- | ------- | ----- |') + @($verdictRows) + @('')
        [IO.File]::WriteAllText($reviewPath, ($review -join "`n"), [Text.UTF8Encoding]::new($false))
    }

    $validator = Join-Path $copy 'extensions/specrew-speckit/scripts/validate-governance.ps1'
    # The iteration path is given absolute and the validator runs from inside the copy: a relative -IterationPath
    # resolves against the current directory, and the first draft of this case validated the real tree instead.
    $copyIteration = Join-Path $copy $iteration
    function Invoke-CopyValidator {
        Push-Location -LiteralPath $copy
        try { $out = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validator -ProjectPath $copy -IterationPath $copyIteration -NoCacheRead -NoParallel 2>&1 | ForEach-Object { [string]$_ }) }
        finally { Pop-Location }
        $text = ($out -join "`n")
        if ($text -notmatch [regex]::Escape($copyIteration.Replace('/', '\'))) { throw "the validator did not report on the copy's iteration ($copyIteration):`n$text" }
        return $text
    }

    $clean = Invoke-CopyValidator
    $hit = @($clean -split "`n" | Where-Object { $_ -match [regex]::Escape($integrityLine) })
    Write-Result -Ok ($hit.Count -eq 0) -Message 'With iteration 001 in reviewing status, the deployed mirror matches its install record (no integrity error).' -Detail ($hit -join "`n")

    Add-Content -LiteralPath (Join-Path $copy '.specify/extensions/specrew-speckit/scripts/validate-governance.ps1') -Value '# hand-patched in the copy; extensions/ unchanged' -Encoding UTF8
    $edited = Invoke-CopyValidator
    Write-Result -Ok ($edited -match 'does not match what was installed \(modified: scripts/validate-governance\.ps1\)') -Message 'Control: in the same setup a hand edit to a deployed file is reported, so the check is reached.' -Detail (@($edited -split "`n" | Select-Object -Last 15) -join "`n")
}
finally {
    if (Test-Path -LiteralPath $copy) { Remove-Item -LiteralPath $copy -Recurse -Force -ErrorAction SilentlyContinue }
}
if ($failures) { exit 1 }
exit 0
