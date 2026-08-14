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

    It 'budget exhaustion is consumed before both answer recording and campaign invocation' {
        $cli = script:Get-ScriptAst 'scripts/specrew-review.ps1'
        (script:Get-MemberAsts $cli 'budget_exhausted').Count | Should -BeGreaterThan 0

        $orchestrator = script:Get-ScriptAst 'scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1'
        $calls = script:Get-CommandAsts $orchestrator 'Test-ReviewCampaignContinuationAuthorized'
        $calls.Count | Should -BeGreaterThan 0
        ($calls.Extent.Text -join "`n") | Should -Match '-RoundsUsed'
        ($calls.Extent.Text -join "`n") | Should -Match '-BudgetTotal'
    }

    It 'not-produced evidence is consumed by both live and resumed human surfaces' {
        $navigator = script:Get-ScriptAst 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1'
        (script:Get-MemberAsts $navigator 'result_produced').Count | Should -BeGreaterOrEqual 1
        $source = $navigator.Extent.Text
        ([regex]::Matches($source, "Get-ReviewAuthorityProperty\s+-Object\s+\`$Fact\s+-Name\s+'result_produced'")).Count | Should -BeGreaterThan 0
    }

    It 'agenda authority compares the captured question hash with the exact canonical agenda' {
        $agenda = script:Get-ScriptAst 'extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1'
        $comparisons = @($agenda.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.BinaryExpressionAst] -and
                    $node.Operator -eq [Management.Automation.Language.TokenKind]::Cne -and
                    $node.Extent.Text -match 'question_hash' -and $node.Extent.Text -match 'expectedQuestionHash'
                }, $true))
        $comparisons.Count | Should -Be 1
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
}
