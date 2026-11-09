$ErrorActionPreference = 'Stop'

# Deep-review class guard (2026-08-14): an authority-bearing field that is only computed or rendered
# is a typed comment, not a control. These cases inspect executable AST nodes in the production
# callers, so leaving the prose behind while deleting the consuming call cannot keep the suite green.
Describe 'authority controls have production consumers' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path

        function script:Get-ScriptAst([string]$RelativePath) {
            $tokens = $null; $errors = $null
            $path = Join-Path $script:RepoRoot $RelativePath
            $ast = [Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
            if (@($errors).Count -gt 0) { throw "parse-failed:$RelativePath" }
            return $ast
        }

        function script:Get-CommandAsts($Ast, [string]$Name) {
            return @($Ast.FindAll({
                        param($node)
                        $node -is [Management.Automation.Language.CommandAst] -and
                        [string]$node.GetCommandName() -ceq $Name
                    }, $true))
        }

        function script:Get-MemberAsts($Ast, [string]$Name) {
            return @($Ast.FindAll({
                        param($node)
                        $node -is [Management.Automation.Language.MemberExpressionAst] -and
                        [string]$node.Member.Value -ceq $Name
                    }, $true))
        }
    }

    It 'budget exhaustion is consumed before the launch grant and before campaign invocation' {
        # Feature 203 T008 step (iii) (DRIFT-052 fix 8, maintainer ruling 2026-11-09). This case used to require the
        # orchestrator to call Test-ReviewCampaignContinuationAuthorized, the per-round pause's continuation check, which
        # step (iii) removed; the budget is consumed by the counter's continuation_available instead. The property is
        # unchanged and asserted by ORDER, not presence: inside Invoke-ReviewCampaignCommand the continuation_available
        # check comes before Add-ReviewCampaignLaunchGrant and before Invoke-ReviewCampaignRun.
        #
        # The case's former other half, "before answer recording" (the review command checked the budget before recording
        # a pause answer), is class A: an exhausted budget must not refuse the answer that tops it up, because
        # `approved for allowance reset` has to land while the budget is spent (FR-007).
        $orchestrator = script:Get-ScriptAst 'scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1'
        $command = @($orchestrator.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Invoke-ReviewCampaignCommand'
                }, $true))
        $command.Count | Should -Be 1
        $budgetChecks = @(script:Get-MemberAsts $command[0] 'continuation_available')
        $budgetChecks.Count | Should -BeGreaterThan 0 -Because 'the launch consumes the budget counter'
        $grants = @(script:Get-CommandAsts $command[0] 'Add-ReviewCampaignLaunchGrant')
        $runs = @(script:Get-CommandAsts $command[0] 'Invoke-ReviewCampaignRun')
        $grants.Count | Should -BeGreaterThan 0
        $runs.Count | Should -BeGreaterThan 0
        $firstCheck = ($budgetChecks | ForEach-Object { $_.Extent.StartOffset } | Measure-Object -Minimum).Minimum
        foreach ($grant in $grants) { $firstCheck | Should -BeLessThan $grant.Extent.StartOffset -Because 'no launch grant is minted before the budget is checked' }
        foreach ($run in $runs) { $firstCheck | Should -BeLessThan $run.Extent.StartOffset -Because 'no reviewer is invoked before the budget is checked' }
    }

    It 'not-produced evidence is consumed by both live and resumed human surfaces' {
        $navigator = script:Get-ScriptAst 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1'
        (script:Get-MemberAsts $navigator 'result_produced').Count | Should -BeGreaterOrEqual 1
        $source = $navigator.Extent.Text
        ([regex]::Matches($source, "Get-ReviewAuthorityProperty\s+-Object\s+\`$Fact\s+-Name\s+'result_produced'")).Count | Should -BeGreaterThan 0
    }

    It 'agenda authority compares the captured structured digest with the exact proposed agenda' {
        $agenda = script:Get-ScriptAst 'extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1'
        $comparisons = @($agenda.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.BinaryExpressionAst] -and
                    $node.Operator -eq [Management.Automation.Language.TokenKind]::Cne -and
                    $node.Extent.Text -match 'receiptDigestProperty' -and $node.Extent.Text -match 'agendaDigest'
                }, $true))
        $comparisons.Count | Should -Be 1
        (script:Get-CommandAsts $agenda 'Get-SpecrewWorkshopAgendaChangedLenses').Count |
            Should -Be 1 -Because 'a changed selection must produce a concrete refusal, not a generic hash mismatch'
    }

    It 'partial signoff has only the captured human-authority production path' {
        $wiring = script:Get-ScriptAst 'scripts/internal/continuous-co-review/signoff-gate-wiring.ps1'
        (script:Get-CommandAsts $wiring 'Get-SpecrewReviewSignoffOverrideAuthorization').Count | Should -BeGreaterThan 0
        (script:Get-CommandAsts $wiring 'Write-SpecrewReviewSignoffOverrideRequest').Count | Should -BeGreaterThan 0

        foreach ($path in @(
                'scripts/internal/sync-boundary-state.ps1',
                'extensions/specrew-speckit/scripts/sync-boundary-state.ps1')) {
            $sync = script:Get-ScriptAst $path
            @($sync.ParamBlock.Parameters | Where-Object {
                    $_.Name.VariablePath.UserPath -match '^ReviewSignoffOverride'
                }).Count | Should -Be 0
        }
    }

    It 'authority-store read failures have a structural refusal consumer' {
        $orchestrator = script:Get-ScriptAst 'scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1'
        (script:Get-CommandAsts $orchestrator 'New-ReviewCampaignAuthorityStoreRefusal').Count | Should -BeGreaterOrEqual 3
    }

    It 'hook-output identity is written by the production dispatcher and consumed by workshop authority' {
        $dispatcher = script:Get-ScriptAst 'scripts/internal/specrew-hook-dispatcher.ps1'
        (script:Get-CommandAsts $dispatcher 'Write-DispatcherHookOutputAuthorityRecord').Count |
            Should -BeGreaterOrEqual 4 -Because 'both payload/reason and host envelope must be journaled'

        $workshop = script:Get-ScriptAst 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
        (script:Get-CommandAsts $workshop 'Test-SpecrewWorkshopResponseIsHookOutput').Count |
            Should -BeGreaterThan 0
    }

    It 'DERIVED: every declared authority control has a production consumer' {
        # A fixed list of five checks missed the sixth control because the list itself was the blind
        # spot. Production declares controls/consumers beside executable code; this test discovers
        # the set, asserts a floor, and requires set equality. Adding a control without its consumer
        # is therefore red without anyone remembering to edit this suite.
        $roots = @(
            (Join-Path $script:RepoRoot 'scripts/internal'),
            (Join-Path $script:RepoRoot 'scripts/specrew-review.ps1'),
            (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts')
        )
        $controls = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $consumers = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($root in $roots) {
            $files = if (Test-Path -LiteralPath $root -PathType Leaf) { @(Get-Item -LiteralPath $root) } else { @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.ps1') }
            foreach ($file in $files) {
                $source = Get-Content -LiteralPath $file.FullName -Raw
                foreach ($match in [regex]::Matches($source, 'SPECREW-AUTHORITY-CONTROL:\s*([a-z0-9-]+)')) { [void]$controls.Add($match.Groups[1].Value) }
                foreach ($match in [regex]::Matches($source, 'SPECREW-AUTHORITY-CONSUMER:\s*([a-z0-9-]+)')) { [void]$consumers.Add($match.Groups[1].Value) }
            }
        }

        $controls.Count | Should -BeGreaterOrEqual 6 -Because 'the current authority-control surface has six independently named controls'
        @($controls | Where-Object { -not $consumers.Contains($_) }) | Should -BeNullOrEmpty -Because 'a computed control without a consumer is a typed comment'
        @($consumers | Where-Object { -not $controls.Contains($_) }) | Should -BeNullOrEmpty -Because 'a consumer without a declared control has no auditable authority contract'
    }
}
