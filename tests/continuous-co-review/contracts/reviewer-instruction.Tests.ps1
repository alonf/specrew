$ErrorActionPreference = 'Stop'

# Trace: T052, FR-017, SEC-007, IMPL-008, SC-013, TG-013.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T052 canonical reviewer instruction source' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:InstructionPath = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/code-review-agent.md'
        $script:FixturePath = Join-Path $script:RepoRoot 'tests/continuous-co-review/fixtures/contracts/reviewer-instruction.expected-markers.json'
        $script:Instruction = Get-Content -LiteralPath $script:InstructionPath -Raw
        $script:Fixture = Get-Content -LiteralPath $script:FixturePath -Raw | ConvertFrom-Json
    }

    It 'stores the canonical reviewer instruction at the Proposal 197 runtime path' {
        Test-Path -LiteralPath $script:InstructionPath -PathType Leaf | Should -Be $true
        $script:Instruction | Should -Match ([regex]::Escape($script:Fixture.canonical_path))
        $script:Instruction | Should -Match 'reviewer-instruction\.v1'
    }

    It 'contains every required reviewer-definition marker from the contract fixture' {
        foreach ($marker in @($script:Fixture.required_markers)) {
            $script:Instruction | Should -Match ([regex]::Escape($marker))
        }
    }

    It 'includes the Proposal 145 rubric phases required for design-conformance review' {
        foreach ($phase in @('Requirement conformance', 'Architecture and separation', 'Security and privacy', 'Verification confidence', 'Operations and observability', 'Review decision')) {
            $script:Instruction | Should -Match ([regex]::Escape($phase))
        }
    }

    It 'binds workshop, traceability, falsification, per-lens validation, policies, and rounds' {
        $script:Instruction | Should -Match 'workshop'
        $script:Instruction | Should -Match 'FR/SC/TG/SEC/INT/OBS/IMPL'
        $script:Instruction | Should -Match 'report-falsification'
        $script:Instruction | Should -Match 'architecture, component design, requirements/NFR, data-storage, security-compliance, integration/API, devops/operations, observability/resilience, and code-implementation'
        $script:Instruction | Should -Match 'Visibility Policy'
        $script:Instruction | Should -Match 'Do-Policy'
        $script:Instruction | Should -Match 'Round 1'
        $script:Instruction | Should -Match 'Round 2'
    }

    It 'forbids mutation and native mirror authority while requiring FindingsResult.v1 JSON' {
        $script:Instruction | Should -Match 'do not modify source, Git state, Specrew state, or workspace files'
        $script:Instruction | Should -Match 'native host-agent mirrors as authority'
        $script:Instruction | Should -Match 'Return one JSON object satisfying `FindingsResult.v1`'
        $script:Instruction | Should -Not -Match '(?i)token value|api key|password value|secret value'
    }
}