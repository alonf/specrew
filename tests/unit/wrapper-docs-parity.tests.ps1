[CmdletBinding()]
param()

# Docs-parity arm of the wrapper cascade (feature 140 / T023, FR-011/FR-009).
# Asserts every `specrew-*` command token in the native-first docs resolves to a real
# command surface — a Specrew.psd1 wrapper alias, a deployed skill, or an allowlisted
# namespace — so a removed/renamed alias cannot leave a stale reference in the docs.
# Cascade on failure: registry -> wrappers -> installer -> FileList -> docs.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; throw $m }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Canonical command surface the docs may reference:
#  (1) wrapper aliases (the registry that drives bin/ + FileList),
$registry = @((Import-PowerShellDataFile -LiteralPath (Join-Path $repoRoot 'Specrew.psd1')).AliasesToExport)
if ($registry.Count -eq 0) { Write-Fail 'Specrew.psd1 AliasesToExport is empty' }

#  (2) deployed skills (slash-command surface), discovered from the tracked .claude/skills set,
$skillsDir = Join-Path $repoRoot '.claude/skills'
$skills = @()
if (Test-Path -LiteralPath $skillsDir -PathType Container) {
    $skills = @(Get-ChildItem -LiteralPath $skillsDir -Directory |
        Where-Object { $_.Name -like 'specrew-*' } |
        ForEach-Object { $_.Name })
}
if ($skills.Count -eq 0) { Write-Fail "no skills discovered under $skillsDir (expected specrew-* skill directories)" }

#  (3) allowlist of non-command specrew-* tokens that legitimately appear in docs, with rationale:
#      specrew-speckit -> the Spec Kit extension namespace (file paths + slash-command prefixes), not a command.
$allowlist = @('specrew-speckit')

$validSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($n in ($registry + $skills + $allowlist)) { [void]$validSet.Add($n) }

# Native-first docs in scope (the FR-014 set). Historical release notes are intentionally out of scope.
$docs = @('README.md', 'docs/getting-started.md', 'docs/user-guide.md', 'docs/troubleshooting.md')

$violations = [System.Collections.Generic.List[string]]::new()
foreach ($rel in $docs) {
    $path = Join-Path $repoRoot $rel
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Write-Fail "doc not found: $rel" }
    $text = Get-Content -LiteralPath $path -Raw
    # Match command-shaped `specrew-*` tokens only: exclude file paths / extensions
    # (e.g. assets/specrew-icon.png) and feature-dir names (e.g. 019-specrew-...) via the
    # look-behind (not preceded by a word char or hyphen) and look-ahead (not followed by a
    # path slash, a longer word, or a .extension). Backticked aliases + /slash-commands still match.
    foreach ($m in [regex]::Matches($text, '(?<![\w-])specrew-[a-z0-9]+(?:-[a-z0-9]+)*(?![\w/-]|\.\w)')) {
        if (-not $validSet.Contains($m.Value)) {
            $violations.Add("$rel -> '$($m.Value)'") | Out-Null
        }
    }
}

if ($violations.Count -gt 0) {
    $list = (($violations | Sort-Object -Unique) -join "`n  ")
    Write-Fail @"
docs reference unknown specrew-* command tokens.
Cascade: registry -> wrappers -> installer -> FileList -> docs. A removed/renamed alias or a
typo left a stale reference. Fix the doc, add the alias/skill, or allowlist it with rationale:
  $list
"@
}
Write-Pass "all specrew-* doc command tokens resolve to a wrapper alias, skill, or allowlisted namespace ($($docs.Count) docs, $($validSet.Count) valid names)"

Write-Host ''
Write-Host 'All wrapper-docs-parity tests passed.' -ForegroundColor Green
