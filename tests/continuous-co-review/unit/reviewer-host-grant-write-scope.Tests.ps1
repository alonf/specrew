#requires -Version 7.0
# Trace: DRIFT-198-I009-031's sibling in the governance surface - DRIFT-198-I009-028, reported twice
# (observed directly on 2026-07-27, then reported again as finding-e78c294017b6e4fb by the
# re-certification round on 2026-07-29) and fixed under the maintainer's 2026-07-29 instruction.
#
# Recording ONE host's authorization used to serialize a FRESH DEFAULT catalog and copy only
# `allowed` / `authorization_ref` / `model` back from prior rows that were BOTH allowed and
# authorized. Three consequences, all silent:
#   - the addressed host's PINNED model reset whenever --model was omitted, destroying the
#     reviewer-of-record provenance that review evidence cites;
#   - every other field of every row reverted to its default;
#   - a SUSPENDED row is `allowed:false`, so it was not preserved at all - and the deliberate
#     reviewer-INDEPENDENCE suspension recorded in its authorization_ref was nulled, which could make
#     a suspended host selectable again: the exact violation the suspension existed to prevent.
#
# The property asserted here is the one the reviewer specified: recording a grant for one host leaves
# every other row byte-identical.

Describe 'recording a reviewer grant writes ONE field of ONE row' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ReviewScript = Join-Path $script:RepoRoot 'scripts/specrew-review.ps1'
        $script:GrantFixtures = [System.Collections.Generic.List[string]]::new()

        # A catalog shaped like the real one at the moment the defect bit: a pinned model on the row
        # being addressed, and a suspended row whose authorization_ref carries the policy REASON.
        function New-GrantFixtureProject {
            $root = Join-Path ([IO.Path]::GetTempPath()) ('specrew-grant-scope-' + [Guid]::NewGuid().ToString('N').Substring(0, 12))
            $null = New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force
            $catalog = [ordered]@{
                schema_version = '1.0'
                hosts          = @(
                    [ordered]@{
                        host = 'codex'; model = 'gpt-5.6-sol'; adapter_id = 'reviewer-host-adapter-codex-exec'
                        allowed = $true; installed = $true; review_class_rank = 85; model_source = 'human-entered'
                        cost_class = 'non-default'; authorization_ref = 'prior-grant-2026-07-28'
                        fallback_allowed = $false; timeout_seconds = 0
                    },
                    [ordered]@{
                        host = 'copilot'; model = 'gpt-5.5-or-claude-4.8'; adapter_id = 'reviewer-host-adapter-copilot-prompt'
                        allowed = $false; installed = $true; review_class_rank = 80; model_source = 'human-entered'
                        cost_class = 'non-default'
                        authorization_ref = 'suspended-2026-07-26-reviewer-independence: the row''s claude-4.8 arm cannot be excluded per-run, so copilot is not selectable while the implementation host is claude'
                        fallback_allowed = $false; timeout_seconds = 0
                    },
                    [ordered]@{
                        host = 'claude'; model = 'opus-4.8-1m-context'; adapter_id = 'reviewer-host-adapter-claude-prompt'
                        allowed = $true; installed = $true; review_class_rank = 85; model_source = 'human-entered'
                        cost_class = 'non-default'; authorization_ref = 'standing-human-grant-slot-9'
                        fallback_allowed = $false; timeout_seconds = 0
                    }
                )
            }
            ([pscustomobject]$catalog | ConvertTo-Json -Depth 100) | Set-Content -LiteralPath (Join-Path $root '.specrew/reviewer-hosts.json') -Encoding UTF8
            $script:GrantFixtures.Add($root)
            return (Resolve-Path -LiteralPath $root).Path
        }

        function Get-GrantCatalog {
            param([Parameter(Mandatory)][string]$ProjectRoot)
            return (Get-Content -LiteralPath (Join-Path $ProjectRoot '.specrew/reviewer-hosts.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100)
        }

        function Invoke-GrantRecording {
            param(
                [Parameter(Mandatory)][string]$ProjectRoot,
                [Parameter(Mandatory)][string]$HostName,
                [Parameter(Mandatory)][string]$Reference,
                [string]$ModelOverride
            )
            $arguments = @('-NoProfile', '-File', $script:ReviewScript, '-ProjectPath', $ProjectRoot, '--host', $HostName, '--authorization-ref', $Reference)
            if (-not [string]::IsNullOrWhiteSpace($ModelOverride)) { $arguments += @('--model', $ModelOverride) }
            $null = & 'pwsh' @arguments 2>&1
            return $LASTEXITCODE
        }
    }

    AfterAll {
        foreach ($fixture in $script:GrantFixtures) {
            try { if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force } }
            catch { $null = $_ }
        }
    }

    It 'updates the addressed row and leaves every OTHER row byte-identical' {
        $project = New-GrantFixtureProject
        $before = Get-GrantCatalog -ProjectRoot $project

        $exitCode = Invoke-GrantRecording -ProjectRoot $project -HostName 'codex' -Reference 'recertification-ref-under-test'
        $exitCode | Should -Be 0 -Because 'recording an authorization is a project-setup operation and must succeed'

        $after = Get-GrantCatalog -ProjectRoot $project
        $addressed = @($after.hosts | Where-Object { $_.host -eq 'codex' })[0]
        $addressed.authorization_ref | Should -Be 'recertification-ref-under-test'

        foreach ($priorRow in @($before.hosts | Where-Object { $_.host -ne 'codex' })) {
            $currentRow = @($after.hosts | Where-Object { $_.host -eq $priorRow.host })[0]
            $currentRow | Should -Not -BeNullOrEmpty -Because "row '$($priorRow.host)' must still exist"
            ($currentRow | ConvertTo-Json -Depth 100 -Compress) |
                Should -BeExactly ($priorRow | ConvertTo-Json -Depth 100 -Compress) `
                -Because "recording a grant for 'codex' must leave row '$($priorRow.host)' byte-identical"
        }
    }

    It 'preserves a SUSPENDED row''s policy reason, which is not merely a field but an independence control' {
        $project = New-GrantFixtureProject
        $null = Invoke-GrantRecording -ProjectRoot $project -HostName 'codex' -Reference 'another-ref'

        $suspended = @((Get-GrantCatalog -ProjectRoot $project).hosts | Where-Object { $_.host -eq 'copilot' })[0]
        $suspended.allowed | Should -BeFalse -Because 'a suspended host must not become selectable as a side effect of authorizing a different host'
        $suspended.authorization_ref | Should -Match 'suspended-2026-07-26-reviewer-independence' `
            -Because 'nulling this text is what made an independence violation possible; it is the control itself, not a comment'
    }

    It 'keeps the pinned model when --model is omitted, and replaces it only when supplied' {
        $project = New-GrantFixtureProject
        $null = Invoke-GrantRecording -ProjectRoot $project -HostName 'codex' -Reference 'ref-without-model'
        $addressed = @((Get-GrantCatalog -ProjectRoot $project).hosts | Where-Object { $_.host -eq 'codex' })[0]
        $addressed.model | Should -Be 'gpt-5.6-sol' -Because 'the maintainer-pinned reviewer-of-record model is provenance that review evidence cites; omitting --model is not a request to reset it'

        $null = Invoke-GrantRecording -ProjectRoot $project -HostName 'codex' -Reference 'ref-with-model' -ModelOverride 'gpt-5.7-explicit'
        $addressed = @((Get-GrantCatalog -ProjectRoot $project).hosts | Where-Object { $_.host -eq 'codex' })[0]
        $addressed.model | Should -Be 'gpt-5.7-explicit' -Because 'an EXPLICIT model is the one case where overwriting the pin is what the operator asked for'
    }

    It 'adds a row for a host the catalog does not yet carry, without rebuilding the file around it' {
        $project = New-GrantFixtureProject
        $before = Get-GrantCatalog -ProjectRoot $project

        $null = Invoke-GrantRecording -ProjectRoot $project -HostName 'cursor-agent' -Reference 'first-time-authorization'

        $after = Get-GrantCatalog -ProjectRoot $project
        @($after.hosts | Where-Object { $_.host -eq 'cursor-agent' }).Count | Should -Be 1 -Because 'a first-time authorization has to create the row'
        foreach ($priorRow in @($before.hosts)) {
            $currentRow = @($after.hosts | Where-Object { $_.host -eq $priorRow.host })[0]
            ($currentRow | ConvertTo-Json -Depth 100 -Compress) |
                Should -BeExactly ($priorRow | ConvertTo-Json -Depth 100 -Compress) `
                -Because "appending a new host must not disturb existing row '$($priorRow.host)'"
        }
    }
}
