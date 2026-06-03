# Code Map: Iteration 004

**Schema**: v1
**Reviewed**: 2026-06-03
**Overall Verdict**: accepted

## Surface

- **Files changed**: 4 — 328 insertions, 0 deletions (`83e1c1e9..HEAD`).
- **Production**: `scripts/internal/lens-applicability.ps1` (203, new — selector + render + JSON emit), `extensions/specrew-speckit/knowledge/design-lenses/applicability-map.json` (17, new — decoupled sibling map), `extensions/specrew-speckit/templates/design-analysis.template.md` (17 — "Applicable Lenses" section wired).
- **Tests**: `tests/unit/lens-applicability-selector.tests.ps1` (91, new — 27 assertions).
- **Hotspots**: none. **Manifests/dependencies**: 0 (pure PowerShell + JSON). **`index.yml`**: NOT modified (decoupled).

## Changed Files → Requirement

| File | Requirement | Role |
| ---- | ----------- | ---- |
| `applicability-map.json` | FR-025, FR-010 | Sibling question→lens gating map (always-on + 6 gated); `index.yml` stays pure. |
| `scripts/internal/lens-applicability.ps1` | FR-025, FR-009, FR-010 | Pure deterministic selector (`Get-SpecrewApplicableLenses`), audit (`Get-SpecrewLensSelection`), JSON emit (`New-SpecrewLensApplicabilityTemplate`), render (`Format-SpecrewApplicableLensesSection`). No network/LLM. |
| `design-analysis.template.md` | FR-009 | "Applicable Lenses" section + questionnaire/render guidance. |
| `lens-applicability-selector.tests.ps1` | SC-006, SC-015 | 27/0 — determinism, gating, degradation, purity, MD049 guard. |

## Notes

- Iteration-4's own design-analysis lenses were dogfood-rendered through this path (see review.md); `lens-applicability.json` is the recorded artifact.
