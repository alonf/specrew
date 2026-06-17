$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function ConvertTo-ContinuousCoReviewIsoTimestamp {
    param(
        [datetime] $Timestamp = [datetime]::UtcNow
    )

    return $Timestamp.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-ContinuousCoReviewObjectProperty {
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        $Object,

        [Parameter(Mandatory)]
        [string] $Name
    )

    if ($null -eq $Object) {
        return $null
    }

    if (Test-ReviewerContractPropertyExists -Object $Object -Name $Name) {
        return Get-ReviewerContractPropertyValue -Object $Object -Name $Name
    }

    return $null
}

function ConvertTo-ContinuousCoReviewDurableJson {
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        $InputObject
    )

    return ($InputObject | ConvertTo-Json -Depth 100)
}

function Write-ContinuousCoReviewIdempotentJson {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [AllowNull()]
        $InputObject
    )

    $json = ConvertTo-ContinuousCoReviewDurableJson -InputObject $InputObject
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $existingJson = Get-Content -LiteralPath $Path -Raw
        $existingCanonical = ConvertTo-ReviewerContractCanonicalJson -InputObject (ConvertFrom-ReviewerContractJson -Json $existingJson)
        $newCanonical = ConvertTo-ReviewerContractCanonicalJson -InputObject $InputObject
        if ($existingCanonical -ne $newCanonical) {
            throw "Durable review artifact already exists with different content: $Path"
        }

        return
    }

    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8 -NoNewline
}

function New-ContinuousCoReviewDispositionFromFinding {
    param(
        [Parameter(Mandatory)]
        $Finding,

        [Parameter(Mandatory)]
        [string] $RecordedAt
    )

    $findingId = Get-ContinuousCoReviewObjectProperty -Object $Finding -Name 'finding_id'
    $resolution = Get-ContinuousCoReviewObjectProperty -Object $Finding -Name 'resolution'

    return [pscustomobject][ordered]@{
        disposition_id   = "disposition-$findingId-open"
        finding_id       = $findingId
        state            = Get-ContinuousCoReviewObjectProperty -Object $Finding -Name 'disposition'
        rationale        = Get-ContinuousCoReviewObjectProperty -Object $resolution -Name 'rationale'
        fix_evidence_ref = Get-ContinuousCoReviewObjectProperty -Object $resolution -Name 'fix_evidence_ref'
        review_round     = 0
        actor_role       = 'reviewer'
        recorded_at      = $RecordedAt
    }
}

function ConvertTo-ContinuousCoReviewDispositionRecord {
    param(
        [Parameter(Mandatory)]
        $Disposition,

        [Parameter(Mandatory)]
        [string] $RecordedAt
    )

    $reviewRound = Get-ContinuousCoReviewObjectProperty -Object $Disposition -Name 'review_round'
    if ($null -eq $reviewRound) {
        $reviewRound = 0
    }

    $recordedAt = Get-ContinuousCoReviewObjectProperty -Object $Disposition -Name 'recorded_at'
    if ([string]::IsNullOrWhiteSpace([string] $recordedAt)) {
        $recordedAt = $RecordedAt
    }

    return [pscustomobject][ordered]@{
        disposition_id   = Get-ContinuousCoReviewObjectProperty -Object $Disposition -Name 'disposition_id'
        finding_id       = Get-ContinuousCoReviewObjectProperty -Object $Disposition -Name 'finding_id'
        state            = Get-ContinuousCoReviewObjectProperty -Object $Disposition -Name 'state'
        rationale        = Get-ContinuousCoReviewObjectProperty -Object $Disposition -Name 'rationale'
        fix_evidence_ref = Get-ContinuousCoReviewObjectProperty -Object $Disposition -Name 'fix_evidence_ref'
        review_round     = [int] $reviewRound
        actor_role       = Get-ContinuousCoReviewObjectProperty -Object $Disposition -Name 'actor_role'
        recorded_at      = [string] $recordedAt
    }
}

function New-ContinuousCoReviewBlackboardThread {
    param(
        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [Parameter(Mandatory)]
        $FindingsResult,

        [AllowNull()]
        $DispositionTrail,

        [AllowNull()]
        [string] $EscalationRef,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $createdAtText = ConvertTo-ContinuousCoReviewIsoTimestamp -Timestamp $CreatedAt
    $runId = Get-ContinuousCoReviewObjectProperty -Object $FindingsResult -Name 'run_id'
    if ([string]::IsNullOrWhiteSpace([string] $runId)) {
        throw 'FindingsResult.run_id is required to write a review blackboard thread.'
    }

    $findingIds = @(
        foreach ($finding in @($FindingsResult.findings)) {
            Get-ContinuousCoReviewObjectProperty -Object $finding -Name 'finding_id'
        }
    )

    $dispositions = @()
    if ($null -ne $DispositionTrail) {
        $dispositions = @(
            foreach ($disposition in @($DispositionTrail)) {
                ConvertTo-ContinuousCoReviewDispositionRecord -Disposition $disposition -RecordedAt $createdAtText
            }
        )
    }

    if (@($dispositions).Count -eq 0) {
        $dispositions = @(
            foreach ($finding in @($FindingsResult.findings)) {
                New-ContinuousCoReviewDispositionFromFinding -Finding $finding -RecordedAt $createdAtText
            }
        )
    }

    $summary = if (@($findingIds).Count -eq 0) {
        'Inline reviewer returned no findings; blackboard thread records no-op result.'
    }
    else {
        "Inline reviewer returned $(@($findingIds).Count) finding(s); disposition trail persisted by orchestrator."
    }

    return [pscustomobject][ordered]@{
        schema_version     = '1.0'
        thread_id          = "thread-$runId"
        run_id             = $runId
        checkpoint_id      = $CheckpointId
        findings           = @($findingIds)
        dispositions       = @($dispositions)
        resolution_summary = $summary
        escalation_ref     = $EscalationRef
        created_at         = $createdAtText
        updated_at         = $createdAtText
    }
}

function New-ContinuousCoReviewRedactedEvidenceRecord {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $FindingsRef,

        [Parameter(Mandatory)]
        [string] $ThreadRef,

        [Parameter(Mandatory)]
        [string] $CreatedAt
    )

    return [pscustomobject][ordered]@{
        schema_version                = '1.0'
        run_id                        = $RunId
        findings_result_ref           = $FindingsRef
        review_thread_ref             = $ThreadRef
        temporary_bundle_policy       = 'not-persisted-by-blackboard-writer'
        raw_provider_transcripts      = 'not-stored'
        raw_prompts                   = 'not-stored'
        secret_or_environment_capture = 'not-stored'
        created_at                    = $CreatedAt
    }
}

function Assert-ContinuousCoReviewBlackboardNoDrift {
    param(
        [Parameter(Mandatory)]
        [string] $RunRoot,

        [Parameter(Mandatory)]
        $FindingsResult,

        [Parameter(Mandatory)]
        $ReviewThread
    )

    $existingFindingsPath = Join-Path $RunRoot 'findings-result.json'
    if (Test-Path -LiteralPath $existingFindingsPath -PathType Leaf) {
        $existingFindings = ConvertFrom-ReviewerContractJson -Json (Get-Content -LiteralPath $existingFindingsPath -Raw)
        if ((ConvertTo-ReviewerContractCanonicalJson -InputObject $existingFindings) -ne (ConvertTo-ReviewerContractCanonicalJson -InputObject $FindingsResult)) {
            throw "Durable review artifact already exists with different content: $existingFindingsPath"
        }
    }

    $existingThreadPath = Join-Path $RunRoot 'review-thread.json'
    if (Test-Path -LiteralPath $existingThreadPath -PathType Leaf) {
        $existingThread = ConvertFrom-ReviewerContractJson -Json (Get-Content -LiteralPath $existingThreadPath -Raw)
        if ((ConvertTo-ReviewerContractCanonicalJson -InputObject $existingThread) -ne (ConvertTo-ReviewerContractCanonicalJson -InputObject $ReviewThread)) {
            throw "Durable review artifact already exists with different content: $existingThreadPath"
        }
    }
}

function Write-ContinuousCoReviewBlackboardThread {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [Parameter(Mandatory)]
        $FindingsResult,

        [AllowNull()]
        $DispositionTrail,

        [AllowNull()]
        [string] $EscalationRef,

        [string] $SchemaRoot,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
    if ($SchemaRoot) {
        Assert-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $SchemaRoot -InputObject $FindingsResult | Out-Null
    }

    $thread = New-ContinuousCoReviewBlackboardThread `
        -CheckpointId $CheckpointId `
        -FindingsResult $FindingsResult `
        -DispositionTrail $DispositionTrail `
        -EscalationRef $EscalationRef `
        -CreatedAt $CreatedAt

    if ($SchemaRoot) {
        Assert-ReviewerContractObject -ContractName 'ReviewThread' -SchemaRoot $SchemaRoot -InputObject $thread | Out-Null
    }

    $runId = $FindingsResult.run_id
    $runRoot = Join-Path $resolvedRepoRoot ".specrew/review/inline/$runId"
    New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
    Assert-ContinuousCoReviewBlackboardNoDrift -RunRoot $runRoot -FindingsResult $FindingsResult -ReviewThread $thread

    $findingsPath = Join-Path $runRoot 'findings-result.json'
    $threadPath = Join-Path $runRoot 'review-thread.json'
    $evidencePath = Join-Path $runRoot 'redacted-evidence.json'

    Write-ContinuousCoReviewIdempotentJson -Path $findingsPath -InputObject $FindingsResult
    Write-ContinuousCoReviewIdempotentJson -Path $threadPath -InputObject $thread

    $createdAtText = ConvertTo-ContinuousCoReviewIsoTimestamp -Timestamp $CreatedAt
    $redactedEvidence = New-ContinuousCoReviewRedactedEvidenceRecord `
        -RunId $runId `
        -FindingsRef 'findings-result.json' `
        -ThreadRef 'review-thread.json' `
        -CreatedAt $createdAtText
    Write-ContinuousCoReviewIdempotentJson -Path $evidencePath -InputObject $redactedEvidence

    return [pscustomobject][ordered]@{
        schema_version        = '1.0'
        run_id                = $runId
        checkpoint_id         = $CheckpointId
        blackboard_root       = $runRoot
        findings_result_path  = $findingsPath
        review_thread_path    = $threadPath
        redacted_evidence_path = $evidencePath
        review_thread         = $thread
    }
}
