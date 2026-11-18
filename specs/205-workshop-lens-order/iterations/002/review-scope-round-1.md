# Review Scope: Feature 205, Iteration 002, Round 1

**Iteration**: 002, problem-space completeness (Amendment A1)
**Baseline**: `f8691e43` (iteration 002's baseline ref in `state.md`)
**Written**: 2026-11-14, before the round, and committed in the reviewed tree

## What iteration 002 changed

Product files, from the baseline to the reviewed commit:

- **Lens files** (`extensions/specrew-speckit/knowledge/design-lenses/`):
  - `product-domain.md`: areas 9 to 14 with keys and suffixes. The compliance regime (area 9) is asked at every
    depth; areas 10 to 14 are recommendation lines at Light.
  - `requirements-nfr.md`, `ui-ux.md`, `security-compliance.md`, `data-storage.md`, `integration-api.md`,
    `devops-operations.md`: the added problem questions, each with a suffix ending in `→ <consumer>`; a
    `## Handed Forward From Earlier Lenses` section; and a `## Depth Model`.
  - `observability-resilience.md`: no problem questions (it is a solution lens); six hand-forward lines.
- **Workshop skill**: `extensions/specrew-speckit/squad-templates/skills/design-workshop.md`. Product-domain asks
  the compliance regime at every depth and shows areas 10 to 14 as one block at Light. Each lens shows its
  recommendations once, as one list closed by one reply, and "accept" closes a lens whose open items are all
  recommendations.
- **Spec template**: `templates/specify/templates/spec-template.md` gains `## Problem Context`, the eleven consumer
  lines.
- **Tests**:
  - `tests/unit/workshop-length-budget.tests.ps1` (new): the length numbers, the Light caps and the consumer checks,
    with 25 self-tests.
  - `tests/unit/lens-order-parity.tests.ps1`: the extractor counts.
- **CI**: one step in `.github/workflows/specrew-ci.yml` runs the length test.
- **Deployed copies**: `.specify/` lens and skill copies, the four host `SKILL.md` copies, and the hash record
  `.specify/extensions/specrew-speckit/.specrew-extension-runtime.json`.
- **Verification plan**: `.specrew/verification-plan.json`, re-pointed to iteration 002 (DRIFT-017).

## The contract

- **Requirements**: spec Amendment A1, FR-023 to FR-029. FR-024 and FR-025 are as reworded on 2026-11-14 (DRIFT-010).
  FR-030 (code-implementation lens refresh) and FR-031 (proposal 220 status line) are iteration 003 by the approved
  iteration plan.
  - Spec TG-003 still lists FR-031 under iteration 002. That is the spec's wording lagging the approved plan, not a
    defect of the code.
- **Success criteria**: SC-007 to SC-010 and SC-012 are this iteration's. SC-011 is iteration 003's.
- **Counts**:
  - The length test's numbers are the budget ceiling for SC-007 to SC-012: Light 51/16/21 (caps 51 points and 18
    replies), Standard and Deep 66/16/6. The test counts every unsuffixed decision area as must-answer at every
    depth, so it is an upper bound.
  - What a lens actually asks at a depth is that lens's own `## Depth Model`. product-domain's Light model asks
    five areas, and the test budgets nine. A workshop that asks five there is within budget, not missing questions.
- **Placement**: observability-resilience's four questions were placed by subject in other lenses and handed
  forward, by the reviewer session's ruling under the maintainer's delegation (DRIFT-007). observability-resilience
  stays `space: solution`, by the maintainer's ruling of 2026-11-10.

## Known limit of the evidence

SC-012's recorded run (`quality/t026-recorded-run.md`):

- **Who answered**: the replies were sent by the reviewer session, each confirmed by the maintainer first
  (DRIFT-011). They are not the maintainer's typed turns in the workshop session.
- **"accept"**: closing a list was shown only together with answers to must-answer questions. No lens in the pass
  had a recommendation list alone.
- **Counts for the pass**: 17 of 21 must-answer, 4 of 6 typed replies, 13 of 13 recommendation lines.
- **Later run**: the maintainer then continued the scratch workshop past the pass. That continuation is outside T026
  and SC-012.

## Not defects of this iteration

- **Later work**: iteration 003 (FR-030, FR-031) and iteration 004 (the two-pass split, the end-of-lens back-check,
  amendments, sweeps, the items carried from iteration 001).
- **Open drift items** for later iterations, nothing changed in 002:
  - DRIFT-014: the agenda shows no problem/solution grouping;
  - DRIFT-015: a stale open point and an unlabelled inference in the scratch records, and a hand-forward line outside
    its lens file.
- **Spec template copy**: the deployed `.specify/templates/spec-template.md` is left without `## Problem Context`; a
  project gets it on its next update (DRIFT-008).
- **Feature 203's area**, handed over and not changed here: H-015 to H-021.
- **Standing exceptions**:
  - Local governance fails only on iteration 001's missing derived independent-review block. That block is not
    added.
  - The co-review-service rerun exception.

## Where to attack first

1. **`tests/unit/workshop-length-budget.tests.ps1`.** Does it count what FR-028 says?
   - Each item is counted where it is shown: a recommendation line at Light, must-answer at Standard and Deep.
   - Hand-forward lines are recommendation lines at every depth.
   - The typed-reply rule is followed.
   - Can a lens file pass the consumer check (FR-029) with a consumer that does not exist, a source lens that runs
     later, or a key the source does not define?
   - Do the self-tests prove both failures FR-028 requires?
2. **Suffix grammar against the lens files.** Every added question ends in exactly one suffix the test parses, with
   one consumer that exists: a `spec.md Problem Context: <name>` line in the template, or `lens: <later lens>`.
3. **The skill against FR-026.** Does the wording make a bare "accept" unambiguous, and keep a lens's
   recommendations to one list, never one prompt per line?
4. **Copies and hashes.** The deployed copies match their sources; the hash record matches the copies (CR-stripped
   SHA-256); and the specrew_version stamp is unchanged.
