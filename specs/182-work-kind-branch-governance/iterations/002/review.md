# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-06-12
**Overall Verdict**: accepted
**Method**: Proposal 145 structured multi-phase reviewer (candidate; rules applied manually — no
shipped 145 validator/skill exists yet).
**Tree Under Review**: rework commit `a10ecf22`; implementation diff baseline `efba60a1` (before-implement boundary).
**Review history**: first pass = needs-rework (4 findings); this is the **re-review** after the
rework round cleared all four. The needs-rework pass + its findings are preserved in the git history
(`6dfa57ec`) and summarized under "Rework round" below.

## Summary

Iteration 002 (the **runtime layer**) delivers the provider-neutral CI work-kind validator
(WorkKindValidator + ChangedFileClassifier + CloseoutEvidenceChecker), the emergency-bypass audit,
honest capability detection, the GitHub reference adapter (gh confined), brownfield adapt-or-change
detection, the read-only synthesized-adapter example, the advisory CI workflow template, and the
Specrew dogfood (`.specrew/work-kind.yml` + `.specrew/repository-governance.yml`). The behaviour is
real and well-evidenced: 88 unit assertions across four suites, denial-path + fail-open + dogfood
self-consistency behaviourally proven (not file-presence), and after the rework round every gate is
green.

**Verdict: accepted.** The first review pass returned needs-rework on four findings; all four are now
fixed, re-verified, and re-replayed. No requirement (FR/SC) in iteration-2 scope is a gap. Verdict
aggregation (Proposal 145): every task `pass`, every Gap Ledger entry `fixed-now` → APPROVE for
review-signoff.

**Verification state (re-replayed this pass)**: 88 unit assertions green (catalog 36, adapter 21,
validator 12 = T211, runtime 19 = T212); PSScriptAnalyzer `-Settings PSGallery` **0 errors AND 0
warnings** (7 Information only); markdownlint **0 errors repo-wide** (exact CI command);
FileList-completeness PASS (287 entries); `validate-governance` PASS on iterations 001 and 002;
mechanical-checks 0 findings.

## Rework round (the four needs-rework findings — all fixed-now)

- **F4 — gate (was must-fix).** Two committed `.md` files failed the exact CI Lint command (MD047
  trailing-newline): `iterations/002/drift-log.md` (iter-2 in-scope) and `current-architecture.md`
  (pre-existing from iter-1). Both newlines added; markdownlint is now 0 errors repo-wide, so the
  "markdownlint clean" claim in state.md is true. Fixed in `a10ecf22`.
- **F1 — consistency/honesty (was moderate).** `provider-adapter.ps1` carried stale-by-time "lands in
  iteration 2" comments on its github contract-dispatch branches while the real github detect/apply ran
  on a parallel path. Reworded to the honest forge-neutral-core vs github-adapter split.
  **Reviewer self-correction:** the first review offered "delegate the contract op to the real github
  detection" as a remedy option — that option was **wrong**. Delegation would make the forge-neutral
  core import the github adapter, violating FR-014, and `provider-adapter.tests.ps1` (T015, lines
  55–61) asserts the core invokes no `gh`/GitHub API. The correct fix was the *honest-documentation*
  option: state plainly that the core keeps a neutral placeholder by design and the real work lives in
  the github adapter via the capability-detector orchestrator. Fixed in `a10ecf22`.
- **F2 — code-quality (was minor).** `provider-github.ps1` `$plan` was assigned but never read. Removed
  (with the gh owner query that only computed it). Fixed in `a10ecf22`.
- **F3 — code-quality (was trivial).** The empty catch disappeared with the removed owner block;
  `New-SpecrewProviderAdapter` (a pure descriptor constructor) renamed `Resolve-SpecrewProviderAdapter`
  so the `PSUseShouldProcessForStateChangingFunctions` false positive is gone — no suppression
  attribute (the repo uses none). Fixed in `a10ecf22`.

## Phase 0 — Context load

- Spec, both iteration plans, the iteration-2 state/drift/hardening-gate, the design-analysis, and the
  seven runtime scripts under review were read in full; the four scripts touched by the rework were
  re-read after the fixes.
- Iteration-2 scope (plan.md): FR-007, FR-011, FR-012, FR-013, FR-015, FR-016, FR-020, FR-021; user
  stories US1, US4, US5, US6; success criteria SC-005, SC-006, SC-007, SC-009, SC-010, SC-012, SC-014.
- Out of scope (not gaps): FR-019 forge-neutralization **migration** + SC-008/SC-013 (Iteration 3);
  T013b release-prep (carried, D-001).

## Phase 1 — Branch hygiene

- Branch `182-work-kind-branch-governance`; working tree clean except untracked/modified
  `.specrew`/`.squad` session+cache files (correctly left unstaged).
- Implementation commits from the before-implement boundary: `dc6e78cf`, `b56dd0c2`, `05fce9d1`,
  `d3493f96`; first review `6dfa57ec`; rework `a10ecf22`.
- CI Lint is now green on the branch (F4 cleared).

## Phase 2 — Functional correctness + claim-to-code + workshop conformance

Every iteration-2 functional requirement is implemented and traced to code + a passing assertion (see
the claim ledger and the FR×phase matrix). Verified by reading the code, not the summary:

- **FR-007** — `Invoke-SpecrewWorkKindValidation` performs all four checks (one-kind, in-catalog,
  changed-file scope, closeout-evidence), defaults to advisory, and every finding names the exact gap +
  allowed scope + the fix (SC-005). Confirmed against the validator suite.
- **FR-012 / FR-021** — `Invoke-SpecrewCapabilityDetection` reports `ci-only`/`manual` honestly and
  never promises branch-protection on the generic path; brownfield returns ADAPT (CI present) vs CHANGE
  with an explicit never-overwrite note.
- **FR-015 / FR-020** — the GitHub adapter is `gh`-confined and fail-open; `apply_protection` refuses
  without `-Approved`, is describe-only without `-Execute`, and the contract guard refuses
  read-only/unverified adapters. Tested.
- **Workshop conformance** is now fully satisfied — the F1 reword makes the forge-neutral-core seam
  explicit and removes the dual-path ambiguity (see the design-to-code trace).

## Phase 3 — Non-functional requirements

- **Fail-open (NFR #5):** every reader returns `$null` on malformed input and the validator degrades to
  advisory WARN; missing catalog / no base-ref / unknown kind all WARN, never crash or spuriously block.
  Behaviourally proven (T211/T212).
- **Forge-neutral core:** the validator core, common readers, generic fallback, and the contract
  dispatch invoke no `gh`/API — re-asserted by the T015 grep test (which also gates the F1 reword).
- **No-new-dependency:** the hand-rolled YAML readers honour Specrew's avoidance of `powershell-yaml`
  (carried watch-item: a maintenance surface as the schemas evolve).
- **No secret held:** the GitHub adapter uses the caller's `gh auth`/`GITHUB_TOKEN`.

## Phase 4 — Code quality + anti-patterns + dependency reality

- PSScriptAnalyzer (`-Settings PSGallery`): **0 errors, 0 warnings** across all six work-kind scripts (7
  Information-only). The three first-pass warnings (dead `$plan`, empty catch, ShouldProcess false
  positive) are all resolved by the rework — none via a suppression attribute.
- No dead code remains in the iteration-2 surface; the `gh` dependency stays confined to
  `provider-github.ps1` and fail-open; the GitHub Actions template is the only GitHub-specific wiring
  and runs the neutral script.

## Phase 5 — Test coverage + gate completeness + evidence replay

Evidence replayed this pass (commands re-run after the rework):

- `work-kind-catalog.tests.ps1` → 36 PASS; `provider-adapter.tests.ps1` → 21 PASS (incl. the rename +
  the forge-neutral-core grep); `work-kind-validator.tests.ps1` → 12 PASS; `work-kind-runtime.tests.ps1`
  → 19 PASS. Total 88.
- `validate-governance.ps1` → PASS on iterations 001 and 002 (WARNs are pre-existing/out-of-scope:
  unrelated closed iterations 048/141 + session handoff-evidence).
- `filelist-completeness.tests.ps1` → PASS (287 entries, bidirectional).
- markdownlint (exact CI command) → **0 errors repo-wide** (F4 cleared).
- mechanical-checks → 0 findings.

## Phase 6 — System safety + operations

- **Privileged surface:** `apply_protection` is the only state-changing op — refused without
  `-Approved`, refused for read-only/unverified/synthesized adapters (DP-S2/S3), describe-only until
  `-Execute`; the live mutation is honestly deferred to the human-approved dogfood/beta. Denial-path
  tested (T212).
- **Emergency bypass (FR-011/SC-009):** `Write-SpecrewWorkKindBypassAudit` writes a durable
  who/why/when/what record; never a silent skip. Tested.
- **Operational wiring:** advisory-by-default CI workflow that warns and names the gap but never blocks
  until a team graduates `MODE: blocking`; honest capability reporting prevents false confidence.
- **Dogfood (SC-014):** Specrew's own `.specrew/repository-governance.yml` matches its real posture.
  Verified **structurally** (capture internally consistent + schema-valid); the live GitHub
  posture-match is asserted from the 2026-06-11 mitigation, with live GitHub verification honestly
  deferred to the dogfood/beta (the test does not query the real repo).

## Phase 7 — Output synthesis + report falsification

I attempted to falsify the accept before recording it:

- *Did the rework actually fix F4?* Re-ran the exact CI Lint command → 0 errors repo-wide. Yes.
- *Did the F1 reword secretly break forge-neutrality?* The T015 grep test (no `gh`/API in the core)
  still passes → the reworded comments introduced no forge token. Yes, and the original "delegate"
  remedy is correctly recorded as rejected.
- *Did removing `$plan` / renaming the constructor break anything?* All 88 assertions green; the rename
  has no production callers (only the test). No.
- *Is any claim in this review over-stated?* SC-014 is recorded as structurally (not live) verified;
  the carried Iteration-3 items are labelled not-gaps. No over-claim found.

## FR × phase coverage matrix (iteration-2 scope)

| FR | P2 functional | P3 NFR | P4 quality | P5 tests/gates | P6 safety/ops | Outcome |
| --- | --- | --- | --- | --- | --- | --- |
| FR-007 validator | pass | pass (fail-open) | pass | pass (T211) | pass (advisory) | pass |
| FR-011 bypass audit | pass | pass | pass | pass (T211) | pass (durable) | pass |
| FR-012 capability detection | pass | pass | pass (F1 cleared) | pass (T212) | pass (honest) | pass |
| FR-013 dogfood | pass | n/a | pass | pass (T212) | pass (SC-014 structural) | pass |
| FR-015 github adapter | pass | pass | pass (F2/F3 cleared) | pass (T212) | pass (gh confined) | pass |
| FR-016 synthesis read-only | pass | pass | pass | pass (T212) | pass (DP-S3) | pass |
| FR-020 apply human-gated | pass | pass | pass | pass (T212 denial) | pass | pass |
| FR-021 brownfield | pass | pass | pass | pass (T212) | pass (never overwrite) | pass |

## Claim-to-evidence ledger

| Claim | Evidence replayed | Verdict |
| --- | --- | --- |
| 88 unit assertions green | re-ran 4 suites: 36 + 21 + 12 + 19 = 88 PASS | true |
| PSScriptAnalyzer 0 errors AND 0 warnings | re-ran PSGallery on 6 scripts: 0 error, 0 warning, 7 info | true |
| markdownlint clean (state.md) | re-ran exact CI command: 0 errors repo-wide | true (was false → fixed) |
| FileList-completeness PASS | re-ran: PASS, 287 entries, bidirectional | true |
| validate-governance 0 FAIL | re-ran: PASS iter-001 + iter-002 | true |
| apply_protection never auto-applied | code + T212 denial-path: refused w/o -Approved; describe-only w/o -Execute | true |
| forge-neutral core (no gh/API) | T015 grep test green after the F1 reword | true |
| Specrew dogfood matches real posture | structural + schema check pass; live verification deferred | true (structural) |

## Design-to-code trace

| Design decision (workshop) | Code | Conformance |
| --- | --- | --- |
| Provider-neutral core; no forge import | validator core + common + generic + contract dispatch; T015 grep green | satisfied |
| ProviderAdapter is the only forge seam | gh confined to `provider-github.ps1`; core dispatch documents the placeholder boundary | satisfied (F1 reword made it explicit) |
| apply_protection human-approved (DP-S2) | guard refuses w/o `-Approved`; describe-only w/o `-Execute` | satisfied |
| Synthesized adapter read-only until verified (DP-S3) | contract guard + read-only example refuses apply | satisfied |
| Advisory default; honest phasing; no over-claim | workflow advisory; validator advisory default; stale "iteration 2" comments removed | satisfied |
| branch_model configurable / user-named branches | dogfood `trunk`/`main`; describe honours names | satisfied |
| review_gate opt-in automated review | dogfood governance: Copilot opt-in captured | satisfied |
| Brownfield adapt-or-change, never overwrite | `Invoke-SpecrewBrownfieldDetection` + note | satisfied |
| Specrew holds no secret | token from CI/gh auth only | satisfied |

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T201 | FR-007 | pass | WorkKindValidator core: advisory default, four checks, fail-open; T211 green (scope-mismatch named). |
| T202 | FR-007 | pass | ChangedFileClassifier: scope-glob + allowlist exemption behave as the catalog declares; T211 green. |
| T203 | FR-007 | pass | CloseoutEvidenceChecker: software-feature/bug-bash open-boundary flagged; fail-open on unresolvable branch; T211. |
| T204 | FR-012 | pass | Capability detection honest + describe-only; F1 (stale dual-path dispatch comments) reworded in the rework round. |
| T205 | FR-015 | pass | GitHub adapter gh-confined + fail-open (T212); F2 dead `$plan` removed + F3 constructor renamed in the rework round. |
| T206 | FR-021 | pass | Brownfield ADAPT-vs-CHANGE + never-overwrite note; read-only; T212 green. |
| T207 | FR-007 | pass | Advisory-default GitHub Actions template runs the provider-neutral script; never blocks until graduated. |
| T208 | FR-016 | pass | Read-only synthesized-adapter example: detect/describe only, apply refused until human-verified; provenance recorded. |
| T209 | FR-011 | pass | Emergency bypass writes a durable who/why/when/what artifact; no silent skip; T211 green. |
| T210 | FR-013 | pass | Dogfood `.specrew/work-kind.yml` + `repository-governance.yml`; SC-014 structural self-consistency green (T212). |
| T211 | FR-007 | pass | Validator + bypass suite: 12 behaviour-proving assertions green. |
| T212 | FR-020 | pass | Capability/denial-path/brownfield/SC-014 suite: 19 assertions green (apply refused w/o approval). |

## Gap Ledger

- No requirement (FR/SC) gaps in iteration-2 scope; all in-scope requirements implemented + evidenced (Iter-3 / T013b items are planned phasing, not gaps): fixed-now.
- F4 review finding (2 MD047 lint errors + a false "markdownlint clean" claim) repaired in commit a10ecf22; markdownlint now 0 errors repo-wide: fixed-now.
- F1 review finding (stale-by-time forge-neutral-core dispatch comments) reworded to the honest seam split; delegation rejected as an FR-014 violation: fixed-now.
- F2 review finding (dead `$plan` in provider-github.ps1) removed: fixed-now.
- F3 review finding (empty catch + ShouldProcess false positive) resolved by the owner-block removal + the Resolve-SpecrewProviderAdapter rename: fixed-now.

## Notes

- The first-pass needs-rework verdict + findings are preserved in git history (`6dfa57ec`); this
  re-review supersedes it with an accepted verdict after the rework round.
- Carried (not iteration-2 gaps): FR-019 migration + SC-008/SC-013 (Iteration 3); T013b release-prep
  (D-001); the hand-rolled YAML reader maintenance watch-item.
- Stop at review-signoff for the maintainer's verdict; no push, PR, merge, tag, publish, release, or
  Iteration-3 work.
