# T028: consumer assumption advisory, rendered-prompt inoculation, and
# heterogeneous-project applicability fixtures.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$sourceChecker = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/test-consumer-assumptions.ps1'
$mirrorChecker = Join-Path $repoRoot '.specify/extensions/specrew-speckit/scripts/test-consumer-assumptions.ps1'
$sourceRules = Join-Path $repoRoot 'extensions/specrew-speckit/data/self-leak-deny-list.json'
$mirrorRules = Join-Path $repoRoot '.specify/extensions/specrew-speckit/data/self-leak-deny-list.json'
$script:failCount = 0

foreach ($dependency in @(
        'scripts/internal/bootstrap/SessionStateAccessor.ps1',
        'scripts/internal/launch-contract.ps1',
        'scripts/internal/coordinator-resume.ps1',
        'extensions/specrew-speckit/scripts/shared-governance.ps1',
        'scripts/internal/continuous-co-review/worktree-reviewer.ps1',
        'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1'
    )) {
    . (Join-Path $repoRoot $dependency)
}

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }

function New-ConsumerFixture {
    param([string]$Name)
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("consumer-firewall-{0}-{1}" -f $Name, [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specify/extensions/specrew-speckit/data'), (Join-Path $root 'docs') | Out-Null
    Copy-Item -LiteralPath $sourceRules -Destination (Join-Path $root '.specify/extensions/specrew-speckit/data/self-leak-deny-list.json')
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew') | Out-Null
    "boundary_enforcement:`n  policy_classes: {}`n" | Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Encoding UTF8
    "release_model: local-only`nrelease_model_provenance: recorded`npublish_target: null`n" | Set-Content -LiteralPath (Join-Path $root '.specrew/repository-governance.yml') -Encoding UTF8
    $root
}

function Invoke-ConsumerCheck {
    param([string]$FixtureRoot)
    $result = & $sourceChecker -ProjectPath $FixtureRoot -PassThru 3>$null
    if ($LASTEXITCODE -ne 0) { throw "consumer checker exited $LASTEXITCODE" }
    $result
}

Write-Host 'Test 1: shipped reader/rule mirrors and package manifest stay identical'
if ((Get-FileHash $sourceChecker).Hash -ne (Get-FileHash $mirrorChecker).Hash) { Write-Fail 'consumer checker source/deployed mirrors differ' } else { Write-Pass 'consumer checker mirrors are byte-identical' }
if ((Get-FileHash $sourceRules).Hash -ne (Get-FileHash $mirrorRules).Hash) { Write-Fail 'deny-list source/deployed mirrors differ' } else { Write-Pass 'both readers consume the same shipped deny-list' }
$manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $repoRoot 'Specrew.psd1')
if ('extensions/specrew-speckit/scripts/test-consumer-assumptions.ps1' -notin @($manifest.FileList)) { Write-Fail 'consumer checker is absent from package FileList' } else { Write-Pass 'consumer checker is in package FileList' }

Write-Host 'Test 2: user-authored mandates are flagged but never rewritten'
$fixture = New-ConsumerFixture -Name 'advisory'
$authoredPath = Join-Path $fixture 'docs/instructions.md'
$authored = "The project must run pytest before handoff.`nThe project must use GitHub for delivery."
$authored | Set-Content -LiteralPath $authoredPath -Encoding UTF8
$beforeHash = (Get-FileHash $authoredPath).Hash
$result = Invoke-ConsumerCheck -FixtureRoot $fixture
$afterHash = (Get-FileHash $authoredPath).Hash
if (-not $result.rules_valid -or $result.finding_count -ne 2) { Write-Fail "expected two advisory findings, got $($result.finding_count)" } else { Write-Pass 'stack and delivery mandates are both flagged' }
if ($beforeHash -ne $afterHash) { Write-Fail 'consumer checker rewrote a user-authored file' } else { Write-Pass 'consumer checker is flag-only for user-authored files' }
Remove-Item -Recurse -Force $fixture

Write-Host 'Test 3: heterogeneous Python/non-Pester, non-GitHub, no-publish fixture is clean'
$fixture = New-ConsumerFixture -Name 'heterogeneous'
@'
[project]
name = "lighthouse-api"
requires-python = ">=3.12"
'@ | Set-Content -LiteralPath (Join-Path $fixture 'pyproject.toml') -Encoding UTF8
@'
# Lighthouse verification and delivery

Python is the detected project language; naming it is not itself a mandate.

<!-- specrew-applicability: project-detected; pyproject.toml and the committed verification plan select pytest -->
This project must run pytest before handoff.

<!-- specrew-applicability: provider-gated; repository governance resolves the configured forge as GitLab -->
This project must use GitLab for remote review when a remote is configured.

The release model is local-only. There is no publish target and branch-ready evidence is complete.
'@ | Set-Content -LiteralPath (Join-Path $fixture 'docs/project-guidance.md') -Encoding UTF8
$result = Invoke-ConsumerCheck -FixtureRoot $fixture
if (-not $result.rules_valid -or $result.finding_count -ne 0) { Write-Fail "heterogeneous fixture produced $($result.finding_count) finding(s)" } else { Write-Pass 'Python/pytest, GitLab, and local-only guidance pass only with grounded applicability' }
Remove-Item -Recurse -Force $fixture

Write-Host 'Test 4: rendered prompt surfaces remain about anything-but-Specrew'
$fixture = New-ConsumerFixture -Name 'rendered-prompts'
$renderRoot = Join-Path $fixture 'docs/rendered'
$surfaces = @()
foreach ($relativeRoot in @('extensions/specrew-speckit/prompts', 'extensions/specrew-speckit/refocus', 'extensions/specrew-speckit/templates', 'extensions/specrew-speckit/squad-templates/coordinator')) {
    $surfaces += @(Get-ChildItem -LiteralPath (Join-Path $repoRoot $relativeRoot) -Recurse -File -Include *.md)
}
$surfaces += @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/squad-templates/agents') -Recurse -File -Filter charter.md)
$surfaces += Get-Item -LiteralPath (Join-Path $repoRoot 'templates/github/agents/squad.agent.md')
$sourceSurfaces = @($surfaces)
foreach ($surface in $surfaces) {
    $relative = [System.IO.Path]::GetRelativePath($repoRoot, $surface.FullName)
    $target = Join-Path $renderRoot $relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    $rendered = (Get-Content -LiteralPath $surface.FullName -Raw -Encoding UTF8).
        Replace('{{project_root}}', $fixture).
        Replace('{{project_name}}', 'lighthouse-api').
        Replace('{{feature_dir}}', 'specs/001-lighthouse')
    $rendered | Set-Content -LiteralPath $target -Encoding UTF8
}

$runtimeRenderRoot = Join-Path $renderRoot 'runtime'
New-Item -ItemType Directory -Force -Path $runtimeRenderRoot | Out-Null
$startPrompt = Get-StartPrompt -ResolvedProjectPath $fixture -Mode 'resume-feature' -FeatureRequest 'Improve lighthouse routing' `
    -ResolvedFeaturePath $null -TeamRoster ([pscustomobject]@{ mode = 'none' }) `
    -RoutingPlan ([pscustomobject]@{ enabled_agents = @(); roles = @{}; fallback_events = @() }) `
    -ProjectState ([pscustomobject]@{ state = 'active'; spec_directories = @(); detected_entries = @() }) `
    -BrownfieldDiscovery $null -DeliveryGuidance $null -SessionState $null -RecoverySession $null
$startPrompt | Set-Content -LiteralPath (Join-Path $renderRoot 'runtime/start-prompt.md') -Encoding UTF8

$reviewPrompt = Get-ContinuousCoReviewSlimPrompt -RunId 'fixture-review' -RoundNumber 2 -MaxRounds 2 `
    -PriorFindings '{"findings":[]}' -ImplementerEvidencePresent
$reviewPrompt | Set-Content -LiteralPath (Join-Path $renderRoot 'runtime/reviewer-round.md') -Encoding UTF8

$navigatorDecision = New-ReviewCampaignVerdictPacketDecision -Route 'review-partial' -Reason 'fixture-partial' `
    -Message 'The current review is partial evidence.' -CampaignId 'fixture-campaign' -RunId 'fixture-review' `
    -TargetDigest 'fixture-digest' -ImplementerAction 'request-current-review'
$navigatorNote = Build-ReviewCampaignNavigatorStopBlock -PacketDecision $navigatorDecision
$navigatorNote | Set-Content -LiteralPath (Join-Path $renderRoot 'runtime/navigator-inject-note.md') -Encoding UTF8
$surfaces += Get-Item -LiteralPath (Join-Path $renderRoot 'runtime/start-prompt.md'), (Join-Path $renderRoot 'runtime/reviewer-round.md'), (Join-Path $renderRoot 'runtime/navigator-inject-note.md')
$result = Invoke-ConsumerCheck -FixtureRoot $fixture
if ($surfaces.Count -lt 10) { Write-Fail "prompt fixture covered too few surfaces ($($surfaces.Count))" }
elseif (-not $result.rules_valid -or $result.finding_count -ne 0) {
    $detail = @($result.findings | ForEach-Object { "$($_.path):$($_.line) [$($_.class)]" }) -join '; '
    Write-Fail "rendered anything-but-Specrew prompts produced findings: $detail"
}
else { Write-Pass "all $($surfaces.Count) prompt/refocus/coordinator surfaces render with zero consumer-assumption hits" }
Remove-Item -Recurse -Force $fixture

Write-Host 'Test 5: damaged/newer consumer rule surface warns fail-open, never false-greens'
$fixture = New-ConsumerFixture -Name 'newer-schema'
$rulePath = Join-Path $fixture '.specify/extensions/specrew-speckit/data/self-leak-deny-list.json'
'{ "schema_version": "9.0" }' | Set-Content -LiteralPath $rulePath -Encoding UTF8
$result = Invoke-ConsumerCheck -FixtureRoot $fixture
if ($result.rules_valid -or @($result.warnings).Count -eq 0) { Write-Fail 'unknown schema did not return an explicit unavailable-rule warning' } else { Write-Pass 'unknown consumer schema is advisory and explicitly unevaluated' }
Remove-Item -Recurse -Force $fixture

Write-Host 'Test 6: gateway and update use the deployed checker after managed refresh'
$workflow = Get-Content -LiteralPath (Join-Path $repoRoot 'templates/github/workflows/specrew-methodology-gate.yml') -Raw
$update = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/specrew-update.ps1') -Raw
if ($workflow -notmatch [regex]::Escape('./.specify/extensions/specrew-speckit/scripts/test-consumer-assumptions.ps1') -or $workflow -notmatch 'advisory') { Write-Fail 'methodology gateway does not call the deployed advisory checker' } else { Write-Pass 'methodology gateway calls the deployed advisory checker' }
$refreshAt = $update.IndexOf('$templateRefreshActions = @(')
$checkerAt = $update.IndexOf("'.specify/extensions/specrew-speckit/scripts/test-consumer-assumptions.ps1'")
if ($refreshAt -lt 0 -or $checkerAt -le $refreshAt) { Write-Fail 'update checker is not sequenced after hash-aware managed refresh' } else { Write-Pass 'update heals eligible managed files before running the flag-only consumer advisory' }

Write-Host 'Test 7: platform/path inoculation is neutral in deployed teaching'
$deployedText = @($sourceSurfaces | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join "`n"
if ($deployedText -match '(?i)C:\\Dev\\Specrew|C:/Dev/Specrew|PowerShell terminals') { Write-Fail 'deployed prompt teaching still contains a self path or unconditional terminal assumption' } else { Write-Pass 'deployed prompt teaching contains no self path or unconditional PowerShell-terminal rule' }
$general = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/refocus/general.md') -Raw
if ($general -notmatch 'Specrew is the methodology tool, never the project') { Write-Fail 'refocus identity inoculation is absent' } else { Write-Pass 'refocus explicitly separates governed project identity from the Specrew tool' }

Write-Host ''
if ($script:failCount -gt 0) { Write-Host "$script:failCount test(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host 'All consumer applicability firewall tests passed.' -ForegroundColor Green
exit 0
