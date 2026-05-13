# Planning Artifact Repair: Feature 015 Consistency

**Date**: 2026-05-13  
**Facilitator**: Planner  
**Context**: Feature 015 public-readiness-pass branch naming and versioning source-of-truth repair  

## What Was Repaired

1. **Branch Reference Consistency**: All references to `016-public-readiness-pass` corrected to `015-public-readiness-pass` in:
   - `specs/015-public-readiness-pass/spec.md` (Feature Branch header)
   - `specs/015-public-readiness-pass/plan.md` (Branch field in header)
   - `.github/copilot-instructions.md` (Recent Changes section)

2. **Versioning Source-of-Truth Explicitness**: Made `.specrew/config.yml` the authoritative version reference:
   - Updated plan.md Summary to state: "`.specrew/config.yml` serves as the canonical source-of-truth for the active Specrew version; downstream README and documentation surfaces mirror this version."
   - Updated FR-008 in spec.md to explicitly name `.specrew/config.yml` and the stale bootstrap value: "`specrew_version: "0.1.0-dev"` to `0.14.0`"
   - Added `.specrew/config.yml` to Project Structure section in plan.md with FR-008 reference

3. **Recent Changes Entry**: Updated `.github/copilot-instructions.md` to replace generic "standard" language with explicit versioning governance: "PowerShell 7 (script extension), Markdown (all documentation artifacts), Git (tag operations) + `validate-governance.ps1` and `shared-governance.ps1` (existing); `.specrew/config.yml` specrew_version bump from 0.1.0-dev to 0.14.0 (version source-of-truth)"

## Why This Matters

- **Consistency**: Feature uses correct branch number (`015`, not `016`) across all planning artifacts
- **Explicitness**: Version governance is now traceable to a specific source file (`.specrew/config.yml`) rather than treated as generic documentation policy
- **Durability**: Future feature-closeout work will understand that version bumps target `.specrew/config.yml` as the authoritative registry, not README or CHANGELOG
- **Scope Clarity**: Confirmed authorization boundary (Iteration 001 planning scaffold + upstream push) is preserved and explicitly stated in all artifacts

## Unchanged Elements

- Scope boundaries remain: specification → Iteration 001 planning scaffold → upstream push; hardening-gate sign-off and implementation authorization remain outside current scope (FR-015)
- All FR-001 through FR-016 and TG-001 through TG-004 requirements preserved
- Quality planning and Phase 1 design gates remain as authored

## Next Actions

Feature 015 planning artifacts are now repair-complete and ready for implementation authorization (when approved by human reviewer).
