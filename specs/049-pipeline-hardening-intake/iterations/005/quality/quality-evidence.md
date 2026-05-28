# Quality Evidence — Feature 049 Iteration 005

**Feature**: `049-pipeline-hardening-intake`  
**Iteration**: `005` (Proposal 141 — Crew Interaction Profile / Persona Lens Separation)  
**Evidence recorded**: `2026-05-28`  
**Tree Under Review**: `bd5ebcbca781a859df789588567c37406e45281f`

> Scaffold note: `scaffold-iteration-artifacts.ps1` crashed under StrictMode generating this file
> (anomaly A-001 in `../drift-log.md`); it was hand-authored to the canonical evidence-envelope
> shape.

## Commands Run

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\f049-i003-intake-engine-tests.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\049-pipeline-hardening-intake\iterations\005 -NoCacheRead
```

## Gate Matrix

| Gate | Requirement | Evidence Source | Status | Exception |
| --- | --- | --- | --- | --- |
| Crew Interaction Profile audit | FR-032, FR-034 | integration test + surface audit | addressed | — |
| Profile-vs-lens separation | FR-035 | integration test + surface audit | addressed | — |
| Soft-vs-hard boundary | FR-036, FR-040 | session-context + specify guidance audit | addressed | — |
| Stable-key compatibility | FR-033 | integration test (persisted YAML keys + persona IDs) | addressed | — |
| Legacy profile proof | FR-037 | legacy fixture load test | addressed | — |
| Loader/path-rule audit | FR-039 | shared-instruction surface audit | addressed | — |
| Multi-developer safety | FR-041, SC-008 | paired-developer fixture test | addressed | — |
| Session-context soft guidance | FR-038 | `New-CrewInteractionProfileSessionContext` test | addressed | — |
| Mirror parity | TG-018 | SHA256 parity check on shipped ↔ `.specify` intake surfaces | addressed | — |
| Reviewer guidance consistency | FR-036 | reviewer/operator guidance audit | addressed | — |

## Results

| Check | Outcome | Evidence |
| --- | --- | --- |
| Crew Interaction Profile labels (FR-032/FR-034) | PASS | `Get-CrewInteractionProfileAreas` maps the four decision-area labels (Product Strategy, UX/UI Design, Software Architecture, AI Delivery Planning) to the stable expertise keys; `Show-UserProfileSummary` renders all four under a Crew Interaction Profile heading and drops the old "Expertise Profile:" job-title heading. |
| Profile-vs-lens separation (FR-035) | PASS | Summary copy + `Get-CrewInteractionProfileLabel` distinguish the user's profile from Specrew's internal persona lenses; reviewer charters carry the capability-vs-lens enforcement block. |
| Stable-key compatibility (FR-033) | PASS | Persisted YAML still emits `software_architecture` + `ai_research_project_management`; `Get-CrewInteractionProfileLabel -PersonaId ai-researcher-project-manager` and `-ExpertiseKey ai_research_project_management` both resolve to "AI Delivery Planning". No rename/migration. |
| Legacy profile proof (FR-037 / scenario 10) | PASS | `legacy-expertise.yml` (expertise layout) and `legacy-dials.yml` (older expertise_dials layout) both load without migration, preserve routing/depth (architect=9 / 8), map null→auto, and render the updated AI Delivery Planning label; the engine drives all four lenses on the legacy profile. |
| Session-context soft guidance (FR-038/FR-040) | PASS | `New-CrewInteractionProfileSessionContext` returns `shared_project_truth=false`, `scope=current-user-runtime-guidance`, application = "soft … hard-applied only in /speckit.specify", decision areas keyed by display label, expertise_dials keyed by stable persona IDs. |
| Multi-developer safety (FR-041/SC-008) | PASS | `dev-a.yml` (architect 9) and `dev-b.yml` (architect 2) resolve independently from their own local files; divergent profiles coexist with no shared-repository profile values. |
| Loader/path-rule audit (FR-039/SC-008) | PASS | README.md + docs/user-guide.md describe the Crew Interaction Profile and point to the `user-profile.yml` loader/path rule rather than hard-coded dial values. |
| Mirror parity (TG-018) | PASS | `Invoke-SpecifyIntake.ps1` shipped ↔ `.specify` copies are SHA256-equal (engine left unchanged — its `persona_name` use is internal state only); skill SKILL.md byte-identical across `.github`/`.claude`/`.agents`. |
| Reviewer guidance consistency (FR-036) | PASS | All four reviewer surfaces (`.specrew/team`, `.agents`, shipped + `.specify` charters) carry the Crew Interaction Profile review-focus block. |
| Scoped governance validation | PASS with non-blocking warnings | `PASS specs\049-pipeline-hardening-intake\iterations\005`; warnings limited to pre-existing README/extension version drift (0.27.5→0.27.6, a Rule 15 feature-closeout concern) and the long-standing F-048 dashboard gap. |
| Runtime scripts parse | PASS | `scripts/internal/user-profile.ps1` and `scripts/specrew-start.ps1` parse with no errors (`Parser::ParseFile`). |

## Integration Test Output

```text
PASS: Mirror parity verified for intake engine runtime surfaces
PASS: Engine foundation catalogs and stack detection load without ConvertFrom-Yaml
PASS: User profile persistence stores FR-024 numeric-or-null schema while preserving summary guidance
PASS: Persisted auto-decision path works through both extension and .specify intake engines
PASS: Intake engine executes end to end with reduced senior-question counts
PASS: Per-lens mode rules reduce senior question count by 62.5 percent
PASS: Low-expertise path surfaces auto-decisions for 100 percent of decision slots
PASS: Senior/high-completeness Mode A rate of 100 percent (4/4 modeled lenses) exceeds 70 percent threshold (SC-005 third clause)
PASS: Fifth-persona extensibility proof succeeded with YAML-only additions
PASS: Slash-command deployment verified across active host roots
PASS: Crew Interaction Profile labels + legacy compatibility verified (FR-032..FR-037)
PASS: Session-context soft guidance + paired-developer safety verified (FR-038, FR-040, FR-041, SC-008)
PASS: Shared-instruction loader/path-rule audit verified (FR-039, SC-008)
PASS: Feature 049 Iteration 003 intake engine integration coverage
```

## Validator Notes

- `README.md` does not yet advertise version `0.27.6`; `extensions/specrew-speckit/extension.yml` and
  `.specify/extensions/specrew-speckit/extension.yml` still declare `0.27.5`. These are Rule 15
  (feature-closeout version management) concerns, not implementation-slice scope.
- Closed iteration `048-beta-before-stable-sdlc/001` is still missing `dashboard.md` (long-standing).
- The repo-wide capacity-drift FAILs from the never-reverted `20→25` bump in `.specrew/iteration-config.yml`
  are out of scope for this slice and tracked for the F-049 feature-closeout cleanup checklist.

These warnings predate Iteration 005 and did not block scoped validation for this slice.
