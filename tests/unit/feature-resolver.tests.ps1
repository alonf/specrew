#requires -Version 7.0
# Feature 202 T010 (FR-017, FR-018, SC-006, DA-5; B4F-105): one answer to "what are we working on".
#
# Resolve-SpecrewActiveFeature decides in the agreed order and names its source: the work in flight (a pending
# decision, the active session unless its feature is closed, an open design workshop), then the pointer written for
# this branch, then the branch name as a hint, then a pointer that records no branch. Two features in flight ask.
# Status (the real `where` dashboard) and the first-prompt orientation both ask it, so they always agree.
#
# Cases (each a constructed project state):
#   1. B4F-105: 199 closed at feature-closeout, pointer empty, branch 201 -> 201 (branch hint); status no longer
#      shows 001 (Shipped).
#   2. 199 on branch 201: the session is in flight on 199 -> 199, not the branch, not a stale pointer to 201.
#   3. The pointer written for this branch decides when nothing is in flight.
#   4. A pointer written on another branch does not; the branch hint does.
#   5. An open design workshop (spec still the unauthored stub) is in flight; a shipped feature's stale controller
#      is not.
#   6. Two features in flight: nothing is chosen, and both surfaces ask which one.
#   7. A pending decision decides, and names itself.
#   8. The writers: the pointer records its branch and keeps Spec Kit's keys; session_state records its branch;
#      both governed writers call the one pointer writer.
#
# RED: run with SPECREW_T010_ROOT pointing at a pre-T010 module tree; cases 1, 2 and 6 fail there.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$moduleRoot = if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_T010_ROOT)) { $env:SPECREW_T010_ROOT } else { $repoRoot }
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
$savedModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $moduleRoot
$script:failCount = 0

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }
function Write-Utf8 { param([string]$Path, [string]$Text) New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null; [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false)) }

$authoredSpec = "# Feature Specification: authored`n`n**Status**: approved`n"
$stubSpec = "<!-- specrew:spec-not-yet-authored -->`n# Feature Specification: stub`n"

function New-State {
    # One constructed project: a git repo on $Branch, feature folders, and optional lifecycle state and pointer.
    param(
        [string]$Branch,
        [hashtable]$Features,          # name -> 'authored' | 'stub'
        [hashtable]$Session,           # session_state fields, or $null
        [string]$LastAuthorized,
        $Pointer,                      # hashtable written as .specify/feature.json, or $null
        [string[]]$OpenWorkshops = @() # features whose controller awaits agenda confirmation
    )
    $root = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ("t010-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime') | Out-Null
    foreach ($name in $Features.Keys) {
        Write-Utf8 (Join-Path $root "specs/$name/spec.md") $(if ($Features[$name] -eq 'stub') { $stubSpec } else { $authoredSpec })
    }
    foreach ($name in $OpenWorkshops) {
        Write-Utf8 (Join-Path $root "specs/$name/lens-applicability.json") (([ordered]@{ agenda_contract = 'complete-coverage-v1'; agenda_status = 'pending-confirmation'; selected = @(); workshop = [ordered]@{} }) | ConvertTo-Json -Depth 5)
    }
    Write-Utf8 (Join-Path $root '.gitignore') ".specrew/`n"
    & git -C $root init -q -b $Branch
    & git -C $root config user.email 't@t'; & git -C $root config user.name 't'
    & git -C $root add -A; & git -C $root commit -q -m fixture
    if ($null -ne $Session) {
        $context = [ordered]@{
            schema = 'v2'
            session_state = $Session
            boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = $LastAuthorized; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
        }
        Write-Utf8 (Join-Path $root '.specrew/start-context.json') ($context | ConvertTo-Json -Depth 10)
    }
    if ($null -ne $Pointer) { Write-Utf8 (Join-Path $root '.specify/feature.json') ($Pointer | ConvertTo-Json) }
    return $root
}

function Get-StatusView {
    # The real `specrew where` (status is the same command): the feature it shows and its "Chosen" line.
    param([string]$Root)
    $out = (@(& pwsh -NoProfile -NonInteractive -File (Join-Path $moduleRoot 'scripts\specrew-where.ps1') --project-path $Root 2>&1) -join "`n")
    $feature = [regex]::Match($out, '(?m)^Feature: \S+ F-(\d+) ')
    $chosen = [regex]::Match($out, '(?m)^Chosen: (.+)$')
    return [pscustomobject]@{ FeatureNumber = $(if ($feature.Success) { $feature.Groups[1].Value } else { '' }); Chosen = $(if ($chosen.Success) { $chosen.Groups[1].Value.Trim() } else { '' }); Raw = $out }
}

function Get-OrientationView {
    # The first-prompt orientation, as the dispatcher would request it.
    param([string]$Root)
    $record = [ordered]@{ schema = 'specrew-turn-record/v1'; event = 'UserPromptSubmit'; host = 'claude'; session_id = ('o-' + [guid]::NewGuid().ToString('N').Substring(0, 6)); safe_session_id = ''; source = $null }
    $record.safe_session_id = $record.session_id
    $encoded = [Convert]::ToBase64String([Text.UTF8Encoding]::new($false).GetBytes(($record | ConvertTo-Json -Compress)))
    Push-Location -LiteralPath $Root
    try { $out = (@(& pwsh -NoProfile -NonInteractive -File (Join-Path $moduleRoot 'extensions\specrew-speckit\scripts\specrew-bootstrap-provider.ps1') --turn-record $encoded --host-kind claude --source-event UserPromptSubmit --project-root $Root 2>&1) -join "`n") }
    finally { Pop-Location }
    $feature = [regex]::Match($out, '(?m)^- Where things stand: feature (\S+?)[;. ]')
    $chosen = [regex]::Match($out, '(?m)^- Chosen: (.+)$')
    return [pscustomobject]@{ Feature = $(if ($feature.Success) { $feature.Groups[1].Value } else { '' }); Chosen = $(if ($chosen.Success) { $chosen.Groups[1].Value.Trim() } else { '' }); Raw = $out }
}

function Test-State {
    # Resolver, status and orientation must name the same feature and the same source.
    param([string]$Label, [string]$Root, [string]$ExpectFeature, [string]$ExpectSource)
    $resolution = Resolve-SpecrewActiveFeature -ProjectRoot $Root
    Assert-True ([string]$resolution.feature_ref -ceq $ExpectFeature -and [string]$resolution.resolved_by -ceq $ExpectSource) ("{0}: the resolver chooses '{1}' by {2} (got '{3}' by {4})" -f $Label, $ExpectFeature, $ExpectSource, $resolution.feature_ref, $resolution.resolved_by)
    $disclosure = Get-SpecrewActiveFeatureDisclosure -Resolution $resolution
    $status = Get-StatusView -Root $Root
    $orientation = Get-OrientationView -Root $Root
    $expectNumber = if ([string]::IsNullOrWhiteSpace($ExpectFeature)) { '' } else { ($ExpectFeature -split '-', 2)[0] }
    Assert-True ($status.FeatureNumber -ceq $expectNumber) ("{0}: status shows feature '{1}' (got '{2}')" -f $Label, $expectNumber, $status.FeatureNumber)
    Assert-True ($orientation.Feature -ceq $ExpectFeature) ("{0}: the orientation names '{1}' (got '{2}')" -f $Label, $ExpectFeature, $orientation.Feature)
    Assert-True ($status.Chosen -ceq $disclosure -and $orientation.Chosen -ceq $disclosure) ("{0}: both name the source: '{1}'" -f $Label, $disclosure)
    # Co-review round 4 (202, FR-018 / SC-006): `specrew start` with no feature named resumes the same feature, and the
    # resume block it feeds describes it - not a feature the pointer named on another branch.
    $startPath = Get-StartAutoChoice -Root $Root
    $startRef = if ([string]::IsNullOrWhiteSpace([string]$startPath)) { '' } else { Split-Path -Leaf $startPath }
    Assert-True ($startRef -ceq $ExpectFeature) ("{0}: specrew start resumes '{1}' (got '{2}')" -f $Label, $ExpectFeature, $startRef)
    if (-not [string]::IsNullOrWhiteSpace($ExpectFeature) -and -not [string]::IsNullOrWhiteSpace([string]$startPath)) {
        $block = [string](Get-CoordinatorResumePromptBlock -ProjectRoot $Root -ResolvedFeaturePath $startPath -SessionState $null)
        Assert-True ($block -match [regex]::Escape("feature $ExpectFeature")) ("{0}: the specrew start resume block describes '{1}'" -f $Label, $ExpectFeature)
    }
}

# `specrew start`'s automatic feature choice, lifted from the script itself. Code from before co-review round 4 has no
# Resolve-SpecrewStartAutoFeaturePath and read the pointer with Resolve-FeatureDirectory 'auto'; that is the RED.
$startAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path $moduleRoot 'scripts\specrew-start.ps1'), [ref]$null, [ref]$null)
foreach ($fn in @($startAst.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Resolve-SpecrewStartAutoFeaturePath', 'Resolve-FeatureDirectory') }, $false))) {
    . ([scriptblock]::Create($fn.Extent.Text))
}
. (Join-Path $moduleRoot 'scripts\internal\coordinator-resume.ps1')
function Get-StartAutoChoice {
    param([string]$Root)
    if (Get-Command Resolve-SpecrewStartAutoFeaturePath -ErrorAction SilentlyContinue) { return (Resolve-SpecrewStartAutoFeaturePath -Root $Root) }
    try { return (Resolve-FeatureDirectory -Root $Root -ResumeFeature 'auto') } catch { return $null }
}

$roots = [System.Collections.Generic.List[string]]::new()
try {
    Write-Host 'Case 1: B4F-105 - a closed feature, an empty pointer, branch 201'
    $r1 = New-State -Branch '201-first-run-experience' -Features @{ '001-specrew-product' = 'authored'; '199-beta3-stabilization' = 'authored'; '201-first-run-experience' = 'authored' } `
        -Session ([ordered]@{ active = $false; boundary_type = 'feature-closeout'; feature_ref = '199-beta3-stabilization' }) -LastAuthorized 'feature-closeout' -Pointer @{ feature_directory = ''; schema = 'v1' }
    $roots.Add($r1)
    Test-State -Label 'B4F-105' -Root $r1 -ExpectFeature '201-first-run-experience' -ExpectSource 'branch-hint'

    Write-Host 'Case 2: 199 on branch 201 - the work in flight decides, not the branch or a stale pointer'
    $r2 = New-State -Branch '201-first-run-experience' -Features @{ '199-beta3-stabilization' = 'authored'; '201-first-run-experience' = 'authored' } `
        -Session ([ordered]@{ active = $true; boundary_type = 'implement'; feature_ref = '199-beta3-stabilization' }) -LastAuthorized 'before-implement' -Pointer @{ feature_directory = 'specs/201-first-run-experience'; schema = 'v1' }
    $roots.Add($r2)
    Test-State -Label '199-on-201' -Root $r2 -ExpectFeature '199-beta3-stabilization' -ExpectSource 'active-session'

    Write-Host 'Case 3: the pointer written for this branch'
    $r3 = New-State -Branch 'main' -Features @{ '005-alpha' = 'authored'; '006-beta' = 'authored' } -Session $null -Pointer @{ feature_directory = 'specs/005-alpha'; branch = 'main'; schema = 'v1' }
    $roots.Add($r3)
    Test-State -Label 'pointer for this branch' -Root $r3 -ExpectFeature '005-alpha' -ExpectSource 'pointer'

    Write-Host 'Case 4: a pointer written on another branch does not decide'
    $r4 = New-State -Branch '006-beta' -Features @{ '005-alpha' = 'authored'; '006-beta' = 'authored' } -Session $null -Pointer @{ feature_directory = 'specs/005-alpha'; branch = '005-alpha'; schema = 'v1' }
    $roots.Add($r4)
    Test-State -Label 'pointer from another branch' -Root $r4 -ExpectFeature '006-beta' -ExpectSource 'branch-hint'

    Write-Host 'Case 5: an open design workshop is in flight; a shipped feature''s stale controller is not'
    $r5 = New-State -Branch 'main' -Features @{ '201-first-run-experience' = 'authored'; '207-new-thing' = 'stub' } -Session $null -Pointer $null -OpenWorkshops @('201-first-run-experience', '207-new-thing')
    $roots.Add($r5)
    Test-State -Label 'open workshop' -Root $r5 -ExpectFeature '207-new-thing' -ExpectSource 'open-workshop'

    Write-Host 'Case 6: two features in flight - nothing is chosen, both surfaces ask'
    $r6 = New-State -Branch 'main' -Features @{ '199-beta3-stabilization' = 'authored'; '207-new-thing' = 'stub' } `
        -Session ([ordered]@{ active = $true; boundary_type = 'implement'; feature_ref = '199-beta3-stabilization' }) -LastAuthorized 'before-implement' -Pointer $null -OpenWorkshops @('207-new-thing')
    $roots.Add($r6)
    Test-State -Label 'ambiguous' -Root $r6 -ExpectFeature '' -ExpectSource 'ambiguous'
    Assert-True ((Get-SpecrewActiveFeatureDisclosure -Resolution (Resolve-SpecrewActiveFeature -ProjectRoot $r6)) -match 'which one are we working on\?') 'ambiguous: the disclosure asks'

    Write-Host 'Case 7: a pending decision decides'
    $r7 = New-State -Branch 'main' -Features @{ '208-pending' = 'authored'; '209-other' = 'stub' } `
        -Session ([ordered]@{ active = $true; boundary_type = 'plan'; feature_ref = '208-pending' }) -LastAuthorized 'specify' -Pointer $null -OpenWorkshops @('209-other')
    $context7 = Get-Content -LiteralPath (Join-Path $r7 '.specrew/start-context.json') -Raw | ConvertFrom-Json -AsHashtable
    $context7['boundary_enforcement']['pending_crossing'] = [ordered]@{ crossing_id = 'cx-1'; from_boundary = 'specify'; to_boundary = 'plan'; feature_ref = '208-pending' }
    Write-Utf8 (Join-Path $r7 '.specrew/start-context.json') ($context7 | ConvertTo-Json -Depth 10)
    $roots.Add($r7)
    $resolution7 = Resolve-SpecrewActiveFeature -ProjectRoot $r7
    Assert-True ([string]$resolution7.feature_ref -eq '208-pending' -and [string]$resolution7.resolved_by -eq 'pending-decision') 'pending decision: chosen over an open workshop, and named as the source'

    Write-Host 'Case 8: the writers'
    $r8 = New-State -Branch '210-writer' -Features @{ '210-writer' = 'stub' } -Session $null -Pointer @{ feature_directory = ''; schema = 'v1'; speckit_key = 'kept' }
    $roots.Add($r8)
    Assert-True (Set-SpecrewActiveFeaturePointer -ProjectRoot $r8 -FeatureRef '210-writer') 'the pointer writer reports success'
    $pointer8 = Get-Content -LiteralPath (Join-Path $r8 '.specify/feature.json') -Raw | ConvertFrom-Json
    Assert-True ([string]$pointer8.feature_directory -eq 'specs/210-writer' -and [string]$pointer8.branch -eq '210-writer' -and [string]$pointer8.speckit_key -eq 'kept') 'the pointer records the feature and its branch, and keeps keys other writers own'
    Assert-True ((Resolve-SpecrewActiveFeature -ProjectRoot $r8).resolved_by -eq 'pointer') 'a freshly written pointer decides on its own branch'
    $scaffold = Get-Content -LiteralPath (Join-Path $moduleRoot 'extensions\specrew-speckit\scripts\create-governed-feature.ps1') -Raw
    $sync = Get-Content -LiteralPath (Join-Path $moduleRoot 'scripts\internal\sync-boundary-state.ps1') -Raw
    Assert-True ($scaffold -match 'Set-SpecrewActiveFeaturePointer -ProjectRoot') 'create-governed-feature writes the pointer through the one writer'
    Assert-True ($sync -match 'Set-SpecrewActiveFeaturePointer -ProjectRoot') 'the boundary sync writes the pointer through the one writer'
    # session_state records its branch: Update-SpecrewStartContext, lifted from the sync script and run.
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $moduleRoot 'scripts\internal\sync-boundary-state.ps1'), [ref]$null, [ref]$null)
    foreach ($name in 'Write-FileAtomically', 'Update-SpecrewStartContext') {
        $fn = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $true)
        if ($null -eq $fn) { Write-Fail "could not lift $name from the sync script"; continue }
        . ([scriptblock]::Create($fn.Extent.Text))
    }
    if (Get-Command Update-SpecrewStartContext -ErrorAction SilentlyContinue) {
        $ctxPath = Join-Path $r8 '.specrew/start-context.json'
        try { Update-SpecrewStartContext -Path $ctxPath -SessionState ([pscustomobject]@{ active = 'true'; boundary_type = 'specify'; feature_ref = '210-writer'; feature_path = 'specs/210-writer'; iteration_number = $null; task_id = $null; auth_commit_hash = $null; recorded_at = '2026-10-14T00:00:00Z' }) } catch { Write-Fail ("Update-SpecrewStartContext threw: {0}" -f $_.Exception.Message) }
        $written = Get-Content -LiteralPath $ctxPath -Raw | ConvertFrom-Json
        Assert-True ($written.session_state.PSObject.Properties['branch'] -and [string]$written.session_state.branch -eq '210-writer') 'session_state records the branch it was written on'
    }
}
finally {
    foreach ($r in $roots) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue }
    $env:SPECREW_MODULE_PATH = $savedModulePath
}
if ($script:failCount -gt 0) { throw ("feature-resolver: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'feature-resolver: all assertions passed' -ForegroundColor Green
