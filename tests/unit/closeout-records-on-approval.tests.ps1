# Feature 202 iteration 003, T031 (B4F-146; FR-027): a closeout is recorded as closed only on its approval.
#
# Seen twice on 2026-10-20/21: the iteration-closeout sync, run to ASK the human for the closeout, added the iteration
# to `.specrew/closed-iterations.yml` before any approval. Anything reading the index then saw the iteration closed
# while the decision was pending - and it would have stayed closed had the human said no. The seal had the same
# defect and moved to the approval's capture (B4F-063); the index entry follows it.
#
# Through the real sync (the deployed wrapper, pointed at this repository's module tree) and the real capture
# (Add-SpecrewBoundaryAuthorization), in a temp git project:
#   1. the sync that asks for the closeout leaves the index without the iteration, and still renders the dashboard;
#   2. asking again adds nothing;
#   3. the captured approval adds the entry, once, and seals the iteration;
#   4. a sync for another boundary adds nothing either.
# The repository's own index and lifecycle position must not change (B4F-148).

$ErrorActionPreference = 'Stop'
$script:Failures = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host ("  PASS: {0}" -f $Message) }
    else { Write-Host ("  FAIL: {0}" -f $Message); $script:Failures++ }
}

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$governance = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1'
$syncWrapper = Join-Path $repoRoot '.specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1'

Write-Host 'closeout-records-on-approval'
Write-Host '  --- preconditions ---'
foreach ($f in @($governance, $syncWrapper)) { Assert-True (Test-Path -LiteralPath $f -PathType Leaf) ('present: ' + (Split-Path -Leaf $f)) }
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE'; exit 1 }
. $governance

# The repository's own stores, before: nothing in this suite may write them.
$guarded = @('.specrew/closed-iterations.yml', '.specrew/start-context.json', '.specify/feature.json', '.squad/decisions.md',
    '.specrew/active-sessions.yml', '.squad/active-features.yml', '.specrew/last-start-prompt.md', '.squad/identity/now.md')
function Get-GuardHashes {
    $map = [ordered]@{}
    foreach ($rel in $guarded) {
        $p = Join-Path $repoRoot $rel
        $map[$rel] = if (Test-Path -LiteralPath $p -PathType Leaf) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash } else { '<absent>' }
    }
    return $map
}
$guardBefore = Get-GuardHashes

function New-RetroIterationRepo {
    # A git project with one feature whose iteration 001 is at retro (retro authorized), everything the closeout
    # sync's gates read present and committed, and NO closed-iterations entry: the iteration is not closed.
    $root = Join-Path ([IO.Path]::GetTempPath()) ('cra-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $utf8 = [Text.UTF8Encoding]::new($false)
    foreach ($d in @('.specrew/runtime', '.specify', '.squad', '.github/agents', 'specs/001-fixture/iterations/001')) { New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/config.yml'), "project_name: fixture`nspecrew_version: `"0.40.0`"`nbootstrap_date: `"2026-09-01`"`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.specify/feature.json'), "{`n  `"feature_directory`": `"specs/001-fixture`"`n}`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.squad/team.md'), "# Team`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.squad/config.json'), "{}`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.squad/decisions.md'), "# Decisions`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.github/agents/squad.agent.md'), "# Squad Agent`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root 'README.md'), "# Fixture`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/runtime/`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/spec.md'), "# Feature Specification: Fixture`n`n## Requirements`n`n- **FR-001**: Do the thing.`n", $utf8)
    $iter = Join-Path $root 'specs/001-fixture/iterations/001'
    [IO.File]::WriteAllText((Join-Path $iter 'plan.md'), "# Iteration Plan: 001`n`n**Status**: retro`n`n## Tasks`n`n| Task | Requirement | Title | Story | Effort |`n| ---- | ----------- | ----- | ----- | ------ |`n| T-001 | FR-001 | Do the thing | S-1 | 2 |`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'tasks.md'), "# Tasks`n`n- [x] T-001 Do the thing`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'tasks-progress.yml'), "feature: 001-fixture`niteration: `"001`"`ntasks:`n  T-001:`n    title: Do the thing`n    status: done`n    started_at: `"2026-09-10T10:00:00Z`"`n    completed_at: `"2026-09-10T11:00:00Z`"`n    blocked_reason: `"`"`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'state.md'), "# Iteration State: 001`n`n**Schema**: v2`n**Current Phase**: retro`n**Iteration Status**: retro`n**Last Completed Task**: T-001`n**Tasks Remaining**: 0`n**In Progress**: none`n**Baseline Ref**: abc1234`n**Updated**: 2026-09-10T12:00:00Z`n`n## Execution Summary`n`nDone.`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'review.md'), "# Review: Iteration 001`n`n**Overall Verdict**: accepted`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'retro.md'), "# Retro: Iteration 001`n`nWhat went well.`n", $utf8)
    $null = & git -C $root init -q -b 001-fixture 2>&1
    $null = & git -C $root config user.email 'fixture@specrew.local' 2>&1
    $null = & git -C $root config user.name 'Fixture' 2>&1
    $null = & git -C $root add -A 2>&1
    $null = & git -C $root commit -q -m 'iteration 001 at retro' 2>&1
    $head = (@(& git -C $root rev-parse HEAD 2>&1))[0].ToString().Trim()
    $ctx = [ordered]@{
        schema = 'v2'
        feature_path = (Join-Path $root 'specs/001-fixture')
        session_state = [ordered]@{ active = $true; boundary_type = 'retro'; feature_ref = '001-fixture'; iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-09-10T12:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'retro'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), $utf8)
    $null = & git -C $root add -A 2>&1
    $null = & git -C $root commit -q -m 'cursor at retro' 2>&1
    return $root
}

function Invoke-Sync {
    param([string]$Root, [string]$Boundary, [string]$Iteration = '001')
    $head = (@(& git -C $Root rev-parse HEAD 2>&1))[0].ToString().Trim()
    $iterationArgs = if ([string]::IsNullOrWhiteSpace($Iteration)) { @() } else { @('-IterationNumber', $Iteration) }
    $out = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $syncWrapper -ProjectPath $Root -BoundaryType $Boundary -FeatureRef 001-fixture @iterationArgs -AuthCommitHash $head 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $out }
}

function Get-IndexEntryCount {
    param([string]$Root)
    # Raw lines, not the parsed index: the parser keys by feature/iteration, so it would hide a second entry.
    $p = Get-SpecrewClosedIterationIndexPath -ProjectRoot $Root
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return 0 }
    return @(Get-Content -LiteralPath $p -Encoding UTF8 | Where-Object { $_ -match '^\s*-\s+feature:\s*"?001-fixture"?\s*$' }).Count
}

function Read-Pending {
    param([string]$Root)
    return (Get-Content -LiteralPath (Join-Path $Root '.specrew/start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12).boundary_enforcement.pending_crossing
}

function Add-FixtureLockAndClaim {
    # The module's own writers, loaded in this function's scope only.
    param([string]$Root)
    . (Join-Path $repoRoot 'scripts/internal/session-management.ps1')
    . (Join-Path $repoRoot 'scripts/internal/feature-claims.ps1')
    Register-SessionLock -ProjectRoot $Root -FeatureId '001-fixture'
    Add-FeatureClaim -ProjectRoot $Root -FeatureId '001-fixture' -ClaimedBy 'fixture' -BranchName '001-fixture' -NowUtc '2026-09-10T12:00:00Z'
}
function Add-FixtureMergeToMain {
    param([string]$Root)
    $first = (@(& git -C $Root rev-list --max-parents=0 HEAD 2>&1))[0].ToString().Trim()
    $null = & git -C $Root branch main $first 2>&1
    $null = & git -C $Root checkout -q main 2>&1
    $null = & git -C $Root merge -q --no-ff 001-fixture -m 'Merge branch 001-fixture' 2>&1
    $null = & git -C $Root checkout -q 001-fixture 2>&1
}
function Test-FixtureLock {
    param([string]$Root)
    $p = Join-Path $Root '.specrew/active-sessions.yml'
    return ((Test-Path -LiteralPath $p -PathType Leaf) -and ((Get-Content -LiteralPath $p -Raw -Encoding UTF8) -match '001-fixture'))
}
function Test-FixtureClaim {
    param([string]$Root)
    $p = Join-Path $Root '.squad/active-features.yml'
    return ((Test-Path -LiteralPath $p -PathType Leaf) -and ((Get-Content -LiteralPath $p -Raw -Encoding UTF8) -match '001-fixture'))
}
function Read-SessionActive {
    param([string]$Root)
    $v = (Get-Content -LiteralPath (Join-Path $Root '.specrew/start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20).session_state.active
    if ($v -is [bool]) { return $v }
    return ([string]$v -eq 'true')
}
function Read-FrontmatterActive {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '<absent>' }
    $m = [regex]::Match((Get-Content -LiteralPath $Path -Raw -Encoding UTF8), '(?m)^session_state_active:\s*(\S+)\s*$')
    return $(if ($m.Success) { $m.Groups[1].Value.Trim('"').ToLowerInvariant() } else { '<none>' })
}
function Read-PointerFeature {
    param([string]$Root)
    $p = Join-Path $Root '.specify/feature.json'
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return '' }
    return [string](Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json).feature_directory
}
# The validator's closure rule, loaded from its file so the text asserted is the text shipped.
$validatorText = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/validate-governance.ps1') -Raw -Encoding UTF8
$fnStart = $validatorText.IndexOf('function Test-SessionStateBoundaryCanonical {')
$fnEnd = $validatorText.IndexOf("`nfunction ", $fnStart + 10)
Invoke-Expression $validatorText.Substring($fnStart, $fnEnd - $fnStart)
function Invoke-ClosureRule {
    param([string]$Root)
    # It reports through Write-Host (the information stream) and returns a count; the contradiction lines are kept.
    return @(Test-SessionStateBoundaryCanonical -ProjectRoot $Root 6>&1 | ForEach-Object { [string]$_ } | Where-Object { $_ -match 'contradictory' })
}

$priorModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot
$roots = New-Object System.Collections.Generic.List[string]
try {
    $root = New-RetroIterationRepo; $roots.Add($root) | Out-Null
    $iter = Join-Path $root 'specs/001-fixture/iterations/001'
    Assert-True ((Get-IndexEntryCount -Root $root) -eq 0) 'fixture: iteration 001 is not in the closed-iterations index'

    Write-Host '  --- 1: the sync that asks for the closeout ---'
    $sync1 = Invoke-Sync -Root $root -Boundary 'iteration-closeout'
    if ($sync1.ExitCode -ne 0) { Write-Host ('  sync output: ' + $sync1.Output) }
    Assert-True ($sync1.ExitCode -eq 0) 'the closeout sync exits 0'
    $pending = Read-Pending -Root $root
    Assert-True ($null -ne $pending -and [string]$pending.to_boundary -eq 'iteration-closeout') 'and the closeout decision is pending'
    Assert-True ((Get-IndexEntryCount -Root $root) -eq 0) 'the closed-iterations index does NOT list iteration 001 while the decision is pending'
    Assert-True (Test-Path -LiteralPath (Join-Path $iter 'dashboard.md') -PathType Leaf) 'the dashboard is still rendered when the closeout is asked for'
    Assert-True (-not (Test-SpecrewIterationSealed -IterationDirectory $iter)) 'and nothing is sealed (B4F-063)'

    Write-Host '  --- 2: the closeout asked again ---'
    $null = & git -C $root add -A 2>&1; $null = & git -C $root commit -q -m 'asked once' 2>&1
    $sync2 = Invoke-Sync -Root $root -Boundary 'iteration-closeout'
    Assert-True ($sync2.ExitCode -eq 0) 'the second closeout sync exits 0'
    Assert-True ((Get-IndexEntryCount -Root $root) -eq 0) 'asking again still leaves iteration 001 out of the index'

    Write-Host '  --- 3: the human''s approval ---'
    $verdict = Add-SpecrewBoundaryAuthorization -ProjectRoot $root -CurrentBoundary 'retro' -AuthorizedBoundary 'iteration-closeout' -AuthorizingHuman 'Fixture Human' -VerdictText 'approved for iteration-closeout' -EvidenceSource 'hook-captured-from-transcript' 2>$null
    Assert-True ($null -ne $verdict -and [string]$verdict.AuthorizedBoundary -ceq 'iteration-closeout') 'the approval is recorded'
    Assert-True ((Get-IndexEntryCount -Root $root) -eq 1) 'and the capture adds iteration 001 to the index, once'
    Assert-True (Test-SpecrewIterationClosed -ProjectRoot $root -Feature '001-fixture' -Iteration '001') 'Test-SpecrewIterationClosed now reads it as closed'
    Assert-True (Test-SpecrewIterationSealed -IterationDirectory $iter) 'and the iteration is sealed, the capture''s last act'
    $after = Test-SpecrewIterationSealIntegrity -IterationDirectory $iter
    Assert-True (@(@($after.drifted) + @($after.missing) + @($after.added)).Count -eq 0) 'the seal is intact: the index entry is written outside the sealed iteration'

    Write-Host '  --- 4: a later sync adds nothing ---'
    $null = & git -C $root add -A 2>&1; $null = & git -C $root commit -q -m 'closeout authorized' 2>&1
    $sync4 = Invoke-Sync -Root $root -Boundary 'iteration-closeout'
    Assert-True ((Get-IndexEntryCount -Root $root) -eq 1) 'a re-run closeout sync after the approval leaves exactly one entry'

    # ==================== T032: the feature closeout ====================
    # When the feature closeout was asked for, the sync marked the session inactive, cleared the active-feature
    # pointer, released the session lock and removed the feature claim (when merged). All four now wait for the
    # approval. The branch is merged to main here so the claim removal has something to do.
    Write-Host '  --- 5: the feature closeout asked for ---'
    Add-FixtureLockAndClaim -Root $root
    $null = & git -C $root add -A 2>&1; $null = & git -C $root commit -q -m 'iteration 001 closed' 2>&1
    Add-FixtureMergeToMain -Root $root
    Assert-True ((Test-FixtureLock -Root $root) -and (Test-FixtureClaim -Root $root)) 'fixture: a session lock and a feature claim for 001-fixture, and the branch merged to main'
    $sync5 = Invoke-Sync -Root $root -Boundary 'feature-closeout' -Iteration ''
    if ($sync5.ExitCode -ne 0) { Write-Host ('  sync output: ' + $sync5.Output) }
    Assert-True ($sync5.ExitCode -eq 0) 'the feature-closeout sync exits 0'
    $pending5 = Read-Pending -Root $root
    Assert-True ($null -ne $pending5 -and [string]$pending5.to_boundary -eq 'feature-closeout') 'and the feature-closeout decision is pending'
    Assert-True ((Read-SessionActive -Root $root) -eq $true) 'the session is still active while the decision is pending'
    Assert-True ((Read-FrontmatterActive -Path (Join-Path $root '.specrew/last-start-prompt.md')) -eq 'true') 'and the launch prompt says so'
    Assert-True ((Get-Content -LiteralPath (Join-Path $root '.squad/identity/now.md') -Raw -Encoding UTF8) -notmatch 'No active feature') 'the identity file does not say "No active feature"'
    Assert-True ((Read-PointerFeature -Root $root) -eq 'specs/001-fixture') 'the active-feature pointer still names the feature'
    Assert-True (Test-FixtureLock -Root $root) 'the session lock is still held'
    Assert-True (Test-FixtureClaim -Root $root) 'the feature claim is still there'
    $resolved5 = Resolve-SpecrewActiveFeature -ProjectRoot $root
    Assert-True ([string]$resolved5.feature_ref -eq '001-fixture') ('readers still resolve the feature as active (by: {0})' -f $resolved5.resolved_by)
    Assert-True (@(Invoke-ClosureRule -Root $root).Count -eq 0) ('the validator does not call the pending state a contradiction (got: {0})' -f (@(Invoke-ClosureRule -Root $root) -join ' | '))

    Write-Host '  --- 6: the human''s feature-closeout approval ---'
    $verdict6 = Add-SpecrewBoundaryAuthorization -ProjectRoot $root -CurrentBoundary 'iteration-closeout' -AuthorizedBoundary 'feature-closeout' -AuthorizingHuman 'Fixture Human' -VerdictText 'approved for feature-closeout' -EvidenceSource 'hook-captured-from-transcript' 2>$null
    Assert-True ($null -ne $verdict6 -and [string]$verdict6.AuthorizedBoundary -ceq 'feature-closeout') 'the approval is recorded'
    Assert-True ((Read-SessionActive -Root $root) -eq $false) 'the session is now inactive'
    Assert-True ((Read-FrontmatterActive -Path (Join-Path $root '.specrew/last-start-prompt.md')) -eq 'false') 'and the launch prompt''s state says so'
    $promptText = Get-Content -LiteralPath (Join-Path $root '.specrew/last-start-prompt.md') -Raw -Encoding UTF8
    Assert-True ($promptText -match '- No active feature\.' -and $promptText -match 'Last feature: 001-fixture') 'and its text says no feature is active'
    $identityText = Get-Content -LiteralPath (Join-Path $root '.squad/identity/now.md') -Raw -Encoding UTF8
    Assert-True ($identityText -match '(?m)^session_state_active: false' -and $identityText -match '(?m)^focus_area: "No active feature"') 'the identity file''s state says no feature is active'
    Assert-True ($identityText -match 'No active feature\. Last completed: Feature 001 \(001-fixture\)') 'and so does its text'
    Assert-True ([string]::IsNullOrEmpty((Read-PointerFeature -Root $root))) 'the active-feature pointer is cleared'
    Assert-True (-not (Test-FixtureLock -Root $root)) 'the session lock is released'
    Assert-True (-not (Test-FixtureClaim -Root $root)) 'the feature claim is removed (the branch is merged)'
    Assert-True (@(Invoke-ClosureRule -Root $root).Count -eq 0) 'the validator sees a consistent closed state'

    Write-Host '  --- 7: the rule still catches the real contradiction ---'
    $ctxPath = Join-Path $root '.specrew/start-context.json'
    $ctx7 = Get-Content -LiteralPath $ctxPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 20
    $ctx7['session_state']['active'] = $true
    [IO.File]::WriteAllText($ctxPath, ($ctx7 | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
    Assert-True (@(Invoke-ClosureRule -Root $root).Count -ge 1) 'active after an approved feature closeout is still refused'
}
finally {
    $env:SPECREW_MODULE_PATH = $priorModulePath
    foreach ($r in $roots) { if (Test-Path -LiteralPath $r) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } }
}

Write-Host '  --- the repository''s own stores ---'
$guardAfter = Get-GuardHashes
foreach ($rel in $guarded) { Assert-True ($guardBefore[$rel] -eq $guardAfter[$rel]) ('unchanged: ' + $rel) }

if ($script:Failures -gt 0) { Write-Host ("FAILED: {0}" -f $script:Failures); exit 1 }
Write-Host 'closeout-records-on-approval: all assertions pass'
exit 0
