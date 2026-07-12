---
scope: boundary.review-signoff
sources:
  - docs/methodology/review-instructions.md
  - docs/methodology/lifecycle-discipline.md
reviewed_at: 2026-06-07
---
## Review-signoff-stage discipline

1. **Review against the requirement, not the effort.** The question is "does this satisfy FR-NNN with evidence", never "did the implementer work hard". Walk the plan's FR-to-test mapping row by row.
2. **Runtime evidence only.** RUN the tests and cite output; exercise the behavior; read the journal/logs. Pattern-grepping for expected strings is not verification — content reads catch what metadata checks miss. File presence proves deployment, never behavior (the Shape catalog exists because this repo shipped that mistake). **Runner-observed floor (FR-014/FR-015).** When a claim rests on test COUNTS, the floor is runner-observed evidence recorded by the universal, framework-neutral recorded-run runner (`Invoke-ContinuousCoReviewRecordedRun`) bound to the EXACT reviewed-tree digest. It records the command-execution facts directly (executable/args/cwd, exit code, timeout, bounded I/O and artifact digests); `command_succeeded` (exit 0) is NOT "all tests passed". Rich counts gain standing ONLY from a run-produced, schema-valid `SpecrewTestResult` — never from prose, caller-supplied numbers, or parsing human-readable console output; a REQUESTED-but-missing/malformed/stale/invalid result fails LOUDLY.
3. **Reviewer artifacts when code was touched.** review.md + code-map.md, coverage-evidence.md, reviewer-index.md, review-diagrams.md, dependency-report.md. The validator demands them; their CONTENT must be real (a dependency report with no audit value fails the meaning bar).
4. **Live co-review is mandatory for code-touched review-signoff.** Before accepting `review.md`, invoke `/specrew-review --live` (or `specrew review --live`) with the active feature and iteration context — with the baseline OMITTED so the run auto-anchors to the feature merge-base (an explicit `--baseline-ref` run is EXPLORATORY by design and never counts as signoff evidence). Treat the run's durable evidence — `.specrew/review/inline/<run-id>/findings-result.json`, `.specrew/review/inline/<run-id>/review-run.json`, and `.specrew/review/inline/<run-id>/gate-verdict.json` — as REQUIRED: `review.md: accepted` is invalid without it. A NON-ZERO `specrew review --live` (e.g. `no-authorized-reviewer-host`) is an INFRASTRUCTURE BLOCKER, not a clean review: surface its remediation (`specrew review --host <host> --authorization-ref <ref>`) and record a blocker or obtain explicit human defer approval. Do NOT replace the co-review with ANY substitute — not hand-authored prose, and NOT a host-internal code-review agent or your own manual read. Those may find real bugs, but they are NOT co-review evidence and must NEVER be recorded as the iteration's review verdict. (A host filling the co-review vacuum with its own reviewer, then writing `review.md: accepted`, is the exact failure this guards.)
5. **Claim ledger honesty.** Every claim in review.md maps to evidence (commit, test run, file inspection); over-strong claims get weakened to what the evidence carries. Check arithmetic claims by re-computing, not re-reading.
6. **Producer-consumer demonstration.** Producer-side changes (metadata, formats, emitted artifacts) need a consumer-side test that proves something real reads them correctly.
7. **Gate-coverage skepticism.** For any gate/validator the feature touched: does it cover what its spec CLAIMS it covers — both directions, all paths? Directional blind spots ship real bugs.
8. **Whole-file re-reads at closure.** Re-read changed artifacts end-to-end; grep for stale-phrase CLASSES (old names, old counts, old statuses), not just phrases that failed before.
9. **The verdict names its exact boundary.** "APPROVE for review-signoff" — never an ambiguous "approve" that could be read as advancing further than reviewed.
10. **Try to DISPROVE the report before approving.** Rerun claimed commands; verify cited evidence is COMMITTED, not working-tree-only; compare code against the design trace; hunt stronger-than-proof language. A review packet is an artifact under test, not testimony.

Known traps: accepting counts ("12 tests added") without running them; reviewing the diff but not the unchanged code it broke; review.md claims that drift from review-report.yml; missing pr-review-resolution when host review exists.

Deep sources:

- {{project_root}}/docs/methodology/review-instructions.md
- {{project_root}}/docs/methodology/lifecycle-discipline.md
