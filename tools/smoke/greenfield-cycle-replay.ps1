Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path '.').Path
$root = Join-Path ([IO.Path]::GetTempPath()) ('realcycle-' + [guid]::NewGuid().ToString('N').Substring(0,8))
$feature = Join-Path $root 'specs/001-feat'
$i2 = Join-Path $feature 'iterations/002'
$i3 = Join-Path $feature 'iterations/003'
foreach ($d in @((Join-Path $root '.specrew/runtime'), (Join-Path $i2 'quality'), (Join-Path $i3 'quality'))) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
# iteration 002: CLOSED, the way a real completed iteration looks
Set-Content -LiteralPath (Join-Path $i2 'plan.md') -Value "# Iteration Plan: 002`n`n**Status**: complete`n" -Encoding UTF8
Set-Content -LiteralPath (Join-Path $i2 'state.md') -Value "# Iteration State: 002`n`n**Current Phase**: iteration-closeout`n**Iteration Status**: complete`n" -Encoding UTF8
# iteration 003: the fresh scaffold a new cycle opens with
Set-Content -LiteralPath (Join-Path $i3 'plan.md') -Value "# Iteration Plan: 003`n`n**Status**: planning`n" -Encoding UTF8
Set-Content -LiteralPath (Join-Path $i3 'state.md') -Value "# Iteration State: 003`n`n**Current Phase**: plan`n**Iteration Status**: executing`n" -Encoding UTF8
Set-Content -LiteralPath (Join-Path $i3 'quality/hardening-gate.md') -Value "# Hardening Gate`n`n**Overall Verdict**: ready" -Encoding UTF8
Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
& git -C $root init -q -b main
& git -C $root config user.email 't@t'
& git -C $root config user.name 't'
& git -C $root add -A
& git -C $root commit -q -m 'cycle fixture'
$head = ([string](& git -C $root rev-parse HEAD)).Trim()
# The ONLY seeded value: the store's global last authorization, as a real closed 002 leaves it.
$context = [ordered]@{
    schema = 'v2'
    feature_path = $feature
    boundary_enforcement = [ordered]@{
        enabled = $true; last_authorized_boundary = 'iteration-closeout'; pending_next_boundary = $null
        policy_classes = [ordered]@{ specify='human-judgment-required'; clarify='human-judgment-required'; plan='human-judgment-required'; tasks='human-judgment-required'; 'before-implement'='human-judgment-required'; 'review-signoff'='human-judgment-required'; retro='human-judgment-required'; 'iteration-closeout'='human-judgment-required'; 'feature-closeout'='human-judgment-required' }
        verdict_history = @(); bypass_history = @()
    }
    generated_at_utc = '2026-08-30T00:00:00Z'
    session_state = [ordered]@{ active=$true; boundary_type='iteration-closeout'; feature_ref='001-feat'; feature_path=$feature; iteration_number='002'; auth_commit_hash=$head; recorded_at='2026-08-30T00:00:00Z' }
}
[IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($context | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))

function Get-PlanStatus { param([string]$p) $m=[regex]::Match((Get-Content -LiteralPath $p -Raw -Encoding UTF8),'\*\*Status\*\*:\s*(?<v>\S+)'); if($m.Success){return $m.Groups['v'].Value}; return '' }
Write-Host ("003 plan BEFORE the real sync: " + (Get-PlanStatus (Join-Path $i3 'plan.md')))

# THE REAL TOP-LEVEL ENTRY POINT - the whole sync path, not the truth gate alone.
. (Join-Path $repoRoot 'scripts/internal/sync-boundary-state.ps1')
try { $null = Invoke-SpecrewBoundaryStateSync -ProjectPath $root -BoundaryType 'plan' -FeatureRef '001-feat' -IterationNumber '003' 2>&1 | Out-Null }
catch { Write-Host ("sync threw: " + $_.Exception.Message) }
Write-Host ("003 plan AFTER  the real sync: " + (Get-PlanStatus (Join-Path $i3 'plan.md')))
Write-Host ("002 plan (closed, untouched):  " + (Get-PlanStatus (Join-Path $i2 'plan.md')))
Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
