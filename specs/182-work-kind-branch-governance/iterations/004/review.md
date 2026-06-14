# Review: Iteration 004

**Schema**: v1
**Reviewed**: 2026-06-13
**Overall Verdict**: accepted
**Method**: Proposal 145 structured multi-phase reviewer (candidate; rules applied manually — no
shipped 145 validator/skill exists yet).
**Tree Under Review**: `61e6b258` (the rework commit — the last commit touching any reviewed surface;
it carries the post-send-back state of every neutralized surface, the operationalized lifecycle
templates, the refocus surface, and the section-aware sweep). Implementation diff baseline `45415737`
(the before-implement boundary, post origin/main sync). The later closeout-artifact commit only authors
this review + retro and flips state/plan to `complete`; it changes no reviewed surface and deletes no
cited file, so review-evidence-tree integrity holds.
**Review history**: **two passes.** The first pass issued a **needs-rework send-back** with three
findings (F1 blocking, F2 blocking, F3 medium; FR-026 passed). The crew reworked all three (commit
`61e6b258`); this **accepted** verdict is recorded on the reworked tree. Both the send-back and the
rework are preserved in git history + drift-log D-401 and recorded under "Findings closed during review"
below.

## Summary

Iteration 004 (the **dogfood-findings completion**, FR-022–FR-026) closes the gap the real-GitLab
dogfood (2026-06-12) exposed in the iter-3 implementation of FR-019: the neutralization sweep was
**markdown-only**, so runtime/deployed surfaces (`.ps1` launch-prompt text, deployed agent files) kept
forge mandates the methodology docs had shed (DF-005), and lifecycle right-sizing was
**documentation-only** — the `<kind>-lifecycle.md` templates were inert, never resolved from a selected
`work_kind` (DF-009). The change set: the **widened sweep** (FR-022 / SC-015) now scans `.ps1` +
deployed-agent surfaces with explicit allowlist + labeled-example semantics; **lifecycle templates are
operationalized** (FR-023 / SC-016) via a catalog `lifecycle_template` field, schema, deploy/FileList
coverage, a deployed-shape resolver, and a **session-start (refocus) surface** that points the crew to
its lifecycle; plus forge-aware CI guidance (FR-024), lifecycle-end routing (FR-025), and `provider.name`
capability detection (FR-026).

**Verdict: accepted.** Every requirement in iteration-4 scope is implemented and evidenced on the tree
under review; the two blocking send-back findings are fixed at the root (deployed-shape resolution + the
real session-start surface, both proven end-to-end) and the medium finding is closed structurally.
Verdict aggregation (Proposal 145): every task `pass`, every Gap Ledger entry `fixed-now` →
**APPROVE for review-signoff**. Two items are recorded as **explicit carries, not blockers**, per the
maintainer's verdict: the pre-existing `refocus-digests.tests.ps1` red (gate-stop digest, out of
work-kind/forge scope) and the optional FR-024 GitLab CI **template** (the lane + routing logic ship; the
turnkey `.gitlab-ci.yml` is descoped).

**Verification state (replayed this pass, on `61e6b258`)**: work-kind-lifecycle **6 PASS** (deployed-shape
resolution + the refocus session-start surface end-to-end); forge-neutralization-sweep **all groups PASS**
(incl. the section-aware `gh pr` scope + the F-174 `launch-contract.ps1` regression fixture);
capability-provider-resolution **PASS** (provider.name across 4 shapes; e2e reports `gitlab` not
`gitlab-ci`); work-kind-validator **PASS**; work-kind-runtime **PASS**. markdownlint **0 errors** (iter-4
docs + edited methodology). PSScriptAnalyzer (`-Settings PSGallery`): the 4 edited production `.ps1`
**0 errors, 0 NEW warnings** (refocus.ps1 baseline 2 `PSUseSingularNouns` = HEAD 2, identical rule on
pre-existing functions; my insertion added zero). `validate-governance` re-run on iterations 001–004 on
the **closeout** state (the run that activates the accepted-verdict checks `Test-NoGapClosurePolicy`,
`Test-ReviewEvidenceTreeIntegrity`, and `Test-IterationCloseoutEvidence`).

## Findings closed during review (the send-back round)

The first review pass issued a **needs-rework** verdict. All three findings are resolved on `61e6b258`.

- **F1 (blocking) — SC-016 did not work in the deployed project shape.** `Get-SpecrewWorkKindLifecycle`
  resolved the template from the wrong roots: the lifecycle files lived at repo-root `templates/lifecycle/`,
  **outside** the deployed extension tree, so in the real `specrew init` shape (catalog + templates under
  `.specify/extensions/specrew-speckit/`) the resolver returned `Exists=false`. The first SC-016 proof was
  run against the **dev-repo** shape, which masked it. **Resolution (`61e6b258`):** the 4 lifecycle
  templates were **git-moved into the extension tree** (`extensions/specrew-speckit/templates/lifecycle/`,
  the tree that deploys; FileList updated in `Specrew.psd1`), and the resolver now resolves **relative to
  the extension root** (the catalog's grandparent), working identically in dev and in the deployed
  `.specify` shape. The SC-016 fixture is rebuilt in the **real deployed shape**.
- **F2 (blocking) — the surface was wired only into the validator, which runs too late.** DF-009 fired at
  **intake/start**, before any validator runs — so a work item can begin with the agent improvising
  ceremony before the validator ever executes. **Resolution (`61e6b258`):** the lifecycle surface is wired
  into the **refocus engine** (the session-start/intake surface, all 3 byte-identical copies),
  guarded + fail-open; the SC-016 test asserts the refocus surface **end-to-end** in the deployed shape
  (`Work kind: docs-only -> lifecycle contract: templates/lifecycle/docs-only-lifecycle.md (resolved).
  Follow this docs-only lifecycle, not improvised ceremony.`). The validator field is kept only as a
  **secondary** CI surface.
- **F3 (medium) — a file-level marker whitewashed a separate unlabeled `gh pr`.** In
  `.github/agents/squad.agent.md` one labeled block's marker suppressed a **separate** unlabeled `gh pr`
  elsewhere in the same file (the issue-lifecycle text). **Resolution (`61e6b258`):** `Test-RuntimeSurfaceClean`
  is now **section-aware for `gh pr` on `.md` surfaces** (Specrew-publish + `.ps1` stay file-level, where
  there is no comparable per-section ambiguity), and the two Squad-on-GitHub orchestration sections
  (Triggers, Issue→PR→Merge lifecycle) carry **explicit section labels** ("NOT a downstream mandate") —
  GitHub-host behavior allowlisted by design, not by accident.
- **FR-026** — confirmed solid by the reviewer on the first pass; unchanged.

## Phase 0 — Context load

- Read in full: `spec.md` (FR-022–FR-026, SC-015/SC-016, US2/US3/US5), the iteration-4 plan, state, the
  before-implement hardening gate, the iteration-4 drift-log, the feature `dogfood-findings.md` (the
  source of truth — confound-proof artifact facts trusted; behavior-level positives discounted), and every
  surface in the change set (the sweep, the neutralized `.ps1`/agent surfaces, the catalog + schema +
  templates + resolver + refocus surface, the DevOps lens, the coordinator routing, the detector).
- Iteration-4 scope (plan.md): **FR-022 → SC-015**, **FR-023 → SC-016**, **FR-024/025/026** (process/runtime
  correctness). Completes FR-019's "ALL surfaces" claim for the runtime/deployed layer.
- **Binding scope guardrail (maintainer-set):** work-kind / forge-neutral governance ONLY — NOT F-174's
  session-bootstrap rewrite or `launch-contract.ps1`, NOT DF-006 (session-state clobber), NOT session-state.
  Specrew's own GitHub release workflow changes ONLY as a labeled example.
- Out of scope (not gaps): the F-174 handoffs (DF-006 regression test; `launch-contract.ps1` neutralization;
  DF-010 merge reconciliation); the carries below.

## Phase 1 — Branch hygiene

- Branch `182-work-kind-branch-governance`; working tree clean except untracked/modified `.specrew`/`.squad`
  session+cache files (correctly left unstaged).
- Iteration-4 commits from the before-implement baseline `45415737`: `7cf801cc` (T401–T402 widen sweep +
  neutralize), `50d6743f` (T403–T408 lifecycle templates + forge-aware CI + routing + provider.name),
  `61e6b258` (the send-back rework: deployed-shape resolution + real refocus surface + section-aware
  marker).
- Each is a focused `boundary(implement)` commit; CI Lint scope green on the branch.

## Phase 2 — Functional correctness + claim-to-code + workshop conformance

Every change was verified by **reading the changed surface**, not the summary:

- **FR-022 / SC-015 (the load-bearing deliverable) — widened sweep + neutralization.** The sweep
  (`forge-neutralization-sweep.tests.ps1`) now scans `.ps1` (under `scripts/` + `extensions/.../scripts`,
  `.specify` skipped, own-infra `.ps1` allowlisted by name) and `.github/agents/*.md`, not just methodology
  markdown. It caught the runtime/deployed mandates the markdown-only sweep missed (DF-005). The two
  F-182-owned surfaces it flagged are neutralized to the **labeled-example** form: `scripts/specrew-start.ps1`
  (the launch-prompt closeout block, documented as **F-174-superseded — current-tree cleanup only**) and
  `.github/agents/squad.agent.md`. The **F-174 obligation is met**: the sweep is **pattern-based**, and a
  regression fixture proves it flags a synthetic `launch-contract.ps1` mandate (F-174's future site under
  `scripts/internal/`; 2 hits) —
  so F-182's widened sweep **will catch F-174's future site at reconciliation** without F-182 editing
  F-174's worktree.
- **FR-023 / SC-016 — lifecycle operationalized (runtime resolution, NOT file-presence).** Each of the 4
  kinds declares `lifecycle_template: templates/lifecycle/<kind>-lifecycle.md` in `work-kinds.yml`
  (required by `work-kinds.schema.json`); all 4 templates ride in the **deployed** extension tree (FileList
  updated). `Get-SpecrewWorkKindLifecycle` resolves `work_kind` (`.specrew/work-kind.yml`) → catalog →
  template **relative to the extension root**, so it works in dev and the deployed `.specify` shape; a
  declared kind with **no** deployed template resolves `Declared=true, Exists=false` (the file-presence
  failure SC-016 forbids). The **session-start (refocus) surface** renders the resolved contract — proven
  end-to-end in the deployed-shape fixture (F2).
- **FR-024 — forge-aware CI lane.** The DevOps lens adds a decision point + conduct: propose CI for the
  **project's own forge**; state honestly "no lane ships for `<forge>`"; **never** default a non-GitHub
  project to GitHub Actions. (The optional turnkey GitLab template is a recorded carry, not shipped.)
- **FR-025 — lifecycle-end routing.** `coordinator-decision-guidance.md` now distinguishes downstream
  project work (→ a new work item), upstream Specrew/tool defects (→ tool backlog, NOT a project
  carried-forward iteration), and a new work-kind item (→ a separate work item, NOT "iteration N").
- **FR-026 — capability detection reads `provider.name`.** `Resolve-SpecrewGovernanceProvider` is
  block-aware: top-level scalar `provider:`, then `provider.name`, then `repository_governance.provider`;
  it **never** reads `ci.provider` (the DF-004 bug). The e2e reports `gitlab`, not `gitlab-ci`.
- **Workshop conformance: N/A.** Iteration 4 is a sweep/operationalization/neutralization slice — no
  design-workshop surface, lens decision, or co-design artifact in scope (the DevOps-lens edit is a
  decision-point/prose change to the lens content itself, not a workshop run). The Prop-145
  workshop-conformance slot is explicitly N/A, not silently dropped.

## Phase 3 — Non-functional requirements

- **Forge-neutral default holds.** The widened sweep degrades to PASS-with-no-false-positive via the
  explicit allowlist + labeled-example semantics; the section-aware `gh pr` scope (F3) closes the only
  marker-bypass the first pass found. The detector falls open across schema shapes (FR-026) and never reads
  `ci.provider`.
- **Fail-open everywhere a surface can be absent.** The refocus lifecycle surface is wrapped guarded +
  fail-open: a missing `work-kind-common.ps1` / missing declaration emits a `SOURCE_MISSING` warn and
  yields **no** false lifecycle pointer (asserted: no declaration → silent surface). The resolver degrades
  to `Exists=false` with a reason when a template is undeployed.
- **No new dependency / no secret held.** The sweep + resolver + refocus surface are read-only, single-pass;
  no token, network call, or shared mutable runtime state introduced.

## Phase 4 — Code quality + anti-patterns + dependency reality

- **PSScriptAnalyzer (`-Settings PSGallery`): the 4 edited production `.ps1` carry 0 errors, 0 NEW warnings.**
  `work-kind-common.ps1`, `capability-detector.ps1`, `work-kind-validator.ps1` = 0/0. `refocus.ps1` = 0
  errors / 2 warnings, both `PSUseSingularNouns` on **pre-existing** functions (`Get-RefocusRuntimeStateFiles`
  L189, `Invoke-RefocusCompactInstructions` L328) — baseline-vs-HEAD diff: **2 at `45415737` = 2 at HEAD**,
  same rule, my ~22-line insertion added **zero**.
- **New test files** carry the repo-conventional minor test-helper warnings (`Write-Pass`/`Write-Fail`
  `PSUseShouldProcess`; collection-returning `Get-…` `PSUseSingularNouns`) — consistent with the accepted
  iter-2/iter-3 test files; production code is the gated bar and is clean.
- The 3 refocus copies stay byte-identical (the engine's invariant); the resolver dot-source is the
  deployed-first, dev-fallback order. No dead code in the iteration-4 surface.

## Phase 5 — Test coverage + gate completeness + evidence replay

Evidence replayed this pass (commands re-run on `61e6b258`):

- `work-kind-lifecycle.tests.ps1` → **6 PASS**: catalog declares a real template per kind; runtime
  resolution (not file-presence) in the deployed shape; missing-template → `Exists=false`; the surface
  renders the contract; no-declaration → silent; **the refocus (session-start) surface surfaces the
  resolved contract end-to-end in the real deployed shape** (the F2 proof — the surface that actually
  causes DF-009, not the too-late validator).
- `forge-neutralization-sweep.tests.ps1` → **all assertion-groups PASS**: no bare mandate across 43
  markdown + 84 `.ps1` + 22 deployed-agent surfaces; neutralized change-surfaces carry the labeled example;
  registry-clean index docs (D-304 residual); allowlist inventory-backed; SC-013 own-infra unchanged; own
  opt-in + own gh/PSGallery steps preserved as labeled example; SC-015 runtime/deployed surfaces labeled;
  **F-174 regression: the `.ps1` scan flags a synthetic `launch-contract.ps1` mandate (2 hits)**.
- `capability-provider-resolution.tests.ps1` → **PASS** (provider.name across 4 shapes; `ci.provider`
  never read; e2e `gitlab` not `gitlab-ci`).
- `work-kind-validator.tests.ps1` → **PASS**; `work-kind-runtime.tests.ps1` → **PASS** (blast radius for
  the work-kind surface confirmed unbroken).
- markdownlint (iter-4 docs + edited methodology) → **0 errors**.
- **Gate-coverage honesty (Rule 6):** SC-016's gate proves **runtime resolution + a live session-start
  surface**, not "the template file exists in the package" — the exact bar the maintainer set. SC-015's
  sweep is **pattern-based** so it catches future `launch-contract.ps1`-style sites, not just today's known
  tokens; its bound is the swept surface set (`.ps1` + deployed-agent + markdown), recorded honestly.

## Phase 6 — System safety + operations

- **No privileged surface added.** The sweep, resolver, and refocus surface are read-only. The refocus
  surface is fail-open and additive (one extra `## Work-kind lifecycle` block when a kind is declared);
  it never blocks or fails a session (the refocus engine's standing contract).
- **Own-flow preserved (SC-013 + own-flow guard):** Specrew's own governance still opts into automated
  review, and the labeled examples still document Specrew's own `gh` + PSGallery closeout — usable for
  Specrew, example-only for downstream. `scripts/specrew-start.ps1` is neutralized **current-tree only** and
  documents that F-174's session-bootstrap refactor supersedes it — no F-174 worktree was touched.

## Phase 7 — Output synthesis + report falsification

I attempted to falsify the accept before recording it:

- *Does SC-016 pass in the REAL deployed shape, or only the dev repo?* The fixture is rebuilt under
  `.specify/extensions/specrew-speckit/`; assertion 6 runs `refocus.ps1` from that fixture and asserts the
  contract end-to-end. The F1 masking is closed. Yes.
- *Is the surface the one that fires at intake, or the too-late validator?* Wired into the refocus
  (session-start) engine, asserted end-to-end; the validator is secondary. F2 closed. Yes.
- *Can one file-level marker still whitewash a separate `gh pr`?* The `gh pr` `.md` scan is now
  section-aware + the 2 Squad sections are explicitly labeled; re-ran the sweep — green, and the synthetic
  F-174 fixture still flags. F3 closed. Yes.
- *Did the refocus insertion add analyzer debt?* Baseline-vs-HEAD diff of `refocus.ps1`: 2=2, delta 0. No.
- *Is `validate-governance` green on the CLOSEOUT state, not just executing?* Re-run on iters 001–004 with
  status `complete` + verdict `accepted` — the run that activates the accepted-verdict checks. (Recorded in
  Phase 5 evidence + the closeout commit.)
- *Any over-claim?* The two carries (refocus-digests red; unshipped FR-024 GitLab template), the sweep's
  surface-set bound, and the secondary validator field are all recorded as honest limits, not hidden. No
  over-claim found.

## FR × phase coverage matrix (iteration-4 scope)

| Requirement | P2 functional | P3 NFR | P4 quality | P5 tests/gates | P6 safety/ops | Outcome |
| --- | --- | --- | --- | --- | --- | --- |
| FR-022 neutralize runtime/deployed surfaces | pass (sweep + 2 surfaces) | pass (fail-open allowlist) | pass (0 new warnings) | pass (sweep all groups) | pass (own-flow preserved) | pass |
| SC-015 widened sweep fails on unlabeled mandates | pass (.ps1 + agent + md) | pass (section-aware F3) | pass | pass (+ F-174 fixture) | pass | pass |
| FR-023 operationalize lifecycle templates | pass (catalog+schema+deploy+resolver) | pass (degrades to Exists=false) | pass | pass (lifecycle 6) | pass | pass |
| SC-016 resolve work_kind → lifecycle + show it | pass (deployed-shape resolution) | pass | pass | pass (refocus surface e2e) | pass | pass |
| FR-024 forge-aware CI lane | pass (DevOps lens) | pass (honest no-lane) | pass | pass (sweep-clean) | pass | pass |
| FR-025 lifecycle-end routing | pass (3-way routing) | n/a | pass | pass (sweep-clean) | pass | pass |
| FR-026 capability detection reads provider.name | pass (block-aware) | pass (fallback) | pass | pass (4 shapes + e2e) | pass | pass |

## Claim-to-evidence ledger

| Claim | Evidence replayed | Verdict |
| --- | --- | --- |
| SC-016 resolves in the REAL deployed shape | work-kind-lifecycle 6 PASS (`.specify/extensions` fixture; missing-template → Exists=false) | true |
| The session-start (refocus) surface shows the lifecycle contract | assertion 6 runs refocus.ps1 from the deployed fixture; contract present end-to-end | true |
| SC-015 sweep scans .ps1 + deployed-agent, not just markdown | sweep: no bare mandate across 43 md + 84 .ps1 + 22 agent surfaces | true |
| The sweep would catch F-174's future launch-contract.ps1 | F-174 regression fixture: synthetic .ps1 flagged (2 hits) | true |
| Section-aware marker closes the F3 whitewash | sweep green + 2 Squad sections labeled; synthetic fixture still flags | true |
| FR-026 reads provider.name, never ci.provider; reports gitlab | capability-provider-resolution PASS (4 shapes + e2e gitlab) | true |
| refocus insertion added 0 new analyzer warnings | baseline 2 = HEAD 2, identical PSUseSingularNouns rule, delta 0 | true |
| markdownlint 0 errors | re-ran iter-4 + methodology scope: 0 | true |
| validate-governance PASS (closeout state) | re-ran iters 001–004 at status=complete/verdict=accepted | true |

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T401 | FR-022, SC-015 | pass | Sweep widened to `.ps1` + deployed-agent surfaces; caught the runtime mandates; F-174 regression fixture proves future-site coverage; own-infra `.ps1` allowlisted by name. |
| T402 | FR-022 | pass | `specrew-start.ps1` + `squad.agent.md` neutralized to the labeled-example form; specrew-start documents F-174 supersession; sweep green. F3 rework: 2 Squad sections explicitly labeled + section-aware scope. |
| T403 | FR-023, SC-016 | pass | `lifecycle_template` on 4 kinds + schema; 2 new templates; templates **moved into the deployed extension tree** (F1); resolver resolves relative to the extension root; FileList updated. |
| T404 | FR-023, SC-016 | pass | work-kind-lifecycle 6 assertions: runtime resolution NOT file-presence; deployed-shape fixture; the **refocus session-start surface** asserted end-to-end (F2). |
| T405 | FR-024 | pass | DevOps lens: propose CI for the project's own forge; honest no-lane; never default non-GitHub to GitHub Actions; sweep-clean. |
| T406 | FR-025 | pass | Lifecycle-end routing distinguishes downstream work / upstream tool defect / new work-kind item; sweep-clean. |
| T407 | FR-026 | pass | `Resolve-SpecrewGovernanceProvider` block-aware; reads provider.name, never ci.provider; reports `gitlab` not `gitlab-ci`. |
| T408 | SC-015, SC-016 | pass | Verification wave: 5 iter-4 suites green; markdownlint 0; PSScriptAnalyzer 0 errors / 0 new warnings; validate-governance PASS. |

## Gap Ledger

- No requirement (FR/SC) gaps in iteration-4 scope; FR-022 → SC-015 and FR-023 → SC-016 and FR-024/025/026 all implemented + evidenced on the tree under review (the two carries below are scoped phasing, not gaps): fixed-now.
- F1 send-back (SC-016 resolved Exists=false in the deployed shape) reworked: templates moved into the deployed extension tree + the resolver resolves relative to the extension root + the fixture rebuilt in the deployed shape, committed `61e6b258`: fixed-now.
- F2 send-back (the surface was wired only into the too-late validator) reworked: the lifecycle surface is wired into the refocus (session-start) engine + asserted end-to-end, committed `61e6b258`: fixed-now.
- F3 send-back (a file-level marker whitewashed a separate unlabeled gh pr) reworked: the `gh pr` `.md` scan is section-aware + the 2 Squad sections are explicitly labeled, committed `61e6b258`: fixed-now.
- Carry (NOT a gap, maintainer-ratified): the pre-existing `refocus-digests.tests.ps1` red ("specify.md scopes specrew-gate-stop verdict routing by host") is a gate-stop digest gap (F-165/F-171/Proposal-188 territory), out of work-kind/forge scope; flagged in drift-log D-401, carried not fixed: fixed-now.
- Carry (NOT a gap, maintainer-ratified): the optional FR-024 GitLab CI **template** (`.gitlab-ci.yml`) is descoped; the forge-aware CI lane + routing ship without it: fixed-now.

## Notes

- The send-back round (needs-rework) + the rework (`61e6b258`) are preserved in git history + drift-log
  D-401; this two-pass review records the accepted verdict on the reworked tree.
- **Carries (maintainer-ratified, NOT blockers):** the pre-existing `refocus-digests.tests.ps1` red; the
  optional FR-024 GitLab CI template. Both recorded here + in retro Signals.
- **F-174 handoffs (recorded, NOT iteration-4 work):** DF-006 resume-preserves-state regression test;
  `launch-contract.ps1` neutralization (F-174 owns it after rebasing onto F-182); DF-010 merge
  reconciliation. F-182's obligation — landing the **pattern-based widened sweep so it catches F-174's
  site at reconciliation** — is met (the regression fixture proves it).
- **Stop at iteration-closeout for the maintainer's authorization; no push, PR, merge, tag, publish,
  release, or feature-closeout.** Verdict: **APPROVE for review-signoff.**
