[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 182 iteration 002 unit tests:
#   T211 work-kind validator (FR-007, SC-005) + bypass audit (FR-011, SC-009).
# Hermetic: a temp project dir holds the catalog + a per-scenario declaration; the changed-file set
# and branch are passed as overrides (no git dependency).

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
$scriptsDir = Join-Path $repoRoot 'extensions' 'specrew-speckit' 'scripts'
. (Join-Path $scriptsDir 'work-kind-validator.ps1')

# --- hermetic temp project with the real catalog ---
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("wk-validator-" + [Guid]::NewGuid().ToString('N'))
$knowledge = Join-Path $tmp 'extensions' 'specrew-speckit' 'knowledge'
$null = New-Item -ItemType Directory -Path $knowledge -Force
$null = New-Item -ItemType Directory -Path (Join-Path $tmp '.specrew') -Force
Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions' 'specrew-speckit' 'knowledge' 'work-kinds.yml') -Destination (Join-Path $knowledge 'work-kinds.yml') -Force

function Set-Decl { param([string]$Kind) Set-Content -LiteralPath (Join-Path $tmp '.specrew' 'work-kind.yml') -Value "work_kind: $Kind`nschema_version: `"1.0`"" -Encoding UTF8 }
function Clear-Decl { Remove-Item -LiteralPath (Join-Path $tmp '.specrew' 'work-kind.yml') -Force -ErrorAction SilentlyContinue }

try {
    # --- changed-file scope: docs-only touching a runtime .ps1 FAILS ---
    Set-Decl 'docs-only'
    $r = Invoke-SpecrewWorkKindValidation -ProjectPath $tmp -ChangedFiles @('docs/x.md', 'extensions/specrew-speckit/scripts/work-kind-validator.ps1') -Branch 'docs/x' -Mode advisory
    Assert-True ($r.verdict -eq 'advisory-fail') "T211: docs-only touching a runtime .ps1 -> advisory-fail (got $($r.verdict))"
    $scopeFinding = @($r.findings | Where-Object { $_.check -eq 'changed-file-scope' })
    Assert-True ($scopeFinding.Count -eq 1) 'T211: exactly one changed-file-scope finding (only the .ps1, not the .md)'
    Assert-True ($scopeFinding[0].message -match 'work-kind-validator\.ps1' -and $scopeFinding[0].message -match 'docs-only allows') 'T211: the finding NAMES the offending file + the allowed scope (SC-005)'

    # --- docs-only touching only docs PASSES ---
    $r2 = Invoke-SpecrewWorkKindValidation -ProjectPath $tmp -ChangedFiles @('docs/x.md', 'README.md', 'CHANGELOG.md') -Branch 'docs/x' -Mode advisory
    Assert-True ($r2.verdict -eq 'advisory-pass') "T211: docs-only touching only docs/allowlisted -> advisory-pass (got $($r2.verdict))"

    # --- software-feature scope is permissive (**) ; feature branch not resolvable -> closeout skipped (fail-open) ---
    Set-Decl 'software-feature'
    $r3 = Invoke-SpecrewWorkKindValidation -ProjectPath $tmp -ChangedFiles @('src/app.ps1', 'docs/x.md') -Branch 'feature/x' -Mode advisory
    Assert-True ($r3.verdict -eq 'advisory-pass') "T211: software-feature over any path passes scope; unresolvable branch -> closeout fail-open (got $($r3.verdict))"

    # --- no declaration + no matching branch prefix -> WARN (never a hard fail) ---
    Clear-Decl
    $r4 = Invoke-SpecrewWorkKindValidation -ProjectPath $tmp -ChangedFiles @('src/app.ps1') -Branch '182-some-feature' -Mode advisory
    Assert-True ($r4.verdict -eq 'advisory-warn' -and $null -eq $r4.kind) 'T211: no declaration + no branch prefix -> advisory-warn, no hard fail'
    Assert-True (@($r4.findings | Where-Object { $_.check -eq 'declaration' }).Count -eq 1) 'T211: the warn NAMES the missing declaration + how to add it'

    # --- branch-prefix inference: a devops/ branch with no decl infers devops ---
    $r5 = Invoke-SpecrewWorkKindValidation -ProjectPath $tmp -ChangedFiles @('.github/workflows/ci.yml') -Branch 'devops/ci-fix' -Mode advisory
    Assert-True ($r5.kind -eq 'devops') "T211: a devops/ branch infers work_kind 'devops' from the prefix (got '$($r5.kind)')"

    # --- blocking mode turns the same scope mismatch into blocking-fail ---
    Set-Decl 'docs-only'
    $r6 = Invoke-SpecrewWorkKindValidation -ProjectPath $tmp -ChangedFiles @('src/app.ps1') -Branch 'docs/x' -Mode blocking
    Assert-True ($r6.verdict -eq 'blocking-fail') "T211: blocking mode -> blocking-fail on a scope mismatch (got $($r6.verdict))"

    # --- unknown kind -> WARN + skip (fail-open) ---
    Set-Decl 'not-a-kind'
    $r7 = Invoke-SpecrewWorkKindValidation -ProjectPath $tmp -ChangedFiles @('src/app.ps1') -Branch 'x' -Mode blocking
    Assert-True ($r7.verdict -like '*-warn') "T211: an unknown work_kind -> warn + skip, never a hard fail (got $($r7.verdict))"

    # --- bypass audit writes a durable artifact (FR-011, SC-009) ---
    Clear-Decl
    $b = Write-SpecrewWorkKindBypassAudit -ProjectPath $tmp -Who 'tester' -Why 'unit test' -When '2026-06-11T00:00:00Z'
    Assert-True ([bool]$b.recorded -and (Test-Path -LiteralPath $b.path)) 'T211: bypass audit writes a durable artifact (no silent skip)'
    Assert-True ((Get-Content -LiteralPath $b.path -Raw) -match 'who: tester' -and (Get-Content -LiteralPath $b.path -Raw) -match 'why: unit test') 'T211: the bypass artifact records who/why/when'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`nAll T211 work-kind validator assertions passed." -ForegroundColor Green
