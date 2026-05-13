# Hardening Gate: Iteration 002

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/015-public-readiness-pass/spec.md`  
**Iteration Ref**: `specs/015-public-readiness-pass/iterations/002`  
**Requested Review Class**: `strongest-available`  
**Effective Review Class**: `strongest-available`  
**Overall Verdict**: blocked  
**Approval Ref**: —  
**Reviewed By**: —  
**Reviewed At**: —  
**Post-Implementation Verification**: pending  
**Verified At**: —

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | Keep the iteration limited to repository-local versioning, release-history, spec-status, and governance-template surfaces; do not introduce credentials, network I/O, or new trust boundaries. | `false` | Iteration 002 changes only repository-local Markdown, YAML, PowerShell, and git-tag metadata. No authentication, secrets, or external integrations are introduced. | — |
| `error-handling-expectations` | `error-handling` | `planned` | `planning-time-analysis` | `pending-post-implementation` | `Test-PublicReadinessSurfaces` must emit additive `WARN [public-readiness]` lines without promoting warnings into hard validator failures or changing existing exit-code behavior. | `true` | The validator extension is the main behavior-sensitive surface in this iteration. Implementation cannot proceed without a clear additive-only warning contract. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `planned` | `planning-time-analysis` | `pending-post-implementation` | Version bump, changelog updates, and annotated tag creation must remain repeat-safe: no `--force` tag rewrites, no destructive history edits, and advisory-only duplicate-tag handling. | `true` | Release-bookkeeping work becomes operationally risky if reruns can rewrite or corrupt durable release markers. | — |
| `test-integrity-targets` | `test-integrity` | `planned` | `planning-time-analysis` | `pending-post-implementation` | Clean and drifted fixtures plus Pester coverage must verify missing/stale public-readiness surfaces are detected while warnings remain advisory. | `true` | Public-readiness drift detection is only trustworthy if clean and violating scenarios are exercised explicitly before closeout. | — |
| `operational-resilience-concerns` | `operational` | `planned` | `planning-time-analysis` | `pending-post-implementation` | Keep the validator extension additive, keep release-governance guidance synchronized across coordinator surfaces, and preserve repo-wide validator green behavior outside the new warning lane. | `true` | This slice touches release-truth and governance workflow surfaces together; resilience depends on staying additive and synchronized. | — |
| `changelog-completeness` | `release-history` | `planned` | `planning-time-analysis` | `pending-post-implementation` | `CHANGELOG.md` must cover Features 001 through 014 with one-line summaries and known commit or merge references where discoverable. | `true` | Public-readiness fails if release history remains incomplete or ambiguous after the version bump. | — |
| `version-tag-integrity` | `release-history` | `planned` | `planning-time-analysis` | `pending-post-implementation` | Annotated tags `v0.13.0` and `v0.14.0` must target commits `21d9e7f` and `3ff32d4` respectively, and must be created without history rewriting. | `true` | Incorrect tags would leave the repo with misleading release anchors and break the version-truth story this iteration is meant to establish. | — |
| `coordinator-prompt-update-correctness` | `governance` | `planned` | `planning-time-analysis` | `pending-post-implementation` | The feature-closeout Step 10 and the coordinator prompt/template surfaces must all describe the same version-bump, changelog, and release-tag workflow without placeholder text or contradictory guidance. | `true` | Future closeout discipline is one of the user-authorized scope items, so planning must hold all coordinator-facing guidance to one canonical workflow. | — |
| `status-field-consistency` | `documentation-accuracy` | `planned` | `planning-time-analysis` | `pending-post-implementation` | Specs 007, 009, 011, and 012 must all move from `Draft` to the canonical shipped-feature label `Complete` with no mixed labels left behind. | `true` | The scope expansion exists specifically to remove stale shipped-spec status drift; mixed labels would leave the public-readiness story inconsistent. | — |
| `version-surface-alignment` | `validation` | `planned` | `planning-time-analysis` | `pending-post-implementation` | `.specrew/config.yml`, README version summary, `docs/versioning.md`, `CHANGELOG.md`, product-spec status, and release tags must all point to the same `0.14.0` baseline. | `true` | The iteration succeeds only if all public version surfaces tell one coherent release story. | — |

## Pre-Implementation Planning Evidence

### Requirement Traceability

- **Version baseline**: FR-008 via T010
- **Release history and anchors**: FR-009, FR-010 via T011-T012
- **Future closeout governance**: FR-012, FR-013 via T013
- **Versioning documentation**: FR-014 via T014
- **Public-readiness validator extension**: FR-016 via T015
- **Shipped-spec status reconciliation**: FR-017 via T016

### Stack-Ready Analysis

| Stack Surface | Path | In Scope | Evidence |
| --- | --- | --- | --- |
| `version-source` | `.specrew/config.yml` | Yes | T010 |
| `release-history-surface` | `CHANGELOG.md`, annotated tags `v0.13.0`, `v0.14.0` | Yes | T011-T012 |
| `coordinator-governance-surfaces` | `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | Yes | T013 |
| `versioning-docs-surface` | `README.md`, `docs/versioning.md` | Yes | T014 |
| `validator-surface` | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `tests/unit/fixtures/015-public-readiness-pass/`, `tests/unit/validate-governance.public-readiness.tests.ps1` | Yes | T015 |
| `shipped-spec-status-surface` | `specs/007-user-facing-progress-handoff/spec.md`, `specs/009-project-path-resolution/spec.md`, `specs/011-specrew-start-conditional-pause/spec.md`, `specs/012-descriptive-id-handoffs/spec.md` | Yes | T016 |

## Deferral Note

- Iteration 002 planning is complete, but hardening-gate sign-off and implementation authorization are not yet recorded.
- Review, retrospective, and closeout artifacts remain out of scope until the implementation slice is separately authorized and executed.

## Hardening-Gate Status

**Overall Verdict**: blocked

**Scope**: Iteration 002 release-truth and governance-carry-forward rollout (FR-008, FR-009, FR-010, FR-012, FR-013, FR-014, FR-016, FR-017) covering version reconciliation, retroactive release history, durable tags, version-management closeout guidance, additive public-readiness warnings, and stale shipped-spec status repair.

**Pre-Implementation Planning Summary**: Planning is complete for the seven authorized scope items. The five canonical concerns appear first in the required order, followed by five iteration-specific concerns for release-history completeness, tag integrity, coordinator-guidance correctness, shipped-spec status consistency, and cross-surface version alignment. The truthful planning-time verdict remains `blocked` until a human signs off on the gate and authorizes implementation.

## Sign-Off Evidence

**Authority**: pending human hardening-gate sign-off and implementation authorization for Feature 015 Iteration 002  
**Reviewed By**: —  
**Reviewed At**: —  
**Evidence Statement**: "Iteration 002 planning artifacts are scaffolded and validator-green, but implementation may not begin until the human reviewer signs off on this hardening gate and authorizes the seven-task T010-T016 slice."

---

**Hardening-Gate Planning Status**: planning-phase artifact complete; hardening-gate sign-off is pending, and Iteration 002 remains blocked from implementation until explicit human authorization is recorded.
