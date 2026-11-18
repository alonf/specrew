# Product-domain record: 205-workshop-lens-order

**Depth**: Light. A later feature in a known product: an internal methodology change whose problem and
maintainer ruling are already recorded in proposal 220.
**Confirmation**: human-confirmed (lens-question), typed reply on 2026-11-09.

| Area | Record | Evidence |
| --- | --- | --- |
| Users | The human in a Specrew design workshop and the crew agent that runs it. Harmed parties: a human asked to choose a structure before its drivers are known, and maintainers whose four lens orders drift. | known |
| Pain | architecture-core runs before requirements-nfr. The order is defined four times and no two agree. Two lenses ask the binding-constraints question. Workaround: the crew picks an order for each feature. | known |
| Context | Extends the shipped workshop (features 176 and 177). | known |
| Constraints | Iteration 1 only; iteration 2 waits for 203 to merge. Do not touch C:\Dev\specrew-b4f-142 or the 203 pin. 204 is reserved. FR-013 migration. | known |
| Outcome | One order in index.yml, a parity test that fails on any second definition, problem space before solution space. | known |
| MVP | index.yml as the single order with a space for each lens; problem and solution sections in each lens file; the constraint and scope questions move to requirements-nfr; the skill and methodology read the one order; FR-001; FR-013. Single pass. | known |
| Non-goals | The FR-002/003 two-pass split, back-check, amendments, bindings flow, sweeps, FR-014 fixtures, new lenses, Proposal 162, automatic influence detection. | known |
| Rollout | Next beta; only agendas confirmed after the release use the new order. | known |
| Alternatives | Skipped at Light depth. | - |

**Carried to the workshop as its own question:** with a single pass, a mixed lens (data-storage,
security-compliance, integration-api, ui-ux, devops-operations) still asks its solution questions before
architecture-core runs. The options for ordering whole lenses in iteration 1 are raised at the lens that owns the
decision.

## Scope amendment (human's typed reply at data-storage, 2026-11-10)

The non-goal "new lenses or questions" applies to **iteration 1**. The feature now has three iterations:

- **Iteration 2 (problem-space completeness):** fill the problem side of the existing lenses where it is thin, for example data-storage never asks what data exists, how sensitive it is, how much there is, or what must be carried over. Iteration 2 has its own short workshop, where the human decides between new questions and a new lens.
- **Iteration 1** adds one output for it: while tagging, list every problem-side gap seen, per lens.
- **Iteration 3:** the back-check, amendments and sweeps, still waiting for 203.

The original text above is left in place.
