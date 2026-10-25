[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [string]$Feature,
    [string]$Iteration,
    [switch]$Json,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

# `specrew reseal` - RE-SEAL A CLOSED ITERATION THE PRODUCT'S OWN MACHINERY MOVED.
#
# The trust-hardening gate refuses a closed iteration whose records changed after its closeout seal, and
# until now it named no remedy: sealed meant immutable, so the condition was treated as impossible. It was
# not impossible - three of the product's own writers fired after the seal (B4F-063): the closeout
# verdict's advance, a closeout re-render, and a session resume's task-progress sync. The rule now is that
# an authorized writer re-seals after its write and an unauthorized writer skips a sealed iteration, so the
# gate should rarely fire for the product's own edits again. Projects sealed BEFORE the rule - every
# consumer that closed an iteration on beta3 - carry the drift already, and this verb is how a human clears
# it: it prints what drifted (the precondition), re-seals over what is on disk, and proves nothing is
# touched afterwards (the postcondition).
#
# WHAT IT REFUSES, by name: an iteration that has no seal (this re-seals; closeout seals for the first
# time), and an iteration that is not closed (the seal file is the closed marker when the index has no
# entry). It never decides whether the drift was legitimate - that is the human's reading of the journal
# and the diff; this verb only makes the seal describe what the human has decided to keep.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-ResealHelp {
    Write-Host @'
Usage: specrew reseal --feature <feature> --iteration <NNN> [--project-path <path>] [--json]

Re-seal a CLOSED iteration whose records were moved after its closeout seal - by the product's own
closeout machinery, or by a human who has decided to keep an edit. Prints the precondition (which sealed
paths drifted, went missing, or were added), rewrites the seal over what is on disk, and prints the
postcondition (the integrity check after: nothing touched).

  --feature <feature>     The feature directory name under specs/ (e.g. 001-layout-autocorrect)
  --iteration <NNN>       The iteration number (e.g. 002)
  --project-path <path>   Project root (default: current directory)
  --json                  Emit the precondition and postcondition as JSON

Refuses an iteration that has no seal (closeout seals for the first time), and one that is not closed.
Read .specrew/runtime/handover-journal.jsonl first: its sealed-iteration-resealed and
sealed-iteration-write-skipped rows say which writer moved the records.
'@
}

# --- argument normalisation: the front door passes CLI-style args through -CliArgs ------------------
$argumentList = @($CliArgs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
for ($index = 0; $index -lt $argumentList.Count; $index++) {
    $argument = [string]$argumentList[$index]
    $next = if (($index + 1) -lt $argumentList.Count) { [string]$argumentList[$index + 1] } else { $null }
    switch -Regex ($argument) {
        '^--help$|^-h$' { $Help = $true }
        '^--json$' { $Json = $true }
        '^--feature=(.+)$' { $Feature = $Matches[1] }
        '^--feature$' { if ($null -ne $next) { $Feature = $next; $index++ } }
        '^--iteration=(.+)$' { $Iteration = $Matches[1] }
        '^--iteration$' { if ($null -ne $next) { $Iteration = $next; $index++ } }
        '^--project-path=(.+)$' { $ProjectPath = $Matches[1] }
        '^--project-path$' { if ($null -ne $next) { $ProjectPath = $next; $index++ } }
        default { Write-Host ("ERROR: Unsupported argument '{0}' for specrew reseal." -f $argument) -ForegroundColor Red; Show-ResealHelp; exit 2 }
    }
}
if ($Help) { Show-ResealHelp; exit 0 }

$sharedGovernancePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    Write-Host ("ERROR: shared-governance.ps1 not found at {0}" -f $sharedGovernancePath) -ForegroundColor Red
    exit 1
}
. $sharedGovernancePath
# Every timestamp read goes through the one reader (PRED-BETA4-014's helper): `sealed_at` comes back from
# ConvertFrom-Json as a [datetime], and printing that raw gives the machine's culture and zone, not the seal's.
$timestampReadPath = Join-Path (Split-Path -Parent $sharedGovernancePath) 'timestamp-read.ps1'
if (-not (Get-Command -Name 'ConvertTo-SpecrewUtcTimestamp' -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $timestampReadPath -PathType Leaf)) { . $timestampReadPath }

$resolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectPath -ErrorAction Stop).Path
if ([string]::IsNullOrWhiteSpace($Feature) -or [string]::IsNullOrWhiteSpace($Iteration)) {
    Write-Host 'ERROR: specrew reseal needs both --feature <feature> and --iteration <NNN>: it re-seals ONE closed iteration, named, never every iteration it can find.' -ForegroundColor Red
    exit 2
}
$normalizedIteration = try { Normalize-SpecrewIterationNumber -IterationNumber $Iteration } catch { $Iteration }
$iterationDirectory = Join-Path (Join-Path (Join-Path $resolvedProjectRoot 'specs') $Feature) (Join-Path 'iterations' $normalizedIteration)
$relativeIteration = ('specs/{0}/iterations/{1}' -f $Feature, $normalizedIteration)

if (-not (Test-Path -LiteralPath $iterationDirectory -PathType Container)) {
    Write-Host ("ERROR: no iteration directory at {0} (looked under {1})." -f $relativeIteration, $resolvedProjectRoot) -ForegroundColor Red
    exit 2
}

# --- preconditions: sealed, and closed --------------------------------------------------------------
if (-not (Test-SpecrewIterationSealed -IterationDirectory $iterationDirectory)) {
    Write-Host ("ERROR: {0} has no closeout seal, so there is nothing to re-seal. A seal is written for the first time by the iteration-closeout sync; this verb only rewrites one that exists." -f $relativeIteration) -ForegroundColor Red
    exit 2
}
$closedInIndex = $false
try { $closedInIndex = [bool](Test-SpecrewIterationClosed -ProjectRoot $resolvedProjectRoot -Feature $Feature -Iteration $normalizedIteration) } catch { $closedInIndex = $false }
$closedInState = $false
try {
    $statePath = Join-Path $iterationDirectory 'state.md'
    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $closedInState = ($null -ne (Get-SpecrewClosedIterationFromStateFile -StatePath $statePath))
    }
}
catch { $closedInState = $false }
if (-not $closedInIndex -and -not $closedInState) {
    Write-Host ("ERROR: {0} is not recorded as closed - not in .specrew/closed-iterations.yml and its state.md does not read as closed - so its seal is not a closeout seal to re-seal. Close the iteration through its boundary sync first." -f $relativeIteration) -ForegroundColor Red
    exit 2
}

$before = Test-SpecrewIterationSealIntegrity -IterationDirectory $iterationDirectory
$touchedBefore = @(@($before.drifted) + @($before.missing) + @($before.added))
$sealBefore = $null
try { $sealBefore = Get-Content -LiteralPath (Get-SpecrewIterationSealPath -IterationDirectory $iterationDirectory) -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $sealBefore = $null }
$sourceBefore = if ($null -ne $sealBefore -and $sealBefore.PSObject.Properties['source']) { [string]$sealBefore.source } else { '' }
$sealedAtBefore = ''
if ($null -ne $sealBefore -and $sealBefore.PSObject.Properties['sealed_at']) {
    $sealedAtParsed = if (Get-Command -Name 'ConvertTo-SpecrewUtcTimestamp' -ErrorAction SilentlyContinue) { ConvertTo-SpecrewUtcTimestamp -Value $sealBefore.sealed_at } else { $null }
    $sealedAtBefore = if ($null -ne $sealedAtParsed) { ([DateTimeOffset]$sealedAtParsed).ToString('yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture) + ' UTC' } else { [string]$sealBefore.sealed_at }
}

if (-not $Json) {
    Write-Host ("[reseal] precondition {0}: sealed {1} by '{2}'; drifted={3} missing={4} added={5}" -f $relativeIteration, $sealedAtBefore, $sourceBefore, (@($before.drifted) -join ','), (@($before.missing) -join ','), (@($before.added) -join ','))
    if ($touchedBefore.Count -eq 0) { Write-Host '[reseal] nothing has moved since the seal; re-sealing anyway records the current state and the source of this re-seal.' }
}

# --- the write, through the one seal writer, with the source naming this verb ----------------------
$sealPath = Write-SpecrewIterationSeal -IterationDirectory $iterationDirectory -Feature $Feature -Iteration $normalizedIteration -Source 'specrew-reseal'
if ([string]::IsNullOrWhiteSpace([string]$sealPath)) {
    Write-Host ("ERROR: the seal for {0} could not be written." -f $relativeIteration) -ForegroundColor Red
    exit 1
}
if (Get-Command -Name 'Add-SpecrewSealJournalEvent' -ErrorAction SilentlyContinue) {
    Add-SpecrewSealJournalEvent -ProjectRoot $resolvedProjectRoot -Event 'sealed-iteration-resealed' -Writer 'specrew-reseal' -IterationDirectory $iterationDirectory -Detail ('re-sealed by a human; before: drifted={0} missing={1} added={2}' -f (@($before.drifted) -join ','), (@($before.missing) -join ','), (@($before.added) -join ','))
}

# --- postcondition: the seal now describes what is on disk ----------------------------------------
$after = Test-SpecrewIterationSealIntegrity -IterationDirectory $iterationDirectory
$touchedAfter = @(@($after.drifted) + @($after.missing) + @($after.added))

if ($Json) {
    [pscustomobject][ordered]@{
        iteration = $relativeIteration
        seal_path = [string]$sealPath
        before    = [ordered]@{ sealed_at = $sealedAtBefore; source = $sourceBefore; drifted = @($before.drifted); missing = @($before.missing); added = @($before.added) }
        after     = [ordered]@{ touched = $touchedAfter.Count; drifted = @($after.drifted); missing = @($after.missing); added = @($after.added) }
    } | ConvertTo-Json -Depth 6
}
else {
    Write-Host ("[reseal] postcondition {0}: touched={1}" -f $relativeIteration, $touchedAfter.Count)
    if ($touchedAfter.Count -eq 0) { Write-Host ("[reseal] re-sealed; the trust gate for {0} passes on the records as they are now." -f $relativeIteration) }
}
if ($touchedAfter.Count -ne 0) {
    Write-Host ("ERROR: the postcondition failed - {0} path(s) still differ from the seal just written: {1}." -f $touchedAfter.Count, ($touchedAfter -join ', ')) -ForegroundColor Red
    exit 1
}
exit 0
