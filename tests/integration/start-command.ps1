[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Write-Skip {
    param([string]$Message)
    Write-Host "SKIP: $Message" -ForegroundColor Yellow
}

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function Invoke-TestCommand {
    param([string]$Command)

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -Command $Command 2>&1)
    return @{
        Output = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function Assert-Contains {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$FailureMessage
    )

    if ($Content -notmatch $Pattern) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Get-FunctionDefinitionsText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string[]]$FunctionNames
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        throw ("Failed to parse function definitions from {0}: {1}" -f $Path, ($parseErrors | ForEach-Object { $_.Message } | Select-Object -First 1))
    }

    foreach ($functionName in $FunctionNames) {
        $functionAst = $ast.Find(
            {
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq $functionName
            },
            $true
        )

        if ($null -eq $functionAst) {
            throw ("Failed to locate function '{0}' in {1}" -f $functionName, $Path)
        }

        $functionAst.Extent.Text
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$entryScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew.ps1'
$startScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-start.ps1'
$initScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-init.ps1'

foreach ($requiredScript in @($entryScript, $startScript, $initScript)) {
    if (-not (Test-Path -LiteralPath $requiredScript -PathType Leaf)) {
        Write-Fail "Missing required script: $requiredScript"
        exit 1
    }
}

$missingTools = @()
if (-not (Get-Command -Name 'specify' -ErrorAction SilentlyContinue)) {
    $missingTools += 'specify'
}
if (-not (Get-Command -Name 'squad' -ErrorAction SilentlyContinue)) {
    $missingTools += 'squad'
}

if ($missingTools.Count -gt 0) {
    Write-Skip ("Start command tests require tools not available in this environment: {0}" -f ($missingTools -join ', '))
    exit 0
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\start-command'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'

if (Test-Path -Path $scratchRoot) {
    Remove-Item -Path $scratchRoot -Recurse -Force
}

$null = New-Item -Path $projectRoot -ItemType Directory -Force

$gitInitOutput = @(& git -C $projectRoot init --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $gitInitOutput) {
        Write-Host $line
    }
    Write-Fail "Failed to initialize git repository in scratch project: $projectRoot"
    exit 1
}

Write-Host "Initializing Specrew project..."
$initResult = Invoke-TestScript -ScriptPath $initScript -ArgumentList @('-ProjectPath', $projectRoot, '-Force', '-NoAgents')
if ($initResult.ExitCode -ne 0) {
    Write-Host "Bootstrap output:"
    foreach ($line in $initResult.Output) {
        Write-Host $line
    }
    Write-Fail "Bootstrap failed"
    exit 1
}

Write-Pass "Bootstrap completed successfully"

Write-Host "`nTest 1: start command help advertises the new flow"
$helpResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('start', '--help')
if ($helpResult.ExitCode -ne 0) {
    Write-Fail "specrew start --help failed"
    exit 1
}

$helpOutput = $helpResult.Output -join "`n"
if (-not (Assert-Contains -Content $helpOutput -Pattern 'specrew start' -FailureMessage 'Help output does not describe the start command.')) {
    exit 1
}
if (-not (Assert-Contains -Content $helpOutput -Pattern 'prompt-approvals' -FailureMessage 'Help output does not describe the prompt-approvals option.')) {
    exit 1
}
if (-not (Assert-Contains -Content $helpOutput -Pattern 'new-window' -FailureMessage 'Help output does not describe the new-window option.')) {
    exit 1
}
if (-not (Assert-Contains -Content $helpOutput -Pattern 'same-window' -FailureMessage 'Help output does not describe the same-window option.')) {
    exit 1
}
Write-Pass "Help output includes specrew start"

Write-Host "`nTest 1aa: display-path helpers trim both path separators"
Invoke-Expression ((Get-FunctionDefinitionsText -Path $startScript -FunctionNames @('Get-DisplayRelativePath', 'Get-DisplayPathFromProjectRoot')) -join "`n`n")
$windowsDisplayPath = Get-DisplayPathFromProjectRoot -ResolvedProjectPath $projectRoot -Path (Join-Path -Path $projectRoot -ChildPath '.specrew\last-start-prompt.md')
if ($windowsDisplayPath -ne '.specrew\last-start-prompt.md') {
    Write-Fail ("Get-DisplayPathFromProjectRoot returned the wrong Windows-relative path: {0}" -f $windowsDisplayPath)
    exit 1
}
$linuxDisplayPath = Get-DisplayRelativePath -ProjectRoot '/repo/project/' -ResolvedPath '/repo/project/.specrew/last-start-prompt.md'
if ($linuxDisplayPath -ne '.specrew/last-start-prompt.md') {
    Write-Fail ("Get-DisplayRelativePath returned the wrong Linux-style relative path: {0}" -f $linuxDisplayPath)
    exit 1
}
if ($linuxDisplayPath -match '^/\.specrew/') {
    Write-Fail ("Linux-style display path still looks absolute: {0}" -f $linuxDisplayPath)
    exit 1
}
Write-Pass "Display-path helpers trim both slash styles"

Write-Host "`nTest 1b: entry wrapper preserves the same terminal for start"
$entryScriptContent = Get-Content -LiteralPath $entryScript -Raw -Encoding UTF8
$nestedStartDispatchPattern = [regex]::Escape('& pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript')
if ($entryScriptContent -match $nestedStartDispatchPattern) {
    Write-Fail "specrew.ps1 still shells out to a nested pwsh process for start, which breaks interactive Copilot attachment."
    exit 1
}
Write-Pass "Entry wrapper dispatches start in-process"

Write-Host "`nTest 1bb: start command avoids inline native Copilot invocation on Windows"
$startScriptContent = Get-Content -LiteralPath $startScript -Raw -Encoding UTF8
$sameWindowProcessLaunchPattern = 'if \(\$SameWindow\)\s*\{\s*\$process = Start-Process -FilePath ''pwsh''.*-NoNewWindow -PassThru -Wait'
if ($startScriptContent -notmatch $sameWindowProcessLaunchPattern) {
    Write-Fail "specrew-start.ps1 does not use a separate pwsh process for same-window Copilot launch on Windows."
    exit 1
}
$uniformAllowAllPattern = 'if \(\$AllowAll\) \{\s*\$copilotArgs \+= ''--allow-all'''
if ($startScriptContent -notmatch $uniformAllowAllPattern) {
    Write-Fail "specrew-start.ps1 no longer applies --allow-all uniformly when AllowAll is true."
    exit 1
}
$windowsAllowAllSnippetPattern = '\$allowAllSnippet = if \(\$AllowAll\) \{ ''\$args \+= ''''--allow-all'''''' \} else \{ '''' \}'
if ($startScriptContent -notmatch $windowsAllowAllSnippetPattern) {
    Write-Fail "specrew-start.ps1 no longer preserves the Windows embedded launch-script --allow-all behavior."
    exit 1
}
Write-Pass "Start command uses a separate pwsh process for same-window launch on Windows"

Write-Host "`nTest 1c: entry wrapper defaults start project-path to the caller location"
$defaultPathProjectRoot = Join-Path -Path $scratchRoot -ChildPath 'default-project'
$null = New-Item -Path $defaultPathProjectRoot -ItemType Directory -Force
$defaultGitInitOutput = @(& git -C $defaultPathProjectRoot init --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $defaultGitInitOutput) {
        Write-Host $line
    }
    Write-Fail "Failed to initialize git repository in default-path scratch project: $defaultPathProjectRoot"
    exit 1
}

$defaultInitResult = Invoke-TestScript -ScriptPath $initScript -ArgumentList @('-ProjectPath', $defaultPathProjectRoot, '-Force', '-NoAgents')
if ($defaultInitResult.ExitCode -ne 0) {
    Write-Host "Bootstrap output:"
    foreach ($line in $defaultInitResult.Output) {
        Write-Host $line
    }
    Write-Fail "Bootstrap failed for the default project-path wrapper test"
    exit 1
}

$quotedDefaultPathProjectRoot = $defaultPathProjectRoot.Replace("'", "''")
$quotedEntryScript = $entryScript.Replace("'", "''")
$defaultPathResult = Invoke-TestCommand -Command "Push-Location -LiteralPath '$quotedDefaultPathProjectRoot'; try { & '$quotedEntryScript' start --no-launch } finally { Pop-Location }"
if ($defaultPathResult.ExitCode -ne 0) {
    Write-Fail "specrew start should succeed without an explicit --project-path when run from the project root"
    foreach ($line in $defaultPathResult.Output) {
        Write-Host $line
    }
    exit 1
}

$defaultPromptPath = Join-Path -Path $defaultPathProjectRoot -ChildPath '.specrew\last-start-prompt.md'
$defaultContextPath = Join-Path -Path $defaultPathProjectRoot -ChildPath '.specrew\start-context.json'
if (-not (Test-Path -LiteralPath $defaultPromptPath -PathType Leaf)) {
    Write-Fail "Wrapper default project-path flow did not create the prompt artifact in the caller project"
    exit 1
}
if (-not (Test-Path -LiteralPath $defaultContextPath -PathType Leaf)) {
    Write-Fail "Wrapper default project-path flow did not create the context artifact in the caller project"
    exit 1
}

$defaultContext = Get-Content -LiteralPath $defaultContextPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($defaultContext.prompt_path -ne $defaultPromptPath) {
    Write-Fail "Wrapper default project-path flow recorded the wrong prompt path in start-context.json"
    exit 1
}
if ($defaultContext.team_roster.team_path -ne (Join-Path -Path $defaultPathProjectRoot -ChildPath '.squad\team.md')) {
    Write-Fail "Wrapper default project-path flow recorded the wrong team roster path in start-context.json"
    exit 1
}

$defaultPathOutput = $defaultPathResult.Output -join "`n"
if (-not (Assert-Contains -Content $defaultPathOutput -Pattern ([regex]::Escape($defaultPromptPath)) -FailureMessage 'Wrapper default project-path flow reported the wrong prompt artifact path.')) {
    exit 1
}
Write-Pass "Entry wrapper defaults project-path to the caller project root"

Write-Host "`nTest 2: start command enters intake-or-resume mode on a fresh repo"
$freshStartResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($freshStartResult.ExitCode -ne 0) {
    Write-Fail "specrew start should succeed on a fresh repo without a feature request"
    foreach ($line in $freshStartResult.Output) {
        Write-Host $line
    }
    exit 1
}

$freshPromptPath = Join-Path -Path $projectRoot -ChildPath '.specrew\last-start-prompt.md'
$freshContextPath = Join-Path -Path $projectRoot -ChildPath '.specrew\start-context.json'
$freshSummaryPath = Join-Path -Path $projectRoot -ChildPath '.specrew\start-summary.md'
if (-not (Test-Path -LiteralPath $freshPromptPath -PathType Leaf)) {
    Write-Fail "Fresh repo start did not create a prompt artifact"
    exit 1
}
if (-not (Test-Path -LiteralPath $freshContextPath -PathType Leaf)) {
    Write-Fail "Fresh repo start did not create a context artifact"
    exit 1
}
if (-not (Test-Path -LiteralPath $freshSummaryPath -PathType Leaf)) {
    Write-Fail "Fresh repo start did not create a human-readable summary artifact"
    exit 1
}

$freshPromptContent = Get-Content -LiteralPath $freshPromptPath -Raw -Encoding UTF8
$freshContext = Get-Content -LiteralPath $freshContextPath -Raw -Encoding UTF8 | ConvertFrom-Json
$freshOutput = $freshStartResult.Output -join "`n"
$freshStartChecks = @(
    @{ Pattern = 'Mode: intake-or-resume'; Failure = 'Fresh repo prompt did not enter intake-or-resume mode.' },
    @{ Pattern = 'Preserve the roster snapshot first'; Failure = 'Fresh repo prompt did not tell Squad to preserve the roster before intake.' },
    @{ Pattern = 'Classify the repository using the project-state snapshot above'; Failure = 'Fresh repo prompt did not tell Squad to classify the repository before asking for spec details.' },
    @{ Pattern = 'What do you want to build\?'; Failure = 'Fresh repo prompt did not require an explicit greenfield intake question.' },
    @{ Pattern = 'wait for the human developer''s answer before invoking any .* lifecycle agent or command'; Failure = 'Fresh repo prompt did not require human intake before lifecycle execution.' },
    @{ Pattern = 'continue with one targeted follow-up question at a time'; Failure = 'Fresh repo prompt did not require iterative greenfield intake.' },
    @{ Pattern = 'defer specialist additions until the spec and clarify outcome are grounded'; Failure = 'Fresh repo prompt did not defer specialist team additions until after spec clarity.' },
    @{ Pattern = 'only propose Junior/Senior same-specialty pairs when the clarified work can be partitioned safely enough for meaningful parallel execution'; Failure = 'Fresh repo prompt did not constrain Junior/Senior same-specialty expansion.' },
    @{ Pattern = 'run speckit\.clarify for every newly generated spec before speckit\.plan'; Failure = 'Fresh repo prompt did not require clarify for newly generated specs.' },
    @{ Pattern = 'Do not invoke speckit\.implement until the human approves'; Failure = 'Fresh repo prompt did not require explicit implementation approval.' },
    @{ Pattern = 'no-gap policy'; Failure = 'Fresh repo prompt did not require the no-gap policy.' },
    @{ Pattern = 'implemented, enforced, observable, and documented'; Failure = 'Fresh repo prompt did not require critical review dimensions.' }
)

foreach ($check in $freshStartChecks) {
    if (-not (Assert-Contains -Content $freshPromptContent -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        exit 1
    }
}
if ($freshContext.approval_mode -ne 'allow-all') {
    Write-Fail ("Fresh repo start recorded the wrong approval mode: {0}" -f $freshContext.approval_mode)
    exit 1
}
if ($freshContext.copilot_autopilot) {
    Write-Fail "Fresh repo start should keep Copilot out of autopilot while intake is unresolved."
    exit 1
}
if ($freshContext.launch_mode -ne 'none') {
    Write-Fail "Fresh repo no-launch flow did not record the expected launch mode."
    exit 1
}
if ($null -eq $freshContext.delivery_guidance -or @($freshContext.delivery_guidance.quality_attributes).Count -eq 0) {
    Write-Fail 'Fresh repo start did not serialize delivery guidance with quality attributes.'
    exit 1
}
if (@($freshContext.delivery_guidance.same_specialty_pair_hints).Count -ne 0) {
    Write-Fail 'Fresh repo start should not infer Junior/Senior same-specialty pairs before a grounded feature request exists.'
    exit 1
}
if ($freshContext.project_state.state -ne 'greenfield-new') {
    Write-Fail "Fresh repo start did not classify the project as greenfield-new."
    exit 1
}
if (-not (Assert-Contains -Content $freshOutput -Pattern 'Manual launch command' -FailureMessage 'Fresh repo no-launch flow did not print an exact manual launch command.')) {
    exit 1
}
if (-not (Assert-Contains -Content $freshOutput -Pattern "copilot --agent 'Squad'" -FailureMessage 'Fresh repo no-launch flow did not show the Copilot + Squad handoff command.')) {
    exit 1
}
if ($freshOutput -match '--autopilot') {
    Write-Fail 'Fresh repo no-launch flow should not use autopilot before intake is grounded.'
    exit 1
}
$freshManualLaunchLine = @($freshStartResult.Output | Where-Object { $_ -match 'Manual launch command' } | Select-Object -Last 1)
if ($freshManualLaunchLine.Count -eq 0) {
    Write-Fail 'Fresh repo no-launch flow did not emit the manual launch line.'
    exit 1
}
if (-not (Assert-Contains -Content $freshManualLaunchLine[0] -Pattern '--allow-all' -FailureMessage 'Fresh repo no-launch flow did not preserve allow-all in the manual handoff command.')) {
    exit 1
}
if (-not (Assert-Contains -Content $freshManualLaunchLine[0] -Pattern '(^| )-i( |$)' -FailureMessage 'Fresh repo no-launch flow should auto-load the bootstrap with -i.')) {
    exit 1
}
if ($freshManualLaunchLine[0] -match '--mode interactive') {
    Write-Fail 'Fresh repo no-launch flow should not pass --mode interactive; -i auto-loading is sufficient.'
    exit 1
}
if (-not (Assert-Contains -Content $freshOutput -Pattern 'last-start-prompt\.md' -FailureMessage 'Fresh repo no-launch flow did not bootstrap from the saved prompt file.')) {
    exit 1
}
if (-not (Assert-Contains -Content $freshOutput -Pattern 'start-context\.json' -FailureMessage 'Fresh repo no-launch flow did not bootstrap from the saved context file.')) {
    exit 1
}
if (-not (Assert-Contains -Content $freshOutput -Pattern 'start-summary\.md' -FailureMessage 'Fresh repo no-launch flow did not print the summary artifact path.')) {
    exit 1
}
if ($freshOutput -match '/\.specrew/') {
    Write-Fail 'Fresh repo no-launch flow emitted an absolute-looking bootstrap path.'
    exit 1
}
Write-Pass "Fresh repo start enters intake-or-resume mode"

Write-Host "`nTest 2b: default launch reuses the current terminal and passes the bootstrap handoff"
$fakeBinRoot = Join-Path -Path $scratchRoot -ChildPath 'fake-bin'
$null = New-Item -Path $fakeBinRoot -ItemType Directory -Force
$fakeCopilotLog = Join-Path -Path $scratchRoot -ChildPath 'fake-copilot.log'
$fakeCopilotPath = Join-Path -Path $fakeBinRoot -ChildPath 'copilot.cmd'
$fakeCopilotScript = @"
@echo off
setlocal
echo %*>>"$fakeCopilotLog"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Sleep -Seconds 2"
exit /b 0
"@
[System.IO.File]::WriteAllText($fakeCopilotPath, $fakeCopilotScript, [System.Text.UTF8Encoding]::new($false))

$launchCommand = @'
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$env:PATH = "{0};" + $env:PATH
& "{1}" start "Launch a tiny clipboard utility" --project-path "{2}"
$sw.Stop()
Write-Output ("__ELAPSED__=" + [math]::Round($sw.Elapsed.TotalSeconds, 2))
'@ -f $fakeBinRoot, $entryScript, $projectRoot
$liveLaunchResult = Invoke-TestCommand -Command $launchCommand
if ($liveLaunchResult.ExitCode -ne 0) {
    Write-Fail 'specrew start failed while testing same-window launch behavior'
    foreach ($line in $liveLaunchResult.Output) {
        Write-Host $line
    }
    exit 1
}

$elapsedLine = @($liveLaunchResult.Output | Where-Object { $_ -like '__ELAPSED__=*' } | Select-Object -Last 1)
if ($elapsedLine.Count -eq 0) {
    Write-Fail 'Same-window launch test did not emit elapsed-time telemetry.'
    exit 1
}
$elapsedSeconds = [double]($elapsedLine[0] -replace '^__ELAPSED__=', '')
if ($elapsedSeconds -lt 1.5) {
    Write-Fail 'Default launch returned too quickly; Copilot was likely detached into a new window instead of reusing the current terminal.'
    exit 1
}
if (-not (Test-Path -LiteralPath $fakeCopilotLog -PathType Leaf)) {
    Write-Fail 'Fake Copilot did not record any launch arguments.'
    exit 1
}
$fakeCopilotArgs = Get-Content -LiteralPath $fakeCopilotLog -Raw -Encoding UTF8
if ($fakeCopilotArgs -notmatch 'last-start-prompt\.md' -or $fakeCopilotArgs -notmatch 'start-context\.json') {
    Write-Fail 'Live launch did not pass the bootstrap handoff file references to Copilot.'
    exit 1
}
if ($fakeCopilotArgs -notmatch '(^| )-i( |$)') {
    Write-Fail 'Live launch should auto-load the bootstrap prompt with -i.'
    exit 1
}
if ($fakeCopilotArgs -notmatch '--allow-all') {
    Write-Fail 'Live launch should preserve --allow-all on every platform.'
    exit 1
}
if ($fakeCopilotArgs -notmatch '--autopilot') {
    Write-Fail 'Live launch should use autopilot once the request is grounded.'
    exit 1
}
if ($fakeCopilotArgs -match '--mode interactive') {
    Write-Fail 'Live launch should not combine --mode interactive with --autopilot.'
    exit 1
}
if ($fakeCopilotArgs -match 'You are Squad running inside a Specrew-bootstrapped repository') {
    Write-Fail 'Live launch still injected the full Squad handoff prompt into Copilot input.'
    exit 1
}
Write-Pass "Default launch reuses the current terminal"

Write-Host "`nTest 3: start command writes prompt artifacts for a new feature"
$request = 'Build a sample reporting dashboard with export support'
$startResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    $request,
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($startResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed for new feature request"
    foreach ($line in $startResult.Output) {
        Write-Host $line
    }
    exit 1
}

$promptPath = Join-Path -Path $projectRoot -ChildPath '.specrew\last-start-prompt.md'
$contextPath = Join-Path -Path $projectRoot -ChildPath '.specrew\start-context.json'
$summaryPath = Join-Path -Path $projectRoot -ChildPath '.specrew\start-summary.md'
foreach ($artifactPath in @($promptPath, $contextPath, $summaryPath)) {
    if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
        Write-Fail "Start command did not create expected artifact: $artifactPath"
        exit 1
    }
}

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
$startContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
$summaryContent = Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8
$promptChecks = @(
    @{ Pattern = 'speckit\.specify'; Failure = 'Prompt is missing specify lifecycle step.' },
    @{ Pattern = 'speckit\.clarify'; Failure = 'Prompt is missing clarify lifecycle step.' },
    @{ Pattern = 'speckit\.plan'; Failure = 'Prompt is missing plan lifecycle step.' },
    @{ Pattern = 'speckit\.tasks'; Failure = 'Prompt is missing tasks lifecycle step.' },
    @{ Pattern = 'speckit\.implement'; Failure = 'Prompt is missing implement lifecycle step.' },
    @{ Pattern = 'speckit\.specrew-speckit\.before-plan'; Failure = 'Prompt is missing the before-plan lifecycle gate.' },
    @{ Pattern = 'speckit\.specrew-speckit\.after-tasks'; Failure = 'Prompt is missing the after-tasks lifecycle gate.' },
    @{ Pattern = 'speckit\.specrew-speckit\.before-implement'; Failure = 'Prompt is missing the before-implement lifecycle gate.' },
    @{ Pattern = 'dedicated Speckit agents or commands \(not generic skills\)'; Failure = 'Prompt does not describe how Speckit lifecycle invocations should be executed.' },
    @{ Pattern = 'run speckit\.clarify for every newly generated spec before speckit\.plan'; Failure = 'Prompt does not require clarify for newly generated specs.' },
    @{ Pattern = 'record a concrete dated skip rationale in \.squad\\decisions\.md before speckit\.plan'; Failure = 'Prompt does not require a recorded skip rationale when clarify is skipped.' },
    @{ Pattern = 'ground any missing intake first, and only then invoke'; Failure = 'Prompt does not stop specify from running before intake is grounded.' },
    @{ Pattern = 'present the resulting team composition clearly before implementation'; Failure = 'Prompt does not require post-spec team presentation before implementation.' },
    @{ Pattern = 'route bounded, lower-risk, well-scoped work to the Junior role'; Failure = 'Prompt does not describe Junior/Senior routing behavior.' },
    @{ Pattern = 'careful, responsible, knowledgeable, and review-ready'; Failure = 'Prompt does not set the higher Junior quality bar.' },
    @{ Pattern = 'deep technical judgment across architecture, systems thinking, computer science depth, tradeoff analysis, and long-range software engineering consequences'; Failure = 'Prompt does not set the deeper Senior technical bar.' },
    @{ Pattern = 'Derive the quality bar from the current feature and project context'; Failure = 'Prompt does not require requirement-driven quality governance.' },
    @{ Pattern = 'If any lifecycle agent reports a file-write or tool-contract failure'; Failure = 'Prompt does not fail fast on artifact-generation errors.' },
    @{ Pattern = 'Planning/problem-solving work should prefer Planner or Spec Steward delegated routing'; Failure = 'Prompt does not require delegated routing for problem-solving-heavy work.' },
    @{ Pattern = 'concrete model ID'; Failure = 'Prompt does not require visible delegated runtime evidence.' },
    @{ Pattern = 'Do not invoke speckit\.implement until the human approves'; Failure = 'Prompt does not require explicit approval before implementation.' },
    @{ Pattern = 'include the hardening-gate verdict and any human-approved deferral status in that readiness summary'; Failure = 'Prompt does not require the hardening-gate verdict in the implementation-readiness summary.' },
    @{ Pattern = 'After speckit\.specrew-speckit\.after-tasks succeeds, treat speckit\.specrew-speckit\.before-implement as the next automatic lifecycle step'; Failure = 'Prompt does not require the automatic after-tasks to before-implement transition.' },
    @{ Pattern = 'Do not stop at the .*after-tasks boundary to ask the human to manually trigger hardening review'; Failure = 'Prompt still allows the coordinator to stop at after-tasks for a manual hardening-review request.' },
    @{ Pattern = 'If speckit\.specrew-speckit\.before-implement blocks, explain the concrete blocking artifact or verdict, why it blocks implementation, and the next valid human action'; Failure = 'Prompt does not require proactive blocker explanation before stopping.' },
    @{ Pattern = 'developer-facing implementation briefing'; Failure = 'Prompt does not require the end-of-feature implementation briefing.' },
    @{ Pattern = 'implemented, enforced, observable, and documented'; Failure = 'Prompt does not require critical evidence-driven review dimensions.' },
    @{ Pattern = 'If review finds an ambiguity, contradiction, or missing decision in the governing spec'; Failure = 'Prompt does not require spec clarification when review finds unknowns.' },
    @{ Pattern = [regex]::Escape($request); Failure = 'Prompt is missing the requested feature text.' }
)

foreach ($check in $promptChecks) {
    if (-not (Assert-Contains -Content $promptContent -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        exit 1
    }
}
if ($startContext.approval_mode -ne 'allow-all') {
    Write-Fail ("New feature flow recorded the wrong approval mode: {0}" -f $startContext.approval_mode)
    exit 1
}
if (-not $startContext.copilot_autopilot) {
    Write-Fail "New feature flow should keep Copilot in autopilot once the request is grounded."
    exit 1
}
if ($null -eq $startContext.delivery_guidance -or @($startContext.delivery_guidance.quality_attributes).Count -eq 0) {
    Write-Fail 'New feature flow did not serialize delivery guidance.'
    exit 1
}
$pairHints = @($startContext.delivery_guidance.same_specialty_pair_hints)
if ($pairHints.Count -eq 0) {
    Write-Fail 'New feature flow did not infer any Junior/Senior same-specialty pair hints for a multi-slice feature request.'
    exit 1
}
$pairRoles = @($pairHints | ForEach-Object { $_.junior_role })
if ($pairRoles -notcontains 'Junior Frontend Developer') {
    Write-Fail 'New feature flow did not infer the expected Junior Frontend Developer pair hint.'
    exit 1
}
if (@($startContext.delivery_guidance.routing_guardrails).Count -eq 0) {
    Write-Fail 'New feature flow did not serialize Junior/Senior routing guardrails.'
    exit 1
}
if ($summaryContent -notmatch 'Review/closure use a no-gap policy' -or
    $summaryContent -notmatch 'Delegated Routing' -or
    $summaryContent -notmatch 'allow-all reduces tool-approval blocking after the request is grounded') {
    Write-Fail 'Start summary is missing the expected launch/no-gap/delegated-routing guidance.'
    exit 1
}
Write-Pass "Start command wrote prompt artifacts for new feature flow"

Write-Host "`nTest 3b: start command suppresses same-specialty pairs for conflict-heavy requests"
$conflictRequest = 'Build a reporting dashboard with export workflows, global state migration, and a shared-state rewrite'
$conflictResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    $conflictRequest,
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($conflictResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed for conflict-heavy feature request"
    foreach ($line in $conflictResult.Output) {
        Write-Host $line
    }
    exit 1
}

$conflictContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (@($conflictContext.delivery_guidance.same_specialty_pair_hints).Count -ne 0) {
    Write-Fail 'Conflict-heavy feature flow should suppress Junior/Senior same-specialty pair hints.'
    exit 1
}
Write-Pass "Conflict-heavy requests suppress same-specialty pair hints"

Write-Host "`nTest 4: prompt-approvals mode is preserved in start context"
$promptApprovalResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    '--project-path', $projectRoot,
    '--prompt-approvals',
    '--no-launch'
)

if ($promptApprovalResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed for prompt-approvals mode"
    foreach ($line in $promptApprovalResult.Output) {
        Write-Host $line
    }
    exit 1
}

$promptApprovalContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($promptApprovalContext.approval_mode -ne 'prompt-approvals') {
    Write-Fail "Prompt approval mode was not recorded correctly."
    exit 1
}
if ($promptApprovalContext.copilot_autopilot) {
    Write-Fail "Prompt-approvals intake flow should keep autopilot off until the request is grounded."
    exit 1
}
$promptApprovalOutput = $promptApprovalResult.Output -join "`n"
if (-not (Assert-Contains -Content $promptApprovalOutput -Pattern 'Manual launch command' -FailureMessage 'Prompt-approvals flow did not print an exact manual launch command.')) {
    exit 1
}
if (-not (Assert-Contains -Content $promptApprovalOutput -Pattern '(^| )-i( |$)' -FailureMessage 'Prompt-approvals flow should auto-load the bootstrap with -i.')) {
    exit 1
}
if ($promptApprovalOutput -match '--mode interactive') {
    Write-Fail 'Prompt-approvals flow should not pass --mode interactive; -i auto-loading is sufficient.'
    exit 1
}
if ($promptApprovalOutput -match '--allow-all') {
    Write-Fail "Prompt-approvals flow should not include --allow-all in the manual launch command."
    exit 1
}
Write-Pass "Prompt approvals mode is preserved"

Write-Host "`nTest 5: resume mode reuses active feature context"
$featureDirectory = Join-Path -Path $projectRoot -ChildPath 'specs\001-existing-feature'
$null = New-Item -Path $featureDirectory -ItemType Directory -Force
$featureJsonPath = Join-Path -Path $projectRoot -ChildPath '.specify\feature.json'
[System.IO.File]::WriteAllText(
    $featureJsonPath,
    "{`n  `"feature_directory`": `"specs/001-existing-feature`"`n}",
    [System.Text.UTF8Encoding]::new($false)
)

$resumeResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    '--resume-feature', 'auto',
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($resumeResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed for resume flow"
    foreach ($line in $resumeResult.Output) {
        Write-Host $line
    }
    exit 1
}

$resumePromptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
if ((Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json).project_state.state -ne 'existing-continue') {
    Write-Fail 'Resume flow did not classify the project as existing-continue.'
    exit 1
}
if (-not (Assert-Contains -Content $resumePromptContent -Pattern ([regex]::Escape($featureDirectory)) -FailureMessage 'Resume prompt did not include the resolved active feature directory.')) {
    exit 1
}
Write-Pass "Resume flow reuses the active feature directory"

Write-Host "`nTest 5b: brownfield project is classified before spec intake"
$brownfieldRoot = Join-Path -Path $projectRoot -ChildPath 'src'
$null = New-Item -Path $brownfieldRoot -ItemType Directory -Force
[System.IO.File]::WriteAllText((Join-Path -Path $brownfieldRoot -ChildPath 'app.txt'), 'existing app content', [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $projectRoot -ChildPath 'README.md'), "# Clipboard Sync`n`nA React dashboard for clipboard sync, analytics, and export workflows.", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $projectRoot -ChildPath 'package.json'), "{`n  `"name`": `"clipboard-sync`",`n  `"dependencies`": {`n    `"react`": `"^18.2.0`",`n    `"typescript`": `"^5.5.0`",`n    `"express`": `"^4.19.0`",`n    `"pg`": `"^8.11.0`"`n  }`n}", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $brownfieldRoot -ChildPath 'app.tsx'), 'export const App = () => null;', [System.Text.UTF8Encoding]::new($false))
if (Test-Path -LiteralPath $featureJsonPath -PathType Leaf) {
    Remove-Item -LiteralPath $featureJsonPath -Force
}

$gitAddOutput = @(& git -C $projectRoot add README.md package.json src 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $gitAddOutput) {
        Write-Host $line
    }
    Write-Fail 'Failed to stage brownfield fixture files for git-history testing.'
    exit 1
}

$gitCommitOutput = @(& git -C $projectRoot -c user.name='Specrew Test' -c user.email='specrew-test@example.com' commit -m 'Add clipboard analytics dashboard baseline' --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $gitCommitOutput) {
        Write-Host $line
    }
    Write-Fail 'Failed to create a git commit for brownfield-history testing.'
    exit 1
}

$brownfieldResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($brownfieldResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed for brownfield classification flow"
    foreach ($line in $brownfieldResult.Output) {
        Write-Host $line
    }
    exit 1
}

$brownfieldContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($brownfieldContext.project_state.state -ne 'brownfield-new') {
    Write-Fail 'Brownfield project was not classified as brownfield-new.'
    exit 1
}
if ($brownfieldContext.copilot_autopilot) {
    Write-Fail 'Brownfield intake should keep Copilot out of autopilot until the requested change is grounded.'
    exit 1
}
$brownfieldPromptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
if (-not (Assert-Contains -Content $brownfieldPromptContent -Pattern 'perform brownfield discovery before asking the human broad intake questions' -FailureMessage 'Brownfield prompt did not instruct Squad to perform brownfield discovery first.')) {
    exit 1
}
if (-not (Assert-Contains -Content $brownfieldPromptContent -Pattern 'Continue negotiating brownfield scope until the requested change is concrete enough for speckit\.specify' -FailureMessage 'Brownfield prompt did not require targeted follow-up intake after discovery.')) {
    exit 1
}
if (-not (Assert-Contains -Content $brownfieldPromptContent -Pattern 'Brownfield discovery snapshot:' -FailureMessage 'Brownfield prompt did not include the serialized discovery snapshot.')) {
    exit 1
}
if ($null -eq $brownfieldContext.brownfield_discovery) {
    Write-Fail 'Brownfield start did not serialize a discovery snapshot into start-context.json.'
    exit 1
}
$brownfieldTechnologies = @($brownfieldContext.brownfield_discovery.technologies | ForEach-Object { $_.name })
if ($brownfieldTechnologies -notcontains 'React' -or $brownfieldTechnologies -notcontains 'Express') {
    Write-Fail 'Brownfield discovery did not capture the expected technology signals.'
    exit 1
}
$brownfieldDomainSignals = @($brownfieldContext.brownfield_discovery.domain_signals)
if ($brownfieldDomainSignals -notcontains 'Analytics & Reporting' -or $brownfieldDomainSignals -notcontains 'Sync & Data Transfer') {
    Write-Fail 'Brownfield discovery did not infer expected domain signals from docs/history.'
    exit 1
}
$suggestedRoles = @($brownfieldContext.brownfield_discovery.suggested_specialists | ForEach-Object { $_.role })
if ($suggestedRoles.Count -eq 0 -or $suggestedRoles -notcontains 'React Frontend Specialist') {
    Write-Fail 'Brownfield discovery did not suggest stack-aware specialist team members.'
    exit 1
}
if (@($brownfieldContext.brownfield_discovery.recent_commits).Count -eq 0) {
    Write-Fail 'Brownfield discovery did not capture recent git history.'
    exit 1
}
if ($null -eq $brownfieldContext.delivery_guidance) {
    Write-Fail 'Brownfield start did not serialize delivery guidance into start-context.json.'
    exit 1
}
if (@($brownfieldContext.delivery_guidance.same_specialty_pair_hints).Count -ne 0) {
    Write-Fail 'Brownfield discovery alone should not infer Junior/Senior same-specialty pairs before a grounded feature request exists.'
    exit 1
}
$brownfieldQualityAttributes = @($brownfieldContext.delivery_guidance.quality_attributes | ForEach-Object { $_.name })
if ($brownfieldQualityAttributes -notcontains 'Reliability & Idempotency' -or $brownfieldQualityAttributes -notcontains 'Brownfield Compatibility') {
    Write-Fail 'Brownfield delivery guidance did not capture the expected quality priorities.'
    exit 1
}
$brownfieldWatchouts = @($brownfieldContext.delivery_guidance.semantics_watchouts)
if ($brownfieldWatchouts.Count -eq 0) {
    Write-Fail 'Brownfield delivery guidance did not capture any semantic watchouts.'
    exit 1
}
Write-Pass "Brownfield project classification is captured before spec intake"

Write-Host "`nTest 5c: brownfield frontend-only repos do not force backend specialists"
$frontendOnlyPackageJson = @'
{
  "name": "clipboard-dashboard",
  "dependencies": {
    "react": "^18.2.0",
    "typescript": "^5.5.0",
    "vite": "^5.4.0"
  }
}
'@
[System.IO.File]::WriteAllText((Join-Path -Path $projectRoot -ChildPath 'package.json'), $frontendOnlyPackageJson, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $projectRoot -ChildPath 'README.md'), "# Clipboard Dashboard`n`nA React dashboard for clipboard analytics and export workflows.", [System.Text.UTF8Encoding]::new($false))

$frontendOnlyResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($frontendOnlyResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed for frontend-only brownfield flow"
    foreach ($line in $frontendOnlyResult.Output) {
        Write-Host $line
    }
    exit 1
}

$frontendOnlyContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
$frontendOnlyRoles = @($frontendOnlyContext.delivery_guidance.specialist_hints | ForEach-Object { $_.role })
if ($frontendOnlyRoles -contains 'Backend API Specialist') {
    Write-Fail 'Frontend-only brownfield flow should not force a Backend API Specialist recommendation.'
    exit 1
}
if ($frontendOnlyRoles -notcontains 'Frontend Experience Specialist') {
    Write-Fail 'Frontend-only brownfield flow did not retain a frontend-oriented specialist recommendation.'
    exit 1
}
Write-Pass "Brownfield frontend-only repos avoid forced backend specialists"

Write-Host "`nTest 6: start command preserves the existing Specrew roster and serializes delegated routing"
$quotedProjectRoot = $projectRoot.Replace("'", "''")
$quotedEntryScriptForTeam = $entryScript.Replace("'", "''")
$teamAddResult = Invoke-TestCommand -Command @"
Push-Location -LiteralPath '$quotedProjectRoot'
try {
    & '$quotedEntryScriptForTeam' team add react-expert --role 'Frontend React Expert' --charter 'Decide and implement React-related frontend work.'
}
finally {
    Pop-Location
}
"@

if ($teamAddResult.ExitCode -ne 0) {
    Write-Fail "Failed to add a supplemental team member for roster-preservation testing"
    foreach ($line in $teamAddResult.Output) {
        Write-Host $line
    }
    exit 1
}

$roleAssignmentsPath = Join-Path -Path $projectRoot -ChildPath '.specrew\role-assignments.yml'
$roleAssignmentsContent = @'
# Role Assignments
# Schema: v1

roles:
  - name: "Spec Steward"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "codex"
    responsibilities: "Spec integrity"

  - name: "Planner"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "copilot"
    responsibilities: "Planning"

  - name: "Implementer"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "copilot"
    responsibilities: "Implementation"

  - name: "Reviewer"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "claude"
    responsibilities: "Review"

  - name: "Retro Facilitator"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "copilot"
    responsibilities: "Retrospective"
'@
[System.IO.File]::WriteAllText($roleAssignmentsPath, $roleAssignmentsContent, [System.Text.UTF8Encoding]::new($false))

$iterationConfigPath = Join-Path -Path $projectRoot -ChildPath '.specrew\iteration-config.yml'
$iterationConfigWithDelegation = @'
# Iteration Configuration
# Schema: v1
effort_unit: "story_points"
capacity_per_iteration: 20
iteration_bounding: "scope"
time_limit_hours: null
overcommit_threshold: 1.0
calibration_enabled: true
defer_strategy: "manual"

# >>> specrew-managed agents >>>
# Specrew-managed delegated-agent opt-in and detection state (FR-022).
agents:
  copilot:
    enabled: true
    access_path: copilot_default
    availability: available
  claude:
    enabled: true
    access_path: copilot_agent_hq
    availability: available
  codex:
    enabled: true
    access_path: copilot_agent_hq
    availability: available
# <<< specrew-managed agents <<<
'@
[System.IO.File]::WriteAllText($iterationConfigPath, $iterationConfigWithDelegation, [System.Text.UTF8Encoding]::new($false))

$delegatedStartResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    'Add a clipboard sync feature',
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($delegatedStartResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed while testing roster preservation and delegated routing"
    foreach ($line in $delegatedStartResult.Output) {
        Write-Host $line
    }
    exit 1
}

$delegatedPromptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
$delegatedContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
$squadConfigPath = Join-Path -Path $projectRoot -ChildPath '.squad\config.json'
$decisionsPath = Join-Path -Path $projectRoot -ChildPath '.squad\decisions.md'
$squadConfig = Get-Content -LiteralPath $squadConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

if (-not (Assert-Contains -Content $delegatedPromptContent -Pattern 'Do NOT enter generic Squad team-setup mode or recast the roster' -FailureMessage 'Prompt did not explicitly preserve the existing Specrew-managed roster.')) {
    exit 1
}

if ($delegatedContext.team_roster.mode -ne 'specrew-managed') {
    Write-Fail 'Start context did not classify the current roster as Specrew-managed.'
    exit 1
}

$supplementalRoles = @($delegatedContext.team_roster.supplemental_members | ForEach-Object { $_.role })
if ($supplementalRoles -notcontains 'Frontend React Expert') {
    Write-Fail 'Start context did not preserve the supplemental roster member.'
    exit 1
}

if ($delegatedContext.delegated_routing.roles.Reviewer.effective_agent -ne 'claude') {
    Write-Fail 'Reviewer did not route to Claude when Claude was enabled and preferred.'
    exit 1
}

if ($delegatedContext.delegated_routing.roles.'Spec Steward'.effective_agent -ne 'codex') {
    Write-Fail 'Spec Steward did not route to Codex when Codex was enabled and preferred.'
    exit 1
}

if ($delegatedContext.squad_model_overrides.Reviewer -ne 'claude-sonnet-4.5') {
    Write-Fail 'Start context did not expose the Reviewer model override.'
    exit 1
}

if ($delegatedContext.squad_model_overrides.'Spec Steward' -ne 'gpt-5.2-codex') {
    Write-Fail 'Start context did not expose the Spec Steward model override.'
    exit 1
}

if ($null -eq $delegatedContext.delegated_routing_evidence -or
    $delegatedContext.delegated_routing_evidence.ledger_path -ne '.squad\decisions.md' -or
    @($delegatedContext.delegated_routing_evidence.required_fields) -notcontains 'model_id') {
    Write-Fail 'Start context did not expose the delegated runtime evidence contract.'
    exit 1
}

if ($squadConfig.agentModelOverrides.Reviewer -ne 'claude-sonnet-4.5' -or $squadConfig.agentModelOverrides.'Spec Steward' -ne 'gpt-5.2-codex') {
    Write-Fail 'specrew start did not persist delegated model overrides into .squad\config.json.'
    exit 1
}

if ($null -eq $squadConfig.specrewManagedModelRouting) {
    Write-Fail 'specrew start did not persist Specrew-managed model-routing metadata into .squad\config.json.'
    exit 1
}

if ($squadConfig.specrewManagedModelRouting.baselineAgentModelOverrides.Reviewer -ne 'claude-sonnet-4.5' -or
    $squadConfig.specrewManagedModelRouting.roleAgentFamilies.Reviewer -ne 'claude' -or
    $squadConfig.specrewManagedModelRouting.roleAgentFamilies.Planner -ne 'copilot') {
    Write-Fail 'specrew start did not persist the baseline override map and role agent families needed for live escalation.'
    exit 1
}

if (-not (Test-Path -LiteralPath $decisionsPath -PathType Leaf)) {
    Write-Fail 'specrew start did not create delegated routing evidence in .squad\decisions.md.'
    exit 1
}

$delegatedDecisions = Get-Content -LiteralPath $decisionsPath -Raw -Encoding UTF8
foreach ($pattern in @(
        'Delegated routing plan',
        'Reviewer \| requested=claude \| actual=claude \| model=claude-sonnet-4\.5 \| status=honored',
        'Spec Steward \| requested=codex \| actual=codex \| model=gpt-5\.2-codex \| status=honored'
    )) {
    if ($delegatedDecisions -notmatch $pattern) {
        Write-Fail "Delegated routing ledger is missing expected content matching: $pattern"
        exit 1
    }
}

Write-Pass "Start command preserves the Specrew roster and serializes delegated routing"

Write-Host "`nTest 7: start command records fallback reasons when a delegated agent is unavailable"
$iterationConfigWithFallback = @'
# Iteration Configuration
# Schema: v1
effort_unit: "story_points"
capacity_per_iteration: 20
iteration_bounding: "scope"
time_limit_hours: null
overcommit_threshold: 1.0
calibration_enabled: true
defer_strategy: "manual"

# >>> specrew-managed agents >>>
# Specrew-managed delegated-agent opt-in and detection state (FR-022).
agents:
  copilot:
    enabled: true
    access_path: copilot_default
    availability: available
  claude:
    enabled: true
    access_path: copilot_agent_hq
    availability: available
  codex:
    enabled: false
    access_path: copilot_agent_hq
    availability: available
# <<< specrew-managed agents <<<
'@
[System.IO.File]::WriteAllText($iterationConfigPath, $iterationConfigWithFallback, [System.Text.UTF8Encoding]::new($false))

$fallbackStartResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    'Harden delegated review routing',
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($fallbackStartResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed while testing delegated fallback logging"
    foreach ($line in $fallbackStartResult.Output) {
        Write-Host $line
    }
    exit 1
}

$fallbackContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
$specStewardPlan = $fallbackContext.delegated_routing.roles.'Spec Steward'
if ($specStewardPlan.effective_agent -ne 'claude') {
    Write-Fail 'Spec Steward did not fall back to Claude when Codex was disabled.'
    exit 1
}

$fallbackEvents = @($fallbackContext.delegated_routing.fallback_events)
$specStewardFallback = @($fallbackEvents | Where-Object { $_.role -eq 'Spec Steward' })
if ($specStewardFallback.Count -eq 0 -or $specStewardFallback[0].reason -notmatch "preferred agent 'codex' is not enabled") {
    Write-Fail 'Delegated routing fallback reason was not recorded for Spec Steward.'
    exit 1
}

$fallbackDecisions = Get-Content -LiteralPath $decisionsPath -Raw -Encoding UTF8
if ($fallbackDecisions -notmatch "Spec Steward \| requested=codex \| actual=claude \| model=claude-sonnet-4\.5 \| status=fell-back \| fallback=preferred agent 'codex' is not enabled") {
    Write-Fail 'Delegated routing fallback was not written to the decisions ledger.'
    exit 1
}

Write-Pass "Start command records delegated routing fallback reasons"

Write-Host "`nAll tests passed!"

Write-Host "Cleaning up test artifacts..."
if (Test-Path -Path $scratchRoot) {
    Remove-Item -Path $scratchRoot -Recurse -Force
}

exit 0
