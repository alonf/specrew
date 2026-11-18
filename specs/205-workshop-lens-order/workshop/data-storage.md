# data-storage: 205-workshop-lens-order

**Depth**: light. **Confirmation**: human-confirmed (lens-question). Typed reply on 2026-11-10.

## Correction recorded at this lens

Only one code reader parses a lens file's `## Design Decision Points`: `Get-SpecrewLensDecisionPoints` in
`scripts/internal/lens-applicability.ps1`, whose section regex ends at `^##\s+`, so a `###` sub-heading does not
end it. design-analysis-gate.ps1 reads "Key Design Decision Points" in design-analysis.md, which is a different
file. The skill's instruction to load the heading is the second reader.

## Shape

```text
index.yml lens entry                   lens file (e.g. data-storage.md)
-------------------------------        -----------------------------------
- id: data-storage                     ## Design Decision Points
  file: data-storage.md                ### Problem questions
  space: both          <-- new           - ...
  default_phase: ...   (unchanged)     ### Solution questions
  categories: [...]                      - ...
(list position = the order)            (one-space lens: the empty side keeps its
                                        heading + "No <space> questions: <why>")
```

## Decisions

1. index.yml gains `space: problem | solution | both`, and a lens's position in the list is the order. The tags:
   - problem: product-domain, requirements-nfr
   - solution: architecture-core, component-design, observability-resilience, code-implementation
   - both: ui-ux, security-compliance, data-storage, integration-api, devops-operations
2. Option a: `### Problem questions` and `### Solution questions` sit inside the existing `## Design Decision Points`, and an extractor test proves that every lens returns exactly the points under both sub-headings.
   - **Split rule:** a bullet that mixes both spaces is split into two bullets, one per space, keeping its words and meaning. That is not rewording. Example: data-storage's "schema changes, migrations, backup, restore, and retention", where retention is the obligation and the rest is mechanics.
   - Every split bullet is listed in the plan.
3. Option a: no new field. The relative-order check runs only at confirmation in confirm-workshop-agenda.ps1, so a confirmed agenda is never re-checked. A test proves that an old confirmed agenda still resumes and completes.

## Scope amendment (human, 2026-11-10)

Recorded in product-domain.md and requirements-nfr.md, with their original text left in place. The non-goal "new lenses or questions" applies to iteration 1. The feature now has three iterations:

- **Iteration 2 (problem-space completeness):** fill the problem side of the existing lenses where it is thin. For example, data-storage never asks what data exists, how sensitive it is, how much there is, or what must be carried over. It gets its own short workshop, where the human decides between new questions and a new lens.
- **Iteration 1** changes nothing for it except one output: while tagging, list every problem-side gap seen, per lens. That list is iteration 2's input.
- **Iteration 3** is the back-check, amendments and sweeps, and still waits for 203.
