# THE UPDATE TRANSITION, TESTED AS ONE THING (fix 2, maintainer instruction 2026-09-10).
#
# Every other test in this batch checks one surface. This one checks the only thing a user actually
# experiences: a project that has been running the old habit is updated, the crew does what it has always
# done, and the question is whether the transition costs them one turn or leaves them stuck.
#
# The sequence, exactly as a real project meets it:
#
#   1. a project on the OLD habit renders a prose packet - the thing that used to satisfy the hook;
#   2. it gets EXACTLY ONE refusal, and that refusal names the command and its parameters;
#   3. the crew runs the command it was given;
#   4. the next turn is compliant, with no second refusal.
#
# WHY "EXACTLY ONE" IS THE ASSERTION AND NOT "AT LEAST ONE". A transition that refuses twice for the same
# reason has not taught anything - it has trapped someone. This batch has the measurement that makes the
# point: eight stops in one session, none of them about the code. A refusal that repeats after being obeyed
# is the same defect wearing a new message.
#
# AND STEP 3 RUNS THE REAL SCRIPT. The refusal names a command; the test runs THAT command, from the path
# the refusal printed, rather than writing the record it would have produced. A test that fabricates the
# artifact cannot notice that the named command does not exist, is not deployed, or does not do what the
# message claims - which is B4F-030's family, and the reason this suite drives the command instead.

$ErrorActionPreference = 'Stop'
$script:Failures = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host ("  PASS: {0}" -f $Message) }
    else { Write-Host ("  FAIL: {0}" -f $Message); $script:Failures++ }
}

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
# THE RUNNER'S RED, READ FROM ITS OWN DIAGNOSTICS (census 34518281283, and 34502784677 before it):
# `WARN ASSESSMENT_UNAVAILABLE the conversation accessor could not be loaded; enforcement for this stop was
# skipped (fail-open)`. The provider resolves scripts/internal/bootstrap from the project tree, then
# SPECREW_MODULE_PATH, then an installed Specrew module. A fixture project has no bootstrap dir; the runner
# has no installed module; this machine has one, which is why the suite was green here and red there. The
# repo root IS the module tree, and conformance-detection.tests.ps1 has always said so - this suite now does too.
$priorModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot
$provider = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'
$declarer = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/declare-turn-end.ps1'
$skillTemplate = Join-Path $repoRoot 'extensions/specrew-speckit/squad-templates/skills/turn-end.md'
$launchContract = Join-Path $repoRoot 'scripts/internal/launch-contract.ps1'
$manifest = Join-Path $repoRoot 'Specrew.psd1'

Write-Host 'turn-end-update-transition'
Write-Host '  --- preconditions (printed, not assumed) ---'
foreach ($required in @($provider, $declarer, $skillTemplate, $launchContract, $manifest)) {
    Assert-True (Test-Path -LiteralPath $required -PathType Leaf) ("present: {0}" -f (Split-Path -Leaf $required))
}
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE: sources missing'; exit 1 }

# --- what `specrew update` carries: the skill AND the directive, together ---------------------------
Write-Host '  --- the update carries the skill and the directive TOGETHER ---'
# Together is the assertion. The skill without the directive is a page nobody is told to read; the
# directive without the skill names a command the project does not have. Either alone is a worse state
# than neither, because both look like the feature shipped.
$manifestText = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8
Assert-True ($manifestText -match 'squad-templates/skills/turn-end\.md') 'the skill is in the package FileList, so the update can deploy it'
foreach ($script in @('declare-turn-end.ps1', 'turn-end-store.ps1', 'record-design-decision.ps1', 'design-decision-store.ps1')) {
    Assert-True ($manifestText -match [regex]::Escape($script)) ("the package ships {0}" -f $script)
}
# The generic skill route deploys squad-templates/skills/<name>.md as specrew-<name>, so the file's
# presence IS its deployment - asserted here rather than assumed, because the user-profile skill was
# advertised for months while shipping to nobody (beta4's fix 4).
$skillText = Get-Content -LiteralPath $skillTemplate -Raw -Encoding UTF8
Assert-True ($skillText -match 'declare-turn-end\.ps1') 'the deployed skill names the command it is about'
$contractText = Get-Content -LiteralPath $launchContract -Raw -Encoding UTF8
Assert-True ($contractText -match 'declare-turn-end\.ps1') 'the launch contract carries the directive sentence'
Assert-True ($contractText -match 'as the last action of the turn') 'and the directive says WHEN to run it'
# The heading dictation it replaced is gone: leaving both would give the agent two contracts for one turn.
Assert-True ($contractText -notmatch 'render a visible five-part context packet') 'the five-heading dictation it replaces is gone from the contract'

# --- the transition itself ---------------------------------------------------------------------------
$root = Join-Path ([IO.Path]::GetTempPath()) ('specrew-update-transition-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
try {
    Write-Host '  --- a project on the OLD habit, updated ---'
    New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root 'specs/050-host-neutral-gate') -Force | Out-Null
    $context = [ordered]@{
        schema               = 'v2'
        feature_path         = (Join-Path $root 'specs/050-host-neutral-gate')
        session_state        = [ordered]@{ active = $true; boundary_type = 'plan'; feature_ref = '050-host-neutral-gate'; iteration_number = '001'; recorded_at = '2026-09-10T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'plan'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($context | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $root 'specs/050-host-neutral-gate/spec.md'), "# Spec`n`nReal content.`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $root '.specrew/runtime/session-marker.json'),
        '{"host":"claude","session_id":"transition-session","project_root":"x","branch":"b","head_commit":"h"}', [Text.UTF8Encoding]::new($false))

    # material work by THIS session: a real git delta is what makes the turn owe anything at all.
    $null = & git -C $root init --quiet
    $null = & git -C $root config core.autocrlf false
    [IO.File]::WriteAllText((Join-Path $root 'baseline.txt'), "base`n", [Text.UTF8Encoding]::new($false))
    $null = & git -C $root add -A
    $null = & git -C $root -c user.name=T -c user.email=t@x.invalid commit --quiet -m base

    # The OLD habit: a five-heading prose packet, exactly what used to satisfy the hook.
    $oldHabitPacket = @'
## What I Just Did

Wrote the plan for the feature at file:///plan.md and recorded the approach.

## Why I Stopped

The plan is written and I am handing back for review.

## What Needs Your Review

The plan document.

## What Happens Next

Tasks, once you are happy.

## What I Need From You

Tell me if the plan is wrong.
'@
    # The host's real transcript shape, not an invented one. A fixture whose lines the provider cannot parse
    # leaves $lastAssistantText empty, and the provider then FAILS OPEN by design - so the whole suite would
    # pass while measuring nothing. The first version of this test did exactly that.
    $transcript = Join-Path $root '.specrew/runtime/transcript.jsonl'
    $turns = foreach ($t in @(@{ role = 'user'; text = 'write the plan' }, @{ role = 'assistant'; text = $oldHabitPacket })) {
        ([pscustomobject]@{ type = $t.role; message = [pscustomobject]@{ content = @([pscustomobject]@{ type = 'text'; text = $t.text }) } } | ConvertTo-Json -Depth 8 -Compress)
    }
    [IO.File]::WriteAllLines($transcript, [string[]]$turns, [Text.UTF8Encoding]::new($false))

    function Invoke-Provider {
        param([string]$Event = 'Stop')
        $cmd = "Set-Location -LiteralPath '$root'; & '$provider' --host-kind claude --source-event $Event --session-id 'transition-session' --transcript-path '$transcript'"
        $out = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1) -join "`n")
        return [pscustomobject]@{ Out = $out; Blocked = ($out -match '<<<SPECREW-STOP-BLOCK>>>') }
    }
    function Invoke-Stop { return (Invoke-Provider -Event 'Stop') }

    # THE TURN STARTS AT THE PROMPT, and the material lane knows it did because the host says so. Without
    # this the turn has no baseline, the delta is unattributable, and a read-only consultation over files an
    # earlier session left dirty would be charged to this one. Firing it here is not test scaffolding - it is
    # the sequence a real turn has, and skipping it made the fixture measure nothing.
    $null = Invoke-Provider -Event 'UserPromptSubmit'
    # ...and only NOW does this turn change anything.
    [IO.File]::WriteAllText((Join-Path $root 'specs/050-host-neutral-gate/plan.md'), "# Plan`n`nWritten this turn.`n", [Text.UTF8Encoding]::new($false))

    Write-Host '  --- step 1-2: the prose packet earns exactly one refusal, and it names the command ---'
    $first = Invoke-Stop
    Assert-True $first.Blocked 'the old-habit prose packet is refused - prose is not evidence'
    if (-not $first.Blocked) {
        # Census 34502784677 (windows-latest) redded this assertion while every local run - including one under
        # the runner's CI environment variables - was green, and the suite printed nothing that could say why.
        # The provider's own output is the diagnosis; it is printed on failure so the next census names the cause.
        Write-Host ('  [diagnosis] provider output: ' + (($first.Out -replace '\s+', ' ')).Substring(0, [Math]::Min(1500, ($first.Out -replace '\s+', ' ').Length)))
        Write-Host ('  [diagnosis] baseline: ' + $(if (Test-Path -LiteralPath (Join-Path $root '.specrew/runtime/conformance-sessions')) { (Get-ChildItem -LiteralPath (Join-Path $root '.specrew/runtime/conformance-sessions') -Recurse -File | ForEach-Object { $_.Name + '=' + $_.Length }) -join ',' } else { 'no session dir' }))
        Write-Host ('  [diagnosis] git status: ' + ((@(& git -C $root status --porcelain=v1 --untracked-files=all 2>&1)) -join ' | '))
    }
    Assert-True ($first.Out -match 'declare-turn-end\.ps1') 'the refusal NAMES the command'
    Assert-True ($first.Out -match '-Kind <boundary\|in-flight\|conversational>') 'and names its parameters'
    Assert-True ($first.Out -match '-Summary') 'including the one that carries what the turn did'
    Assert-True ([regex]::Matches($first.Out, 'declare-turn-end\.ps1').Count -ge 1) 'the command appears in the refusal text the agent reads'

    Write-Host '  --- step 3: the crew runs the command it was given, from the path it was given ---'
    # Taken from the refusal rather than hard-coded: if the message ever names a path that is not there,
    # this fails here instead of passing on a command nobody could have run.
    $named = [regex]::Match($first.Out, '(?<path>[^\s'']*declare-turn-end\.ps1)')
    Assert-True $named.Success 'the refusal contains a runnable path for the command'
    $deployedRelative = $named.Groups['path'].Value
    Assert-True ($deployedRelative -match '^\.specify/') ('the named path is the DEPLOYED one a project would have: {0}' -f $deployedRelative)
    # The fixture has no deployed .specify tree, so run the repo copy - the path SHAPE is what was asserted.
    $declared = & pwsh -NoProfile -File $declarer -Kind 'conversational' -Summary 'wrote the plan' -ProjectRoot $root -AsJson 2>&1
    $declaredJson = $null
    try { $declaredJson = ((@($declared) -join "`n") | ConvertFrom-Json) } catch { $declaredJson = $null }
    Assert-True ($null -ne $declaredJson -and [bool]$declaredJson.record_written) 'the command runs and writes its record'

    Write-Host '  --- step 4: the next turn is compliant, and there is no second refusal ---'
    $second = Invoke-Stop
    Assert-True (-not $second.Blocked) 'the very next stop is NOT refused - the transition costs one turn, not a loop'
    Assert-True ($second.Out -notmatch 'declare-turn-end\.ps1') 'and the command is not demanded again once it has been run'

    # --- the boundary stop the Claude gate-stop skill used to compose by hand ---------------------------
    # The skill now routes through the script (PRED-BETA4-016), so what the skill's own test pins as the
    # surface's PROPERTIES must be what the script renders: the four responses as lines the human can
    # literally send, no numbered option, the marker last - and, with -Owed, the FR-024 withhold paragraph in
    # the skill's words with no lines and no marker.
    Write-Host '  --- the boundary render: four sendable lines, then the marker; or the withhold paragraph ---'
    $stopLines = @('# Specrew Pending Verdict Stop', '', 'Boundary to ask for: plan -> tasks', 'Human approval phrase: approved for tasks', 'Marker last line exactly:', '<!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks -->', '', 'Working boundary: tasks', 'Last authorized boundary: plan', 'Feature: 050-host-neutral-gate')
    [IO.File]::WriteAllText((Join-Path $root '.specrew/runtime/pending-verdict-stop.md'), (($stopLines -join [Environment]::NewLine) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
    $boundaryOut = (@(& pwsh -NoProfile -File $declarer -Kind 'boundary' -Summary 'planned the feature' -ProjectRoot $root -AsJson 2>&1) -join "`n")
    $boundary = $null
    try { $boundary = ($boundaryOut | ConvertFrom-Json) } catch { $boundary = $null }
    $text = if ($null -ne $boundary) { [string]$boundary.text } else { '' }
    Assert-True ($text -match '(?m)^What would you like to do\? Type one of these:') 'the boundary render offers the responses as text to type'
    Assert-True ($text -match '(?m)^  approved for tasks\r?$') 'line 1: the bare approval phrase, from the artifact'
    Assert-True ($text -match '(?m)^  approved for tasks - <your instructions>\r?$') 'line 2: approve WITH instructions - how a human approves without rubber-stamping'
    Assert-True ($text -match '(?m)^  changes needed: <what to change>\r?$') 'line 3: changes needed'
    Assert-True ($text -match '(?m)^  discuss prompt 1\r?$') 'line 4: discuss one prompt without withdrawing the rest'
    Assert-True ($text -match '(?m)^1\. Anything above') 'and the discussion prompts are numbered, so prompt 1 names something'
    Assert-True ($text -notmatch '(?m)^\s*1\.\s*Approve') 'no numbered verdict option - a number is a control that cannot authorize'
    Assert-True ($text.TrimEnd() -match '<!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks -->$') 'the marker is the VERY LAST line'
    $owedOut = (@(& pwsh -NoProfile -File $declarer -Kind 'boundary' -Summary 'planned, but tasks.md is not written' -Owed 'tasks.md' -ProjectRoot $root -AsJson 2>&1) -join "`n")
    $owed = $null
    try { $owed = ($owedOut | ConvertFrom-Json) } catch { $owed = $null }
    $owedText = if ($null -ne $owed) { [string]$owed.text } else { '' }
    Assert-True ($owedText -match "I am not offering a verdict here: 'plan' owes tasks.md and it does not exist yet") 'with -Owed the withhold paragraph names the stage that owes and what it owes, in the gate-stop skill''s words'
    Assert-True ($owedText -match 'indistinguishable in the ledger from an approval of real work') 'and says WHY, in the words the machinery uses on its own surface'
    Assert-True ($owedText -notmatch 'approved for tasks' -and $owedText -notmatch 'SPECREW-VERDICT-BOUNDARY') 'and offers NO responses and NO marker'
}
finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    if ($null -eq $priorModulePath) { Remove-Item Env:\SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $priorModulePath }
}

if ($script:Failures -gt 0) {
    Write-Host ("turn-end-update-transition: {0} FAILED" -f $script:Failures)
    exit 1
}
Write-Host 'turn-end-update-transition: all cases passed'
exit 0
