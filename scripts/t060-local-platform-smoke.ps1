#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Preflight', 'Invoke')]
    [string] $Mode,

    [Parameter(Mandatory)]
    [ValidateSet('cursor-agent', 'antigravity', 'copilot')]
    [string] $HostName,

    [Parameter(Mandatory)]
    [string] $RepoRoot,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-f]{40}$')]
    [string] $ExpectedCommit,

    [Parameter(Mandatory)]
    [string] $OutputDirectory,

    [ValidatePattern('^run-[a-z0-9][a-z0-9-]{0,63}$')]
    [string] $RunId,

    [ValidateLength(1, 256)]
    [string] $AuthorizationRef,

    [Parameter(Mandatory)]
    [ValidateRange(1, 7200)]
    [int] $TimeoutSeconds,

    [string] $Model,

    [switch] $AcknowledgeProviderInvocation,

    [string] $ExpectedRepositoryUrl = 'https://github.com/alonf/specrew.git'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-T060LocalGit {
    param(
        [Parameter(Mandatory)][string] $Root,
        [Parameter(Mandatory)][string[]] $ArgumentList
    )
    $output = @(& git -C $Root @ArgumentList 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw ('t060-git-failed:{0}:{1}' -f ($ArgumentList -join '-'), (($output | ForEach-Object { [string]$_ }) -join ' '))
    }
    return (($output | ForEach-Object { [string]$_ }) -join "`n").Trim()
}

function Write-T060LocalJsonFile {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)] $Value
    )
    $json = $Value | ConvertTo-Json -Depth 30
    [IO.File]::WriteAllText($Path, $json + "`n", [Text.UTF8Encoding]::new($false))
}

function Get-T060LocalFileSha256 {
    param([Parameter(Mandatory)][string] $Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-T060LocalCliEvidence {
    param(
        [Parameter(Mandatory)][string] $SelectedHost,
        [Parameter(Mandatory)] $Definition,
        [string] $SelectedModel
    )
    $command = Get-Command -Name ([string]$Definition.command) -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) { throw "t060-reviewer-cli-not-installed:$SelectedHost" }

    $versionOutput = @(& $command.Source --version 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "t060-reviewer-version-check-failed:$SelectedHost" }
    $version = [string](@($versionOutput | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1))
    if ([string]::IsNullOrWhiteSpace($version) -or $version.Length -gt 160 -or $version -match '[\r\n]') {
        throw "t060-reviewer-version-output-invalid:$SelectedHost"
    }

    $authStatus = 'credential-state-not-exposed'
    $modelEvidence = 'configured-by-user'
    if ($SelectedHost -ceq 'cursor-agent') {
        $null = @(& $command.Source status 2>&1)
        if ($LASTEXITCODE -ne 0) { throw 't060-cursor-not-authenticated' }
        $availableModels = @(& $command.Source models 2>&1)
        if ($LASTEXITCODE -ne 0) { throw 't060-cursor-model-list-probe-failed' }
        $modelPattern = '^{0}\s+-\s+' -f [regex]::Escape($SelectedModel)
        if (@($availableModels | Where-Object { [string]$_ -cmatch $modelPattern }).Count -ne 1) {
            throw "t060-cursor-model-unavailable:$SelectedModel"
        }
        $authStatus = 'authenticated-probe-passed'
        $modelEvidence = $SelectedModel
    }
    elseif ($SelectedHost -ceq 'antigravity') {
        $null = @(& $command.Source models 2>&1)
        if ($LASTEXITCODE -ne 0) { throw 't060-antigravity-model-list-probe-failed' }
        $authStatus = 'authenticated-model-list-probe-passed'
    }
    elseif ($SelectedHost -ceq 'copilot') {
        $homePath = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
        if ([string]::IsNullOrWhiteSpace($homePath) -or -not [IO.Directory]::Exists((Join-Path $homePath '.copilot'))) {
            throw 't060-copilot-credential-state-missing'
        }
        $authStatus = 'credential-state-present-no-read-only-status-command'
    }

    return [pscustomobject][ordered]@{
        version = $version
        auth_status = $authStatus
        model = $modelEvidence
    }
}

if (-not $IsWindows -and -not $IsLinux) { throw 't060-local-platform-smoke-requires-windows-or-linux' }
$platformName = if ($IsWindows) { 'windows' } else { 'linux' }
$allowedPlatform = if ($HostName -cin @('cursor-agent', 'antigravity')) { 'windows' } else { 'linux' }
if ($platformName -cne $allowedPlatform) { throw "t060-host-platform-mismatch:host=$HostName:required=$allowedPlatform:actual=$platformName" }
if ($HostName -ceq 'cursor-agent') {
    if ([string]::IsNullOrWhiteSpace($Model)) { throw 't060-cursor-explicit-model-required' }
    if ($Model -cnotmatch '^[a-z0-9][a-z0-9.-]{0,127}$') { throw 't060-cursor-model-invalid' }
}
elseif (-not [string]::IsNullOrWhiteSpace($Model)) { throw 't060-model-override-only-supported-for-cursor' }

if ($Mode -ceq 'Invoke') {
    if ([string]::IsNullOrWhiteSpace($RunId)) { throw 't060-invoke-run-id-required' }
    if ([string]::IsNullOrWhiteSpace($AuthorizationRef)) { throw 't060-invoke-authorization-ref-required' }
    if (-not $AcknowledgeProviderInvocation) { throw 't060-invoke-explicit-acknowledgement-required' }
}
elseif ($AcknowledgeProviderInvocation -or -not [string]::IsNullOrWhiteSpace($RunId) -or -not [string]::IsNullOrWhiteSpace($AuthorizationRef)) {
    throw 't060-preflight-rejects-provider-authorization-inputs'
}

$root = (Resolve-Path -LiteralPath $RepoRoot).Path
$loadPath = Join-Path $root 'scripts/internal/continuous-co-review/_load.ps1'
if (-not [IO.File]::Exists($loadPath)) { throw "t060-review-runtime-missing:$loadPath" }
. $loadPath

$topLevel = Invoke-T060LocalGit -Root $root -ArgumentList @('rev-parse', '--show-toplevel')
$pathComparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
if (-not ([IO.Path]::GetFullPath($topLevel)).Equals([IO.Path]::GetFullPath($root), $pathComparison)) { throw 't060-repo-root-mismatch' }
$headBefore = (Invoke-T060LocalGit -Root $root -ArgumentList @('rev-parse', 'HEAD^{commit}')).ToLowerInvariant()
if ($headBefore -cne $ExpectedCommit) { throw "t060-pinned-commit-mismatch:expected=$ExpectedCommit:actual=$headBefore" }
$originUrl = Invoke-T060LocalGit -Root $root -ArgumentList @('remote', 'get-url', 'origin')
if ($originUrl -cne $ExpectedRepositoryUrl) { throw "t060-origin-url-mismatch:expected=$ExpectedRepositoryUrl:actual=$originUrl" }
$statusBefore = Invoke-T060LocalGit -Root $root -ArgumentList @('status', '--porcelain=v1', '--untracked-files=all')
if (-not [string]::IsNullOrEmpty($statusBefore)) { throw 't060-repo-must-be-clean-before-run' }

$output = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-ContinuousCoReviewPathUnderRoot -Path $output -Root $root) { throw 't060-output-directory-must-be-outside-repo' }
if ([IO.Directory]::Exists($output) -and @(Get-ChildItem -LiteralPath $output -Force).Count -gt 0) { throw 't060-output-directory-must-be-empty' }
[IO.Directory]::CreateDirectory($output) | Out-Null

$definition = Get-ContinuousCoReviewProductionHarnessDefinition -HostName $HostName
if ($null -eq $definition) { throw "t060-production-harness-definition-missing:$HostName" }
$cliEvidence = Get-T060LocalCliEvidence -SelectedHost $HostName -Definition $definition -SelectedModel $Model
$digestEvidence = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root
if (-not $digestEvidence.ok) { throw ('t060-reviewed-state-digest-failed:' + [string]$digestEvidence.failure_reason) }
$reviewedDigest = [string]$digestEvidence.tree_id
$platform = [pscustomobject][ordered]@{
    os = $platformName
    os_version = [Runtime.InteropServices.RuntimeInformation]::OSDescription
    architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
}

$preflightRoot = Join-Path ([IO.Path]::GetTempPath()) ('specrew-t060-local-preflight-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory((Join-Path $preflightRoot 'candidate')) | Out-Null
try {
    $preflightInvocation = [pscustomobject][ordered]@{
        schema_version = '1.0'
        campaign_id = 'cmp-t060-local-preflight'
        run_id = 'run-t060-local-preflight'
        target_digest = $reviewedDigest
        snapshot_path = $root
        review_scope = "T060 no-spend $platformName/$HostName production-port preflight."
        prompt_path = (Join-Path $root 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md')
        candidate_result_path = (Join-Path $preflightRoot 'candidate/candidate.json')
        candidate_report_path = (Join-Path $preflightRoot 'candidate/candidate.md')
        deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds).ToString('o')
    }
    $harness = New-ReviewProductionHarnessPort -HostName $HostName -TimeoutSeconds $TimeoutSeconds -Model $Model
    $runtime = New-ReviewProductionRuntimePort -TimeoutSeconds $TimeoutSeconds
    $harnessPreflight = & $harness.preflight $preflightInvocation
    $runtimePreflight = & $runtime.preflight $preflightInvocation
}
finally {
    Remove-Item -LiteralPath $preflightRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$preflight = [pscustomobject][ordered]@{
    schema_version = '1.0'
    evidence_kind = 't060-local-platform-preflight'
    evidence_source = 'local-machine'
    generated_at = [DateTimeOffset]::UtcNow.ToString('o')
    provider_invoked = $false
    target = [pscustomobject][ordered]@{
        repository_url = $originUrl
        head_commit = $headBefore
        reviewed_state_digest = $reviewedDigest
        clean = $true
    }
    platform = $platform
    harness = [pscustomobject][ordered]@{
        host = $HostName
        harness_id = [string]$harness.id
        cli_version = [string]$cliEvidence.version
        model = [string]$cliEvidence.model
        auth_status = [string]$cliEvidence.auth_status
        ready = [bool]$harnessPreflight.ok
        reason = [string]$harnessPreflight.reason
    }
    runtime = [pscustomobject][ordered]@{
        runtime_id = [string]$runtime.id
        ready = [bool]$runtimePreflight.ok
        reason = [string]$runtimePreflight.reason
    }
}
$preflightPath = Join-Path $output 'preflight.json'
Write-T060LocalJsonFile -Path $preflightPath -Value $preflight
if (-not $harnessPreflight.ok -or -not $runtimePreflight.ok) {
    throw ('t060-production-preflight-failed:harness={0}:runtime={1}' -f $harnessPreflight.reason, $runtimePreflight.reason)
}
if ($Mode -ceq 'Preflight') {
    $preflight | ConvertTo-Json -Depth 20
    return
}

$authorityConfigPath = Join-Path $output 'campaign-authority.json'
Write-T060LocalJsonFile -Path $authorityConfigPath -Value ([pscustomobject][ordered]@{ schema_version = '1.0'; mode = 'campaign' })
$storeRoot = Join-Path $output 'authority'
$externalParent = Split-Path -Parent $root
$targetRoot = Join-Path $externalParent '.t060-targets'
$stagingRoot = Join-Path $externalParent '.t060-staging'
$ports = [pscustomobject][ordered]@{
    target = New-GitReviewTargetPort -OriginRepo $root -ExternalRoot $targetRoot
    harness = $harness
    runtime = $runtime
    clock = New-ReviewSystemClockPort
    prompt_path = (Join-Path $root 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md')
}
$progressEvents = [Collections.Generic.List[object]]::new()
$lastHeartbeatPrinted = -60000L
$progressSink = {
    param($event)
    $progressEvents.Add($event) | Out-Null
    $isHeartbeat = [string]$event.stage -ceq 'running' -and $null -eq $event.validated_finding_count
    if (-not $isHeartbeat -or ([long]$event.elapsed_ms - $lastHeartbeatPrinted) -ge 60000) {
        $findingText = if ($null -ne $event.validated_finding_count) { "; findings=$($event.validated_finding_count)" } else { '' }
        Write-Host ("T060 {0}/{1} [{2}] elapsed={3}ms{4} {5}" -f $platformName, $HostName, $event.stage, $event.elapsed_ms, $findingText, $event.message)
        if ($isHeartbeat) { $lastHeartbeatPrinted = [long]$event.elapsed_ms }
    }
}.GetNewClosure()

# This is the only provider-capable call in this package. It is synchronous and has no hidden
# retry; every further attempt requires a new run ID and a new explicit human authorization.
$campaignRun = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '198-beta2-hardening' -IterationNumber '007' `
    -RunId $RunId -ReviewerHost $HostName -GrantAuthorizationRef $AuthorizationRef -TimeoutSeconds $TimeoutSeconds `
    -AuthorityConfigPath $authorityConfigPath -StoreRoot $storeRoot -StagingRoot $stagingRoot -Ports $ports -ProgressSink $progressSink

$progressPath = Join-Path $output 'progress.json'
Write-T060LocalJsonFile -Path $progressPath -Value @($progressEvents)
$resultPath = Join-Path $output 'result.json'
$reportPath = Join-Path $output 'report.md'
if ([string]::IsNullOrWhiteSpace([string]$campaignRun.result_path) -or -not [IO.File]::Exists([string]$campaignRun.result_path)) { throw 't060-terminal-result-file-missing' }
if ([string]::IsNullOrWhiteSpace([string]$campaignRun.report_path) -or -not [IO.File]::Exists([string]$campaignRun.report_path)) { throw 't060-terminal-report-file-missing' }
[IO.File]::Copy([string]$campaignRun.result_path, $resultPath, $false)
[IO.File]::Copy([string]$campaignRun.report_path, $reportPath, $false)

$headAfter = (Invoke-T060LocalGit -Root $root -ArgumentList @('rev-parse', 'HEAD^{commit}')).ToLowerInvariant()
$statusAfter = Invoke-T060LocalGit -Root $root -ArgumentList @('status', '--porcelain=v1', '--untracked-files=all')
$cleanAfter = [string]::IsNullOrEmpty($statusAfter)
$headUnchanged = $headAfter -ceq $headBefore
$campaignId = [string]$campaignRun.campaign_id
$grants = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $storeRoot -CampaignId $campaignId -Kind grants | Where-Object { [string]$_.authorization_ref -ceq $AuthorizationRef })
$reservations = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $storeRoot -CampaignId $campaignId -Kind reservations | Where-Object { [string]$_.run_id -ceq $RunId })
$spends = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $storeRoot -CampaignId $campaignId -Kind spend | Where-Object { [string]$_.run_id -ceq $RunId })
$resultJson = [IO.File]::ReadAllText($resultPath, [Text.UTF8Encoding]::new($false, $true))
$resultValidation = Test-ReviewAuthorityContractJson -ContractName ReviewResult -Json $resultJson `
    -ExpectedCampaignId $campaignId -ExpectedRunId $RunId -ExpectedTargetDigest $reviewedDigest
$result = if ($resultValidation.valid) { $resultJson | ConvertFrom-Json -Depth 30 } else { $null }
$findingCount = if ($null -eq $result) { $null } else { @($result.findings).Count }
$smokeClean = $null -ne $result -and [string]$result.completion -ceq 'complete' -and [string]$result.verdict -ceq 'pass' -and `
    [string]$result.runtime_outcome -ceq 'completed' -and [bool]$result.termination_verified -and [string]$result.containment -ceq 'verified' -and `
    [string]$result.currentness -ceq 'current' -and [string]$result.validation -ceq 'valid' -and [bool]$result.can_approve_current -and $findingCount -eq 0

$manifest = [pscustomobject][ordered]@{
    schema_version = '1.0'
    evidence_kind = 't060-local-platform-smoke'
    evidence_source = 'local-machine'
    generated_at = [DateTimeOffset]::UtcNow.ToString('o')
    target = [pscustomobject][ordered]@{
        repository_url = $originUrl; head_commit = $headBefore; reviewed_state_digest = $reviewedDigest
        clean_before = $true; clean_after = $cleanAfter; head_unchanged = $headUnchanged
    }
    platform = $platform
    harness = [pscustomobject][ordered]@{
        host = $HostName; harness_id = [string]$harness.id; cli_version = [string]$cliEvidence.version
        model = [string]$cliEvidence.model; auth_status = [string]$cliEvidence.auth_status
    }
    authorization = [pscustomobject][ordered]@{
        reference = $AuthorizationRef; grant_count = $grants.Count; reservation_count = $reservations.Count; invocation_count = $spends.Count
    }
    run = [pscustomobject][ordered]@{
        campaign_id = $campaignId; run_id = $RunId; status = [string]$campaignRun.status
        reason = $(if ($null -eq $campaignRun.reason) { $null } else { [string]$campaignRun.reason })
        invoked = [bool]$campaignRun.invoked; smoke_clean = [bool]$smokeClean; finding_count = $findingCount
        preflight_file = 'preflight.json'; result_file = 'result.json'; report_file = 'report.md'; progress_file = 'progress.json'
        preflight_sha256 = Get-T060LocalFileSha256 -Path $preflightPath
        result_sha256 = Get-T060LocalFileSha256 -Path $resultPath
        report_sha256 = Get-T060LocalFileSha256 -Path $reportPath
        progress_sha256 = Get-T060LocalFileSha256 -Path $progressPath
    }
    controller = [pscustomobject][ordered]@{
        authority_mode = 'external-t060-campaign-config'; authority_config_file = 'campaign-authority.json'
        authority_config_sha256 = Get-T060LocalFileSha256 -Path $authorityConfigPath
        runtime_id = [string]$runtime.id; timeout_seconds = $TimeoutSeconds; terminal_result_contract_valid = [bool]$resultValidation.valid
    }
}
Write-T060LocalJsonFile -Path (Join-Path $output 'manifest.json') -Value $manifest
Remove-Item -LiteralPath $stagingRoot -Recurse -Force -ErrorAction SilentlyContinue
if ([IO.Directory]::Exists($targetRoot) -and @(Get-ChildItem -LiteralPath $targetRoot -Force).Count -eq 0) {
    Remove-Item -LiteralPath $targetRoot -Force -ErrorAction SilentlyContinue
}

if (-not $headUnchanged -or -not $cleanAfter) { throw 't060-origin-repository-mutated' }
if ($grants.Count -ne 1 -or $reservations.Count -ne 1 -or $spends.Count -ne 1) { throw "t060-provider-authority-count-invalid:grants=$($grants.Count):reservations=$($reservations.Count):spends=$($spends.Count)" }
if (-not $resultValidation.valid) { throw ('t060-terminal-result-contract-invalid:' + ($resultValidation.errors -join ',')) }
if (-not $smokeClean) {
    $verdict = if ($null -eq $result) { 'unavailable' } else { [string]$result.verdict }
    throw ('t060-smoke-not-clean:verdict={0}:findings={1}' -f $verdict, $findingCount)
}
$manifest | ConvertTo-Json -Depth 20
