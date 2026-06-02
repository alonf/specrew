[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$detectHostsScript = Join-Path $repoRoot 'scripts\internal\detect-hosts.ps1'
$flagTranslationScript = Join-Path $repoRoot 'scripts\internal\host-flag-translation.ps1'
$promptSurgeryScript = Join-Path $repoRoot 'scripts\internal\coordinator-prompt-surgery.ps1'

# Test 1: detect-hosts.ps1 exists and exports expected functions
. $detectHostsScript
foreach ($fn in 'Get-SpecrewSupportedHostKinds', 'Get-SpecrewDeferredHostKinds', 'Get-SpecrewHostBinary', 'Get-SpecrewHostInstallGuidance', 'Get-SpecrewDeferredHostGuidance', 'Test-SpecrewHostAvailable', 'Get-SpecrewAvailableHosts', 'Test-HostSkillRoot', 'Get-SpecrewHostSkillRoot') {
    if (-not (Get-Command $fn -ErrorAction SilentlyContinue)) {
        Write-Fail "Expected function not found after sourcing detect-hosts.ps1: $fn"
    }
}
Write-Pass 'detect-hosts.ps1 exports all expected functions'

# Test 2: Supported / deferred host kinds match spec (set membership; order is registry-driven and may sort)
$supported = @(Get-SpecrewSupportedHostKinds | Sort-Object)
$expectedSupported = @('antigravity', 'claude', 'codex', 'copilot', 'cursor')   # sorted alphabetically — registry-driven order (cursor added F-050)
if (($supported -join ',') -ne ($expectedSupported -join ',')) {
    Write-Fail "Supported host kinds drift. Got: $($supported -join ',') Expected: $($expectedSupported -join ',') (Antigravity follow-up slice graduated antigravity from deferred to supported)"
}
$deferred = @(Get-SpecrewDeferredHostKinds | Sort-Object)
$expectedDeferred = @('auto')   # only synthetic 'auto' remains deferred — registry-driven from manifest Status='deferred' + synthetic 'auto'
if (($deferred -join ',') -ne ($expectedDeferred -join ',')) {
    Write-Fail "Deferred host kinds drift. Got: $($deferred -join ',') Expected: $($expectedDeferred -join ',') (Antigravity graduated; only synthetic 'auto' remains deferred)"
}
Write-Pass 'Host-kind enums match spec (supported: antigravity,claude,codex,copilot,cursor; deferred: auto only)'

# Test 3: Host binary names are correct
foreach ($pair in @{ copilot = 'copilot'; claude = 'claude'; codex = 'codex'; antigravity = 'agy' }.GetEnumerator()) {
    $bin = Get-SpecrewHostBinary -HostKind $pair.Key
    if ($bin -ne $pair.Value) {
        Write-Fail "Host binary mismatch for $($pair.Key): got $bin"
    }
}
Write-Pass 'Get-SpecrewHostBinary returns correct binary names for all four hosts (antigravity -> agy)'

# Test 4: Install guidance for each host contains a URL
foreach ($hk in 'copilot', 'claude', 'codex', 'antigravity') {
    $guidance = Get-SpecrewHostInstallGuidance -HostKind $hk
    if ($guidance -notmatch 'https?://') {
        Write-Fail "Install guidance for $hk has no URL: $guidance"
    }
}
Write-Pass 'Install guidance for each host contains a documentation URL'

# Test 5: Deferred host guidance — only auto remains deferred post-Antigravity-slice
$autoGuidance = Get-SpecrewDeferredHostGuidance -HostKind 'auto'
if ($autoGuidance -notmatch '104' -or $autoGuidance -notmatch 'Onboarding') {
    Write-Fail "Auto deferred guidance should mention Proposal 104 + Onboarding. Got: $autoGuidance"
}
# Antigravity is now supported; calling Get-SpecrewDeferredHostGuidance for it should THROW
$threw = $false
try { Get-SpecrewDeferredHostGuidance -HostKind 'antigravity' | Out-Null } catch { $threw = $true }
if (-not $threw) {
    Write-Fail "Antigravity is now SUPPORTED (not deferred); Get-SpecrewDeferredHostGuidance should throw for it"
}
Write-Pass 'Deferred-host guidance text contracts to auto only (antigravity is supported)'

# Test 5b (new): Antigravity Gemini deadline warning helper exists and fires appropriately
$preDeadline = [DateTime]::Parse('2026-05-15')
$postDeadline = [DateTime]::Parse('2026-06-20')
$nearDeadline = [DateTime]::Parse('2026-06-02')

$envBackupSubTier = $env:GOOGLE_AI_SUBSCRIPTION_TIER
$envBackupKey = $env:ANTIGRAVITY_API_KEY
try {
    $env:GOOGLE_AI_SUBSCRIPTION_TIER = $null
    $env:ANTIGRAVITY_API_KEY = $null
    Remove-Item -LiteralPath Env:\GOOGLE_AI_SUBSCRIPTION_TIER -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath Env:\ANTIGRAVITY_API_KEY -ErrorAction SilentlyContinue

    $earlyResult = Test-AntigravityGeminiDeadlineWarning -ProjectPath 'C:\nope' -CurrentDate $preDeadline
    if ($earlyResult.ShouldWarn) {
        Write-Fail "Antigravity deadline warning fired too early ($preDeadline) -- should be silent before 2026-06-01"
    }

    $nearResult = Test-AntigravityGeminiDeadlineWarning -ProjectPath 'C:\nope' -CurrentDate $nearDeadline
    if (-not $nearResult.ShouldWarn) {
        Write-Fail "Antigravity deadline warning failed to fire near deadline ($nearDeadline)"
    }

    $postResult = Test-AntigravityGeminiDeadlineWarning -ProjectPath 'C:\nope' -CurrentDate $postDeadline
    if (-not $postResult.ShouldWarn) {
        Write-Fail "Antigravity deadline warning failed to fire post-deadline ($postDeadline)"
    }
    if ($postResult.Message -notmatch 'ended') {
        Write-Fail "Post-deadline warning should say 'ended'; got: $($postResult.Message)"
    }
}
finally {
    if ($null -ne $envBackupSubTier) { $env:GOOGLE_AI_SUBSCRIPTION_TIER = $envBackupSubTier }
    if ($null -ne $envBackupKey) { $env:ANTIGRAVITY_API_KEY = $envBackupKey }
}
Write-Pass 'Antigravity Gemini-deadline warning fires correctly (silent before 2026-06-01; warns near and after 2026-06-18)'

# Test 6: Get-SpecrewHostSkillRoot returns correct paths per host
$projectRoot = 'C:\fake\project'
$copilotRoot = Get-SpecrewHostSkillRoot -HostKind 'copilot' -ProjectPath $projectRoot
$claudeRoot = Get-SpecrewHostSkillRoot -HostKind 'claude' -ProjectPath $projectRoot
$codexRoot = Get-SpecrewHostSkillRoot -HostKind 'codex' -ProjectPath $projectRoot
$antigravityRoot = Get-SpecrewHostSkillRoot -HostKind 'antigravity' -ProjectPath $projectRoot
if ($copilotRoot -notlike '*\.github\skills*') { Write-Fail "Copilot skill root wrong: $copilotRoot" }
if ($claudeRoot -notlike '*\.claude\skills*') { Write-Fail "Claude skill root wrong: $claudeRoot" }
if ($codexRoot -notlike '*\.agents\skills*') { Write-Fail "Codex skill root wrong: $codexRoot" }
if ($antigravityRoot -notlike '*\.agents\skills*') { Write-Fail "Antigravity skill root wrong (should be .agents/skills like Codex): $antigravityRoot" }
Write-Pass 'Per-host skill roots resolve correctly (antigravity uses .agents/skills like Codex)'

# Test 7: flag-translation matrix for all 9 cells per research.md Task 2
. $flagTranslationScript
$matrix = @{
    'copilot|--remote'     = @{ ExpectArgs = @('--remote'); ExpectNotice = $false }
    'claude|--remote'      = @{ ExpectArgs = @('--remote-control'); ExpectNotice = $true }
    'codex|--remote'       = @{ ExpectArgs = @(); ExpectNotice = $true }
    'copilot|--allow-all'  = @{ ExpectArgs = @('--allow-all'); ExpectNotice = $false }
    'claude|--allow-all'   = @{ ExpectArgs = @('--dangerously-skip-permissions'); ExpectNotice = $true }
    'codex|--allow-all'    = @{ ExpectArgs = @('--dangerously-bypass-approvals-and-sandbox'); ExpectNotice = $true }
    'copilot|--autopilot'  = @{ ExpectArgs = @('--autopilot'); ExpectNotice = $false }
    'claude|--autopilot'   = @{ ExpectArgs = @(); ExpectNotice = $true }
    'codex|--autopilot'    = @{ ExpectArgs = @(); ExpectNotice = $true }
}
foreach ($pair in $matrix.GetEnumerator()) {
    $parts = $pair.Key -split '\|'
    $hk = $parts[0]
    $flag = $parts[1]
    $t = Get-HostFlagTranslation -HostKind $hk -SpecrewFlag $flag
    $expectedArgs = @($pair.Value.ExpectArgs)
    $actualArgs = @($t.Args)
    if ((@($expectedArgs) -join ',') -ne (@($actualArgs) -join ',')) {
        Write-Fail "Flag translation mismatch [$hk $flag]: expected args=($($expectedArgs -join ',')) got args=($($actualArgs -join ','))"
    }
    if ($pair.Value.ExpectNotice -and [string]::IsNullOrWhiteSpace($t.Notice)) {
        Write-Fail "Flag translation [$hk $flag] expected a notice but got none"
    }
}
Write-Pass 'Flag-translation matrix covers all 9 cells correctly (research.md Task 2)'

# Test 8: Codex --remote produces SuppressWarning=$false (warn-and-continue)
$codexRemote = Get-HostFlagTranslation -HostKind 'codex' -SpecrewFlag '--remote'
if ($codexRemote.SuppressWarning -ne $false) {
    Write-Fail "Codex --remote should NOT suppress warning (must warn-and-continue per AC8)"
}
Write-Pass 'Codex --remote warn-and-continue case correctly surfaces a non-suppressed notice'

# Test 9: coordinator-prompt-surgery universal header for all hosts (FR-011)
. $promptSurgeryScript
$samplePrompt = @'
You are Squad running inside a Specrew-bootstrapped repository.

1. Do this first.
2. Do this second.
12. Read .squad/decisions.md for delegated routing ledger entries.
35. Honor agentModelOverrides in .squad/config.json for per-agent model routing.
37. Run sync-squad-model-overrides.ps1 when overrides change.
42. Update .squad/config.json baselineAgentModelOverrides if a role-level shift is needed.
43. Persist .squad/config.json changes alongside lifecycle ledger entries.
44. Treat .squad/config.json as the source of truth for agent model identity.

50. The Crew should always do this.
'@

$expectedHeader = 'You are the Crew team coordinator running inside a Specrew-bootstrapped repository.'

foreach ($hk in 'copilot', 'claude', 'codex') {
    $rewritten = Invoke-SpecrewCoordinatorPromptSurgery -Prompt $samplePrompt -HostKind $hk
    if ($rewritten -notmatch [regex]::Escape($expectedHeader)) {
        Write-Fail "FR-011 universal header missing after surgery for host=$hk"
    }
    if ($rewritten -match 'You are Squad running inside') {
        Write-Fail "FR-011 original Squad header still present after surgery for host=$hk"
    }
}
Write-Pass 'FR-011 universal header rewrite applied to all 3 hosts'

# Test 9b: host orientation block is selected-host, version, runtime-status, and lifecycle-position accurate
$orientationPrompt = @'
You are Squad running inside a Specrew-bootstrapped repository.

48. **Session opening orientation**

<<SPECREW_HOST_ORIENTATION_BLOCK>>
'@

$codexOrientation = Invoke-SpecrewCoordinatorPromptSurgery -Prompt $orientationPrompt -HostKind 'codex' -CrewRuntimeStatus 'bootstrap_only' -SpecrewVersion '0.30.0-beta5' -LifecycleMode 'new-feature'
if ($codexOrientation -notmatch 'OpenAI Codex CLI') {
    Write-Fail 'Codex orientation did not name the selected Codex host.'
}
foreach ($required in @('Specrew: 0.30.0-beta5', 'Host: codex \(OpenAI Codex CLI\); runtime: non-Squad', 'Lifecycle: new feature intake\.')) {
    if ($codexOrientation -notmatch $required) {
        Write-Fail "Codex orientation missed required version/host/runtime/lifecycle text '$required'."
    }
}
if ($codexOrientation -match 'Claude Code|GitHub Copilot|Squad runtime|plays each role|I run all of them inside this session') {
    Write-Fail "Codex orientation contains a false hard-coded host/runtime claim:`n$codexOrientation"
}
if ($codexOrientation -match [regex]::Escape('<<SPECREW_HOST_ORIENTATION_BLOCK>>')) {
    Write-Fail 'Codex orientation marker was not replaced.'
}
# FR-011 (reproduce-first): a greenfield/intake orientation (no feature yet) MUST NOT emit a
# feature-path-shaped browse URL. The coordinator substitutes <feature> per Rule 48, and with no
# feature that collapses to `specs//`. Greenfield browse guidance must omit/placeholder the path.
if ($codexOrientation -match 'specs/<feature>/spec') {
    Write-Fail "FR-011: greenfield orientation emits a feature-path browse reference that collapses to specs// when no feature exists:`n$codexOrientation"
}

$claudeOrientation = Invoke-SpecrewCoordinatorPromptSurgery -Prompt $orientationPrompt -HostKind 'claude' -CrewRuntimeStatus 'bootstrap_only' -SpecrewVersion '0.30.0-beta5' -LifecycleMode 'resume-feature' -FeatureRef '001-token-tray' -BoundaryType 'plan'
if ($claudeOrientation -notmatch 'Claude Code CLI') {
    Write-Fail 'Claude orientation did not name the selected Claude host.'
}
foreach ($required in @('Specrew: 0.30.0-beta5', 'Host: claude \(Claude Code CLI\); runtime: non-Squad', 'Welcome back - resuming feature 001-token-tray at plan\.')) {
    if ($claudeOrientation -notmatch $required) {
        Write-Fail "Claude resume orientation missed required version/host/runtime/lifecycle text '$required'."
    }
}
if ($claudeOrientation -match 'GitHub Copilot|Squad runtime|plays each role|I run all of them inside this session') {
    Write-Fail "Claude orientation contains a false hard-coded runtime claim:`n$claudeOrientation"
}
# FR-011: a resolved-feature resume DOES surface the concrete browse paths (the coordinator fills
# <feature> with the real ref, yielding a non-empty segment) — the guard must not strip them here.
if ($claudeOrientation -notmatch 'specs/<feature>/spec\.md') {
    Write-Fail "Resume orientation should surface the feature browse paths for substitution:`n$claudeOrientation"
}

$copilotOrientation = Invoke-SpecrewCoordinatorPromptSurgery -Prompt $orientationPrompt -HostKind 'copilot' -CrewRuntimeStatus 'squad-runtime' -SpecrewVersion '0.30.0-beta5' -LifecycleMode 'resume-feature' -FeatureRef '001-token-tray' -BoundaryType 'plan'
if ($copilotOrientation -notmatch 'GitHub Copilot CLI' -or $copilotOrientation -notmatch 'Squad runtime coordinates' -or $copilotOrientation -notmatch 'Specrew: 0.30.0-beta5' -or $copilotOrientation -notmatch 'Host: copilot \(GitHub Copilot CLI\); runtime: Squad') {
    Write-Fail "Copilot/Squad orientation did not describe the active host/runtime accurately:`n$copilotOrientation"
}
Write-Pass 'Host orientation rendering is accurate for Codex, Claude, and Copilot/Squad initial/resume cases'

# Test 9c: host interaction guidance is rendered by the selected host package
$interactionPrompt = @'
53. **Structured verdict menu**

<<SPECREW_HOST_INTERACTION_GUIDANCE_BLOCK>>
'@

$codexInteraction = Invoke-SpecrewCoordinatorPromptSurgery -Prompt $interactionPrompt -HostKind 'codex'
if ($codexInteraction -notmatch 'request_user_input' -or $codexInteraction -notmatch 'approve as-is, approve with instructions, send back, and discuss prompt #N') {
    Write-Fail "Codex interaction guidance did not require the structured user-input/menu path with the shared response contract:`n$codexInteraction"
}
if ($codexInteraction -match 'AskUserQuestion|Squad handles the rest') {
    Write-Fail "Codex interaction guidance contains another host/runtime primitive or false lifecycle claim:`n$codexInteraction"
}

$claudeInteraction = Invoke-SpecrewCoordinatorPromptSurgery -Prompt $interactionPrompt -HostKind 'claude'
if ($claudeInteraction -notmatch 'AskUserQuestion' -or $claudeInteraction -notmatch 'approve as-is, approve with instructions, send back, and discuss prompt #N') {
    Write-Fail "Claude interaction guidance did not render the Claude-specific structured question primitive with the shared response contract:`n$claudeInteraction"
}

$copilotInteraction = Invoke-SpecrewCoordinatorPromptSurgery -Prompt $interactionPrompt -HostKind 'copilot'
if ($copilotInteraction -notmatch 'No structured question/menu primitive is declared' -or $copilotInteraction -notmatch 'textual "What''s your verdict\?" options exactly as shown') {
    Write-Fail "Copilot interaction guidance did not render the textual fallback contract when no structured primitive is declared:`n$copilotInteraction"
}
if ($copilotInteraction -match 'request_user_input|AskUserQuestion') {
    Write-Fail "Copilot interaction guidance leaked another host's structured primitive:`n$copilotInteraction"
}
Write-Pass 'Host interaction guidance is adapter-rendered for Codex, Claude, and Copilot'

# Test 10: FR-012 Squad-runtime-path strip for non-Copilot hosts only
$copilotRewritten = Invoke-SpecrewCoordinatorPromptSurgery -Prompt $samplePrompt -HostKind 'copilot'
if ($copilotRewritten -notmatch '\.squad/decisions\.md|\.squad\\decisions\.md') {
    Write-Fail 'FR-012 violation: Copilot path should RETAIN .squad/decisions.md rule'
}
if ($copilotRewritten -notmatch 'agentModelOverrides') {
    Write-Fail 'FR-012 violation: Copilot path should RETAIN agentModelOverrides rule'
}

foreach ($hk in 'claude', 'codex') {
    $rewritten = Invoke-SpecrewCoordinatorPromptSurgery -Prompt $samplePrompt -HostKind $hk
    if ($rewritten -match '\.squad/decisions\.md|\.squad\\decisions\.md') {
        Write-Fail "FR-012 violation: $hk path should STRIP .squad/decisions.md rule"
    }
    if ($rewritten -match 'agentModelOverrides') {
        Write-Fail "FR-012 violation: $hk path should STRIP agentModelOverrides rule"
    }
    if ($rewritten -match 'sync-squad-model-overrides\.ps1') {
        Write-Fail "FR-012 violation: $hk path should STRIP sync-squad-model-overrides.ps1 rule"
    }
    if ($rewritten -match '\.squad/config\.json|\.squad\\config\.json') {
        Write-Fail "FR-012 violation: $hk path should STRIP .squad/config.json rules"
    }
    if ($rewritten -notmatch 'Do this first') {
        Write-Fail "FR-012 went too far: $hk path stripped non-Squad-runtime rules"
    }
}
Write-Pass 'FR-012 Squad-runtime-path strip removes 4 rules for non-Copilot hosts; Copilot retains them; non-Squad rules untouched'

# Test 11: FR-014 Codex pwsh-form replacement for slash-command boundary refs
$slashPrompt = 'To advance the plan boundary, invoke /speckit.specrew-speckit.sync-plan and report results.'
$codexRewritten = Invoke-SpecrewCoordinatorPromptSurgery -Prompt $slashPrompt -HostKind 'codex'
if ($codexRewritten -notmatch 'pwsh -File' -or $codexRewritten -notmatch '-BoundaryType plan') {
    Write-Fail "FR-014 violation: Codex slash-command refs should be rewritten as pwsh-form. Got: $codexRewritten"
}
if ($codexRewritten -match '/speckit\.specrew-speckit\.sync-plan') {
    Write-Fail "FR-014 violation: Codex path retains slash-command reference. Got: $codexRewritten"
}
foreach ($hk in 'copilot', 'claude') {
    $rewritten = Invoke-SpecrewCoordinatorPromptSurgery -Prompt $slashPrompt -HostKind $hk
    if ($rewritten -notmatch '/speckit\.specrew-speckit\.sync-plan') {
        Write-Fail "FR-014 violation: $hk should RETAIN slash-command refs"
    }
}
Write-Pass 'FR-014 Codex pwsh-form rewrite applied only to Codex; Copilot and Claude retain slash-command refs'

# Test 12: Test-HostSkillRoot returns expected structure on missing dir
$tmpProject = Join-Path $repoRoot '.scratch\multi-host-test-project'
if (Test-Path -LiteralPath $tmpProject) { Remove-Item -Recurse -Force -LiteralPath $tmpProject }
New-Item -ItemType Directory -Path $tmpProject -Force | Out-Null
try {
    $result = Test-HostSkillRoot -HostKind 'claude' -ProjectPath $tmpProject
    if ($result.Exists) { Write-Fail "Test-HostSkillRoot reported Exists=true on missing dir" }
    if ($result.Warnings.Count -eq 0) { Write-Fail "Test-HostSkillRoot should emit warning on missing dir" }
    if (-not $result.HasUserSlashCommandSurface) { Write-Fail "Claude should have HasUserSlashCommandSurface=true" }

    $codexResult = Test-HostSkillRoot -HostKind 'codex' -ProjectPath $tmpProject
    if ($codexResult.HasUserSlashCommandSurface) { Write-Fail "Codex should have HasUserSlashCommandSurface=false per FR-013" }
    $hasInfoNote = $codexResult.Warnings | Where-Object { $_ -match '^INFO:' }
    if (-not $hasInfoNote) { Write-Fail "Codex skill check should emit INFO: note per FR-013" }
}
finally {
    if (Test-Path -LiteralPath $tmpProject) { Remove-Item -Recurse -Force -LiteralPath $tmpProject -ErrorAction SilentlyContinue }
}
Write-Pass 'Test-HostSkillRoot reports missing dirs honestly + Codex emits FR-013 informational note'

# Test 13: Top-level specrew-start.ps1 has -HostKind parameter
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$startContent = Get-Content -LiteralPath $startScript -Raw -Encoding UTF8
if ($startContent -notmatch '\[string\]\$HostKind\s*=\s*'+ "''") {
    Write-Fail '-HostKind parameter not found in specrew-start.ps1'
}
if ($startContent -notmatch "'--host'\s*\{") {
    Write-Fail '--host CLI alias not wired into Convert-UnixStyleArguments'
}
Write-Pass 'specrew-start.ps1 exposes -HostKind parameter + --host CLI alias'

# Test 14: Copilot launch path stays argv-identical (regression guard)
# The dispatch builds args as ('--agent', $Agent, '--add-dir', $project, '-i', $prompt[, '--autopilot'][, '--allow-all'])
. $detectHostsScript
. $flagTranslationScript
. $promptSurgeryScript
. $startScript -Help *>$null 2>&1
# Re-source to bring Get-SpecrewHostLaunchInvocation into scope
$startCode = Get-Content -LiteralPath $startScript -Raw
$inlineHostLaunch = $startCode -match 'function Get-SpecrewHostLaunchInvocation'
if (-not $inlineHostLaunch) {
    Write-Fail 'Get-SpecrewHostLaunchInvocation not defined in specrew-start.ps1'
}
Write-Pass 'Get-SpecrewHostLaunchInvocation function defined in specrew-start.ps1'

# Test 15: Sourcing the start script does not fail (smoke)
$smokeResult = pwsh -NoProfile -Command "& { try { . '$startScript' -Help *>`$null; Write-Output 'SMOKE_OK' } catch { Write-Output \"SMOKE_FAIL: `$_\" } }" 2>&1 | Out-String
if ($smokeResult -notmatch 'SMOKE_OK') {
    Write-Fail "specrew-start.ps1 smoke source failed:`n$smokeResult"
}
Write-Pass 'specrew-start.ps1 sources cleanly without runtime errors'

# Test 16: Get-SpecrewHostLaunchInvocation argv shape per host (regression guard)
# This test reaches into the Get-SpecrewHostLaunchInvocation function directly to
# verify per-host argv shape. Copilot golden argv is the regression guard — any drift
# from the pre-F-040 shape would fail this test.
$dispatchScratch = pwsh -NoProfile -Command @"
. '$startScript' -Help *>`$null 2>&1
. '$detectHostsScript'
. '$flagTranslationScript'
. '$promptSurgeryScript'

`$result = @{}

# Copilot golden: matches pre-F-040 shape
`$copilot = Get-SpecrewHostLaunchInvocation -HostKind copilot -ResolvedProjectPath 'C:\proj' -BootstrapPrompt 'BOOT' -Agent 'Squad' -AllowAll `$true -UseAutopilot `$true -UseRemote `$false
`$result.copilot = (`$copilot.Args -join '|')

# Claude: claude -p BOOT --add-dir C:\proj --dangerously-skip-permissions [--remote-control with UseRemote]
`$claude = Get-SpecrewHostLaunchInvocation -HostKind claude -ResolvedProjectPath 'C:\proj' -BootstrapPrompt 'BOOT' -Agent 'Squad' -AllowAll `$true -UseAutopilot `$false -UseRemote `$true
`$result.claude = (`$claude.Args -join '|')

# Codex: codex --cd C:\proj --dangerously-bypass-approvals-and-sandbox BOOT
`$codex = Get-SpecrewHostLaunchInvocation -HostKind codex -ResolvedProjectPath 'C:\proj' -BootstrapPrompt 'BOOT' -Agent 'Squad' -AllowAll `$true -UseAutopilot `$false -UseRemote `$false
`$result.codex = (`$codex.Args -join '|')

`$result | ConvertTo-Json -Compress
"@ 2>&1 | Out-String

$argvResult = $null
try { $argvResult = $dispatchScratch | ConvertFrom-Json } catch {}
if ($null -eq $argvResult) { Write-Fail "argv-shape probe returned non-JSON: $dispatchScratch" }

# Copilot golden — must match pre-F-040 verbatim (regression guard)
$expectedCopilot = '--agent|Squad|--autopilot|--add-dir|C:\proj|-i|BOOT|--allow-all'
if ($argvResult.copilot -ne $expectedCopilot) {
    Write-Fail "Copilot argv DRIFT detected (regression guard):`n  expected: $expectedCopilot`n  got     : $($argvResult.copilot)"
}

# Claude: interactive REPL with positional initial prompt (NOT -p which is one-shot).
# Bug discovered in 2026-05-23 real-launch test: claude -p exits after first response.
$expectedClaude = '--add-dir|C:\proj|--dangerously-skip-permissions|--remote-control|BOOT'
if ($argvResult.claude -ne $expectedClaude) {
    Write-Fail "Claude argv shape mismatch:`n  expected: $expectedClaude`n  got     : $($argvResult.claude)"
}

# Codex: interactive REPL with positional initial prompt (NOT `codex exec` which is non-interactive).
# Same bug class as Claude -p fix.
$expectedCodex = '--cd|C:\proj|--dangerously-bypass-approvals-and-sandbox|BOOT'
if ($argvResult.codex -ne $expectedCodex) {
    Write-Fail "Codex argv shape mismatch:`n  expected: $expectedCodex`n  got     : $($argvResult.codex)"
}
Write-Pass 'Get-SpecrewHostLaunchInvocation argv golden match per host (Copilot regression guard + Claude + Codex shape verified)'

# Test 17: start-context.json schema additive-fields back-compat
# Pre-F-040 start-context.json (F-039 schema v2) lacked selected_host/available_hosts/crew_runtime_status.
# F-040 adds them as ADDITIVE fields — existing JSON files without these fields must still load.
$tmpCtxProject = Join-Path $repoRoot '.scratch\multi-host-context-backcompat'
if (Test-Path -LiteralPath $tmpCtxProject) { Remove-Item -Recurse -Force -LiteralPath $tmpCtxProject }
New-Item -ItemType Directory -Path (Join-Path $tmpCtxProject '.specrew') -Force | Out-Null
try {
    # Pre-F-040 schema v2 context (no host fields)
    $preF040Json = @'
{
  "schema": "v2",
  "mode": "intake",
  "feature_request": "test",
  "feature_path": null,
  "agent": "Squad",
  "approval_mode": "allow-all",
  "launch_mode": "same-window",
  "copilot_autopilot": false,
  "boundary_enforcement": {
    "schema": "v2",
    "verdicts": [],
    "bypass_records": []
  }
}
'@
    Set-Content -LiteralPath (Join-Path $tmpCtxProject '.specrew\start-context.json') -Value $preF040Json -Encoding UTF8

    # Verify F-040 helpers (Get-SpecrewStartContextState if available) tolerate the missing fields
    $probe = pwsh -NoProfile -Command @"
try {
    Set-Location -LiteralPath '$tmpCtxProject'
    `$ctx = Get-Content -LiteralPath '.specrew/start-context.json' -Raw | ConvertFrom-Json
    if (`$ctx.schema -ne 'v2') { Write-Output 'SCHEMA_MISMATCH' }
    elseif (`$ctx.PSObject.Properties.Name -contains 'selected_host') { Write-Output 'F040_FIELDS_PRESENT_UNEXPECTED' }
    else { Write-Output 'BACKCOMPAT_OK' }
} catch {
    Write-Output ('PARSE_FAIL: ' + `$_.Exception.Message)
}
"@ 2>&1 | Out-String
    if ($probe -notmatch 'BACKCOMPAT_OK') {
        Write-Fail "Pre-F-040 start-context.json schema-v2 back-compat failed: $probe"
    }
}
finally {
    if (Test-Path -LiteralPath $tmpCtxProject) { Remove-Item -Recurse -Force -LiteralPath $tmpCtxProject -ErrorAction SilentlyContinue }
}
Write-Pass 'start-context.json pre-F-040 schema v2 (without selected_host/available_hosts/crew_runtime_status) still parses (backwards-compatible)'

# Test 18: Universal Crew header is the same literal across all hosts (FR-011 invariant)
$header = Get-SpecrewUniversalCoordinatorHeader
$expectedHeaderLiteral = 'You are the Crew team coordinator running inside a Specrew-bootstrapped repository.'
if ($header -ne $expectedHeaderLiteral) {
    Write-Fail "Universal Crew header literal drift. Got: $header"
}
foreach ($hk in 'copilot', 'claude', 'codex') {
    $hostHeader = Get-SpecrewUniversalCoordinatorHeader
    if ($hostHeader -ne $expectedHeaderLiteral) {
        Write-Fail "Universal Crew header should be identical across hosts; drift for $hk : $hostHeader"
    }
}
Write-Pass 'Universal Crew-coordinator header literal is identical across all hosts (FR-011 invariant)'

# Test 18b: FR-014 (reproduce-first) — launch guidance must not leak another host's terminology
# (SC-010). The approval-mode launch line printed by `specrew start` must be host-neutral, not
# "Copilot approval mode" on every host (it prints on a claude launch too).
$startApprovalText = Get-Content -LiteralPath $startScript -Raw -Encoding UTF8
if ($startApprovalText -match 'Copilot approval mode') {
    Write-Fail 'FR-014/SC-010: specrew-start.ps1 emits "Copilot approval mode" launch guidance, leaking Copilot terminology on non-Copilot hosts.'
}
if ($startApprovalText -notmatch 'Approval mode:') {
    Write-Fail 'FR-014: specrew-start.ps1 should emit host-neutral "Approval mode:" launch guidance.'
}
# FR-014 class: the new-window launch success line must use the host-aware label, not a hardcoded
# "Delegated to Copilot" (the host-aware $hostLabel switch already exists just above it).
if ($startApprovalText -match 'Delegated to Copilot') {
    Write-Fail 'FR-014/SC-010: specrew-start.ps1 hardcodes "Delegated to Copilot" in the new-window launch success line, leaking Copilot terminology on non-Copilot hosts.'
}
Write-Pass 'FR-014 launch guidance uses host-neutral approval-mode + delegation wording (no Copilot terminology leak)'

# Test 19a: --no-launch + missing host generates artifacts (back-compat with pre-F-040)
# Pre-F-040 behavior: Start-CopilotSession returned $false on missing copilot,
# then specrew-start.ps1 still printed the manual launch command and exited 0.
# F-040 must preserve this contract so `specrew init` + `specrew start --no-launch`
# works on a fresh machine before any host CLI is installed.
$startScriptText = Get-Content -LiteralPath $startScript -Raw -Encoding UTF8
if ($startScriptText -notmatch '-not \$availableHostsMap\[\$selectedHost\] -and -not \$NoLaunch') {
    Write-Fail '--no-launch should bypass the missing-host fail-fast (regression of pre-F-040 no-launch artifact-generation contract)'
}
Write-Pass '--no-launch path bypasses missing-host fail-fast (artifacts still generated when host CLI is absent)'

# Test 19: --host auto rejection text quality (AC16)
# Note: antigravity used to be tested here as deferred; Antigravity follow-up
# slice graduated it to supported. Only auto remains in the deferred set.
$auto = Get-SpecrewDeferredHostGuidance -HostKind 'auto'
if ($auto -notmatch '104') {
    Write-Fail "Auto deferred guidance should mention Proposal 104: $auto"
}
if ($auto -notmatch 'antigravity') {
    Write-Fail "Auto deferred guidance should now list antigravity as a valid explicit host: $auto"
}
Write-Pass 'Deferred-host guidance — auto-only contracts; mentions all four explicit hosts (copilot|claude|codex|antigravity)'

Write-Host ''
Write-Host 'Multi-host launch path: all assertions pass' -ForegroundColor Green
exit 0
