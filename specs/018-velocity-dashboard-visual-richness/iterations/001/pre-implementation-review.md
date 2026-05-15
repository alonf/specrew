# Pre-Implementation Review: Feature 018 Iteration 001

**Schema**: v1  
**Reviewed By**: Reviewer  
**Reviewed At**: 2026-05-15  
**Scope**: FR-001..FR-020, TG-001..TG-004  
**Overall Verdict**: ready-with-concerns

---

## Review Summary

- The authorized pre-implementation boundary now exists on disk: `iterations/001/quality/hardening-gate.md`, `quality-evidence.md`, `trap-reapplication.md`, `mechanical-findings.json`, `plan.md`, and `state.md` are present and aligned to the single-iteration execution slice.
- The blocker in the earlier review is cleared. `.squad/decisions.md` records both the hardening-gate sign-off and the bundled implementation authorization for Feature 018 Iteration 001, and the current iteration package passes `validate-governance.ps1`.
- Boundary readiness is still conditional in the useful sense: implementation may proceed only within the authorized iteration-scoped artifact set, with the watchpoints below carried forward as required verification targets rather than softened advice.

---

## Authorized Boundary Check

| Topic | Evidence | Assessment | Required Next Move |
| --- | --- | --- | --- |
| Boundary artifact presence | `iterations/001/state.md:32-40,58-63`, `iterations/001/plan.md:93-128`, `iterations/001/quality/hardening-gate.md:1-112`, `.squad/decisions.md:2068-2089` | The iteration-scoped hardening gate and companion execution artifacts now exist, and the approval ledger points to this same hardening-gate-and-implementation-auth boundary. The earlier missing-artifact blocker is gone. | Keep the review anchored to `iterations/001/` and do not reopen feature-root planning surfaces at this boundary. |
| Plan-vs-task traceability | `plan.md:167-182`, `tasks.md:35-119`, `iterations/001/plan.md:19-37,117-127` | The five approved pillars, story coverage, and validation lanes remain fully represented. No traceability blocker is visible in the current execution package. | Start with `T001-T005` only after the before-implement boundary confirms this same artifact set. |
| NFR-001 timing feasibility | `spec.md:121,147`, `plan.md:42-49,103,134,142`, `tasks.md:104,117`, `iterations/001/quality/hardening-gate.md:26,40` | Feasible, but still a hard stop-ship concern rather than a polish check. The package truthfully defers runtime proof to the dedicated render-budget lane. | Treat `T024` + `T028` as mandatory stop-ship evidence the first time they run. |
| Terminal-capability decision precedence | `spec.md:13-15,99`, `tasks.md:80-84`, `iterations/001/quality/hardening-gate.md:24,38,89-93` | No blocker remains because the hardening gate now names the precedence concern explicitly and binds it to later verification. The concern remains live until replay proves one deterministic order across entry points. | Carry the precedence chain forward unchanged: forced ASCII / Unicode opt-out first, non-interactive or dumb output next, UTF-8 eligibility next, Windows VT gating for live ANSI last. |
| Windows VT fallback truthfulness | `spec.md:23`, `contracts/dashboard-rich-rendering-contract.md:36-42`, `tasks.md:80-84`, `iterations/001/quality/hardening-gate.md:25,39` | The concern is properly captured at the authorized boundary. It is no longer missing from the pre-implementation package. | Require clean monochrome fallback on Windows when VT is unavailable; no partial ANSI leakage. |
| Feature 017 regression coverage | `spec.md:118-121`, `plan.md:98-104`, `tasks.md:98-105,117-118`, `iterations/001/quality/quality-evidence.md:13-19` | Covered. Existing Feature 017 unit/integration lanes remain mandatory and are explicitly carried into the iteration-scoped evidence matrix. | Preserve the current Feature 017 test lanes as acceptance evidence, not optional reassurance. |
| ANSI stripping with Unicode preservation | `spec.md:21,98-99`, `contracts/dashboard-artifact-encoding-contract.md:20-32`, `tasks.md:76-84,99-105`, `iterations/001/quality/hardening-gate.md:27,46` | Covered on substance and now correctly anchored in the hardening gate. The remaining risk is execution discipline, not planning incompleteness. | Keep ANSI stripping and Unicode preservation in one acceptance chain; do not let stripping degrade into ASCII conversion. |
| Iteration-closeout dashboard artifact rendering | `contracts/dashboard-artifact-encoding-contract.md:7-18,34-38`, `tasks.md:84,99,103,118`, `iterations/001/quality/hardening-gate.md:28,47`, `iterations/001/state.md:35-40` | Covered and correctly scoped to the live/closeout parity boundary. The authorized package now records the same immutability and parity expectations the approval ledger assumes. | Keep closeout rendering parity and artifact immutability as explicit replay targets; do not widen into new lifecycle behavior. |

---

## Gap Ledger

| ID | Severity | Gap | Why It Matters | Action |
| --- | --- | --- | --- | --- |
| G-001 | watchpoint | The authorized boundary is iteration-scoped, but some feature-level planning text still points at feature-root quality paths from the earlier planning frame. | The next move must stay tied to the approved `iterations/001/` package, not drift back into a broader or older artifact framing. | Treat `iterations/001/quality/hardening-gate.md` and the companion iteration artifacts as the controlling boundary for `/speckit.specrew-speckit.before-implement`. |
| G-002 | watchpoint | Terminal-capability rules still need runtime proof of a single deterministic precedence chain across `--ASCII`, Unicode opt-out, redirected/dumb output, UTF-8 checks, and Windows VT eligibility. | This remains the highest-likelihood truthfulness regression for a rich-default terminal feature. | Preserve the gate’s precedence watchpoint unchanged and prove it through the real CLI/rendering replay lanes. |
| G-003 | watchpoint | Render-budget, ANSI-stripping, and closeout-parity concerns are planned correctly but remain unproven until implementation evidence exists. | These are exactly the places where a visually richer slice can appear complete while quietly violating NFR-001 or historical-artifact trust. | Keep them as explicit stop-ship or acceptance gates during implementation and later review; do not downgrade them to polish. |

---

## Reviewer Verdict

**READY WITH CONCERNS** — The authorized Feature 018 Iteration 001 pre-implementation boundary is now present on disk and coherent enough to proceed. The missing-hardening-gate blocker is cleared; implementation may advance through `/speckit.specrew-speckit.before-implement` and then into `T001-T005`, but only under the watchpoints already encoded in `specs/018-velocity-dashboard-visual-richness/iterations/001/quality/hardening-gate.md` for precedence truthfulness, Windows VT fallback, render-budget stop-ship evidence, ANSI stripping with Unicode preservation, and closeout dashboard parity.
