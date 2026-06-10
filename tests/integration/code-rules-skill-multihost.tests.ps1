[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 177 (code-implementation lens) iteration 002:
#   T015 guidance-skill conduct content, T016 multi-host parity.
# Conduct-content + deployment-parity tests (the runtime "agent actually guided" proof is the
# deployed-module dogfood T017 / SC-004,007,008, not unit-provable here).

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }
function Assert-Match { param([string]$Text, [string]$Pattern, [string]$m) if ($Text -notmatch $Pattern) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$skillsTpl = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\skills'
$codeRulesTpl = Join-Path $skillsTpl 'code-rules.md'
$workshopTpl = Join-Path $skillsTpl 'design-workshop.md'

# ---------------------------------------------------------------------------
# T015 — specrew-code-rules guidance-skill conduct content (FR-005, FR-006, FR-008)
# ---------------------------------------------------------------------------
Assert-True (Test-Path -LiteralPath $codeRulesTpl) 'T015: code-rules.md skill template exists'
$cr = Get-Content -LiteralPath $codeRulesTpl -Raw
Assert-Match -Text $cr -Pattern '(?ms)^---\s.*\bname:\s*"?specrew-code-rules"?' 'T015: frontmatter declares name specrew-code-rules'
Assert-Match -Text $cr -Pattern '(?i)resolve the active feature' 'T015: resolves the active feature (start-context)'
Assert-Match -Text $cr -Pattern 'implementation-rules\.yml' 'T015: reads the per-feature manifest'
Assert-Match -Text $cr -Pattern 'code-rules\.yml' 'T015: reads the canonical catalog by id'
Assert-Match -Text $cr -Pattern '(?i)baseline' 'T015: composes the baseline'
Assert-Match -Text $cr -Pattern '(?i)overlay' 'T015: composes the per-feature overlay'
Assert-Match -Text $cr -Pattern '(?i)task-scoped' 'T015: surfaces task-scoped (not a flat dump)'
Assert-Match -Text $cr -Pattern '(?i)baseline-only' 'T015: baseline-only mode when no manifest (FR-008)'
Assert-Match -Text $cr -Pattern 'dependency_policy' 'T015: honors the dependency_policy (FR-013)'
Assert-Match -Text $cr -Pattern '(?i)no new dependency|use existing' 'T015: default use-existing/no-new-dependency stance'
Assert-Match -Text $cr -Pattern '(?i)fail-open' 'T015: fail-open (never crash / never silently skip)'
Assert-Match -Text $cr -Pattern '(?i)guidance, not a gate' 'T015: explicitly guidance, not a gate (no 145)'

# The design-workshop skill carries the code-implementation lens turn (T012/T013).
Assert-True (Test-Path -LiteralPath $workshopTpl) 'T015: design-workshop skill template exists'
$ws = Get-Content -LiteralPath $workshopTpl -Raw
Assert-Match -Text $ws -Pattern '(?im)^## The code-implementation lens' 'T015: design-workshop has the code-implementation lens section'
Assert-Match -Text $ws -Pattern '(?i)auto-on for code' 'T015: code-implementation is auto-on for code features'
Assert-Match -Text $ws -Pattern '(?i)source of code-rules truth' 'T015: guideline-first source-of-truth (FR-010)'
Assert-Match -Text $ws -Pattern '(?i)example project' 'T015: example-project source-of-truth (FR-010/FR-011)'
Assert-Match -Text $ws -Pattern '(?i)assisted ingestion' 'T015: assisted ingestion (FR-011)'
Assert-Match -Text $ws -Pattern '(?i)grouped, pre-checked|grouped pre-checked|grouped.{0,20}checklist' 'T015: grouped pre-checked checklist (FR-003/FR-009, no wall)'
Assert-Match -Text $ws -Pattern 'dependency_policy' 'T015: dependency-selection capture (FR-013)'
Assert-Match -Text $ws -Pattern '(?i)code-rules\.local\.yml' 'T015: project overlay for company/org rules (FR-012)'
Assert-Match -Text $ws -Pattern '`code-implementation`' 'T015: code-implementation is in the lens enumeration'

# ---------------------------------------------------------------------------
# T016 — multi-host parity (FR-005, SC-003)
# ---------------------------------------------------------------------------
# code-rules.md is an all-hosts deployable definition (frontmatter name + NO host-scope restriction),
# so the existing deploy engine fans it to every host skill dir. (Deployed parity is dogfood-verified, T017.)
Assert-True ($cr -notmatch '(?im)^\s*host[-_ ]?scope\s*:' -and $cr -notmatch '(?im)^\s*hosts?\s*:\s*\[') 'T016: code-rules.md has no host-scope restriction => deploys to all hosts'
# T016 (Copilot review, PR #2447): explicitly assert the NEW specrew-code-rules skill reaches every host
# root (not only design-workshop). It is a generic skill -- frontmatter `name: specrew-code-rules`, in the
# enumerated skills-template root, no host-scope -- so the deploy engine's *.md fan-out lands it as
# `specrew-code-rules/SKILL.md` in each of the four host roots (.claude/skills, .cursor/rules,
# .github/skills, .agents/skills). The actual downstream deploy to all four is dogfood-verified (T017).
Assert-True (Test-Path -LiteralPath $codeRulesTpl) 'T016: specrew-code-rules (code-rules.md) is in the enumerated skills-template root -- the deploy-engine *.md fan-out source for every host (claude/cursor/github/agents)'
Assert-Match -Text $cr -Pattern '(?ms)^---\s.*\bname:\s*"?specrew-code-rules"?' 'T016: code-rules.md frontmatter name => deploys as specrew-code-rules/SKILL.md per host'

# design-workshop is already deployed; its template must be byte-identical across every host copy (parity).
$workshopCopies = @(
    (Join-Path $repoRoot '.claude\skills\specrew-design-workshop\SKILL.md'),
    (Join-Path $repoRoot '.agents\skills\specrew-design-workshop\SKILL.md'),
    (Join-Path $repoRoot '.github\skills\specrew-design-workshop\SKILL.md'),
    (Join-Path $repoRoot '.cursor\rules\specrew-design-workshop\SKILL.md')
)
$tplBytes = [System.IO.File]::ReadAllText($workshopTpl)
foreach ($copy in $workshopCopies) {
    Assert-True (Test-Path -LiteralPath $copy) "T016: design-workshop deployed copy exists: $copy"
    Assert-True (([System.IO.File]::ReadAllText($copy)) -eq $tplBytes) "T016: design-workshop deployed copy is byte-identical to the template: $copy"
}
# The code-implementation lens turn (T012/T013) is present in every deployed copy too (drift guard).
foreach ($copy in $workshopCopies) {
    Assert-Match -Text ([System.IO.File]::ReadAllText($copy)) -Pattern '(?im)^## The code-implementation lens' "T016: deployed copy carries the code-implementation lens turn: $copy"
}

Write-Host ''
Write-Host 'All code-rules-skill multi-host (F-177 i2) tests passed.' -ForegroundColor Green
exit 0
