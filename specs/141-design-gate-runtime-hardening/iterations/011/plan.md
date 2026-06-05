# Iteration Plan: 011

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 18/20 story_points
**Started**: 2026-06-05

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Task Status one of planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Iteration Theme

**Confirmation integrity & intake responsiveness (Amendment A7)** — fix the testLenses7codex Squad blocker: the
workshop recorded seven "Human agreed" lens decisions after ~three human questions (the coordinator's
stopping-judgment backfilled synthetic agreements at specify). Option B (decision `3ea67b32`, draft
`e7a6588c`): a structural per-lens **provenance floor** (SC-026) under the **integrity invariant** (FR-038) +
the **`squad.agent.md` stopping-completeness rule** (the root-cause lever) + the **intake UX** (FR-040). The
floor forces an auditable per-lens declaration but cannot verify the human was asked — the **Squad re-dogfood
(SC-027)** is the behavioral acceptance.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-039 / SC-026 | Per-lens `confirmation` provenance value + the deterministic specify-boundary floor (grandfather-gated by `confirmation_required`) | US-CI |
| FR-038 | Confirmation-integrity invariant + count self-check + the one delegate/skip exception; the `squad.agent.md` stopping-completeness rule | US-CI |
| FR-040 | Intake responsiveness — prep announcement + agenda assignment + per-lens lazy-load progress | US-CI |
| SC-027 | Behavioral acceptance — the Squad/Copilot re-dogfood (synthetic-agreement failure does NOT recur) | US-CI |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Provenance floor: add the per-lens `confirmation` field convention + extend `Test-SpecrewLensWorkshopRecords` to require a valid enum (human-confirmed\|human-delegated\|human-skipped) per selected lens when `confirmation_required: true` (grandfather-safe; pre-A7 artifacts no-op), plus a wiring integration test that proves the floor FAILS through the real gate entry for a missing/invalid provenance | FR-039, SC-026 | US-CI | 4 | Implementer | scripts/internal/design-analysis-gate.ps1, tests/unit/** | planned | claude | — | — |
| T002 | FR-038 invariant in the design-workshop skill: record human-agreed ONLY for surfaced+confirmed lenses; the one delegate/skip exception with honest provenance; never synthesize-and-attribute; the count self-check; the provenance field in the workshop record | FR-038 | US-CI | 3 | Spec Steward | extensions/specrew-speckit/squad-templates/skills/** | planned | claude | — | — |
| T003 | `squad.agent.md` stopping-completeness rule (the root-cause lever): the coordinator MUST NOT declare intake "specific enough" until every selected lens is confirmed/delegated/skipped; never backfill an agreement — modeled on the working greenfield-intake interactive rule, prominent against the launch-aggressively persona | FR-038 | US-CI | 3 | Implementer | .github/agents/squad.agent.md | planned | claude | — | — |
| T004 | FR-040 intake UX: prep announcement ("preparing the workshop, takes a moment") + the agenda "assignment" (lenses + each lens's decision so the human prepares) + per-lens lazy-load progress cue ("preparing lens X of N: <lens>, get ready"); in the skill + a Rule 9a pointer | FR-040 | US-CI | 3 | Spec Steward | extensions/specrew-speckit/squad-templates/skills/**, scripts/specrew-start.ps1 | planned | claude | — | — |
| T005 | Tests + validator: SC-026 floor (positive / missing / invalid / grandfather-no-op) + presence-lock the FR-038 invariant + count + exception + the FR-040 UX conduct in the skill + the `squad.agent.md` rule; all touched suites + the full validator green | SC-026 | US-CI | 3 | Reviewer | tests/unit/** | planned | claude | — | — |
| T006 | SC-027 Squad re-dogfood: a Copilot/Squad downstream run where the workshop does NOT record agreements for un-surfaced lenses (the testLenses7codex failure does not recur), delegated/skipped lenses are honestly attributed, and the intake announces prep + agenda + per-lens progress. Behavioral acceptance gate (needs the maintainer) | SC-027 | US-CI | 2 | Planner | specs/141-design-gate-runtime-hardening/** | planned | claude | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | |
| Iteration Bounding | scope | |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 18/20. |
| Defer Strategy | manual | |
| Calibration Enabled | true | |

## Concurrency Rationale

- T001 (the floor) is the structural root; T002 (skill invariant), T003 (`squad.agent.md` rule), and T004 (UX)
  are independent conduct edits on different files; T005 (tests) follows the code; T006 (the dogfood) is the
  human-run acceptance gate. Serial baseline team.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Design-analysis (Option B, decision `3ea67b32`). |
| Implementation | 13 | T001 floor (4) + T002 skill (3) + T003 squad.agent.md (3) + T004 UX (3). |
| Review | 5 | T005 tests (3) + T006 the Squad dogfood (2). |
| Rework | 0 | Buffer via the 18/20 headroom. |

## Traceability Summary

- Iteration 11 scope: Amendment A7 (FR-038/FR-039/FR-040, SC-026/SC-027).
- Design-analysis: completed via the stop; Option B; decision `3ea67b32`, draft `e7a6588c`.
- Mapping: provenance floor → T001 (FR-039/SC-026); skill invariant → T002 (FR-038); squad.agent.md stopping
  rule → T003 (FR-038); intake UX → T004 (FR-040); tests → T005 (SC-026); Squad dogfood → T006 (SC-027).

## Notes

- **The acceptance is behavioral.** The SC-026 floor enforces that a per-lens provenance value is *present and
  valid*; it cannot verify the human was actually asked (the agent could set `human-confirmed` falsely). T006's
  Squad re-dogfood — not T005's unit floor — is the real gate (the i6–i10 lesson, the testLenses7 finding).
- `index.yml` stays pure; the floor is deterministic + LLM/network-free; the deploy is unchanged (the skill is
  edited in place); no release/push while 141 is in progress; the deferred Proposal 156 scope stays out.
- The grandfather marker `confirmation_required: true` keeps pre-A7 `workshop_intake` artifacts (testLenses4–7,
  i1–i10) no-op — the `workshop_intake`/`fr026_grandfathered` precedent.
