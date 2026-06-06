# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-06
**Overall Verdict**: accepted

## Test Strategy

Feature 168 uses focused regression coverage with synthetic proposal fixtures. The tests exercise the real governance validator against scratch git repositories and assert docs, reviewer guidance, status surfacing, and validator mirror parity. Real shipped proposal bodies are not edited for coverage.

## Tests Run

| Command | Result | Exit Code | Notes |
| ------- | ------ | --------- | ----- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File '.\tests\unit\validate-governance.post-ship-proposal-amendment.tests.ps1'` | pass | 0 | Focused replay passed all Feature 168 validator/docs/status/mirror assertions. |
| `npx --yes markdownlint-cli2 "docs/methodology/proposal-discipline.md" "docs/methodology/review-instructions.md" "proposals/INDEX.md" "tests/unit/fixtures/168-post-ship-proposal-amendment-discipline/*.md" "specs/168-post-ship-proposal-amendment-discipline/**/*.md"` | pass | 0 | Markdownlint checked 34 files with 0 errors. |
| Parser/mirror command in `quality/quality-evidence.md` | pass | 0 | Both PowerShell files parsed; extension validator and `.specify` mirror content matched. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File '.\extensions\specrew-speckit\scripts\validate-governance.ps1' -ProjectPath . -IterationPath '.\specs\168-post-ship-proposal-amendment-discipline\iterations\001' -NoCacheRead -NoParallel` | pass | 0 | Scoped governance validation passed with known soft warnings recorded in quality evidence. |

## Coverage-to-Requirements

| Requirement | Coverage Evidence |
| ----------- | ----------------- |
| FR-001 | Docs assertion verifies all mutability classes. |
| FR-002 | Docs assertion verifies required amendment fields. |
| FR-003 | Docs assertion verifies allowed amendment statuses. |
| FR-004 | Docs and validator fixtures cover shipped/superseded direct-edit rules. |
| FR-005 | Docs cover new proposal/follow-up default for behavior-changing amendments. |
| FR-006 | Review guidance and review ledger require delta-from-shipped-behavior evidence. |
| FR-007 | Reviewer guidance requires delta-based review and no unrelated shipped-scope reimplementation. |
| FR-008 | Review ledger links delivered delta to Feature 168 evidence and preserved shipped behavior. |
| FR-009 | Reviewer guidance requires final amendment disposition for closeout. |
| FR-010 | Unsafe shipped/superseded body edit fixtures emit warning-first findings. |
| FR-011 | Valid amendment, allowed correction, candidate, draft, and active fixtures avoid unsafe body-edit warnings. |
| FR-012 | Malformed amendment fixture emits separate `malformed-amendment` finding. |
| FR-013 | Proposal index and synthetic status fixture show unimplemented amendment statuses. |
| FR-014 | Focused replay covers validator, docs, reviewer, status, malformed, and mirror parity requirements. |
| FR-015 | Delta audit and fixture-only tests prove no real shipped proposal body rewrite or bulk migration. |

## Residual Risk

- Validator detection is deliberately lightweight and structural. It catches changed shipped/superseded sections, not every possible semantic rewrite.
- Status surfacing is human-maintained in `proposals/INDEX.md`; generated amendment index work is intentionally out of scope.
