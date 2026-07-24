$ErrorActionPreference = 'Stop'

Describe 'Shared production review harness contract and strict candidate matrix (T053)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-store.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-target-port.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-result-ingestor.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-host-catalog.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-harness-contract.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-claude-harness-port.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1')

        function script:New-HarnessCandidate {
            param([string]$RunId = 'run-one', [string]$Digest = 'digest-one', [object[]]$Findings = @())
            $verdict = if (@($Findings).Count -eq 0) { 'pass' } else { 'findings' }
            return [pscustomobject][ordered]@{
                schema_version = '1.0'; run_id = $RunId; target_digest = $Digest
                completion = 'complete'; verdict = $verdict; summary = 'bounded fixture result'; findings = @($Findings)
            }
        }

        function script:New-HarnessFinding {
            return [pscustomobject][ordered]@{
                local_id = 'local-one'; severity = 'major'; title = 'Observed defect'
                description = 'A deterministic candidate finding.'; location = 'src/example.ps1:4'
            }
        }

        function script:New-HarnessInvocation {
            param([Parameter(Mandatory)][string]$Root, [string]$ReviewScope = 'Review source correctness.')
            $snapshot = Join-Path $Root 'snapshot'
            $stage = Join-Path $Root 'stage'
            New-Item -ItemType Directory -Path $snapshot, $stage -Force | Out-Null
            return [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-demo'; run_id = 'run-one'; target_digest = 'digest-one'
                snapshot_path = $snapshot; review_scope = $ReviewScope
                prompt_path = (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md')
                candidate_result_path = (Join-Path $stage 'candidate.json')
                candidate_report_path = (Join-Path $stage 'candidate.md')
                deadline = '2026-07-16T12:00:00Z'
            }
        }

        function script:Read-HarnessCandidateText {
            param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][AllowEmptyString()][string]$Text)
            New-Item -ItemType Directory -Path $Root -Force | Out-Null
            $path = Join-Path $Root 'candidate.json'
            [IO.File]::WriteAllText($path, $Text, [Text.UTF8Encoding]::new($false))
            return Read-ReviewCandidateResult -Path $path -ExpectedRunId 'run-one' -ExpectedTargetDigest 'digest-one'
        }
    }

    It 'freezes one bounded prompt contract with every placeholder exactly once' {
        $path = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md'
        $template = [IO.File]::ReadAllText($path, [Text.UTF8Encoding]::new($false, $true))
        $validation = Test-ReviewFilePrimaryPromptTemplate -Template $template
        $validation.valid | Should -BeTrue -Because ($validation.errors -join ', ')
        $validation.byte_count | Should -BeLessOrEqual (Get-ReviewHarnessContractLimits).max_prompt_template_bytes
        foreach ($placeholder in (Get-ReviewFilePrimaryPromptPlaceholders)) {
            ([regex]::Matches($template, [regex]::Escape($placeholder))).Count | Should -Be 1
        }
    }

    It 'derives every advertised prompt budget below the central ingress maximum' {
        $authority = Get-ReviewAuthorityCandidateLimits
        $advertised = Get-ReviewHarnessContractLimits
        $advertised.max_candidate_bytes | Should -Be $authority.max_candidate_bytes
        $advertised.advertised_summary_characters | Should -BeLessOrEqual $authority.max_summary_characters
        $advertised.advertised_findings | Should -BeLessOrEqual $authority.max_findings
        $advertised.advertised_local_id_characters | Should -BeLessOrEqual $authority.max_local_id_characters
        $advertised.advertised_title_characters | Should -BeLessOrEqual $authority.max_title_characters
        $advertised.advertised_description_characters | Should -BeLessOrEqual $authority.max_description_characters
        $advertised.advertised_location_characters | Should -BeLessOrEqual $authority.max_location_characters

        $template = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md') -Raw
        $rendered = Render-ReviewFilePrimaryPrompt -Template $template -Invocation (New-HarnessInvocation -Root (Join-Path $TestDrive 'derived-budgets'))
        $rendered | Should -Match "summary at most $($advertised.advertised_summary_characters) characters"
        $rendered | Should -Match "no more than $($advertised.advertised_findings) findings"
        $rendered | Should -Not -Match '__MAX_[A-Z0-9_]+__'
    }

    It 'keeps candidate byte authority in one source and passes it explicitly to ingress' {
        $authoritySource = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1') -Raw
        $harnessSource = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-harness-contract.ps1') -Raw
        $ingressSource = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-result-ingestor.ps1') -Raw
        ([regex]::Matches($authoritySource, '262144')).Count | Should -Be 1
        $harnessSource | Should -Not -Match '262144'
        $ingressSource | Should -Not -Match '262144'
        $harnessSource | Should -Match 'max_candidate_bytes = \$authority\.max_candidate_bytes'
        $ingressSource | Should -Match 'Read-ReviewCandidateResult.+-MaxBytes \$candidateLimits\.max_candidate_bytes'
    }

    It 'rejects missing, repeated, unknown, and oversized prompt-template contracts' {
        $template = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md') -Raw
        (Test-ReviewFilePrimaryPromptTemplate -Template ($template.Replace('__DEADLINE__', 'deadline'))).valid | Should -BeFalse
        (Test-ReviewFilePrimaryPromptTemplate -Template ($template + "`n__RUN_ID__")).valid | Should -BeFalse
        (Test-ReviewFilePrimaryPromptTemplate -Template ($template + "`n__UNKNOWN_VALUE__")).valid | Should -BeFalse
        (Test-ReviewFilePrimaryPromptTemplate -Template ($template + ('x' * 33000))).valid | Should -BeFalse
    }

    It 'rejects a prompt that drops the single-reviewer-session prohibition' {
        $template = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md') -Raw
        $weakened = [regex]::Replace($template, '(?is)do not delegate to\s+subagents or start other model-backed reviewers\.', 'work independently.')
        $validation = Test-ReviewFilePrimaryPromptTemplate -Template $weakened
        $validation.valid | Should -BeFalse
        $validation.errors | Should -Contain 'prompt-contract-missing:single-reviewer-session'
    }

    It 'rejects a prompt that falsely claims every host restricts the exposed tool set' {
        $template = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md') -Raw
        $weakened = [regex]::Replace(
            $template,
            '(?is)The approved review contract permits only Read.+?outside the approved review contract\.',
            'Your available tools are deliberately limited to Read, Glob, Grep, and Write.'
        )
        $validation = Test-ReviewFilePrimaryPromptTemplate -Template $weakened
        $validation.valid | Should -BeFalse
        $validation.errors | Should -Contain 'prompt-contract-missing:host-tool-posture'
    }

    It 'rejects a prompt that makes complete mean exhaustive file-by-file inventory' {
        $template = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md') -Raw
        $weakened = [regex]::Replace(
            $template,
            '(?is)Review the frozen workspace.+?Do not modify the source,',
            'Review the complete frozen workspace exhaustively. Do not modify the source,'
        )
        $validation = Test-ReviewFilePrimaryPromptTemplate -Template $weakened
        $validation.valid | Should -BeFalse
        $validation.errors | Should -Contain 'prompt-contract-missing:risk-based-completion'
    }

    It 'rejects a prompt that leaves the optional finding location type ambiguous' {
        $template = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md') -Raw
        $weakened = [regex]::Replace($template, '(?is)`location`, when present,.+?grounded source location\.', '`location` is optional.')
        $validation = Test-ReviewFilePrimaryPromptTemplate -Template $weakened
        $validation.valid | Should -BeFalse
        $validation.errors | Should -Contain 'prompt-contract-missing:location-string-type'
    }

    It 'rejects a prompt that omits the conservative candidate-size budgets' {
        $template = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md') -Raw
        $weakened = [regex]::Replace(
            $template,
            '(?is)Keep the candidate well inside the schema bounds:.+?never truncate the JSON object\.',
            'Keep the candidate concise.'
        )
        $validation = Test-ReviewFilePrimaryPromptTemplate -Template $weakened
        $validation.valid | Should -BeFalse
        $validation.errors | Should -Contain 'prompt-contract-missing:summary-budget'
        $validation.errors | Should -Contain 'prompt-contract-missing:finding-budgets'
    }

    It 'catalogs all five production vectors under the same file-primary contract without implementing absent adapters' {
        $expected = @('claude', 'codex', 'copilot', 'cursor-agent', 'antigravity')
        foreach ($hostName in $expected) {
            $definition = Get-ContinuousCoReviewProductionHarnessDefinition -HostName $hostName
            $definition | Should -Not -BeNullOrEmpty
            $definition.harness_id | Should -Match '^[a-z0-9-]{1,64}$'
            $definition.constructor | Should -Match '^New-Review[A-Za-z0-9]+FilePrimaryHarnessPort$'
            $definition.result_transport | Should -Be 'file-primary'
            $definition.candidate_contract_version | Should -Be '1.0'
            $definition.prompt_transport | Should -BeIn @('stdin', 'argument')
            $definition.default_timeout_seconds | Should -BeGreaterOrEqual 1
            $definition.default_timeout_seconds | Should -BeLessOrEqual 7200
        }
        (New-ReviewProductionHarnessPort -HostName claude -TimeoutSeconds 600).id | Should -Be 'claude-code-file-primary'
        foreach ($hostName in @('codex', 'copilot', 'cursor-agent', 'antigravity')) {
            $port = New-ReviewProductionHarnessPort -HostName $hostName -TimeoutSeconds 600
            $port.result_transport | Should -Be 'file-primary'
            (& $port.preflight $null).reason | Should -Be "production-harness-not-implemented:$hostName"
        }
    }

    It 'builds a bounded Claude process spec with only the approved environment delta and no source payload' {
        $invocation = New-HarnessInvocation -Root (Join-Path $TestDrive 'process-spec') -ReviewScope 'Inspect behavior; keep __RUN_ID__ as literal scope text.'
        $port = New-ReviewClaudeFilePrimaryHarnessPort -TimeoutSeconds 600 -AvailabilityProbe { $true }
        (& $port.preflight $invocation).ok | Should -BeTrue
        $spec = & $port.build_process $invocation ([ordered]@{
            SPECREW_REFOCUS_DISABLE = '1'; SPECREW_DISABLE_EVENTS = 'SessionStart,Stop'; UNRELATED_SECRET = 'must-not-copy'
        })
        $spec.command | Should -Be 'claude'
        $spec.prompt_transport | Should -Be 'stdin'
        $spec.argument_list | Should -Be @(
            '-p', '--no-session-persistence', '--setting-sources', '', '--disable-slash-commands', '--no-chrome',
            '--strict-mcp-config', '--mcp-config', '{"mcpServers":{}}', '--tools', 'Read,Glob,Grep,Write',
            '--permission-mode', 'bypassPermissions'
        )
        @($spec.argument_list | Where-Object { $_ -ceq '{}' }).Count | Should -Be 0 -Because 'an empty object is not a valid strict Claude MCP document and aborts before review startup'
        [array]::IndexOf(@($spec.argument_list), '--mcp-config') | Should -BeGreaterOrEqual 0
        $spec.argument_list[[array]::IndexOf(@($spec.argument_list), '--mcp-config') + 1] | Should -Be '{"mcpServers":{}}'
        $spec.working_directory | Should -Be ([IO.Path]::GetFullPath($invocation.snapshot_path))
        $spec.candidate_result_path | Should -Be ([IO.Path]::GetFullPath($invocation.candidate_result_path))
        $spec.stdout_authority | Should -BeFalse
        $spec.result_transport | Should -Be 'file-primary'
        @($spec.environment_delta.Keys) | Should -Be @('SPECREW_REFOCUS_DISABLE', 'SPECREW_DISABLE_EVENTS')
        $spec.stdin_text | Should -Match ([regex]::Escape([IO.Path]::GetFullPath($invocation.candidate_result_path)))
        $spec.stdin_text | Should -Match 'run-one'
        $spec.stdin_text | Should -Match 'digest-one'
        $spec.stdin_text | Should -Match '__RUN_ID__ as literal scope text' -Because 'replacement must not recursively expand reviewer-supplied scope text'
        $spec.stdin_text | Should -Match 'Use Write only for the exact candidate result path'
        $spec.stdin_text | Should -Match 'Even if\s+the host exposes additional tools, they are outside the approved review contract'
        $spec.stdin_text | Should -Match 'Do not run tests, shell commands, installers, update commands, or repository automation'
        $spec.stdin_text | Should -Not -Match 'must-not-copy'
    }

    It 'fails preflight before invocation when the executable is unavailable or the candidate path already exists' {
        $invocation = New-HarnessInvocation -Root (Join-Path $TestDrive 'preflight')
        $calls = 0
        $invoker = { param($worktree, $prompt, $timeout) $calls++; throw 'must-not-run' }.GetNewClosure()
        $unavailable = New-ReviewClaudeFilePrimaryHarnessPort -AgentInvoker $invoker -AvailabilityProbe { $false }
        (& $unavailable.preflight $invocation).ok | Should -BeFalse
        $calls | Should -Be 0
        [IO.File]::WriteAllText($invocation.candidate_result_path, '{}')
        $available = New-ReviewClaudeFilePrimaryHarnessPort -AgentInvoker $invoker -AvailabilityProbe { $true }
        (& $available.preflight $invocation).reason | Should -Be 'candidate-path-preexists'
        $calls | Should -Be 0
    }

    It 'invokes once, ignores stdout for authority, and performs no hidden retry after invalid file output' {
        $invocation = New-HarnessInvocation -Root (Join-Path $TestDrive 'one-call')
        $calls = [Collections.Generic.List[string]]::new()
        $validButNonAuthoritativeStdout = New-HarnessCandidate | ConvertTo-Json -Depth 20 -Compress
        $invoker = {
            param($worktree, $prompt, $timeout)
            $calls.Add($prompt) | Out-Null
            [IO.File]::WriteAllText($invocation.candidate_result_path, '{"not":"a candidate"}', [Text.UTF8Encoding]::new($false))
            return [pscustomobject]@{ exit_code = 0; stdout = $validButNonAuthoritativeStdout; stderr = '' }
        }.GetNewClosure()
        $port = New-ReviewClaudeFilePrimaryHarnessPort -AgentInvoker $invoker -AvailabilityProbe { $true }
        $activity = & $port.invoke $invocation (Get-ReviewTargetSuppressionEnvironment)
        $calls.Count | Should -Be 1
        $activity.output_activity | Should -BeTrue
        $activity.stdout_authority | Should -BeFalse
        $read = Read-ReviewCandidateResult -Path $invocation.candidate_result_path -ExpectedRunId run-one -ExpectedTargetDigest digest-one
        $read.valid | Should -BeFalse
        $calls.Count | Should -Be 1 -Because 'strict ingress rejection never grants an implicit provider retry'
    }

    It 'accepts complete zero-finding and findings candidates from the file-primary channel' {
        $zero = New-HarnessCandidate | ConvertTo-Json -Depth 20 -Compress
        $withFindings = New-HarnessCandidate -Findings @(New-HarnessFinding) | ConvertTo-Json -Depth 20 -Compress
        (Read-HarnessCandidateText -Root (Join-Path $TestDrive 'valid-zero') -Text $zero).valid | Should -BeTrue
        $read = Read-HarnessCandidateText -Root (Join-Path $TestDrive 'valid-findings') -Text $withFindings
        $read.valid | Should -BeTrue
        @($read.candidate.findings).Count | Should -Be 1
    }

    It 'rejects a candidate whose summary exceeds the strict ingress maximum' {
        $candidate = New-HarnessCandidate
        $candidate.summary = 'x' * 4001
        $read = Read-HarnessCandidateText -Root (Join-Path $TestDrive 'summary-too-long') -Text ($candidate | ConvertTo-Json -Depth 20 -Compress)
        $read.valid | Should -BeFalse
        $read.category | Should -Be 'schema-invalid'
        $read.errors | Should -Contain 'too-long:summary:4000'
    }

    It 'rejects prose, fences, trailing text, malformed JSON, unknown fields, missing fields, identity drift, and unsupported versions' -ForEach @(
        @{ name = 'prose'; text = 'Here is the result: {"schema_version":"1.0"}'; category = 'prose-wrapped-json' }
        @{ name = 'fence'; text = ('```json' + "`n" + '{"schema_version":"1.0"}' + "`n" + '```'); category = 'prose-wrapped-json' }
        @{ name = 'trailing'; text = '{"schema_version":"1.0"} complete'; category = 'prose-wrapped-json' }
        @{ name = 'malformed'; text = '{"schema_version":"1.0",}'; category = 'invalid-json' }
        @{ name = 'unknown-top'; text = '{"schema_version":"1.0","run_id":"run-one","target_digest":"digest-one","completion":"complete","verdict":"pass","summary":"x","findings":[],"extra":true}'; category = 'unknown-field' }
        @{ name = 'unknown-finding'; text = '{"schema_version":"1.0","run_id":"run-one","target_digest":"digest-one","completion":"complete","verdict":"findings","summary":"x","findings":[{"local_id":"a","severity":"major","title":"t","description":"d","extra":true}]}'; category = 'unknown-field' }
        @{ name = 'location-object'; text = '{"schema_version":"1.0","run_id":"run-one","target_digest":"digest-one","completion":"complete","verdict":"findings","summary":"x","findings":[{"local_id":"a","severity":"major","title":"t","description":"d","location":{"path":"src/a.ps1","line":4}}]}'; category = 'schema-invalid' }
        @{ name = 'location-array'; text = '{"schema_version":"1.0","run_id":"run-one","target_digest":"digest-one","completion":"complete","verdict":"findings","summary":"x","findings":[{"local_id":"a","severity":"major","title":"t","description":"d","location":["src/a.ps1:4"]}]}'; category = 'schema-invalid' }
        @{ name = 'missing'; text = '{"schema_version":"1.0","run_id":"run-one","target_digest":"digest-one","completion":"complete","verdict":"pass","summary":"x"}'; category = 'schema-invalid' }
        @{ name = 'wrong-run'; text = '{"schema_version":"1.0","run_id":"run-other","target_digest":"digest-one","completion":"complete","verdict":"pass","summary":"x","findings":[]}'; category = 'identity-mismatch' }
        @{ name = 'wrong-digest'; text = '{"schema_version":"1.0","run_id":"run-one","target_digest":"digest-other","completion":"complete","verdict":"pass","summary":"x","findings":[]}'; category = 'identity-mismatch' }
        @{ name = 'version'; text = '{"schema_version":"2.0","run_id":"run-one","target_digest":"digest-one","completion":"complete","verdict":"pass","summary":"x","findings":[]}'; category = 'unsupported-version' }
    ) {
        $read = Read-HarnessCandidateText -Root (Join-Path $TestDrive "invalid-$name") -Text $text
        $read.valid | Should -BeFalse
        $read.category | Should -Be $category
    }

    It 'rejects duplicate fields, invalid UTF-8, and payloads over the shared bound' {
        $duplicate = '{"schema_version":"1.0","run_id":"run-one","run_id":"run-two","target_digest":"digest-one","completion":"complete","verdict":"pass","summary":"x","findings":[]}'
        (Read-HarnessCandidateText -Root (Join-Path $TestDrive 'duplicate') -Text $duplicate).category | Should -Be 'duplicate-field'

        $invalidRoot = Join-Path $TestDrive 'invalid-utf8'; New-Item -ItemType Directory -Path $invalidRoot -Force | Out-Null
        $invalidPath = Join-Path $invalidRoot 'candidate.json'
        [IO.File]::WriteAllBytes($invalidPath, [byte[]](0x7B, 0x22, 0x78, 0x22, 0x3A, 0x22, 0xC3, 0x28, 0x22, 0x7D))
        (Read-ReviewCandidateResult -Path $invalidPath -ExpectedRunId run-one -ExpectedTargetDigest digest-one).category | Should -Be 'invalid-utf8'

        $largeRoot = Join-Path $TestDrive 'large'; New-Item -ItemType Directory -Path $largeRoot -Force | Out-Null
        $largePath = Join-Path $largeRoot 'candidate.json'
        [IO.File]::WriteAllBytes($largePath, [byte[]]::new((Get-ReviewHarnessContractLimits).max_candidate_bytes + 1))
        (Read-ReviewCandidateResult -Path $largePath -ExpectedRunId run-one -ExpectedTargetDigest digest-one).category | Should -Be 'payload-too-large'
    }

    It 'rejects a rendered prompt over the shared bound before an invocation can start' {
        $invocation = New-HarnessInvocation -Root (Join-Path $TestDrive 'rendered-large') -ReviewScope ('x' * 66000)
        $port = New-ReviewClaudeFilePrimaryHarnessPort -AvailabilityProbe { $true }
        { & $port.build_process $invocation @{} } | Should -Throw '*rendered-prompt-too-large*'
    }

    It 'rejects origin-owned campaign staging before creating grant authority or invoking a provider' {
        $origin = Join-Path $TestDrive 'origin-staging'
        New-Item -ItemType Directory -Path (Join-Path $origin 'specs/001-demo/iterations/007') -Force | Out-Null
        $config = Join-Path $origin 'authority.json'
        [IO.File]::WriteAllText($config, '{"schema_version":"1.0","mode":"campaign"}', [Text.UTF8Encoding]::new($false))
        $store = Join-Path $origin 'store'
        { Invoke-ReviewCampaignCommand -RepoRoot $origin -FeatureId '001-demo' -IterationNumber '007' -RunId 'run-one' -GrantAuthorizationRef 'human-slot' -AuthorityConfigPath $config -StoreRoot $store -StagingRoot (Join-Path $origin 'staging') } |
            Should -Throw '*review-campaign-staging-root-inside-origin*'
        Test-Path -LiteralPath $store | Should -BeFalse
    }
}
