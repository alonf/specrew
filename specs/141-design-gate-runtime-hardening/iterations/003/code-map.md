# Code Map: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-03
**Overall Verdict**: accepted

## Surface

- **Files changed (source + test)**: 5 — 209 insertions, 2 deletions (iteration-003 source range `592b21c0~1..ac02e58b`, excludes the origin/main merge).
- **Production code**: 2 files, ~19 lines. **Tests**: 3 files, ~192 lines. Test-heavy, as expected for a reproduce-first hardening slice.
- **Hotspots**: none (no file exceeds ~92 changed lines; the largest is a new test).
- **Manifests/dependencies**: 0 changed (pure PowerShell).

## Changed Files → Requirement

| File | Lines | Requirement | Role |
| ---- | ----- | ----------- | ---- |
| `scripts/auto-detection.ps1` | +10/-2 | FR-012 | `$writeSignals` corroborates a distinct-actor signal instead of triggering the multi-developer recommendation alone. |
| `scripts/specrew-start.ps1` | +7 | FR-013 | `Save-StartArtifacts` else-branch: greenfield baseline guidance nudge when no git HEAD resolves (no stamp, no auto-commit). |
| `tests/unit/feature-051-iteration2b.tests.ps1` | +44 | SC-008 | Reproduce-first: single-dev bootstrap → no multi-dev signal; 2-author repo → recommendation still fires (over-suppression guard). |
| `tests/integration/design-gate-runtime-hardening-greenfield-baseline.tests.ps1` | +92 (new) | SC-009 | Primary, locally-green: zero-commit guidance + no-stamp + no-commit; post-commit resolve-to-HEAD + consistency. |
| `tests/integration/baseline-hygiene.tests.ps1` | +56 | SC-009 | Co-located SC-009 in the Feature-029 baseline suite (CI-reach not verified here). |

## Notes

- The origin/main merge (`8609760c`, 0.31.0 + Feature 140) is excluded from this surface — its files (`bin/`, `scripts/specrew.ps1`, `install.sh`, design-lenses) are disjoint from the 141 changes.
- No production file was touched outside the two named above; the FR-013 change is `Write-Warning`-only and does not touch the `recorded_at` serialization path.
