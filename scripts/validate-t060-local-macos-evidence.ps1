#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $RepoRoot,

    [Parameter(Mandatory)]
    [string] $PackagePath,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-f]{40}$')]
    [string] $ExpectedCommit,

    [Parameter(Mandatory)]
    [ValidatePattern('^run-[a-z0-9][a-z0-9-]{0,63}$')]
    [string] $ExpectedRunId,

    [Parameter(Mandatory)]
    [ValidateLength(1, 256)]
    [string] $ExpectedAuthorizationRef,

    [string] $ExpectedRepositoryUrl = 'https://github.com/alonf/specrew.git'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Read-T060StrictJsonObject {
    param(
        [Parameter(Mandatory)][string] $Path,
        [ValidateRange(1, 1048576)][int] $MaximumBytes = 262144
    )
    if (-not [IO.File]::Exists($Path)) { throw "missing-file:$Path" }
    $info = [IO.FileInfo]$Path
    if ($info.Length -le 0 -or $info.Length -gt $MaximumBytes) { throw "invalid-json-size:$Path" }
    $json = [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false, $true))
    $trimmed = $json.Trim()
    if (-not $trimmed.StartsWith('{') -or -not $trimmed.EndsWith('}')) { throw "json-object-required:$Path" }
    try { $document = [Text.Json.JsonDocument]::Parse($trimmed) }
    catch [Text.Json.JsonException] { throw "invalid-json:$Path" }
    try {
        if ($document.RootElement.ValueKind -ne [Text.Json.JsonValueKind]::Object) { throw "json-object-required:$Path" }
        $pending = [Collections.Generic.Stack[object]]::new()
        $pending.Push([pscustomobject]@{ element = $document.RootElement; path = '$' })
        while ($pending.Count -gt 0) {
            $node = $pending.Pop()
            $element = [Text.Json.JsonElement]$node.element
            if ($element.ValueKind -eq [Text.Json.JsonValueKind]::Object) {
                $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
                foreach ($property in $element.EnumerateObject()) {
                    $child = [string]$node.path + '.' + $property.Name
                    if (-not $seen.Add($property.Name)) { throw "duplicate-json-field:$child" }
                    $pending.Push([pscustomobject]@{ element = $property.Value; path = $child })
                }
            }
            elseif ($element.ValueKind -eq [Text.Json.JsonValueKind]::Array) {
                $index = 0
                foreach ($item in $element.EnumerateArray()) {
                    $pending.Push([pscustomobject]@{ element = $item; path = ([string]$node.path + "[$index]") })
                    $index++
                }
            }
        }
    }
    finally { $document.Dispose() }
    try { return ($trimmed | ConvertFrom-Json -Depth 30 -ErrorAction Stop) }
    catch { throw "invalid-json:$Path" }
}

function Add-T060ClosedShapeErrors {
    param(
        [Parameter(Mandatory)] $Object,
        [Parameter(Mandatory)][string[]] $Fields,
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][AllowEmptyCollection()][Collections.Generic.List[string]] $Errors
    )
    if ($Object -isnot [pscustomobject]) { $Errors.Add("wrong-type:$Path:object") | Out-Null; return }
    $actual = @($Object.PSObject.Properties.Name)
    foreach ($field in $Fields) {
        if ($field -cnotin $actual) { $Errors.Add("missing-field:$Path.$field") | Out-Null }
    }
    foreach ($field in $actual) {
        if ($field -cnotin $Fields) { $Errors.Add("unknown-field:$Path.$field") | Out-Null }
    }
}

function Get-T060Sha256 {
    param([Parameter(Mandatory)][string] $Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

$errors = [Collections.Generic.List[string]]::new()
$manifest = $null
$preflight = $null
$result = $null
$findingCount = $null
$resultVerdict = $null
$packageRoot = $null
$targetRepoRoot = $null
$targetRepoDigest = $null
try {
    $targetRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
    $packageRoot = (Resolve-Path -LiteralPath $PackagePath).Path
    $loadPath = Join-Path $PSScriptRoot 'internal/continuous-co-review/_load.ps1'
    . $loadPath

    $actualCommitOutput = @(& git -C $targetRepoRoot rev-parse 'HEAD^{commit}' 2>&1)
    if ($LASTEXITCODE -ne 0) { throw 'repository-checkout-head-unavailable' }
    $actualCommit = (($actualCommitOutput | ForEach-Object { [string]$_ }) -join "`n").Trim().ToLowerInvariant()
    if ($actualCommit -cne $ExpectedCommit) { $errors.Add('repository-checkout-commit-mismatch') | Out-Null }
    $actualOriginOutput = @(& git -C $targetRepoRoot remote get-url origin 2>&1)
    if ($LASTEXITCODE -ne 0) { throw 'repository-checkout-origin-unavailable' }
    $actualOrigin = (($actualOriginOutput | ForEach-Object { [string]$_ }) -join "`n").Trim()
    if ($actualOrigin -cne $ExpectedRepositoryUrl) { $errors.Add('repository-checkout-origin-mismatch') | Out-Null }
    $actualStatus = ((@(& git -C $targetRepoRoot status --porcelain=v1 --untracked-files=all 2>&1) | ForEach-Object { [string]$_ }) -join "`n").Trim()
    if ($LASTEXITCODE -ne 0) { throw 'repository-checkout-status-unavailable' }
    if (-not [string]::IsNullOrEmpty($actualStatus)) { $errors.Add('repository-checkout-not-clean') | Out-Null }
    $digestEvidence = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $targetRepoRoot
    if ($null -eq $digestEvidence -or -not [bool]$digestEvidence.ok -or [string]$digestEvidence.tree_id -cnotmatch '^[0-9a-f]{40}$') {
        $why = if ($null -ne $digestEvidence -and $digestEvidence.PSObject.Properties['failure_reason']) { [string]$digestEvidence.failure_reason } else { 'unknown' }
        throw "repository-digest-unavailable:$why"
    }
    $targetRepoDigest = [string]$digestEvidence.tree_id

    $manifestPath = Join-Path $packageRoot 'manifest.json'
    $preflightPath = Join-Path $packageRoot 'preflight.json'
    $resultPath = Join-Path $packageRoot 'result.json'
    $reportPath = Join-Path $packageRoot 'report.md'
    $progressPath = Join-Path $packageRoot 'progress.json'
    $authorityConfigPath = Join-Path $packageRoot 'campaign-authority.json'
    $manifest = Read-T060StrictJsonObject -Path $manifestPath
    $preflight = Read-T060StrictJsonObject -Path $preflightPath

    Add-T060ClosedShapeErrors -Object $manifest -Fields @('schema_version', 'evidence_kind', 'evidence_source', 'generated_at', 'target', 'platform', 'harness', 'authorization', 'run', 'controller') -Path '$' -Errors $errors
    Add-T060ClosedShapeErrors -Object $manifest.target -Fields @('repository_url', 'head_commit', 'reviewed_state_digest', 'clean_before', 'clean_after', 'head_unchanged') -Path '$.target' -Errors $errors
    Add-T060ClosedShapeErrors -Object $manifest.platform -Fields @('os', 'os_version', 'architecture') -Path '$.platform' -Errors $errors
    Add-T060ClosedShapeErrors -Object $manifest.harness -Fields @('host', 'harness_id', 'cli_version', 'auth_status') -Path '$.harness' -Errors $errors
    Add-T060ClosedShapeErrors -Object $manifest.authorization -Fields @('reference', 'invocation_count') -Path '$.authorization' -Errors $errors
    Add-T060ClosedShapeErrors -Object $manifest.run -Fields @('campaign_id', 'run_id', 'status', 'reason', 'invoked', 'preflight_file', 'result_file', 'report_file', 'progress_file', 'preflight_sha256', 'result_sha256', 'report_sha256', 'progress_sha256') -Path '$.run' -Errors $errors
    Add-T060ClosedShapeErrors -Object $manifest.controller -Fields @('authority_mode', 'authority_config_file', 'authority_config_sha256', 'runtime_id', 'timeout_seconds', 'terminal_result_contract_valid') -Path '$.controller' -Errors $errors

    Add-T060ClosedShapeErrors -Object $preflight -Fields @('schema_version', 'evidence_kind', 'evidence_source', 'generated_at', 'provider_invoked', 'target', 'platform', 'harness', 'runtime') -Path '$preflight' -Errors $errors
    Add-T060ClosedShapeErrors -Object $preflight.target -Fields @('repository_url', 'head_commit', 'reviewed_state_digest', 'clean') -Path '$preflight.target' -Errors $errors
    Add-T060ClosedShapeErrors -Object $preflight.platform -Fields @('os', 'os_version', 'architecture') -Path '$preflight.platform' -Errors $errors
    Add-T060ClosedShapeErrors -Object $preflight.harness -Fields @('host', 'harness_id', 'cli_version', 'auth_status', 'ready', 'reason') -Path '$preflight.harness' -Errors $errors
    Add-T060ClosedShapeErrors -Object $preflight.runtime -Fields @('runtime_id', 'ready', 'reason') -Path '$preflight.runtime' -Errors $errors

    if ([string]$manifest.schema_version -cne '1.0' -or [string]$preflight.schema_version -cne '1.0') { $errors.Add('schema-version-invalid') | Out-Null }
    if ([string]$manifest.evidence_kind -cne 't060-local-macos-smoke') { $errors.Add('evidence-kind-invalid') | Out-Null }
    if ([string]$manifest.evidence_source -cne 'local-machine' -or [string]$preflight.evidence_source -cne 'local-machine') { $errors.Add('evidence-source-must-be-local-machine') | Out-Null }
    if ([string]$preflight.evidence_kind -cne 't060-local-macos-preflight' -or [bool]$preflight.provider_invoked) { $errors.Add('preflight-provenance-invalid') | Out-Null }
    if ([string]$manifest.target.repository_url -cne $ExpectedRepositoryUrl -or [string]$preflight.target.repository_url -cne $ExpectedRepositoryUrl) { $errors.Add('repository-url-mismatch') | Out-Null }
    if ([string]$manifest.target.head_commit -cne $ExpectedCommit -or [string]$preflight.target.head_commit -cne $ExpectedCommit) { $errors.Add('commit-mismatch') | Out-Null }
    if (-not [bool]$manifest.target.clean_before -or -not [bool]$manifest.target.clean_after -or -not [bool]$manifest.target.head_unchanged -or -not [bool]$preflight.target.clean) { $errors.Add('repository-integrity-invalid') | Out-Null }
    if ([string]$manifest.target.reviewed_state_digest -cne [string]$preflight.target.reviewed_state_digest) { $errors.Add('preflight-digest-mismatch') | Out-Null }
    if ([string]$manifest.target.reviewed_state_digest -cne $targetRepoDigest) { $errors.Add('repository-digest-mismatch') | Out-Null }
    if ([string]$manifest.platform.os -cne 'macos' -or [string]$preflight.platform.os -cne 'macos') { $errors.Add('platform-must-be-macos') | Out-Null }
    if ([string]$manifest.harness.host -cne 'codex' -or [string]$manifest.harness.harness_id -cne 'codex-cli-file-primary') { $errors.Add('harness-identity-invalid') | Out-Null }
    if ([string]$preflight.harness.host -cne 'codex' -or [string]$preflight.harness.harness_id -cne 'codex-cli-file-primary' -or -not [bool]$preflight.harness.ready) { $errors.Add('harness-preflight-invalid') | Out-Null }
    if ([string]$manifest.harness.auth_status -cne 'authenticated' -or [string]$preflight.harness.auth_status -cne 'authenticated') { $errors.Add('auth-preflight-invalid') | Out-Null }
    if ([string]$manifest.controller.runtime_id -cne 'macos-process-group-runtime' -or [string]$preflight.runtime.runtime_id -cne 'macos-process-group-runtime' -or -not [bool]$preflight.runtime.ready) { $errors.Add('runtime-preflight-invalid') | Out-Null }
    if ([string]$manifest.controller.authority_mode -cne 'external-t060-campaign-config') { $errors.Add('authority-mode-provenance-invalid') | Out-Null }
    if ([string]$manifest.controller.authority_config_file -cne 'campaign-authority.json') { $errors.Add('authority-config-file-invalid') | Out-Null }
    if (-not [IO.File]::Exists($authorityConfigPath) -or [string]$manifest.controller.authority_config_sha256 -cnotmatch '^[0-9a-f]{64}$' -or (Get-T060Sha256 -Path $authorityConfigPath) -cne [string]$manifest.controller.authority_config_sha256) {
        $errors.Add('authority-config-hash-mismatch') | Out-Null
    }
    else {
        $authorityConfig = Read-T060StrictJsonObject -Path $authorityConfigPath -MaximumBytes 4096
        Add-T060ClosedShapeErrors -Object $authorityConfig -Fields @('schema_version', 'mode') -Path '$authority_config' -Errors $errors
        if ([string]$authorityConfig.schema_version -cne '1.0' -or [string]$authorityConfig.mode -cne 'campaign') { $errors.Add('authority-config-invalid') | Out-Null }
    }
    if ([int]$manifest.controller.timeout_seconds -ne 600) { $errors.Add('timeout-must-be-600-seconds') | Out-Null }
    if (-not [bool]$manifest.controller.terminal_result_contract_valid) { $errors.Add('producer-contract-validation-failed') | Out-Null }
    if ([string]$manifest.authorization.reference -cne $ExpectedAuthorizationRef) { $errors.Add('authorization-reference-mismatch') | Out-Null }
    if ([int]$manifest.authorization.invocation_count -ne 1) { $errors.Add('manifest-invocation-count-must-be-one') | Out-Null }
    if ([string]$manifest.run.run_id -cne $ExpectedRunId) { $errors.Add('run-id-mismatch') | Out-Null }
    if ([string]$manifest.run.status -cne 'terminal' -or -not [bool]$manifest.run.invoked) { $errors.Add('run-not-invoked-terminal') | Out-Null }
    if ([string]$manifest.run.preflight_file -cne 'preflight.json' -or [string]$manifest.run.result_file -cne 'result.json' -or [string]$manifest.run.report_file -cne 'report.md' -or [string]$manifest.run.progress_file -cne 'progress.json') { $errors.Add('package-file-name-invalid') | Out-Null }

    foreach ($pair in @(
        @{ path = $preflightPath; expected = [string]$manifest.run.preflight_sha256; name = 'preflight' },
        @{ path = $resultPath; expected = [string]$manifest.run.result_sha256; name = 'result' },
        @{ path = $reportPath; expected = [string]$manifest.run.report_sha256; name = 'report' },
        @{ path = $progressPath; expected = [string]$manifest.run.progress_sha256; name = 'progress' }
    )) {
        if (-not [IO.File]::Exists([string]$pair.path)) { $errors.Add("missing-$($pair.name)-file") | Out-Null; continue }
        if ([string]$pair.expected -cnotmatch '^[0-9a-f]{64}$' -or (Get-T060Sha256 -Path ([string]$pair.path)) -cne [string]$pair.expected) {
            $errors.Add("$($pair.name)-hash-mismatch") | Out-Null
        }
    }

    if ([IO.File]::Exists($reportPath) -and ([IO.FileInfo]$reportPath).Length -le 0) { $errors.Add('report-empty') | Out-Null }
    if ([IO.File]::Exists($resultPath)) {
        $resultJson = [IO.File]::ReadAllText($resultPath, [Text.UTF8Encoding]::new($false, $true))
        $resultValidation = Test-ReviewAuthorityContractJson -ContractName ReviewResult -Json $resultJson `
            -ExpectedCampaignId ([string]$manifest.run.campaign_id) -ExpectedRunId $ExpectedRunId `
            -ExpectedTargetDigest ([string]$manifest.target.reviewed_state_digest)
        if (-not $resultValidation.valid) { $errors.Add(('result-contract-invalid:' + ($resultValidation.errors -join ','))) | Out-Null }
        else {
            $result = $resultJson | ConvertFrom-Json -Depth 30
            $findingCount = @($result.findings).Count
            $resultVerdict = [string]$result.verdict
        }
    }

    $storeRoot = Join-Path $packageRoot 'authority'
    if (-not [IO.Directory]::Exists($storeRoot)) { $errors.Add('authority-store-missing') | Out-Null }
    else {
        try {
            $campaignId = [string]$manifest.run.campaign_id
            $grants = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $storeRoot -CampaignId $campaignId -Kind grants)
            $reservations = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $storeRoot -CampaignId $campaignId -Kind reservations)
            $spends = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $storeRoot -CampaignId $campaignId -Kind spend)
            if (@($grants | Where-Object { [string]$_.authorization_ref -ceq $ExpectedAuthorizationRef }).Count -ne 1) { $errors.Add('authority-grant-mismatch') | Out-Null }
            if (@($reservations | Where-Object { [string]$_.run_id -ceq $ExpectedRunId }).Count -ne 1) { $errors.Add('authority-reservation-mismatch') | Out-Null }
            if ($spends.Count -ne 1 -or @($spends | Where-Object { [string]$_.run_id -ceq $ExpectedRunId }).Count -ne 1) { $errors.Add('authority-spend-count-mismatch') | Out-Null }
            $authorityResult = Join-Path $storeRoot ("campaigns/{0}/runs/{1}/result.json" -f $campaignId, $ExpectedRunId)
            $authorityReport = Join-Path $storeRoot ("campaigns/{0}/runs/{1}/report.md" -f $campaignId, $ExpectedRunId)
            if (-not [IO.File]::Exists($authorityResult) -or (Get-T060Sha256 -Path $authorityResult) -cne (Get-T060Sha256 -Path $resultPath)) { $errors.Add('authority-result-copy-mismatch') | Out-Null }
            if (-not [IO.File]::Exists($authorityReport) -or (Get-T060Sha256 -Path $authorityReport) -cne (Get-T060Sha256 -Path $reportPath)) { $errors.Add('authority-report-copy-mismatch') | Out-Null }
        }
        catch { $errors.Add(('authority-store-invalid:' + $_.Exception.Message)) | Out-Null }
    }
}
catch {
    $errors.Add($_.Exception.Message) | Out-Null
}

$valid = $errors.Count -eq 0
$smokeClean = $false
if ($valid -and $null -ne $result) {
    $smokeClean = (
        [string]$result.completion -ceq 'complete' -and
        [string]$result.verdict -ceq 'pass' -and
        [string]$result.runtime_outcome -ceq 'completed' -and
        [bool]$result.termination_verified -and
        [string]$result.containment -ceq 'verified' -and
        [string]$result.currentness -ceq 'current' -and
        [string]$result.validation -ceq 'valid' -and
        [bool]$result.can_approve_current -and
        @($result.findings).Count -eq 0
    )
}
$validationOutput = [pscustomobject][ordered]@{
    schema_version = '1.0'
    package_valid = $valid
    smoke_clean = $smokeClean
    evidence_source = $(if ($null -eq $manifest) { $null } else { [string]$manifest.evidence_source })
    head_commit = $(if ($null -eq $manifest) { $null } else { [string]$manifest.target.head_commit })
    target_digest = $(if ($null -eq $manifest) { $null } else { [string]$manifest.target.reviewed_state_digest })
    campaign_id = $(if ($null -eq $manifest) { $null } else { [string]$manifest.run.campaign_id })
    run_id = $(if ($null -eq $manifest) { $null } else { [string]$manifest.run.run_id })
    verdict = $resultVerdict
    finding_count = $findingCount
    errors = @($errors)
}
$validationOutput | ConvertTo-Json -Depth 10
if (-not $valid) { exit 1 }
