---

### 2026-05-12T23:59:59+03:00: Deferred gap - Feature 001 iteration 011
**By:** Alon Fliess (via Copilot)
**Type:** deferred-gap
**Iteration Reference**: specs/001-specrew-product/iterations/011
**What:** Defer cleanup and historical-state verification of pre-existing gap in Feature 001, iteration 011 to a separate scoped feature. This gap is unrelated to Feature 014 handoff-format-scoping and is preserved without folding into Feature 014 closeout scope to maintain clean feature boundaries.
**Approving Human**: Alon Fliess
**Deferred On**: 2026-05-12
**Why:** Feature 014 Iteration 001 successfully delivered its bounded stop-vs-progress selector and additive soft-warning rollout (FR-001 through FR-007) without addressing unrelated historical cleanup. Recording this gap as an explicit tracked defer preserves the "no-gap" governance policy while protecting Feature 014's integrity.
**Follow-up Commitment:** Open a separate scoped feature to address Feature 001 iteration 011 state cleanup and verification.

---

## 2026-05-12T20:59:59Z — Canonical defer entry (Feature 014 iteration 001 closeout correction)

- **Decision ID**: defer-fr054-immutability-guardrail
- **Type**: defer
- **Affected Requirement**: FR-054
- **Affected Iteration**: specs\001-specrew-product\iterations\011
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-08T13:10:19Z
- **Next Action**: Address automated immutable-snapshot enforcement in a separate scoped feature after Feature 001 iteration 011 cleanup verification is complete
- **Rationale**: Historical cleanup during Feature 014 iteration 001 closeout. Iteration 011 focused on fixing legacy explicit-target validation regression without retroactively modifying closed iteration artifacts. FR-054 immutability enforcement (automated rejection of rewrites to closed iteration artifacts) remains unimplemented but this deferral preserves iteration boundaries and forward-only semantics.

---

### 2026-05-12T22:49:40+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Authorize the independent review boundary for Feature 014, handoff-format scoping, Iteration 001, the bounded stop-vs-progress selector and additive soft-warning rollout, against implementation commit `f02688f`; the reviewer must evaluate the canonical and iteration-specific concerns, run the five preserved handoff-governance regressions plus the two new soft-warning rules on compliant and violating fixtures, confirm the Feature 012 `human-handoff-id-context` scope-of-applicability update does not regress its existing detection, confirm repo-wide `validate-governance.ps1` stays green, emit `review.md` with an explicit verdict, dogfood the new format-scoping rules in the review output itself, repair any blocking gap in the current iteration instead of deferring it, and stop before retrospective for separate human sign-off on the review verdict.
**Why:** User request — captured for team memory


---

# Reviewer Decision: Feature 014 Iteration 001 Review

**Date**: 2026-05-12  
**By**: Reviewer  
**Type**: review-boundary

## Decision

Accept the review boundary for feature `014`, handoff format scoping, iteration `001`.

## Why It Matters

- The canonical concerns and all five iteration-specific concerns pass across implemented, enforced, observable, and documented lenses.
- The preserved five handoff-governance regressions, the two Feature `012`, descriptive references in handoffs, replay-path regressions, the bounded direct-validator stop-vs-progress matrix, and repo-wide `validate-governance.ps1 -ProjectPath .` all passed.
- The iteration artifacts are now truthful for the review boundary: `review.md` exists, `plan.md` is `reviewing`, and `state.md` no longer claims review is deferred.

## Evidence

- `specs\014-handoff-format-scoping\iterations\001\review.md`
- `specs\014-handoff-format-scoping\iterations\001\plan.md`
- `specs\014-handoff-format-scoping\iterations\001\state.md`
- `tests\integration\handoff-governance-jargon-response-test.ps1`
- `tests\integration\handoff-governance-plain-language-response-test.ps1`
- `tests\integration\handoff-governance-review-file-reference-test.ps1`
- `tests\integration\handoff-governance-descriptive-narration-test.ps1`
- `tests\integration\handoff-governance-descriptive-stop-message-test.ps1`
- `tests\integration\descriptive-reference-authored-prose.ps1`
- `tests\integration\descriptive-reference-excluded-surfaces.ps1`

## Next Action

Await Alon Fliess's separate authorization before opening retrospective or closeout work for feature `014`, iteration `001`.


---

# Spec Steward Inbox: Feature 013 Iteration 002 closeout boundary

**Date**: 2026-05-12  
**Feature**: `013-validator-hardening`  
**Iteration**: `002`

## Decision

Treat iteration `002` as truthfully closed once all six canonical iteration artifacts exist, accepted review `d7b2e42` is reflected in the hardening-gate verification fields, retrospective commit `947edff` is preserved, and the full closeout validation lane is green on the closeout tree.

## Alignment Guardrail

- Record iteration closure only at the iteration layer.
- Keep feature `013` open until a separate feature-closeout authorization is granted and recorded.
- Do not rewrite review or retrospective artifacts to narrate later lifecycle boundaries; update only the live closeout-facing artifacts.

## Authoritative References

- `specs/013-validator-hardening/spec.md`
- `specs/013-validator-hardening/iterations/002/state.md`
- `specs/013-validator-hardening/iterations/002/quality/hardening-gate.md`
- `specs/013-validator-hardening/iterations/002/retro.md`


### 2026-05-11T22:18:50+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Keep using the plain-language three-section handoff format, apply descriptive scope alongside numeric IDs in Squad-authored narration and stop messages during feature 012 iteration 001, require the reviewer to verify the two blocking concerns explicitly, run the full six-script validation lane before closeout, do not claim iteration closeout unless validation is green and git status is clean except for `.claude/settings.local.json`, and treat edits to `.github/agents/squad.agent.md` or `.squad/templates/squad.agent.md` as a session-restart trigger that requires an iteration-boundary commit and restart before closeout sign-off.
**Why:** User request — captured for team memory

# Decision: Feature 012 Iteration 001 Pre-Implementation Hardening Gate Sign-Off

**Decided**: 2026-05-11  
**Decision Owner**: Alon Fliess  
**Decision Type**: Feature Authorization  
**Status**: Effective Immediately  

## Decision Summary

**The pre-implementation hardening gate for Feature 012 (Descriptive-ID-Handoffs) Iteration 001 is SIGNED OFF and implementation is AUTHORIZED to proceed.**

Alon Fliess explicitly authorizes:
- Iteration 001 implementation (T001–T011, 8 story points)
- Iteration 001 review phase
- Iteration 001 retrospective and closeout

## Authorization Details

**Authorizer**: Alon Fliess  
**Review Class**: strongest-available  
**Review Date**: 2026-05-11  

**Authorization Statement (verbatim)**:  
"I sign off on the iteration 001 pre-implementation hardening gate for feature 012 descriptive-id-handoffs and I authorize iteration 001 implementation, review, retrospective, and closeout."

## Scope Locked

This decision locks the scope of Iteration 001 to the planned 11 tasks (T001–T011):

| Phase | Task Count | Tasks |
| --- | --- | --- |
| **Phase 1: Setup** | 2 | T001, T002 |
| **Phase 2: Foundational** | 2 | T003, T004 |
| **Phase 3: US1 (Narration)** | 4 | T005–T008 |
| **Phase 4: US2 (Stop Messages)** | 3 | T009–T011 |

Iteration 002 explicitly defers:
- Replay-path integration tests (T012–T014)
- Corpus seeding in `known-traps.md` (T015)
- Quality artifacts and hardening-gate updates (T016)
- Any blocking enforcement changes
- Any expansion to tool-rendered output

## Hardening Gate Assessment

The hardening gate assessment (see `specs/012-descriptive-id-handoffs/iterations/001/quality/hardening-gate.md`) confirms:

✓ All planning artifacts are complete  
✓ All pre-implementation concerns have been addressed or explicitly deferred  
✓ Feature 007 compatibility is preserved through regression testing  
✓ All user-facing guidance surfaces (prompts, checklists, contracts, startup guidance) are aligned  
✓ Worked examples are in scope for Iteration 001  
✓ The rule remains non-blocking per FR-008 and FR-009  

## Next Actions

1. **T001** (Pre-implementation baseline): Run existing handoff-governance regression tests and record baseline
2. **T002** (Boundary confirmation): Review feature boundary and two-iteration split  
3. **T003–T004** (Foundational): Extend validator rule and update coordinator contract
4. **T005–T011** (Parallel US1 and US2 work): Update guidance surfaces and validate

## Records Updated

- `specs/012-descriptive-id-handoffs/iterations/001/quality/hardening-gate.md`: Signed off by Alon Fliess
- `specs/012-descriptive-id-handoffs/iterations/001/plan.md`: Status changed to `implementation-authorized`
- `specs/012-descriptive-id-handoffs/iterations/001/state.md`: Current phase changed to `implementation-authorized`

---

**This decision is effective immediately. Implementation may begin with T001.**

## 2026-05-11-reviewer-feature012-iter001-review
### 2026-05-11T00:00:00Z: Reviewer decision - Iteration 001 review acceptance
**By:** Reviewer (Copilot)
**Type:** review-approval
**What:** Accept Iteration 001 review boundary for feature `012-descriptive-id-handoffs`.
**Why:** Both blocking concerns pass with runtime evidence (validator-detection-correctness via five integration tests, coordinator-prompt-rollout-fidelity via feature 007 regression suite preservation), all non-blocking concerns pass (guidance synchronization, bulk-list handling, tool-call scope exclusion), and iteration artifacts are truthful. T008 narration validation completed with new integration test script `tests\integration\handoff-governance-descriptive-narration-test.ps1`. All five handoff-governance tests passing. Readable-reference rule rolled out across validator, prompts, checklist, contract, and Squad startup surfaces with feature 007 compatibility preserved.
**Evidence:** `specs\012-descriptive-id-handoffs\iterations\001\review.md`, `specs\012-descriptive-id-handoffs\iterations\001\plan.md`, `specs\012-descriptive-id-handoffs\iterations\001\state.md`, `tests\integration\handoff-governance-descriptive-narration-test.ps1`
**Next Action:** Proceed to retrospective and closeout.

### 2026-05-12T00:17:00+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** For feature 012 iteration 002, scaffold and commit planning artifacts only; use the canonical state.md schema, draft the nine-column hardening gate with the specified blocking concerns, do not start implementation, do not scaffold iteration 003, and stop for fresh hardening-gate sign-off plus implementation authorization after planning.
**Why:** User request — captured for team memory

# Planner Decision Inbox: Feature 012 Iteration 002 Planning

**Date**: 2026-05-12  
**By**: Planner  
**Type**: planning-governance

## Decision

Feature `012-descriptive-id-handoffs` iteration `002` planning keeps the canonical Iteration 001 `state.md` metadata schema and applies the richer pre-sign-off hardening-gate convention with pending review metadata.

## Why It Matters

- The older scaffolded `state.md` shape omits canonical metadata fields and previously caused validator failures.
- The richer hardening-gate convention lets planning show `Overall Verdict: ready` while truthfully keeping review and runtime-evidence fields pending.
- Iteration 002 therefore treats the iteration-local hardening gate as a planning artifact now, leaving task `T016` focused on post-implementation feature-level quality follow-through evidence instead of recreating the pre-implementation gate.

## Expected Follow-Through

- Reuse the canonical state metadata headings exactly in future feature 012 iteration artifacts.
- Keep the five canonical hardening concerns first, then add feature-specific concerns in explicit, reviewed order.
- Preserve the distinction between planning-time gate creation and post-implementation evidence recording when task tables mention quality artifacts.

### 2026-05-12T01:24:17+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** For feature 012 iteration 002, record hardening-gate sign-off with the requested metadata repair (`error-handling-expectations` Blocking=false), then proceed with implementation, review, retrospective, and closeout for tasks T012-T020 while preserving replay-path evidence, corpus seeding, regression checks, the six-script closeout lane, readable-reference narration, and startup-guidance restart handling.
**Why:** User request — captured for team memory

# Implementer Decision Inbox: Feature 012 iteration 002 execution

## Decision

For feature 012, descriptive references in handoffs, iteration 002, the replay proof uses fixture-backed invocations of `extensions\specrew-speckit\validators\handoff-governance-validator.ps1` as the real governance review path, and the new tests assert on the validator's user-visible `status`, `findings`, and `summary` output instead of checking runtime state alone.

## Why

The signed iteration hardening gate called out replay-path integrity as a blocking concern, and the active known-traps corpus already requires user-facing handoff coverage to exercise the actual replay surface. Encoding the replay path in fixture manifests also makes the proof auditable in feature-level quality artifacts and keeps the lane aligned with the seeded corpus row.

# Reviewer Decision: Feature 012 Iteration 002 Review

**Date**: 2026-05-12  
**Reviewer**: Reviewer agent  
**Scope**: Feature `012`, descriptive references in handoffs, iteration `002`, the replay-path proof slice

## Decision

Accept the iteration `002` review boundary.

## Why

1. The replay tests use the real handoff-governance validator path and assert on user-visible output (`status`, `findings`, and `summary`) instead of internal state alone.
2. The `human-handoff-id-context` known-trap row is seeded in `.specrew\quality\known-traps.md` and aligned with the replay lane plus preserved regressions.
3. The preserved feature `007`, user-facing progress handoff, regression trio and the iteration `001`, readable-reference, regression pair all passed on the current tree, so the descriptive-reference proof slice remains additive and non-blocking.

## Evidence

- `specs\012-descriptive-id-handoffs\iterations\002\review.md`
- `specs\012-descriptive-id-handoffs\iterations\002\plan.md`
- `specs\012-descriptive-id-handoffs\iterations\002\state.md`
- `specs\012-descriptive-id-handoffs\iterations\002\quality\hardening-gate.md`
- `specs\012-descriptive-id-handoffs\quality\hardening-gate.md`

## Next Action

Proceed to the iteration `002` retrospective, then run closeout without reopening implementation unless contradictory runtime evidence appears.

# Retro Decision: Feature 012 Iteration 002

**Date**: 2026-05-12  
**By**: Retro Facilitator  
**Type**: process-governance

## Decision

Feature `012`, descriptive references in handoffs, iteration `002`, the replay-path and corpus follow-through slice, confirms four process baselines for future handoff-governance work.

## Why It Matters

1. User-facing governance rules need replay-path proof against the real validator output, not runtime-state-only checks.
2. A known-traps corpus row is durable only when the validation lane and follow-through artifacts are updated in the same slice.
3. Descriptive-reference proof must always preserve the feature `007` regression trio and the feature `012` iteration `001` readable-reference pair in the same lane.
4. Authored lifecycle prose is a legitimate dogfood surface for readable references and should keep pairing numeric IDs with descriptive scope.

## Expected Follow-Through

- Add a `Phase Baseline` table to iteration plans before review closes so retro scaffolding remains reusable.
- Keep replay-path assertions, corpus entries, validation-lane commands, and follow-through artifacts synchronized for future handoff-governance changes.
- Preserve the combined regression lane explicitly whenever descriptive-reference or related handoff-governance behavior changes.

# Reviewer Prep Rubric: Feature 013 Iteration 002

**Date**: 2026-05-12  
**Reviewer**: Reviewer  
**Feature**: `013-validator-hardening`  
**Iteration**: `002`  
**Scope**: Independent review preparation for the five blocking concerns in `specs/013-validator-hardening/iterations/002/quality/hardening-gate.md`

---

## Purpose

This note prepares the independent review boundary while implementation runs. It does **not** review code and does **not** issue a verdict. It translates the five blocking hardening-gate concerns into requirement-level evidence checks so the eventual review can fail fast on missing proof instead of retelling the implementation story.

---

## Acceptance Lenses the Eventual Review Must Apply

Each blocking concern must pass all applicable lenses below:

1. **Implemented** — the intended code or artifact change exists in the named path.
2. **Enforced** — the real validator or restart flow rejects/permits the right cases mechanically.
3. **Observable** — user-visible output proves the rule, including structured FAIL content where required.
4. **Documented / Traceable** — plan, quickstart, corpus, and iteration artifacts cite the requirement and test evidence truthfully.
5. **Regression-safe** — iteration 001 behavior and the additive CLI surface remain intact.

If any lens fails for a blocking concern, the review verdict is `needs-work`.

---

## Blocking Concern 1: Over-Claim Detection Correctness

**Hardening-Gate Concern**: `over-claim-detection-correctness`  
**Requirement Lens**: FR-004, FR-005, FR-008, FR-010; TG-004, TG-008; SC-004, SC-005  
**Primary Tasks**: T018, T019, T020, T029

### What Must Be True

- Closed-status iterations without complete closeout evidence fail mechanically.
- Required evidence includes accepted `review.md`, `retro.md`, and post-implementation verification in `quality/hardening-gate.md` for required concerns.
- Dirty-tree enforcement is limited to the iteration directory's canonical artifacts.
- `.squad/decisions.md` and `.squad/identity/now.md` may inform evidence but must not fail the dirty-tree check by themselves.
- FAIL output stays structured and names the missing evidence or changed files without surfacing raw PowerShell exceptions.

### Required Evidence

1. **Fixture Coverage**
   - `tests\integration\fixtures\013-validator-hardening\overclaim\`
   - Must include: missing retro, missing review, non-accepted review, pending post-implementation hardening evidence, clean pass case, dirty iteration-directory case, repo-level-only change case.

2. **Replay Assertions**
   - `tests\integration\validator-hardening-iteration2.ps1`
   - Must prove: closed-status detection, each required evidence failure mode, iteration-directory-only `git status --porcelain` filtering, zero raw exceptions.

3. **Implementation Inspection**
   - `extensions\specrew-speckit\scripts\shared-governance.ps1`
   - `extensions\specrew-speckit\scripts\validate-governance.ps1`
   - Must show: closeout-evidence checks, scoped dirty-tree filtering, explicit evidence-only treatment of `.squad/decisions.md` and `.squad/identity/now.md`, structured FAIL generation.

4. **Closeout Lane Proof**
   - `tests\integration\validator-hardening-iteration2.ps1`
   - `extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`
   - Must confirm the rule works in both seeded fixtures and the live repo lane.

### Failure Criteria

- Any over-claim fixture passes when it should fail.
- Repo-level evidence files alone trigger dirty-tree failure.
- A closed-status iteration missing review, retro, or hardening verification is accepted.
- Any failure mode produces raw exception text instead of structured FAIL output.

---

## Blocking Concern 2: Approval-Reuse Detection Correctness

**Hardening-Gate Concern**: `approval-reuse-detection-correctness`  
**Requirement Lens**: FR-003, FR-005, FR-008; TG-003, TG-008; SC-003, SC-005  
**Primary Tasks**: T014, T015, T016, T029

### What Must Be True

- Sibling iterations with duplicated approval evidence quotes in `plan.md` or `state.md` fail mechanically.
- Matching is based on whitespace normalization plus markdown-emphasis stripping only.
- Distinct quotes do not false-match after normalization.
- Reuse is allowed only when an explicit blanket multi-iteration authorization scope is recorded.
- FAIL output names both iterations and the duplicated quote in structured form.

### Required Evidence

1. **Fixture Coverage**
   - `tests\integration\fixtures\013-validator-hardening\approval-reuse\`
   - Must include: byte-identical duplicates, whitespace-drift duplicates, emphasis-variant duplicates, distinct quotes that must pass, explicit blanket-scope pass cases, unlabeled reuse fail cases.

2. **Replay Assertions**
   - `tests\integration\validator-hardening-iteration2.ps1`
   - Must prove: duplicate detection, normalization behavior, blanket-scope exemption, structured FAIL output, no raw exceptions.

3. **Implementation Inspection**
   - `extensions\specrew-speckit\scripts\shared-governance.ps1`
   - `extensions\specrew-speckit\scripts\validate-governance.ps1`
   - Must show: sibling-iteration collection, normalization logic, explicit-scope exemption handling, structured FAIL naming both iterations.

### Failure Criteria

- Duplicate approval evidence passes without explicit blanket scope.
- Distinct quotes are rejected because normalization over-matches.
- Blanket-scope cases still fail.
- FAIL output omits one of the two iterations or the duplicated quote.

---

## Blocking Concern 3: Bookkeeping Classifier Accuracy

**Hardening-Gate Concern**: `bookkeeping-classifier-accuracy`  
**Requirement Lens**: FR-006, FR-010, FR-005; TG-005, TG-007; SC-006, SC-005  
**Primary Tasks**: T022, T023, T024, T025, T026

### What Must Be True

- `.github/copilot-instructions.md` changes limited to timestamp, `## Active Technologies`, or `## Recent Changes` classify as `bookkeeping`.
- Any change outside those areas classifies as `behavior`.
- The classifier is implemented as reusable helper logic consumed by `scripts\specrew-start.ps1`, not validator-only logic.
- Bookkeeping-only changes do not trigger restart guidance; behavior changes do.
- Any validator-side reuse remains additive and does not change existing command surface or exit-code expectations.

### Required Evidence

1. **Fixture Coverage**
   - `tests\integration\fixtures\013-validator-hardening\copilot-instructions\`
   - Must include: timestamp-only, Active Technologies only, Recent Changes only, mixed bookkeeping-only, mixed bookkeeping+behavior, behavior-only edits, manual edits inside bookkeeping sections that must still classify correctly.

2. **Classifier-Only Replay**
   - `tests\integration\validator-hardening-iteration2.ps1 -ClassifierOnly`
   - Must prove the expected bookkeeping vs. behavior outcomes deterministically.

3. **Full Replay + Compatibility**
   - `tests\integration\validator-hardening-iteration2.ps1`
   - Must prove classifier participation does not alter validator CLI shape, PASS/FAIL format, or exit-code expectations.

4. **Implementation Inspection**
   - `extensions\specrew-speckit\scripts\Test-CopilotInstructionsChangeType.ps1`
   - `scripts\specrew-start.ps1`
   - `extensions\specrew-speckit\scripts\validate-governance.ps1`
   - Must show: helper ownership in the reusable script, consumption by `specrew-start.ps1`, additive-only validator-side reuse.

5. **Recorded Evidence**
   - `specs\013-validator-hardening\quickstart.md`
   - Must capture the classifier proof named in T026 after the commands pass.

### Failure Criteria

- Any bookkeeping-only diff is classified as behavior.
- Any behavior-affecting diff is classified as bookkeeping.
- Restart guidance still fires for bookkeeping-only changes.
- The helper exists only inside the validator and is not consumed by `specrew-start.ps1`.
- Classifier integration changes validator CLI or exit-code compatibility.

---

## Blocking Concern 4: Corpus Graduation Completeness

**Hardening-Gate Concern**: `corpus-graduation-completeness`  
**Requirement Lens**: FR-007; TG-003, TG-004, TG-006; SC-007  
**Primary Tasks**: T017, T021, T027, T028, T029

### What Must Be True

- `.specrew/quality/known-traps.md` marks the four relevant rows as validator-enforced:
  - per-iteration approval evidence reuse
  - over-claim
  - canonical iteration schema
  - canonical concern enumeration
- Each graduated row cites the implementing requirement(s), proving test(s), and implementation file(s).
- Stale guidance text does not remain after graduation.
- Feature documentation truthfully references the graduated enforcement state.

### Required Evidence

1. **Corpus Inspection**
   - `.specrew\quality\known-traps.md`
   - Must show all four rows marked validator-enforced with non-placeholder citations.

2. **Traceability Inspection**
   - Approval-reuse row must cite FR-003 and `tests\integration\validator-hardening-iteration2.ps1`.
   - Over-claim row must cite FR-004 and `tests\integration\validator-hardening-iteration2.ps1`.
   - Canonical-schema / canonical-concern rows must cite FR-001 / FR-002 and `tests\integration\validator-hardening-iteration1.ps1`.

3. **Documentation Truth**
   - `specs\013-validator-hardening\plan.md`
   - `specs\013-validator-hardening\quickstart.md`
   - `specs\013-validator-hardening\quality\trap-reapplication.md`
   - Must reflect the final enforcement/citation state without claiming closure before proof exists.

### Failure Criteria

- Any required row remains ungraduated at review time.
- Citations point to wrong or nonexistent requirement/test paths.
- Placeholder or stale pre-enforcement guidance remains.
- Feature docs claim graduation without the corpus proving it.

---

## Blocking Concern 5: Regression Preservation

**Hardening-Gate Concern**: `regression-preservation`  
**Requirement Lens**: FR-010 plus retained FR-001, FR-002, FR-005 behavior; TG-007; SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-007  
**Primary Tasks**: T023, T026, T029

### What Must Be True

- Iteration 002 changes do not break iteration 001 canonical-schema enforcement, canonical-concern enforcement, or structured FAIL behavior.
- `validate-governance.ps1` remains additive: same command surface, argument expectations, exit-code behavior, and PASS/FAIL compatibility.
- The full closeout lane passes on the final tree.

### Required Evidence

1. **Iteration 001 Regression Lane**
   - `tests\integration\validator-hardening-iteration1.ps1`
   - Must stay green after iteration 002 lands.

2. **Feature Closeout Lane**
   - `tests\integration\quality-profile-foundation.ps1`
   - `tests\integration\hardening-gate-contract.ps1`
   - `tests\integration\quality-evidence-governance.ps1`
   - `tests\integration\validation-contract-lane.ps1`
   - `tests\integration\project-path-resolution-regression.ps1`
   - `tests\integration\validator-hardening-iteration1.ps1`
   - `tests\integration\validator-hardening-iteration2.ps1`
   - `extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`

3. **Diff Audit**
   - Final review must inspect the touched validator, classifier, fixture, corpus, and documentation paths named by T029.
   - Must confirm the changes remain within the authorized iteration-002 scope.

### Failure Criteria

- Any iteration 001 rule regresses.
- The validator surface changes incompatibly.
- Repo-wide validator pass breaks on the final tree.
- Final diff contains out-of-scope behavior beyond iteration 002 authorization.

---

## Review Execution Checklist

Before issuing a verdict, the eventual reviewer must confirm all of the following:

- [ ] T014-T029 are marked complete only where corresponding evidence exists.
- [ ] `specs\013-validator-hardening\iterations\002\state.md` and `plan.md` tell the same lifecycle truth as the review boundary.
- [ ] `specs\013-validator-hardening\iterations\002\quality\hardening-gate.md` has post-implementation verification populated truthfully.
- [ ] All five blocking concerns above have passed their required evidence checks.
- [ ] Structured FAIL output remains the user-visible failure mode for new rejection paths.
- [ ] The full closeout lane from T029 passes on the review tree.

---

## Verdict Translation

| Outcome | Verdict | Next Move |
| --- | --- | --- |
| All five blocking concerns pass and artifact truth is coherent | `pass` | Proceed to retrospective and closeout |
| Any blocking concern fails or required evidence is missing | `needs-work` | Return to implementation with a named gap ledger |
| Scope/authority truth is contradictory or spec authority is insufficient | `blocked` | Escalate to Alon Fliess before closure |

---

## Notes

- This is review preparation only; it is not an implementation review and not a release verdict.
- The hardening gate remains the authority for which concerns are blocking; this note supplies the evidence bar the eventual review must enforce.
- No soft acceptance: a known gap must be fixed now or explicitly deferred with approval and recorded evidence.

# Retro Facilitator Inbox: Feature 013 iteration 002 retrospective

**Date**: 2026-05-12  
**Feature**: `013-validator-hardening`  
**Iteration**: `002`

## Decision

Treat three lessons from the accepted iteration-002 review as standing process guidance for future planning and retro work:

1. `/speckit.plan`-generated changes inside `.github/copilot-instructions.md` timestamp, `## Active Technologies`, and `## Recent Changes` sections are bookkeeping-only unless the diff escapes those bounded sections.
2. Any dirty-tree blocker change must prove both sides of the rule: one fixture where canonical iteration artifacts fail and one fixture where repo-level evidence-only traces pass.
3. `.claude/settings.local.json` and similar workstation-local files are lifecycle-boundary noise unless the iteration explicitly changes their behavior and says so.

## Why

Feature 013 iteration 002 hit all three patterns in a bounded way: planner-output drift had to be repaired before restart guidance stayed low-noise, the lockout-chain false-positive dirt precedent had to be encoded into the over-claim replay path, and commit `c3ac63a` carried local config noise that did not change governance truth. Recording the rule now keeps future retros from rediscovering the same distinctions as if they were new.

## Next Planning Application

- When a slice touches restart guidance, state the bookkeeping-only sections up front and require replay coverage before approval.
- When a slice touches closure truth or dirt filtering, require the evidence-only pass fixture in the plan, not just the dirty fail fixture.
- When a lifecycle commit includes local noise, either isolate it or label it explicitly so review/retro/closeout boundaries stay readable.


## 2026-05-11-implementer-iter005-implementation
### 2026-05-10T22:12:33Z: Iteration 005 implementation boundary
**By:** Implementer (Copilot)
**Type:** implementation-scope
**What:** Keep Polish execution aligned to the authorized six-command validation lane and verify any user-facing replay example against real reviewer replay output before documenting it.
**Why:** The iteration plan and hardening-gate authorization both narrowed T027 to a six-command lane, so implementation should not silently reintroduce extra validation commands. Reviewer-facing visibility text is easy to drift if copied by hand; replay examples in docs should come from `scaffold-reviewer-artifacts.ps1` / `specrew-review.ps1` output instead.
**Evidence:** Validation lane passed with: `tests\integration\reviewer-regression-event.ps1`, `tests\integration\lockout-chain-cap.ps1`, `tests\integration\reviewer-regression-ledger.ps1`, `tests\integration\reviewer-regression-withdrawal.ps1`, `tests\integration\carry-forward-closed-iteration.ps1`, and `extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`. Documentation examples in `docs\user-guide.md` were checked against live output from `extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1` and `scripts\specrew.ps1 review` on the lockout-cap fixture.

## 2026-05-11-reviewer-iter005-review
### 2026-05-11T00:00:00Z: Reviewer decision - Iteration 005 review acceptance
**By:** Reviewer (Copilot)
**Type:** review-approval
**What:** Accept Iteration 005 review boundary for `008-reviewer-escalation-symmetry`.
**Why:** T027 passed on the authorized six-command lane only (no `gap-governance.ps1`), and T028 documentation plus the lockout-cap visibility example were verified against actual `scaffold-reviewer-artifacts.ps1` and `specrew review` replay output.
**Evidence:** `specs\008-reviewer-escalation-symmetry\iterations\005\review.md`, `specs\008-reviewer-escalation-symmetry\iterations\005\plan.md`, `specs\008-reviewer-escalation-symmetry\iterations\005\state.md`
**Next Action:** Run the Iteration 005 retrospective, then perform closeout without reopening implementation unless new contradictory runtime evidence appears.

## 2026-05-11-retro-facilitator-iter005-retro
### 2026-05-11T00:00:00Z: Team decision - Iteration 005 retrospective findings
**By:** Retro Facilitator (Copilot)
**Type:** process-governance
**What:** Iteration 005 retrospective extracted three core governance lessons and formalized them as enforced baselines for future hardening gates.

### Core Findings

**1. Richer Hardening-Gate Schema is Preferred Baseline**
- Iteration 005 hardening-gate was authored with Overall Verdict `ready` and explicit pending fields (`Reviewed By`, `Reviewed At` marked pending). At sign-off, governance fields updated atomically without blocking.
- This schema prevents approval-inheritance drift by signaling planning readiness while explicitly showing which governance fields remain pending.
- **Action:** Spec Steward (Alon Fliess) will update Spec 005 Phase 2 hardening-gate enforcement to require this schema for all new iterations.

**2. Approval Scope Must Tether to Active Iteration Slice**
- Iteration 004 review identified approval-recording gaps where scope was inherited from prior cycles without explicit revalidation.
- Iteration 005 corrected this by having Alon Fliess sign off on 2026-05-11 with explicit scope refresh: Polish slice (T027–T028, 3 story_points).
- **Action:** Encode this as a validation rule in Spec 008 governance-trap corpus and propagate to feature portfolio approval-gate checklists.

**3. Staged Validation Discipline Prevents Late-Found Gaps**
- Iteration 005 applied this discipline explicitly: T027 ran the authorized six-command validation lane; T028 verified documentation against live `scaffold-reviewer-artifacts.ps1` and `specrew review` output.
- Result: zero rework, zero review findings, zero reviewer-regression events.
- **Action:** Continue enforcing replay-path coverage mandate in all Polish and handoff-facing iterations.

## 2026-05-11-spec-steward-iter005-governance
### 2026-05-11T00:00:00Z: Spec steward decision - Feature 008 Iteration 005 pre-sign-off governance schema
**By:** Spec Steward (Copilot)
**Type:** governance-pattern
**What:** Accepted the pre-sign-off hardening-gate schema convention established by iteration 005 sign-off protocol. This convention formalizes the lifecycle transition from planning-phase readiness to signed-off authorization.

**Governance Pattern Formalized:**
- **Pre-Sign-Off State:** Overall Verdict: `ready`, Pending metadata fields explicitly marked, Evidence Basis: `planning-time-analysis`, Runtime Evidence Status: `pending-post-implementation`
- **Post-Sign-Off State:** Overall Verdict updated to reflect signed status, Reviewed By/Reviewed At updated with actual values, Sign-Off Evidence section added

**Two-Artifact Traceability:** When human approval changes authorized scope (e.g., reducing validation commands):
1. Update plan.md task definition with new scope
2. Update hardening-gate concern evidence to name exact authorized command set
3. Re-run validation to confirm both artifacts align
4. Record scope change in Sign-Off Evidence section

**Known-Traps Seeded:**
1. `pre-sign-off-schema-convention-drift` — Detects hardening gates losing pending-metadata notation
2. `validation-lane-concern-scope-drift` — Detects when concern documentation and plan.md task definitions diverge

**Applicability:** This pattern is baseline for pre-implementation hardening-gate sign-off workflows across all features. Future iteration 005+ slices follow this schema unless explicitly overridden.

## 2026-05-11-planner-iter005-approval-boundary-repair
### 2026-05-11T00:00:00Z: Planner decision - Iteration 005 approval-recording boundary repair
**By:** Planner (Copilot)
**Type:** governance-repair
**What:** Reviewer flagged four concrete governance gaps in Iteration 005's approval-recording boundary. All four gaps have been repaired.

**Repairs Applied:**
1. **state.md Sign-Off Status Alignment:** Updated `Hardening-Gate Sign-Off` to ✅ **SIGNED** (2026-05-11) and `Implementation Authorization` to ✅ **AUTHORIZED** (2026-05-11)
2. **plan.md Distinct Implementation Authorization Record:** Added new `Implementation Authorization` section (hardening-gate-triggered authorization to implement, 2026-05-11), distinct from planning-level approval (2026-05-10)
3. **hardening-gate.md Sign-Off Readiness Concern Count:** Updated concern count from four to six polish-specific concerns to match Concern Review table
4. **hardening-gate.md Approval Ref:** Preserved `Approval Ref: —` per explicit human direction, documented as exception to governance trap

**Verification:** Ran governance validation script — ✅ **PASS** — All governance checks passed.

**Learnings for Future Iterations:**
1. Distinguish planning-level approval (to prepare hardening gate) from hardening-gate-triggered implementation authorization (to execute after gate sign-off)
2. Validate concern counts match Concern Review table row counts
3. Governance traps document best practices but do not supersede explicit direction from approval authorities

## 2026-05-11-planner-iter005-retro-repair
### 2026-05-11T00:00:00Z: Planner decision - Iteration 005 retrospective truthfulness boundary repair
**By:** Planner (Copilot)
**Type:** governance-repair
**What:** Iteration 005 retrospective failed independent audit gate because it mischaracterized governance friction by framing the approval-recording boundary rejection and repair cycle as a "success story" while claiming zero friction occurred.

**Changes Made:**
1. **Retrospective (retro.md):** Separated friction from resolution with explicit "Friction Encountered and Resolved" section; corrected Approval Ref claim; reframed "What Didn't Go Well"
2. **State (state.md):** Updated Current Phase to `retrospective-in-progress`; updated Iteration Status to clarify retrospective repair in progress

**Governance Principle Codified:** Honest retrospectives must name friction explicitly before explaining how it was resolved. Narratives that omit friction events—even to praise remediation—fail the truthfulness boundary.

**Approval Status:** Retrospective truthfulness repair recorded. Closeout may proceed after human re-review confirms repaired retrospective satisfies truthfulness boundary. Retro facilitator locked out of further revisions.

## 2026-05-11-retro-facilitator-iter002-amendment
### 2026-05-10T00:00:00Z: Retro facilitator decision - Iteration 002 retrospective amendment
**By:** Retro Facilitator (Copilot)
**Type:** process-governance
**What:** Iteration 002 retrospective amended to capture three real governance lessons.

**Decisions Captured:**
1. **Approval Scope Must Be Tethered to Active Iteration Slice:** When a plan is resliced or deferred, approval scope must be refreshed. Do not reuse approval evidence from prior iteration boundaries.
2. **Human-Direction Hold Messages Must Follow Three-Section Rule:** All hold messages must include: (1) Why we stopped, (2) What you can do, (3) Who to escalate to.
3. **Startup-Loaded Configuration Requires Iteration-Boundary Commits:** Files loaded at session startup (`.github/agents/squad.agent.md`, `.specify/extensions/specrew-speckit/squad-templates/*`) require explicit iteration-boundary commits and session restart via `specrew-start.ps1` to take effect.

**Team Action Items:**
- Planner: Update Iteration 003 plan approval section to include explicit scope certification
- Coordinator handoff maintainer: Ensure all future human-direction holds follow the three-section rule
- Review-operations maintainer: Document startup-loaded file boundaries in the next planning ceremony

## 2026-05-11-reviewer-iter005-retro-reaudit
### 2026-05-11T00:00:00Z: Reviewer decision - Iteration 005 retrospective truthfulness re-audit
**By:** Reviewer (Copilot)
**Type:** review-audit
**What:** Re-audit of Iteration 005 retrospective repair confirmed it satisfies all three truthfulness boundaries.

**Audit Result:** ✅ **APPROVED**

**Findings:**

## 2026-05-11-runtime-evidence-feature011-iter002-signoff
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 hardening-gate sign-off routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Hardening-gate sign-off recording and planning -> execution boundary update for feature `011-specrew-start-conditional-pause` iteration 002
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-boundary-repair
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 execution-boundary truthfulness repair routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Repair stale pre-sign-off wording in feature `011-specrew-start-conditional-pause` iteration 002 execution-boundary artifacts after sign-off was recorded
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-state-tail-repair
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 state tail repair routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Repair the final stale pre-sign-off line remaining in `state.md` after execution-boundary updates
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-implementation
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 implementation routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Execute feature `011-specrew-start-conditional-pause` iteration 002 tasks T043-T056
**Requested Agent:** Implementer
**Actual Agent:** Implementer
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-review-prep
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 review-prep routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Prepare the independent review checklist for the three blocking concerns before implementation lands
**Requested Agent:** Reviewer
**Actual Agent:** Reviewer
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-review
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 review routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Independently review feature `011-specrew-start-conditional-pause` iteration 002 implementation against the approved blocking concerns and issue the review verdict
**Requested Agent:** Reviewer
**Actual Agent:** Reviewer
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-retro
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 retrospective routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Facilitate the retrospective for feature `011-specrew-start-conditional-pause` iteration 002 after accepted review
**Requested Agent:** Retro Facilitator
**Actual Agent:** Retro Facilitator
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-closeout
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 closeout routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Complete feature `011-specrew-start-conditional-pause` iteration 002 closeout, including T057 documentation updates, staged validation lane, and closure boundary
**Requested Agent:** Implementer
**Actual Agent:** Implementer
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-feature-closeout
### 2026-05-11T18:36:08+03:00: Runtime evidence - Feature 011 feature-level closeout routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Record the feature-level closure for `011-specrew-start-conditional-pause`, refresh stale focus pointers, rerun the six-script lane, and commit the feature closure boundary
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-tasks
### 2026-05-11T19:26:29+03:00: Runtime evidence - Feature 012 task generation routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Generate `tasks.md` for feature `012-descriptive-id-handoffs` from the approved spec and plan, then continue to the post-task governance readiness check
**Requested Agent:** Planner
**Actual Agent:** Planner
**Model:** gpt-5.4
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-after-tasks
### 2026-05-11T19:26:29+03:00: Runtime evidence - Feature 012 after-tasks governance routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Run the post-task governance validation for `012-descriptive-id-handoffs` immediately after task generation
**Requested Agent:** Planner
**Actual Agent:** Planner
**Model:** gpt-5.4
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-authorization-boundary-repair
### 2026-05-11T19:50:26+03:00: Runtime evidence - Feature 012 iteration 001 authorization-boundary repair routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Commit the generated task backlog boundary, scaffold iteration 001 planning artifacts with a canonical pre-implementation hardening gate, refine the feature plan's iteration-scaffolding constraint, and stop for fresh sign-off plus implementation authorization
**Requested Agent:** Planner
**Actual Agent:** Planner
**Model:** claude-haiku-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-state-schema-repair
### 2026-05-11T20:06:05+03:00: Runtime evidence - Feature 012 iteration 001 state-schema repair routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Align iteration `001` state metadata to the canonical schema, rerun governance validation until the crash is gone and zero FAIL lines remain, then seed the canonical state-schema trap row
**Requested Agent:** Planner
**Actual Agent:** Planner
**Model:** claude-haiku-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-before-implement
### 2026-05-11T22:18:50+03:00: Runtime evidence - Feature 012 iteration 001 before-implement routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Record the human hardening-gate sign-off and implementation authorization for feature `012-descriptive-id-handoffs` iteration `001`, then run the pre-implementation governance gate
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-haiku-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-review
### 2026-05-11T23:20:48+03:00: Runtime evidence - Feature 012 iteration 001 review routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Run T008 narration validation for feature `012-descriptive-id-handoffs` iteration `001`, scaffold the missing review artifact, verify the blocking concerns, and record the review verdict for the readable-reference rollout
**Requested Agent:** Reviewer
**Actual Agent:** Reviewer
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-review-followthrough
### 2026-05-11T23:20:48+03:00: Runtime evidence - Feature 012 iteration 001 review follow-through routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Convert the iteration `001` hardening gate to post-implementation recorded state and normalize the review-phase artifact fields so retrospective can start cleanly
**Requested Agent:** Reviewer
**Actual Agent:** Reviewer
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-retro
### 2026-05-11T23:55:00+03:00: Runtime evidence - Feature 012 iteration 001 retrospective routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Author the iteration `001` retrospective for the readable-reference rollout, update lifecycle artifacts for the retro boundary, and keep closeout as the next step
**Requested Agent:** Retro Facilitator
**Actual Agent:** Retro Facilitator
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-12-runtime-evidence-feature012-iter002-planning
### 2026-05-12T00:22:00+03:00: Runtime evidence - Feature 012 iteration 002 planning routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Scaffold iteration `002`, the replay-path integration and corpus follow-through planning slice, validate governance, and commit the planning boundary without starting implementation
**Requested Agent:** Planner
**Actual Agent:** Planner
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-specify
### 2026-05-11T18:39:12+03:00: Runtime evidence - Feature 012 opening routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Open the next approved feature from `C:\Temp\squad-descriptive-references.md` and establish the repository feature pointer for descriptive-reference validation work
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-clarify
### 2026-05-11T18:41:37+03:00: Runtime evidence - Feature 012 clarification routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Tighten the descriptive-reference spec around the numeric-ID threshold, grouped-list handling, and exclusion of tool-rendered output from the detector
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-plan
### 2026-05-11T18:44:02+03:00: Runtime evidence - Feature 012 planning routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Build the feature plan for descriptive-reference handoffs, including iteration scoping across coordinator guidance and later governance/test enforcement
**Requested Agent:** Planner
**Actual Agent:** Planner
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none
1. **Rejection/Repair Cycle — No Smoothing Detected:** Retrospective now contains explicit "Friction Encountered and Resolved" section. New friction section isolates rejection event and names it explicitly before explaining resolution.
2. **Approval Ref Traceability — Accurate Language Confirmed:** Language now correctly states "Approval Ref remains `—`" and grounds traceability in timestamp records per governance discipline.
3. **State.md Retrospective Status — Consistent Fields:** All three status fields (Current Phase, Iteration Status, Retrospective Verdict) tell the same story: review complete, retrospective repaired, closure awaits re-approval.

**Governance Principles Confirmed:**
1. Honest friction naming — retro explicitly names rejection and repair cycle as governance correction
2. Approval Ref exception is auditable — decision inbox entry documents rationale
3. Staged validation discipline preserved — distinct positive item separate from friction event

**Approval Status:** Repaired retrospective passes truthfulness boundary. Iteration 005 closeout may proceed.

## 2026-05-10T12-05-33Z-copilot-directive
### 2026-05-10T12:05:33+03:00: User directive - Final user-facing response format
**By:** Alon Fliess (via Copilot)
**Type:** process-directive
**What:** Final user-facing responses must lead with plain English in three named sections: What I just did / Why I stopped / What I need from you. Governance vocabulary should appear only as cross-references.
**Why:** User request — captured for team memory

## 2026-05-11-runtime-evidence-feature007-iter002-implementation
### 2026-05-11T04:10:06+03:00: Runtime evidence - Feature 007 Iteration 002 implementation
**By:** Squad (Coordinator)
**Type:** implementation-evidence
**What:** Iteration 002 implementation completed T007-T010 for feature `007-user-facing-progress-handoff`: the soft validator landed, two validator integration tests landed, the validation lane was registered, and the review-file navigation rule was rolled into all durable guidance surfaces.
**Why:** Preserve the implementation boundary, the approval evidence (`Approved, continue implementation.`), the validation results, and the new session-restart requirement triggered by updating `.github/agents/squad.agent.md`.
**Evidence:** `extensions\specrew-speckit\validators\handoff-governance-validator.ps1`; `tests\integration\handoff-governance-jargon-response-test.ps1`; `tests\integration\handoff-governance-plain-language-response-test.ps1`; `extensions\specrew-speckit\governance\validation-lane.md`; `tests\integration\validation-contract-lane.ps1`; `specs\007-user-facing-progress-handoff\iterations\002\quality\hardening-gate.md`
**Validation:** `tests\integration\validation-contract-lane.ps1` ✅ PASS; `extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\007-user-facing-progress-handoff\iterations\002` ✅ PASS; empty-input validator invocation exited cleanly with soft warnings; repeated identical validator runs produced identical output.
**Next Action:** Start a fresh session before Iteration 002 review so the updated `.github/agents/squad.agent.md` coordinator-response guidance is active.

# Decision Ledger

## 2026-05-09-runtime-evidence-009
### 2026-05-09T22:09:00+03:00: Feature 009 lifecycle and repair evidence
**By:** Alon Fliess (via Copilot)
**What:** Feature `specs/009-project-path-resolution` was run through specify, clarify, planning, tasks, hardening-gate approval, implementation, reviewer repair, and final validation. The final outcome included audited path-resolution fixes across entry-point and internal scripts, a deterministic regression lane, static anti-pattern coverage, known-traps seeding, trap reapplication evidence, and a return of `.specify\feature.json` to `specs/008-reviewer-escalation-symmetry` after closure.
**Why:** Preserve a compact lifecycle record that feature 009 completed ahead of feature 008, including the reviewer-enforced repair cycle that expanded runtime coverage and closed the remaining audit gaps.

## copilot-decision-2026-05-07T22-12-30+03-00
### 2026-05-07T22:12:30+03:00: Clarify skip rationale for 005 Phase 1
**By:** Alon Fliess (via Copilot)
**What:** Resume `specs/005-stack-aware-quality-bar` at Phase 1 planning without re-running clarify because the hardened spec is unchanged, reviewer-approved, and materially complete for phase-scoped planning.
**Why:** Existing feature resume — proceed through the formal lifecycle with plan/tasks/before-implement for the first slice.


## 2026-05-08-spec-005-clarifications-applied
# Decision: Spec 005 Clarifications Applied - Planning Ready

**Date**: 2026-05-08  
**Type**: spec-clarification  
**Affected Feature**: specs/005-stack-aware-quality-bar  
**Requestor**: Alon Fliess  
**Status**: Applied

## Context

Six critical clarifications were resolved through interactive clarification workflow for spec 005 (Stack-Aware Quality Bar). These decisions remove ambiguity around implementation mechanisms, approval flows, baseline comparisons, and trap management workflows.

## Decisions Applied

1. **Lens Checklist Format**: Versioned lens checklists use Markdown tables (FR-022 updated)
2. **Reasoning Class Binding**: Required bug-hunter lenses hard-bind to the strongest available reviewer/reasoning class by default; lower-tier execution requires an explicit recorded override (FR-038, FR-039 updated)
3. **Hardening-Gate Approval Authority**: Deferrals for unresolved security, resilience, or operational concerns require human developer approval; agents may recommend only (FR-033 updated)
4. **Quality-Drift Baseline Order**: Compares against the active feature's planned quality baseline first, then prior iteration baselines when they exist (FR-042 updated)
5. **Technology-Specific Best Practices**: The quality bar enforces technology-specific software quality best practices even when the human developer lacks deep quality expertise (new FR-003a added)
6. **Trap Promotion Workflow**: After human approval, a newly found trap is added to the known-traps corpus immediately and may then be promoted into a checklist item or mechanical check in the same or next slice (FR-036 updated)

## Rationale

These clarifications resolve critical implementation ambiguities that would otherwise block planning:

- **Format standardization** (Markdown tables) enables consistent tooling and human review
- **Hard binding to strongest reasoning class** prevents quality regressions from model-tier downgrades
- **Human approval gates** for critical deferrals prevent agents from bypassing security/resilience concerns
- **Baseline comparison order** provides clear precedence for quality-drift detection
- **Technology-specific enforcement** ensures quality doesn't degrade when developers work outside their expertise zones
- **Immediate trap addition** with optional promotion creates a clear learning workflow without blocking current work

## Implications

- **Planning Readiness**: Spec 005 is now planning-ready with all critical ambiguities resolved
- **Implementation Clarity**: Format, approval, and workflow decisions provide concrete implementation targets
- **Quality Consistency**: Hard-binding and technology-specific enforcement raise the quality floor
- **Governance Traceability**: Human approval requirements and immediate trap addition support auditable quality governance

## Affected Artifacts

- `specs/005-stack-aware-quality-bar/spec.md`: Added Clarifications section, updated FR-022, FR-033, FR-038, FR-039, FR-042, added FR-003a, updated FR-036, updated TG-001, updated Requirement Ownership table, updated Key Entities, updated Assumptions

## Next Steps

1. Proceed to `/speckit.plan` to generate implementation plan artifacts

## 2026-05-11-runtime-evidence-feature007-iter001-review
### 2026-05-11T03:01:19+03:00: Runtime evidence - Feature 007 Iteration 001 review routing
**By:** Squad (Coordinator)
**Role / Work Item:** Reviewer - review iteration `specs/007-user-facing-progress-handoff/iterations/001`
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** claude-sonnet-4.5
**Status:** fallback
**Fallback Reason:** preferred agent `claude` is not enabled in the delegated routing plan; routed through Copilot task execution

## 2026-05-11-runtime-evidence-feature007-iter001-retro
### 2026-05-11T03:01:19+03:00: Runtime evidence - Feature 007 Iteration 001 retrospective routing
**By:** Squad (Coordinator)
**Role / Work Item:** Retro Facilitator - retrospective for `specs/007-user-facing-progress-handoff/iterations/001`
**Requested Agent:** copilot
**Actual Agent:** copilot
**Model ID:** claude-haiku-4.5
**Status:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature007-iter002-planning
### 2026-05-11T03:01:19+03:00: Runtime evidence - Feature 007 Iteration 002 planning routing
**By:** Squad (Coordinator)
**Role / Work Item:** Planner - plan `specs/007-user-facing-progress-handoff/iterations/002`
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** claude-sonnet-4.5
**Status:** fallback
**Fallback Reason:** preferred agent `claude` is not enabled in the delegated routing plan; routed through Copilot task execution

## 2026-05-11-runtime-evidence-feature007-iter002-plan-repair
### 2026-05-11T03:28:32+03:00: Runtime evidence - Feature 007 Iteration 002 planning structure repair
**By:** Squad (Coordinator)
**Role / Work Item:** Planner - repair iteration 002 planning artifacts and draft planning-time hardening gate
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** claude-sonnet-4.5
**Status:** fallback
**Fallback Reason:** preferred agent `claude` is not enabled in the delegated routing plan; routed through Copilot task execution

## 2026-05-11-runtime-evidence-feature007-scaffolding-corpus-repair
### 2026-05-11T03:28:32+03:00: Runtime evidence - Feature 007 scaffolding-authorization corpus repair
**By:** Squad (Coordinator)
**Role / Work Item:** Spec Steward - clarify trap coverage for unauthorized iteration scaffolding
**Requested Agent:** codex
**Actual Agent:** copilot
**Model ID:** claude-haiku-4.5
**Status:** fallback
**Fallback Reason:** preferred agent `codex` is not enabled in the delegated routing plan; routed through Copilot task execution

## 2026-05-11-runtime-evidence-feature007-iter001-retro-repair
### 2026-05-11T03:01:19+03:00: Runtime evidence - Feature 007 Iteration 001 retro boundary repair
**By:** Squad (Coordinator)
**Role / Work Item:** Retro Facilitator - repair stale restart-boundary messaging in iteration 001 retrospective/state
**Requested Agent:** copilot
**Actual Agent:** copilot
**Model ID:** claude-haiku-4.5
**Status:** honored
**Fallback Reason:** none
2. Design versioned lens checklist Markdown table schema during planning
3. Implement strongest-class routing policy with explicit override tracking
4. Design hardening-gate approval workflow with human sign-off capture


## 2026-05-08-spec-005-concrete-mechanisms
# Decision: Spec 005 Updated with Concrete Quality Mechanisms

**Date**: 2026-05-08  
**Type**: spec-update  
**Affected Feature**: specs/005-stack-aware-quality-bar  
**Requestor**: Alon Fliess  
**Status**: Recorded

## Context

User diagnosis identified that spec 005's quality-governance approach was too category-level, naming quality concerns without providing concrete, enforceable mechanisms. Failures cluster around ceremonial sophistication without enforcement, security baseline drift, operational/resilience holes, and anti-patterns plus test theater. Fast-model implementations especially struggle because they lack concrete guidance.

## Decision

Updated spec 005 to convert tacit senior-quality knowledge into concrete, versioned, reviewable artifacts:

1. **Versioned Lens Checklists** (FR-022 through FR-026): Line-item checks with semantic versioning, upgrade guidance, and change logs
2. **Stack Profile Presets** (FR-024): Named bundles for common stacks (e.g., `node-public-ws-service v1.3.0`, `react-spa-public v2.1.0`)
3. **Mechanical Checks** (FR-027 through FR-030): Non-judgment checks for dead fields/symbols, anti-pattern heuristics, test-integrity validation
4. **Pre-Implementation Hardening Gate** (FR-031 through FR-033): Explicit security/resilience/operational review with recorded sign-off before implementation starts
5. **Known-Traps Corpus** (FR-034 through FR-037): Project-wide defect memory with trap reapplication capability
6. **Strongest-Class Review Binding** (FR-038 through FR-040): Required routing of lens execution to strongest available reasoning class with explicit override policy
7. **Quality-Drift Detection** (FR-041 through FR-043): Separate from spec-drift, detects non-functional quality degradation via quality gap ledger
8. **Reference-Implementation Mode** (FR-044 through FR-046): Optional companion capability for high-risk features

## Rationale

The user's diagnosis showed that category-level quality language helps but does not prevent recurring defect patterns. Concrete mechanisms—versioned checklists, presets, mechanical checks, hardening gates, defect memory, routing policy, and drift detection—convert quality expectations from reviewer intuition into explicit, auditable, improvable artifacts.

## Implications

- **Implementation Complexity**: Increases—now requires versioned artifact management, mechanical check integration, hardening gate workflow, and quality-drift baseline tracking
- **Review Quality**: Improves—explicit line-item checks, mechanical findings, and strongest-class routing reduce reliance on model judgment
- **Learning Curve**: Steeper for fast models—but that is the point; fast models need concrete guidance to deliver senior-quality output
- **Scope Discipline**: Maintained—all mechanisms remain additive to existing lifecycle, no separate platform introduced

## Affected Artifacts

- `specs/005-stack-aware-quality-bar/spec.md`: Problem statement, FR-022 through FR-046, updated TG requirements, updated Key Entities, updated Success Criteria, updated Assumptions, updated Governance Alignment

## Open Questions

- **Mechanical check implementation**: Static analysis extensions, custom lint rules, or integrated tooling?
- **Lens checklist format**: Pure Markdown with tables, or structured YAML with Markdown rendering?
- **Known-traps corpus maintenance**: Manual-only in v1, or semi-automated trap detection from review findings?
- **Quality-drift baseline storage**: Per-iteration JSON snapshots, or cumulative baseline files?

## Next Steps

1. Planning phase: design versioned lens checklist format and stack preset structure
2. Implementation phase: build mechanical checks for dead-field detection and anti-pattern heuristics
3. Validation phase: test hardening gate workflow and quality-drift detection against representative features


## copilot-directive-2026-05-04T11-28-23
### 2026-05-04T11:28:23+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Team member management must be command-driven; users should not have to edit multiple `.squad/` files manually. If Squad has no CRUD command surface for team members, Specrew must provide one.
**Why:** User request — captured for team memory


## copilot-directive-2026-05-04T12-28-01
### 2026-05-04T12:28:01+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Validation should require the mandatory baseline Specrew team members to exist, but must not reject or validate any other additional custom team members.
**Why:** User request — captured for team memory


## copilot-directive-2026-05-07T21-05-27+03-00
### 2026-05-07T21:05:27+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Quality drift should compare against the active feature's planned quality baseline first, then prior iteration baselines when present, and the quality bar should enforce technology-specific software quality best practices even when the human developer lacks deep quality expertise.
**Why:** User request — captured for team memory


## copilot-directive-2026-05-07T21-27-52+03-00
### 2026-05-07T21:27:52.819+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Agents must not "fix" warnings by adding them to a warning-disable or suppression list instead of addressing the underlying problem. The default policy is to fix the root cause. Only when disabling or suppressing the warning is genuinely reasonable or necessary may that path be taken, and it requires explicit human user approval first.
**Why:** User request — captured for team memory


## copilot-directive-2026-05-07T22-03-31+03-00
### 2026-05-07T22:03:31+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Keep GitHub lifecycle issues aligned with the authoritative local iteration artifacts; update source artifacts first and rely on sync rather than manual issue drift.
**Why:** User request — captured for team memory


## data-baseline-validation-fix
# Decision: Baseline Team Validation Fix

**Date**: 2026-05-04  
**Author**: Data (Planner)  
**Status**: Implemented

## Context

The governance validator (`validate-governance.ps1`) was missing team composition validation. Per FR-002 and the product spec, Specrew requires five baseline roles to be present:

- Spec Steward
- Planner
- Implementer
- Reviewer
- Retro Facilitator

However, downstream projects should be free to add custom domain-specific members (e.g., Security Analyst, UX Designer, DBA) without validation rejecting them.

## Problem

The validator had **no team validation logic at all**. It only extracted team roles for sign-off validation but never verified that the mandatory baseline roles were present.

## Solution

Added `Test-BaselineTeamMembers` function that:

1. Checks for presence of all five required baseline roles
2. Reports missing roles as validation errors
3. **Ignores any additional custom members** (does not validate or reject them)

Also updated `Get-TeamRoleMap` to read from **both** team formats:
- Standard Squad "Members" section (Name → Role mapping)
- Specrew-managed "Specrew Baseline Roles" section (Role-only entries in managed block)

This dual-format support is necessary because:
- The Specrew repo itself uses the Members section with named members
- Bootstrapped projects use the managed baseline-roles block

## Verification

Created comprehensive test suite (`tests/integration/validate-baseline-team.ps1`) covering:

1. ✅ Baseline-only team (should pass)
2. ✅ Baseline + single custom member (should pass)
3. ✅ Team missing baseline role (should fail with clear error)
4. ✅ Baseline + multiple custom members (should pass)

All existing integration tests still pass:
- ✅ `tests/integration/team-management.ps1`
- ✅ `tests/integration/bootstrap-to-iteration.ps1` (implied via scaffold paths)
- ✅ Main project validation (`validate-governance.ps1 -ProjectPath .`)

## Impact

- **Validation now enforces baseline team requirement** (previously missing)
- **Custom members are explicitly ignored** (requirement met)
- **No breaking changes** to existing workflows
- **Test coverage added** for this validation surface

## Related Requirements

- FR-002: Bootstrap MUST configure baseline roles (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator)
- FR-002: Users can add domain-specific members; baseline roles are protected
- Dogfooding obligation: Specrew validates its own governance model

## Follow-Up

None required. Validation is complete and tested.


## data-bootstrap-handoff-revision
# Decision: Bootstrap Handoff Terminal Output and Squad Readiness Signal

**Date**: 2026-05-04  
**Author**: Data (Planner)  
**Status**: Implemented  
**Context**: Rejected artifact revision from La Forge; reviewer lockout applied

## Problem

Picard updated the bootstrap contract to require explicit next-step guidance. La Forge's implementation was rejected for three specific issues:

1. **Missing explicit flow orientation**: Terminal output must include the concise flow wording from contract: "baseline crew → specify features → plan iteration → execute (and review/retro if needed)"
2. **Inconsistent phrase**: Test expected "Baseline Specrew crew installed:" but code output "Baseline crew installed:" — contract/runtime/test were out of sync
3. **No explicit Squad readiness signal**: Downstream repo must be left in a state recognizable by Squad coordinator as "configured, operation-ready team" — not just inferred from populated files

## Decision

Fixed all three issues with minimal, complete changes:

### 1. Terminal Output Flow (Issue 1 & 2)
- Added "=== Usage Flow ===" section with explicit: "Baseline crew → specify features → plan iteration → execute (review and retro as needed)"
- Changed output phrase from "Baseline crew installed:" to "Baseline Specrew crew installed:" with trailing period to match contract and test expectations
- Restructured "Next Steps" to clearly separate: (1) Start spec authoring, (2) Run iteration lifecycle, (3) Optional team extension
- Added explicit references: "Add extra Squad members after bootstrap" and "Keep the Specrew-managed baseline block intact"

### 2. Squad Readiness Metadata (Issue 3)
- Added explicit team status block to `.squad/team.md` via `deploy-squad-runtime.ps1`
- Metadata includes:
  - `**Team Status**: configured` — explicit recognizable state
  - `**Baseline Roles**: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator`
  - `**Configuration**: Specrew-managed baseline`
- Managed block approach ensures idempotency and allows merging with existing team config

## Rationale

- **Smallest complete fix**: No architectural changes; only output and metadata additions
- **Contract alignment**: Brings implementation, contract, and tests into sync
- **Squad recognizability**: Team status metadata provides explicit signal that Squad can read rather than inferring from file presence
- **Self-sufficient handoff**: Developer gets complete orientation in terminal without leaving for docs

## Validation

- Bootstrap integration test passes cleanly (all pattern matches succeed)
- Team status metadata appears in downstream `.squad/team.md` after bootstrap
- Terminal output includes all three required elements: baseline crew list, usage flow, extension instructions

## Files Changed

- `scripts/specrew-init.ps1`: Terminal output revised (lines 102-125)
- `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`: Team status block added (lines 408-414)

## Follow-up

None required. All three rejection issues resolved.


## data-greenfield-bootstrap-truthfulness
# Decision: Greenfield Bootstrap Documentation Truthfulness

**Date**: 2026-05-04  
**Status**: IMPLEMENTED  
**Owner**: Data (Planner)  
**Audience**: Team (Worf, Picard, La Forge, implementers)

## Problem

The greenfield bootstrap documentation (`docs/getting-started.md`) overclaimed what the non-interactive bootstrap path can deliver end-to-end. Specifically:

1. **Dependency validation success was conflated with bootstrap completion**: The script validates Spec Kit/Squad versions successfully, but this doesn't guarantee `.specify/` and `.squad/` will be created (CLIs might fail).
2. **Environment-specific Spec Kit CLI blocker was underemphasized**: The Unicode encoding issue in some Windows PowerShell environments was documented as a "workaround scenario" but actually **blocks the entire greenfield-to-iteration flow** because it prevents `.specify/` creation.
3. **No gate between bootstrap success and iteration scaffolding**: Docs implied you could immediately run downstream scripts (plan/artifacts/review/retro) after bootstrap, but these all require `.specify/` to exist.

## Evidence

- Test `bootstrap-to-iteration.ps1` (lines 76-79): **Skips entirely** if `specify` or `squad` CLIs unavailable
- CI workflow (lines 78-84): Full greenfield-to-iteration path only runs when both CLIs are installed and operational
- Script exit codes: `specrew-init.ps1` returns 0 when `.specrew/` is created + dependency validation passes, even if `.specify/` initialization failed
- Encoding issue: Not optional workaround; blocks all downstream iteration artifact scaffolding helpers

## Decision

**Distinguish three distinct success states in documentation**:

1. **Dependency Validation Success** (version detection): ✅ Always succeeds if CLIs installed
2. **Bootstrap Completion** (artifact creation): ✅ Creates `.specrew/` + governance; ⚠️ May fail to create `.specify/` or `.squad/` if CLIs error
3. **Greenfield-to-Iteration Flow Success** (full path): ⚠️ Requires dependency validation + CLI initialization + manual Spec Kit init if CLI failed

**Document this truthfully by**:
- Adding prerequisites section: Explicitly state Spec Kit CLI and Squad CLI must be operational
- Making `.specify/` existence a gate: Users must check for it before proceeding to iteration scaffolding
- Reframing Spec Kit encoding issue as a blocker (not optional workaround)
- Providing 5-step resolution path with terminal fallback
- Clearly separating what bootstrap always provides vs. what depends on CLI success

## Rationale

1. **Precision over comfort**: Users hitting the encoding issue deserve to know it's not a workaround scenario—it completely blocks iteration scaffolding.
2. **Traceability to test reality**: The docs now match what the CI integration tests actually validate (full flow requires both CLIs).
3. **No runtime changes needed**: Fix is pure documentation accuracy; all validator and flag fixes remain intact.
4. **Prevents silent failures**: Users won't waste time trying to run downstream scripts on incomplete bootstraps.

## Scope

**In Scope**: `docs/getting-started.md` greenfield and troubleshooting sections  
**Out of Scope**: Runtime code (no changes to `scripts/specrew-init.ps1` or validators)  
**Brownfield Notes**: Brownfield flow unchanged; this addresses only greenfield overclaiming

## Implementation

- ✅ Updated "Greenfield Quickstart" section (lines 40-114): Added prerequisites, conditional gate, step 4 guard
- ✅ Rewrote "Known Limitations" section (lines 178-228): Separated dependency validation from completion; reframed blocker; added resolution path
- ✅ Preserved validator and flag fixes: `validate-versions.ps1` behavior unchanged; `--ai` flag still corrected

## Verification

- ✅ Docs now explicitly state Spec Kit CLI must succeed for `.specify/` creation
- ✅ Docs now gate iteration scaffolding on `.specify/` existence
- ✅ Encoding issue now documented as flow blocker with 5-step resolution
- ✅ Integration tests (`bootstrap-to-iteration.ps1`, `validate-versions-cli-behavior.ps1`) remain unmodified
- ✅ CI workflow validates full greenfield-to-iteration path with both CLIs present

## Next Steps

1. Worf review: Verify docs now match test reality
2. Team review: Confirm truthfulness acceptable for published docs
3. No implementation work: This is doc-only; no runtime changes


## data-iter002-execution-update
# Data: Iteration 002 Execution Lifecycle Correction

**Date**: 2026-05-03
**By**: Data (Planner)
**Status**: Artifact-Safe Corrective Update (Verification Mode)

## Finding

Iteration 002 planning artifacts (plan.md) were still in `planning` status with Started=TBD, but substantial execution work had already commenced:
- FR-019 resume command implementation (resume-iteration.ps1 complete; integration tests present)
- FR-020 brownfield merge implementation (brownfield-merge.ps1 heavily modified; integration tests created)
- T-204, T-205, T-206 actively in development
