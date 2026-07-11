# Paired tests for the per-host review-budget resolution chain and the independence
# provenance (F-198 FR-021/FR-022/FR-023, SC-006, NFR-007): explicit -> config ->
# catalog -> 600 floor; env cascade recorded as independence_source.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\continuous-co-review\reviewer-contracts.ps1')
. (Join-Path $repoRoot 'scripts\internal\continuous-co-review\reviewer-host-catalog.ps1')
. (Join-Path $repoRoot 'scripts\internal\continuous-co-review\continuous-co-review-navigator.ps1')
$script:failCount = 0

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }

Write-Host "Test 1: catalog rows carry the decided per-host budgets"
$expected = @{ copilot = 300; codex = 600; claude = 600; antigravity = 900 }
foreach ($hostName in $expected.Keys) {
    $v = Get-ContinuousCoReviewHostDefaultTimeoutSeconds -HostName $hostName
    if ($v -ne $expected[$hostName]) { Write-Fail "$hostName expected $($expected[$hostName]), got '$v'" } else { Write-Pass "$hostName -> $v" }
}
$null1 = Get-ContinuousCoReviewHostDefaultTimeoutSeconds -HostName 'cursor-agent'
$null2 = Get-ContinuousCoReviewHostDefaultTimeoutSeconds -HostName 'no-such-host'
if ($null -ne $null1 -or $null -ne $null2) { Write-Fail "rows without a value must return null (tolerant reader)" } else { Write-Pass "absent value / unknown host -> null (tolerant reader)" }

Write-Host "Test 2: resolution chain - config wins over catalog"
$fx = Join-Path ([System.IO.Path]::GetTempPath()) ("budget-fixture-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path (Join-Path $fx '.specrew') | Out-Null
'co_review_timeout_seconds: 777' | Set-Content (Join-Path $fx '.specrew\config.yml')
$v = Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $fx -HostName 'copilot'
if ($v -ne 777) { Write-Fail "config must win over catalog, got $v" } else { Write-Pass "config 777 beats catalog copilot 300" }

Write-Host "Test 3: resolution chain - catalog per-host when no config"
Remove-Item (Join-Path $fx '.specrew\config.yml') -Force
$v = Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $fx -HostName 'antigravity'
if ($v -ne 900) { Write-Fail "catalog antigravity 900 expected, got $v" } else { Write-Pass "no config -> catalog antigravity 900" }
$v = Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $fx -HostName 'copilot'
if ($v -ne 300) { Write-Fail "catalog copilot 300 expected, got $v" } else { Write-Pass "no config -> catalog copilot 300" }

Write-Host "Test 4: resolution chain - the 600 floor is the terminal fallback"
$v = Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $fx -HostName 'no-such-host'
if ($v -ne 600) { Write-Fail "unknown host must fall to the 600 floor, got $v" } else { Write-Pass "unknown host -> 600 floor" }
$v = Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $fx
if ($v -ne 600) { Write-Fail "no host must fall to the 600 floor, got $v" } else { Write-Pass "no host -> 600 floor (maintainer ruling: 300 was too short)" }
Remove-Item -Recurse -Force $fx

Write-Host "Test 5: independence provenance - flag beats env, env beats unverified (FR-023)"
. (Join-Path $repoRoot 'scripts\internal\continuous-co-review\worktree-review-orchestrator.ps1')
# Hermetic fixture (independent-review catch): the resolver authorizes hosts from
# <RepoRoot>/.specrew/reviewer-hosts.json, which is untracked runtime state - absent in a
# clean checkout, so pointing at the live repo made these assertions depend on ambient
# authorization. The fixture carries its own authorized codex entry, like Tests 2-4.
$fx5 = Join-Path ([System.IO.Path]::GetTempPath()) ("provenance-fixture-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path (Join-Path $fx5 '.specrew') | Out-Null
@{
    schema_version = '1.0'
    hosts          = @(@{
            host = 'codex'; model = 'chatgpt'; adapter_id = 'reviewer-host-adapter-codex-exec'
            allowed = $true; installed = $true; review_class_rank = 85; model_source = 'human-entered'
            cost_class = 'non-default'; authorization_ref = 'fixture-authorized'; fallback_allowed = $false
            timeout_seconds = 0
        })
} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $fx5 '.specrew\reviewer-hosts.json') -Encoding UTF8
$savedHost = $env:SPECREW_HOST; $savedActive = $env:SPECREW_ACTIVE_HOST
try {
    $env:SPECREW_HOST = 'claude'; $env:SPECREW_ACTIVE_HOST = $null
    $r = Resolve-ContinuousCoReviewReviewerHost -RepoRoot $fx5 -CodeWriterHost 'claude' -RequestedHost 'codex'
    if ($null -eq $r -or [string]$r.independence_source -ne 'flag') { Write-Fail "explicit flag must record independence_source=flag, got: $($r | ConvertTo-Json -Compress)" }
    else { Write-Pass "explicit -CodeWriterHost records independence_source=flag" }
    $r = Resolve-ContinuousCoReviewReviewerHost -RepoRoot $fx5 -CodeWriterHost '' -RequestedHost 'codex'
    if ($null -eq $r -or [string]$r.independence_source -ne 'env') { Write-Fail "env cascade must record independence_source=env, got: $($r | ConvertTo-Json -Compress)" }
    elseif ([string]$r.independence -ne 'independent') { Write-Fail "env-resolved claude code-writer vs codex reviewer must label independent, got '$($r.independence)'" }
    else { Write-Pass "SPECREW_HOST cascade records independence_source=env and upgrades the label to independent" }
    $env:SPECREW_HOST = $null
    $r = Resolve-ContinuousCoReviewReviewerHost -RepoRoot $fx5 -CodeWriterHost '' -RequestedHost 'codex'
    if ($null -eq $r -or [string]$r.independence_source -ne 'unverified') { Write-Fail "no flag + no env must record independence_source=unverified, got: $($r | ConvertTo-Json -Compress)" }
    else { Write-Pass "no flag/env stays unverified (SEC-004 fail-closed treatment unchanged)" }
}
finally { $env:SPECREW_HOST = $savedHost; $env:SPECREW_ACTIVE_HOST = $savedActive; Remove-Item -Recurse -Force $fx5 -ErrorAction SilentlyContinue }

Write-Host ""
if ($script:failCount -gt 0) { Write-Host "$script:failCount test(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "All budget-resolution + provenance tests passed." -ForegroundColor Green
exit 0
