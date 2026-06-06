# Quickstart: Post-Ship Proposal Amendment Discipline

**Feature**: 168-post-ship-proposal-amendment-discipline
**Last verified**: 2026-06-06

## Run it

After implementation, run the focused checks from the repository root:

```powershell
npx markdownlint-cli docs/methodology/proposal-discipline.md docs/methodology/review-instructions.md
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\unit\validate-governance.post-ship-proposal-amendment.tests.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\.specify\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

If implementation places the tests in an existing narrower test file, use the task-defined test command instead of the example unit file name above.

## Try the canonical scenario

1. Open the synthetic shipped-proposal fixture created by the implementation tasks.
   Expected result: the fixture has `status: shipped` and a body edit outside `Post-Ship Amendments`.
2. Run the focused amendment-discipline test command.
   Expected result: the validator emits a warning for a shipped or superseded normative edit outside `Post-Ship Amendments`.
3. Open the valid amendment fixture.
   Expected result: the fixture includes all required amendment fields and does not emit the shipped-body-edit warning.
4. Inspect the index/status fixture output.
   Expected result: the output includes a line equivalent to `A1 accepted-unimplemented`.

## Verify the edge cases

- Candidate and draft proposal fixtures with normal body edits should not emit shipped-proposal amendment warnings.
- A shipped proposal fixture with only typo, broken link, errata, or supersession-pointer changes should not emit a shipped-normative-edit warning.
- A malformed `Post-Ship Amendments` fixture should emit a malformed-amendment finding, not a generic unsafe body rewrite warning.
- Review evidence must identify amendment id, preserve list, tests required, and no unrelated shipped-scope reimplementation.
