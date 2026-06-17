# Tasks: Full Antigravity Refocus

**Schema**: v1
**Feature**: file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/spec.md
**Iteration**: file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/iterations/002/plan.md
**Status**: iteration 002 tasks decomposed; awaiting before-implement go-ahead
**Capacity**: 20/20 story_points

## Iteration 001 (closed)

Iteration 001 closed at `abf18b99` (T001-T008, all `done`, 26/26 temporary-overcap
story_points). Its historical task table and traceability live in
file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/iterations/001/plan.md
and this file's git history. The table below is the active iteration 002
decomposition; iteration 002 requirement scope is FR-011 through FR-018, SC-011
through SC-020, and TG-005 (real-host evidence labeling).

## Task Table

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Verification |
| --- | --- | --- | --- | ---: | --- | --- | --- | --- |
| T001 | Confirm current instruction-file behavior and related proposal posture | FR-011, FR-016, FR-018, SC-011, SC-019, SC-020 | US6 | 2 | Planner, Reviewer | `hosts/**`; `scripts/specrew-init.ps1`; `scripts/specrew-update.ps1`; `scripts/specrew-start.ps1`; `scripts/init/**`; `scripts/internal/**`; `Specrew.psd1`; `proposals/**` | done | Discovery note records which hosts already deploy instruction content, the current manifest `InstructionsFile` values, and whether a proposal amendment is needed; a PASS/FAIL split-guard row is emitted. |
| T002 | Add packaged coordinator instruction fragment and managed-section merge helper | FR-012, FR-013, FR-018, SC-012, SC-013, SC-020 | US6, US7, US8 | 4 | Implementer | `scripts/internal/**`; `templates/**`; `extensions/specrew-speckit/**`; `.specify/extensions/specrew-speckit/**`; `Specrew.psd1`; `tests/**` | done | Unit tests prove the merge helper replaces only the delimited Specrew-owned section and preserves user content byte-for-byte; the packaged fragment carries the exact FR-013 guard text. |
| T003 | Wire manifest-driven init deployment, update refresh, and start heal | FR-011, FR-015, FR-016, FR-018, SC-011, SC-014, SC-019, SC-020 | US6, US8 | 4 | Implementer | `hosts/**`; `scripts/specrew-init.ps1`; `scripts/specrew-update.ps1`; `scripts/specrew-start.ps1`; `scripts/init/**`; `scripts/internal/**`; `Specrew.psd1`; `tests/integration/**` | done | Integration test: scratch init creates/merges each host's manifest-declared `InstructionsFile`; `specrew update` refreshes; `specrew start` heals a missing/stale section -- all reading `InstructionsFile` from manifests with no host-name branch. |
| T004 | Front-load bootstrap action and mirror the anti-raw-Spec-Kit guard | FR-013, FR-014, FR-018, SC-013, SC-015, SC-018 | US7 | 3 | Implementer, Spec Steward | `scripts/internal/specrew-bootstrap-provider.ps1`; `extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1`; `.specify/extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1`; `scripts/internal/bootstrap/**`; `tests/bootstrap/**` | done | Ordering test pins the immediate Specrew action above broader context; text test pins the exact FR-013 guard in the bootstrap; both surfaces carry identical guard text. |
| T005 | Add automated coverage: instruction merge, FileList, bootstrap ordering, host-coupling firewall | FR-012, FR-015, FR-016, FR-018, SC-011, SC-012, SC-013, SC-014, SC-015, SC-019, SC-020 | US6, US7, US8 | 4 | Reviewer | `tests/integration/**`; `tests/bootstrap/**`; `tests/unit/**`; `scripts/**`; `hosts/**`; `Specrew.psd1` | done | Host-coupling firewall negative test rejects `agy`/Antigravity literals and host-name branching in shared instruction-delivery core; FileList test proves the template/helper paths exist; idempotence tests for init/update/start-heal. |
| T006 | Run real-host Antigravity Opus 4.6 and Gemini Flash dogfood evidence | FR-017, SC-016, SC-017, SC-018, TG-005 | US7 | 3 | Reviewer, Human | `specs/184-full-antigravity-refocus/iterations/002/**` | in-progress | Machine-local real-host evidence record: Opus 4.6 time-to-workshop vs iter-001; Gemini Flash follows the governed workshop and does not invoke `specify.exe workflow`, or the weak-model caveat is explicitly preserved. Human-owned parity-validation acceptance -- not droppable for slack. |

## Sequencing

- T001 (discovery) gates implementation: it confirms current instruction-file
  behavior, exact deploy surfaces, and the proposal posture before any code lands.
- **Split guard (live):** if T001 or T003 shows this requires per-host handlers
  instead of a shared manifest-driven `InstructionsFile` projection, or if T004
  needs bootstrap/runtime contract rewrites beyond front-loading plus guard
  wording, STOP for a human split/defer decision rather than overrun the 20/20 cap.
- T002 creates the reusable template plus merge primitive; T003 consumes it from
  init/update/start.
- T004 (bootstrap text) may run partly in parallel with T003 after T002, but
  T002/T003/T005 share deploy/package surfaces (`scripts/specrew-*.ps1`, the
  bootstrap provider plus its mirrors, `Specrew.psd1`, the host-coupling firewall
  test) and stay serial to avoid conflicting edits -- one implementer workstream.
- T005 validates the completed behavior; T006 is the human-owned real-host
  acceptance and must not be deferred for slack.

## Traceability Check

**Verdict**: PASS (bidirectional -- both directions checked)

| Check | Result |
| --- | --- |
| Every task maps to at least one FR, SC, or TG | PASS |
| Every FR-011 through FR-018 has at least one task | PASS |
| Every SC-011 through SC-020 has at least one task | PASS |
| TG-005 (real-host evidence labeling) has at least one task | PASS |
| Tasks include owner, effort, story, and verification metadata | PASS |
| Invalid or stale requirement references | None |
| Orphan tasks (task with no FR/SC/TG) | None |
| Uncovered requirements (in-scope FR/SC/TG with no task) | None |

## Traceability Matrix

| Requirement | Covering Tasks |
| --- | --- |
| FR-011 | T001, T003 |
| FR-012 | T002, T005 |
| FR-013 | T002, T004 |
| FR-014 | T004 |
| FR-015 | T003, T005 |
| FR-016 | T001, T003, T005 |
| FR-017 | T006 |
| FR-018 | T001, T002, T003, T004, T005 |
| SC-011 | T001, T003, T005 |
| SC-012 | T002, T005 |
| SC-013 | T002, T004, T005 |
| SC-014 | T003, T005 |
| SC-015 | T004, T005 |
| SC-016 | T006 |
| SC-017 | T006 |
| SC-018 | T004, T006 |
| SC-019 | T001, T003, T005 |
| SC-020 | T001, T002, T003, T005 |
| TG-005 | T006 |
