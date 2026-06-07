[CmdletBinding()]
param()

# Feature 165 regression test — the specrew-gate-stop skill is the deterministic fix for the Claude
# AskUserQuestion verdict-packet collapse (the picker folds the Rule 46 six-section packet into its
# short fields, so the human is asked to approve what they cannot read). Conduct could NOT hold it —
# six in-context amendments AND a runtime PreToolUse hook-deny were all gamed/skimmed. The non-gameable
# lever is removing the tool: this skill's frontmatter `disallowed-tools: AskUserQuestion` deletes the
# picker for the stop, so the model has no picker to collapse into and renders the packet as Markdown.
# This test locks that contract so it cannot silently regress.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$skillRel = 'extensions\specrew-speckit\squad-templates\skills\gate-stop.md'
$skillPath = Join-Path $repoRoot $skillRel
$mirrorPath = Join-Path $repoRoot (Join-Path '.specify' $skillRel)

if (-not (Test-Path -LiteralPath $skillPath -PathType Leaf)) {
    Write-Fail "gate-stop skill not found at $skillPath"
}
$content = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8

# 1. The enforcement field — this IS the fix; a conduct instruction alone is gameable.
if ($content -notmatch '(?m)^disallowed-tools:\s*AskUserQuestion\s*$') {
    Write-Fail "gate-stop frontmatter is missing 'disallowed-tools: AskUserQuestion' — without it the picker is not removed and the packet collapses again."
}

# 2. The full Rule 46 six-section re-entry packet.
$sections = @(
    '## What I Just Did',
    '## Why I Stopped',
    '## What Needs Your Review',
    '## What Happens Next',
    '## Discussion Prompts',
    '## What I Need From You'
)
$missing = @($sections | Where-Object { $content -notmatch [regex]::Escape($_) })
if ($missing.Count -gt 0) {
    Write-Fail ("gate-stop skill is missing Rule 46 section(s): {0}" -f ($missing -join ', '))
}

# 3. It must forbid the picker for the verdict and render the textual options instead.
if ($content -notmatch 'AskUserQuestion' -or $content -notmatch "What's your verdict\?") {
    Write-Fail "gate-stop skill must name AskUserQuestion (to forbid it for the verdict) and render the textual 'What's your verdict?' options."
}

# 4. Source <-> .specify self-host mirror parity (Proposal 132).
if (-not (Test-Path -LiteralPath $mirrorPath -PathType Leaf)) {
    Write-Fail "gate-stop skill .specify mirror not found at $mirrorPath (mirror parity)."
}
$mirror = Get-Content -LiteralPath $mirrorPath -Raw -Encoding UTF8
if ($mirror -ne $content) {
    Write-Fail "gate-stop skill source and .specify mirror have drifted — they must be identical (Proposal 132 mirror parity)."
}

Write-Pass "specrew-gate-stop: disallowed-tools enforcement, six-section packet, no-picker verdict, and .specify mirror parity all present"
Write-Host "`ngate-stop skill: all assertions pass" -ForegroundColor Green
