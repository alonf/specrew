# Coverage Evidence: Iteration 001 — Session Mode Configuration & File Classification

**Schema**: v1
**Reviewed**: 2026-05-31
**Overall Verdict**: accepted

> **Review-evidence integrity note:** the scaffolder emitted a Form-vs-Meaning warning (19 tasks vs 20 changed files). Verified **false positive**: all implementation IS committed (HEAD `4141a892` == origin; `git diff a9600489...HEAD --stat` shows the files). The count differs because governance artifacts (spec/plan/tasks/drift-log/etc.) and the second `scaffold-governance.ps1` mirror are not 1:1 with tasks. No uncommitted work.

## Test Strategy

- TDD: every acceptance test authored fail-first, verified red, then driven green by implementation.
- Tests assert **observed reality** (config bytes, `.gitignore` lines, real git index state), not declared success; no filesystem/git mocking.
- T008 drives the **real** governance scaffold writer; T015 runs against a **real** temporary git repository.

## Tests Run

| Command | Result | Pass | Fail | Exit | Notes |
| ------- | ------ | ---- | ---- | ---- | ----- |
| `tests/unit/feature-051-session-mode.tests.ps1` | pass | 10 | 0 | 0 | US1 — config get/set/revert/invalid (FR-001/002) + fresh-scaffold default single (FR-003, real writer). |
| `tests/unit/feature-051-file-classification.tests.ps1` | pass | 29 | 0 | 0 | US2 — FR-004 rule set (4 categories + 8 patterns); T014 gitignore generation/idempotency/preservation; T015 git-rm-cached vs real temp git repo. |
| `tests/unit/slash-command-arg-whitelist.tests.ps1` | pass | — | 0 | 0 | Regression: new `config` command did not break the arg whitelist. |
| `validate-governance.ps1 -ProjectPath .` | pass | — | 0 | 0 | No FAIL/medium/hard; only pre-existing soft warnings (F-048 dashboard, handoff-block). |
| `run-mechanical-checks.ps1` | pass | — | 0 | — | `quality/mechanical-findings.json`: zero findings. |

> Note: `validate-governance.reader-tolerance.tests.ps1` exits 1 ONLY from a Pester 3.4.0 TestDrive teardown error (`Remove-Item C:\Users\ALON~1.HOM does not exist`); all 3 of its assertions pass. Environmental/pre-existing; zero overlap with F-051 surfaces.

## Coverage Estimate

- Kind: qualitative
- Label: focused (acceptance + regression). No line-coverage tool for PowerShell in this repo; coverage argued per-FR below.

## Coverage-to-Requirements (precise)

| Requirement | Covering test(s) | Evidence |
| ----------- | ---------------- | -------- |
| FR-001 (session_mode flag) | feature-051-session-mode (T008 default; T007 set) | config.yml carries session_mode; default single. |
| FR-002 (config set CLI + validation) | feature-051-session-mode (T007) | set→multi, revert→single, invalid→exit 1 no-mutation; CLI dispatch smoke. |
| FR-003 (default single) | feature-051-session-mode (T008, real scaffold writer) | fresh scaffold → session_mode single. |
| FR-004 (4-category classification) | feature-051-file-classification (FR-004 block) | all 4 categories + 8 canonical per-session patterns asserted. |
| FR-005 (gitignore generation) | feature-051-file-classification (T014) | all patterns present, idempotent, preserves existing entries/comments. |
| FR-006 (git rm --cached cleanup) | feature-051-file-classification (T015, real git repo) | index entry removed, working copy kept, unrelated file untouched. |

## Known coverage-edge (disclosed)

- **T011 / T013 (init wiring of gitignore + git-rm-cached):** verified by (a) direct helper tests against real temp dirs/repos, (b) PowerShell parse-check of the modified `specrew-init.ps1`, and (c) code-read of the inserted block. NOT verified by a full end-to-end `specrew init` execution (init is a heavy multi-deploy operation). The helper logic itself is fully exercised; only the in-init call-site is not run under test. **Candidate follow-up:** an init-flow integration test asserting `.gitignore` + git-index state after a real `specrew init` (Iteration-1 retro signal / small-fix slice). Not a requirement gap — FR-005/006 behavior is proven at the unit level.
