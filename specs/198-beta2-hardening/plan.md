# Implementation Plan: 0.40.0-beta2 Hardening Bundle

**Feature**: 198-beta2-hardening
**Branch**: `198-beta2-hardening`
**Date**: 2026-07-10
**Spec**: file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/spec.md
**Design decision**: Option B (approved for plan with Option B — gates/design-analysis-001.md)

## Summary

The original four-iteration hardening plan grew through evidence-backed corrective slices. Iterations 001–003
delivered the substrate, governance core, and initial review seams; Iterations 005–007 replaced the failed review
authority architecture and proved the production campaign. Iteration 008 is the single Beta2 finish-line slice:
the missing command-plan supplier/injection path plus the never-opened Iteration 004 distribution/release tail.
Iteration 001 executes design Option B: a versioned JSON self-leak
deny-list with a manifest-derived blocking lint lane, and the Spec-Kit
0.12.9 / Squad 0.11.0 pin moves with scratch-dir probe evidence and
evidence-gated extension decisions. Everything later is tested on the new
substrate and born under the lint.

## Technical Context

- **Language/runtime**: PowerShell 7.x module (Specrew) + Markdown/YAML/
  JSON artifacts; Pester test suites (unit + integration); markdownlint;
  PSScriptAnalyzer.
- **Repository**: the Specrew self-host repo; PR-protected `main`;
  tag-push workflow auto-publishes prereleases to the gallery.
- **Toolchain pins**: Spec-Kit 0.8.4 → **0.12.9** (breaking: `--ai` family
  removed at 0.10.0 → `--integration <key>`; git extension opt-in since
  0.10.0; agent-context full opt-in since 0.12.0; per-event hook lists
  since 0.10.0). Squad 0.9.1 → **0.11.0** (clean).
- **Binding doctrine** (workshop anchors, spec `## Workshop Decision
  Anchors`): data seams over host-conditional code (A1); hooks are
  surfacing-only (A2); fail-direction per surface (I3 asymmetric package);
  T096/D5 at input provenance; ProviderMirrorParity; Specrew.psd1
  FileList; paired honesty tests (NFR-007).

## Phase 1 Quality Planning

### Stack Surfaces in Scope

| Surface | In scope via |
| --- | --- |
| Module scripts (`scripts/`, `scripts/internal/`, `extensions/specrew-speckit/scripts/` + `.specify` mirror) | init migration, lint script, later governance/runtime work |
| Shipped data (`extensions/specrew-speckit/data/`) | SelfLeakDenyList (new), MachineryPathList (003) |
| CI workflows (`.github/workflows/`, `templates/github/workflows/`) | SelfLeakLintLane job (001), consumer-ization (004) |
| Manifests/pins (Specrew.psd1, extension.yml + mirror, CI env, version-check, dependency-install, validate-versions, Get-SpecKitGitReference) | toolchain bump + release bookkeeping |
| Tests (`tests/unit`, `tests/integration`) | paired fixtures, probe-backed suites |

### Risk Dimensions

1. **Governance correctness** — the ratchet and honesty check change how
   boundaries and evidence behave; a wrong fail-direction is a false-green
   or a lifecycle deadlock. Mitigation: paired tests + fail-closed
   defaults (I3).
2. **Distribution blast radius** — init/update surgery touches every
   consumer. Mitigation: hash-guarded healing, fixtures per provider
   shape, advisory-first gateway.
3. **Toolchain migration** — one hard break is known; unknown breaks are
   possible. Mitigation: scratch-dir probe first, no-extensions fixture
   suites, single tested pin, 2–3 SP headroom in 001.
4. **Self-host CI trust** — the new lint must not red legit content.
   Mitigation: annotation escape with recorded reason; paired fixtures.

### Quality Tool Bundle

Pester (unit/integration/fixture), PSScriptAnalyzer, markdownlint-cli2
(F-033 ignore set), the new SelfLeakLintLane (blocking, self-host),
validate-governance.ps1 at every boundary commit, validate-versions.ps1
(extended in 004 to the seven-surface pre-tag check).

### Required Quality Gates

- Paired honesty tests green for every honesty invariant touched
  (NFR-007; enforcement item per implementation-rules).
- SelfLeakLintLane green over the deploy surface from its first landing.
- Mirror parity: every `extensions/specrew-speckit` script change syncs
  its `.specify` mirror in the same commit.
- FileList: every new shipped file lands in Specrew.psd1 FileList in its
  creating commit.
- Governance validator: no new FAIL findings at boundary commits.
- Full suites green on the Spec-Kit 0.12.9 fixture before the 001 close.

### Not-Applicable Dimensions and Rationale

- Performance tuning (evidence-driven-performance exception; W9's
  incremental baselines are recorded-evidence-driven correctness work).
- Browser/UI acceptance (no screens; console text asserted in tests).
- Load testing (no throughput service). Exact-digest campaign injection and any multi-session capture correction
  still require deterministic concurrency fixtures.

### Explicit Phase 2+ Deferrals

- Consumer-side deny-list checks + prompt fixture (FR-035/FR-036) — 004.
- Machinery list + strips (FR-012) — 003.
- Seven-surface pre-tag check extension (FR-040) — 004.

## Phase 2 Hardening and Specialist Review Planning

### Hardening Focus Areas

Trust-boundary enforcement (containment floor S1), input provenance
(T096/D5 surfaces in W11/W16 texts), fail-direction correctness (I3),
certified==reviewed identity (W5/W13 mechanism b), self-fact firewall
(205), boundary authorization (#2906 ratchet + covering set).

### Lens Activation Plan

Per the resolved quality profile (before-plan, 2026-07-09): hardening and
test-integrity lenses `required`; lens execution evidence lands per
iteration under `specs/198-beta2-hardening/iterations/<NNN>/quality/`
(hardening-gate.md scaffolded per iteration; concern rows refined with
feature-specific rationale at before-implement).

### Routing Policy

Requested reasoning/review class `strongest-available` for required
hardening and bug-hunter lenses; effective-class evidence recorded at
execution; explicit approved lower-tier override required before any
downgrade (per the resolved profile).

### Explicit Later Deferrals

Known-traps corpus seeding, quality-drift comparison, and
reference-implementation checks stay deferred unless a slice explicitly
includes them (per the resolved profile).

## Constitution Check

- Host-neutral core: all new enforcement in scripts + data seams; hooks
  surfacing-only. PASS (by design, A2/FR-006).
- Data-seam doctrine: new volatility (deny-list, machinery list, catalog
  column, release model) is data. PASS (A1).
- T096/D5: teaching texts name doors; enforcement at input provenance;
  no agent self-escalation anywhere in the design. PASS (S3).
- Digest identity: formula unchanged; W13 bypass is gate-level and
  announced. PASS (mechanism b).
- ProviderMirrorParity + FileList + markdownlint: bound as custom rules
  in implementation-rules.yml. PASS (process).

## Project Structure

### Documentation (this feature)

```text
specs/198-beta2-hardening/
├── spec.md · plan.md · tasks.md (after plan approval)
├── checklists/requirements.md
├── implementation-rules.yml · lens-applicability.json
├── data-model.md · quickstart.md · review-diagrams.md
├── contracts/198-beta2-hardening.md (+ mechanical-findings.schema.json)
├── gates/design-analysis-001.md
├── workshop/  (product-domain + 9 lens records)
└── iterations/00N/  (design-analysis, plan, state, drift-log, quality/)
```

### Source Code (repository root; iteration 001 touches)

```text
extensions/specrew-speckit/data/self-leak-deny-list.json   (NEW, FileList)
scripts/internal/lint-self-leak.ps1                        (NEW; name final at tasks)
.github/workflows/specrew-ci.yml                           (+ SelfLeakLintLane job)
scripts/specrew-init.ps1                                   (--ai → --integration)
scripts/internal/version-check.ps1                         (supported-versions)
scripts/internal/dependency-install.ps1                    (squad minimum)
extensions/specrew-speckit/extension.yml (+ .specify mirror) (requires/min_speckit)
.github/workflows/* (env pins SPEC_KIT_VERSION / SQUAD_VERSION)
Get-SpecKitGitReference call sites                          (pin reference)
tests/unit + tests/integration                             (paired fixtures, probe-backed suites)
Specrew.psd1                                               (FileList additions)
```

Iterations 002–004 touch `scripts/internal/sync-boundary-state.ps1`,
`extensions/specrew-speckit/scripts/shared-governance.ps1`, the reviewer
runtime scripts, `templates/github/workflows/*`, and
`scripts/internal/distribution-module-init.ps1` — detailed in their own
iteration design-analyses.

## Iteration Plan Overview

| Iteration | Scope (FRs) | SP | Gate highlights |
| --- | --- | --- | --- |
| 001 substrate + firewall-first | FR-033, FR-034, FR-037, FR-038, FR-039 | 5 | lint lane live + suites green on 0.12.9 fixture |
| 002 governance correctness core | FR-001..FR-007, FR-020..FR-023 (+ codex/copilot timeout measurements per clarify Q1) | 6–8 | ratchet paired tests; honesty-check paired tests; catalog resolution fixture |
| 003 containment + round economy | FR-008..FR-019 | 6–8 | containment fixtures incl. false-kill guard; reviewer-can-still-see-it per exclusion |
| 004 distribution + release | FR-024..FR-032, FR-035, FR-036, FR-040 | historical/unstarted | Never opened; its 7.0 SP amended tail is absorbed into Iteration 008 |
| 005 local-host certification + failed-design evidence | FR-050..FR-054 | historical | T035–T039 delivered; final review exposed the superseded lease/authority architecture |
| 006 authority foundation | FR-057..FR-065, SC-017..SC-021 (foundation portions) | 16 | pure campaign/run policy; immutable JSON facts; exact targets; strict terminal-result ingress; concurrency/recovery fixtures |
| 007 production completeness | FR-060..FR-064, SC-019..SC-021 (completion portions) | 17 | five real harness adapters; three OS runtime adapters; progress/retro projection; five live smokes + three-OS matrix |
| 008 Beta2 finish line | FR-024..FR-032, FR-035, FR-036, FR-040, FR-046..FR-049, SC-008..SC-015 | 15 core (18 max with both optional repairs) | supplier/runner/injection E2E; consumer distribution; prerelease publish; published-beta dogfood |

## Iteration 001 Detail (Option B)

### Scope

FR-033 (deny-list lint lane, blocking, manifest-derived surface), FR-034
(parameterization rule doc, lint error text points at it), FR-037
(deny-list data file: JSON, schema_version, proposal-205 seed, annotation
escapes per file kind), FR-038 (Spec-Kit 0.12.9: probe → migrate →
fixture suites → evidence-gated extension decisions → pin surfaces),
FR-039 (Squad 0.11.0: minimums/defaults + probe + layout suites).

### Quality Gates (iteration 001 exit)

1. Paired fixtures green: seeded leak per deny-list class → red;
   annotated → green with reason; clean surface → green.
2. Lint output content asserted (file/term/class/escape/doc pointer).
3. Probe evidence file committed under `iterations/001/quality/`.
4. Integration suites green against the 0.12.9 no-extensions fixture (or
   the added extension carries its dependency evidence).
5. All pin surfaces agree (spot-checked by test, formalized to the
   seven-surface check in 004).
6. FileList + mirror parity for every new/changed shipped file.

### FR-to-Test Mapping (iteration 001)

| FR | Test shape |
| --- | --- |
| FR-033 | Pester fixture: manifest-derived surface enumeration == deploy allowlist; seeded-leak red per class; blocking job wired in CI |
| FR-034 | lint red-output asserts the rule-doc pointer; doc exists with the abstract-rule + resolution-point teaching |
| FR-037 | schema_version + entry-shape validation test; annotation same-line + line-above cases per file kind (md HTML comment; ps1/psd1/yml # comment) |
| FR-038 | probe transcript recorded; init fixture completes with --integration; suites green on 0.12.9 fixture; pin-surface agreement assertions |
| FR-039 | squad probe (scratch) + .squad layout suites; minimum/default assertions |

### Capacity Estimate

5 SP against the 5–8 SP cap: deny-list file + seed (1), lint + CI job +
paired fixtures (2), Spec-Kit probe/migration/pins/fixture (1.5), Squad
(0.5). Headroom absorbs probe surprises (e.g., a demonstrated
git-extension dependency).

## Complexity Tracking

The original four-stream, 5–8 SP model remains historical context for
Iterations 001–004. The Iteration 005 architectural reassessment adds no
dependency or service, but it does introduce explicit multi-process claim,
allowance, and recovery correctness. The replacement Beta2 work is therefore
split into Iteration 006 (16 SP authority foundation) and Iteration 007
(17 SP production completeness), both below the current 26 SP cap. The remaining Beta2 release dependencies are
combined into Iteration 008 at 15 SP core. The separately visible 0.75 SP stale-binding rebind and 2.25 SP
stop/capture repair would raise the maximum to 18 SP if a later tasks verdict explicitly selects both.

## Phase 0 Research

Open research item (non-load-bearing, from product-domain): the Spec-Kit
0.12.9 flag survey + extension.yml hooks-schema load — resolved by the
FR-038 scratch-dir probe as the FIRST implementation task of iteration
001; evidence lands in `iterations/001/quality/toolchain-probe-evidence.md`.

## Phase 1 Design and Contracts

Wave B artifacts authored with this plan: data-model at
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/data-model.md,
public-surface contract at
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/contracts/198-beta2-hardening.md,
quickstart at
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/quickstart.md,
review diagrams at
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/review-diagrams.md. Iteration 008 adds the
supplier contract at
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/contracts/verification-plan-supplier.md.

## Post-Design Constitution Check

Re-checked after Option B detailing: no host-conditional logic introduced;
all volatility in data files; fail directions match I3; teaching texts
carry doors not powers. PASS.

## 2026-07-16 Architectural Reassessment Amendment

The maintainer approved Option B after the Iteration 005 review rounds exposed
fail-open authority, inconsistent mutation, unvalidated result consumption,
overstated probe claims, and false timing provenance. The controlling design is
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/005/design-analysis.md.

The amendment supersedes the Iteration 005 T035–T040 block as an implementation
plan for the new requirements; it does not erase those tasks as historical
evidence. Iteration 006 delivers the 16 SP authority foundation in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/006/plan.md.
Iteration 007 is reserved for the 17 SP five-harness/three-platform production
completion slice. Beta2 release remains blocked until both slices pass their
separate lifecycle gates and clean review.

## 2026-07-18 Beta2 Finish-Line Planning Amendment

The Iteration 008 planning verdict binds to the actual Iteration 007 closeout commit
`ec2287c0b950ceb78522f3b5aae8dd94d4710a88`. A pending crossing record cited the stale pre-closeout commit
`744e77d8` and tree `542c54f0`; that citation is a known binding defect and carries no authority.

Capacity arithmetic permits one coherent finish-line iteration. The amended historical Iteration 004 tail is
7.0 SP. The residual FR-048/FR-049/SC-015 supplier, setup, production injection, and fixture work is 5.5 SP.
Independent verification and published-beta dogfood add 2.5 SP, for 15.0/26 SP core. The existing T018 schema,
validator, runner, and evidence recorder are reused rather than reimplemented.

The binding plan is
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/008/plan.md. T068 (0.75 SP narrow
stale-binding rebind) and T069 (2.25 SP remaining stop/capture repair) are priced but not selected. Proposal 209
remains separately scheduled. Planning grants no task authoring, implementation, provider invocation, tag, or
publication authority.
