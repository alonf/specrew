# Review: Iteration 007

**Schema**: v1
**Reviewed**: 2026-06-04
**Review method**: Proposal 145 (7-phase structured review + FR×phase matrix + claim-ledger + design-trace + report-falsification). 145 is a candidate (not yet validator-enforced), so it is followed here as the review *method*; the structured matrix/ledger/trace are folded into this `review.md` (145's YAML artifacts are its future enforcement shape).
**Overall Verdict**: accepted

## Summary

Iteration 7 delivered the Amendment A4 per-lens facilitated **workshop** (Option B): the agenda generator (T001), the per-lens decision schema + SC-021 floor (T002), the workshop conduct prompt rule (T003), the FR-009 decisions render (T004), the deterministic-floor tests (T005), and the **mandatory runtime dogfood (T006)**. The dogfood (`C:\Temp\SpecrewTrials\testLenses3`, feature 001-photo-foundation) is the headline evidence: it **validated the workshop conduct (SC-020)** — inferred applicability with confirm-only, seven genuine per-lens sessions with real design questions (incl. ASCII layout mockups), iterate-until-"move on", depth-adapted to the dials, recorded `workshop_intake` + per-lens records — and the expertise-transparency line surfaced (settling the parked runtime-confirmation). It **also did what 145 exists to do**: it caught a gate-completeness gap the unit tests missed — the SC-021 floor was wired into the design-analysis gate (iteration-first resolution) and **no-opped on the feature-level workshop artifact**. Fixed (`a0b78cbc`): re-homed to the specify boundary against the feature-level artifact, with a test modeling the real layout.

## Phase 0 — Context load

Loaded: spec A4 (FR-009/FR-025/FR-026/SC-020/SC-021), [plan.md](plan.md) (Option B, 6 tasks, decision `57974536`), [design-analysis.md](iterations/007/design-analysis.md) (the option comparison + the 5 maintainer instructions), the testLenses3 dogfood transcript, and the code diff across `scripts/internal/lens-applicability.ps1`, `scripts/internal/design-analysis-gate.ps1`, `scripts/specrew-start.ps1`, and the three test suites. **Verdict: pass.**

## Phase 1 — Branch hygiene

- Branch `141-design-gate-runtime-hardening`; i7 commits `49ab7fe1` (T001) → `1dfc2676` (T002) → `46dbe038` (T003/T004) → `5735127a` (T005) → `a0b78cbc` (SC-021 fix), on the design-analysis (`57974536`) + plan (`93573b93`/`644a2f99`) + before-implement (`b09ff9ef`) chain.
- **No upstream / local-only is INTENTIONAL** (the standing "no push/PR while 141 is in progress" constraint) — this is the deliberate state, NOT the Shape-4 never-pushed gap; recorded so it is not mistaken for one.
- Shape-5 audit: every file cited as evidence below is committed (no working-tree-only evidence). The dirty working tree is Specrew-managed session-state (closed-iterations.yml, active-features.yml, lifecycle-events.jsonl, now.md) + this closeout; `proposals/145-*.md` is NOT staged (proposals commit to main, not the feature branch).
- **Verdict: pass.**

## Phase 2 — Functional correctness

- **Agenda generator (T001):** `Get-SpecrewLensWorkshopAgenda` returns a lens's decision points as the discussion agenda (verified: architecture-core → 5 prompts); `Format-SpecrewLensWorkshopAgenda` renders the per-lens numbered agenda + decision/depth/move-on lines; graceful on missing/empty.
- **SC-021 floor (T002 + the `a0b78cbc` fix):** `Test-SpecrewLensWorkshopRecords` requires a non-placeholder per-lens record (agenda + decision + depth + moved_on); marker-gated (`workshop_intake`) + grandfather-safe. **Now fires at the specify boundary** against the feature-level artifact.
- **Conduct rule (T003):** Rule 9a rewritten — infer-then-confirm, per-lens discussion until "move on", depth-adapt, right-size. Parse-clean; double-backticks for the `@"..."@` here-string.
- **Design → code conformance:** Option B → agenda generator + SC-021 gate + conduct rule + decisions render — all present and traced (see the trace table). **The dogfood is the behavioral conformance evidence** for the conduct.
- **Verdict: pass** (after the SC-021 fix — see Phase 7 falsification).

## Phase 3 — Non-functional requirements

- Security: the generator/gate are read-only + LLM/network-free; no secrets, auth, eval, or credential persistence. Logging/observability/perf: n/a (pure functions + a prompt rule; no hot path). **Verdict: pass** (security/operability checked; the rest n/a with reason).

## Phase 4 — Code quality

- Lint: markdownlint + PowerShell parse clean across the edited files.
- **Dependency reality:** no new packages/imports — pure PowerShell + JSON (no-new-dependency proof: the diff adds only functions to existing dot-sourced helpers).
- **Anti-pattern scan:** the helpers use `catch { return @() }` / `catch { $doc = $null }` — this is **documented graceful-degradation** (missing/malformed lens inputs degrade to "none", never throw), not catch-and-ignore; disposition `accepted_with_rationale`. No sleep-as-sync, no hidden global mutable state, no unbounded retry, no test-only production behavior, no fake fixtures in production paths.
- **Verdict: pass.**

## Phase 5 — Test coverage + integrity

- FR→test: FR-009/FR-026/SC-021 covered by unit tests (selector + gate suites); FR-025 conduct (SC-020) is **behavioral → covered by the dogfood, not a unit test** (stated honestly, per the hardening gate).
- **Gate-completeness (Shape 8) — the load-bearing check:** the SC-021 gate's coverage was INCOMPLETE (resolved the wrong artifact) and the **dogfood caught exactly that** — the founding 145 thesis, live. The fix adds a **negative/falsification case** (incomplete record → the specify gate FAILS, naming the lens) alongside the passing path.
- Fixture realism: the deterministic tests use synthetic JSON artifacts (appropriate for a pure gate); the conduct's realism is the real downstream dogfood (not synthetic).
- Producer/consumer: the workshop (producer) + the dogfood (consumer demonstration).
- Tests-actually-run: selector, gate, and feature suites ran green (exit 0) post-fix.
- **Verdict: pass.**

## Phase 6 — System safety + ops

- Backward compatibility: the SC-021 floor is **marker-gated** (`workshop_intake`) — pre-A4 questionnaire artifacts no-op and are never retroactively failed; `fr026_grandfathered` exempts. The conduct degrades gracefully (no catalog → no-op).
- No release/publish/push in scope. Multi-dev collision: n/a (additive helpers + a prompt rule). **Verdict: pass.**

## FR × Phase Coverage Matrix

| Requirement | P1 hygiene | P2 functional | P3 NFR | P4 quality | P5 tests | P6 ops |
| --- | --- | --- | --- | --- | --- | --- |
| FR-025 (conduct) | pass | pass (dogfood) | n/a (no NFR aspect) | pass | pass (behavioral → dogfood) | pass |
| FR-009 (decisions flow) | pass | pass | n/a | pass | pass (render test) | n/a |
| FR-026 / SC-021 (floor) | pass | pass (post-fix) | pass (deterministic) | pass | pass (+ negative case) | pass (grandfather-safe) |
| SC-020 (dogfood) | pass | pass | n/a | n/a | pass (the dogfood ran) | pass |

## Claim-to-Evidence Ledger

| Claim | Evidence |
| --- | --- |
| Workshop conduct works (SC-020) | testLenses3 dogfood transcript: infer+confirm applicability, 7 per-lens sessions, "move on", recorded `workshop_intake` + per-lens records |
| Agenda = lens decision points | `Get-SpecrewLensWorkshopAgenda` (lens-applicability.ps1); test "workshop agenda IS the lens decision points" PASS |
| SC-021 floor fires + names the lens | `Test-SpecrewLensWorkshopRecords` (design-analysis-gate.ps1) wired into `Invoke-SpecrewSpecifyBoundaryLensGate`; specify-gate test (design-gate-runtime-hardening.tests.ps1) blocks-on-incomplete/passes-on-complete PASS |
| Expertise line surfaces | dogfood orientation: "expert on Software Architecture, mid-level on UX/UI Design — correct me…" |
| No new dependencies | diff adds only functions to existing helpers (pure PS + JSON) |

## Design → Code → Test Trace

| Design (Option B) | Implementation | Evidence | Status |
| --- | --- | --- | --- |
| Discussable-prompt generator from decision points | `Get-SpecrewLensWorkshopAgenda` / `Format-SpecrewLensWorkshopAgenda` | selector suite | matched |
| Per-lens decision schema + presence floor | `Test-SpecrewLensWorkshopRecords` + specify-gate wiring | gate + feature suites | matched (post-fix) |
| Behavioral conduct | Rule 9a (specrew-start.ps1) | testLenses3 dogfood | matched |
| Decisions inform design/plan | `Format-SpecrewLensWorkshopDecisions` + Rule 9a flow clause | selector suite | matched |

## Phase 7 — Report falsification

- **Falsified my own SC-021 claim.** The pre-dogfood report would have said "SC-021 floor enforced." The dogfood disproved it (the floor no-opped on the feature-level artifact). Downgraded → fixed (`a0b78cbc`) → re-verified by the specify-gate negative-case test. This is the report-as-claim-under-test discipline working.
- Verified the expertise-line claim against the actual transcript (not asserted from the unit test).
- Verified "no new dependencies" against the diff.
- No claim is stronger than its evidence: the conduct claim rests on the dogfood (not unit tests); the floor claim rests on the post-fix test.

## Per-Phase Verdict + Overall

per_phase: { p0: pass, p1: pass, p2: pass, p3: pass, p4: pass, p5: pass, p6: pass }. All applicable phases pass (after the SC-021 fix). **Overall: APPROVE for review-signoff.**

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-009, FR-025 | pass | Agenda generator + render; verified. |
| T002 | FR-026 | pass | SC-021 schema + floor; **re-homed to the specify boundary (a0b78cbc) after the dogfood found it no-opping** — now fires + names the lens. |
| T003 | FR-025 | pass | Conduct prompt rule; validated by the dogfood (SC-020). |
| T004 | FR-009 | pass | Decisions render + the Rule 9a flow clause. |
| T005 | FR-026, SC-021, FR-009 | pass | Deterministic-floor tests + the specify-gate negative case. |
| T006 | SC-020 | pass | The runtime dogfood ran, validated the conduct, and caught the SC-021 gap — the acceptance evidence (maintainer instruction #4). |

## Gap Ledger

- **No FR/SC gaps in delivered scope:** FR-025 (conduct, dogfood-validated), FR-009, FR-026/SC-021 (floor, fixed + tested), SC-020 (dogfood ran) all delivered and verified. The SC-021 mis-fire was **fixed this iteration** (`a0b78cbc`), not deferred. **fixed-now.**

## Follow-ups (not iteration-7 gaps)

- **Workshop visuals → Amendment A5 / Iteration 8** (maintainer-chosen next increment): console/mermaid/svg mockups with clickable temp-file links; existing-doc/Figma/image intake; plot-from-description / accept-a-drawing — for UI, user+system flows, component blocks, comparison tables.
- **FR-026 gate emphasis tolerance:** the `Addressed:` coverage regex rejects `*Addressed*` / `**Addressed**`; the dogfood agent hit this when hand-authoring. Small hardening to tolerate emphasis.
- **Installed-vs-dev module resolution:** the downstream agent's in-session `Get-Module -ListAvailable` found the installed 0.31.0 (lens helpers absent) and hand-authored to the contract; the sync wrapper correctly used the dev tree. Known SPECREW_MODULE_PATH / distribution class; clears when 0.31.1 ships. The recurring `.specify/feature.json` gitignored-but-staged friction is bundled here.

## Notes

- Hardening-gate concerns promoted to runtime-evidence at this signoff (see [quality/hardening-gate.md](iterations/007/quality/hardening-gate.md)) — the deterministic floor is unit-tested; the conduct is dogfood-validated.
- Iteration 7 closes on its delivered scope; the workshop visuals are Iteration 8 (Amendment A5).
