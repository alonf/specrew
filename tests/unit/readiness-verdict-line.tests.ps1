# B4F-071: THE OVERALL VERDICT LINE COMES FROM THE LEDGER, AND EVERY READER QUOTES IT VERBATIM.
#
# On the router-skill project (Copilot CLI 1.0.83, 2026-09-10) the before-implement readiness sub-agent read
# the ledger and wrote "Overall verdict: BLOCKED for implementation - no tasks -> before-implement
# authorization exists". The crew summarized the passing artifact checks as PASS, dropped that line, and
# announced T201. readiness-verdict.ps1 prints that line from the ledger; the command makes it the report's
# first line; the coordinator quotes it verbatim. This suite pins the script's two answers and the three
# surfaces that name it. Mutation (recorded, not a switch): `-ge` -> `-gt` in the script makes Case 2 red.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script_ = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/readiness-verdict.ps1'
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')

function New-LedgerRoot {
    param([string]$LastAuthorized, [string]$Working, [switch]$WithPendingCrossing)
    $root = Join-Path ([IO.Path]::GetTempPath()) ('rvl-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-fixture/iterations/001') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/iterations/001/plan.md'), "# Iteration Plan: 001`n`n**Status**: planning`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/iterations/001/quality-placeholder.md'), "x`n", [Text.UTF8Encoding]::new($false))
    $ctx = [ordered]@{
        schema = 'v2'; feature_path = (Join-Path $root 'specs/001-fixture')
        session_state = [ordered]@{ active = $true; boundary_type = $Working; feature_ref = '001-fixture'; iteration_number = '001'; recorded_at = '2026-09-10T12:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = $LastAuthorized; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    if ($WithPendingCrossing) {
        # a real commit, because the scoped crossing binds to a git tree
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-fixture/iterations/001/quality') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/iterations/001/quality/hardening-gate.md'), "# Hardening Gate`n", [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/runtime/`n", [Text.UTF8Encoding]::new($false))
        $null = & git -C $root init -q -b main 2>&1; $null = & git -C $root config user.email 'f@f' 2>&1; $null = & git -C $root config user.name 'f' 2>&1
        $null = & git -C $root add -A 2>&1; $null = & git -C $root commit -q -m fixture 2>&1
        $head = (@(& git -C $root rev-parse HEAD 2>&1))[0].ToString().Trim()
        $null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $root -WorkingBoundary $Working -BoundaryCommitHash $head -RecordedAt '2026-09-10T12:00:01Z' 2>$null
    }
    return $root
}
function Invoke-Line { param([string]$Root) $o = (& pwsh -NoProfile -File $script_ -ProjectPath $Root 2>&1 | ForEach-Object { [string]$_ }) -join "`n"; return [pscustomobject]@{ Code = $LASTEXITCODE; Out = $o.Trim() } }

Write-Host 'readiness-verdict-line'
$roots = New-Object System.Collections.Generic.List[string]
try {
    Write-Host '  --- Case 1: the router-skill shape - authorized through tasks, tasks -> before-implement pending ---'
    $r1 = New-LedgerRoot -LastAuthorized 'tasks' -Working 'before-implement' -WithPendingCrossing; $roots.Add($r1) | Out-Null
    $l1 = Invoke-Line -Root $r1
    Assert-True ($l1.Code -eq 0) 'the script exits 0 - the line is evidence, not a gate'
    Assert-True ($l1.Out -match '^Overall verdict: BLOCKED for implementation') ('the line says BLOCKED (got: ' + $l1.Out.Substring(0, [Math]::Min(80, $l1.Out.Length)) + ')')
    Assert-True ($l1.Out -match "last authorized boundary is 'tasks'") 'and names the ledger''s last authorized boundary'
    Assert-True ($l1.Out -match "pending crossing is 'tasks -> before-implement'") 'and the pending crossing'
    Assert-True ($l1.Out -match "approved for before-implement") 'and the one move that clears it'
    Assert-True (@($l1.Out -split "`n").Count -eq 1) 'it is ONE line'

    Write-Host '  --- Case 2: authorized through before-implement ---'
    $r2 = New-LedgerRoot -LastAuthorized 'before-implement' -Working 'before-implement'; $roots.Add($r2) | Out-Null
    $l2 = Invoke-Line -Root $r2
    Assert-True ($l2.Out -match '^Overall verdict: READY for implementation') 'the line says READY when the ledger says before-implement'
    Write-Host '  --- Case 3: authorized past it ---'
    $r3 = New-LedgerRoot -LastAuthorized 'review-signoff' -Working 'review-signoff'; $roots.Add($r3) | Out-Null
    Assert-True ((Invoke-Line -Root $r3).Out -match '^Overall verdict: READY') 'a later authorized boundary is READY too'
    Write-Host '  --- Case 4: nothing pending, nothing authorized past plan ---'
    $r4 = New-LedgerRoot -LastAuthorized 'plan' -Working 'plan'; $roots.Add($r4) | Out-Null
    $l4 = Invoke-Line -Root $r4
    Assert-True ($l4.Out -match '^Overall verdict: BLOCKED' -and $l4.Out -match 'no crossing is pending') 'BLOCKED, and says no crossing is pending'

    Write-Host '  --- the surfaces that carry the line ---'
    foreach ($rel in @('extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md', '.specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md')) {
        $cmd = Get-Content -LiteralPath (Join-Path $repoRoot $rel) -Raw -Encoding UTF8
        Assert-True ($cmd -match 'readiness-verdict\.ps1' -and $cmd -match '(?i)first line of your report, verbatim') ("the command names the script and the verbatim first-line rule: " + $rel)
        Assert-True ($cmd -match '(?i)artifact checks that all pass do not make the overall verdict READY') ("and says passing artifacts are not the verdict: " + $rel)
    }
    $coord = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md') -Raw -Encoding UTF8
    Assert-True ($coord -match 'readiness-verdict\.ps1' -and $coord -match '(?i)quoted VERBATIM as the first line') 'the coordinator quotes the line verbatim in the packet'
    Assert-True ($coord -match '(?i)never summarized as the overall verdict') 'and never summarizes passing artifacts as the verdict'
    $manifest = Get-Content -LiteralPath (Join-Path $repoRoot 'Specrew.psd1') -Raw -Encoding UTF8
    Assert-True ($manifest -match "'extensions/specrew-speckit/scripts/readiness-verdict\.ps1'") 'the script ships: it is in the package FileList'
    Assert-True ((Get-Content -LiteralPath $script_ -Raw) -ceq (Get-Content -LiteralPath (Join-Path $repoRoot '.specify/extensions/specrew-speckit/scripts/readiness-verdict.ps1') -Raw)) 'the deployed mirror is byte-identical'
}
finally { foreach ($r in $roots) { if (Test-Path -LiteralPath $r) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } } }

if ($script:Failures -gt 0) { Write-Host ("readiness-verdict-line: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'readiness-verdict-line: all cases passed'
exit 0
