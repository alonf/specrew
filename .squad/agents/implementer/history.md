# Implementer History

Project-specific learnings and patterns discovered during work.

## Patterns

<!-- Append entries below. Format: **Pattern:** description. **Context:** when it applies. -->

## Learnings

- 2026-05-08: When Phase 2 routing defaults change, keep `extensions/specrew-speckit\templates\iteration-config.yml`, `extensions/specrew-speckit\scripts\scaffold-governance.ps1`, and the repo's own `.specrew\iteration-config.yml` aligned so downstream scaffolds and Specrew dogfooding stay truthful together.
- 2026-05-08: Phase 2 config fixtures should mirror the contract block exactly by pairing `quality.known_traps_path` with explicit `quality.routing` defaults, so governance tests can exercise seeded defaults without implying later enforcement work is already implemented.
- 2026-05-08: When a new iteration-local evidence surface is introduced, seed it in both the initial iteration scaffold and the reviewer closeout scaffold so late-generated packets preserve the same placeholder homes without overwriting real evidence.
- 2026-05-08: The hardening-gate orchestrator should reconcile the existing `quality\hardening-gate.md` artifact instead of inventing review outcomes; preserve explicit rationale text, compute verdicts through `shared-governance.ps1`, and fail closed on unresolved `tbd` or unapproved deferred concerns.
