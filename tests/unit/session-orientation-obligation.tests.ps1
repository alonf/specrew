[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# W23 (2026-08-18 manual walk, C:\Dev\casiocalculator): a fresh Claude session received the full
# orientation - SessionStart fired in `full` mode, the payload is recorded in hook-output-authority,
# and the fire won its render claim - and the human never saw it. The agent read the state files,
# said "I'll read the project's Specrew state files first, then get oriented", and went straight to
# scaffolding and the workshop. Orientation performed on itself instead of for the human.
#
# The codebase had already measured this class once: "the iter-6 directive told the agent to READ
# last-start-prompt.md BEFORE acting; the side-by-side disproof showed the agent never read it - a file
# is a skip the agent self-orients past." The remedy then was to inline the contract, which claude does
# not get (its hook-output cap drops the ~45KB body, so claude runs the pointer branch).
#
# NOTHING MECHANICAL CATCHES A MISSING BANNER. `hook-bootstrap-render-*.json` is a DELIVERY claim - an
# atomic single-winner election so two concurrent fires do not render twice - not evidence the human saw
# anything, and the Stop lane has no banner check. A Stop-side check was considered and deferred by
# maintainer ruling: it would run on every stop to catch a first-turn omission, and adding a block class
# at release time is the wrong trade.
#
# So the obligation is carried by the two channels that are always in context: the session directive and
# the host-materialized project instructions. This guard pins both, because an obligation that lives in
# one host's file is not an obligation of the project.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

# --- 1. The always-loaded project instructions (the template every host surface is cut from) ---
$template = Join-Path $repoRoot 'templates\coordinator-instructions.md'
Assert-True (Test-Path -LiteralPath $template -PathType Leaf) 'the coordinator instructions template exists'
# These files are hard-wrapped prose, so a sentence spans lines. Match on whitespace-normalized text:
# pinning a phrase to one physical line would make the guard fail on a reflow that changed nothing.
function ConvertTo-FlowedText {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    return (($Text -replace '\s+', ' ').Trim())
}
$templateText = ConvertTo-FlowedText -Text (Get-Content -LiteralPath $template -Raw -Encoding UTF8)

$obligations = @(
    @{ Name = 'a session opens by orienting the human'; Pattern = '(?i)session opens by orienting the human' }
    @{ Name = 'the orientation is rendered as visible prose'; Pattern = '(?i)visible prose' }
    @{ Name = 'what the crew believes about the human is shown to them'; Pattern = '(?i)user-profile expertise dials' }
    @{ Name = 'reading it is distinguished from rendering it'; Pattern = '(?i)reading it to orient yourself is not rendering it' }
    @{ Name = 'a concrete first request does not replace the orientation'; Pattern = '(?i)does not replace the orientation' }
)
foreach ($o in $obligations) {
    Assert-True ($templateText -match $o.Pattern) ("the project instructions state that {0}" -f $o.Name)
}

# The orientation obligation must come BEFORE the workshop instruction: an agent reading top-down meets
# "open by orienting" before it meets "new features start with the design workshop", which is the exact
# instruction the walk jumped to.
$orientIndex = $templateText.IndexOf('A session opens by orienting the human')
$workshopIndex = $templateText.IndexOf('New features start with the design workshop')
Assert-True ($orientIndex -gt 0 -and $workshopIndex -gt $orientIndex) 'the orientation obligation is stated before the workshop instruction, in reading order'

# --- 2. Every host-materialized surface carries it, not just the one host that was walked ---
$hostSurfaces = @('CLAUDE.md', 'AGENTS.md', '.github\copilot-instructions.md') |
    ForEach-Object { Join-Path $repoRoot $_ } |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
Assert-True (@($hostSurfaces).Count -ge 1) 'at least one host instruction surface is materialized in this project to check'
foreach ($surface in $hostSurfaces) {
    $surfaceText = ConvertTo-FlowedText -Text (Get-Content -LiteralPath $surface -Raw -Encoding UTF8)
    Assert-True ($surfaceText -match '(?i)session opens by orienting the human') ("{0} carries the orientation obligation" -f (Split-Path $surface -Leaf))
    Assert-True ($surfaceText -match '(?i)user-profile expertise dials') ("{0} requires showing the human what is believed about them" -f (Split-Path $surface -Leaf))
}

# --- 3. The session directive itself says the orientation is for the human, in all three copies ---
$providers = @(
    'scripts\internal\specrew-bootstrap-provider.ps1'
    'extensions\specrew-speckit\scripts\specrew-bootstrap-provider.ps1'
    '.specify\extensions\specrew-speckit\scripts\specrew-bootstrap-provider.ps1'
) | ForEach-Object { Join-Path $repoRoot $_ }
foreach ($provider in $providers) {
    Assert-True (Test-Path -LiteralPath $provider -PathType Leaf) ("bootstrap provider copy exists: {0}" -f (Split-Path (Split-Path $provider -Parent) -Leaf))
    $providerText = Get-Content -LiteralPath $provider -Raw -Encoding UTF8
    Assert-True ($providerText -match '(?i)SHOWN to the human, not merely read by you') 'the session directive states the orientation is for the human, not context for the agent'
    Assert-True ($providerText -match '(?i)reading it to orient yourself is not rendering it') 'the session directive names the exact failure the walk produced'
    Assert-True ($providerText -match '(?i)concrete request in their first message does not replace it') 'the session directive closes the "they asked for something concrete" shortcut'
}

# --- 4. The ids in that directive stay glossed (FR-016 does not regress through this edit) ---
. (Join-Path $repoRoot 'scripts\internal\specrew-consumer-language.ps1')
$directiveLine = @(Get-Content -LiteralPath $providers[0] -Encoding UTF8 | Where-Object { $_ -match 'SHOWN to the human, not merely read by you' })
Assert-True (@($directiveLine).Count -eq 1) 'the sharpened directive is a single emitted line'
Assert-True (@(Get-SpecrewUnglossedId -Text $directiveLine[0]).Count -eq 0) 'the sharpened directive still glosses every requirement id it cites'

Write-Host 'session orientation obligation: all assertions pass' -ForegroundColor Green
