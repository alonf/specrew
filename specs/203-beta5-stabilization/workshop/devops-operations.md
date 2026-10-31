# Lens: devops-operations (medium)

**Feature**: 203-beta5-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-31,
receipt `d39441aa871f09b709525ee7bbb888463887874a2314053b7e621a82c860f31c`.
**Question**: the CI rider. Which PR lanes carry the census-failable tests (B5F-015, B4F-119), linting the
composed and dot-directory copies (B5F-013), and whether lint may keep gating the deterministic gate
(B4F-079, B4F-158).

Repository governance (protected main, required checks, closeout before merge) is inherited unchanged.
The repository is public: CI cost is wall-clock, not minutes.

## CI topology today

```text
 push (any branch)              PR into main                    tag v*.* / dispatch
 -----------------              ------------                    -------------------
 Specrew CI                     Specrew CI                      Publish: full-test-census
   lint (**/*.md, no dot-dirs)    lint (changed .md, incl.        windows-latest, 4 parallel,
     |  needs                       dot-dirs)                     every tests/**/*tests?.ps1
     v                              |  needs                      = 451 files, ~50 min
   deterministic gate  (~28 min)    v                             (last run 2026-10-26)
     |  needs                     deterministic gate
     v                              v
   contract lane                  contract lane
 Test, Cross-Platform           Test, Cross-Platform
 (curated suites, ~45 named)    (same curated suites)

 never run anywhere: test scripts outside the *tests?.ps1 pattern that no lane names
   (65 such .ps1 files under tests/, some support/probes; B4F-119's seven failing suites are here)
```

Two gaps: (1) the census can fail on all 451 files while PR lanes run a curated ~45 (measure e);
(2) suites outside the census pattern never run in the census, and some run nowhere (B4F-079, B4F-119).

## Decisions

1. **Measure (e): the census runs in PR CI.** The census sweep itself is a required check on every PR into
   main, sharded on windows-latest. Parity is structural: a test asserts the PR job and the publish job
   use the same selection and the same exclusion list, with no PR-only exclusions. Covers B5F-015.
   **Maintainer additions:**
   - Before the spec fixes the lanes, list what the deterministic gate does beyond running tests.
     Wherever it only runs suites the census also runs, the census shards replace it rather than run
     beside it.
   - The Linux and macOS curated lanes stay: the census is Windows-only, and B4F-142 failed only on Linux.
   - The shard count is sized against the account's concurrent-job limit, so shards and lanes do not queue
     behind each other.

   **Fact recorded for the spec (open point):** the deterministic gate runs on `ubuntu-latest`, not
   Windows. Its 34 steps are toolchain setup (Node, markdownlint, uv, specify CLI, squad CLI) and named
   suites, several of them script-style suites outside the census pattern (`f198-regression-suite.ps1`,
   `bootstrap-to-iteration.ps1`, `manual/review-production-harness-dry-run.ps1`), and at least one placed
   there for its POSIX branch (`unix-resolver-path-semantics.tests.ps1`). Replacing it with Windows shards
   would remove Linux coverage, which the "Linux lanes stay" rule keeps. The spec presents the inventory
   and the maintainer rules which steps move, which stay on Linux, and whether the gate remains as a Linux
   lane.
2. **No path filter.** Docs-only PRs run the census too: a docs change can fail a test
   (`substantive-interaction-model-iteration2` reads README.md).
3. **The census universe.** The census selects every `.ps1` under `tests/` except an explicit, reviewed
   list of non-suites (support files, live-host probes). A file in neither set fails the selection check.
   B4F-119's seven failing suites are each fixed or retired at implement, with a record either way.
4. **Lint stops gating the tests (B4F-079, B4F-158).** The deterministic gate drops `needs: lint`; lint stays
   a required check of its own. The other half of B4F-158 (the validator accepting the record states the
   lifecycle passes through) goes to the backlog, not 203.
5. **Dot-directory lint (B5F-013).** Fix the coordinator fragment (MD046); push lint covers dot-directories
   (`--dot`, keeping the `.squad`, `.specify` and runtime exclusions); a test composes the fragment and
   lints the composed `.github/agents/squad.agent.md`; then the interim `.markdownlintignore` entry goes.
6. **B4F-142's CI side.** It surfaced in the Linux Cross-Platform lane, which keeps running it unchanged. The
   fix is decided in observability-resilience.

## Rejected alternatives

- Adding ~400 suites one by one to curated lanes: the same cost with more churn.
- A path filter for docs-only PRs: a docs change can fail a test.
- Census shards beside a gate that only runs census suites: duplicate wall-clock.

## Bindings

- `census-in-pr-ci`: `required-sharded-windows-same-selection`
- `census-pr-parity`: `structural-same-selection-and-exclusions`
- `gate-overlap`: `inventory-before-spec-shards-replace-census-only-steps`
- `os-lanes`: `linux-macos-curated-lanes-stay`
- `shard-count`: `sized-to-concurrent-job-limit`
- `census-path-filter`: `none`
- `census-universe`: `all-tests-ps1-minus-reviewed-non-suite-list`
- `unrun-suites`: `fix-or-retire-with-record`
- `lint-gates-tests`: `no-lint-own-required-check`
- `record-state-validator`: `backlog`
- `dot-directory-lint`: `fix-fragment-lint-composed-and-dot-dirs-on-push`
