# architecture-core: 205-workshop-lens-order

**Depth**: medium. **Confirmation**: human-confirmed (lens-question). All three decision points were answered in one typed reply on 2026-11-09.

## Decision 1: whole-lens order in a single pass (the question carried from product-domain)

Option A, with the problem section asked first inside every lens:

```text
product-domain > requirements-nfr > ui-ux > security-compliance > data-storage
> integration-api > devops-operations > architecture-core > component-design
> observability-resilience > code-implementation
```

- Inside every lens, the problem section is asked before the solution section.
- Known gap: the mixed lenses' solution questions run before architecture-core. Iteration 2's two-pass split closes it.
- Iteration 1 has no formal "decide later". When the human says they will settle something at design-analysis, that goes into the lens's decision text as it does today. Nothing is built around it.

## Decision 2: how consumers get the order

```text
index.yml (order + space per lens)
   +--read at runtime--> confirm-workshop-agenda.ps1  (refuses a relative-order break)
   +--parity test-----> skill source, methodology, before-specify, README (prose lists kept)
   |                      +--sync--> deployed copies (diff against source)
   +--sweep-----------> any other shipped run of >=3 lens ids
```

- Option 1: the prose lists stay and the parity test checks them.
- The skill gains one sentence: if any list disagrees with index.yml, index.yml wins.

## Decision 3: decomposition and volatility

- No new structure. The changes go into existing units: index.yml, the lens and prose files, one check in confirm-workshop-agenda.ps1, and one new test file.
- The volatile point is the lens catalog (for example Proposals 214 and 162). index.yml is where a new lens gets its position and space.
- **Correction to the requirements-nfr parity rule (human's own amendment):**
  - Full lists must match index.yml exactly, in order and in membership. A lens added to index.yml fails the test until those lists carry it. The full lists are the skill's list, the methodology catalog tables and the catalog README. The crew also proposes counting the before-specify command list as full, since it enumerates every lens.
  - The relative-order rule applies only to partial lists, such as an example agenda.
  - The test itself names which surfaces are full.
