#requires -Version 7.0
# Feature 202 T013 (FR-020; widened by DRIFT-002): the design-analysis gate's refusal names the step that produces the
# artifact and lists every gap in ONE pass.
#
# RED (202's own intake, three refusals): a missing file was named without its producer, and the format was disclosed
# one layer per refusal - the sections first; each option's fields only once an Alternatives section existed; the
# decision's labels only once a Human Decision section existed.
#
# The acceptance is one refusal that carries the producer and every requirement the validator checks, so a crew that
# fixes exactly what the refusal lists is not refused again for something it was not told.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\design-analysis-gate.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

# Everything Test-SpecrewDesignAnalysisArtifact checks, by the words a refusal must use for it.
$requirements = [ordered]@{
    'the Problem Framing section'          = 'Problem Framing'
    'the decision points section'          = 'Key Design Decision Points'
    'the Alternatives section'             = 'Alternatives'
    'the Simplest option'                  = 'Simplest'
    'the Reasonable option'                = 'Reasonable'
    'By-the-book or why not distinct'      = 'By-the-book'
    'option field Approach'                = 'Approach'
    'option field Architectural pattern'   = 'Architectural pattern'
    'option field Quality features'        = 'Quality features considered'
    'option field Effort estimate'         = 'Effort estimate'
    'option field Reversibility cost'      = 'Reversibility cost'
    'option field Trade-offs'              = 'Trade-offs'
    'an option diagram'                    = 'Mermaid diagram'
    'the Crew Recommendation section'      = 'Crew Recommendation'
    'exactly one recommended option'       = 'exactly one recommended option'
    'the Human Decision section'           = 'Human Decision'
    'the verdict or Chosen Option field'   = 'Chosen Option'
    'the human reason or instructions'     = 'reason'
    'the decision commit hash'             = 'commit hash'
}

function New-GateProject {
    param([AllowNull()][object]$Artifact)   # [object]: a [string] parameter would turn $null into '' and write an empty file
    $root = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('dag-' + [guid]::NewGuid().ToString('N').Substring(0, 8))))
    $iter = Join-Path $root 'specs/001-feat/iterations/001'
    New-Item -ItemType Directory -Force -Path $iter | Out-Null
    if ($null -ne $Artifact) { [IO.File]::WriteAllText((Join-Path $iter 'design-analysis.md'), [string]$Artifact, [Text.UTF8Encoding]::new($false)) }
    return $root
}

function Get-Refusal {
    # The plan-boundary refusal as the crew sees it: the gate's message text.
    param([string]$Root)
    $r = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $Root -FeatureRef '001-feat' -IterationNumber '001'
    return [pscustomobject]@{ Valid = $r.Valid; Text = (@($r.Errors) -join "`n") }
}

$roots = [Collections.Generic.List[string]]::new()
try {
    Write-Host 'Case 1: the artifact does not exist'
    $r1 = New-GateProject -Artifact $null; $roots.Add($r1)
    $x1 = Get-Refusal $r1
    Assert-True (-not $x1.Valid) 'refused'
    Assert-True ($x1.Text -match 'New-SpecrewDesignAnalysisArtifact' -and $x1.Text -match '(?i)design workshop') 'the refusal names the step that produces the artifact'
    foreach ($k in $requirements.Keys) { Assert-True ($x1.Text.Contains($requirements[$k])) ("the one refusal already lists {0}" -f $k) }

    Write-Host 'Case 2: only the problem is written (the next layer used to need a second refusal)'
    $r2 = New-GateProject -Artifact "# Design Analysis`n`n## Problem Framing`n`nUsers lose context on resume.`n"; $roots.Add($r2)
    $x2 = Get-Refusal $r2
    foreach ($k in $requirements.Keys) {
        if ($k -eq 'the Problem Framing section') { continue }
        Assert-True ($x2.Text.Contains($requirements[$k])) ("with Alternatives and Human Decision absent, the refusal still lists {0}" -f $k)
    }

    Write-Host 'Case 2b: an empty artifact (scaffolded, never filled) is refused with the list, not a crash'
    $r2b = New-GateProject -Artifact ''; $roots.Add($r2b)
    $threw = $null
    try { $x2b = Get-Refusal $r2b } catch { $threw = $_.Exception.Message }
    Assert-True ($null -eq $threw) ("the check does not throw on an empty file ({0})" -f $threw)
    if ($null -eq $threw) { Assert-True ((-not $x2b.Valid) -and $x2b.Text.Contains('Problem Framing') -and $x2b.Text.Contains('commit hash')) 'it lists every requirement' }

    Write-Host 'Case 3: a crew that fixes exactly what case 2 listed passes'
    $full = @'
# Design Analysis

## Problem Framing

Users lose context on resume.

## Key Design Decision Points

- Where the position comes from.

## Alternatives

### Option A - Simplest

- Approach: read the ledger.
- Architectural pattern: accessor.
- Quality features considered: correctness.
- Effort estimate: 1 SP.
- Reversibility cost: low.
- Trade-offs: none worth noting.
- Diagram: docs/a.png

### Option B - Reasonable

- Approach: read the ledger and the task list.
- Architectural pattern: accessor plus engine.
- Quality features considered: correctness, clarity.
- Effort estimate: 2 SP.
- Reversibility cost: low.
- Trade-offs: one more read.
- Diagram: docs/b.png

By-the-book is not meaningfully distinct here.

## Crew Recommendation

Recommended: Option B

## Human Decision

- Chosen Option: Option B
- Reason: matches the ledger.
- Decision recorded in commit: abc1234
'@
    $r3 = New-GateProject -Artifact $full; $roots.Add($r3)
    $x3 = Get-Refusal $r3
    Assert-True ($x3.Valid) ("an artifact carrying exactly the listed items passes ({0})" -f $x3.Text)

    Write-Host 'Case 4: the plan-boundary gate message carries the producer too'
    $msg = $null
    try { $null = Invoke-SpecrewDesignAnalysisPlanBoundaryGate -ProjectRoot $r1 -FeatureRef '001-feat' -IterationNumber '001' } catch { $msg = $_.Exception.Message }
    if ($null -ne $msg) { Assert-True ($msg -match 'New-SpecrewDesignAnalysisArtifact') 'the thrown refusal names the producer' }
    else { Write-Host '  (gate not required for this fixture; the artifact-level refusal above is the contract)' }
}
finally {
    foreach ($r in $roots) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue }
}
if ($script:failCount -gt 0) { Write-Host "design-analysis-gate-refusal: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'design-analysis-gate-refusal: all passed' -ForegroundColor Green
