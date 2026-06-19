$ErrorActionPreference = 'Stop'

# Trace: T044, FR-001, FR-006, INT-009, OBS-003, SC-001, SC-002, SC-005, SC-009, TG-011.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T044 TG-011 continuous co-review spine obeys implementation-rules.yml' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'
        $script:CreatedAt = [datetime] '2026-06-18T00:44:00Z'
    }

    function Invoke-T044Git {
        param(
            [Parameter(Mandatory)]
            [string] $Repository,

            [Parameter(Mandatory)]
            [string[]] $Arguments
        )

        $output = @(& git -C $Repository @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "git $($Arguments -join ' ') failed in $Repository with exit code ${exitCode}: $($output -join "`n")"
        }

        return @($output)
    }

    function New-T044GitRepository {
        param(
            [Parameter(Mandatory)]
            [string] $Name,

            [string] $SourceRelativePath = 'scripts/internal/continuous-co-review/reviewer-host-adapter-fixture.ps1'
        )

        $repository = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path $repository -Force | Out-Null
        Invoke-T044Git -Repository $repository -Arguments @('init', '--initial-branch=main') | Out-Null
        Invoke-T044Git -Repository $repository -Arguments @('config', 'user.email', 'proposal-197@example.invalid') | Out-Null
        Invoke-T044Git -Repository $repository -Arguments @('config', 'user.name', 'Proposal 197 Test') | Out-Null

        $sourcePath = Join-Path $repository $SourceRelativePath
        New-Item -ItemType Directory -Path (Split-Path -Parent $sourcePath) -Force | Out-Null
        Set-Content -LiteralPath $sourcePath -Value "function Invoke-FixtureReview { 'initial' }" -Encoding UTF8
        Invoke-T044Git -Repository $repository -Arguments @('add', '.') | Out-Null
        Invoke-T044Git -Repository $repository -Arguments @('commit', '-m', 'initial fixture') | Out-Null

        $baselineOutput = @(Invoke-T044Git -Repository $repository -Arguments @('rev-parse', 'HEAD'))

        return [pscustomobject][ordered]@{
            path         = $repository
            baseline_ref = ([string] $baselineOutput[0]).Trim()
            source_path  = $sourcePath
        }
    }

    function Add-T044ReviewableChange {
        param(
            [Parameter(Mandatory)]
            [string] $Path
        )

        Add-Content -LiteralPath $Path -Value "function Invoke-FixtureReviewChange { 'reviewable' }" -Encoding UTF8
    }

    function New-T044ProviderRequest {
        return [pscustomobject][ordered]@{
            requested_host    = 'fixture'
            requested_model   = 'fixture-reviewer'
            authorization_ref = 'authz-fixture-reviewer'
            timeout_seconds   = 60
            fallback_policy   = 'none'
        }
    }

    function New-T044Catalog {
        return [pscustomobject][ordered]@{
            schema_version = '1.0'
            hosts          = @(
                [pscustomobject][ordered]@{
                    host              = 'fixture'
                    model             = 'fixture-reviewer'
                    adapter_id        = 'reviewer-host-adapter-fixture'
                    allowed           = $true
                    installed         = $true
                    review_class_rank = 100
                    model_source      = 'human-entered'
                    cost_class        = 'free-local-fixture'
                    authorization_ref = 'authz-fixture-reviewer'
                    fallback_allowed  = $false
                }
            )
        }
    }

    function New-T044Candidate {
        return [pscustomobject][ordered]@{
            host              = 'fixture'
            model             = 'fixture-reviewer'
            adapter_id        = 'reviewer-host-adapter-fixture'
            authorization_ref = 'authz-fixture-reviewer'
            authorized        = $true
            timeout_seconds   = 60
        }
    }

    function New-T044SpawnInvocation {
        param(
            [Parameter(Mandatory)]
            $Request,

            [Parameter(Mandatory)]
            $Candidate,

            [Parameter(Mandatory)]
            [int] $AttemptNumber
        )

        return [pscustomobject][ordered]@{
            schema_version        = '1.0'
            invocation_id         = "invocation-$($Request.run_id)-$AttemptNumber"
            run_id                = $Request.run_id
            attempt_number        = $AttemptNumber
            adapter_id            = $Candidate.adapter_id
            requested_host        = $Request.provider_request.requested_host
            requested_model       = $Request.provider_request.requested_model
            actual_host           = $Candidate.host
            actual_model          = $Candidate.model
            argv_summary          = @('fixture-reviewer', '--stdin-request-json')
            working_directory_ref = '.specrew/review/inline'
            timeout_seconds       = $Candidate.timeout_seconds
            stdout_capture_policy = 'parse-json-only'
            stderr_capture_policy = 'status-only'
            exit_code             = 0
            failure_category      = $null
            started_at            = '2026-06-18T00:44:00Z'
            ended_at              = '2026-06-18T00:44:00Z'
        }
    }

    function New-T044FindingsResult {
        param(
            [Parameter(Mandatory)]
            $Request,

            [Parameter(Mandatory)]
            $Candidate
        )

        return [pscustomobject][ordered]@{
            schema_version = '1.0'
            run_id         = $Request.run_id
            status         = 'findings'
            reviewer       = [pscustomobject][ordered]@{
                host       = $Candidate.host
                model      = $Candidate.model
                adapter_id = $Candidate.adapter_id
            }
            findings       = @(
                [pscustomobject][ordered]@{
                    finding_id       = 'finding-t044-blocking'
                    source_run_id    = $Request.run_id
                    fingerprint      = 'sha256:t044-blocking'
                    location         = [pscustomobject][ordered]@{
                        path       = 'scripts/internal/continuous-co-review/reviewer-host-adapter-fixture.ps1'
                        line_start = 1
                        line_end   = 1
                    }
                    severity         = 'blocking'
                    kind             = 'design-contract-violation'
                    design_reference = 'FR-006'
                    comment          = 'Controlled fake adapter produces a deterministic blocking finding for the end-to-end spine.'
                    disposition      = 'open'
                    resolution       = [pscustomobject][ordered]@{
                        state            = 'unresolved'
                        fix_evidence_ref = $null
                        rationale        = $null
                    }
                }
            )
            created_at     = '2026-06-18T00:44:00Z'
        }
    }

    function Invoke-T044CheckpointReview {
        param(
            [Parameter(Mandatory)]
            [string] $Repository,

            [Parameter(Mandatory)]
            [string] $BaselineRef,

            [Parameter(Mandatory)]
            [string] $RunId,

            [scriptblock] $InvokeAdapter,

            [string[]] $ExcludedPathPatterns = @()
        )

        return Invoke-ContinuousCoReviewCheckpointReview `
            -RepoRoot $Repository `
            -CheckpointId 'checkpoint-t044' `
            -BaselineRef $BaselineRef `
            -RunId $RunId `
            -ProviderRequest (New-T044ProviderRequest) `
            -DesignContextRefs @(
                'specs/197-continuous-co-review/spec.md',
                'specs/197-continuous-co-review/implementation-rules.yml'
            ) `
            -Candidates @((New-T044Candidate)) `
            -Catalog (New-T044Catalog) `
            -SchemaRoot $script:SchemaRoot `
            -RunRoot (Join-Path $TestDrive "runs/$RunId") `
            -AllowedPaths @('scripts/internal/continuous-co-review/', 'tests/continuous-co-review/') `
            -ForbiddenPaths @('hosts/', 'extensions/specrew-speckit/scripts/provider-adapter.ps1') `
            -ExcludedPathPatterns $ExcludedPathPatterns `
            -InvokeAdapter $InvokeAdapter `
            -CreatedAt $script:CreatedAt
    }

    It 'runs request, fake-adapter findings, review thread, gate verdict, and review-run evidence end to end' {
        $fixtureRepository = New-T044GitRepository -Name 'reviewable-spine'
        Add-T044ReviewableChange -Path $fixtureRepository.source_path
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            return [pscustomobject][ordered]@{
                kind                   = 'findings-result'
                provider_invocation    = New-T044SpawnInvocation -Request $Request -Candidate $Candidate -AttemptNumber $AttemptNumber
                findings_result        = New-T044FindingsResult -Request $Request -Candidate $Candidate
                infrastructure_failure = $null
            }
        }

        $result = Invoke-T044CheckpointReview -Repository $fixtureRepository.path -BaselineRef $fixtureRepository.baseline_ref -RunId 'run-t044-reviewable' -InvokeAdapter $adapter

        $result.status | Should Be 'blocked'
        $result.request.output_contract | Should Be 'FindingsResult.v1'
        $result.request.request_hash | Should Match '^sha256:'
        $result.execution.readonly_boundary | Should Be 'fresh-context-request-bundle-only'
        $result.execution.findings_result.findings[0].finding_id | Should Be 'finding-t044-blocking'
        $result.blackboard.review_thread.findings[0] | Should Be 'finding-t044-blocking'
        $result.gate_verdict.state | Should Be 'blocked'
        $result.gate_verdict.unresolved_blocking_count | Should Be 1
        $result.run_index.review_run.status | Should Be 'blocked'
        $result.run_index.review_run.adapter_id | Should Be 'reviewer-host-adapter-fixture'

        (Test-ReviewerContractObject -ContractName 'ReviewRequest' -SchemaRoot $script:SchemaRoot -InputObject $result.request).Valid | Should Be $true
        (Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $result.execution.findings_result).Valid | Should Be $true
        (Test-ReviewerContractObject -ContractName 'ReviewThread' -SchemaRoot $script:SchemaRoot -InputObject $result.blackboard.review_thread).Valid | Should Be $true
        (Test-ReviewerContractObject -ContractName 'GateVerdict' -SchemaRoot $script:SchemaRoot -InputObject $result.gate_verdict).Valid | Should Be $true
    }

    It 'guards the reviewed project root when the runtime is invoked from another repository' {
        $fixtureRepository = New-T044GitRepository -Name 'reviewed-project-mutation-spine' -SourceRelativePath 'src/sample.ps1'
        Add-T044ReviewableChange -Path $fixtureRepository.source_path
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            Set-Content -LiteralPath $fixtureRepository.source_path -Value "function Invoke-FixtureReview { 'mutated-by-reviewer' }" -Encoding UTF8
            return [pscustomobject][ordered]@{
                kind                   = 'findings-result'
                provider_invocation    = New-T044SpawnInvocation -Request $Request -Candidate $Candidate -AttemptNumber $AttemptNumber
                findings_result        = New-T044FindingsResult -Request $Request -Candidate $Candidate
                infrastructure_failure = $null
            }
        }

        $result = Invoke-T044CheckpointReview -Repository $fixtureRepository.path -BaselineRef $fixtureRepository.baseline_ref -RunId 'run-t044-reviewed-root-mutation' -InvokeAdapter $adapter

        $result.status | Should Be 'infrastructure_failure'
        $result.infrastructure_failure.category | Should Be 'workspace-mutation-invalidated'
        $result.execution.mutation_guard.source_mutated | Should Be $true
        $result.execution.mutation_guard.changes[0].path | Should Be 'src/sample.ps1'
        $result.gate_verdict.state | Should Be 'unsafe'
    }

    It 'records a skipped run when the controlled change set has no reviewable diff' {
        $fixtureRepository = New-T044GitRepository -Name 'skipped-spine'

        $result = Invoke-T044CheckpointReview -Repository $fixtureRepository.path -BaselineRef $fixtureRepository.baseline_ref -RunId 'run-t044-skipped' -InvokeAdapter { throw 'adapter must not run for skipped change sets' }

        $result.status | Should Be 'skipped'
        $result.change_set.status | Should Be 'skipped'
        $result.change_set.skipped_run.reason | Should Be 'no-reviewable-diff'
        $result.gate_verdict.state | Should Be 'skipped'
        $result.gate_verdict.round_count | Should Be 0
        $result.run_index.review_run_skipped.status | Should Be 'skipped'
        $result.run_index.review_run_skipped.gate_verdict_ref | Should Be 'gate-verdict.json'
    }

    It 'maps infrastructure failure fixtures to unsafe gate verdict without creating findings' {
        $fixtureRepository = New-T044GitRepository -Name 'infrastructure-failure-spine'

        $result = Invoke-T044CheckpointReview -Repository $fixtureRepository.path -BaselineRef 'missing-baseline-for-t044' -RunId 'run-t044-infrastructure-failure' -InvokeAdapter { throw 'adapter must not run when diff collection fails' }

        $result.status | Should Be 'infrastructure_failure'
        $result.infrastructure_failure.category | Should Be 'command-invocation-failure'
        $result.gate_verdict.state | Should Be 'unsafe'
        ($result.gate_verdict.unsafe_reasons -contains 'command-invocation-failure') | Should Be $true
        $result.run_index.review_run.status | Should Be 'unsafe'

        (Test-ReviewerContractObject -ContractName 'InfrastructureFailure' -SchemaRoot $script:SchemaRoot -InputObject $result.infrastructure_failure).Valid | Should Be $true
        (Test-ReviewerContractObject -ContractName 'GateVerdict' -SchemaRoot $script:SchemaRoot -InputObject $result.gate_verdict).Valid | Should Be $true
    }
}
