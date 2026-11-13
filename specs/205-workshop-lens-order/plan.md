# Implementation Plan: Workshop Lens Order (Proposal 220, iteration 1)

**Branch**: `205-workshop-lens-order` | **Date**: 2026-11-10 | **Spec**: file:///C:/Dev/specrew-220-workshop-lens-order/specs/205-workshop-lens-order/spec.md
**Input**: the spec, the workshop records under `workshop/`, and the design analysis `iterations/001/design-analysis.md` (Option A, approved 2026-11-10).
**Plan verdict**: approved for plan on 2026-11-10, with three changes. They are applied below and marked *(plan verdict)*:

1. `specrew-conformance-provider.ps1` is not edited, and its regex alternation is exempted instead.
2. In code and data files, consecutive lines that each carry a lens id form one block.
3. The tagging checks count numbered decision points themselves.

The prompt rulings: observability-resilience stays `solution`; the sweep exclusions are accepted; the short-name limit is accepted, and those lists go to iteration 3's input.

## Summary

`index.yml` becomes the only definition of the lens order. It is problem-first (option A), and each lens gets a
`space` of `problem`, `solution` or `both`. Every lens file tags its questions under `### Problem questions` and
`### Solution questions` inside `## Design Decision Points`. The surfaces that keep a list of lenses are rewritten
to the one order:

- the workshop skill
- the methodology
- the before-specify command
- the catalog README

A new test-first parity test proves the order and the tagging, and the agenda writer refuses a new agenda that
breaks the order. Confirmed agendas are never re-checked (FR-013). The tagging pass also produces iteration 2's
input: the per-lens list of problem-side gaps.

## Technical Context

**Language/Version**: PowerShell 7 (pwsh), Markdown, YAML (the constrained subset read by `Read-IntakeYaml`)
**Primary Dependencies**: none new. `Read-IntakeYaml.ps1` already parses `index.yml`, and it was verified on 2026-11-10 to accept `space`.
**Storage**: files: `index.yml` and the lens markdown. No new persisted field (data-storage decision 3).
**Testing**: script-style tests (`Set-StrictMode`, `Assert-True`/`Write-Fail`, exit code), registered as named `specrew-ci.yml` steps
**Target Platform**: the Specrew module and its deployed project copies (Windows, Linux, macOS)
**Project Type**: CLI/tooling (PowerShell module + methodology text)
**Performance Goals**: the parity test finishes in seconds over the shipped text (a guideline, not a requirement)
**Constraints**:

- No `scripts/specrew-update.ps1` run in this worktree while 203 is unmerged.
- `.squad/active-features.yml` is never committed again on this branch.
- 203, its pin and `C:\Dev\specrew-b4f-142` are untouched.
- Before every push: `validate-governance.ps1 -ProjectPath . -ChangedOnly` and the CI markdownlint command, and push only if both exit 0.

**Scale/Scope**: 11 lens files, 1 catalog, 4 prose surfaces, 1 script check, 2 test files, 1 CI file, proposal 220 + INDEX

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`
**Inferred Quality Profile**: `quality-profile.custom-composition.v1` (resolver output, **corrected below**)
**Selected preset ref or explicit custom composition**: custom composition from `security-baseline@v1.0.0`, `robustness-baseline@v1.0.0` and `test-integrity@v1.0.0`
**Bounded custom composition**: the resolver matched `node-rest-with-postgres` (90) and `react-spa-public` (80) from
the repository's `package.json`. That is wrong for this feature (DRIFT-001, a recurrence of 203's DRIFT-001). The
corrected surfaces are below.

### Quality plan (resolved profile, corrected)

#### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `lens-catalog` | `extensions/specrew-speckit/knowledge/design-lenses/index.yml`, `*.md` | custom (YAML + Markdown) | the one order and the tagged questions |
| `methodology-prose` | the skill, the methodology, the before-specify command, the catalog README | custom (Markdown) | the full and partial lists the parity test checks |
| `agenda-writer` | `extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1` | custom (PowerShell 7) | the only runtime code change: the refusal |
| `tests-ci` | `tests/unit/lens-order-parity.tests.ps1`, `tests/integration/workshop-agenda-confirmation.tests.ps1`, `.github/workflows/specrew-ci.yml` | custom (PowerShell 7 + GitHub Actions) | the proof and its CI lane |

*Corrected:* the resolver's `api-runtime` (Node.js http-api) and `browser-ui` (TypeScript browser-spa) surfaces do not exist in this feature.

#### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| `test-integrity` | required | The feature *is* a proof. The parity test must fail first on today's five orders (SC-001), and must never be made green by filing a question under the wrong heading (FR-015). |
| `robustness` | required | The agenda writer refuses and never reorders. The parity test reports every mismatch in one run. |
| `security` | not-applicable | There is no identity, secret or trust boundary. The refusal text names lens ids only. |
| `concurrency-correctness` | not-applicable | Single-process text checks. The agenda writer's write path is unchanged. |
| `retry-idempotency-and-recovery` | not-applicable | No retries or shared state, as recorded in the hardening gate. |

#### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | custom-composition (above) | corrected stack |
| Mechanical Checks | dead-field, anti-pattern, test-integrity | `run-mechanical-checks.ps1` → `iterations/001/quality/mechanical-findings.json` |
| Ecosystem Tools | markdownlint (CI command), `validate-governance.ps1 -ChangedOnly`, PSScriptAnalyzer as CI runs it | local before every push; CI after |

#### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| parity test red-first | test-integrity | first run of `lens-order-parity.tests.ps1` on the unchanged tree, output kept in `quality-evidence.md` | planned |
| parity test green | test-integrity | the same test after the change, plus its CI named step | planned |
| agenda refusal + FR-013 resume | robustness | the extended `workshop-agenda-confirmation.tests.ps1` | planned |
| existing workshop tests | regression | a local run of every workshop test, with results reported (FR-021) | planned |
| CI three workflows green, no skipped gate job | process | Specrew CI / Test / Cross-Platform Validation on the pushed commit | planned |

#### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `security-baseline` live controls | no new trust surface | none |
| `operational-resilience` | no server, SLO or on-call surface | none |

#### Explicit Phase 2+ Deferrals

- Iteration 2: problem-space completeness, using this iteration's gap list.
- Iteration 3 (after 203 merges): the two-pass split, the back-check, amendments and sweeps. **Input recorded here:**
  the short-name lens lists outside the id sweep (the skill's frontmatter description, launch-contract rule 9a, the
  reviewer prompt in `scripts/internal/continuous-co-review/worktree-reviewer.ps1`), and, after 203 merges,
  reordering the `review-signoff-evidence-gate.ps1:589` comment and removing its temporary exemption.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: iteration 001 as specified
**Hardening Gate Artifact**: file:///C:/Dev/specrew-220-workshop-lens-order/specs/205-workshop-lens-order/iterations/001/quality/hardening-gate.md
**Known-Traps Corpus Location**: none for this feature
**Trap Reapplication Artifact**: none yet

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Security surface analysis | no new surface; the refusal echoes only lens ids from the crew's own agenda JSON | hardening gate row | not-applicable |
| Error handling and failure semantics | refusal through `New-SpecrewWorkshopAgendaRefusal`, never reorder; the parity test collects every mismatch | tests + hardening gate | required |
| Retry and idempotency expectations | none: text checks and an unchanged write path | hardening gate row | not-applicable |
| Test-integrity targets | red-first parity run; a negative case for every check; no question moved to pass | tests + `quality-evidence.md` | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `test-integrity@v1.0.0` | required | the deliverable is a proof | `iterations/001/quality/` |
| `robustness-baseline@v1.0.0` | required | refusal + all-mismatch reporting | `iterations/001/quality/` |
| `security-baseline@v1.0.0` | not-applicable | no new trust surface | hardening gate rationale |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| co-review | codex (human-selected, `workshop-205-workshop-lens-order`) | recorded at review | none | Claude is the author |

### Explicit Later Deferrals

- Iteration 2's question additions, and iteration 3's back-check and sweeps, as above.

## Constitution Check

- **Spec Authority Gate**: every deliverable below maps to a spec FR. There is no scope beyond the spec. The spec
  marks the two-pass split as iteration 3.
- **Layering Gate**:
  - Spec Kit extension layer: lens catalog, lens files, skill, before-specify command, agenda writer.
  - Docs: methodology.
  - Repository process: CI and the proposal.
  - Squad layer: no change.
- **Traceability Gate**: see "FR coverage" below. Every FR has deliverables and a test or evidence.
- **Ownership Gate**: implementer (Claude) for all FRs, codex co-review, the spec steward for drift, and the
  maintainer for every boundary.
- **Capacity Gate**: story points. The estimate is about 12 SP against proposal 220's 10-15 SP for iteration 1
  (breakdown in the iteration plan).
- **Drift/Reconciliation Gate**: `iterations/001/drift-log.md` for iteration drift, and `workshop/intake-drift-log.md`
  for intake. A spec conflict goes through clarify.
- **Verification Gate**: the red-first parity run, then green, the existing workshop tests, CI on the pushed
  commit, and the codex review.

## FR coverage (every FR, including FR-017, FR-020, FR-021, FR-022)

| FR | Deliverable | Proof |
| --- | --- | --- |
| FR-001 | parity test: full lists exact, partial relative, sweep (definition below), copies full-content, full surfaces named in the test | `lens-order-parity.tests.ps1`, red-first then green |
| FR-004 | architecture-core loses its constraints question (merged) and its scope question (moved); requirements-nfr gains the scope question | tagging checks + the SC-002 per-lens counts |
| FR-005 | `###` sub-headings in all 11 lens files; checks a/b/c, where the **tagging checks count bullet and numbered decision points themselves**, so product-domain's 8 numbered points are proven tagged *(plan verdict)*; extractor test (extractor unchanged, DRIFT-003 stays recorded) | parity test, FR-005 section |
| FR-013 | the order check runs only in `confirm-workshop-agenda.ps1` at confirmation; an old-order agenda fixture resumes and completes | `workshop-agenda-confirmation.tests.ps1` |
| FR-015 | `index.yml`: problem-first order plus `space` per lens (the tag table below) | parity test (check c) |
| FR-016 | relative-order refusal in the agenda writer | `workshop-agenda-confirmation.tests.ps1` (refusal case, no reorder) |
| FR-017 | skill and methodology describe the single-pass order from `index.yml`, problem section first inside each lens. **Methodology rewrite:** the Band 1/2/3 catalog tables (full, read in order), the "normally always-on" list and the example agenda (partial, re-ordered), and the diagram table (full) | parity test over these surfaces + review |
| FR-018 | skill sentence: `index.yml` wins on any disagreement; a confirmed agenda keeps the order it was confirmed in | parity test asserts the sentence is present in the skill source and every copy |
| FR-019 | mismatch report: file:line, expected, found, fix; every mismatch in one run; the deploy-script wording for copies | parity test self-check: a fixture with several seeded mismatches must report all of them |
| FR-020 | **per-lens gap list**: `iterations/001/problem-gap-list.md`, finalised during the tagging task (the draft is below); no question added | review + SC-006 (all 11 lenses covered) |
| FR-021 | **workshop-test CI coverage**: run all ~31 existing workshop tests locally and report; add named `specrew-ci.yml` steps for the two new/extended files plus each existing workshop test that covers a touched file and passes; a red one is reported as a finding | local run log in `quality-evidence.md`; CI |
| FR-022 | **proposal 220**: `status: active`, `shipped-as: feature-205`, a status-history line (three iterations, the fifth order surface, option A); `proposals/INDEX.md` row and summary line | review (proposals are excluded from the sweep) |

## The new order and tags (FR-015)

```text
position  lens                       space     notes
1         product-domain             problem
2         requirements-nfr           problem   gains the scope question (FR-004)
3         ui-ux                      both
4         security-compliance        both
5         data-storage               both
6         integration-api            both
7         devops-operations          both
8         architecture-core          solution  constraints merged, scope moved (FR-004)
9         component-design           solution
10        observability-resilience   solution  two bullets to decide, see "Tag disagreements" below
11        code-implementation        solution
```

## Planned tagging per lens, with every split bullet

The tagging classifies each existing decision point. **Split bullets** (the maintainer asked to see every one)
keep their words and meaning, one bullet per space:

| # | Lens | Original bullet | Problem half | Solution half |
| --- | --- | --- | --- | --- |
| S1 | security-compliance | "What data is sensitive, and how is it protected in transit, at rest, logs, telemetry, backups, and exports?" | "What data is sensitive?" | "How is sensitive data protected in transit, at rest, logs, telemetry, backups, and exports?" |
| S2 | data-storage | "How are schema changes, migrations, backup, restore, and retention handled?" | "How is retention handled?" | "How are schema changes, migrations, backup, and restore handled?" |
| S3 | integration-api | "What owns the contract and how is it versioned?" | "What owns the contract?" | "How is the contract versioned?" |

Classification of every other bullet (P = problem, S = solution):

- **product-domain**: all 8 numbered areas are P. Solution side: "No solution questions: product-domain is
  pre-technical by design."
- **requirements-nfr**: all 5 existing bullets are P. It gains "What is deliberately out of scope for this
  iteration?" (P). Solution side: "No solution questions: this lens records the drivers the solution lenses must
  meet."
- **ui-ux**:
  - P: source of UX truth; primary journeys and recovery paths; accessibility/localization/RTL/theming/regulatory constraints.
  - S: client/server/streamed data operations; how loading/empty/error states are shown; where UI state lives.
- **security-compliance**:
  - P: S1's problem half; which actions need audit records.
  - S: who authenticates and where identity is established; the authorization model; S1's solution half; threat
    surfaces introduced by scripts, plugins and the like.
- **data-storage**:
  - P: whether persistent storage is required or derived state is enough; what owns each data type; S2's problem half.
  - S: storage model; consistency model; S2's solution half; avoiding direct access to another service's database.
- **integration-api**:
  - P: S3's problem half.
  - S: integration style; sync/async; safe/idempotent/cacheable; authn/throttling/API management; compatibility
    testing; S3's solution half.
- **devops-operations**:
  - P: which environments must be equivalent and where they may differ; what users, roles, service identities and
    permissions are needed.
  - S: hosting model; code-owned vs manual infrastructure; secrets and configuration; CI/CD stages and rollback;
    the CI lane for the project's forge.
- **architecture-core**: S for design method, building blocks, volatility, and the simplicity/reversibility
  balance. Problem side: "No problem questions: binding constraints and scope are owned by requirements-nfr."
- **component-design**: all 5 are S. Problem side: "No problem questions: ...".
- **code-implementation**: all 7 are S. Problem side: "No problem questions: ...".
- **observability-resilience**: all 6 are S. That covers what must be logged, measured or traced; correlation
  context; health checks; retry/timeout patterns; and, by the plan-verdict ruling, "What errors are expected ..."
  and "What is the cost of observability ...".

### Tag disagreement, ruled at the plan verdict (FR-015)

The planning pass found one lens whose questions may disagree with its expected tag:

- **observability-resilience (expected `solution`)**:
  - "What errors are expected, and which are exceptional?" reads as a problem fact (the domain's failure modes).
  - "What is the cost of observability, and what should not be logged?" mixes a budget/privacy constraint
    (problem) with a mechanism choice (solution).
  - If these are problem questions, the tag becomes `both` and S4 would split the second bullet. If not, the tag
    stays `solution` and both stay solution questions.
  - **Ruling (maintainer, plan verdict 2026-11-10):** observability-resilience stays `solution`. Both bullets are
    solution questions as worded, and their problem-side halves go to the gap list. There is no S4 split.

### SC-002 expected counts (`Get-SpecrewLensDecisionPoints`)

```text
lens                       before  after  why
product-domain             0       0      numbered list; the extractor sees bullets only (DRIFT-003)
requirements-nfr           5       6      + scope question
ui-ux                      6       6
security-compliance        5       6      S1
data-storage               6       7      S2
integration-api            6       7      S3
devops-operations          7       7
architecture-core          6       4      - constraints (merged), - scope (moved)
component-design           5       5
observability-resilience   6       6      no S4 split (plan-verdict ruling)
code-implementation        7       7
```

## The sweep: what counts as a "run of three or more lens ids" (maintainer note 1)

**Lens id**: an `id` from `index.yml`, matched as a whole token: `(?<![A-Za-z0-9_-])<id>(?![A-Za-z0-9_-])`. So
`architecture-core.md` and `` `architecture-core` `` match. `architecture-core-v2` and `my-ui-ux` do not.

**Scanning unit (block)**: lens ids are collected per block in reading order, never across blocks.

- **Markdown files (`.md`)**:
  - a **prose line** is one block;
  - a **list** is one block: consecutive list items (`-`, `*`, `+` or `N.` at the same indentation), with their
    indented continuation lines, ending at a blank line, a heading or a non-list line;
  - a **table** is one block: consecutive rows starting with `|`, read row by row, left to right;
  - **fenced code**: each line is its own block.
- **Code and data files (`.ps1`, `.psm1`, `.psd1`, `.json`, `.yml`, `.yaml`)**: consecutive lines that each carry at
  least one lens id form one block, like consecutive list items *(plan verdict)*. A line with no lens id ends the
  block, and a single line with three or more ids is a block by itself.

**Run**: the ids in one block, in reading order, keeping only the first occurrence of each id. A block with
**three or more distinct ids** is a run. Ids separated by other words still form a run inside the block.

**Pass rule**: a run passes when its ids appear in the same relative order as `index.yml`. A **full surface**
(named in the test) must also contain exactly the `index.yml` ids, no more and no fewer. A run that must differ
needs an exemption with a reason.

**Matches (would be checked)**:

```text
1. "product-domain first, then architecture-core, component-design, data-storage ..."   (one prose line: a run)
2. - `architecture-core`                                                                  (consecutive list items:
   - `component-design`                                                                    one block, a run)
   - `requirements-nfr`
3. | `architecture-core` | ... |                                                          (consecutive table rows:
   | `component-design` | ... |                                                            one block, a run)
   | `requirements-nfr` | ... |
4. $x -match '(?:architecture-core|requirements-nfr|data-storage|ui-ux)'                (one code line: a run)
5. $ids = @(                                                                               (consecutive code lines that
     'architecture-core',                                                                   each carry an id: one block,
     'component-design',                                                                    a run; the plan verdict)
     'requirements-nfr')
```

**Does not match**:

```text
1. "requirements-nfr and architecture-core"                       (two ids only)
2. "... architecture-core ..."  <blank line>  "... ui-ux ... data-storage"   (separate blocks, never joined)
3. ## heading with architecture-core, then a list of ui-ux, data-storage   (heading ends the list block)
4. "architecture-core-v2, my-ui-ux, data-storage-x"               (not whole-token ids)
5. two code lines with one id each, separated by a line with no id   (the id-free line ends the block)
6. anything under specs/, proposals/ (and the other excluded paths below)
```

**Scope (shipped text)**: tracked files under `extensions/`, `docs/`, `scripts/`, `templates/`, `hosts/`, and the
root-level `*.md`, with these exclusions:

- **Historical records** (the maintainer's rule): `specs/`, `proposals/`.
- **Proposed further exclusions, for the maintainer to confirm at this plan verdict**:
  - `tests/`: fixtures and assertions, not shipped.
  - `CHANGELOG.md`, `docs/release-notes-*.md`, `docs/beta*-findings.md`: historical registers, like proposals.
  - Deployed copies (`.specify/`, `.claude/`, `.agents/`, `.github/skills/`, `.cursor/`): checked by the copy rule
    against their source, so they are not swept twice.

**Exemptions** *(plan verdict)*:

| Path | Run | Reason |
| --- | --- | --- |
| `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` (the lines near :1346 and :1358, matched by pattern, not line number) | the regex alternations of lens ids | Order has no meaning in a regex alternation. The file is owned by feature 203's T011 and is not edited here. |

The methodology's partial lists are re-ordered rather than exempted. Any further exemption the implementation finds
necessary comes to the maintainer before it is added.

**Known limit** (accepted for iteration 1 at the plan verdict): lists that use short names rather than ids are
outside the id sweep, for example the skill's frontmatter description ("architecture, data, ui-ux, security, ...")
and launch-contract rule 9a. They are rewritten to the new order by hand, but not enforced. **They are recorded as
input for iteration 3.**

## Draft problem-side gap list (FR-020; finalised during tagging)

| Lens | Problem-side gaps seen | Notes |
| --- | --- | --- |
| product-domain | none seen | |
| requirements-nfr | regulatory/compliance NFRs are not asked directly | question bank only |
| ui-ux | who the UI's users are (skills, devices, context): personas are absent, only journeys | |
| security-compliance | which regulation or compliance regime applies; data residency; who the threat actors are | |
| data-storage | what data exists; how sensitive; how much and how fast it grows; what must be carried over | maintainer's example |
| integration-api | which outside systems exist and which contracts must be honoured; their limits/SLAs | |
| devops-operations | where it must run (platform constraints) as opposed to how it is hosted; who operates it and when; budget | |
| architecture-core | n/a (solution lens) | |
| component-design | n/a (solution lens) | |
| observability-resilience | what operators need to diagnose; SLO/alerting expectations; the problem halves of "What errors are expected, and which are exceptional?" (the domain's failure modes) and "What is the cost of observability, and what should not be logged?" (the observability budget, and data that must never be logged) | plan-verdict ruling: the lens stays `solution` |
| code-implementation | n/a (solution lens) | |

## Project Structure

### Documentation (this feature)

```text
specs/205-workshop-lens-order/
├── spec.md, plan.md, data-model.md, quickstart.md, review-diagrams.md
├── contracts/workshop-lens-order.md
├── workshop/            (intake records + intake-drift-log.md)
├── gates/design-analysis-001.md
└── iterations/001/      (design-analysis, plan, state, drift-log, quality/, problem-gap-list.md)
```

### Source Code (repository root)

```text
extensions/specrew-speckit/knowledge/design-lenses/index.yml          (order + space)
extensions/specrew-speckit/knowledge/design-lenses/<11 lens>.md        (### sub-headings, FR-004 move)
extensions/specrew-speckit/knowledge/design-lenses/README.md           (full list, new order)
extensions/specrew-speckit/squad-templates/skills/design-workshop.md   (full list, sentences, problem-first conduct)
extensions/specrew-speckit/commands/speckit.specrew-speckit.before-specify.md   (full list)
extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1         (relative-order refusal)
docs/methodology/design-workshop-methodology.md                        (tables + partial lists)
tests/unit/lens-order-parity.tests.ps1                                 (new)
tests/integration/workshop-agenda-confirmation.tests.ps1               (extended)
.github/workflows/specrew-ci.yml                                       (named steps)
proposals/220-...md, proposals/INDEX.md                                (FR-022)
deployed copies under .specify/, .claude/, .agents/, .github/skills/, .cursor/   (via the two deploy scripts only)
```

## Complexity Tracking

No constitution violations. The only new code is one refusal branch and one test file. The sweep is the most
intricate part, and its definition is fixed above so it can be reviewed before it is written.

## Iteration 002 plan (Amendment A1, Option A)

**Input**: spec Amendment A1 (FR-023 to FR-029, FR-031; FR-030 is iteration 003), the iteration 002 workshop record
`workshop/iteration-002-problem-space.md`, and the design analysis `iterations/002/design-analysis.md` (Option A,
approved for plan by the maintainer on 2026-11-13). Amendment A1 is approved at this plan boundary (maintainer ruling,
2026-11-13; DRIFT-205-INTAKE-005).

**Iterations after this one** (the maintainer's ruling at the design decision): iteration 003 is the
code-implementation lens refresh (FR-030), straight after 002, not waiting for feature 203. Iteration 004, after 203
merges, holds the two-pass split, the back-check, amendments, sweeps, and the items iteration 001 carried forward.

### What changes, Option A

Everything lives in the lens files and is read by the agent. No new code runs in the workshop path. Two new checks are
tests over the files.

| Area | Change |
| --- | --- |
| `product-domain.md` | Six facts added to its decision areas, with depth content: the compliance regime is asked at every depth; the other five are recommendation lines at Light and questions at Standard and Deep. |
| `product-domain.yml` (per feature) | Six new keys in the free-form `areas`; no schema change. |
| Receiving lenses | Each hand-forward is one recommendation line naming the product-domain area key it comes from. |
| Six lenses | The twelve FR-025 questions, under `### Problem questions`, each with the fixed suffix. |
| Workshop skill | One recommendation block per lens, shown once, closed by one reply; "accept" closes a lens whose open items are all recommendations; product-domain asks the compliance regime at every depth. |
| Spec template | A new `## Problem Context` section with one named line per fact (the FR-029 consumer). |
| Tests | One new test file with two checks: the FR-028 length numbers and the FR-029 consumers. |

### The six product-domain facts (FR-023, FR-024)

| Fact | Area key | Light | Default when nothing shows | Handed forward to | Consumer in spec.md Problem Context |
| --- | --- | --- | --- | --- | --- |
| Compliance or regulatory regime | `compliance_regime` | must answer: the named regulation or "none" | no default | requirements-nfr, security-compliance | Regulation and compliance |
| Data residency | `data_residency` | recommendation line | "not stated" | security-compliance, data-storage | Data residency |
| Systems and data to carry over | `carry_over` | recommendation line | what the repository shows, else "not stated" | data-storage, integration-api | Systems and data carried over |
| Where it must run | `platform_constraints` | recommendation line | what the repository shows, else "not stated" | devops-operations | Where it runs |
| Who operates it, and when | `operators` | recommendation line | "not stated", never a guess | devops-operations, observability-resilience | Who operates it, and when |
| Budget | `budget` | recommendation line | "not stated" | devops-operations, observability-resilience | Budget |

A receiving lens shows the line as "product-domain: <answer>" or "product-domain: not stated" (section
`## Handed Forward From Earlier Lenses`). The same line form carries the four answers that observability-resilience
receives from requirements-nfr, security-compliance and devops-operations, each naming its source lens and its key
(FR-024's source widened by the 2026-11-13 ruling, DRIFT-007). At Standard and Deep the
product-domain facts are questions, and the receiving lenses still show them as recommendation lines.

### The twelve lens-specific questions (FR-025, FR-026, FR-029)

Default recommendations are proposals; the implementer may sharpen the wording, not the meaning.

| Lens | Question | Light recommendation (reason) | Consumer |
| --- | --- | --- | --- |
| requirements-nfr | Which regulatory or compliance obligations become NFRs? | those that follow from product-domain's regime, or none when it is "none" (the regime is already answered) | Problem Context: Regulation and compliance |
| ui-ux | Who are the UI's users: skills, devices, context of use? | the users product-domain names, on the devices the repository targets (both already known) | Problem Context: Users of the interface |
| security-compliance | Who are the threat actors? | "not stated" (nothing to infer it from) | Problem Context: Threat actors |
| data-storage | What data exists? | the data the spec's entities name (already in the spec) | Problem Context: Data inventory |
| data-storage | How sensitive is it? | as product-domain's regime implies; "no sensitive data stated" when "none" | Problem Context: Data inventory |
| data-storage | How much is there, and how fast does it grow? | "not stated" | Problem Context: Data inventory |
| integration-api | Which outside systems exist, and whose contracts must be honoured? | the systems product-domain's carry-over names, else "none stated" | Problem Context: Outside systems and their limits |
| integration-api | What are their limits, quotas and SLAs? | "not stated" | Problem Context: Outside systems and their limits |
| devops-operations | What do operators need to diagnose? | "not stated" | Problem Context: Operating needs |
| requirements-nfr | What SLO and alerting is expected? | "none stated" | Problem Context: Operating needs |
| requirements-nfr | Which failures does the domain expect? | "not stated" | Problem Context: Operating needs |
| security-compliance | What must never be logged? | secrets, and any data product-domain's regime marks sensitive (the regime is already answered) | Problem Context: Operating needs |
| (none: product-domain's udget) | What is the observability budget? | handed forward from product-domain's budget fact | Problem Context: Budget |

**Placement of the last four rows (reviewer ruling under the maintainer's delegation, 2026-11-13; iteration 002
DRIFT-007).** This table first filed them under observability-resilience, a solution lens with no problem questions
(the maintainer's plan-verdict ruling of 2026-11-10, above), which FR-005c forbids. Each now sits in the lens its
subject belongs to: operator diagnosis in devops-operations, SLO/alerting and expected failures in requirements-nfr
(always on, owner of measurable thresholds), and what must never be logged in security-compliance (owner of sensitive
data). The budget half is product-domain's budget fact. observability-resilience receives all four answers as
hand-forward lines, so a feature that selects it without devops-operations still sees them (as "not stated" when the
source lens did not run). No tag, order or parity rule changes.

### Depth content for the touched lenses (FR-027)

- **Light**: every existing question is asked as today; the added questions and the hand-forward lines are
  recommendation lines; product-domain asks the compliance regime.
- **Standard**: the added questions and product-domain's six facts are asked as questions; hand-forward lines stay
  recommendation lines.
- **Deep**: as Standard in this iteration. Deep content beyond that is later work.

The touched lenses: product-domain, requirements-nfr, ui-ux, security-compliance, data-storage, integration-api,
devops-operations (one question and its hand-forward lines) and observability-resilience (hand-forward lines only).

### The question suffix (FR-026, FR-027, FR-029)

One fixed form on the question's own bullet, so the iteration 001 extractor still returns one point per question:

```text
- How sensitive is it? — Light: recommend "as product-domain's regime implies" (the regime is already answered) → spec.md Problem Context: Data inventory
- Who are the threat actors? — Light: recommend "not stated" (nothing to infer it from) → spec.md Problem Context: Threat actors
- What is the compliance or regulatory regime? — Light: ask → spec.md Problem Context: Regulation and compliance
```

Not valid: a recommendation with no reason, a consumer that is not a template section or a lens, a suffix split onto a
second line, or a recommendation line written as a separate prompt.

### Length numbers for the reference profile (FR-028)

Before: counted from the lens files at `d4c11236`. After: the Option A projection from the tables above; the length
test records the tested values.

| Depth | Must-answer points (before → after) | Minimum typed replies (before → after) | Recommendation lines (before → after) |
| --- | --- | --- | --- |
| Light | 50 → 51 (cap 51) | 16 → 16 (cap 18) | 0 → 21 |
| Standard | 50 → 66 | 16 → 16 | 0 → 6 |
| Deep | 50 → 66 | 16 → 16 | 0 → 6 |

At Light the 21 lines are product-domain's 5, the 6 hand-forward lines in requirements-nfr (1), security-compliance
(2), data-storage (2) and integration-api (1), and the 10 added questions of those four lenses (3, 2, 3 and 2). At
Standard and Deep the 16 must-answer additions are product-domain's 6 and those 10. The test records these values
(tested 2026-11-13, after the placement ruling; before it the projection was 18 lines and 63 points).

### Evidence the file tests cannot give: one recorded Light workshop run (maintainer's note)

No code runs in the workshop, so no file test can prove that a lens shows its recommendations as one list or that
"accept" closes it. One recorded Light run supplies that evidence:

- a small sample feature in a scratch project under this session's temp folder, never in this worktree;
- the deployed extension copied in by the two project-only deploy scripts; no `specrew init`, `specrew start` or
  anything on the never-run list, and the home hook files hashed before and after;
- a Light pass through product-domain and two touched lenses, with the transcript kept as evidence;
- the human replies are typed by the maintainer in that host session, because the workshop takes only typed replies.

**Cost**: 2 SP of crew work, and about 30 to 45 minutes of the maintainer's typing. If the setup turns out to need
any script on the never-run list, the crew stops and asks.

**Placement**: iteration 002, last (T026), after the lens files, the skill and the tests are done (maintainer's
decision, 13:19 local on 2026-11-13). Its success criterion is SC-012.

### Sizes and the point over the cap

| Work | SP |
| --- | --- |
| product-domain: six facts, compliance asked at every depth, depth content (FR-023) | 2 |
| hand-forward lines in the receiving lenses (FR-024) | 2 |
| twelve lens-specific questions with recommendations and consumers (FR-025, FR-026) | 3 |
| depth content for the touched lenses (FR-027) | 2.5 |
| workshop skill conduct: one block, "accept" closes (FR-026) | 1.5 |
| spec template `## Problem Context` and its copies (FR-029) | 1 |
| one test file: length numbers and consumers, with self-tests (FR-028, FR-029) | 4 |
| parity, extractor counts, workshop regression, CI steps, copies | 2 |
| the recorded Light workshop run (T026, last; SC-012) | 2 |
| **Total** | **20** |

The plan is at the cap of 20:

- the length and consumer checks share one test file and its parser (-0.5);
- FR-031, the proposal 220 status line, moves to iteration 003 with the code-implementation lens refresh (-0.5);
- the review-signoff crossing is not planned capacity in this iteration, and its 2 SP go to the recorded Light run.
  The maintainer chose this at 13:19 local on 2026-11-13. The retro reports the crossing's actual cost, as iteration
  001's did.

A recorded overrun was not possible: the governance check refuses a plan over capacity ("plan.md is over capacity:
planned effort 22 story_points exceeds the allowed 20 story_points (capacity 20 x threshold 1.0). Configured
defer_strategy is 'manual'"). The capacity file is not changed.

### Quality and risks

- The quality resolver read the stack as Node plus a browser SPA again, as in iteration 001 (iteration 002 DRIFT-001).
  The real stack is PowerShell 7 scripts, lens markdown and tests.
- Each new check is written failing first: the length test against recorded numbers, and the consumer test on the
  first added question without a consumer.
- The iteration 001 parity, tagging and agenda tests run unchanged; the extractor counts change by exactly the added
  questions (SC-010).
- Risk: an added Light line could make the lens read as a wall. The skill's one-block rule and the recorded run are the
  guard.
