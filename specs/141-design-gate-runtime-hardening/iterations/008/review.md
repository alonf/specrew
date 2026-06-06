# Review: Iteration 008

**Schema**: v1
**Reviewed**: 2026-06-05
**Review method**: Proposal 145 (7-phase structured review + FR×phase matrix + claim-ledger + design-trace + report-falsification). 145 is a candidate (not validator-enforced), followed here as the review *method*; its matrix/ledger/trace are folded into this `review.md`.
**Overall Verdict**: accepted

## Summary

Iteration 8 delivered the Amendment A5 **workshop-visuals** capability (Option B): the per-lens diagram catalog `diagram-vocabulary.json` + reader `Get-SpecrewLensDiagramType` (T001), the tiered emit helper `Format-SpecrewWorkshopVisual` + the `.specrew/workshop-visuals/` gitignore pattern (T002), the intake-reference helper `Format-SpecrewVisualIntakeReference` + the Rule 9b conduct addition (T003), the SC-023 deterministic-floor tests (T004, 15 assertions), and the **runtime visual dogfood** (T005). The dogfood (`C:\Temp\SpecrewTrials\testLenses4`, feature `001-doc-translation`) is the headline evidence — and it did exactly what the dogfood exists to do: it **proved the capability fires** (a per-lens architecture component diagram + an ERD were authored from the catalog) **and it falsified the surfacing claim** — the agent wrote the diagrams only to a persisted `.specrew\workshop-visuals\001-doc-translation-architecture.html` with **no in-band clickable `file:///` link and no inline render**, so the maintainer saw no diagram (SC-022's "surfaced per the tier policy" clause), and the ui-ux lens produced no visual. The maintainer dispositioned the fix INSIDE Feature 141 as **Amendment A6 / iteration 009** (Rule 9b surfacing strengthening, folded with collaborative-design conduct). The SC-022 surfacing-clause confirmation is **carried to iteration 009** (`.squad\decisions.md` defer entry); the SC-023 floor passed in full.

## Phase 0 — Context load

Loaded: spec A5 (FR-030/FR-031/FR-032/FR-033, SC-022/SC-023), [plan.md](plan.md) (Option B, 5 tasks, 17/20, decision `18721b9e`), [design-analysis.md](design-analysis.md) (the workshop-settled Option B), the testLenses4 dogfood transcript (the maintainer's 6 findings), and the diff across `extensions/specrew-speckit/knowledge/design-lenses/diagram-vocabulary.json`, `scripts/internal/lens-applicability.ps1`, `scripts/internal/file-classification.ps1`, `scripts/specrew-start.ps1` (Rule 9b), and `tests/unit/lens-applicability-selector.tests.ps1`. **Verdict: pass.**

## Phase 1 — Branch hygiene

- Branch `141-design-gate-runtime-hardening`; i8 chain `ac74a645` (A5 spec) → `aed6dd60` (design draft) → `18721b9e` (decision) → `724dd799` (decision-hash) → `e05c1785` (T001-T004 build) → `99598c6d` (Effort-Model Time-Limit fix).
- **No upstream / local-only is INTENTIONAL** (the standing "no push/PR while 141 is in progress" constraint) — the deliberate state, NOT a Shape-4 never-pushed gap.
- Shape-5 audit: every file cited below is committed. Dirty working tree = Specrew-managed session-state + this closeout; `proposals/*.md` is NOT staged (proposals commit to main, not the feature branch).
- **Verdict: pass.**

## Phase 2 — Functional correctness

- **Catalog + reader (T001):** `diagram-vocabulary.json` maps 9 lenses + cross-cutting flows/comparison to diagram-type + render-form; `Get-SpecrewLensDiagramType` resolves per lens and returns null on missing file/lens (verified: security→trust-boundary/mermaid, data→ERD/mermaid, ui-ux→layout/ascii, missing→null). `index.yml` stays pure (catalog is a sibling).
- **Emit helper (T002):** `Format-SpecrewWorkshopVisual` — inline→fenced block; temp→writes under `.specrew/workshop-visuals/` + returns a `file:///` ref (FR-028 console form); persisted→mermaid/ascii/table inline, svg/html→referenced markdown link; throws clearly when temp/persisted-svg-html lacks a destination. `.specrew/workshop-visuals/` added to the per-session gitignore patterns (FR-033).
- **Intake-reference (T003):** `Format-SpecrewVisualIntakeReference` records a provided artifact path/note as a `file:///` reference (graceful null). Rule 9b added (parse-clean; double-backticks for the here-string).
- **Design → code conformance:** Option B → catalog + emit + intake-reference + conduct rule — all present and traced. **The dogfood is the behavioral conformance evidence, and it is where the gap surfaced (Phase 7).**
- **Verdict: pass for the deterministic capability; the conduct surfacing is carried (Phase 7 falsification).**

## Phase 3 — Non-functional requirements

- Security: catalog reader + emit helper read a data file and write local visual files; no auth, secrets, network, eval, or credential persistence; intake references a provided path (no fetch). LLM/network-free (A5/FR-010). Logging/perf: n/a (pure functions + a prompt rule). **Verdict: pass.**

## Phase 4 — Code quality

- Lint: markdownlint + PowerShell parse clean across the edited files.
- **Dependency reality:** no new packages/imports — pure PowerShell + JSON (the diff adds functions to existing dot-sourced helpers + one data file).
- **Anti-pattern scan:** `catch { $… = $null }` is documented graceful-degradation (missing catalog/lens → none, never throw), not catch-and-ignore. No sleep-as-sync, no hidden global mutable state, no test-only production behavior.
- **Verdict: pass.**

## Phase 5 — Test coverage + integrity

- FR→test: FR-030/FR-031/FR-033/SC-023 covered by the selector suite (catalog resolve 5 + emit tiers 6 + intake 2 + table = 15 assertions, green); file-classification suite green after the gitignore pattern.
- **Gate-completeness (Shape 8) — the load-bearing check:** SC-022 (the *behavioral* visual experience) is NOT unit-provable, and the plan said so — the **runtime dogfood** is its acceptance gate. The dogfood did the gate-completeness job: it found the conduct (Rule 9b, phrased "MAY") under-drove surfacing, so a valid catalog + a working emit helper still produced **no diagram the maintainer could see**. A green unit suite would never have surfaced this — only the real run did.
- Fixture realism: deterministic tests use synthetic content (appropriate for a pure helper); the conduct's realism is the real downstream dogfood.
- Tests-actually-run: selector + file-classification suites ran green (exit 0).
- **Verdict: pass for SC-023; SC-022 surfacing-clause unmet at runtime → carried to i9 (Gap Ledger).**

## Phase 6 — System safety + ops

- Backward compatibility: catalog reader + emit helper are additive; the gitignore pattern is idempotent/non-destructive (`Update-GitignoreForSession`). Temp visuals are ephemeral (gitignored). No release/publish/push in scope. Deferred Proposal 156 scope stayed out. **Verdict: pass.**

## FR × Phase Coverage Matrix

| Requirement | P1 hygiene | P2 functional | P3 NFR | P4 quality | P5 tests | P6 ops |
| --- | --- | --- | --- | --- | --- | --- |
| FR-030 (catalog + reader) | pass | pass | n/a | pass | pass | pass |
| FR-031 (tiered render+**surface**) | pass | pass (emit) / **carried (surface conduct)** | n/a | pass | pass (emit) / **dogfood: surfacing unmet** | pass |
| FR-032 (bidirectional intake) | pass | pass | n/a | pass | pass | pass |
| FR-033 (temp lifecycle / gitignore) | pass | pass | n/a | pass | pass | pass |
| SC-023 (deterministic floor) | pass | pass | pass | pass | pass | pass |
| SC-022 (visual dogfood) | pass | pass (fires) | n/a | n/a | **surfacing clause carried to i9** | pass |

## Claim-to-Evidence Ledger

| Claim | Evidence |
| --- | --- |
| Capability fires (catalog → diagram) | testLenses4 transcript: architecture component diagram + ERD authored from `diagram-vocabulary.json` |
| Catalog resolves per lens, degrades gracefully | `Get-SpecrewLensDiagramType`; selector tests (catalog resolve 5) PASS |
| Emit helper writes temp + returns `file:///`; persisted mermaid-inline / svg-html referenced | `Format-SpecrewWorkshopVisual`; selector tests (emit tiers 6) PASS |
| Temp dir gitignored | `.specrew/workshop-visuals/` in `$script:SpecrewPerSessionPatterns`; file-classification suite green |
| **SC-022 surfacing clause met** | **FALSIFIED by the dogfood** — diagrams written to disk only, no in-band link / inline render → carried to i9 (`.squad\decisions.md`) |

## Design → Code → Test Trace

| Design (Option B) | Implementation | Evidence | Status |
| --- | --- | --- | --- |
| `lens → diagram-type → render-form` catalog | `diagram-vocabulary.json` + `Get-SpecrewLensDiagramType` | selector suite | matched |
| Deterministic tiered emit (FR-028 form) | `Format-SpecrewWorkshopVisual` | selector suite | matched |
| Bidirectional intake-reference | `Format-SpecrewVisualIntakeReference` | selector suite | matched |
| Ephemeral temp lifecycle | `.specrew/workshop-visuals/` gitignore pattern | file-classification suite | matched |
| Behavioral surfacing conduct | Rule 9b (specrew-start.ps1) | testLenses4 dogfood | **gap: under-drove surfacing → i9/A6** |

## Phase 7 — Report falsification

- **Falsified my own SC-022 surfacing claim.** A pre-dogfood report would have read "SC-022 met — workshop visuals surface per the tier policy." The dogfood disproved it: the agent authored the diagrams (the capability is real) but surfaced them only as an on-disk HTML file with no in-band link, so nothing was seen. Recorded honestly, NOT papered over: the surfacing-clause confirmation + the Rule 9b strengthening are carried to iteration 009 (the maintainer's "inside 141 / A6" disposition), with a `.squad\decisions.md` defer entry.
- Verified the "capability fires" claim against the transcript (the HTML was written with catalog-sourced mermaid), not asserted from the unit tests.
- No claim is stronger than its evidence: the floor claim rests on the 15 passing assertions; the surfacing claim is explicitly DOWNGRADED to "carried", not claimed met.

## Per-Phase Verdict + Overall

per_phase: { p0: pass, p1: pass, p2: pass, p3: pass, p4: pass, p5: pass, p6: pass }. The deterministic capability + floor are delivered and tested; SC-022's surfacing clause is unmet at runtime and carried to i9 per the maintainer's disposition. **Overall: ACCEPTED for review-signoff** (capability + SC-023 floor accepted; SC-022 surfacing carried, not claimed).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-030 | pass | Catalog + reader; verified (resolve + graceful null). |
| T002 | FR-031, FR-033 | pass | Emit helper (all tiers) + gitignore pattern; verified. |
| T003 | FR-032, FR-030 | pass | Intake-reference helper + Rule 9b conduct; parse-clean. |
| T004 | SC-023, FR-030, FR-031 | pass | 15 assertions green; the deterministic floor. |
| T005 | SC-022 | pass | The visual dogfood RAN — proved the capability fires AND falsified the surfacing claim (the 145 value). The surfacing-clause fix is carried to i9/A6 (maintainer disposition). The dogfood itself succeeded; its finding drives the next increment. |

## Gap Ledger

- **SC-022 surfacing clause — deferred to iteration 009 (Amendment A6).** The visual capability fires but the conduct (Rule 9b, "MAY") did not compel in-band surfacing, so the maintainer saw no diagram and the ui-ux lens produced none. Maintainer-dispositioned INSIDE 141 as A6 (Rule 9b strengthened: visuals MUST surface in-band; expected for structural + UI lenses). Canonical defer entry in `.squad\decisions.md` (FR-031). NOT a silent skip — recorded, approved, and carried with a named next action.
- **No other FR/SC gaps in delivered scope (fixed-now):** FR-030, FR-031 (emit), FR-032, FR-033, SC-023 all delivered + tested this iteration.

## Follow-ups (dispositioned to Amendment A6 / iteration 009 unless noted)

- **Collaborative design (dogfood #1/#2/#4) → A6 / i9.** The workshop ran as per-lens Q&A then I authored three finished architectures to pick from; the design-method/style was not offered; the component/responsibility/flow map was never co-designed. Maintainer chose "inside 141". This is A6's core.
- **Visual surfacing (dogfood #3/#5) → A6 / i9.** Folded into A6 (Rule 9b strengthening), per the defer entry above.
- **Two-tier workshop (dogfood #6) → separate proposal** (app-level workshop once + short per-feature). Genuinely new structure, NOT A6.

## Notes

- Hardening-gate concerns promoted to runtime-evidence at this signoff (see [quality/hardening-gate.md](quality/hardening-gate.md)) — the SC-023 floor is unit-tested; the SC-022 behavioral surfacing was exercised in the dogfood and found wanting → carried.
- Iteration 8 closes on its delivered + tested capability; the surfacing fix + the collaborative-design capability are iteration 009 (Amendment A6). The dogfood was again the gate-completeness check (the 145 / Shape-8 thesis, live for the second consecutive iteration).
