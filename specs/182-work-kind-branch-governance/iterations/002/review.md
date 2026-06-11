# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-06-12
**Overall Verdict**: needs-rework
**Method**: Proposal 145 structured multi-phase reviewer (candidate; rules applied manually — no
shipped 145 validator/skill exists yet).
**Tree Under Review**: HEAD `d3493f96`; implementation diff baseline `efba60a1` (before-implement boundary).

## Summary

Iteration 002 (the **runtime layer**) delivers the provider-neutral CI work-kind validator
(WorkKindValidator + ChangedFileClassifier + CloseoutEvidenceChecker), the emergency-bypass audit,
honest capability detection, the GitHub reference adapter (gh confined), brownfield adapt-or-change
detection, the read-only synthesized-adapter example, the advisory CI workflow template, and the
Specrew dogfood (`.specrew/work-kind.yml` + `.specrew/repository-governance.yml`). The **behaviour**
is real and well-evidenced: 88 unit assertions across four suites (T211 = 12, T212 = 19 are new this
iteration), PSScriptAnalyzer 0 errors, FileList-completeness PASS, `validate-governance` PASS on both
iterations. Fail-open, denial-path, and dogfood self-consistency are all behaviourally proven, not
file-presence-checked.

**Verdict: needs-rework — bounded, not a rejection.** The runtime requirements are met and evidenced,
but the review surfaces four findings that must clear before review-signoff. The load-bearing one is a
truthfulness/gate defect, not a behavioural bug: two committed Markdown files fail the **exact** CI
Lint command, one of them this iteration's own `iterations/002/drift-log.md`, while `state.md` and
`plan.md` assert "markdownlint clean". A review that stamped APPROVE while the Lint gate is red and the
iteration's own state doc carries a false "clean" claim would itself be the over-claim this whole
feature exists to prevent. The other three are an honesty/consistency finding (stale, orphaned
contract-dispatch code), a dead-variable code-quality defect, and a carried analyzer false-positive.
None require a redesign; all are small, bounded edits the human can authorize at the boundary.

## Phase 0 — Context load

- Spec, both iteration plans, the iteration-2 state/drift/hardening-gate, the design-analysis, and the
  seven runtime scripts under review were read in full.
- Iteration-2 scope (from plan.md): FR-007, FR-011, FR-012, FR-013, FR-015, FR-016, FR-020, FR-021;
  user stories US1, US4, US5, US6; success criteria SC-005, SC-006, SC-007, SC-009, SC-010, SC-012,
  SC-014.
- Out of scope (not gaps): FR-019 forge-neutralization **migration** + SC-008/SC-013 (Iteration 3);
  T013b release-prep (carried, D-001).

## Phase 1 — Branch hygiene

- Branch `182-work-kind-branch-governance`; working tree clean except untracked/modified
  `.specrew`/`.squad` session+cache files (correctly left unstaged per standing rule).
- Implementation commits since the before-implement boundary: `dc6e78cf` (validator + bypass),
  `b56dd0c2` (gate/FileList/schema fix), `05fce9d1` (capability + github adapter + brownfield +
  dogfood), `d3493f96` (state truth reconcile). Boundary commits use the `boundary(<phase>)` form.
- **Finding F4 (branch-hygiene/gate):** two committed `.md` files fail CI Lint (see Phase 5).

## Phase 2 — Functional correctness + claim-to-code + workshop conformance

Every iteration-2 functional requirement is implemented and traced to code + a passing assertion (see
the claim ledger and FR×phase matrix below). Highlights verified by reading the code, not the summary:

- **FR-007** — `Invoke-SpecrewWorkKindValidation` performs all four checks (one-kind, in-catalog,
  changed-file scope, closeout-evidence), defaults to advisory, and every finding **names the exact
  gap + allowed scope + the fix** (SC-005). Confirmed against the validator suite (docs-only touching a
  `.ps1` → `advisory-fail` naming the file; blocking mode → `blocking-fail`).
- **FR-009 (carried)** — branch-prefix inference (`Get-SpecrewWorkKindFromBranchPrefix`) and the
  global-allowlist exemption both behave as the catalog declares.
- **FR-012 / FR-021** — `Invoke-SpecrewCapabilityDetection` reports `ci-only`/`manual` honestly for the
  generic path and never promises branch-protection; brownfield returns ADAPT (CI present) vs CHANGE
  with an explicit never-overwrite note.
- **FR-020** — `Invoke-SpecrewGitHubApplyProtection` refuses without `-Approved`, and is describe-only
  with `-Approved` but no `-Execute`; the contract guard refuses read-only/unverified adapters. Tested.
- **Workshop conformance** is satisfied with one consistency finding — see the workshop-decision
  conformance ledger (F1).

## Phase 3 — Non-functional requirements

- **Fail-open (NFR #5, load-bearing for a CI check):** every reader (`work-kind-common.ps1`) returns
  `$null` on malformed input and the validator degrades to advisory WARN; missing catalog / no
  base-ref / unknown kind all WARN, never crash or spuriously block. Behaviourally proven (T211/T212).
- **Forge-neutral core:** the validator core, common readers, and generic fallback invoke no `gh`/API;
  `provider-adapter.tests.ps1` asserts the core path calls no GitHub URL.
- **No-new-dependency:** the hand-rolled YAML readers honour Specrew's deliberate avoidance of
  `powershell-yaml`. (Watch item carried from Iter-1: a maintenance surface as the schemas evolve.)
- **No secret held:** the GitHub adapter uses the caller's `gh auth`/`GITHUB_TOKEN`; nothing in the
  iteration stores or requires a Specrew-held credential.

## Phase 4 — Code quality + anti-patterns + dependency reality

- PSScriptAnalyzer (`-Settings PSGallery`): **0 errors**, 3 warnings (CI fails only on Error; warnings
  are the Proposal-037 queue).
- **Finding F1 (consistency/honesty, moderate):** `provider-adapter.ps1` still carries the Iteration-1
  contract-dispatch stubs — `Invoke-SpecrewDetectCapability` (github → `ci-only`, "lands in iteration
  2") and `Invoke-SpecrewApplyProtection` (github → "implemented in iteration 2"). We **are** in
  iteration 2; those comments are stale-by-time. The real github capability + apply landed in a
  **parallel** path (`capability-detector.ps1` → `Get-SpecrewGitHubCapability`;
  `provider-github.ps1` → `Invoke-SpecrewGitHubApplyProtection`) that bypasses the contract dispatch.
  Grep confirms the contract ops are exercised **only** by the Iteration-1 `provider-adapter.tests.ps1`
  expecting the stub — no iteration-2 runtime path routes github through them. So this is orphaned,
  stale-by-time code + a dual capability path, **not** a live behavioural bug, and it *under*-claims
  (so it is not an SC-008 over-claim). Bounded reconciliation: either delegate the contract op's github
  branch to the real github functions and drop the stale comments, or document the transitional
  duplication honestly.
- **Finding F2 (code-quality, minor):** in `provider-github.ps1`, `$plan` is assigned (lines 26, 38)
  and never read or returned — dead code. PSScriptAnalyzer flags it
  (`PSUseDeclaredVarsMoreThanAssignments`, line 26). The mechanism mapping comment even says "Without
  the plan we report the conservative mechanism." Wire `$plan` into the mapping or drop it.
- **Finding F3 (code-quality, trivial/carried):** `PSAvoidUsingEmptyCatchBlock` at
  `provider-github.ps1:40` (intentional fail-open — add a one-line comment to silence it) and the
  `PSUseShouldProcessForStateChangingFunctions` false positive on `New-SpecrewProviderAdapter` (a pure
  constructor; carried from Iter-1 on the Proposal-037 queue).
- Dependency reality: the only external tool is `gh`, confined to `provider-github.ps1` and fail-open;
  the GitHub Actions template is the only GitHub-specific wiring and runs the neutral script.

## Phase 5 — Test coverage + gate completeness + evidence replay

Evidence replayed this review (commands re-run, not quoted from the summary):

- `tests/unit/work-kind-catalog.tests.ps1` → 36 PASS.
- `tests/unit/provider-adapter.tests.ps1` → 21 PASS.
- `tests/unit/work-kind-validator.tests.ps1` → 12 PASS (T211).
- `tests/unit/work-kind-runtime.tests.ps1` → 19 PASS (T212).
- `validate-governance.ps1` → PASS on iterations 001 and 002 (WARNs are pre-existing/out-of-scope:
  unrelated closed iterations 048/141 missing dashboards, and handoff-block-missing session-evidence
  warnings — none are feature-182 FAILs).
- `filelist-completeness.tests.ps1` → PASS (287 entries; bidirectional guard).
- **Finding F4 (gate completeness, must-fix):** the exact CI Lint command
  (`markdownlint '**/*.md' --ignore node_modules --ignore .squad --ignore .specify`) returns **2
  errors**, both MD047 single-trailing-newline: `iterations/002/drift-log.md:45` (iteration-2
  in-scope, from `efba60a1`) and `current-architecture.md:15` (pre-existing from iter-1 `99380c06`,
  surfaced now — meaning Iter-1's "markdownlint clean" was also slightly inaccurate). CI Lint goes red
  on this branch as-is, and `state.md`/`plan.md` assert "markdownlint clean", which is objectively
  false at this commit. Add the trailing newlines and correct the claim.

## Phase 6 — System safety + operations

- **Privileged surface:** `apply_protection` is the only state-changing op. It is refused without
  explicit `-Approved`, refused for read-only/unverified/synthesized adapters (DP-S2/S3), and even when
  approved is describe-only until `-Execute` — the live mutation is honestly deferred to the
  human-approved dogfood/beta. Denial-path tested (T212).
- **Emergency bypass (FR-011/SC-009):** `Write-SpecrewWorkKindBypassAudit` writes a durable
  who/why/when/what record; never a silent skip. Tested.
- **Operational wiring:** advisory-by-default CI workflow that warns and names the gap but never blocks
  until a team graduates `MODE: blocking`; honest capability reporting prevents false confidence.
- **Dogfood (SC-014):** Specrew's own `.specrew/repository-governance.yml` matches its real posture
  (main protected, PR-required, no force-push/deletion, applies to admins, Copilot opt-in). Verified
  **structurally** (capture internally consistent + schema-valid); the live GitHub posture-match is
  asserted from the 2026-06-11 mitigation, with live GitHub verification honestly deferred to the
  dogfood/beta (the test does not query the real repo).

## Phase 7 — Output synthesis + report falsification

I attempted to falsify my own findings before recording them:

- *Is F1 actually a live bug?* No — grep proves the contract dispatch is exercised only by Iter-1 tests
  expecting the stub; the real runtime path is correct and tested. Recorded as consistency/honesty, not
  behavioural. Severity kept at moderate, not blocking-behaviour.
- *Is F4 a CI false alarm or scope mismatch?* No — re-ran the exact CI command; 2 errors repo-wide, both
  in feature 182, one this iteration's own artifact. Real and CI-blocking.
- *Are the validate-governance WARNs in-scope?* No — they name unrelated closed iterations (048, 141)
  and session handoff-evidence; not feature-182 failures.
- *Is the dogfood SC-014 over-stated anywhere?* It was — corrected above to "structurally verified;
  live GitHub verification deferred," so the review does not itself over-claim.

## FR × phase coverage matrix (iteration-2 scope)

| FR | P2 functional | P3 NFR | P4 quality | P5 tests/gates | P6 safety/ops | Outcome |
| --- | --- | --- | --- | --- | --- | --- |
| FR-007 validator | pass | pass (fail-open) | pass | pass (T211) | pass (advisory) | pass |
| FR-011 bypass audit | pass | pass | pass | pass (T211) | pass (durable) | pass |
| FR-012 capability detection | pass | pass | F1 (dual path) | pass (T212) | pass (honest) | pass-with-finding |
| FR-013 dogfood | pass | n/a | pass | pass (T212) | pass (SC-014 structural) | pass |
| FR-015 github adapter | pass | pass | F1 + F2 | pass (T212) | pass (gh confined) | needs-work |
| FR-016 synthesis read-only | pass | pass | pass | pass (T212) | pass (DP-S3) | pass |
| FR-020 apply human-gated | pass | pass | pass | pass (T212 denial) | pass | pass |
| FR-021 brownfield | pass | pass | pass | pass (T212) | pass (never overwrite) | pass |

## Claim-to-evidence ledger

| Claim (from plan/state/summary) | Evidence replayed | Verdict |
| --- | --- | --- |
| 88 unit assertions green | re-ran 4 suites: 36 + 21 + 12 + 19 = 88 PASS | true |
| PSScriptAnalyzer 0 errors | re-ran PSGallery on 6 work-kind scripts: 0 errors, 3 warnings | true |
| FileList-completeness PASS | re-ran: PASS, 287 entries, bidirectional | true |
| validate-governance 0 FAIL | re-ran: PASS iter-001 + iter-002 (WARNs out-of-scope) | true |
| "markdownlint clean" (state.md/plan) | re-ran exact CI command: 2 MD047 errors | **false → F4** |
| apply_protection never auto-applied | code + T212 denial-path: refused w/o -Approved, describe-only w/o -Execute | true |
| github capability landed (iter-2) | landed in capability-detector + provider-github; contract dispatch left stale | true-but-F1 |
| Specrew dogfood matches real posture | structural + schema check pass; live verification deferred | true (structural) |

## Design-to-code trace

| Design decision (workshop) | Code | Conformance |
| --- | --- | --- |
| Provider-neutral core; no forge import | validator core + common + generic; asserted no-gh | satisfied |
| ProviderAdapter is the only forge seam | gh confined to `provider-github.ps1` | satisfied-with-finding (F1 dual path) |
| apply_protection human-approved (DP-S2) | guard refuses w/o `-Approved`; describe-only w/o `-Execute` | satisfied |
| Synthesized adapter read-only until verified (DP-S3) | contract guard + read-only example refuses apply | satisfied |
| Advisory default; honest phasing; no over-claim | workflow advisory; validator advisory default | satisfied (F1 comments under-claim, not over) |
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
| T204 | FR-012 | needs-work | Capability detection works + is honest (T212), but introduced a second capability path that left the contract dispatch stale-by-time (F1). |
| T205 | FR-015 | needs-work | GitHub adapter works + gh-confined + fail-open (T212), but ships dead `$plan` (F2) and its apply landed beside an unreconciled stale contract-dispatch stub (F1). |
| T206 | FR-021 | pass | Brownfield ADAPT-vs-CHANGE + never-overwrite note; read-only; T212 green. |
| T207 | FR-007 | pass | Advisory-default GitHub Actions template runs the provider-neutral script; never blocks until graduated. |
| T208 | FR-016 | pass | Read-only synthesized-adapter example: detect/describe only, apply refused until human-verified; provenance recorded. |
| T209 | FR-011 | pass | Emergency bypass writes a durable who/why/when/what artifact; no silent skip; T211 green. |
| T210 | FR-013 | pass | Dogfood `.specrew/work-kind.yml` + `repository-governance.yml`; SC-014 structural self-consistency green (T212). |
| T211 | FR-007 | pass | Validator + bypass suite: 12 behaviour-proving assertions green. |
| T212 | FR-020 | pass | Capability/denial-path/brownfield/SC-014 suite: 19 assertions green (apply refused w/o approval). |

## Gap Ledger

- F4 (must-fix, gate): two committed MD047 trailing-newline lint errors fail the exact CI Lint command — `iterations/002/drift-log.md:45` (iter-2 in-scope) and `current-architecture.md:15` (pre-existing from iter-1) — while state.md/plan assert "markdownlint clean"; add the newlines and correct the claim.
- F1 (moderate, consistency/honesty): `provider-adapter.ps1` contract-dispatch github branches carry stale-by-time "lands in iteration 2" comments and are orphaned (only iter-1 tests call them) while the real github detection/apply run on a parallel path; reconcile the dispatch to the real github functions or honestly document the transitional duplication.
- F2 (minor, code-quality): `provider-github.ps1` `$plan` is assigned but never read/returned (PSScriptAnalyzer-flagged dead code); wire it into the mechanism mapping or remove it.
- F3 (trivial, carried): silence the intentional empty-catch at `provider-github.ps1:40` with a comment and leave the `New-SpecrewProviderAdapter` ShouldProcess false positive on the Proposal-037 queue.

## Notes

- Verdict drivers: F4 (CI Lint red + false "clean" claim) and F1/F2 (consistency + dead code). The
  runtime behaviour itself is correct and fully evidenced; this is a bounded truth/quality rework, not
  a functional rejection.
- The fixes are deliberately **not** applied in this review turn: silently patching the lint would
  erase the evidence that "clean" was wrong, and code edits cross the review-signoff boundary the
  maintainer owns. Recorded as findings for the human to authorize.
- Carried (not iteration-2 gaps): FR-019 migration + SC-008/SC-013 (Iteration 3); T013b release-prep
  (D-001); the hand-rolled YAML reader maintenance watch-item.
- Stop at review-signoff for the maintainer's verdict; no push, PR, merge, tag, publish, release, or
  Iteration-3 work.
