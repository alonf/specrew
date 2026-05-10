# Implementer History

Project-specific learnings and patterns discovered during work.

## Patterns

<!-- Append entries below. Format: **Pattern:** description. **Context:** when it applies. -->

## Learnings

- 2026-05-08: When Phase 2 routing defaults change, keep `extensions/specrew-speckit\templates\iteration-config.yml`, `extensions/specrew-speckit\scripts\scaffold-governance.ps1`, and the repo's own `.specrew\iteration-config.yml` aligned so downstream scaffolds and Specrew dogfooding stay truthful together.
- 2026-05-08: Phase 2 config fixtures should mirror the contract block exactly by pairing `quality.known_traps_path` with explicit `quality.routing` defaults, so governance tests can exercise seeded defaults without implying later enforcement work is already implemented.
- 2026-05-08: When a new iteration-local evidence surface is introduced, seed it in both the initial iteration scaffold and the reviewer closeout scaffold so late-generated packets preserve the same placeholder homes without overwriting real evidence.
- 2026-05-08: The hardening-gate orchestrator should reconcile the existing `quality\hardening-gate.md` artifact instead of inventing review outcomes; preserve explicit rationale text, compute verdicts through `shared-governance.ps1`, and fail closed on unresolved `tbd` or unapproved deferred concerns.
- 2026-05-10: When adding new state tracking to reviewer-regression logic (like implementer chain and lockout caps), store runtime state in `.squad/config.json` under the feature-specific section, decision evidence in `.squad/decisions.md`, and visibility in iteration `state.md` managed blocks. This three-surface pattern (runtime, governance, visibility) ensures state is both machine-readable and human-inspectable.
- 2026-05-10: Cap-activation logic should transition check (before/after) to ensure idempotent decision recording. Record the cap-activation decision only when the cap first becomes active, not on every subsequent report call, to avoid duplicate ledger entries.
- 2026-05-10: When extending test suites with new assertions, reuse existing test harness patterns (like `reviewer-regression-event.ps1`) to minimize fixture setup and focus tests on the new acceptance criteria. This keeps tests maintainable and reduces duplication.
- 2026-05-10: For state visibility tests, prefer checking the managed block in `state.md` directly over running full command-line integration (like `specrew review`) when the fixture doesn't include all required closeout artifacts. Direct block inspection is faster and more focused on the FR requirement.
- 2026-05-10: When surfacing governance state in user-facing handoff outputs (like reviewer replay), parse the managed block from `state.md` using a dedicated helper function, include parsed fields in both the summary object and digest line, and update tests to exercise the full handoff path (scaffold → review command) rather than reading fixture state directly. Cap state fields should be added conditionally to summary lines only when active, avoiding clutter and maintaining backward compatibility with existing parsing logic.
