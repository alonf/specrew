# Review Diagrams: Iteration 004

**Schema**: v1
**Reviewed**: 2026-06-03

## Questionnaire-driven lens selection (FR-025, Option B decoupled)

```mermaid
flowchart LR
  Scaffold[design-analysis scaffold] -->|6 questions + human confirm| JSON[lens-applicability.json<br/>answers]
  Map[applicability-map.json<br/>sibling; index.yml stays pure] --> Selector
  JSON --> Selector[Get-SpecrewApplicableLenses<br/>pure, deterministic, no network/LLM]
  Selector -->|selected| Render[Format-SpecrewApplicableLensesSection]
  Render --> Section[Applicable Lenses section<br/>in design-analysis.md]
  Selector -.audit (included/excluded).-> JSON
  Catalog[(index.yml + lens files<br/>read-only)] -.referenced by id.-> Render
```

## Dogfood (iteration-4's own design analysis)

```mermaid
flowchart LR
  A[answers: data=yes, else no] --> S[selector]
  S --> Sel[architecture-core, component-design,<br/>requirements-nfr, data-storage]
  Sel --> R[rendered section]
  R --> Chk{render == JSON selected?}
  Chk -->|yes converge| OK[gate Valid=true; no send-back]
  Chk -->|no diverge| SB[STOP + send back]
```

## Notes

- The `index.yml` catalog is read-only (referenced by lens id for links); the gating lives in the
  decoupled sibling `applicability-map.json`. The dogfood converged (CONVERGE=True), so the
  send-back branch was not taken.
