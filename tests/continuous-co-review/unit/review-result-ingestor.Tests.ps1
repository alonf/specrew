$ErrorActionPreference = 'Stop'

# Trace: T047 / FR-059..FR-062 / SC-018, SC-020.
Describe 'Strict candidate result ingress and controller publication (T047)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-result-ingestor.ps1')

        function script:New-IngressFinding {
            param([string]$LocalId = 'local-1', [string]$Severity = 'major', [string]$Title = 'Bug', [string]$Description = 'Incorrect behavior')
            [pscustomobject][ordered]@{ local_id = $LocalId; severity = $Severity; title = $Title; description = $Description; location = 'src/app.ps1:10' }
        }
        function script:New-IngressCandidate {
            param([string]$Run = 'run-one', [string]$Digest = 'digest-one', [string]$Completion = 'complete', [string]$Verdict = 'pass', [string]$Summary = 'review complete', [object[]]$Findings = @())
            [pscustomobject][ordered]@{ schema_version = '1.0'; run_id = $Run; target_digest = $Digest; completion = $Completion; verdict = $Verdict; summary = $Summary; findings = @($Findings) }
        }
        function script:Write-IngressCandidate {
            param([Parameter(Mandatory)][string]$Staging, [string]$Campaign = 'cmp-demo', [string]$Run = 'run-one', [Parameter(Mandatory)]$Candidate)
            $paths = Initialize-ReviewRunStaging -StagingRoot $Staging -CampaignId $Campaign -RunId $Run
            $json = if ($Candidate -is [string]) { $Candidate } else { $Candidate | ConvertTo-Json -Depth 20 -Compress }
            [IO.File]::WriteAllText($paths.candidate_result_path, $json, [Text.UTF8Encoding]::new($false))
            return $paths
        }
        function script:Invoke-TestIngress {
            param([Parameter(Mandatory)][string]$Store, [Parameter(Mandatory)][string]$Staging, [hashtable]$Override = @{})
            $parameters = @{
                StoreRoot = $Store; StagingRoot = $Staging; CampaignId = 'cmp-demo'; RunId = 'run-one'; TargetDigest = 'digest-one'
                HarnessId = 'fixture'; RuntimeOutcome = 'completed'; Invoked = $true; TerminationVerified = $true
                Containment = 'verified'; Currentness = 'current'; StartedAt = '2026-07-16T00:00:00Z'
                EndedAt = '2026-07-16T00:00:01Z'; DurationMs = 1000
            }
            foreach ($key in $Override.Keys) { $parameters[$key] = $Override[$key] }
            return Invoke-ReviewResultIngress @parameters
        }
    }

    It 'publishes a valid candidate as immutable controller JSON plus derived Markdown' {
        $store = Join-Path $TestDrive 'valid-store'; $staging = Join-Path $TestDrive 'valid-staging'
        $paths = Write-IngressCandidate -Staging $staging -Candidate (New-IngressCandidate)
        [IO.File]::WriteAllText($paths.candidate_report_path, 'Reviewer-authored Markdown is not authority.')

        Test-Path -LiteralPath (Join-Path $store 'campaigns/cmp-demo/runs/run-one/result.json') | Should -BeFalse
        $published = Invoke-TestIngress -Store $store -Staging $staging
        $published.published | Should -BeTrue
        $published.result.can_approve_current | Should -BeTrue
        $published.result.validation | Should -Be 'valid'
        $published.result.runtime_outcome | Should -Be 'completed'
        Test-Path -LiteralPath $published.result_path | Should -BeTrue
        Test-Path -LiteralPath $published.report_path | Should -BeTrue
        $persisted = Read-ReviewAuthorityFactFile -Path $published.result_path -ContractName ReviewResult
        $persisted.run_id | Should -Be 'run-one'
        (Get-Content -LiteralPath $published.report_path -Raw) | Should -Match 'controller-generated projection'
        (Get-Content -LiteralPath $published.report_path -Raw) | Should -Not -Match 'Reviewer-authored Markdown is not authority'
    }

    It 'publishes malformed output as controller-owned invalid-output without salvaging authority' {
        $store = Join-Path $TestDrive 'invalid-store'; $staging = Join-Path $TestDrive 'invalid-staging'
        Write-IngressCandidate -Staging $staging -Candidate 'Here is JSON: {"schema_version":"1.0"}' | Out-Null
        $published = Invoke-TestIngress -Store $store -Staging $staging
        $published.published | Should -BeTrue
        $published.candidate_category | Should -Be 'prose-wrapped-json'
        $published.result.runtime_outcome | Should -Be 'invalid-output'
        $published.result.validation | Should -Be 'invalid'
        $published.result.completion | Should -Be 'none'
        $published.result.can_approve_current | Should -BeFalse
        $published.result.findings.Count | Should -Be 0
    }

    It 'classifies a substituted run or target identity explicitly' {
        $store = Join-Path $TestDrive 'substitute-store'; $staging = Join-Path $TestDrive 'substitute-staging'
        Write-IngressCandidate -Staging $staging -Candidate (New-IngressCandidate -Run run-other -Digest digest-other) | Out-Null
        $published = Invoke-TestIngress -Store $store -Staging $staging
        $published.candidate_category | Should -Be 'identity-mismatch'
        $published.result.runtime_outcome | Should -Be 'identity-mismatch'
        $published.result.can_approve_current | Should -BeFalse
        $published.result.failure_reason | Should -Match 'identity-mismatch'
    }

    It 'is idempotent for the same terminal object and fails closed on a conflicting duplicate' {
        $store = Join-Path $TestDrive 'duplicate-store'; $staging = Join-Path $TestDrive 'duplicate-staging'
        $paths = Write-IngressCandidate -Staging $staging -Candidate (New-IngressCandidate)
        (Invoke-TestIngress -Store $store -Staging $staging).reason | Should -Be 'terminal-result-published'
        (Invoke-TestIngress -Store $store -Staging $staging).reason | Should -Be 'terminal-result-idempotent'

        [IO.File]::WriteAllText($paths.candidate_result_path, ((New-IngressCandidate -Summary 'different terminal content') | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
        { Invoke-TestIngress -Store $store -Staging $staging } | Should -Throw -ExpectedMessage '*review-store-corruption:conflicting-immutable-fact*'
    }

    It 'waits for verified process-tree death before publishing timeout and then retains valid partial findings' {
        $store = Join-Path $TestDrive 'timeout-store'; $staging = Join-Path $TestDrive 'timeout-staging'
        $finding = New-IngressFinding -Severity blocking
        Write-IngressCandidate -Staging $staging -Candidate (New-IngressCandidate -Completion partial -Verdict incomplete -Findings @($finding)) | Out-Null

        $beforeKill = Invoke-TestIngress -Store $store -Staging $staging -Override @{ RuntimeOutcome = 'timed-out'; TerminationVerified = $false; Containment = 'unknown'; FailureReason = 'timeout requested' }
        $beforeKill.published | Should -BeFalse
        $beforeKill.reason | Should -Be 'timeout-requires-verified-tree-death'
        Test-Path -LiteralPath (Join-Path $store 'campaigns/cmp-demo/runs/run-one/result.json') | Should -BeFalse

        $afterKill = Invoke-TestIngress -Store $store -Staging $staging -Override @{ RuntimeOutcome = 'timed-out'; TerminationVerified = $true; Containment = 'verified'; FailureReason = 'timed out; reviewer process tree verified dead' }
        $afterKill.published | Should -BeTrue
        $afterKill.result.runtime_outcome | Should -Be 'timed-out'
        $afterKill.result.completion | Should -Be 'partial'
        $afterKill.result.verdict | Should -Be 'incomplete'
        $afterKill.result.findings.Count | Should -Be 1
        $afterKill.result.findings[0].severity | Should -Be 'blocking'
        $afterKill.result.findings[0].relevance | Should -Be 'current'
        $afterKill.result.can_approve_current | Should -BeFalse
        (Get-Content -LiteralPath $afterKill.report_path -Raw) | Should -Match 'process tree verified dead'
    }

    It 'keeps moved-snapshot findings visible with lineage while preventing current approval' {
        $store = Join-Path $TestDrive 'moved-store'; $staging = Join-Path $TestDrive 'moved-staging'
        $finding = New-IngressFinding -LocalId reviewer-new -Severity minor
        Write-IngressCandidate -Staging $staging -Candidate (New-IngressCandidate -Verdict findings -Findings @($finding)) | Out-Null
        $prior = [pscustomobject]@{ finding_id = 'finding-prior'; lineage_id = 'lin-existing'; severity = 'blocking'; title = 'Bug'; description = 'Incorrect behavior'; location = 'src/app.ps1:10' }
        $published = Invoke-TestIngress -Store $store -Staging $staging -Override @{ Currentness = 'snapshot-moved'; PriorFindings = @($prior) }
        $published.result.completion | Should -Be 'complete'
        $published.result.currentness | Should -Be 'snapshot-moved'
        $published.result.can_approve_current | Should -BeFalse
        $published.result.findings.Count | Should -Be 1
        $published.result.findings[0].relevance | Should -Be 'snapshot-moved'
        $published.result.findings[0].lineage_id | Should -Be 'lin-existing'
        $published.result.findings[0].severity | Should -Be 'minor' -Because 'lineage linking never rewrites reviewer severity'
    }

    It 'keeps each run candidate and terminal artifact in its own directory' {
        $staging = Join-Path $TestDrive 'unique-staging'
        $one = Initialize-ReviewRunStaging -StagingRoot $staging -CampaignId cmp-demo -RunId run-one
        $two = Initialize-ReviewRunStaging -StagingRoot $staging -CampaignId cmp-demo -RunId run-two
        $one.candidate_result_path | Should -Not -Be $two.candidate_result_path
        $one.candidate_result_path | Should -Match 'run-one'
        $two.candidate_result_path | Should -Match 'run-two'
    }
}
