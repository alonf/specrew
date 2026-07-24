$ErrorActionPreference = 'Stop'

# F-198 Iteration 005 / T036 (FR-051): the Codex malformed-output / fail-open REGRESSION.
#
# Observed contract (iterations/005/evidence/codex-stop-contract-characterization.md, Scenario E): Codex SILENTLY
# fails OPEN on malformed Stop-hook stdout - non-JSON is ignored with no parse error, no warning, exit 0; the gate
# is bypassed. Copilot's characterization shows the same (truncated/garbage block JSON -> turn ends, no block).
# So a malformed emission from Specrew's dispatcher = a SILENT governance bypass. Specrew must therefore NEVER
# emit malformed gate output. This regression pins that: the dispatcher's Stop-gate emitter produces well-formed
# JSON with the required keys, and the fail-open guard correctly rejects the malformed shapes.

Describe 'F-198 T036 FR-051 Codex Stop-gate fail-open regression' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/hook-health-receipt.ps1')

        $script:DispatcherPath = Join-Path $script:RepoRoot 'scripts/internal/specrew-hook-dispatcher.ps1'
        $script:ConformanceProviderPath = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'
        $script:CodexManifestPath = Join-Path $script:RepoRoot 'hosts/codex/host.psd1'

        # Extract the REAL dispatcher gate emitter (Write-StopBlockOutput) via the AST, without executing the
        # dispatcher's top-level main. This tests the actual production emission code, not a copy.
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:DispatcherPath, [ref]$tokens, [ref]$errors)
        $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Write-StopBlockOutput' }, $true) | Select-Object -First 1
        if ($null -eq $fn) { throw "Write-StopBlockOutput not found in the dispatcher - the gate emitter moved/renamed (this regression must be updated)." }
        . ([scriptblock]::Create($fn.Extent.Text))

        $script:DispatcherText = Get-Content -LiteralPath $script:DispatcherPath -Raw
    }

    Context "the dispatcher's Stop-gate emitter produces well-formed JSON with the required keys" {
        It 'emits well-formed {"decision":"block","reason":...} for decision-block (the codex/claude/copilot gate)' {
            $emit = Write-StopBlockOutput -Shape 'decision-block' -Reason 'RENDER THE RE-ENTRY PACKET'
            { $emit | ConvertFrom-Json } | Should -Not -Throw
            $parsed = $emit | ConvertFrom-Json
            $parsed.decision | Should -Be 'block'
            $parsed.reason | Should -Be 'RENDER THE RE-ENTRY PACKET'
        }

        It 'the emitted block validates as a well-formed BLOCK via the fail-open guard' {
            $emit = Write-StopBlockOutput -Shape 'decision-block' -Reason 'DIRECTIVE'
            $verdict = Test-SpecrewHookGateEmissionWellFormed -Json $emit
            $verdict.WellFormed | Should -BeTrue
            $verdict.IsBlock | Should -BeTrue
            $verdict.Decision | Should -Be 'block'
        }

        It 'emits well-formed continuation/followup envelopes for the other blocking shapes' {
            $cont = Write-StopBlockOutput -Shape 'decision-continue' -Reason 'R'
            ($cont | ConvertFrom-Json).decision | Should -Be 'continue'
            (Test-SpecrewHookGateEmissionWellFormed -Json $cont).IsBlock | Should -BeTrue

            $followup = Write-StopBlockOutput -Shape 'followup-message' -Reason 'R'
            ($followup | ConvertFrom-Json).followup_message | Should -Be 'R'
            (Test-SpecrewHookGateEmissionWellFormed -Json $followup).IsBlock | Should -BeTrue
        }

        It 'the emitted JSON is single-line compressed (a host reads one stdout line as the gate)' {
            $emit = Write-StopBlockOutput -Shape 'decision-block' -Reason 'multi word directive'
            $emit.Trim() | Should -Not -Match "`n"
        }
    }

    Context 'the fail-open guard rejects the malformed shapes that would silently bypass the gate (T036)' {
        It 'classifies non-JSON garbage stdout as NOT well-formed (the Codex Scenario-E fail-open trap)' {
            $verdict = Test-SpecrewHookGateEmissionWellFormed -Json 'THIS_IS_NOT_JSON_... {{{ <<<'
            $verdict.WellFormed | Should -BeFalse
            $verdict.IsBlock | Should -BeFalse
        }

        It 'classifies truncated/invalid block JSON as NOT well-formed' {
            (Test-SpecrewHookGateEmissionWellFormed -Json '{"decision":"block"').WellFormed | Should -BeFalse
        }

        It 'classifies a block envelope with no reason as NOT a directive-bearing block' {
            $verdict = Test-SpecrewHookGateEmissionWellFormed -Json '{"decision":"block"}'
            $verdict.IsBlock | Should -BeFalse
        }

        It 'classifies the Codex-manual {"continue":false,...} no-op shape as NOT a block (it would NOT gate)' {
            # Evidence Scenario D: this shape does NOT force-continue on Codex 0.144.1. If Specrew emitted it
            # intending to block, the block would be silently lost - so it must classify as non-blocking.
            $verdict = Test-SpecrewHookGateEmissionWellFormed -Json '{"continue":false,"stopReason":"X","systemMessage":"Y"}'
            $verdict.IsBlock | Should -BeFalse
        }

        It 'treats an empty object {} as a well-formed ALLOW (non-block Stop), not a block' {
            $verdict = Test-SpecrewHookGateEmissionWellFormed -Json '{}'
            $verdict.WellFormed | Should -BeTrue
            $verdict.IsBlock | Should -BeFalse
        }

        It 'treats empty / whitespace stdout as NOT well-formed' {
            (Test-SpecrewHookGateEmissionWellFormed -Json '').WellFormed | Should -BeFalse
            (Test-SpecrewHookGateEmissionWellFormed -Json '   ').WellFormed | Should -BeFalse
        }
    }

    Context 'source: the Stop-gate path is wired to emit well-formed JSON, never a raw reason' {
        It 'the dispatcher routes the stop-block short-circuit through Write-StopBlockOutput (not a raw Write-Output)' {
            $script:DispatcherText | Should -Match 'Write-StopBlockOutput\s+-Shape\s+\$blockShape\s+-Reason'
        }

        It "the dispatcher's decision-block branch emits via ConvertTo-Json (well-formed by construction)" {
            $script:DispatcherText | Should -Match "decision\s*=\s*'block'"
            # same-line assertion: the 'decision-block' switch arm pipes through ConvertTo-Json (the inner hashtable
            # brace sits between them, so match across it on the one line rather than excluding braces).
            $script:DispatcherText | Should -Match "'decision-block'.*ConvertTo-Json"
        }

        It 'the conformance provider emits the SPECREW-STOP-BLOCK sentinel the dispatcher converts to a gate' {
            (Test-Path -LiteralPath $script:ConformanceProviderPath) | Should -BeTrue
            $provider = Get-Content -LiteralPath $script:ConformanceProviderPath -Raw
            $provider | Should -Match '<<<SPECREW-STOP-BLOCK>>>'
        }

        It 'the Codex host manifest declares StopBlockShape = decision-block (the FR-051-observed-correct shape)' {
            $manifest = Import-PowerShellDataFile -LiteralPath $script:CodexManifestPath
            $manifest.RefocusHookBindings.DispatcherRuntime.StopBlockShape | Should -Be 'decision-block'
        }
    }
}
