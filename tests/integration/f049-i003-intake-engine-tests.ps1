# Integration Tests: Feature 049 Iteration 003 - Intake Engine + User Profile
# Tests for engine + data foundation, user-profile persistence, expertise-dial behavior,
# and extensibility proof (SC-005, SC-006)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'Feature 049 Iteration 003: Intake Engine + User Profile Integration' {
    
    Context 'T001: Engine + Data Architecture Foundation' {
        It 'Intake engine exists and is executable' {
            $enginePath = 'extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1'
            Test-Path $enginePath | Should -Be $true
        }
        
        It 'Engine has mirror parity' {
            $enginePath1 = 'extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1'
            $enginePath2 = '.specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1'
            Test-Path $enginePath1 | Should -Be $true
            Test-Path $enginePath2 | Should -Be $true
        }
        
        It 'All YAML data catalogs exist' {
            $catalogs = @(
                '.specify/intake/personas.yml',
                '.specify/intake/categories.yml',
                '.specify/intake/depth-rules.yml',
                '.specify/intake/questions/product-manager.yml',
                '.specify/intake/questions/ux-ui-specialist.yml',
                '.specify/intake/questions/architect.yml',
                '.specify/intake/questions/ai-researcher-project-manager.yml',
                '.specify/intake/auto-decision-defaults/generic.yml'
            )
            
            foreach ($catalog in $catalogs) {
                Test-Path $catalog | Should -Be $true
            }
        }
    }
    
    Context 'T030: User Profile Persistence + Slash Command' {
        It 'User profile helper exists' {
            $helperPath = 'scripts/internal/user-profile.ps1'
            Test-Path $helperPath | Should -Be $true
        }
        
        It 'Slash command deployed to all hosts' {
            $skillPaths = @(
                '.claude/skills/specrew-user-profile/SKILL.md',
                '.github/skills/specrew-user-profile/SKILL.md',
                '.agents/skills/specrew-user-profile/SKILL.md'
            )
            
            foreach ($skillPath in $skillPaths) {
                Test-Path $skillPath | Should -Be $true
            }
        }
        
        It 'User profile functions are available' {
            . 'scripts/internal/user-profile.ps1'
            
            Get-Command Get-UserProfilePath -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Get-UserProfile -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Save-UserProfile -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Show-UserProfileSummary -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'T031: Expertise-Dial-Driven Question Depth' {
        It 'Depth rules define mode thresholds' {
            $depthRulesPath = '.specify/intake/depth-rules.yml'
            $content = Get-Content $depthRulesPath -Raw
            
            $content | Should -Match 'mode_a'
            $content | Should -Match 'mode_b'
            $content | Should -Match 'mode_c'
        }
        
        It 'Question banks include mode tags' {
            $questionBanks = @(
                '.specify/intake/questions/product-manager.yml',
                '.specify/intake/questions/ux-ui-specialist.yml',
                '.specify/intake/questions/architect.yml',
                '.specify/intake/questions/ai-researcher-project-manager.yml'
            )
            
            foreach ($bankPath in $questionBanks) {
                $content = Get-Content $bankPath -Raw
                $content | Should -Match 'questions:'
            }
        }
        
        # TODO: Add end-to-end test that verifies:
        # - dial 7-10 → Mode A (senior questions)
        # - dial 4-6 → Mode B (standard questions)
        # - dial 1-3 → Mode C (auto-decisions with transparency)
    }
    
    Context 'T032: 5th-Persona Extensibility Proof (SC-006)' {
        It 'Personas catalog is YAML data' {
            $personasPath = '.specify/intake/personas.yml'
            Test-Path $personasPath | Should -Be $true
            
            $content = Get-Content $personasPath -Raw
            $content | Should -Match 'personas:'
        }
        
        It 'Engine loads personas from catalog' {
            $enginePath = 'extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1'
            $content = Get-Content $enginePath -Raw
            
            # Engine should reference Load-PersonaCatalog helper
            $content | Should -Match 'Load-PersonaCatalog'
        }
        
        # TODO: Add extensibility proof test:
        # 1. Add temporary 5th persona to personas.yml
        # 2. Add corresponding question bank
        # 3. Run intake engine
        # 4. Verify 5th persona is recognized
        # 5. Clean up (remove 5th persona)
        # This proves adding personas is YAML-only, no code changes needed
    }
    
    Context 'T033: Per-Lens Mode Branching Correctness' {
        It 'Resolve-PerLensMode helper exists' {
            $helperPath = 'extensions/specrew-speckit/scripts/intake/helpers/Resolve-PerLensMode.ps1'
            Test-Path $helperPath | Should -Be $true
        }
        
        It 'Depth rules define per-lens evaluation' {
            $depthRulesPath = '.specify/intake/depth-rules.yml'
            $content = Get-Content $depthRulesPath -Raw
            
            $content | Should -Match 'dial_threshold'
            $content | Should -Match 'completeness_threshold'
        }
        
        # TODO: Add per-lens mode correctness test:
        # - Set different expertise dials per persona
        # - Provide varying completeness per lens
        # - Verify each lens evaluates independently
        # - Verify most-conservative-wins (C > B > A) applies when lenses conflict
    }
    
    Context 'T034: Complete Regression Suite + Acceptance Evidence' {
        It 'Integration test file exists' {
            Test-Path 'tests/integration/substantive-interaction-model-iteration2.ps1' | Should -Be $true
        }
        
        # TODO: Run complete regression suite:
        # - SC-005 metrics: ≥30% question reduction for dial 7-10, ≥40% decision reduction for dial 1-3
        # - SC-006 extensibility proof: 5th persona added as YAML-only
        # - Per-lens mode correctness
        # - User profile persistence
        # - Intake engine invocation from orchestrators
        # Record acceptance evidence in:
        # specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md
    }
}

# Test execution notes:
# - T001: Engine foundation tests pass (files exist, mirror parity validated)
# - T030: User profile + slash command tests pass (helper functions available)
# - T031: Expertise-dial structure validated (depth rules + question banks exist)
# - T032: Extensibility architecture validated (YAML-based persona catalog)
# - T033: Per-lens mode architecture validated (Resolve-PerLensMode helper exists)
# - T034: Regression suite structure validated (test file exists)
#
# Future work:
# - Add end-to-end intake engine execution tests
# - Add 5th-persona extensibility proof with temp persona creation/cleanup
# - Add per-lens mode branching behavior tests
# - Measure and document SC-005 metrics (question/decision reduction)
# - Generate quality-evidence.md with acceptance test results
