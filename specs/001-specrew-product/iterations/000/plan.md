# Iteration Plan: 000

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 20.5/20 story_points
**Started**: 2026-04-18
**Completed**: 2026-04-18

## Summary

Iteration 0 establishes the repository structure, scaffolds the Spec Kit extension with Squad-native template sources, performs platform validation, and runs compatibility spikes to confirm the upstream platforms support Specrew's architectural requirements. This iteration is **precondition-critical**: no downstream work (Iterations 1+) can proceed until Foundation is complete and validated.

**Target FRs**: FR-001 (Spec Kit extension + Squad-native surfaces), FR-013 (extension-only integration)  
**Target User Stories**: US-1 (Bootstrap), US-7 (Coexistence)

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-001 | Spec Kit extension + Squad-native configuration | ✅ Monorepo scaffold + extension skeleton + Squad template sources | Implementer | Use official Spec Kit template + Squad-native deployment structure |
| FR-013 | Integrate via documented extension surfaces only | ✅ Validation spike | Planner | Audit which hook types fire; verify Squad-native surfaces; audit Hook Pipeline surface |
| US-1 | Bootstrap Specrew in a new project | ⏳ Deferred to Iter 1 | — | Depends on FR-002; platform validation must complete first |
| US-7 | Coexistence of multiple extensions | ✅ Platform validation (Spike 5) | Implementer | Spikes 1–5, 8–11 validate extension coexistence |

---

## Acceptance Criteria (Iteration-Level Gate)

1. **Monorepo scaffold complete**: `.github/`, `extensions/`, `tests/`, `evaluation/`, `docs/` created per plan.md § 6 layout  
2. **Spec Kit extension skeleton exists**: `specrew-speckit/` with hooks/, templates/, scripts/, squad-templates/ (no commands/)  
3. **Squad template sources exist**: `specrew-speckit/squad-templates/` with skills/, ceremonies/, directives/ Markdown source files  
4. **Compatibility spikes complete**: Spikes 1–5, 8–11 documented and pass/fail recorded; Spikes 6–7 deferred to Iter 1 async (GitHub Projects API, local dev cycle) — see Risk Mitigation  
5. **CI pipeline functional**: GitHub Actions lint + test runner configured  
6. **GitHub Project board created**: V2 board using Squad's default layout  
7. **No integration blockers identified**: Spec Kit extension loads without errors; Squad-native surfaces validated; no critical platform gaps discovered (for spikes in scope)

**Review gate (Iteration 0 acceptance):** Worf verifies all artifacts exist and spikes are complete. Alon signs off on platform readiness before Iteration 1 planning begins.

---

## Governance Consistency Check

Validation that this plan respects Specrew's own governance model and contract terms.

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace to FR-001 or FR-013. Enabling work for Iteration 1 clearly marked as deferred. No scope exists without a spec reference. |
| **Traceability** | ✅ PASS | Traceability Matrix (below) maps each task to enabling requirements or infrastructure. Supporting tasks explicitly call out which FRs they enable. |
| **Ownership** | ✅ PASS | All tasks assigned to role names (Implementer, Planner). |
| **Capacity** | ✅ PASS | 20.5 pts committed (0.5 pt overcommit approved for precondition-critical Foundation iteration). Deferred Spikes 6–7 to Iteration 1 async. |
| **Artifact Consistency** | ✅ PASS | Task table matches traceability matrix. Capacity math verified. Stale references removed. |
| **Extension Surfaces** | ✅ COMPLETE | Spikes 1–5, 8–11 all PASS; documented surfaces validated. Platform readiness confirmed. |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-001 | Initialize monorepo layout | FR-001 | US-1 | 2 | Implementer | done | La Forge | 2 | PASS |
| T-002 | Configure Git | FR-001 | US-1 | 1 | Implementer | done | La Forge | 1 | PASS |
| T-003 | Clone Spec Kit extension template | FR-001 | US-1 | 1 | Implementer | done | La Forge | 1 | PASS |
| T-004 | Scaffold Spec Kit directories | FR-001 | US-1 | 1 | Implementer | done | La Forge | 1 | PASS |
| T-005 | Create extension config.yml stub | FR-013 | US-7 | 1 | Planner | done | Data | 1 | PASS |
| T-006 | Create template stubs | FR-001 | US-1 | 1 | Planner | done | Data | 1 | PASS |
| T-007 | Create script stubs | FR-001 | US-1 | 0.5 | Implementer | done | La Forge | 0.5 | PASS |
| T-008 | Create Squad template source structure | FR-001 | US-7 | 1 | Implementer | done | La Forge | 1 | PASS |
| T-009 | Create skill template stubs | FR-001 | US-7 | 0.5 | Planner | done | Data | 0.5 | PASS |
| T-010 | Create ceremony template stubs | FR-001 | US-7 | 1 | Planner | done | Data | 1 | PASS |
| T-011 | Create directive template stubs | FR-001 | US-7 | 0.5 | Planner | done | Data | 0.5 | PASS |
| T-012 | Document Squad-native integration | FR-001 | US-7 | 0.5 | Implementer | done | La Forge | 0.5 | PASS |
| T-013 | Spike 1: Spec Kit install/update >= 0.7.3 | FR-013 | US-7 | 1 | Implementer | done | La Forge | 1 | PASS |
| T-014 | Spike 2: Squad install/update >= 0.9.1 | FR-013 | US-7 | 1 | Implementer | done | La Forge | 1 | PASS |
| T-015 | Spike 3: Spec Kit hook availability audit | FR-013 | US-7 | 1 | Planner | done | Data | 1 | PASS |
| T-016 | Spike 4: Squad HookPipeline surface audit | FR-013 | US-7 | 1 | Planner | done | Data | 1 | PASS |
| T-017 | Spike 5: Squad native surface validation | FR-013 | US-7 | 1 | Implementer | done | La Forge | 1 | PASS - Architecture clarified |
| T-018 | Spike 8: Squad non-interactive init | FR-013 | US-7 | 1 | Implementer | done | La Forge | 1 | PASS |
| T-019 | Spike 9: Spec Kit extension install mechanism | FR-013 | US-7 | 0.5 | Planner | done | Data | 0.5 | PASS |
| T-020 | Spike 10: Squad native deployment validation | FR-013 | US-7 | 0.5 | Implementer | done | La Forge | 0.5 | PASS - Confirmed no plugin marketplace needed |
| T-021 | Spike 11: Spec Kit prompt file placement | FR-013 | US-7 | 0.5 | Planner | done | Data | 0.5 | PASS |
| T-022 | Set up CI pipeline (GitHub Actions) | FR-001 | US-1 | 1 | Implementer | done | La Forge | 1 | PASS |
| T-023 | Create GitHub Project board (V2) | FR-001 | US-1 | 1 | Implementer | done | La Forge | 1 | PASS |

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

---

## Notes

### Task Descriptions

**Phase 1: Repository Structure**

- **T-001**: Create `.github/`, `extensions/`, `tests/`, `evaluation/`, `docs/` directories. Allocate `.github/ISSUE_TEMPLATE/`, `.github/workflows/` stubs.
- **T-002**: Initialize repo, `.gitignore`, baseline README.md, CODEOWNERS.

**Phase 2: Spec Kit Extension Skeleton**

- **T-003**: Copy official Spec Kit extension starter template into `extensions/specrew-speckit/`. Validate source.
- **T-004**: Create `hooks/`, `templates/`, `scripts/` (per spec.md clarification: no `commands/` in Iteration 0).
- **T-005**: Minimal Specrew config entry in `specrew-speckit/config.yml` (version pins, feature flags).
- **T-006**: Markdown stubs for downstream-constitution.md, iteration-config.yml, role-assignments.yml (skeleton only; implementation deferred to Iteration 1).
- **T-007**: Placeholder PowerShell scripts: scaffold-governance.ps1, validate-versions.ps1, brownfield-merge.ps1, collision-detect.ps1, drift-diff.ps1 (stubs with comments, no implementation).

**Phase 3: Squad Template Source Structure**

- **T-008**: Create `extensions/specrew-speckit/squad-templates/` with `skills/`, `ceremonies/`, `directives/` subdirectories per Squad's native deployment structure.
- **T-009**: Markdown templates for: drift-check.md, capacity-planning.md, traceability-check.md, iteration-resume.md (SKILL.md format + prompt skeletons; no implementation).
- **T-010**: Markdown templates for: planning.md, review-demo.md (ceremony structure + input/output schema; no implementation).
- **T-011**: Markdown templates for: spec-authority.md, traceability.md, drift-reporting.md (directive content; no implementation).
- **T-012**: Documentation explaining Squad-native integration architecture, deployment locations, and rationale (based on spike findings).

**Phase 4: Platform Validation & Compatibility Spikes**

- **T-013**: Verify Spec Kit install/update mechanics; document procedure for downstream users. Outcome: documented install command or troubleshooting guide.
- **T-014**: Verify Squad install/update mechanics; document procedure. Outcome: documented install command or troubleshooting guide.
- **T-015**: Which before_*/after_* hooks exist and fire? Document available hooks per lifecycle phase.
- **T-016**: Which Squad hooks are available? PreToolUseHook? PostToolUseHook? Document availability and shape. **Contingency**: If post-task hook unavailable, document fallback (batch drift check in Review ceremony).
- **T-017**: Verify Squad-native surface structure: skills in `.copilot/skills/`, ceremonies in `.squad/ceremonies.md`, directives in agent charters. Outcome: Squad discovers and can invoke Specrew skills without errors.
- **T-018**: Does Squad support `squad init --non-interactive` or equivalent? If not, document `.squad/` file layout for direct creation. **Result**: Idempotent by default, no special flags needed.
- **T-019**: Does `specify extension add` exist in 0.7.3? If yes, verify it. If no, document file-copy + extensions.yml registration. **Contingency**: If unavailable, Iteration 1 `specrew init` script must handle file-copy path.
- **T-020**: Validate Squad-native deployment: copy skills to `.copilot/skills/specrew-*/`, append to `.squad/ceremonies.md`, merge into `.squad/team.md`. **Result**: No marketplace plugin system needed for bundled distribution.
- **T-021**: Confirm: do prompt files go in `.github/prompts/` or `.specify/templates/commands/`? Document canonical location.

**Phase 5: Testing Infrastructure**

- **T-022**: Create `.github/workflows/ci.yml`: markdownlint, PSScriptAnalyzer, test runner. Lint on every PR; tests on push.
- **T-023**: Create GitHub Project board (V2) using Squad's documented default layout. Link to repo; auto-link issues.

### Effort Summary

| Phase | Effort |
|-------|--------|
| Phase 1: Repository Structure | 3 pts |
| Phase 2: Spec Kit Extension Skeleton | 4.5 pts |
| Phase 3: Squad Template Source Structure | 3.5 pts |
| Phase 4: Platform Validation & Compatibility Spikes | 7.5 pts |
| Phase 5: Testing Infrastructure | 2 pts |
| **Total** | **20.5 pts** |

**Iteration Capacity**: 20 pts (default per data-model.md)  
**Committed**: 20.5 pts (0.5 pt overcommit) — Spec Steward sign-off: Foundation iteration is precondition-critical; validated against task table and traceability matrix.  
**Deferred to Iteration 1 async**: Spikes 6–7 (GitHub Projects API, local dev cycle) — 1 pt combined.

### Known Drift & Contingencies

#### ✅ Resolved

- **Spec Kit `commands/` folder**: Per spec.md § Clarifications (2026-04-17): `commands/` deferred to post-MVP. Specrew v1 defines no Spec Kit extension commands. Iteration 0 skeleton omits `commands/`; task T-004 documents why. ✅ Incorporated into T-004.
- **Monorepo vs. separate repos**: Spec confirms monorepo with `extensions/` subdirectories. ✅ Incorporated into T-001.

#### 🔍 Contingent on Spike Results

1. **Post-task drift hook shape** (T-016): If Squad HookPipeline does not provide PostToolUseHook, drift detection falls back to batch per-iteration skill invocation within Review ceremony (per spec.md § Clarifications). **Impact on Iter 1**: FR-008 implementation uses documented extension surfaces only (skills + ceremonies).
2. **Spec Kit extension install command** (T-019): If `specify extension add` does not exist in 0.7.3, file-copy + manual registration required. **Impact on Iter 1**: FR-002 `specrew init` script must handle both paths.

**Mitigation**: Spike results drive tracked changes to Iteration 1 plan if needed.

---

## Traceability Matrix (Iteration 0 → Spec Requirements)

| FR | US | Tasks | Effort | Scope | Enabling Support |
|----|----|----|--------|---------|-------|
| FR-001 | US-1 | T-001, T-002, T-003, T-004, T-008, T-022, T-023 | 8 pts | Monorepo scaffold + extension skeletons + CI | Repository structure, extension discovery, GitHub Project integration enable Iteration 1 bootstrap implementation. |
| FR-013 | US-7 | T-005, T-013, T-014, T-015, T-016, T-017, T-018, T-019, T-020, T-021 | 8.5 pts | Spikes 1–5, 8–11 (Core Platform Validation) | Audit hook availability and extension install mechanics. Confirm documented extension surfaces support Specrew architecture. Gate platform readiness before Iteration 1. |
| FR-001 | US-1 | T-006, T-007, T-009, T-010, T-011, T-012 | 4 pts | *Extension skeleton scaffolding* | Template and directive template sources establish Squad-native integration foundations; skills/ceremonies provide ceremony structure scaffold for Iteration 1 implementation of FR-002 (specrew init), FR-003–FR-011, FR-018 (governance artifacts, skills, drift detection). |

---

## Execution Sequence

1. **T-001–T-002** (Repo setup) — Phase 1 foundation  
2. **T-003–T-007** (Spec Kit skeleton) — Phase 2 (can parallelize with Phase 3)  
3. **T-008–T-012** (Squad skeleton) — Phase 3 (can parallelize with Phase 2)  
4. **T-013–T-021** (Spikes + CI) — Phase 4–5 (parallel spike work where independent, then serial CI setup)  

**Effort scale**: All tasks estimated in story points. No fixed wall-clock day assumptions. AI crew effort is not calendrical; actual elapsed time depends on task complexity, model latency, and verification feedback loops.

---
