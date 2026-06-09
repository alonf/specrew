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

# 1b. Host scope — the skill is Claude-specific and must not deploy into non-Claude roots.
if ($content -notmatch '(?m)^host-scope:\s*claude\s*$') {
    Write-Fail "gate-stop frontmatter is missing 'host-scope: claude' — without it deploy-squad-runtime.ps1 publishes the Claude-only skill to non-Claude hosts."
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

# 5. Routing (static, cross-platform): the Claude host interaction guidance must route boundary verdict
#    stops through this skill. The runtime assertion lives in multi-host-launch-path.tests.ps1, which is
#    Windows-coupled (hardcoded C:\ launch paths) and runs locally; this static source check keeps the
#    routing covered on the Linux CI lane.
$surgeryPath = Join-Path $repoRoot (Join-Path 'scripts' (Join-Path 'internal' 'coordinator-prompt-surgery.ps1'))
if (-not (Test-Path -LiteralPath $surgeryPath -PathType Leaf)) {
    Write-Fail "coordinator-prompt-surgery.ps1 not found at $surgeryPath"
}
$surgery = Get-Content -LiteralPath $surgeryPath -Raw -Encoding UTF8
if ($surgery -notmatch 'specrew-gate-stop' -or $surgery -notmatch 'disallows the AskUserQuestion tool') {
    Write-Fail "coordinator-prompt-surgery.ps1 no longer routes Claude boundary verdict stops through specrew-gate-stop (the Claude interaction-guidance branch is missing the gate-stop routing)."
}

# 6. Runtime deployment: the Claude-only skill lands in .claude and managed stale copies are removed
#    from the other active host roots. This is the Issue #2083 regression guard.
$deployScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\gate-stop-host-scope-test'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
New-Item -ItemType Directory -Path (Join-Path $scratchRoot '.squad') -Force | Out-Null

$staleRoots = @(
    '.github\skills',
    '.agents\skills',
    '.cursor\rules'
)
foreach ($root in $staleRoots) {
    $staleSkillDir = Join-Path $scratchRoot (Join-Path $root 'specrew-gate-stop')
    New-Item -ItemType Directory -Path $staleSkillDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $staleSkillDir 'SKILL.md') -Value $content -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $staleSkillDir '.specrew-managed') -Value "schema: v1`nowner: specrew`nkind: project-skill`ndirectory: specrew-gate-stop" -Encoding UTF8
}

& $deployScript -ProjectPath $scratchRoot | Out-Null

$claudeSkill = Join-Path $scratchRoot '.claude\skills\specrew-gate-stop\SKILL.md'
if (-not (Test-Path -LiteralPath $claudeSkill -PathType Leaf)) {
    Write-Fail "gate-stop skill was not deployed to the Claude skill root at $claudeSkill."
}

foreach ($root in $staleRoots) {
    $outOfScopeSkillDir = Join-Path $scratchRoot (Join-Path $root 'specrew-gate-stop')
    if (Test-Path -LiteralPath $outOfScopeSkillDir) {
        Write-Fail "gate-stop skill was left in non-Claude host root: $outOfScopeSkillDir"
    }
}

Write-Pass "specrew-gate-stop: disallowed-tools enforcement, Claude host scope, six-section packet, no-picker verdict, Claude routing, .specify mirror parity, and scoped deployment all present"
Write-Host "`ngate-stop skill: all assertions pass" -ForegroundColor Green
