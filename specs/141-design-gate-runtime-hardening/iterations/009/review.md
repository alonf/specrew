# Review: Iteration 009

**Schema**: v1
**Reviewed**: 2026-06-05
**Review method**: Proposal 145 (7-phase structured review + FR×phase matrix + claim-ledger + design-trace + report-falsification). 145 is a candidate (not validator-enforced), followed here as the review *method*.
**Overall Verdict**: accepted

## Summary

Iteration 9 delivered Amendment A6 — collaborative architecture & design: the conduct (Rule 9a phase-framing, Rule 9b in-band surfacing, new Rule 9c co-design at design-analysis), the architecture-core design-method decision point (FR-035), and the marker-gated, grandfather-safe `Test-SpecrewDesignCoDesignRecord` floor (SC-025) wired into the pre-plan gate — plus the **wiring integration test** the i7 lesson demanded. The **SC-024 dogfood (testLenses5, Claude + Codex)** is the headline evidence, and it did what the dogfood exists to do: it **confirmed the co-design CONDUCT works** (the human co-designed the IDesign component/responsibility map + walked two flows, recorded in the Co-Design Record) and the floor holds — AND it **falsified the surfacing claim**: the Claude agent wrote the component diagram to an HTML file and never surfaced it, presented a terse "4 Managers, 3 Engines" count, and the ui-ux layout agreement was captured nowhere. Three of the four findings were FIXED in-iteration (A: ASCII is the inline default on terminal hosts where a fenced mermaid block is source text, not a picture; C: name components + responsibilities, never a count; D: the SC-025 floor now requires the ui-ux layout capture). The fourth — the agent under-surfacing in-conversation because the conduct lives in a ~50-rule one-shot launch prompt it skims — is the **delivery/dilution** cause, dispositioned by the maintainer as a delivery REDO in **iteration 010** (same A4/A5/A6 intent, changed implementation: relocate conduct to a re-invokable workshop skill + the on-demand per-lens md + a trimmed prompt). SC-024's full behavioral pass is **carried to i10** (`.squad\decisions.md` defer entry).

## Phase 0 — Context load

Loaded: spec A6 (FR-034..FR-037, SC-024/SC-025), [plan.md](plan.md) (Option B, 6 tasks, 18/20, decision `1beb17ff`), [design-analysis.md](design-analysis.md), the testLenses5 dogfood transcript (Claude run + the parallel Codex run, which rendered ASCII inline when asked — the discriminating evidence), and the diff across `scripts/specrew-start.ps1` (Rules 9a/9b/9c), `extensions/specrew-speckit/knowledge/design-lenses/architecture-core.md`, `scripts/internal/design-analysis-gate.ps1` (the floor + D extension), and `tests/unit/**`. **Verdict: pass.**

## Phase 1 — Branch hygiene

- Branch `141-design-gate-runtime-hardening`; i9 chain `0ca464ac` (A6 spec) → `abfe785e` (design draft) → `1beb17ff` (decision) → `37498974` (hash) → `b8d81f6c` (plan) → `05508f90` (before-implement) → `e9b84651` (build T001-T005) → `adb80a9f` (wiring test) → `2f3d1c96` (testLenses5 A/C/D fixes).
- **No upstream / local-only is INTENTIONAL** (the standing "no push/PR while 141 in progress" constraint) — not a Shape-4 gap. `proposals/145` + `proposals/162` are NOT on this branch (proposals → main; 162 committed to main `0844b05d`).
- Shape-5 audit: every cited file is committed. **Verdict: pass.**

## Phase 2 — Functional correctness

- **Conduct (T001-T002):** Rule 9a phase-framing clause (e); Rule 9c co-design (method discussion + co-build map/flows before options + expertise-adapt + record); Rule 9b surfacing — strengthened to ASCII-inline-default + mermaid/file-with-link (the testLenses5 A fix). Parse-clean; double-backticks for the here-string.
- **Lens data (T003):** architecture-core gained a design-method/decomposition-style decision point (FR-035); `Get-SpecrewLensWorkshopAgenda` surfaces it (selector-suite assertion).
- **Floor (T004):** `Test-SpecrewDesignCoDesignRecord` — marker-gated (`co_design`), grandfather-safe; requires component→responsibility map + ≥1 flow + agreed marker, and (D fix) the agreed UI/screen layout when ui-ux is selected; wired into `Test-SpecrewDesignAnalysisArtifact`.
- **Design → code conformance:** Option B → conduct + lens-data + floor — all present and traced. **The dogfood is the behavioral evidence: the conduct CONFORMS (co-design happened); the DELIVERY under-surfaces → i10.**
- **Verdict: pass for the conduct + floor; the surfacing delivery is carried (Phase 7).**

## Phase 3 — Non-functional requirements

- Security: prompt-conduct text + a deterministic markdown/JSON gate check + a lens-data edit; no auth, secrets, network, eval. The floor + agenda are LLM/network-free. **Verdict: pass.**

## Phase 4 — Code quality

- Lint: markdownlint + PowerShell parse clean across the edited files (AST-checked).
- **Dependency reality:** no new packages/imports — pure PowerShell + JSON + a lens-md edit.
- **Anti-pattern scan:** the floor uses `catch { return @() }` graceful-degradation (malformed/missing lens-applicability.json → no-op), documented; no sleep-as-sync, no hidden global state, no test-only production behavior. **Verdict: pass.**

## Phase 5 — Test coverage + integrity

- FR→test: SC-025 floor covered by the selector + gate suites (marker-gated/grandfather/placeholder + the **wiring integration test** through `Test-SpecrewDesignAnalysisArtifact` — the i7 lesson — + the **D ui-ux capture twin**); FR-035 by the agenda assertion. SC-024 (co-design conduct) is **behavioral → the dogfood, not a unit test** (stated honestly).
- **Gate-completeness (Shape 8) — load-bearing, third iteration running:** the SC-025 floor was proven to fire through the real gate (the negative-path integration test), closing the i7-class wiring hole BEFORE the dogfood. The dogfood then did its own gate-completeness job — it found that the CONDUCT, though correct, doesn't reliably surface because of its DELIVERY (the one-shot mega-prompt). A green floor + a passing wiring test were necessary, not sufficient; only the real run exposed the delivery-dilution.
- Tests-actually-run: selector, gate (incl. integration + D twins), file-classification, design-gate-runtime-hardening suites ran green (exit 0). **Verdict: pass for SC-025; SC-024 delivery carried to i10.**

## Phase 6 — System safety + ops

- Backward compatibility: the co-design floor is **marker-gated** (`co_design`) + grandfather-safe — i1-i8, Feature 140, and pre-A6 artifacts no-op; the D ui-ux requirement only fires when ui-ux is selected AND co_design is set. No release/publish/push. **Verdict: pass.**

## FR × Phase Coverage Matrix

| Requirement | P1 | P2 | P3 | P4 | P5 | P6 |
| --- | --- | --- | --- | --- | --- | --- |
| FR-034 (phase-framing) | pass | pass (conduct) | n/a | pass | pass (dogfood) | pass |
| FR-035 (design-method) | pass | pass | n/a | pass | pass (agenda test) | pass |
| FR-036 / SC-024 (co-design) | pass | pass (conduct works) / **delivery carried** | n/a | pass | pass (dogfood: conduct yes, surfacing no) | pass |
| FR-037 (in-band surfacing) | pass | **A fixed (ASCII); delivery → i10** | n/a | pass | dogfood: under-surfaced → i10 | pass |
| SC-025 (floor) | pass | pass (+ D ui-ux) | pass | pass | pass (+ wiring + D twin) | pass (grandfather-safe) |

## Claim-to-Evidence Ledger

| Claim | Evidence |
| --- | --- |
| Co-design conduct works (SC-024 conduct) | testLenses5: human co-designed the IDesign map (4 Managers/3 Engines/5 ResourceAccess) + 2 walked flows, recorded in the Co-Design Record |
| SC-025 floor fires through the real gate | the negative-path integration test (Test-SpecrewDesignAnalysisArtifact → FAIL naming Co-Design Record) PASS |
| D: ui-ux layout capture enforced | the ui-ux twin (marked + ui-ux selected + no layout → FAIL; + layout → PASS) PASS |
| **In-band surfacing reliable (SC-024 surfacing)** | **FALSIFIED** — Claude wrote the diagram to HTML, never surfaced; Codex rendered ASCII inline only when asked → A fixed (ASCII-default), delivery relocation carried to i10 |
| Agents re-invoke skills (i10 viability) | web docs: skill name+description always in system prompt; body loaded on-demand, multiple times/session |

## Design → Code → Test Trace

| Design (Option B) | Implementation | Evidence | Status |
| --- | --- | --- | --- |
| Co-design conduct | Rules 9a/9b/9c (specrew-start.ps1) | testLenses5 dogfood | matched (conduct); delivery → i10 |
| Design-method discussion | architecture-core decision point | agenda assertion | matched |
| Co-design-record floor | `Test-SpecrewDesignCoDesignRecord` + wiring | gate suite (incl. integration + D) | matched |
| In-band surfacing | Rule 9b (ASCII-default after A fix) | dogfood | content matched; delivery carried |

## Phase 7 — Report falsification

- **Falsified my own "SC-024 surfacing met" claim.** The pre-dogfood report (and the first i9 handoff) implied A6's visuals would surface. testLenses5 disproved it on the Claude host. Recorded honestly: A (content) + D (floor) fixed in-iteration; the delivery cause routed to i10 with a `.squad\decisions.md` defer entry — NOT papered over.
- Verified "co-design conduct works" against the transcript (the human genuinely shaped the map + flows), not asserted from the floor.
- No claim stronger than its evidence: the floor claim rests on the wiring + D tests; the conduct claim on the dogfood; the surfacing claim is explicitly DOWNGRADED to "carried".

## Per-Phase Verdict + Overall

per_phase: { p0: pass, p1: pass, p2: pass, p3: pass, p4: pass, p5: pass, p6: pass }. The co-design conduct + the SC-025 floor (+ A/C/D fixes) are delivered + tested; SC-024's in-band-surfacing delivery is carried to i10 per the maintainer's relocation disposition. **Overall: ACCEPTED for review-signoff.**

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-034, FR-036 | pass | Rule 9a phase-framing + Rule 9c co-design; co-design conduct validated by the dogfood. |
| T002 | FR-037 | pass | Rule 9b surfacing; A fix (ASCII-inline-default) applied after the dogfood; delivery reliability → i10. |
| T003 | FR-035 | pass | architecture-core design-method point + agenda assertion. |
| T004 | SC-025, FR-036 | pass | `Test-SpecrewDesignCoDesignRecord` + wiring + the D ui-ux extension. |
| T005 | SC-025, FR-035 | pass | Floor tests + wiring integration + D twin + agenda assertion; all suites green. |
| T006 | SC-024 | pass | The dogfood RAN (testLenses5) — confirmed the conduct works AND falsified the surfacing (the 145 value). A/C/D fixed; the delivery relocation is i10 (maintainer disposition). The dogfood itself succeeded; its finding drives the next increment. |

## Gap Ledger

- **SC-024 in-band-surfacing delivery — deferred to iteration 010 (the relocation).** The co-design conduct works but under-surfaces in-conversation because it lives in a ~50-rule one-shot launch prompt; the maintainer dispositioned a delivery REDO (skill + on-demand per-lens md + trimmed prompt) INSIDE 141 as i10. Canonical defer entry in `.squad\decisions.md` (FR-036). Approved, named next action — not a silent skip.
- **A/C/D fixed-now:** ASCII-inline default (A), named-components (C), ui-ux capture floor (D) all delivered + tested this iteration.
- **No other FR/SC gaps in delivered scope (fixed-now):** FR-034, FR-035, FR-036 (conduct), SC-025 (floor) all delivered + tested.

## Follow-ups

- **Lens-conduct delivery relocation → iteration 010** (maintainer-chosen): a single re-invokable `design-workshop` skill (uniform across the 5 host skill dirs) loading the right `design-lenses/<id>.md` per stage; per-lens conduct co-located into those md; trimmed launch prompt; workshop-folder artifacts. Web-confirmed: skills re-invoke on-demand.
- **B (options invisible at the verdict menu) → parked Rule-46 / AskUserQuestion-collapse** (handoff-quality track, NOT 141).
- **Future (post-141):** the maintainer's sub-agent-per-skill + coordinator model.

## Notes

- Hardening-gate concerns promoted to runtime-evidence at this signoff (see [quality/hardening-gate.md](quality/hardening-gate.md)).
- Iteration 9 closes on its delivered + tested scope (the co-design conduct + the SC-025 floor + A/C/D); the delivery relocation is iteration 010. The dogfood was the gate-completeness check for the third consecutive iteration (the 145 / Shape-8 thesis).
