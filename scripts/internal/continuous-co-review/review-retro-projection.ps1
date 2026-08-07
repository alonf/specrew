$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Get-Command -Name 'Test-ReviewAuthorityContractObject' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-authority-core.ps1') }
if (-not (Get-Command -Name 'Get-ReviewAuthorityCampaignRunResults' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-authority-store.ps1') }

function ConvertTo-ReviewRetrospectiveEvidence {
    [CmdletBinding()]
    param([object[]]$Results = @())
    $groups = [ordered]@{}
    $severityRank = @{ note = 1; minor = 2; major = 3; blocking = 4 }
    foreach ($result in @($Results | Where-Object { $null -ne $_ })) {
        $validation = Test-ReviewAuthorityContractObject -ContractName ReviewResult -InputObject $result -ExpectedCampaignId ([string]$result.campaign_id) -ExpectedRunId ([string]$result.run_id) -ExpectedTargetDigest ([string]$result.target_digest)
        if (-not $validation.valid) { throw ('review-retro-invalid-result:' + ($validation.errors -join ',')) }
        foreach ($finding in @($result.findings)) {
            $lineage = [string]$finding.lineage_id
            if (-not $groups.Contains($lineage)) {
                $groups[$lineage] = [pscustomobject]@{
                    lineage_id = $lineage; severity = [string]$finding.severity; title = [string]$finding.title; description = [string]$finding.description
                    representative_finding_id = [string]$finding.finding_id
                    sources = [Collections.Generic.List[object]]::new()
                }
            }
            $problem = $groups[$lineage]
            $candidateRank = [int]$severityRank[[string]$finding.severity]
            $currentRank = [int]$severityRank[[string]$problem.severity]
            if ($candidateRank -gt $currentRank -or ($candidateRank -eq $currentRank -and [string]$finding.finding_id -clt [string]$problem.representative_finding_id)) {
                $problem.severity = [string]$finding.severity
                $problem.title = [string]$finding.title
                $problem.description = [string]$finding.description
                $problem.representative_finding_id = [string]$finding.finding_id
            }
            $problem.sources.Add([pscustomobject][ordered]@{
                campaign_id = [string]$result.campaign_id; run_id = [string]$result.run_id; finding_id = [string]$finding.finding_id
                harness_id = [string]$result.harness_id; target_digest = [string]$result.target_digest; completion = [string]$result.completion
                runtime_outcome = [string]$result.runtime_outcome; validation = [string]$result.validation; currentness = [string]$result.currentness
                termination_verified = [bool]$result.termination_verified; containment = [string]$result.containment
                failure_reason = $(if ($null -eq $result.failure_reason) { $null } else { [string]$result.failure_reason })
                relevance = [string]$finding.relevance; resolution = [string]$finding.resolution; severity = [string]$finding.severity
            }) | Out-Null
        }
    }
    $problems = [Collections.Generic.List[object]]::new()
    foreach ($lineage in @($groups.Keys | Sort-Object)) {
        $group = $groups[$lineage]
        $sources = @($group.sources | Sort-Object campaign_id, run_id, finding_id)
        $problems.Add([pscustomobject][ordered]@{
            problem_id = ('problem-' + ([string]$lineage -replace '^lin-', '')); lineage_id = [string]$lineage
            severity = [string]$group.severity; title = [string]$group.title; description = [string]$group.description
            source_count = $sources.Count; sources = $sources
        }) | Out-Null
    }
    return [pscustomobject][ordered]@{
        schema_version = '1.0'; source_kind = 'validated-review-result-json'; authority = $false
        problem_count = $problems.Count; problems = @($problems)
    }
}

function Get-ReviewCampaignRetrospectiveEvidence {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$StoreRoot, [Parameter(Mandatory)][string]$CampaignId)
    $results = @(Get-ReviewAuthorityCampaignRunResults -StoreRoot $StoreRoot -CampaignId $CampaignId)
    return ConvertTo-ReviewRetrospectiveEvidence -Results $results
}
