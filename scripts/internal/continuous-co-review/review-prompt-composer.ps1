$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ContinuousCoReviewPromptValue {
    param(
        [AllowNull()]
        $Object,
        [Parameter(Mandatory)]
        [string] $Name,
        [AllowNull()]
        $DefaultValue = $null
    )

    if ($null -eq $Object) { return $DefaultValue }
    if (Test-ReviewerContractPropertyExists -Object $Object -Name $Name) {
        $value = Get-ReviewerContractPropertyValue -Object $Object -Name $Name
        if ($null -ne $value) { return $value }
    }
    return $DefaultValue
}

function Get-ContinuousCoReviewInstructionContent {
    param(
        [Parameter(Mandatory)]
        $Request,
        [string] $RepoRoot
    )

    $instruction = Get-ContinuousCoReviewPromptValue -Object $Request -Name 'reviewer_instruction'
    $canonicalPath = [string] (Get-ContinuousCoReviewPromptValue -Object $instruction -Name 'canonical_path' -DefaultValue 'scripts/internal/continuous-co-review/code-review-agent.md')
    $root = if ($RepoRoot) { (Resolve-Path -LiteralPath $RepoRoot).Path } else { (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path }
    $path = Join-Path $root $canonicalPath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Canonical reviewer instruction source not found: $path"
    }

    $content = Get-Content -LiteralPath $path -Raw
    $actualHash = "sha256:$(Get-ReviewerContractSha256Hex -Text $content)"
    $expectedHash = [string] (Get-ContinuousCoReviewPromptValue -Object $instruction -Name 'content_hash')
    if (-not [string]::IsNullOrWhiteSpace($expectedHash) -and $actualHash -ne $expectedHash) {
        throw "Canonical reviewer instruction hash mismatch. Expected $expectedHash but found $actualHash."
    }

    return [pscustomobject][ordered]@{
        canonical_path = $canonicalPath.Replace('\\', '/')
        content        = $content
        content_hash   = $actualHash
    }
}

function Get-ContinuousCoReviewFindingsResultContractContent {
    param(
        [string] $SchemaRoot
    )

    # Resolve the contract root via the CANONICAL resolver (an explicit SchemaRoot wins; otherwise the
    # module-base contracts dir) so the AUTHORITATIVE full JSON schema is embedded even when the caller
    # passed NO SchemaRoot - e.g. the DETACHED navigator reviewer path, whose harness calls the execution
    # engine without one. The old code only loaded the schema for an EXPLICIT SchemaRoot, so that path fell
    # back to the prose summary below -> codex 0.142/gpt-5.5 guessed the field SHAPES wrong (string
    # location/resolution; an out-of-enum "must_fix" disposition) -> FindingsResult schema-mismatch -> a
    # real review SILENTLY LOST (the iter-006 live-e2e first-run failure).
    try {
        $contractRoot = Get-ContinuousCoReviewContractRoot -SchemaRoot $SchemaRoot
        if ($contractRoot) {
            $schemaPath = Join-Path $contractRoot 'findings-result.schema.json'
            if (Test-Path -LiteralPath $schemaPath -PathType Leaf) {
                return Get-Content -LiteralPath $schemaPath -Raw
            }
        }
    }
    catch { $null = $_ }

    # Defense-in-depth prose (only reached if the schema file is unreachable): name the exact field SHAPES,
    # the closed enums, and a NEW finding's values, so a host given only this still emits conformant JSON.
    return 'FindingsResult.v1 - emit ONLY these properties (additionalProperties is false at every level). Top level: schema_version "1.0", run_id, status ("findings" or "no_findings"), findings (array), created_at. Each finding: finding_id, source_run_id, location (an OBJECT {path, line_start (int|null), line_end (int|null)} - NOT a string), severity ("blocking"|"advisory"|"nit"), kind, design_reference, comment, disposition ("open"|"accepted_fix_pending"|"resolved"|"rejected_with_rationale"|"escalated_to_human" - a NEW finding is "open", NOT "must_fix"), resolution (an OBJECT {state ("unresolved"|"resolved"|"rejected"|"escalated"), fix_evidence_ref (string|null), rationale (string|null)} - a NEW finding is {state:"unresolved"} - NOT a string).'
}

function New-ContinuousCoReviewPrompt {
    param(
        [Parameter(Mandatory)]
        $Request,
        [string] $SchemaRoot,
        [string] $RepoRoot,
        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    if ($SchemaRoot) {
        Assert-ReviewerContractObject -ContractName 'ReviewRequest' -SchemaRoot $SchemaRoot -InputObject $Request | Out-Null
    }
    if ($Request.schema_version -ne '2.0') {
        throw 'Review prompt composition requires ReviewRequest.v2.'
    }

    $instruction = Get-ContinuousCoReviewInstructionContent -Request $Request -RepoRoot $RepoRoot
    $designContext = Get-ContinuousCoReviewPromptValue -Object $Request -Name 'design_context'
    $changeSet = Get-ContinuousCoReviewPromptValue -Object $Request -Name 'change_set'
    $diffContent = [string] (Get-ContinuousCoReviewPromptValue -Object $changeSet -Name 'diff_content')
    if ([string]::IsNullOrWhiteSpace($diffContent)) {
        throw 'Review prompt composition requires exact diff/change-set content in ReviewRequest.v2 change_set.diff_content.'
    }
    $visibilityPolicy = Get-ContinuousCoReviewPromptValue -Object $Request -Name 'visibility_policy'
    $doPolicy = Get-ContinuousCoReviewPromptValue -Object $Request -Name 'do_policy'
    $priorFindings = @(Get-ContinuousCoReviewPromptValue -Object $Request -Name 'prior_findings' -DefaultValue @())
    $sources = @(Get-ContinuousCoReviewPromptValue -Object $designContext -Name 'sources' -DefaultValue @())
    $sourcePaths = @($sources | ForEach-Object { [string] (Get-ContinuousCoReviewPromptValue -Object $_ -Name 'path') })
    $priorFindingIds = @($priorFindings | ForEach-Object { [string] (Get-ContinuousCoReviewPromptValue -Object $_ -Name 'finding_id') })
    $requestJson = ConvertTo-ReviewerContractCanonicalJson -InputObject $Request
    $visibilityJson = ConvertTo-ReviewerContractCanonicalJson -InputObject $visibilityPolicy
    $doPolicyJson = ConvertTo-ReviewerContractCanonicalJson -InputObject $doPolicy
    $priorFindingsJson = ConvertTo-ReviewerContractCanonicalJson -InputObject $priorFindings
    $findingsResultContract = Get-ContinuousCoReviewFindingsResultContractContent -SchemaRoot $SchemaRoot
    $promptContent = @(
        '# Specrew Continuous Co-Review Runtime Prompt',
        '',
        '## Canonical Reviewer Instruction',
        "Source: $($instruction.canonical_path)",
        "Content hash: $($instruction.content_hash)",
        '',
        $instruction.content,
        '',
        '## ReviewRequest.v2 Metadata',
        "Run ID: $($Request.run_id)",
        "Checkpoint ID: $($Request.checkpoint_id)",
        "Request hash: $($Request.request_hash)",
        "Round number: $($Request.round_number)",
        "Output contract: $($Request.output_contract)",
        '',
        '## Design Context Sources',
        ($sourcePaths -join "`n"),
        '',
        '## Design Context Content',
        [string] (Get-ContinuousCoReviewPromptValue -Object $designContext -Name 'content'),
        '',
        '## Exact Diff / Change-Set Content',
        $diffContent,
        '',
        '## Prior Findings',
        $priorFindingsJson,
        '',
        '## Visibility Policy',
        $visibilityJson,
        '',
        '## Do Policy',
        $doPolicyJson,
        '',
        '## Full ReviewRequest.v2 JSON',
        $requestJson,
        '',
        '## FindingsResult.v1 JSON Schema',
        $findingsResultContract,
        '',
        'Return only valid FindingsResult.v1 JSON. Use `finding_id`, not `id`; do not emit properties absent from the schema. Return JSON only, with no Markdown or prose.'
    ) -join "`n"

    if ([string]::IsNullOrWhiteSpace($promptContent)) {
        throw 'Composed review prompt is empty.'
    }

    $promptHash = "sha256:$(Get-ReviewerContractSha256Hex -Text $promptContent)"
    return [pscustomobject][ordered]@{
        schema_version              = '1.0'
        run_id                      = $Request.run_id
        prompt_id                   = "prompt-$($Request.run_id)"
        review_request_hash         = $Request.request_hash
        reviewer_instruction_hash   = $instruction.content_hash
        design_context_sources      = @($sourcePaths)
        diff_hash                   = $Request.change_set.diff_hash
        round_number                = [int] $Request.round_number
        prior_finding_ids           = @($priorFindingIds)
        visibility_policy           = $visibilityPolicy
        do_policy                   = $doPolicy
        output_contract             = $Request.output_contract
        prompt_content              = $promptContent
        prompt_hash                 = $promptHash
        created_at                  = $CreatedAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
    }
}

function Write-ContinuousCoReviewPrompt {
    param(
        [Parameter(Mandatory)]
        $Prompt,
        [Parameter(Mandatory)]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace([string] $Prompt.prompt_content)) {
        throw 'Refusing to write an empty review prompt.'
    }
    Set-Content -LiteralPath $Path -Value ([string] $Prompt.prompt_content) -Encoding UTF8 -NoNewline
    return $Path
}
