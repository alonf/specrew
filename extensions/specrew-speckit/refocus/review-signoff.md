---
scope: boundary.review-signoff
sources:
  - docs/methodology/review-instructions.md
  - docs/methodology/lifecycle-discipline.md
  - proposals/145-structured-multi-phase-reviewer.md
reviewed_at: 2026-06-07
---
## Review-signoff-stage discipline

1. **Review against the requirement, not the effort.** The question is "does this satisfy FR-NNN with evidence", never "did the implementer work hard". Walk the plan's FR-to-test mapping row by row.
2. **Runtime evidence only.** RUN the tests and cite output; exercise the behavior; read the journal/logs. Pattern-grepping for expected strings is not verification — content reads catch what metadata checks miss. File presence proves deployment, never behavior (the Shape catalog exists because this repo shipped that mistake).
3. **Reviewer artifacts when code was touched.** review.md + code-map.md, coverage-evidence.md, reviewer-index.md, review-diagrams.md, dependency-report.md. The validator demands them; their CONTENT must be real (a dependency report with no audit value fails the meaning bar).
4. **Claim ledger honesty.** Every claim in review.md maps to evidence (commit, test run, file inspection); over-strong claims get weakened to what the evidence carries. Check arithmetic claims by re-computing, not re-reading.
5. **Producer-consumer demonstration.** Producer-side changes (metadata, formats, emitted artifacts) need a consumer-side test that proves something real reads them correctly.
6. **Gate-coverage skepticism.** For any gate/validator the feature touched: does it cover what its spec CLAIMS it covers — both directions, all paths? Directional blind spots ship real bugs.
7. **Whole-file re-reads at closure.** Re-read changed artifacts end-to-end; grep for stale-phrase CLASSES (old names, old counts, old statuses), not just phrases that failed before.
8. **The verdict names its exact boundary.** "APPROVE for review-signoff" — never an ambiguous "approve" that could be read as advancing further than reviewed.
9. **Try to DISPROVE the report before approving.** Rerun claimed commands; verify cited evidence is COMMITTED, not working-tree-only; compare code against the design trace; hunt stronger-than-proof language. A review packet is an artifact under test, not testimony.

Known traps: accepting counts ("12 tests added") without running them; reviewing the diff but not the unchanged code it broke; review.md claims that drift from review-report.yml; missing pr-review-resolution when host review exists.

Deep sources:

- {{project_root}}/docs/methodology/review-instructions.md
- {{project_root}}/docs/methodology/lifecycle-discipline.md
