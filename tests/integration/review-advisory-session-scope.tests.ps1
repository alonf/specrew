# FIX 2 ITEM (c) FOR THE REVIEW ADVISORY (PRED-BETA4-024): "these files have not been reviewed yet" is said to
# the session that wrote something, not to every session that stops in the project.
#
# The co-review navigator's campaign stop block had no session in it: it fired on every Stop while the tree's
# digest was unreviewed, and a read-only reviewer session received it seventeen consecutive times after
# declaring conversational each turn. The conformance provider (order 40) already judges THIS session's
# declaration at Stop; it now leaves that judgment beside its turn counter (`turn-material.json`), and the
# navigator provider (order 50, the same `--session-id` the dispatcher passes to every provider, the same
# state-root resolver) reads it: quiet for conversational or absent-and-not-material; today's block for
# in-flight, boundary, absent-with-material, no judgment, a judgment that is not this Stop's, or a pause.
#
# The navigator LOGIC is stubbed (a worktree-navigator.ps1 that always returns the review-required block) in
# a temp module tree the provider copy resolves through, so what is under test is the provider's gate and the
# conformance provider's judgment - the two halves of the handshake - not the campaign engine.
# -MutateUnscoped replaces the provider's gate with `if ($false)`: the read-only session gets the block.

param([switch] $MutateUnscoped)

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$priorModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot   # the conformance provider resolves its bootstrap dir through this (census 34518281283)
$store = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/turn-end-store.ps1'
$conformance = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'
$declarer = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/declare-turn-end.ps1'
$providerSource = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1'

Write-Host 'review-advisory-session-scope'
Write-Host '  --- preconditions ---'
foreach ($f in @($store, $conformance, $declarer, $providerSource)) { Assert-True (Test-Path -LiteralPath $f -PathType Leaf) ('present: ' + (Split-Path -Leaf $f)) }
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE'; exit 1 }
. $store

# ---- the temp module tree: a copy of the provider beside the store it dot-sources, over a STUB navigator ----
$tree = Join-Path ([IO.Path]::GetTempPath()) ('rass-tree-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$treeScripts = Join-Path $tree 'extensions/specrew-speckit/scripts'
New-Item -ItemType Directory -Path $treeScripts -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tree 'scripts/internal/continuous-co-review') -Force | Out-Null
foreach ($f in @('turn-end-store.ps1', 'timestamp-read.ps1')) { Copy-Item -LiteralPath (Join-Path $repoRoot ('extensions/specrew-speckit/scripts/' + $f)) -Destination (Join-Path $treeScripts $f) -Force }
$providerText = Get-Content -LiteralPath $providerSource -Raw -Encoding UTF8
if ($MutateUnscoped) {
    $gate = 'if ($isStop -and -not [string]::IsNullOrWhiteSpace([string]$decision.stop_block) -and'
    if (([regex]::Matches($providerText, [regex]::Escape($gate))).Count -ne 1) { Write-Host '  FAIL: the mutation site is not unique'; exit 1 }
    $providerText = $providerText.Replace($gate, 'if ($false -and')
    Write-Host '  (MUTATION ACTIVE: the provider''s session gate is gone)'
}
$provider = Join-Path $treeScripts 'specrew-co-review-navigator-provider.ps1'
[IO.File]::WriteAllText($provider, $providerText, [Text.UTF8Encoding]::new($false))
# The stub: every Stop is `review-required`, unless the project carries a marker file asking for a pause.
$stub = @'
function Invoke-ContinuousCoReviewWorktreeNavigator {
    param([Parameter(Mandatory)][string]$RepoRoot, [string]$TrunkName = '', [switch]$SessionStart, [string]$CodeWriterHost, [string]$TranscriptPath, [int]$TimeoutSeconds = 900)
    $route = if (Test-Path -LiteralPath (Join-Path $RepoRoot '.specrew/runtime/stub-pause-pending')) { 'pause-pending' } else { 'review-required' }
    $d = [pscustomobject]@{ action = 'no-op'; reason = ('stub:' + $route); engine = 'stub'; fired_run_id = $null; fired_tree_id = $null; stop_block = ('Specrew review - these files have not been reviewed yet (' + $route + ').'); inject_notes = @() }
    $d | Add-Member -NotePropertyName route -NotePropertyValue $route -Force
    return $d
}
'@
[IO.File]::WriteAllText((Join-Path $tree 'scripts/internal/continuous-co-review/worktree-navigator.ps1'), $stub, [Text.UTF8Encoding]::new($false))

function Invoke-Navigator {
    param([string]$ProjectRoot, [string]$SessionId)
    Push-Location $ProjectRoot
    try {
        $a = @('-NoProfile', '-File', $provider, '--host-kind', 'claude', '--source-event', 'Stop')
        if (-not [string]::IsNullOrWhiteSpace($SessionId)) { $a += @('--session-id', $SessionId) }
        $out = & pwsh @a 2>&1 | Out-String
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = $out; Blocked = ($out -match '<<<SPECREW-STOP-BLOCK>>>') }
    }
    finally { Pop-Location }
}
function Invoke-Conformance {
    param([string]$ProjectRoot, [string]$Event, [string]$SessionId)
    Push-Location $ProjectRoot
    try {
        $out = & pwsh -NoProfile -File $conformance --host-kind claude --source-event $Event --session-id $SessionId 2>&1 | Out-String
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = $out; Blocked = ($out -match '<<<SPECREW-STOP-BLOCK>>>') }
    }
    finally { Pop-Location }
}
function Invoke-Declare {
    param([string]$ProjectRoot, [string]$Kind, [string]$Token, [string]$Pending = '')
    $a = @('-NoProfile', '-File', $declarer, '-Kind', $Kind, '-Summary', 'fixture turn', '-ProjectRoot', $ProjectRoot, '-Token', $Token, '-AsJson')
    if (-not [string]::IsNullOrWhiteSpace($Pending)) { $a += @('-Pending', $Pending) }
    $out = & pwsh @a 2>&1 | Out-String
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = $out }
}
function Read-NavigatorJournal { param([string]$Root) $p = Join-Path $Root '.specrew/runtime/co-review-navigator-journal.jsonl'; if (Test-Path -LiteralPath $p) { return @(Get-Content -LiteralPath $p) } else { return @() } }
function New-Root {
    $r = Join-Path ([IO.Path]::GetTempPath()) ('rass-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    New-Item -ItemType Directory -Path (Join-Path $r '.specrew/runtime') -Force | Out-Null
    return $r
}

$roots = New-Object System.Collections.Generic.List[string]
try {
    # ============ Part 2: the field shape, end to end - conformance judges, the navigator reads ============
    Write-Host '  --- the field shape: a read-only session declares conversational; the same project''s working session declares in-flight ---'
    $root = New-Root; $roots.Add($root) | Out-Null
    $pathsA = Get-SpecrewTurnEndPaths -ProjectRoot $root -HostKind 'claude' -SessionId 'reviewer'
    $pathsB = Get-SpecrewTurnEndPaths -ProjectRoot $root -HostKind 'claude' -SessionId 'worker'
    $null = Invoke-Conformance -ProjectRoot $root -Event 'UserPromptSubmit' -SessionId 'reviewer'
    $tokenA = Read-SpecrewTurnToken -StateRoot $pathsA.StateRoot
    Assert-True (-not [string]::IsNullOrWhiteSpace($tokenA)) 'the reviewer session''s turn started and it holds a token'
    $decl = Invoke-Declare -ProjectRoot $root -Kind 'conversational' -Token $tokenA
    Assert-True ($decl.Code -eq 0) 'the reviewer session declares conversational with its token'
    $stopA = Invoke-Conformance -ProjectRoot $root -Event 'Stop' -SessionId 'reviewer'
    Assert-True ($stopA.Code -eq 0 -and -not $stopA.Blocked) 'the conformance provider accepts the declaration (no block)'
    $verdictA = Read-SpecrewTurnMaterialVerdict -StateRoot $pathsA.StateRoot
    Assert-True ($null -ne $verdictA -and [string]$verdictA.declaration_kind -ceq 'conversational' -and [string]$verdictA.turn_id -ceq 'turn-1' -and -not [bool]$verdictA.material) ('and leaves its judgment beside the counter: {0}' -f $(if ($null -ne $verdictA) { $verdictA | ConvertTo-Json -Compress } else { '(none)' }))
    Assert-True ((Get-SpecrewTurnId -StateRoot $pathsA.StateRoot) -ceq 'turn-2') 'the counter stepped after the judgment was written'
    $navA = Invoke-Navigator -ProjectRoot $root -SessionId 'reviewer'
    Assert-True ($navA.Code -eq 0 -and -not $navA.Blocked) ('the navigator, running after, says NOTHING to the reviewer session (out: {0})' -f ($navA.Out -replace '\s+', ' ').Trim())
    $journalA = @(Read-NavigatorJournal -Root $root)
    Assert-True (($journalA -join "`n") -match '"action":"quiet".*session declared conversational') 'and its journal says why: quiet, the session declared conversational'

    $null = Invoke-Conformance -ProjectRoot $root -Event 'UserPromptSubmit' -SessionId 'worker'
    $tokenB = Read-SpecrewTurnToken -StateRoot $pathsB.StateRoot
    $declB = Invoke-Declare -ProjectRoot $root -Kind 'in-flight' -Token $tokenB -Pending 'the census dispatch'
    Assert-True ($declB.Code -eq 0) 'the working session declares in-flight with its own token'
    $stopB = Invoke-Conformance -ProjectRoot $root -Event 'Stop' -SessionId 'worker'
    $verdictB = Read-SpecrewTurnMaterialVerdict -StateRoot $pathsB.StateRoot
    Assert-True ($null -ne $verdictB -and [string]$verdictB.declaration_kind -ceq 'in-flight') 'the worker''s judgment reads in-flight'
    $navB = Invoke-Navigator -ProjectRoot $root -SessionId 'worker'
    Assert-True ($navB.Blocked -and $navB.Out -match 'have not been reviewed yet') 'the navigator BLOCKS the working session - the advisory goes to the session that wrote something'
    $navA2 = Invoke-Navigator -ProjectRoot $root -SessionId 'reviewer'
    Assert-True (-not $navA2.Blocked) 'and still says nothing to the reviewer session in the same project, same tree'

    # ============ Part 3: the block still fires where it should ==================================
    Write-Host '  --- the block still fires where it should ---'
    $r3 = New-Root; $roots.Add($r3) | Out-Null
    $none = Invoke-Navigator -ProjectRoot $r3 -SessionId 'nobody'
    Assert-True ($none.Blocked) 'no judgment on disk (a host that never ran conformance): the block, as today'
    $p3 = Get-SpecrewTurnEndPaths -ProjectRoot $r3 -HostKind 'claude' -SessionId 'S'
    $null = Write-SpecrewTurnMaterialVerdict -StateRoot $p3.StateRoot -TurnId 'turn-1' -DeclarationKind '' -Material $true
    Assert-True ((Invoke-Navigator -ProjectRoot $r3 -SessionId 'S').Blocked) 'declared nothing, judged material: the block'
    $null = Write-SpecrewTurnMaterialVerdict -StateRoot $p3.StateRoot -TurnId 'turn-1' -DeclarationKind '' -Material $false
    Assert-True (-not (Invoke-Navigator -ProjectRoot $r3 -SessionId 'S').Blocked) 'declared nothing, judged NOT material: quiet - a read-only session on a host without declarations'
    $null = Write-SpecrewTurnMaterialVerdict -StateRoot $p3.StateRoot -TurnId 'turn-1' -DeclarationKind 'boundary' -Material $true
    Assert-True ((Invoke-Navigator -ProjectRoot $r3 -SessionId 'S').Blocked) 'declared boundary: the block'
    $null = Write-SpecrewTurnMaterialVerdict -StateRoot $p3.StateRoot -TurnId 'turn-1' -DeclarationKind 'conversational' -Material $false
    New-Item -ItemType File -Path (Join-Path $r3 '.specrew/runtime/stub-pause-pending') -Force | Out-Null
    Assert-True ((Invoke-Navigator -ProjectRoot $r3 -SessionId 'S').Blocked) 'a pause-pending route blocks even the conversational session - a pause is the human''s decision owed, not a file attribution'
    Remove-Item -LiteralPath (Join-Path $r3 '.specrew/runtime/stub-pause-pending') -Force
    Assert-True (-not (Invoke-Navigator -ProjectRoot $r3 -SessionId 'S').Blocked) '(control) the same conversational judgment is quiet again once the pause is gone'
    $null = Write-SpecrewTurnMaterialVerdict -StateRoot $p3.StateRoot -TurnId 'turn-7' -DeclarationKind 'conversational' -Material $false
    Assert-True ((Invoke-Navigator -ProjectRoot $r3 -SessionId 'S').Blocked) 'a judgment whose turn id is not this Stop''s (turn-7 against a counter at 1): the block - not this Stop''s judgment'
    $stalePath = Get-SpecrewTurnMaterialVerdictPath -StateRoot $p3.StateRoot
    [IO.File]::WriteAllText($stalePath, (([ordered]@{ schema_version = '1.0'; turn_id = 'turn-1'; declaration_kind = 'conversational'; material = $false; judged_at = [DateTimeOffset]::UtcNow.AddMinutes(-10).ToString('o') } | ConvertTo-Json -Compress)), [Text.UTF8Encoding]::new($false))
    Assert-True ((Invoke-Navigator -ProjectRoot $r3 -SessionId 'S').Blocked) 'a judgment ten minutes old: the block - freshness fails toward the advisory'
    $unanchored = Invoke-Navigator -ProjectRoot $r3 -SessionId ''
    Assert-True ($unanchored.Blocked) 'no session id at all (a host that names none): the block, as today'
}
finally {
    foreach ($r in $roots) { if (Test-Path -LiteralPath $r) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } }
    if (Test-Path -LiteralPath $tree) { Remove-Item -LiteralPath $tree -Recurse -Force -ErrorAction SilentlyContinue }
    if ($null -eq $priorModulePath) { Remove-Item Env:\SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $priorModulePath }
}

if ($script:Failures -gt 0) {
    Write-Host ("review-advisory-session-scope: {0} FAILED" -f $script:Failures)
    exit 1
}
Write-Host 'review-advisory-session-scope: all cases passed'
exit 0
