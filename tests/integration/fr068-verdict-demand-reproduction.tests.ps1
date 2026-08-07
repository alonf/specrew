$ErrorActionPreference = 'Stop'

# T086 — FR-068 reproduction harness (F-198 iteration 011).
#
# The spec's evidence note for FR-068 is binding: the 2026-07-25T17:40:45Z transcript is an
# observation ELSEWHERE, not a reproduction HERE. Implementation must begin by reproducing the
# defect, not by assuming its shape. This file is that reproduction.
#
# The observed shape had TWO halves in ONE delivered message, separated by a literal
# `----- AND ALSO -----`:
#
#   HALF 1 (premature verdict demand): "Give the explicit verdict 'approved for review-signoff' to
#   authorize this exact crossing" — demanded while `before-implement` was the last authorized
#   boundary, i.e. with the review-signoff stage carrying no evidence.
#
#   HALF 2 (contradictory composition): the same message said "emit the verdict marker as the LAST
#   line: <!-- SPECREW-VERDICT-BOUNDARY ... -->" AND, past the separator, "do NOT emit a
#   SPECREW-VERDICT-BOUNDARY marker."
#
# The two halves are certified differently in iteration 011, deliberately:
#
#   * HALF 1 is a RED-FIRST GATE. It asserts the CORRECT behaviour and is expected to FAIL against
#     HEAD until T090 lands the artifact-gated demand. A fixture that passes before the fix proves
#     nothing (the iteration-010 lesson).
#
#   * HALF 2 is a CHARACTERIZATION RECORD, not a gate. SC-025's composition clause is scoped to the
#     beta3 hook-machinery cluster by the maintainer's authorized specify touch, so no fix lands
#     here. It therefore asserts what the dispatcher does TODAY, so beta3 inherits a proven
#     reproduction rather than a description — and so that when beta3 resolves composition, THIS
#     TEST FAILS LOUDLY and forces the update. That inversion is intended; see the banner it prints.
#
# Run standalone:
#   pwsh -NoProfile -File tests/integration/fr068-verdict-demand-reproduction.tests.ps1

$script:Failures = 0
function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Red { param([string]$m) Write-Host "RED (expected until T090): $m" -ForegroundColor Yellow; $script:Failures++ }
function Write-Measured { param([string]$m) Write-Host "MEASURED: $m" -ForegroundColor Cyan }
function Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; $script:Failures++ }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$provider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
$dispatcher = (Resolve-Path "$repoRoot/scripts/internal/specrew-hook-dispatcher.ps1").Path
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("fr068-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch -Force | Out-Null

# ---------------------------------------------------------------------------------------------
# HALF 1 — a verdict demand emitted for a stage that produced no evidence.
# ---------------------------------------------------------------------------------------------

function New-EvidencelessBoundaryFixture {
    # Reproduces the observed crossing exactly: before-implement -> review-signoff, with the
    # review-signoff stage carrying NONE of its required artifacts. The iteration directory holds
    # a plan (so the feature resolves) and deliberately no review.md / reviewer-index.md / etc.
    $proj = Join-Path $scratch ([guid]::NewGuid().ToString('N'))
    $featureDir = Join-Path $proj 'specs\050-host-neutral-gate'
    $iterDir = Join-Path $featureDir 'iterations\001'
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path $iterDir -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $featureDir 'spec.md') `
        -Value "# Feature Specification: Host-Neutral Gate Enforcement`n`nThe authoritative contract for the active feature." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iterDir 'plan.md') `
        -Value "# Iteration Plan: 001`n`n**Status**: implementing`n`n## Tasks`n`n| Task | Title |`n| --- | --- |`n| T001 | do the thing |" -Encoding UTF8

    $ctx = [ordered]@{
        schema               = 'v2'
        feature_path         = $featureDir
        session_state        = [ordered]@{
            active = $true; boundary_type = 'review-signoff'
            feature_ref = '050-host-neutral-gate'; iteration_number = '001'
            recorded_at = '2026-06-20T00:00:00Z'
        }
        boundary_enforcement = [ordered]@{
            enabled = $true; last_authorized_boundary = 'before-implement'
            pending_next_boundary = $null; verdict_history = @(); bypass_history = @()
        }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'),
        ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))

    $null = & git -C $proj init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'fixture git init failed' }
    $null = & git -C $proj config core.autocrlf false
    $null = & git -C $proj add -A
    $null = & git -C $proj -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m 'fixture baseline'
    if ($LASTEXITCODE -ne 0) { throw 'fixture baseline commit failed' }
    return $proj
}

function New-FixtureTranscript {
    # The provider cannot assess a turn it cannot see: with no transcript it stays silent, and a
    # silent provider is NOT evidence that the demand was correctly withheld. The first revision of
    # this harness omitted the transcript and scored that silence as a pass — the same false-green
    # shape that produced DRIFT-198-I009-042. The transcript is therefore part of the fixture, and
    # the scoring below treats "no block at all" as INCONCLUSIVE rather than as success.
    param([string]$Proj)
    $dir = Join-Path $Proj '.specrew\runtime'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $path = Join-Path $dir ('transcript-' + [guid]::NewGuid().ToString('N') + '.jsonl')
    $turns = @(
        @{ role = 'user'; text = 'Continue the iteration.' },
        @{ role = 'assistant'; text = 'I implemented the change and ran the tests. Here is where things stand.' }
    )
    $lines = foreach ($t in $turns) {
        ([pscustomobject]@{
                type    = $t.role
                message = [pscustomobject]@{ content = @([pscustomobject]@{ type = 'text'; text = $t.text }) }
            } | ConvertTo-Json -Depth 8 -Compress)
    }
    [System.IO.File]::WriteAllLines($path, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
    return $path
}

Write-Host "`n--- HALF 1: verdict demand against a stage with no evidence ---`n" -ForegroundColor White

$proj = New-EvidencelessBoundaryFixture
$reviewArtifacts = @('review.md', 'reviewer-index.md', 'code-map.md', 'coverage-evidence.md')
$present = @($reviewArtifacts | Where-Object { Test-Path -LiteralPath (Join-Path $proj "specs\050-host-neutral-gate\iterations\001\$_") })
Write-Measured ("review-signoff stage artifacts present in the fixture: {0} of {1} ({2})" -f $present.Count, $reviewArtifacts.Count, $(if ($present.Count -eq 0) { 'none — the stage produced nothing' } else { $present -join ', ' }))

$transcript = New-FixtureTranscript -Proj $proj
$cmd = "Set-Location -LiteralPath '$proj'; & '$provider' --host-kind claude --source-event Stop --transcript-path '$transcript'"
$out = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1) -join "`n")

# Detect the BEHAVIOUR, not one surface form. `Get-SpecrewPendingVerdictState` has two branches and
# they word the demand differently: the SCOPED branch produces the verbatim transcript phrase, the
# LEGACY-UNSCOPED branch produces a marker/packet demand for the pending crossing. Both are a verdict
# demand. The first revision of this assertion matched only the scoped phrase and scored the
# unscoped demand as "no demand" — asserting a surface form rather than measuring the behaviour, the
# same mistake in a second costume. Which branch fired is recorded, because T090 must cover both.
$demandScoped = $out -match "Give the explicit verdict 'approved for"
$demandUnscoped = ($out -match 'verdict marker for the pending boundary crossing') -or ($out -match 'boundary state is pending')
$demanded = $demandScoped -or $demandUnscoped
$branch = if ($demandScoped) { 'scoped (the observed transcript form)' } elseif ($demandUnscoped) { 'legacy-unscoped' } else { 'none' }
$blocked = $out -match '<<<SPECREW-STOP-BLOCK>>>'
Write-Measured ("provider emitted a stop-block: {0}; emitted a verdict demand: {1}; branch: {2}" -f $blocked, $demanded, $branch)
$flat = ($out -replace '\s+', ' ').Trim()
Write-Measured ("block text (first 300 chars): {0}" -f $(if ($flat.Length -eq 0) { '(empty)' } else { $flat.Substring(0, [Math]::Min(300, $flat.Length)) }))

# THREE outcomes, not two. Silence is not success.
if (-not $blocked) {
    Fail 'INCONCLUSIVE — the provider emitted no stop-block at all, so the demand path was never reached. This is a FIXTURE defect, not evidence that FR-068 half 1 is satisfied. Do not read it as a pass'
    Write-Measured ("provider output was: {0}" -f $(if ([string]::IsNullOrWhiteSpace($out)) { '(empty)' } else { ($out -replace '\s+', ' ').Substring(0, [Math]::Min(240, ($out -replace '\s+', ' ').Length)) }))
}
elseif ($demanded) {
    Write-Red 'the provider demands a verdict for review-signoff while the stage has produced NO artifacts — FR-068 half 1 REPRODUCED'
    Write-Red 'the demand names no missing artifact — a corrected surface must name what the stage owes'
}
else {
    Write-Pass 'the provider blocks and communicates WITHOUT demanding a verdict for an evidence-less stage (FR-068 half 1 satisfied)'
}

Remove-Item -LiteralPath $proj -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------------------------
# HALF 2 — two providers, one message, contradictory instructions about the SAME marker.
# ---------------------------------------------------------------------------------------------

Write-Host "`n--- HALF 2: contradictory composition (characterization; beta3 flips this) ---`n" -ForegroundColor White

function Invoke-DispatcherContradiction {
    # The real co-occurring pair from the transcript: conformance (order 40) instructs the agent to
    # EMIT the verdict marker; the co-review navigator (order 50) instructs it NOT to. Both are
    # verbatim-shaped after the observed message.
    $p = Join-Path $scratch ([guid]::NewGuid().ToString('N'))
    $scriptsDir = Join-Path $p '.specify/extensions/specrew-speckit/scripts'
    New-Item -ItemType Directory -Path (Join-Path $p '.specrew/runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

    $rows = @(
        @{ id = 'conformance'; kind = 'inject'; events = @('Stop'); order = 40; budget_share = 1.0; command = 'conf-stub.ps1' },
        @{ id = 'co-review-navigator'; kind = 'inject'; events = @('Stop'); order = 50; budget_share = 1.0; command = 'nav-stub.ps1' }
    )
    Set-Content -LiteralPath (Join-Path $p '.specify/extensions/specrew-speckit/refocus-scopes.json') `
        -Value (@{ schema_version = '1'; providers = @($rows) } | ConvertTo-Json -Depth 6) -Encoding UTF8

    Set-Content -LiteralPath (Join-Path $scriptsDir 'conf-stub.ps1') -Encoding UTF8 -Value @'
Write-Output "<<<SPECREW-STOP-BLOCK>>>`nThis is a BOUNDARY stop (before-implement -> review-signoff); emit the verdict marker as the LAST line: <!-- SPECREW-VERDICT-BOUNDARY: before-implement -> review-signoff -->"
exit 0
'@
    Set-Content -LiteralPath (Join-Path $scriptsDir 'nav-stub.ps1') -Encoding UTF8 -Value @'
Write-Output "<<<SPECREW-STOP-BLOCK>>>`nSpecrew campaign review - review-required.`n(Campaign review block, not a lifecycle verdict - do NOT emit a SPECREW-VERDICT-BOUNDARY marker.)"
exit 0
'@

    $eventFile = Join-Path $p 'event.json'
    Set-Content -LiteralPath $eventFile -Value (@{ session_id = 'fr068'; source = 'Stop' } | ConvertTo-Json -Compress) -Encoding UTF8 -NoNewline
    $outFile = Join-Path $p 'd.out'; $errFile = Join-Path $p 'd.err'
    $proc = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', 'Stop', '-HostKind', 'claude') `
        -WorkingDirectory $p -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput $eventFile -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $result = [pscustomobject]@{
        ExitCode = $proc.ExitCode
        Out      = (Get-Content -LiteralPath $outFile -Raw -ErrorAction SilentlyContinue)
    }
    Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
    return $result
}

$r = Invoke-DispatcherContradiction
$emitDirective = $r.Out -match 'emit the verdict marker as the LAST line'
$forbidDirective = $r.Out -match 'do NOT emit a SPECREW-VERDICT-BOUNDARY marker'
$separator = $r.Out -match 'AND ALSO'

Write-Measured ("dispatcher exit={0}; emit-directive present={1}; forbid-directive present={2}; separator present={3}" -f $r.ExitCode, $emitDirective, $forbidDirective, $separator)

if ($emitDirective -and $forbidDirective) {
    Write-Pass 'CHARACTERIZED: one delivered message carries BOTH "emit the marker" and "do NOT emit the marker" — FR-068 half 2 reproduced exactly'
    if ($separator) {
        Write-Pass 'CHARACTERIZED: the two directives are joined by the AND-ALSO separator — concatenation, with no precedence and no conflict detection'
    }
}
else {
    Fail 'half 2 did NOT reproduce — the dispatcher no longer emits both directives; if composition was fixed, update this characterization and SC-025'
}

Write-Host @"

  NOTE: half 2's assertions pin TODAY's defective behaviour on purpose. SC-025's composition
  clause is scoped to the beta3 hook-machinery cluster, so no fix lands in iteration 011. When
  beta3 resolves composition, these two assertions MUST fail — that failure is the signal to
  update them alongside the fix, not a regression.
"@ -ForegroundColor DarkGray

# ---------------------------------------------------------------------------------------------
# HALF 3 — the clarify row's matcher must enforce the contract it was authored from.
#
# DRIFT-198-I011-006 (certification finding 4). The contract requires "a dated Clarifications session
# block OR a recorded skip-with-rationale". The shipped matcher accepted `##\s+Clarifications` (any
# heading, including an empty placeholder) and `clarif\w*[^.\r\n]{0,40}\bskip` — a loose regex that
# NEGATED PROSE satisfies. The reviewer's proof: the sentence "Clarifications must not be skipped"
# marks the stage satisfied and re-enables the approval options this whole requirement exists to
# withhold.
#
# Maintainer ruling: take the STRICT rule. Over-blocking is visible and correctable; under-blocking
# silently re-enables approval options, which is the defect class this iteration exists to kill.
#
# Measured by calling the REAL gate against REAL committed trees — four shapes, both directions, so
# the strictness is proven to block the bad AND still admit the two legitimate arms. A one-directional
# test would prove only that the matcher got stricter, not that it stayed correct.
# ---------------------------------------------------------------------------------------------

Write-Host "`n--- HALF 3: the clarify matcher enforces the authored contract ---`n" -ForegroundColor White

function Test-ClarifyShape {
    param([string]$Label, [string]$SpecBody, [bool]$ExpectSatisfied, [string]$Why)

    $proj = Join-Path $scratch ([guid]::NewGuid().ToString('N'))
    $featureDir = Join-Path $proj 'specs\050-host-neutral-gate'
    New-Item -ItemType Directory -Path $featureDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $featureDir 'spec.md') -Value $SpecBody -Encoding UTF8
    $null = & git -C $proj init --quiet
    $null = & git -C $proj config core.autocrlf false
    $null = & git -C $proj add -A
    $null = & git -C $proj -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m 'clarify shape'
    if ($LASTEXITCODE -ne 0) { Fail "fixture commit failed for shape '$Label'"; return }
    $tree = (@(& git -C $proj rev-parse 'HEAD^{tree}') -join '').Trim()

    # Child process: shared-governance sets StrictMode at file scope, and the gate must be exercised
    # through its real entry point rather than a re-implementation of the regex here.
    $probe = Join-Path $scratch ('clarify-' + [guid]::NewGuid().ToString('N') + '.ps1')
    $body = @"
`$ErrorActionPreference = 'Stop'
. '$repoRoot/extensions/specrew-speckit/scripts/shared-governance.ps1'
`$ev = Get-SpecrewBoundaryStageEvidence -ProjectRoot '$proj' -Boundary 'clarify' ``
    -FeaturePath '$featureDir' -IterationNumber '001' -ArtifactStateId '$tree'
[pscustomobject]@{ satisfied = [bool]`$ev.Satisfied; checked = [bool]`$ev.Checked; unverifiable = [bool]`$ev.Unverifiable } | ConvertTo-Json -Compress
"@
    [System.IO.File]::WriteAllText($probe, $body, [System.Text.UTF8Encoding]::new($false))
    $out = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $probe 2>&1) -join "`n")
    $res = $null
    $m = [regex]::Match($out, '(?s)\{.*"satisfied".*\}')
    if ($m.Success) { try { $res = $m.Value | ConvertFrom-Json } catch { $res = $null } }

    if ($null -eq $res) {
        Fail ("shape '{0}': the gate produced no parseable result — measures nothing. Output: {1}" -f $Label, (($out -replace '\s+', ' ').Trim()))
        return
    }
    Write-Measured ("shape '{0}': satisfied={1}; checked={2}; unverifiable={3}" -f $Label, $res.satisfied, $res.checked, $res.unverifiable)

    if ([bool]$res.satisfied -eq $ExpectSatisfied) {
        Write-Pass ("{0} -> satisfied={1} ({2})" -f $Label, $ExpectSatisfied, $Why)
    }
    elseif ($ExpectSatisfied) {
        Write-Red ("OVER-BLOCKS: {0} is a legitimate clarify arm but the gate refuses it ({1})" -f $Label, $Why)
    }
    else {
        Write-Red ("UNDER-BLOCKS: {0} satisfies the clarify gate but must not ({1})" -f $Label, $Why)
    }
}

# The reviewer's exact proof string. Negated prose that ASSERTS clarify may not be skipped was
# scored as evidence that it WAS legitimately skipped.
Test-ClarifyShape -Label 'negated prose ("must not be skipped")' -ExpectSatisfied $false `
    -Why 'a sentence forbidding a skip is not a record of one' `
    -SpecBody @"
# Feature Specification: Host-Neutral Gate Enforcement

## Process Notes

Clarifications must not be skipped on a feature of this size.
"@

Test-ClarifyShape -Label 'placeholder heading, empty section' -ExpectSatisfied $false `
    -Why 'an empty section records no session and no skip' `
    -SpecBody @"
# Feature Specification: Host-Neutral Gate Enforcement

## Clarifications

## Requirements
"@

Test-ClarifyShape -Label 'dated session block (arm 1)' -ExpectSatisfied $true `
    -Why 'the lived shape: a dated session under the Clarifications heading' `
    -SpecBody @"
# Feature Specification: Host-Neutral Gate Enforcement

## Clarifications

### Session 2026-08-06 (clarify)

- Q: Which host owns the reap? -> A (human): the watchdog.
"@

Test-ClarifyShape -Label 'structured skip-with-rationale (arm 2)' -ExpectSatisfied $true `
    -Why 'the skip arm is load-bearing: a workshop that resolved everything must not be forced into ceremony' `
    -SpecBody @"
# Feature Specification: Host-Neutral Gate Enforcement

## Clarifications

- **Clarify Disposition**: skip with recorded rationale - the 7-lens intake workshop resolved every open design question interactively; zero NEEDS CLARIFICATION markers remain.
"@

Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
if ($script:Failures -gt 0) {
    Write-Host "=== T086 reproduction: $($script:Failures) RED assertion(s) — expected until T090 lands ===" -ForegroundColor Yellow
    exit 1
}
Write-Host '=== T086 reproduction: all assertions green ===' -ForegroundColor Green
exit 0
