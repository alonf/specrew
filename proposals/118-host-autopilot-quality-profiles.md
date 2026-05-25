---
proposal: 118
title: Host Autopilot Quality Profiles — Document + Surface Host-Default Quality Tendencies at Selection Time
status: candidate
phase: phase-2
estimated-sp: 10-15
priority-tier: 1
type: methodology+tooling
discussion: tbd
depends-on:
  - 108 # specrew-init Refactor + Per-Host Crew-Runtime Abstraction (shipped F-044) — provides the per-host manifest schema this proposal extends
  - 104 # Multi-Host Onboarding + Selection Flow (shipped F-043) — provides the host-selection menu this proposal augments
composes-with:
  - 112 # Quality-Tier Routing Bundle (118 is the empirically-grounded refinement of 112's Pillar 1 — model-tier alone doesn't drive quality, host autopilot defaults do)
  - 113 # Empirical User-Acceptance Gate (118 surfaces which hosts need stronger evidence requirements)
  - 117 # Iteration-Level Lifecycle Enforcement (118 surfaces which hosts skip iteration ceremony — enforcement is the structural fix; 118 is the visibility layer)
blocks: []
audience: methodology
---

# Host Autopilot Quality Profiles — Document + Surface Host-Default Quality Tendencies at Selection Time

## Why

The 2026-05-25 dice-projects re-audit (with AntigravityStrong stronger-model data point added) **empirically refuted Proposal 112's central premise** that model strength drives lifecycle quality. AntigravityStrong (Antigravity with a stronger model) did NOT close the quality gap vs Claude or Codex — it actually **regressed on tests** (eliminated the `tests/` directory entirely; absorbed test code into `src/Tests.cpp` with bare asserts).

This invalidates the "route higher-quality features to stronger models" hypothesis. The actual quality lever is **host autopilot default choices**, which are invisible to the user at host-selection time but drive systematic differences in output:

| Host | Build system default | Test framework default | Compile-strictness default | Code-organization default |
|---|---|---|---|---|
| **Antigravity** | `.bat` (raw cl.exe) or `.ps1` (smart VS detection) | assert-based or absent | Minimal warnings | Flat `src/`, one file per class |
| **Claude** | CMake with strict `/W4 /WX /permissive-` | doctest (headless-first) | Maximal strictness | Layered (app/ core/ shaders/) |
| **Codex** | CMake with `/W4 /permissive-` | Assert-based, minimal | Strict | Layered (app/ core/ render/) |
| **Copilot** | CMake with `/W4 /permissive-` | Google Test (categorized) | Strict | Rich subsystems (physics/gameplay/camera/animation/scene/render/input/util) |

These defaults emerge from each host's autopilot — not from the user's spec, not from the model's reasoning, not from Specrew's coordinator prompts. They're embedded in the host's "what does a reasonable C++ project look like" priors.

The user has no way to see these defaults at host-selection time. The current selection menu (Proposal 104, shipped F-043) shows:

```text
1. Claude Code CLI
2. Codex
3. GitHub Copilot CLI
4. Antigravity
```

But the user can't see that picking Antigravity means "default to assert-based testing, .bat build, minimal scaffolding" — only discovers it after the feature runs to completion.

### The empirical evidence chain that produced this proposal

1. **2026-05-25 dice smoke test** — same prompt to 4 hosts; 5 quality dimensions audited; visible per-host quality disparities
2. **AntigravityStrong re-run** — stronger model added; expected to close gap; DID NOT close gap (regressed on tests)
3. **Conclusion**: model strength is necessary-but-insufficient; host autopilot defaults are the binding constraint
4. **Implication**: Proposal 112 Pillar 1's "Quality-Tier Routing" framing is wrong as a complete answer — needs to be paired with host-profile awareness OR replaced by host-profile-based recommendations

## What — Four Pillars

### Pillar 1: Host Autopilot Profile in Manifest

Extend `hosts/<kind>/host.psd1` schema (Proposal 108's surface) with an `AutopilotProfile` field:

```powershell
@{
    Kind          = 'antigravity'
    DisplayName   = 'Antigravity'
    # ... existing fields
    
    AutopilotProfile = @{
        BuildSystem        = @{ Default = 'platform-script'; Preferred = 'cmake-if-explicit' }
        TestFramework      = @{ Default = 'asserts'; SuggestExplicit = 'doctest-or-gtest' }
        CompileStrictness  = @{ Default = 'minimal'; SuggestExplicit = 'maximal' }
        CodeOrganization   = @{ Default = 'flat'; SuggestExplicit = 'layered-or-subsystem' }
        IterationCeremony  = @{ Default = 'optional-skip'; SuggestExplicit = 'enforce-via-117' }
        KnownStrengths     = @('rapid-prototyping', 'minimal-scaffold', 'fast-feedback')
        KnownGaps          = @('test-formality', 'compile-strictness', 'iteration-discipline')
    }
}
```

Per-host author records the empirically-observed defaults + suggested explicit overrides + known strengths/gaps. Updated when audit reveals new data.

### Pillar 2: Selection-Time Profile Disclosure

When the user runs `specrew start` (or `specrew host list`), the host-selection menu shows the profile:

```text
Select host for this session:

  1. Claude Code CLI                    [autopilot: strict CMake/doctest/layered]
  2. Codex                              [autopilot: CMake/asserts/minimal-scaffold]
  3. GitHub Copilot CLI                 [autopilot: CMake/gtest/rich-subsystems]
  4. Antigravity                        [autopilot: platform-script/asserts/flat]
                                        ⚠ Known gap: test formality. Use --enforce-tests if rigor required.

Choice [1-4]:
```

User sees the trade-off BEFORE committing to a host. If they're starting a feature that needs strict testing, they can see at-a-glance that Antigravity will need an explicit override.

### Pillar 3: Per-Feature Quality Overrides

When the user knows their feature needs override from a host's default, they declare it at `specrew start` time:

```powershell
specrew start --host antigravity --quality-overrides "test-framework=doctest,compile-strictness=maximal,iteration-ceremony=enforce" "feature prompt..."
```

Or, more ergonomically, via a feature-level quality profile:

```powershell
specrew start --host antigravity --quality-profile production "feature prompt..."
```

`production` is a named bundle of overrides defined per project in `.specrew/quality-profiles.yml`:

```yaml
quality_profiles:
  production:
    test_framework: doctest
    compile_strictness: maximal
    iteration_ceremony: enforce
    documentation_density: comprehensive
    acceptance_evidence: required  # composes with Proposal 113
  prototype:
    test_framework: asserts
    compile_strictness: minimal
    iteration_ceremony: optional
    documentation_density: minimal
    acceptance_evidence: deferred-by-default
```

The host's autopilot is signaled the override via the coordinator prompt. Whether autopilot honors it depends on the host (some hosts honor more reliably than others — that's another data point for the profile).

### Pillar 4: Profile-Refinement Telemetry

Each closed iteration's retro captures observed-vs-expected:

```markdown
## Host autopilot profile observations (auto-generated)

**Host**: antigravity
**Expected per profile**: test-framework=asserts (default), compile-strictness=minimal (default)
**Observed in this iteration**: test-framework=NONE-TESTS-REMOVED, compile-strictness=minimal
**Profile drift**: test-framework moved from "asserts" → "no tests at all" — autopilot regression possibly correlated with stronger model (gemini-2.5-pro vs default)
**Suggested profile update**: AntigravityStrong variant should be documented separately; default model = "asserts", strong model = "test-removal-risk"
```

These observations feed back into the manifest. Over time, the profile accuracy improves. After N closed iterations, the profile is a reliable predictor.

This composes with Proposal 057 (Roadmap Spine) — host-profile data could populate per-feature roadmap entries showing "implemented on Antigravity; profile: asserts/minimal; warnings: 0 (matches expected); test count: 0 (BELOW expected)".

## How — Implementation Surface + Effort

| Component | File | Effort |
|---|---|---|
| Extend host manifest schema with `AutopilotProfile` field | All 4 hosts' `host.psd1` + future Cursor 114 | 1 SP |
| Author empirical profiles based on dice-audit evidence | Per-host `host.psd1` content | 1-2 SP |
| Extend host-selection menu to surface profile | `scripts/internal/host-menu.ps1` (per F-043) | 1 SP |
| `--quality-overrides` + `--quality-profile` flag plumbing | `scripts/specrew-start.ps1` | 2 SP |
| `.specrew/quality-profiles.yml` schema + loader | `scripts/internal/quality-profiles.ps1` (new) | 1-2 SP |
| Coordinator-prompt injection of override signals | Per-host coordinator template translation | 1 SP |
| Profile-refinement telemetry (retro auto-generation hook) | `extensions/specrew-speckit/scripts/scaffold-retro.ps1` | 2 SP |
| Tests + golden profiles | `tests/host-autopilot-profiles.tests.ps1` (new) | 1-2 SP |
| Documentation — host autopilot profile catalog | `docs/host-profiles.md` (new) + `docs/user-guide.md` updates | 1 SP |

**Total estimate**: ~10-15 SP. Single iteration, single feature.

### Initial profile authoring (data from dice audit)

The dice re-audit produced enough evidence to populate v0 profiles for all 4 current hosts:

```yaml
# Initial profiles based on 2026-05-25 dice-projects re-audit

antigravity:
  build_system: platform-script (.bat or .ps1)
  test_framework: asserts (or absent — see AntigravityStrong regression)
  compile_strictness: minimal
  code_organization: flat-src
  iteration_ceremony: optional-skip
  known_strengths: [rapid-iteration, minimal-friction]
  known_gaps: [test-formality, compile-strictness, iteration-discipline]
  regression_risks: [test-removal-with-stronger-models]

claude:
  build_system: cmake
  test_framework: doctest
  compile_strictness: maximal (/W4 /WX /permissive-)
  code_organization: layered (app/ core/ shaders/)
  iteration_ceremony: respected
  known_strengths: [headless-first-testing, strict-compilation, layered-architecture]
  known_gaps: [iteration-state-md-population]
  regression_risks: []

codex:
  build_system: cmake
  test_framework: asserts (minimal)
  compile_strictness: strict (/W4 /permissive-)
  code_organization: layered (include/ + src/)
  iteration_ceremony: respected-minimally
  known_strengths: [code-density, efficient-scaffolding]
  known_gaps: [test-formality, iteration-completeness]
  regression_risks: [token-pressure-shortcuts]

copilot:
  build_system: cmake
  test_framework: googletest (categorized contract/integration/performance)
  compile_strictness: strict (/W4 /permissive-)
  code_organization: rich-subsystem (physics, gameplay, camera, animation, scene, render, input, util)
  iteration_ceremony: respected
  known_strengths: [test-organization, subsystem-discipline]
  known_gaps: [iteration-state-md-population]
  regression_risks: []
```

These are starting points; profile-refinement-telemetry (Pillar 4) updates them as more empirical data accumulates.

## Composition Notes

### With Proposal 112 (Quality-Tier Routing Bundle)

112's Pillar 1 says "route to stronger models for higher-quality work". 118 says "model-tier is necessary but not sufficient — host autopilot defaults are the binding constraint; profile + override is the actual lever". They're complementary:

- 112 Pillar 1 (post-refinement) → "select tier of model within the chosen host"
- 118 → "choose the host based on profile match for the feature; if mismatched, apply explicit overrides"

Recommendation: ship 118 first (visibility layer) — gather empirical evidence on which hosts honor overrides reliably — then refine 112 Pillar 1 with that data.

### With Proposal 117 (Iteration-Level Lifecycle Enforcement)

117 enforces populated state.md/review.md/retro.md universally. 118 surfaces WHICH hosts are likely to skip iteration ceremony (via `iteration_ceremony` profile field). They compose: 117 is the enforcement; 118 is the warning before the user picks a host known to need 117's enforcement.

### With Proposal 113 (Empirical User-Acceptance Gate)

113 mandates Acceptance Evidence in review.md. 118 surfaces hosts that historically don't populate evidence (via `acceptance_evidence` profile field in `quality-profiles.yml`). Together: 113 is the gate; 118 is the host-selection guidance that prevents stepping into a known-weak gate.

### With Proposal 108 (specrew-init Refactor + Per-Host Crew-Runtime Abstraction — shipped F-044)

108 established the host package contract. 118 extends the manifest with the AutopilotProfile field. Both are about per-host configuration; 108 is the structural foundation, 118 is the empirical observation layer.

### With Proposal 104 (Multi-Host Onboarding + Selection Flow — shipped F-043)

104 wrote the host-selection menu. 118 augments that menu with profile disclosure. Direct UI evolution.

## Open Questions

1. **Profile drift across model upgrades?** AntigravityStrong vs Antigravity showed that model upgrade can shift autopilot behavior (test removal). Should profiles be per-model within a host, not just per-host? Recommend: yes for hosts with significant model-tier variance (Antigravity has cheap/strong tiers; Claude is mostly Sonnet); document as `model_variants:` block in profile.

2. **How are profile updates governed?** When the empirical evidence shifts (a host's autopilot changes), who updates the profile? Recommend: profile-refinement-telemetry (Pillar 4) auto-suggests updates in retros; user accepts/rejects; profile committed to host.psd1 in a chore commit.

3. **What if a host's autopilot ignores override signals?** Some hosts may not honor `--quality-overrides` consistently. Recommend: profile records `override_honor_rate` (e.g., "antigravity: honors test-framework override 60% of time per N samples"); selection menu surfaces low honor rates as additional caveats.

4. **Should profile drive automatic host recommendation?** When user says `specrew start "implement payment processing"`, should Specrew auto-suggest "use Claude or Copilot — these have stronger compile-strictness profiles for security-sensitive code"? Recommend: NO for v1 — keep host selection explicit. Auto-recommendation is a Phase 3 enhancement once profiles are mature.

5. **Profile portability across projects?** Should `quality-profiles.yml` be project-local or user-global? Recommend: project-local (different projects have different needs — production app vs research prototype). Provide a user-global default file for convenience.

## Not in Scope

- Auto-routing to a different host mid-iteration (Proposal 069 / 024 territory)
- Cross-host iteration handoff (concurrent multi-host execution) — out of scope; per-iteration host stability assumed
- Model-tier routing WITHIN a host (Proposal 112 Pillar 1's refined scope after 118 ships)
- Cost/token budget per host (Proposal 112 Pillar 6, Proposal 068 / 070)
- Automated profile-update from telemetry without human review (manual approval required for now)

## Empirical Motivation Captured

- **2026-05-25 dice-projects re-audit** (5 projects: Antigravity, AntigravityStong, Claude, Codex, Copilot)
- **AntigravityStrong re-run** specifically refuted "model strength alone closes the quality gap" — the stronger model regressed on tests
- **Cross-host patterns** revealed each host has consistent autopilot defaults independent of model tier — Claude always strict-CMake/doctest; Copilot always rich-subsystem/gtest; Antigravity always platform-script/asserts; Codex always layered/asserts
- **Audit evidence**: see file:///C:/Temp/SpecrewProjectMultipleHost/ for all 5 projects; comparative report in agent audit summary committed during this session

## Status History

- **2026-05-25** — Drafted as direct response to dice-audit invalidation of Proposal 112 Pillar 1. Candidate status. Sequencing recommendation: ship 117 FIRST (universal enforcement closes the iteration-ceremony gap that 118 needs to surface meaningfully); then 118 (visibility + override layer); then refine 112 Pillar 1 with the empirical data from 117+118's deployment.
