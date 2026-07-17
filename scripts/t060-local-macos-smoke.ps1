#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Preflight', 'Invoke')]
    [string] $Mode,

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

    [ValidateRange(1, 7200)]
    [int] $TimeoutSeconds = 600,

    [switch] $AcknowledgeProviderInvocation,

    [string] $ExpectedRepositoryUrl = 'https://github.com/alonf/specrew.git'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-T060Git {
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

function Write-T060JsonFile {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)] $Value
    )
    $json = $Value | ConvertTo-Json -Depth 30
    [IO.File]::WriteAllText($Path, $json + "`n", [Text.UTF8Encoding]::new($false))
}

function Get-T060FileSha256 {
    param([Parameter(Mandatory)][string] $Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

if (-not $IsMacOS) { throw 't060-local-macos-smoke-requires-macos' }
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

$topLevel = Invoke-T060Git -Root $root -ArgumentList @('rev-parse', '--show-toplevel')
$pathComparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
if (-not ([IO.Path]::GetFullPath($topLevel)).Equals([IO.Path]::GetFullPath($root), $pathComparison)) {
    throw 't060-repo-root-mismatch'
}
$headBefore = (Invoke-T060Git -Root $root -ArgumentList @('rev-parse', 'HEAD^{commit}')).ToLowerInvariant()
if ($headBefore -cne $ExpectedCommit) { throw "t060-pinned-commit-mismatch:expected=$ExpectedCommit:actual=$headBefore" }
$originUrl = Invoke-T060Git -Root $root -ArgumentList @('remote', 'get-url', 'origin')
if ($originUrl -cne $ExpectedRepositoryUrl) { throw "t060-origin-url-mismatch:expected=$ExpectedRepositoryUrl:actual=$originUrl" }
$statusBefore = Invoke-T060Git -Root $root -ArgumentList @('status', '--porcelain=v1', '--untracked-files=all')
if (-not [string]::IsNullOrEmpty($statusBefore)) { throw 't060-repo-must-be-clean-before-run' }

$output = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-ContinuousCoReviewPathUnderRoot -Path $output -Root $root) { throw 't060-output-directory-must-be-outside-repo' }
if ([IO.Directory]::Exists($output) -and @(Get-ChildItem -LiteralPath $output -Force).Count -gt 0) {
    throw 't060-output-directory-must-be-empty'
}
[IO.Directory]::CreateDirectory($output) | Out-Null

$codexCommand = Get-Command -Name codex -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $codexCommand) { throw 't060-codex-cli-not-installed' }
$versionOutput = @(& $codexCommand.Source --version 2>&1)
if ($LASTEXITCODE -ne 0) { throw 't060-codex-version-check-failed' }
$codexVersion = [string](@($versionOutput | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1))
if ([string]::IsNullOrWhiteSpace($codexVersion) -or $codexVersion.Length -gt 160 -or $codexVersion -match '[\r\n]') {
    throw 't060-codex-version-output-invalid'
}
$null = @(& $codexCommand.Source login status 2>&1)
if ($LASTEXITCODE -ne 0) { throw 't060-codex-not-authenticated' }

$digestEvidence = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root
if (-not $digestEvidence.ok) { throw ('t060-reviewed-state-digest-failed:' + [string]$digestEvidence.failure_reason) }
$reviewedDigest = [string]$digestEvidence.tree_id
$platform = [pscustomobject][ordered]@{
    os = 'macos'
    os_version = [Runtime.InteropServices.RuntimeInformation]::OSDescription
    architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
}

$preflightRoot = Join-Path ([IO.Path]::GetTempPath()) ('specrew-t060-macos-preflight-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory((Join-Path $preflightRoot 'candidate')) | Out-Null
try {
    $preflightInvocation = [pscustomobject][ordered]@{
        schema_version = '1.0'
        campaign_id = 'cmp-t060-macos-preflight'
        run_id = 'run-t060-macos-preflight'
        target_digest = $reviewedDigest
        snapshot_path = $root
        review_scope = 'T060 no-spend local macOS production-port preflight.'
        prompt_path = (Join-Path $root 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md')
        candidate_result_path = (Join-Path $preflightRoot 'candidate/candidate.json')
        candidate_report_path = (Join-Path $preflightRoot 'candidate/candidate.md')
        deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds).ToString('o')
    }
    $harness = New-ReviewProductionHarnessPort -HostName codex -TimeoutSeconds $TimeoutSeconds
    $runtime = New-ReviewProductionRuntimePort -TimeoutSeconds $TimeoutSeconds
    $harnessPreflight = & $harness.preflight $preflightInvocation
    $runtimePreflight = & $runtime.preflight $preflightInvocation
}
finally {
    Remove-Item -LiteralPath $preflightRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$preflight = [pscustomobject][ordered]@{
    schema_version = '1.0'
    evidence_kind = 't060-local-macos-preflight'
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
        host = 'codex'
        harness_id = [string]$harness.id
        cli_version = $codexVersion
        auth_status = 'authenticated'
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
Write-T060JsonFile -Path $preflightPath -Value $preflight
if (-not $harnessPreflight.ok -or -not $runtimePreflight.ok) {
    throw ('t060-production-preflight-failed:harness={0}:runtime={1}' -f $harnessPreflight.reason, $runtimePreflight.reason)
}
if ($Mode -ceq 'Preflight') {
    $preflight | ConvertTo-Json -Depth 20
    return
}

$authorityConfigPath = Join-Path $output 'campaign-authority.json'
Write-T060JsonFile -Path $authorityConfigPath -Value ([pscustomobject][ordered]@{ schema_version = '1.0'; mode = 'campaign' })
$storeRoot = Join-Path $output 'authority'
$stagingRoot = Join-Path $output '.staging'
$progressEvents = [Collections.Generic.List[object]]::new()
$progressSink = {
    param($event)
    $progressEvents.Add($event) | Out-Null
    $findingText = if ($null -ne $event.validated_finding_count) { "; findings=$($event.validated_finding_count)" } else { '' }
    Write-Host ("T060 macOS [{0}] elapsed={1}ms{2} {3}" -f $event.stage, $event.elapsed_ms, $findingText, $event.message)
}.GetNewClosure()

# This is the only provider-capable call in this package. The production command itself is
# synchronous and has no hidden retry; a second attempt requires a new run ID and human grant.
$t060ReviewScope = @'
Review the implemented code and tests in the complete frozen target for correctness, security,
failure semantics, and conformance with the resolved design context. This T060 run is one serialized
live harness proof executed before the remaining T060 harnesses, campaign-authority cutover, T061
independent signoff, retrospective, and closeout. Treat plan/state entries that accurately identify
those later steps or an external provider-quota constraint as execution context, not code-review
findings. Report a pending or deferred item only when a grounded defect in the frozen code makes that
step unsafe or impossible, or when the implementation contradicts an approved requirement. Do not
review project-completion or gate status in this code-review run.
'@
$campaignRun = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '198-beta2-hardening' -IterationNumber '007' `
    -RunId $RunId -ReviewerHost codex -GrantAuthorizationRef $AuthorizationRef -TimeoutSeconds $TimeoutSeconds `
    -AuthorityConfigPath $authorityConfigPath -StoreRoot $storeRoot -StagingRoot $stagingRoot `
    -ReviewScope $t060ReviewScope -ProgressSink $progressSink

$progressPath = Join-Path $output 'progress.json'
Write-T060JsonFile -Path $progressPath -Value @($progressEvents)
$resultPath = Join-Path $output 'result.json'
$reportPath = Join-Path $output 'report.md'
if ([string]::IsNullOrWhiteSpace([string]$campaignRun.result_path) -or -not [IO.File]::Exists([string]$campaignRun.result_path)) {
    throw 't060-terminal-result-file-missing'
}
if ([string]::IsNullOrWhiteSpace([string]$campaignRun.report_path) -or -not [IO.File]::Exists([string]$campaignRun.report_path)) {
    throw 't060-terminal-report-file-missing'
}
[IO.File]::Copy([string]$campaignRun.result_path, $resultPath, $false)
[IO.File]::Copy([string]$campaignRun.report_path, $reportPath, $false)

$headAfter = (Invoke-T060Git -Root $root -ArgumentList @('rev-parse', 'HEAD^{commit}')).ToLowerInvariant()
$statusAfter = Invoke-T060Git -Root $root -ArgumentList @('status', '--porcelain=v1', '--untracked-files=all')
$cleanAfter = [string]::IsNullOrEmpty($statusAfter)
$headUnchanged = $headAfter -ceq $headBefore
$spends = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $storeRoot -CampaignId ([string]$campaignRun.campaign_id) -Kind spend |
    Where-Object { [string]$_.run_id -ceq $RunId })
$resultJson = [IO.File]::ReadAllText($resultPath, [Text.UTF8Encoding]::new($false, $true))
$resultValidation = Test-ReviewAuthorityContractJson -ContractName ReviewResult -Json $resultJson `
    -ExpectedCampaignId ([string]$campaignRun.campaign_id) -ExpectedRunId $RunId -ExpectedTargetDigest $reviewedDigest

$manifest = [pscustomobject][ordered]@{
    schema_version = '1.0'
    evidence_kind = 't060-local-macos-smoke'
    evidence_source = 'local-machine'
    generated_at = [DateTimeOffset]::UtcNow.ToString('o')
    target = [pscustomobject][ordered]@{
        repository_url = $originUrl
        head_commit = $headBefore
        reviewed_state_digest = $reviewedDigest
        clean_before = $true
        clean_after = $cleanAfter
        head_unchanged = $headUnchanged
    }
    platform = $platform
    harness = [pscustomobject][ordered]@{
        host = 'codex'
        harness_id = [string]$harness.id
        cli_version = $codexVersion
        auth_status = 'authenticated'
    }
    authorization = [pscustomobject][ordered]@{
        reference = $AuthorizationRef
        invocation_count = $spends.Count
    }
    run = [pscustomobject][ordered]@{
        campaign_id = [string]$campaignRun.campaign_id
        run_id = $RunId
        status = [string]$campaignRun.status
        reason = $(if ($null -eq $campaignRun.reason) { $null } else { [string]$campaignRun.reason })
        invoked = [bool]$campaignRun.invoked
        preflight_file = 'preflight.json'
        result_file = 'result.json'
        report_file = 'report.md'
        progress_file = 'progress.json'
        preflight_sha256 = Get-T060FileSha256 -Path $preflightPath
        result_sha256 = Get-T060FileSha256 -Path $resultPath
        report_sha256 = Get-T060FileSha256 -Path $reportPath
        progress_sha256 = Get-T060FileSha256 -Path $progressPath
    }
    controller = [pscustomobject][ordered]@{
        authority_mode = 'external-t060-campaign-config'
        authority_config_file = 'campaign-authority.json'
        authority_config_sha256 = Get-T060FileSha256 -Path $authorityConfigPath
        runtime_id = [string]$runtime.id
        timeout_seconds = $TimeoutSeconds
        terminal_result_contract_valid = [bool]$resultValidation.valid
    }
}
Write-T060JsonFile -Path (Join-Path $output 'manifest.json') -Value $manifest
Remove-Item -LiteralPath $stagingRoot -Recurse -Force -ErrorAction SilentlyContinue

if (-not $headUnchanged -or -not $cleanAfter) { throw 't060-origin-repository-mutated' }
if ($spends.Count -ne 1) { throw "t060-provider-invocation-count-invalid:$($spends.Count)" }
if (-not $resultValidation.valid) { throw ('t060-terminal-result-contract-invalid:' + ($resultValidation.errors -join ',')) }
$manifest | ConvertTo-Json -Depth 20
